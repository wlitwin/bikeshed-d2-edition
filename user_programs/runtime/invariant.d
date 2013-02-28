// NOTE: Can't put module name, as it's a keyword apparently...

/**
 *
 */
void _d_invariant(Object o)
{   
	ClassInfo c;

	//printf("__d_invariant(%p)\n", o);

	// BUG: needs to be filename/line of caller, not library routine
	assert(o !is null); // just do null check, not invariant check

	c = o.classinfo;
	do
	{
		if (c.classInvariant)
		{
			(*c.classInvariant)(o);
		}
		c = c.base;
	} while (c);
}

/**
 *
 */
extern (C) void _d_invariant(Object o)
{  
	ClassInfo c;

	//printf("__d_invariant(%p)\n", o);

	// BUG: needs to be filename/line of caller, not library routine
	assert(o !is null); // just do null check, not invariant check

	c = o.classinfo;
	do
	{
		if (c.classInvariant)
		{
			(*c.classInvariant)(o);
		}
		c = c.base;
	} while (c);
}
