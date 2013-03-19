module glue;

/* This module ties the runtime to the kernel.
 * It fills in functionality required by the
 * runtime, but in kernel space.
 */

//import kernel.layer0.support : panic;

extern(C)
{
	void _d_array_bounds(ModuleInfo* m, uint line)
	{
		// TODO replace
		// panic("Array out of bounds ", m.name, " ", line);
		asm { cli; hlt; }
	}

	void _d_assert(string file, uint line)
	{
		// TODO replace
		// panic("Assert: ", file, " ", line);
		asm { cli; hlt; }
	}

	void _d_assert_msg(string msg, string file, uint line)
	{
		// TODO replace
		// panic("Assert: ", msg, " ", file, " ", line);
		asm { cli; hlt; }
	}

	void _d_assertm(ModuleInfo* m, uint line)
	{
		// TODO replace
		// panic("Assert: ", m.name, " ", line);
		asm { cli; hlt; }
	}

	void _d_unittestm(ModuleInfo* m, uint line)
	{
		// TODO replace
		// panic("Unit test failed: ", m.name, " ", line);
		asm { cli; hlt; }
	}
	
	//@system nothrow      void*  memcpy (void* s1, in void* s2, size_t n);
	@system nothrow      void   free   (void* ptr);
	//@system nothrow pure int    memcmp (in void* s1, in void* s2, size_t n);
	//@system nothrow pure size_t strlen (in char* s);
	@system nothrow      void*  malloc (size_t size);
	@system nothrow      void*  alloca (size_t size);

	@system nothrow extern (C)
	void* memcpy(void* destination, const void* source, size_t num)
	{
		immutable(ubyte)* bytePtrSrc  = cast(immutable(ubyte) *)source;
		ubyte*  bytePtrDest = cast(ubyte *)destination;

		while (num > 0)
		{
			*bytePtrDest = *bytePtrSrc;
			++bytePtrDest;
			++bytePtrSrc;
			--num;
		}

		return destination;
	}

	@system nothrow pure extern (C)
	int memcmp(const void* ptr1, const void* ptr2, size_t num)
	{
		immutable(ubyte)* ptrA = cast(immutable(ubyte) *)ptr1;
		immutable(ubyte)* ptrB = cast(immutable(ubyte) *)ptr2;

		while (num > 0)
		{
			if (*ptrA != *ptrB)
			{
				return *ptrA - *ptrB;
			}

			++ptrA;
			++ptrB;
			--num;
		}

		return 0;
	}

	@system nothrow pure extern (C)
	size_t strlen(immutable(char)* str)
	{
		size_t length = 0;
		while (*str != 0)
		{
			++length;
			++str;
		}

		return length;
	}
}
