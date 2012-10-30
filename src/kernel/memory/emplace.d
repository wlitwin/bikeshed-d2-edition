module kernel.memory.emplace;

import kernel.serial;
import kernel.support;
    
T enforce(T, string file = __FILE__, int line = __LINE__)
       (T value, lazy const(char)[] msg = null)
{
      if (!value) 
	  {
		serial_outln("Enforce failure at: ", file, " ", line);	
		if (msg)
		{
			serial_outln(msg);
		}
		panic();
	  }
      return value;
}

// emplace
/**
Given a pointer $(D chunk) to uninitialized memory (but already typed
as $(D T)), constructs an object of non-$(D class) type $(D T) at that
address.

This function can be $(D @trusted) if the corresponding constructor of
$(D T) is $(D @safe).

Returns: A pointer to the newly constructed object (which is the same
as $(D chunk)).
 */
T* emplace(T)(T* chunk)
    if (!is(T == class))
{
    auto result = cast(typeof(return)) chunk;
    static T i;
    memcpy(result, &i, T.sizeof);
    return result;
}
///ditto
T* emplace(T)(T* chunk)
    if (is(T == class))
{
    *chunk = null;
    return chunk;
}


/**
Given a pointer $(D chunk) to uninitialized memory (but already typed
as a non-class type $(D T)), constructs an object of type $(D T) at
that address from arguments $(D args).

This function can be $(D @trusted) if the corresponding constructor of
$(D T) is $(D @safe).

Returns: A pointer to the newly constructed object (which is the same
as $(D chunk)).
 */
T* emplace(T, Args...)(T* chunk, Args args)
    if (!is(T == struct) && Args.length == 1)
{
    *chunk = args[0];
    return chunk;
}

// Specialization for struct
T* emplace(T, Args...)(T* chunk, Args args)
    if (is(T == struct))
{
    auto result = cast(typeof(return)) chunk;

    void initialize()
    {
        static T i;
        memcpy(chunk, &i, T.sizeof);
    }

    static if (is(typeof(result.__ctor(args))))
    {
        // T defines a genuine constructor accepting args
        // Go the classic route: write .init first, then call ctor
        initialize();
        result.__ctor(args);
    }
    else static if (is(typeof(T(args))))
    {
        // Struct without constructor that has one matching field for
        // each argument
        *result = T(args);
    }
    else //static if (Args.length == 1 && is(Args[0] : T))
    {
        static assert(Args.length == 1);
        //static assert(0, T.stringof ~ " " ~ Args.stringof);
        // initialize();
        *result = args[0];
    }
    return result;
}

/**
Given a raw memory area $(D chunk), constructs an object of $(D class)
type $(D T) at that address. The constructor is passed the arguments
$(D Args). The $(D chunk) must be as least as large as $(D T) needs
and should have an alignment multiple of $(D T)'s alignment. (The size
of a $(D class) instance is obtained by using $(D
__traits(classInstanceSize, T))).

This function can be $(D @trusted) if the corresponding constructor of
$(D T) is $(D @safe).

Returns: A pointer to the newly constructed object.
 */

T emplace(T, Args...)(void[] chunk, Args args) if (is(T == class))
{
    enum classSize = __traits(classInstanceSize, T);
	//static assert(chunk.length >= classSize);
    enforce(chunk.length >= classSize,
          "emplace: chunk size too small");
    auto a = cast(size_t) chunk.ptr;
    enforce(a % T.alignof == 0, "emplace: bad alignment");
    auto result = cast(typeof(return)) chunk.ptr;

    // Initialize the object in its pre-ctor state
    (cast(byte[]) chunk)[0 .. classSize] = typeid(T).init[];

    // Call the ctor if any
    static if (is(typeof(result.__ctor(args))))
    {
        // T defines a genuine constructor accepting args
        // Go the classic route: write .init first, then call ctor
        result.__ctor(args);
    }
    else
    {
        static assert(args.length == 0 && !is(typeof(&T.__ctor)),
                "Don't know how to initialize an object of type "
                ~ T.stringof ~ " with arguments " ~ Args.stringof);
    }
    return result;
}

/**
Given a raw memory area $(D chunk), constructs an object of non-$(D
class) type $(D T) at that address. The constructor is passed the
arguments $(D args), if any. The $(D chunk) must be as least as large
as $(D T) needs and should have an alignment multiple of $(D T)'s
alignment.

This function can be $(D @trusted) if the corresponding constructor of
$(D T) is $(D @safe).

Returns: A pointer to the newly constructed object.
 */
T* emplace(T, Args...)(void[] chunk, Args args)
    if (!is(T == class))
{
    enforce(chunk.length >= T.sizeof,
           new ConvException("emplace: chunk size too small"));
    auto a = cast(size_t) chunk.ptr;
    enforce(a % T.alignof == 0, text(a, " vs. ", T.alignof));
    auto result = cast(typeof(return)) chunk.ptr;
    return emplace(result, args);
}
