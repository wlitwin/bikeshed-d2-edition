
// this function is called from the utf module
//extern (C) void onUnicodeError(string msg, size_t idx);

/***********************************
 * These are internal callbacks for various language errors.
 */

extern (C)
{
    // Use ModuleInfo to get file name for "m" versions

    void _d_assertm(ModuleInfo* m, uint line)
    {
    }

    void _d_assert_msg(string msg, string file, uint line)
    {
    }

    void _d_assert(string file, uint line)
    {
    }

    void _d_unittestm(ModuleInfo* m, uint line)
    {
    }

    void _d_unittest_msg(string msg, string file, uint line)
    {
    }

    void _d_unittest(string file, uint line)
    {
    }

    void _d_array_bounds(ModuleInfo* m, uint line)
    {
    }

    void _d_switch_error(ModuleInfo* m, uint line)
    {
    }
}

