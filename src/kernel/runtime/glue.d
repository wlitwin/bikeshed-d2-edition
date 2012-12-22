module stubs;

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
}
