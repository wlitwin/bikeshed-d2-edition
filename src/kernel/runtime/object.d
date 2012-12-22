module object;

import glue;
import utils.hash;
import utils.string;
import utils.minfo;


extern (C) Object _d_newclass(const TypeInfo_Class ci) nothrow;
/+extern (C) void  _d_arrayshrinkfit(const TypeInfo ti, void[] arr);
extern (C) size_t _d_arraysetcapacity(const TypeInfo ti, size_t newcapacity, void* arrptr) pure nothrow; 
+/
alias bool bit;

alias typeof(int.sizeof) size_t;
alias typeof(cast(void*)0 - cast(void*)0) ptrdiff_t;

alias immutable(char)[]  string;
alias immutable(wchar)[] wstring;
alias immutable(dchar)[] dstring;

alias size_t hash_t;

class Object
{
nothrow:
	string toString() nothrow
	{
		return this.classinfo.name;
	}

	size_t toHash() @trusted nothrow
	{
		return cast(size_t)cast(void*)this;
	}

	int opCmp(Object o) nothrow
	{
		return cast(int)cast(void*)this - cast(int)cast(void*)o;
	}

	bool opEquals(Object o) nothrow
	{
		return this is o;
	}

	bool opEquals(Object lhs, Object rhs) nothrow
	{
		if (lhs is rhs)
			return true;
		if (lhs is null || rhs is null)
			return false;
		if (typeid(lhs) == typeid(rhs))
			return lhs.opEquals(rhs);

		return lhs.opEquals(rhs) &&
			   rhs.opEquals(lhs);
	}

	interface Monitor
	{
		void lock();
		void unlock();
	}

	static Object factory(string classname)
	{
		auto ci = TypeInfo_Class.find(classname);
		if (ci)
		{
			return ci.create();
		}

		return null;
	}
}

bool opEquals(const Object lhs, const Object rhs) nothrow
{
	// A hack at the moment
	return opEquals(cast()lhs, cast()rhs);
}

bool opEquals(Object lhs, Object rhs) nothrow
{
	// If aliased to the same object or both null => equal
	if (lhs is rhs) return true;

	// If either is null => not equal
	if (lhs is null || rhs is null) return false;

	// If same exact type => one call to method opEquals
	if (typeid(lhs) is typeid(rhs) || typeid(lhs).opEquals(typeid(rhs)))
	{
		return lhs.opEquals(rhs);
	}

	// General case => symmetric calls to method opEquals
	return lhs.opEquals(rhs) && rhs.opEquals(lhs);
}

bool opEquals(TypeInfo lhs, TypeInfo rhs) nothrow
{
	// If aliased to the same object or both null => equal
	if (lhs is rhs) return true;

	// If either is null => not equal
	if (lhs is null || rhs is null) return false;

	// If same exact type => one call to opEquals
	if (typeid(lhs) == typeid(rhs)) return lhs.opEquals(rhs);

	// Factor out top level const
	TypeInfo_Const c = cast(TypeInfo_Const) lhs;
	if (c)
	{
		lhs = c.base;
	}

	c = cast(TypeInfo_Const) rhs;
	if (c)
	{
		rhs = c.base;
	}

	// General case => symmetric calls to method opEquals
	return lhs.opEquals(rhs) && rhs.opEquals(lhs);
}

/**
 * Information about an interface.
 * When an object is accessed via an interface, an Interface* appears
 * as the first entry in the vtable.
 */
struct Interface
{
	TypeInfo_Class classinfo; /// .classinfo for this interface (not for containing class)
	void*[] vtbl;
	ptrdiff_t offset; /// Offset to Interface 'this' from Object 'this'
}

/**
 * Runtime type information about a class. Can be retrieved for any class
 * type or instance by using the .classinfo property.
 * A pointer to this appears as the first entry in the class's vtbl[].
 */
alias TypeInfo_Class ClassInfo;

/**
 * Array of pairs giving the offset and type information for each
 * member in an aggregate.
 */
struct OffsetTypeInfo
{
	size_t offset; /// Offset of member from start of object
	TypeInfo ti;   /// TypeInfo for this member
}



/**
 * Runtime type information about a type.
 * Can be retrieved for any type using a typeid expression
 */
class TypeInfo
{
nothrow:
	override string toString() const nothrow
	{
		// hack to keep const qualifiers for TypeInfo member functions
		return (cast()super).toString();
	}

	override size_t toHash() @trusted const nothrow
	{
		auto data = this.toString();
		return hashOf(data.ptr, data.length);
	}

	override int opCmp(Object o) nothrow
	{
		if (this is o)
			return 0;

		TypeInfo ti = cast(TypeInfo)o;
		if (ti is null)
			return 1;

		return dstrcmp(this.toString(), ti.toString());
	}

	override bool opEquals(Object o)
	{
		/* TypeInfo instances are singletons, but duplicates
		 * can exist across DLL's. Therefore comparing for a name match
		 * is sufficient
		 */
		if (this is o)
			return true;

		auto ti = cast(const TypeInfo)o;
		return ti && this.toString() == ti.toString();
	}

	/// Returns hash of the instance of a type
	size_t getHash(in void* p) @trusted nothrow const
	{
		return cast(size_t)p;
	}

	/// Compares two instances for equality
	bool equals(in void* p1, in void* p2) const nothrow
	{
		return p1 == p2;
	}

	/// Compares two instances for <, ==, >
	int compare(in void* p1, in void* p2) const nothrow
	{
		return 0;
	}

	/// Returns size of the type
	size_t tsize() nothrow pure const @safe @property
	{
		return 0;
	}
	
	/// Swaps two instances of the type
	void swap(void* p1, void* p2) const nothrow
	{
		size_t n = tsize;
		for (size_t i = 0; i < n; ++i)
		{
			byte t = (cast(byte *)p1)[i];
			(cast(byte *)p1)[i] = (cast(byte *)p2)[i];
			(cast(byte *)p1)[i] = t;
		}
	}

	/// Get TypeInfo for 'next' type, as defined by what kind of type this is,
	/// null if none
	const(TypeInfo) next() const pure nothrow @property
	{
		return null;
	}

	/// Return the default initializer. If the type should be initialized
	/// to all zeros, an array with a null ptr and a length equal to the
	/// type size will be returned. 
	/// TODO make property, but conflicts with T.init
	const(void)[] init() pure nothrow const @safe
	{
		return null;
	}

	/// Get flags for type: 1 means GC shuold scan for pointers
	uint flags() nothrow pure const @safe
	{
		return 0;
	}

	/// Get type information on the contents of the type; null if not
	/// available
	const(OffsetTypeInfo)[] offTi() const nothrow
	{
		return null;
	}

	/// Run the destructor on the object and all its sub-objects
	void destroy(void* p) const nothrow
	{ }

	/// Run the postblit on the object and all its sub-objects
	void postblit(void* p) const nothrow
	{ }

	/// Return alignedment of type
	size_t talign() const pure nothrow @property @safe
	{
		return tsize;
	}

	/// Return internal info on arguments fitting into 8byte
	/// See X86-64 ABI 3.2.3
	version (X86_64)
	{
		int argTypes(out TypeInfo arg1, out TypeInfo arg2) @safe nothrow
		{
			arg1 = this;
			return 0;
		}
	}

	@property immutable(void)* rtInfo() nothrow pure const @safe
	{
		return null;
	}
}

class TypeInfo_Vector : TypeInfo
{
nothrow:
	override string toString() const nothrow
	{
		return "__vector(" ~ base.toString() ~ ")";
	}

	override bool opEquals(Object o) nothrow
	{
		if (this is o)
			return true;
		
		auto c = cast(const TypeInfo_Vector)o;
		return c && this.base == c.base;
	}

	override size_t getHash(in void* p) const nothrow
	{
		return base.getHash(p);
	}

	override bool equals(in void* p1, in void* p2) const nothrow
	{
		return base.equals(p1, p2);
	}

	override int compare(in void* p1, in void* p2) const nothrow
	{
		return base.compare(p1, p2);
	}

	override size_t tsize() const pure nothrow @property
	{
		return base.tsize;
	}

	override void swap(void* p1, void* p2) const nothrow
	{
		return base.swap(p1, p2);
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return base.next;
	}

	override uint flags() const pure nothrow @property
	{
		return base.flags;
	}

	override const(void)[] init() const pure nothrow
	{
		return base.init();
	}

	override size_t talign() const pure nothrow @property
	{
		return 16;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			return base.argTypes(arg1, arg2);
		}
	}

	TypeInfo base;
}

class TypeInfo_Typedef : TypeInfo
{
nothrow:
	override string toString() const
	{
		return name;
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		auto c = cast(const TypeInfo_Typedef)o;
		return c && this.name == c.name
				 && this.base == c.base;
	}

	override size_t getHash(in void* p) const
	{
		return base.getHash(p);
	}

	override bool equals(in void* p1, in void* p2) const
	{
		return base.equals(p1, p2);
	}

	override int compare(in void* p1, in void* p2) const
	{
		return base.compare(p1, p2);
	}

	override size_t tsize() const pure nothrow @property
	{
		return base.tsize;
	}

	override void swap(void* p1, void* p2) const
	{
		return base.swap(p1, p2);
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return base.next;
	}

	override uint flags() const pure nothrow @property
	{
		return base.flags;
	}

	override const(void)[] init() const pure nothrow @safe
	{
		return m_init.length ? m_init : base.init();
	}

	override size_t talign() const pure nothrow @property
	{
		return base.talign;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			return base.argTypes(arg1, arg2);
		}
	}

	TypeInfo base;
	string   name;
	void[]   m_init;

	override @property immutable(void)* rtInfo() const
	{
		return base.rtInfo;
	}
}

class TypeInfo_Enum : TypeInfo_Typedef
{ }

class TypeInfo_Pointer : TypeInfo
{
nothrow:
	override string toString() const
	{
		return m_next.toString() ~ "*";
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		auto c = cast(const TypeInfo_Pointer)o;
		return c && this.m_next == c.m_next;
	}
	
	override size_t getHash(in void* p) @trusted const
	{
		return cast(size_t)*cast(void**)p;
	}

	override bool equals(in void* p1, in void* p2) const
	{
		return *cast(void**)p1 == *cast(void**)p2;
	}

	override int compare(in void* p1, in void* p2) const
	{
		if (*cast(void**)p1 < *cast(void**)p2)
		{
			return -1;
		}
		else if (*cast(void**)p1 > *cast(void**)p2)
		{
			return 1;
		}
		else
			return 0;
	}

	override size_t tsize() const pure nothrow @property
	{
		return (void*).sizeof;
	}

	override void swap(void* p1, void* p2) const
	{
		void* tmp = *cast(void**)p1;
		*cast(void**)p1 = *cast(void**)p2;
		*cast(void**)p2 = tmp;
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return m_next;
	}

	override uint flags() const pure nothrow @property
	{
		return 1; // Doesn't do anything, no garbage collector!
	}

	TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
nothrow:
	override string toString() const
	{
		return value.toString() ~ "[]";
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		auto c = cast(const TypeInfo_Array)o;
		return c && this.value == c.value;
	}

	override size_t getHash(in void* p) @trusted const
	{
		void[] a = *cast(void[]*)p;
		return hashOf(a.ptr, a.length * value.tsize);
	}

	override bool equals(in void* p1, in void* p2) const
	{
		void[] a1 = *cast(void[]*)p1;
		void[] a2 = *cast(void[]*)p2;
		if (a1.length != a2.length)
			return false;

		size_t sz = value.tsize;
		for (size_t i = 0; i < a1.length; ++i)
		{
			if (!value.equals(a1.ptr + i*sz, a2.ptr + i*sz))
			{
				return false;
			}
		}

		return true;
	}

	override int compare(in void* p1, in void* p2) const
	{
		void[] a1 = *cast(void[]*)p1;
		void[] a2 = *cast(void[]*)p2;
		size_t sz  = value.tsize;
		size_t len = a1.length;

		if (a2.length < len)
		{
			len = a2.length;
		}

		for (size_t u = 0; u < len; ++u)
		{
			int result = value.compare(a1.ptr + u*sz, a2.ptr + u*sz);
			if (result)
				return result;
		}

		return cast(int)a1.length - cast(int)a2.length;
	}

	override size_t tsize() const pure nothrow @property
	{
		return (void[]).sizeof;
	}

	override void swap(void* p1, void* p2) const
	{
		void[] tmp = *cast(void[]*)p1;
		*cast(void[]*)p1 = *cast(void[]*)p2;
		*cast(void[]*)p2 = tmp;
	}

	TypeInfo value;

	override const(TypeInfo) next() const pure nothrow @property
	{
		return value;
	}

	override uint flags() const pure nothrow @property
	{
		return 1; /// Does nothing, no garbage collector!
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			arg1 = typeid(size_t);
			arg2 = typeid(void*);

			return 0;
		}
	}
}

class TypeInfo_StaticArray : TypeInfo
{
nothrow:
	override string toString() const
	{
		char[20] tmp = void;
		return cast(string)(value.toString() ~ "[" ~ tmp.intToString(len) ~ "]");
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;
		
		auto c = cast(const TypeInfo_StaticArray)o;
		return c && this.len == c.len
				 && this.value == c.value;
	}

	override size_t getHash(in void* p) @trusted const
	{
		size_t sz = value.tsize;
		size_t hash = 0;
		for (size_t i = 0; i < len; ++i)
		{
			hash += value.getHash(p + i*sz);
		}
		return hash;
	}
	
	override bool equals(in void* p1, in void* p2) const
	{
		size_t sz = value.tsize;
		
		for (size_t u = 0; u < len; ++u)
		{
			if (!value.equals(p1 + u*sz, p2 + u*sz))
			{
				return false;
			}
		}

		return true;
	}

	override int compare(in void* p1, in void* p2) const
	{
		size_t sz = value.tsize;

		for (size_t u = 0; u < len; ++u)
		{
			int result = value.compare(p1 + u*sz, p2 + u*sz);
			if (result)
			{
				return result;
			}
		}

		return 0;
	}

	override size_t tsize() const pure nothrow @property
	{
		return len * value.tsize;
	}

	override void swap(void* p1, void* p2) const
	{
		void* tmp;
		size_t sz = value.tsize;
		ubyte[16] buffer;
		void* pbuffer;

		if (sz < buffer.sizeof)
			tmp = buffer.ptr;
		else
			tmp = pbuffer = (new void[sz]).ptr;

		for (size_t u = 0; u < len; u += sz)
		{
			size_t o = u * sz;
			memcpy(tmp, p1 + o, sz);
			memcpy(p1 + o, p2 + o, sz);
			memcpy(p2 + o, tmp, sz);
		}

		if (pbuffer)
		{
			free(pbuffer);
		}
	}

	override const(void)[] init() const pure nothrow
	{
		return value.init();
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return value;
	}

	override uint flags() const pure nothrow @property
	{
		return value.flags;
	}

	override void destroy(void* p) const
	{
		auto sz = value.tsize;
		p += sz * len;
		foreach (i; 0 .. len)
		{
			p -= sz;
			value.destroy(p);
		}
	}

	override void postblit(void* p) const
	{
		auto sz = value.tsize;
		foreach (i; 0 .. len)
		{
			value.postblit(p);
			p += sz;
		}
	}

	TypeInfo value;
	size_t   len;

	override size_t talign() const pure nothrow @property
	{
		return value.talign;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			arg1 = typeid(void*);
			return 0;
		}
	}
}


// XXX - This data structure will have a custom implementation
class TypeInfo_AssociativeArray : TypeInfo
{
nothrow:
	override string toString() const
	{
		return cast(string)(next.toString() ~ "[" ~ key.toString() ~ "]");
	}

	override bool opEquals(Object o)
	{
		if (this is o)
		{
			return true;
		}

		auto c = cast(const TypeInfo_AssociativeArray)o;
		return c && this.key == c
				 && this.value == c.value;
	}

	override hash_t getHash(in void* p) @trusted nothrow
	{
		return 0;//_aaGetHash(cast(void*)p, this);
	}

	override size_t tsize() const pure nothrow
	{
		return (char[int]).sizeof;
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return value;
	}

	override uint flags() const pure nothrow @property
	{
		return 1;
	}

	TypeInfo value;
	TypeInfo key;

	TypeInfo impl;

	override size_t talign() const pure nothrow @property
	{
		return (char[int]).alignof;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			arg1 = typeid(void*);
			return 0;
		}
	}
}

class TypeInfo_Function : TypeInfo
{
nothrow:
	override string toString() const
	{
		return cast(string)(next.toString() ~ "()");
	}

	override bool opEquals(Object o)
	{
		if (this is o)
		{
			return true;
		}

		auto c = cast(const TypeInfo_Function)o;
		return c && this.deco == c.deco;
	}

	// TODO - Add rest of the functions
	override size_t tsize() const pure nothrow @property
	{
		return 0; // No size for functions
	}

	TypeInfo next;
	string deco;
}

class TypeInfo_Delegate : TypeInfo
{
nothrow:
	override string toString() const
	{
		return cast(string)(next.toString() ~ " delegate()");
	}

	override bool opEquals(Object o)
	{
		if (this is o)
		{
			return true;
		}

		auto c = cast(const TypeInfo_Delegate)o;
		return c && this.deco == c.deco;
	}

	// TODO - Add the rest of the functions
	override size_t tsize() const pure nothrow @property
	{
		alias int delegate() dg;
		return dg.sizeof;
	}

	override uint flags() const pure nothrow @property
	{
		return 1;
	}

	TypeInfo next;
	string deco;

	override size_t talign() const pure nothrow
	{
		alias int delegate() dg;
		return dg.alignof;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			arg1 = typeid(void*);
			arg2 = typeid(void*);
			return 0;
		}
	}
}

/**
 * Runtime type information about a class.
 * Can be retrieved from an object instance by using the
 * .classinfo property
 */
class TypeInfo_Class : TypeInfo
{
nothrow:
	override string toString() const
	{
		return info.name;
	}

	override bool opEquals(Object o)
	{
		if (this is o)
		{
			return true;
		}

		auto c = cast(const TypeInfo_Class)o;
		return c && this.info.name == c.info.name;
	}

	override size_t getHash(in void* p) @trusted const
	{
		auto o = *cast(Object*)p;
		return o ? o.toHash() : 0;
	}

	override bool equals(in void* p1, in void* p2) const
	{
		Object o1 = *cast(Object*)p1;
		Object o2 = *cast(Object*)p2;

		return (o1 is o2) || (o1 && o1.opEquals(o2));
	}

	override int compare(in void* p1, in void* p2) const
	{
		Object o1 = *cast(Object*)p1;
		Object o2 = *cast(Object*)p2;
		int c = 0;

		// Regard null references as always being "less than"
		if (o1 !is o2)
		{
			if (o1)
			{
				if (!o2)
					c = 1;
				else
					c = o1.opCmp(o2);
			}
			else
				c = -1;
		}

		return c;
	}

	override size_t tsize() const pure nothrow @property
	{
		return Object.sizeof;
	}

	override uint flags() const pure nothrow @property
	{
		return 1;
	}

	override const (OffsetTypeInfo)[] offTi() const pure nothrow @property
	{
		return m_offTi;
	}

	auto info() @safe const pure nothrow @property
	{
		return this;
	}

	auto typeInfo() @safe const pure nothrow @property
	{
		return this;
	}

	byte[] init; /// Class static initializer
	string name;
	void*[] vtbl;
	Interface[] interfaces;
	TypeInfo_Class base;
	void* destructor;
	void function(Object) classInvariant;
	uint m_flags;
	void* deallocator;
	OffsetTypeInfo[] m_offTi;
	void function(Object) defaultConstructor;

	immutable(void)* m_RTInfo;
	override @property immutable(void)* rtInfo() const
	{
		return m_RTInfo;
	}

	static const(TypeInfo_Class) find(in char[] classname) nothrow
	{
		auto val = ModuleInfo();
		pragma(msg, "VALS TYPE IS!!!!!!!!!!!!!!!!!!!");
		pragma(msg, typeof(val));
		pragma(msg, "TODO: Figure out what's really happening here!");
		foreach (c; val.localClasses)
		{
			if (c.name == classname)
			{
				return c;
			}
		}
			
		/*foreach (m; ModuleInfo)
		{
			if (m)
			{
				foreach (c; m.localClasses)
				{
					if (c.name == classname)
						return c;
				}
			}
		}
		*/

		return null;
	}

	Object create() const
	{
		if (m_flags & 8 && !defaultConstructor)
			return null;
		if (m_flags & 64) // Abstract
			return null;
		Object o = _d_newclass(this);
		if (m_flags & 8 && defaultConstructor)
		{
			defaultConstructor(o);
		}

		return o;
	}

}

class TypeInfo_Interface : TypeInfo
{
nothrow:
	override string toString() const
	{
		return info.name;
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		auto c = cast(const TypeInfo_Interface)o;
		return c && this.info.name == c.classinfo.name;
	}

	override size_t getHash(in void* p) @trusted const
	{
		Interface* pi = **cast(Interface ***)*cast(void**)p;
		Object o = cast(Object)(*cast(void**)p - pi.offset);
		assert(o);
		return o.toHash();
	}

	override bool equals(in void* p1, in void* p2) const
	{
		Interface* pi = **cast(Interface ***)*cast(void**)p1;
		Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
		pi = **cast(Interface ***)*cast(void**)p2;
		Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);

		return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
	}

	override int compare(in void* p1, in void* p2) const
	{
		Interface* pi = **cast(Interface ***)*cast(void**)p1;
		Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
		pi = **cast(Interface ***)*cast(void**)p2;
		Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
		int c = 0;

		// Regard null references as always being "less than"
		if (o1 != o2)
		{
			if (o1)
			{
				if (!o2)
					c = 1;
				else
					c = o1.opCmp(o2);
			}
			else
				c = -1;
		}

		return c;
	}

	override size_t tsize() const pure nothrow @property
	{
		return Object.sizeof;
	}

	override uint flags() const pure nothrow @property
	{
		return 1;
	}

	TypeInfo_Class info;
}

class TypeInfo_Struct : TypeInfo
{
nothrow:
	override string toString() const
	{
		return name;
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;
		auto s = cast(const TypeInfo_Struct)o;
		return s && this.name == s.name 
				 && this.init().length == s.init().length;
	}

	override size_t getHash(in void* p) @safe const pure nothrow	
	{
		assert(p);
		if (xtoHash)
		{
			return (*xtoHash)(p);
		}
		else
		{
			return hashOf(p, init().length);
		}
	}

	override bool equals(in void* p1, in void* p2) @trusted const pure nothrow
	{
		if (!p1 || !p2)
			return false;
		else if (xopEquals)
			return (*xopEquals)(p1, p2);
		else if (p1 == p2)
			return true;
		else
			return memcmp(p1, p2, init().length) == 0;
	}

	override int compare(in void* p1, in void* p2) @trusted const pure nothrow
	{
		// Regard null references as always being "less than"
		if (p1 != p2)
		{
			if (p1)
			{
				if (!p2)
					return true;
				else if (xopCmp)
					return (*xopCmp)(p2, p1);
				else
					return memcmp(p1, p2, init().length);
			}
			else
				return -1;
		}

		return 0;
	}

	override size_t tsize() const pure nothrow @property
	{
		return init().length;
	}

	override const(void)[] init() @safe const pure nothrow 
	{
		return m_init;
	}

	override uint flags() const pure nothrow @property
	{
		return m_flags;
	}

	override size_t talign() const pure nothrow @property
	{
		return m_align;
	}

	override void destroy(void* p) const
	{
		if (xdtor)
			(*xdtor)(p);
	}

	override void postblit(void* p) const
	{
		if (xpostblit)
			(*xpostblit)(p);
	}

	string name;
	void[] m_init; // Initializer; init.ptr == null if 0 initialize

	@safe pure nothrow
	{
		size_t function(in void*)           xtoHash;
		bool   function(in void*, in void*) xopEquals;
		int    function(in void*, in void*) xopCmp;
		char[] function(in void*)           xtoString;

		uint m_flags;
	}

	void function(void*) xdtor;
	void function(void*) xpostblit;

	uint m_align;

	immutable(void)* m_RTInfo;
	override @property immutable(void)* rtInfo() const
	{
		return m_RTInfo;
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			arg1 = m_arg1;
			arg2 = m_arg2;
			return 0;
		}

		TypeInfo m_arg1;
		TypeInfo m_arg2;
	}
}

class TypeInfo_Tuple : TypeInfo
{
nothrow:
	TypeInfo[] elements;

	override string toString() const
	{
		string s = "(";
		foreach (i, element; elements)
		{
			if (i)
				s ~= ',';
			s ~= element.toString();
		}
		s ~= ")";

		return s;
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		auto t = cast(const TypeInfo_Tuple)o;
		if (t && elements.length == t.elements.length)
		{
			for (size_t i = 0; i < elements.length; ++i)
			{
				if (elements[i] != t.elements[i])
					return false;
			}

			return true;
		}

		return false;
	}

	override size_t getHash(in void* p) const
	{
		assert(0);
	}

	override bool equals(in void* p1, in void* p2) const
	{
		assert(0);
	}

	override int compare(in void* p1, in void* p2) const
	{
		assert(0);
	}

	override size_t tsize() const pure nothrow @property
	{
		assert(0);
	}

	override void swap(void* p1, void* p2) const
	{
		assert(0);
	}

	override void destroy(void* p) const
	{
		assert(0);
	}

	override void postblit(void* p) const
	{
		assert(0);
	}

	override size_t talign() const pure nothrow @property
	{
		assert(0);
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			assert(0);
		}
	}
}

class TypeInfo_Const : TypeInfo
{
nothrow:
	override string toString() const	
	{
		return cast(string) ("const(" ~ base.toString() ~ ")");
	}

	override bool opEquals(Object o)
	{
		if (this is o)
			return true;

		if (typeid(this) != typeid(o))
			return false;

		auto t = cast(TypeInfo_Const)o;
		return base.opEquals(t.base);
	}

	override size_t getHash(in void* p) const
	{
		return base.getHash(p);
	}

	override bool equals(in void* p1, in void* p2) const
	{
		return base.equals(p1, p2);
	}

	override int compare(in void* p1, in void* p2) const
	{
		return base.compare(p1, p2);
	}

	override size_t tsize() const pure nothrow @property
	{
		return base.tsize;
	}

	override void swap(void* p1, void* p2) const
	{
		return base.swap(p1, p2);
	}

	override const(TypeInfo) next() const pure nothrow @property
	{
		return base.next;
	}

	override uint flags() const pure nothrow @property
	{
		return base.flags;
	}

	override const(void)[] init() nothrow pure const
	{
		return base.init();
	}

	override size_t talign() const pure nothrow @property
	{
		return base.talign();
	}

	version (X86_64)
	{
		override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
		{
			return base.argTypes(arg1, arg2);
		}
	}

	TypeInfo base;
}

class TypeInfo_Invariant : TypeInfo_Const
{
nothrow:
	override string toString() const
	{
		return cast(string)("immutable(" ~ base.toString() ~ ")");
	}
}

class TypeInfo_Shared : TypeInfo_Const
{
nothrow:
	override string toString() const
	{
		return cast(string)("shared(" ~ base.toString() ~ ")");
	}
}

class TypeInfo_Inout : TypeInfo_Const
{
nothrow:
	override string toString() const
	{
		return cast(string)("inout(" ~ base.toString() ~ ")");
	}
}

abstract class MemberInfo
{
	string name() const pure nothrow @property;
}

class MemberInfo_field : MemberInfo
{
nothrow:
	this(string name, TypeInfo ti, size_t offset)
	{
		m_name = name;
		m_typeinfo = ti;
		m_offset = offset;
	}

	override string name() const pure nothrow @property
	{
		return m_name;
	}

	TypeInfo typeInfo() pure nothrow @property
	{
		return m_typeinfo;
	}

	size_t offset() pure nothrow @property
	{
		return m_offset;
	}

	string   m_name;
	TypeInfo m_typeinfo;
	size_t   m_offset;
}

class MemberInfo_function : MemberInfo
{
nothrow:
	this(string name, TypeInfo ti, void* fp, uint flags)
	{
		m_name = name;
		m_typeinfo = ti;
		m_fp = fp;
		m_flags = flags;
	}

	override string name() pure nothrow @property
	{
		return m_name;
	}

	TypeInfo typeinfo() pure nothrow @property
	{
		return m_typeinfo;
	}

	void* fp() pure nothrow @property
	{
		return m_fp;
	}

	uint flags() pure nothrow @property
	{
		return m_flags;
	}

	string   m_name;
	TypeInfo m_typeinfo;
	void*    m_fp;
	uint     m_flags;
}

///////////////////////////////////////////////////////////////////////////////
// ModuleInfo
///////////////////////////////////////////////////////////////////////////////

enum
{
    MIctorstart  = 1,   // we've started constructing it
    MIctordone   = 2,   // finished construction
    MIstandalone = 4,   // module ctor does not depend on other module
                        // ctors being done first
    MItlsctor    = 8,
    MItlsdtor    = 0x10,
    MIctor       = 0x20,
    MIdtor       = 0x40,
    MIxgetMembers = 0x80,
    MIictor      = 0x100,
    MIunitTest   = 0x200,
    MIimportedModules = 0x400,
    MIlocalClasses = 0x800,
    MInew        = 0x80000000        // it's the "new" layout
}

struct ModuleInfo
{
nothrow:
    struct New
    {
        uint flags;
        uint index;                        // index into _moduleinfo_array[]

        /* Order of appearance, depending on flags
         * tlsctor
         * tlsdtor
         * xgetMembers
         * ctor
         * dtor
         * ictor
         * importedModules
         * localClasses
         * name
         */
    }
    struct Old
    {
        string          name;
        ModuleInfo*[]    importedModules;
        TypeInfo_Class[]     localClasses;
        uint            flags;

        void function() ctor;       // module shared static constructor (order dependent)
        void function() dtor;       // module shared static destructor
        void function() unitTest;   // module unit tests

        void* xgetMembers;          // module getMembers() function

        void function() ictor;      // module shared static constructor (order independent)

        void function() tlsctor;        // module thread local static constructor (order dependent)
        void function() tlsdtor;        // module thread local static destructor

        uint index;                        // index into _moduleinfo_array[]

        void*[1] reserved;          // for future expansion
    }

    union
    {
        New n;
        Old o;
    }

    @property bool isNew() nothrow pure { return (n.flags & MInew) != 0; }

    @property uint index() nothrow pure { return isNew ? n.index : o.index; }
    @property void index(uint i) nothrow pure { if (isNew) n.index = i; else o.index = i; }

    @property uint flags() nothrow pure { return isNew ? n.flags : o.flags; }
    @property void flags(uint f) nothrow pure { if (isNew) n.flags = f; else o.flags = f; }

    @property void function() tlsctor() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MItlsctor)
            {
                size_t off = New.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        else
            return o.tlsctor;
    }

    @property void function() tlsdtor() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MItlsdtor)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        else
            return o.tlsdtor;
    }

    @property void* xgetMembers() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIxgetMembers)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        return o.xgetMembers;
    }

    @property void function() ctor() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIctor)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        return o.ctor;
    }

    @property void function() dtor() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIdtor)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                if (n.flags & MIctor)
                    off += o.ctor.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        return o.ctor;
    }

    @property void function() ictor() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIictor)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                if (n.flags & MIctor)
                    off += o.ctor.sizeof;
                if (n.flags & MIdtor)
                    off += o.ctor.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        return o.ictor;
    }

    @property void function() unitTest() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIunitTest)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                if (n.flags & MIctor)
                    off += o.ctor.sizeof;
                if (n.flags & MIdtor)
                    off += o.ctor.sizeof;
                if (n.flags & MIictor)
                    off += o.ictor.sizeof;
                return *cast(typeof(return)*)(cast(void*)(&this) + off);
            }
            return null;
        }
        return o.unitTest;
    }

    @property ModuleInfo*[] importedModules() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIimportedModules)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                if (n.flags & MIctor)
                    off += o.ctor.sizeof;
                if (n.flags & MIdtor)
                    off += o.ctor.sizeof;
                if (n.flags & MIictor)
                    off += o.ictor.sizeof;
                if (n.flags & MIunitTest)
                    off += o.unitTest.sizeof;
                auto plength = cast(size_t*)(cast(void*)(&this) + off);
                ModuleInfo** pm = cast(ModuleInfo**)(plength + 1);
                return pm[0 .. *plength];
            }
            return null;
        }
        return o.importedModules;
    }

    @property TypeInfo_Class[] localClasses() nothrow pure
    {
        if (isNew)
        {
            if (n.flags & MIlocalClasses)
            {
                size_t off = New.sizeof;
                if (n.flags & MItlsctor)
                    off += o.tlsctor.sizeof;
                if (n.flags & MItlsdtor)
                    off += o.tlsdtor.sizeof;
                if (n.flags & MIxgetMembers)
                    off += o.xgetMembers.sizeof;
                if (n.flags & MIctor)
                    off += o.ctor.sizeof;
                if (n.flags & MIdtor)
                    off += o.ctor.sizeof;
                if (n.flags & MIictor)
                    off += o.ictor.sizeof;
                if (n.flags & MIunitTest)
                    off += o.unitTest.sizeof;
                if (n.flags & MIimportedModules)
                {
                    auto plength = cast(size_t*)(cast(void*)(&this) + off);
                    off += size_t.sizeof + *plength * plength.sizeof;
                }
                auto plength = cast(size_t*)(cast(void*)(&this) + off);
                TypeInfo_Class* pt = cast(TypeInfo_Class*)(plength + 1);
                return pt[0 .. *plength];
            }
            return null;
        }
        return o.localClasses;
    }

    @property string name() nothrow pure
    {
        if (isNew)
        {
            size_t off = New.sizeof;
            if (n.flags & MItlsctor)
                off += o.tlsctor.sizeof;
            if (n.flags & MItlsdtor)
                off += o.tlsdtor.sizeof;
            if (n.flags & MIxgetMembers)
                off += o.xgetMembers.sizeof;
            if (n.flags & MIctor)
                off += o.ctor.sizeof;
            if (n.flags & MIdtor)
                off += o.ctor.sizeof;
            if (n.flags & MIictor)
                off += o.ictor.sizeof;
            if (n.flags & MIunitTest)
                off += o.unitTest.sizeof;
            if (n.flags & MIimportedModules)
            {
                auto plength = cast(size_t*)(cast(void*)(&this) + off);
                off += size_t.sizeof + *plength * plength.sizeof;
            }
            if (n.flags & MIlocalClasses)
            {
                auto plength = cast(size_t*)(cast(void*)(&this) + off);
                off += size_t.sizeof + *plength * plength.sizeof;
            }
            auto p = cast(immutable(char)*)(cast(void*)(&this) + off);
            auto len = strlen(p);
            return p[0 .. len];
        }
        return o.name;
    }

    alias int delegate(ref ModuleInfo*) ApplyDg;

    //static int opApply(scope ApplyDg dg)
    static int opApply(int delegate(ref ModuleInfo* __applyArg0) @system nothrow dg) nothrow
    {
        return moduleinfos_apply(dg);
    }
}


template RTInfo(T)
{
	enum RTInfo = null;
}

/+
extern (C)
{
    // from druntime/src/compiler/dmd/aaA.d

 /+   size_t _aaLen(void* p);
    void* _aaGet(void** pp, TypeInfo keyti, size_t valuesize, ...);
    void* _aaGetRvalue(void* p, TypeInfo keyti, size_t valuesize, ...);
    void* _aaIn(void* p, TypeInfo keyti);
    void _aaDel(void* p, TypeInfo keyti, ...);
    void[] _aaValues(void* p, size_t keysize, size_t valuesize);
    void[] _aaKeys(void* p, size_t keysize);
    void* _aaRehash(void** pp, TypeInfo keyti);

    extern (D) alias scope int delegate(void *) _dg_t;
    int _aaApply(void* aa, size_t keysize, _dg_t dg);

    extern (D) alias scope int delegate(void *, void *) _dg2_t;
    int _aaApply2(void* aa, size_t keysize, _dg2_t dg);

    void* _d_assocarrayliteralT(TypeInfo_AssociativeArray ti, size_t length, ...);
    hash_t _aaGetHash(void* aa, const(TypeInfo) tiRaw) nothrow;
+/
}

alias destroy clear;

/++
    Destroys the given object and puts it in an invalid state. It's used to
    destroy an object so that any cleanup which its destructor or finalizer
    does is done and so that it no longer references any other objects. It does
    $(I not) initiate a GC cycle or free any GC memory.
  +/
void destroy(T)(T obj) if (is(T == class))
{
    rt_finalize(cast(void*)obj);
}

void destroy(T)(T obj) if (is(T == interface))
{
    destroy(cast(Object)obj);
}

void destroy(T)(ref T obj) if (is(T == struct))
{
    typeid(T).destroy( &obj );
    auto buf = (cast(ubyte*) &obj)[0 .. T.sizeof];
    auto init = cast(ubyte[])typeid(T).init();
    if(init.ptr is null) // null ptr means initialize to 0s
        buf[] = 0;
    else
        buf[] = init[];
}

void destroy(T : U[n], U, size_t n)(ref T obj)
{
    obj = T.init;
}

void destroy(T)(ref T obj)
    if (!is(T == struct) && !is(T == interface) && !is(T == class) && !_isStaticArray!T)
{
    obj = T.init;
}

template _isStaticArray(T : U[N], U, size_t N)
{
    enum bool _isStaticArray = true;
}

template _isStaticArray(T)
{
    enum bool _isStaticArray = false;
}
/+
/**
 * (Property) Get the current capacity of an array.  The capacity is the number
 * of elements that the array can grow to before the array must be
 * extended/reallocated.
 */
@property size_t capacity(T)(T[] arr) pure nothrow
{
    return _d_arraysetcapacity(typeid(T[]), 0, cast(void *)&arr);
}

/**
 * Try to reserve capacity for an array.  The capacity is the number of
 * elements that the array can grow to before the array must be
 * extended/reallocated.
 *
 * The return value is the new capacity of the array (which may be larger than
 * the requested capacity).
 */
size_t reserve(T)(ref T[] arr, size_t newcapacity) pure nothrow
{
    return _d_arraysetcapacity(typeid(T[]), newcapacity, cast(void *)&arr);
}

/**
 * Assume that it is safe to append to this array.  Appends made to this array
 * after calling this function may append in place, even if the array was a
 * slice of a larger array to begin with.
 *
 * Use this only when you are sure no elements are in use beyond the array in
 * the memory block.  If there are, those elements could be overwritten by
 * appending to this array.
 *
 * Calling this function, and then using references to data located after the
 * given array results in undefined behavior.
 */
void assumeSafeAppend(T)(T[] arr)
{
    _d_arrayshrinkfit(typeid(T[]), *(cast(void[]*)&arr));
}
+/
///////////////////////////////////////////////////////////////////////////////
// Monitor
///////////////////////////////////////////////////////////////////////////////

//alias Object.Monitor IMonitor;
//alias void delegate(Object) DEvent;

// NOTE: The dtor callback feature is only supported for monitors that are not
//       supplied by the user.  The assumption is that any object with a user-
//       supplied monitor may have special storage or lifetime requirements and
//       that as a result, storing references to local objects within Monitor
//       may not be safe or desirable.  Thus, devt is only valid if impl is
//       null.
+/
