/**
 * TypeInfo support code.
 *
 * Copyright: Copyright Digital Mars 2004 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright
 */

/*          Copyright Digital Mars 2004 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module typeinfo.ti_delegate;

private import utils.hash;

// delegate

alias void delegate(int) dg;

class TypeInfo_D : TypeInfo
{
    @trusted:
    const:
    pure:
    nothrow:

    override size_t getHash(in void* p)
    {
        return hashOf(p, dg.sizeof);
    }

    override bool equals(in void* p1, in void* p2)
    {
        return *cast(dg *)p1 == *cast(dg *)p2;
    }

    override @property size_t tsize() nothrow pure
    {
        return dg.sizeof;
    }

    override void swap(void *p1, void *p2)
    {
        dg t;

        t = *cast(dg *)p1;
        *cast(dg *)p1 = *cast(dg *)p2;
        *cast(dg *)p2 = t;
    }

    override @property uint flags() nothrow pure
    {
        return 1;
    }
}