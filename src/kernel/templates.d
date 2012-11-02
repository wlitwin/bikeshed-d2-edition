// This file is full of CTFE templates

template toDigit(int n)
{
	const string toDigit = "0123456789"[n .. n+1];
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

