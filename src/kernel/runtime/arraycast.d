module arraycast;

extern (C)

@trusted nothrow
void[] _d_arraycast(size_t tsize, size_t fsize, void[] a)
{
	auto length = a.length;

	auto nbytes = length * fsize;
	if (nbytes % tsize != 0)
	{
		//throw new Error("array cast misalignment");
		assert(false);
	}
	length = nbytes / tsize;
	*cast(size_t *)&a = length; // jam new length
	return a;
}
