module glue;

/* This module ties the runtime to the kernel.
 * It fills in functionality required by the
 * runtime, but in kernel space.
 */

import kernel.layer0.support : panic;

extern(C)
{
	void _d_array_bounds(ModuleInfo* m, uint line)
	{
		panic("Array out of bounds ", m.name, " ", line);
	}

	void _d_assert(string file, uint line)
	{
		panic("Assert: ", file, " ", line);
	}

	void _d_assert_msg(string msg, string file, uint line)
	{
		panic("Assert: ", msg, " ", file, " ", line);
	}

	void _d_assertm(ModuleInfo* m, uint line)
	{
		panic("Assert: ", m.name, " ", line);
	}

	void _d_unittestm(ModuleInfo* m, uint line)
	{
		panic("Unit test failed: ", m.name, " ", line);
	}
	
	@system nothrow      void*  memcpy (void* s1, in void* s2, size_t n);
	@system nothrow      void   free   (void* ptr);
	@system nothrow pure int    memcmp (in void* s1, in void* s2, size_t n);
	@system nothrow pure size_t strlen (in char* s);
	@system nothrow      void*  malloc (size_t size);
	@system nothrow      void*  alloca (size_t size);
}
