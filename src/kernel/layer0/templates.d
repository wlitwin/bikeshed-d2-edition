// This file is full of CTFE templates


/**
 ******************************************************************************
 * STOLEN FROM THE OFFICIAL DRUNTIME
 ******************************************************************************
 * This function returns the next argument in the sequence referenced by
 * the supplied argument pointer.  The argument pointer will be adjusted
 * to point to the next arggument in the sequence.
 *
 * Params:
 *  ap  = The argument pointer.
 *
 * Returns:
 *  The next argument in the sequence.  The result is undefined if ap
 *  does not point to a valid argument.
 */
alias void* va_list;

T va_arg(T)( ref va_list ap )
{
	T arg = *cast(T*) ap;
	ap = cast(va_list)( cast(void*) ap + ( ( T.sizeof + int.sizeof - 1 ) & ~( int.sizeof - 1 ) ) );
	return arg;
}


template toDigit(int n)
{
	const string toDigit = "0123456789"[n];
}

template itoa(long n)
{
	static if (n < 0)
	{
		const string itoa = "-" ~ itoa!(-n);
	}
	else static if (n < 10)
	{
		const string itoa = toDigit!(n);
	}
	else
		const string itoa = itoa!(n/10L) ~ toDigit!(n%10L);
}

template itoa(ulong n)
{
	static if (n < 10)
	{
		const string itoa = toDigit!(n);
	}
	else
		const string itoa = itoa!(n/10L) ~ toDigit!(n%10L);
}

