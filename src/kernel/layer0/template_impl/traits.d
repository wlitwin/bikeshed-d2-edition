module kernel.layer0.template_impl.traits;

/***
 * Detect whether type $(D T) is an aggregate type.
 */
template isAggregateType(T)
{
	enum isAggregateType = is(T == struct) || is(T == union) ||
		is(T == class)  || is(T == interface);
}

	/+
template isIteratable(T)
{
	enum isIterable = is(typeof({ foreach(elem; T.init) {} }));
}

template isMutable(T)
{
	enum isMutable = !is(T == const) && !is(T == immutable) && !is(T == inout);
}

+/

/**
 * Detect whether $(D T) is a built-in integral type. Types $(D bool),
 * $(D char), $(D wchar), and $(D dchar) are not considered integral.
 */
template isIntegral(T)
{
	enum bool isIntegral = is(IntegralTypeOf!T) && !isAggregateType!T;
}

/**
 * Detect whether $(D T) is a built-in boolean type.
 */
template isBoolean(T)
{
	enum bool isBoolean = is(BooleanTypeOf!T) && !isAggregateType!T;
}

/**
  Detect whether $(D T) is one of the built-in character types.
 */
template isSomeChar(T)
{
	enum isSomeChar = is(CharTypeOf!T) && !isAggregateType!T;
}

/**
  Detect whether $(D T) is one of the built-in string types.
 */
template isSomeString(T)
{
	enum isSomeString = is(StringTypeOf!T) && !isAggregateType!T;
}

/*
 */
template StringTypeOf(T)
{
	static if (is(T == typeof(null)))
	{
		// It is impossible to determine exact string type from typeof(null) -
		// it means that StringTypeOf!(typeof(null)) is undefined.
		// Then this behavior is convenient for template constraint.
		static assert(0, T.stringof~" is not a string type");
	}
	else static if (is(T : const char[]) || is(T : const wchar[]) || is(T : const dchar[]))
	{
		alias ArrayTypeOf!T StringTypeOf;
	}
	else
		static assert(0, T.stringof~" is not a string type");
}

/**
  Strips off all $(D typedef)s (including $(D enum) ones) from type $(D T).

Example:
--------------------
enum E : int { a }
typedef E F;
typedef const F G;
static assert(is(OriginalType!G == const int));
--------------------
 */
template OriginalType(T)
{
	template Impl(T)
	{
		static if (is(T U == typedef)) alias OriginalType!U Impl;
		else static if (is(T U ==    enum)) alias OriginalType!U Impl;
		else                                alias              T Impl;
	}

	alias ModifyTypePreservingSTC!(Impl, T) OriginalType;
}

// [For internal use]
private template ModifyTypePreservingSTC(alias Modifier, T)
{
	static if (is(T U == shared(const U))) alias shared(const Modifier!U) ModifyTypePreservingSTC;
	else static if (is(T U ==        const U )) alias        const(Modifier!U) ModifyTypePreservingSTC;
	else static if (is(T U ==    immutable U )) alias    immutable(Modifier!U) ModifyTypePreservingSTC;
	else static if (is(T U ==       shared U )) alias       shared(Modifier!U) ModifyTypePreservingSTC;
	else                                        alias              Modifier!T  ModifyTypePreservingSTC;
}


/*
 */
template StaticArrayTypeOf(T)
{
	inout(U[n]) idx(U, size_t n)( inout(U[n]) );

	static if (is(T == enum))
		alias .StaticArrayTypeOf!(OriginalType!T) StaticArrayTypeOf;
	else static if (is(typeof(idx(defaultInit!T)) X))
		alias X StaticArrayTypeOf;
	else
		static assert(0, T.stringof~" is not a static array type");
}

/*
 */
template DynamicArrayTypeOf(T)
{
	inout(U[]) idx(U)( inout(U[]) );

	static if (is(T == enum))
		alias .DynamicArrayTypeOf!(OriginalType!T) DynamicArrayTypeOf;
	else static if (!is(StaticArrayTypeOf!T) &&
			is(typeof(idx(defaultInit!T)) X))
	{
		alias typeof(defaultInit!T[0]) E;

		E[]  idy(              E[]  );
		const(E[]) idy(        const(E[]) );
		inout(E[]) idy(        inout(E[]) );
		shared(      E[]) idy( shared(      E[]) );
		shared(const E[]) idy( shared(const E[]) );
		shared(inout E[]) idy( shared(inout E[]) );
		immutable(E[]) idy(    immutable(E[]) );

		alias typeof(idy(defaultInit!T)) DynamicArrayTypeOf;
	}
	else
		static assert(0, T.stringof~" is not a dynamic array");
}

/*
 */
template ArrayTypeOf(T)
{
	static if (is(StaticArrayTypeOf!T X))
		alias X ArrayTypeOf;
	else static if (is(DynamicArrayTypeOf!T X))
		alias X ArrayTypeOf;
	else
		static assert(0, T.stringof~" is not an array type");
}


/*
 */
template CharTypeOf(T)
{
	inout( char) idx(        inout( char) );
	inout(wchar) idx(        inout(wchar) );
	inout(dchar) idx(        inout(dchar) );
	shared(inout  char) idx( shared(inout  char) );
	shared(inout wchar) idx( shared(inout wchar) );
	shared(inout dchar) idx( shared(inout dchar) );

	immutable(  char) idy(   immutable(  char) );
	immutable( wchar) idy(   immutable( wchar) );
	immutable( dchar) idy(   immutable( dchar) );
	// Integrals and characers are impilcit convertible each other with value copy.
	// Then adding exact overloads to detect it.
	immutable(  byte) idy(   immutable(  byte) );
	immutable( ubyte) idy(   immutable( ubyte) );
	immutable( short) idy(   immutable( short) );
	immutable(ushort) idy(   immutable(ushort) );
	immutable(   int) idy(   immutable(   int) );
	immutable(  uint) idy(   immutable(  uint) );
	immutable(  long) idy(   immutable(  long) );
	immutable( ulong) idy(   immutable( ulong) );

	static if (is(T == enum))
		alias .CharTypeOf!(OriginalType!T) CharTypeOf;
	else static if (is(typeof(idx(T.init)) X))
		alias X CharTypeOf;
	else static if (is(typeof(idy(T.init)) X) && staticIndexOf!(Unqual!X, CharTypeList) >= 0)
		alias X CharTypeOf;
	else
		static assert(0, T.stringof~" is not a character type");
}

/*
 */
template IntegralTypeOf(T)
{
	inout(  byte) idx(        inout(  byte) );
	inout( ubyte) idx(        inout( ubyte) );
	inout( short) idx(        inout( short) );
	inout(ushort) idx(        inout(ushort) );
	inout(   int) idx(        inout(   int) );
	inout(  uint) idx(        inout(  uint) );
	inout(  long) idx(        inout(  long) );
	inout( ulong) idx(        inout( ulong) );
	shared(inout   byte) idx( shared(inout   byte) );
	shared(inout  ubyte) idx( shared(inout  ubyte) );
	shared(inout  short) idx( shared(inout  short) );
	shared(inout ushort) idx( shared(inout ushort) );
	shared(inout    int) idx( shared(inout    int) );
	shared(inout   uint) idx( shared(inout   uint) );
	shared(inout   long) idx( shared(inout   long) );
	shared(inout  ulong) idx( shared(inout  ulong) );

	immutable(  char) idy(    immutable(  char) );
	immutable( wchar) idy(    immutable( wchar) );
	immutable( dchar) idy(    immutable( dchar) );
	// Integrals and characers are impilcit convertible each other with value copy.
	// Then adding exact overloads to detect it.
	immutable(  byte) idy(    immutable(  byte) );
	immutable( ubyte) idy(    immutable( ubyte) );
	immutable( short) idy(    immutable( short) );
	immutable(ushort) idy(    immutable(ushort) );
	immutable(   int) idy(    immutable(   int) );
	immutable(  uint) idy(    immutable(  uint) );
	immutable(  long) idy(    immutable(  long) );
	immutable( ulong) idy(    immutable( ulong) );

	static if (is(T == enum))
		alias .IntegralTypeOf!(OriginalType!T) IntegralTypeOf;
	else static if (is(typeof(idx(T.init)) X))
		alias X IntegralTypeOf;
	else static if (is(typeof(idy(T.init)) X) && staticIndexOf!(Unqual!X, IntegralTypeList) >= 0)
		alias X IntegralTypeOf;
	else
		static assert(0, T.stringof~" is not an integral type");
}
