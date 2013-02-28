module arrays;

import glue;

/**
 * Append y[] to array x[]
 */
extern (C) void[] _d_arrayappendT(const TypeInfo ti, ref byte[] x, byte[] y)
{
	auto length = x.length;
	auto sizeelem = ti.next.tsize;              // array element size
	_d_arrayappendcTX(ti, x, y.length);
	memcpy(x.ptr + length * sizeelem, y.ptr, y.length * sizeelem);

	// do postblit
	__doPostblit(x.ptr + length * sizeelem, y.length * sizeelem, ti.next);
	return x;
}

/**
 * Obsolete, replaced with _d_arrayappendcTX()
 */
extern (C) void[] _d_arrayappendcT(const TypeInfo ti, ref byte[] x, ...)
{
	assert(false);
	/+
    version(X86)
    {
        byte *argp = cast(byte*)(&ti + 2);
        return _d_arrayappendT(ti, x, argp[0..1]);
    }
    else version(Win64)
    {
        byte *argp = cast(byte*)(&ti + 2);
        return _d_arrayappendT(ti, x, argp[0..1]);
    }
    else version(X86_64)
    {
        // This code copies the element twice, which is annoying
        //   #1 is from va_arg copying from the varargs to b
        //   #2 is in _d_arrayappendT is copyinb b into the end of x
        // to fix this, we need a form of _d_arrayappendT that just grows
        // the array and leaves the copy to be done here by va_arg.
        byte[] b = (cast(byte*)alloca(ti.next.tsize))[0 .. ti.next.tsize];

        va_list ap;
        va_start(ap, __va_argsave);
        va_arg(ap, cast()ti.next, cast(void*)b.ptr);
        va_end(ap);

        // The 0..1 here is strange.  Inside _d_arrayappendT, it ends up copying
        // b.length * ti.next.tsize bytes, which is right amount, but awfully
        // indirectly determined.  So, while it passes a darray of just one byte,
        // the entire block is copied correctly.  If the full b darray is passed
        // in, what's copied is ti.next.tsize * ti.next.tsize bytes, rather than
        // 1 * ti.next.tsize bytes.
        return _d_arrayappendT(ti, x, b[0..1]);
    }
    else
    {
        static assert(false, "platform not supported");
    }
	+/
}

void __doPostblit(void *ptr, size_t len, const TypeInfo ti)
{
	// optimize out any type info that does not need postblit.
	//if((&ti.postblit).funcptr is &TypeInfo.postblit) // compiler doesn't like this
	auto fptr = &ti.postblit;
	if(fptr.funcptr is &TypeInfo.postblit)
		// postblit has not been overridden, no point in looping.
		return;

	if(auto tis = cast(TypeInfo_Struct)ti)
	{
		// this is a struct, check the xpostblit member
		auto pblit = tis.xpostblit;
		if(!pblit)
			// postblit not specified, no point in looping.
			return;

		// optimized for struct, call xpostblit directly for each element
		immutable size = ti.tsize;
		const eptr = ptr + len;
		for(;ptr < eptr;ptr += size)
			pblit(ptr);
	}
	else
	{
		// generic case, call the typeinfo's postblit function
		immutable size = ti.tsize;
		const eptr = ptr + len;
		for(;ptr < eptr;ptr += size)
			ti.postblit(ptr);
	}
}

/**************************************
 * Extend an array by n elements.
 * Caller must initialize those elements.
 */
	extern (C)
byte[] _d_arrayappendcTX(const TypeInfo ti, ref byte[] px, size_t n)
{
	assert(false);
	/*
	// This is a cut&paste job from _d_arrayappendT(). Should be refactored.

	// only optimize array append where ti is not a shared type
	auto sizeelem = ti.next.tsize;              // array element size
	auto isshared = ti.classinfo is TypeInfo_Shared.classinfo;
	auto bic = !isshared ? __getBlkInfo(px.ptr) : null;
	auto info = bic ? *bic : gc_query(px.ptr);
	auto length = px.length;
	auto newlength = length + n;
	auto newsize = newlength * sizeelem;
	auto size = length * sizeelem;

	// calculate the extent of the array given the base.
	size_t offset = px.ptr - __arrayStart(info);
	if(info.base && (info.attr & BlkAttr.APPENDABLE))
	{
	if(info.size >= PAGESIZE)
	{
	// size of array is at the front of the block
	if(!__setArrayAllocLength(info, newsize + offset, isshared, size + offset))
	{
	// check to see if it failed because there is not
	// enough space
	auto newcap = newCapacity(newlength, sizeelem);
	if(*(cast(size_t*)info.base) == size + offset)
	{
	// not enough space, try extending
	auto extendoffset = offset + LARGEPAD - info.size;
	auto u = gc_extend(px.ptr, newsize + extendoffset, newcap + extendoffset);
	if(u)
	{
	// extend worked, now try setting the length
	// again.
	info.size = u;
	if(__setArrayAllocLength(info, newsize + offset, isshared, size + offset))
	{
	if(!isshared)
	__insertBlkInfoCache(info, bic);
	goto L1;
	}
	}
	}

	// couldn't do it, reallocate
	info = gc_qalloc(newcap + LARGEPAD, info.attr);
	__setArrayAllocLength(info, newsize, isshared);
	if(!isshared)
	__insertBlkInfoCache(info, bic);
	auto newdata = cast(byte *)info.base + LARGEPREFIX;
	memcpy(newdata, px.ptr, length * sizeelem);
	// do postblit processing
	__doPostblit(newdata, length * sizeelem, ti.next);
	(cast(void **)(&px))[1] = newdata;
	}
	else if(!isshared && !bic)
	{
	__insertBlkInfoCache(info, null);
	}
	}
	else if(!__setArrayAllocLength(info, newsize + offset, isshared, size + offset))
	{
	// could not resize in place
	auto allocsize = newCapacity(newlength, sizeelem);
	info = gc_qalloc(allocsize + __arrayPad(allocsize), info.attr);
	goto L2;
	}
	else if(!isshared && !bic)
	{
	__insertBlkInfoCache(info, null);
	}
}
else
{
	// not appendable or is null
	auto allocsize = newCapacity(newlength, sizeelem);
	info = gc_qalloc(allocsize + __arrayPad(allocsize), (info.base ? info.attr : !(ti.next.flags & 1) ? BlkAttr.NO_SCAN : 0) | BlkAttr.APPENDABLE);
L2:
	__setArrayAllocLength(info, newsize, isshared);
	if(!isshared)
		__insertBlkInfoCache(info, bic);
	auto newdata = cast(byte *)__arrayStart(info);
	memcpy(newdata, px.ptr, length * sizeelem);
	// do postblit processing
	__doPostblit(newdata, length * sizeelem, ti.next);
	(cast(void **)(&px))[1] = newdata;
}

L1:
*cast(size_t *)&px = newlength;
return px;
*/
}

/**
 *
 */
extern (C) void[] _d_arraycatnT(const TypeInfo ti, uint n, ...)
{
	assert(false);
	/*
    size_t length;
    auto size = ti.next.tsize;   // array element size

    version(X86)
    {
        byte[]* p = cast(byte[]*)(&n + 1);

        for (auto i = 0; i < n; i++)
        {
            byte[] b = *p++;
            length += b.length;
        }
    }
    else version(Win64)
    {
        byte[]** p = cast(byte[]**)(cast(void*)&n + 8);

        for (auto i = 0; i < n; i++)
        {
            byte[]* b = *p++;
            length += (*b).length;
        }
    }
    else
    {
        __va_list argsave = __va_argsave.va;
        va_list ap;
        va_start(ap, __va_argsave);
        for (auto i = 0; i < n; i++)
        {
            byte[] b;
            va_arg(ap, b);
            length += b.length;
        }
        va_end(ap);
    }
    if (!length)
        return null;

    auto allocsize = length * size;
    auto info = gc_qalloc(allocsize + __arrayPad(allocsize), !(ti.next.flags & 1) ? BlkAttr.NO_SCAN | BlkAttr.APPENDABLE : BlkAttr.APPENDABLE);
    auto isshared = ti.classinfo is TypeInfo_Shared.classinfo;
    __setArrayAllocLength(info, allocsize, isshared);
    void *a = __arrayStart (info);

    version(X86)
    {
        p = cast(byte[]*)(&n + 1);

        size_t j = 0;
        for (auto i = 0; i < n; i++)
        {
            byte[] b = *p++;
            if (b.length)
            {
                memcpy(a + j, b.ptr, b.length * size);
                j += b.length * size;
            }
        }
    }
    else version (Win64)
    {
        p = cast(byte[]**)(cast(void*)&n + 8);

        size_t j = 0;
        for (auto i = 0; i < n; i++)
        {
            byte[] b = *(*p++);
            if (b.length)
            {
                memcpy(a + j, b.ptr, b.length * size);
                j += b.length * size;
            }
        }
    }
    else
    {
        va_list ap2 = &argsave;
        size_t j = 0;
        for (auto i = 0; i < n; i++)
        {
            byte[] b;
            va_arg(ap2, b);
            if (b.length)
            {
                memcpy(a + j, b.ptr, b.length * size);
                j += b.length * size;
            }
        }
        va_end(ap2);
    }

    // do postblit processing
    __doPostblit(a, j, ti.next);

    return a[0..length];
	*/
}

/**
 *
 */
extern (C) byte[] _d_arraycatT(const TypeInfo ti, byte[] x, byte[] y)
out (result)
{
	/+
    auto sizeelem = ti.next.tsize;              // array element size
    debug(PRINTF) printf("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d => %d,%p)\n", x.length, x.ptr, y.length, y.ptr, sizeelem, result.length, result.ptr);
    assert(result.length == x.length + y.length);

    // If a postblit is involved, the contents of result might rightly differ
    // from the bitwise concatenation of x and y.
    auto pb = &ti.next.postblit;
    if (pb.funcptr is &TypeInfo.postblit)
    {
        for (size_t i = 0; i < x.length * sizeelem; i++)
            assert((cast(byte*)result)[i] == (cast(byte*)x)[i]);
        for (size_t i = 0; i < y.length * sizeelem; i++)
            assert((cast(byte*)result)[x.length * sizeelem + i] == (cast(byte*)y)[i]);
    }

    size_t cap = gc_sizeOf(result.ptr);
    assert(!cap || cap > result.length * sizeelem);
	+/
}
body
{
	assert(false);
	/+
    version (none)
    {
        /* Cannot use this optimization because:
         *  char[] a, b;
         *  char c = 'a';
         *  b = a ~ c;
         *  c = 'b';
         * will change the contents of b.
         */
        if (!y.length)
            return x;
        if (!x.length)
            return y;
    }

    auto sizeelem = ti.next.tsize;              // array element size
    debug(PRINTF) printf("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d)\n", x.length, x.ptr, y.length, y.ptr, sizeelem);
    size_t xlen = x.length * sizeelem;
    size_t ylen = y.length * sizeelem;
    size_t len  = xlen + ylen;

    if (!len)
        return null;

    auto info = gc_qalloc(len + __arrayPad(len), !(ti.next.flags & 1) ? BlkAttr.NO_SCAN | BlkAttr.APPENDABLE : BlkAttr.APPENDABLE);
    byte* p = cast(byte*)__arrayStart(info);
    p[len] = 0; // guessing this is to optimize for null-terminated arrays?
    memcpy(p, x.ptr, xlen);
    memcpy(p + xlen, y.ptr, ylen);
    // do postblit processing
    __doPostblit(p, xlen + ylen, ti.next);

    auto isshared = ti.classinfo is TypeInfo_Shared.classinfo;
    __setArrayAllocLength(info, len, isshared);
    return p[0 .. x.length + y.length];
	+/
}

/**
 * Allocate a new array of length elements.
 * ti is the type of the resulting array, or pointer to element.
 * (For when the array is initialized to 0)
 */
extern (C) void[] _d_newarrayT(const TypeInfo ti, size_t length)
{
	assert(false);
	/+
    void[] result;
    auto size = ti.next.tsize;                  // array element size

    debug(PRINTF) printf("_d_newarrayT(length = x%x, size = %d)\n", length, size);
    if (length == 0 || size == 0)
        result = null;
    else
    {
        version (D_InlineAsm_X86)
        {
            asm
            {
                mov     EAX,size        ;
                mul     EAX,length      ;
                mov     size,EAX        ;
                jc      Loverflow       ;
            }
        }
        else version(D_InlineAsm_X86_64)
        {
            asm
            {
                mov     RAX,size        ;
                mul     RAX,length      ;
                mov     size,RAX        ;
                jc      Loverflow       ;
            }
        }
        else
        {
            auto newsize = size * length;
            if (newsize / length != size)
                goto Loverflow;

            size = newsize;
        }

        // increase the size by the array pad.
        auto info = gc_qalloc(size + __arrayPad(size), !(ti.next.flags & 1) ? BlkAttr.NO_SCAN | BlkAttr.APPENDABLE : BlkAttr.APPENDABLE);
        debug(PRINTF) printf(" p = %p\n", info.base);
        // update the length of the array
        auto arrstart = __arrayStart(info);
        memset(arrstart, 0, size);
        auto isshared = ti.classinfo is TypeInfo_Shared.classinfo;
        __setArrayAllocLength(info, size, isshared);
        result = arrstart[0..length];
    }
    return result;

Loverflow:
    onOutOfMemoryError();
    assert(0);
	+/
}
