module array_eq;

import glue;

/***************************************
 * Support for array equality test.
 * Returns:
 *      1       equal
 *      0       not equal
 */

extern (C) int _adEq(void[] a1, void[] a2, TypeInfo ti)
{
	debug(adi) printf("_adEq(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
	if (a1.length != a2.length)
		return 0; // not equal
	auto sz = ti.tsize;
	auto p1 = a1.ptr;
	auto p2 = a2.ptr;

	if (sz == 1)
		// We should really have a ti.isPOD() check for this
		return (memcmp(p1, p2, a1.length) == 0);

	for (size_t i = 0; i < a1.length; i++)
	{
		if (!ti.equals(p1 + i * sz, p2 + i * sz))
			return 0; // not equal
	}
	return 1; // equal
}

extern (C) int _adEq2(void[] a1, void[] a2, TypeInfo ti)
{
	debug(adi) printf("_adEq2(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
	if (a1.length != a2.length)
		return 0;               // not equal
	if (!ti.equals(&a1, &a2))
		return 0;
	return 1;
}

