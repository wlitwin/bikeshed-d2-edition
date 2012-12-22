module utils.minfo;

import declares;

struct ModuleGroup
{
	this(ModuleInfo*[] modules)
	{
		_modules = modules;
	}

	@property inout(ModuleInfo*)[] modules() inout
	{
		return _modules;
	}

	void sortCtors()
	{
		// don't bother to initialize, as they are getting overwritten anyhow
		immutable n = _modules.length;
		_ctors = (cast(ModuleInfo**).malloc(n * size_t.sizeof))[0 .. n];
		_tlsctors = (cast(ModuleInfo**).malloc(n * size_t.sizeof))[0 .. n];
		.sortCtors(this);
	}

	void runCtors()
	{
		// run independent ctors
		runModuleFuncs!(m => m.ictor)(_modules);
		// sorted module ctors
		runModuleFuncs!(m => m.ctor)(_ctors);
		// flag all modules as initialized
		foreach (m; _modules)
			m.flags = m.flags | MIctordone;
	}

	void runTlsCtors()
	{
		runModuleFuncs!(m => m.tlsctor)(_tlsctors);
	}

	void runTlsDtors()
	{
		runModuleFuncsRev!(m => m.tlsdtor)(_tlsctors);
	}

	void runDtors()
	{
		runModuleFuncsRev!(m => m.dtor)(_ctors);
		// clean all initialized flags
		foreach (m; _modules)
			m.flags = m.flags & ~MIctordone;

		free();
	}

	void free()
	{
		.free(_ctors.ptr);
		_ctors = null;
		.free(_tlsctors.ptr);
		_tlsctors = null;
		_modules = null;
	}

	private:
	ModuleInfo*[]  _modules;
	ModuleInfo*[]    _ctors;
	ModuleInfo*[] _tlsctors;
}

void onCycleError(StackRec[] stack)
{
	string msg = "Aborting";

	msg ~= ": Cycle detected between modules with ctors/dtors:\n";
	foreach (e; stack)
	{
		msg ~= e.mod.name;
		msg ~= " -> ";
	}
	msg ~= stack[0].mod.name;
Lerror:
	assert(false, msg);
}


/********************************************
 * Iterate over all module infos.
 */
__gshared ModuleGroup _moduleGroup;

int moduleinfos_apply(scope int delegate(ref ModuleInfo*) @system nothrow dg) nothrow
{
	int ret = 0;

	foreach (m; _moduleGroup._modules)
	{
		// TODO: Should null ModuleInfo be allowed?
		if (m !is null)
		{
			ret = dg(m);
			if (ret)
				break;
		}
	}
	return ret;
}

/********************************************
 * Check for cycles on module constructors, and establish an order for module
 * constructors.
 */

void sortCtors(ref ModuleGroup mgroup)
	in
{
	assert(mgroup._modules.length == mgroup._ctors.length);
	assert(mgroup._modules.length == mgroup._tlsctors.length);
}
body
{
	enum AllocaLimit = 100 * 1024; // 100KB

	immutable len = mgroup._modules.length;
	immutable size = len * StackRec.sizeof;

	if (!len)
	{
		return;
	}
	else if (size <= AllocaLimit)
	{
		auto p = cast(ubyte*).alloca(size);
		p[0 .. size] = 0;
		sortCtorsImpl(mgroup, (cast(StackRec*)p)[0 .. len]);
	}
	else
	{
		auto p = cast(ubyte*).malloc(size);
		p[0 .. size] = 0;
		sortCtorsImpl(mgroup, (cast(StackRec*)p)[0 .. len]);
		.free(p);
	}
}

struct StackRec
{
	@property ModuleInfo* mod()
	{
		return _mods[_idx];
	}

	ModuleInfo*[] _mods;
	size_t         _idx;
}

private void sortCtorsImpl(ref ModuleGroup mgroup, StackRec[] stack)
{
	size_t stackidx;
	bool tlsPass;

Lagain:

	const mask = tlsPass ? (MItlsctor | MItlsdtor) : (MIctor | MIdtor);
	auto ctors = tlsPass ? mgroup._tlsctors : mgroup._ctors;
	size_t cidx;

	ModuleInfo*[] mods = mgroup._modules;
	size_t idx;
	while (true)
	{
		while (idx < mods.length)
		{
			auto m = mods[idx];
			auto fl = m.flags;
			if (fl & MIctorstart)
			{
				// trace back to cycle start
				fl &= ~MIctorstart;
				size_t start = stackidx;
				while (start--)
				{
					auto sm = stack[start].mod;
					if (sm == m)
						break;
					fl |= sm.flags & MIctorstart;
				}
				assert(stack[start].mod == m);
				if (fl & MIctorstart)
				{
					/* This is an illegal cycle, no partial order can be established
					 * because the import chain have contradicting ctor/dtor
					 * constraints.
					 */
					onCycleError(stack[start .. stackidx]);
				}
				else
				{
					/* This is also a cycle, but the import chain does not constrain
					 * the order of initialization, either because the imported
					 * modules have no ctors or the ctors are standalone.
					 */
					++idx;
				}
			}
			else if (fl & MIctordone)
			{   // already visited => skip
				++idx;
			}
			else
			{
				if (fl & mask)
				{
					if (fl & MIstandalone || !m.importedModules.length)
					{   // trivial ctor => sort in
						ctors[cidx++] = m;
						m.flags = fl | MIctordone;
					}
					else
					{   // non-trivial ctor => defer
						m.flags = fl | MIctorstart;
					}
				}
				else    // no ctor => mark as visited
					m.flags = fl | MIctordone;

				if (m.importedModules.length)
				{
					/* Internal runtime error, dependency on an uninitialized
					 * module outside of the current module group.
					 */
					(stackidx < mgroup._modules.length) || assert(0);

					// recurse
					stack[stackidx++] = StackRec(mods, idx);
					idx  = 0;
					mods = m.importedModules;
				}
			}
		}

		if (stackidx)
		{   // pop old value from stack
			--stackidx;
			mods    = stack[stackidx]._mods;
			idx     = stack[stackidx]._idx;
			auto m  = mods[idx++];
			auto fl = m.flags;
			if (fl & mask && !(fl & MIctordone))
				ctors[cidx++] = m;
			m.flags = (fl & ~MIctorstart) | MIctordone;
		}
		else // done
			break;
	}
	// store final number
	tlsPass ? mgroup._tlsctors : mgroup._ctors = ctors[0 .. cidx];

	// clean flags
	foreach(m; mgroup._modules)
		m.flags = m.flags & ~(MIctorstart | MIctordone);

	// rerun for TLS constructors
	if (!tlsPass)
	{
		tlsPass = true;
		goto Lagain;
	}
}

void runModuleFuncs(alias getfp)(ModuleInfo*[] modules)
{
	foreach (m; modules)
	{
		if (auto fp = getfp(m))
			(*fp)();
	}
}

void runModuleFuncsRev(alias getfp)(ModuleInfo*[] modules)
{
	foreach_reverse (m; modules)
	{
		if (auto fp = getfp(m))
			(*fp)();
	}
}

