module kernel.layer1.strfuncs;

// Implements some basic string operations

__gshared:
nothrow:
public:

/* Find the last index of a character in a string.
 * If the character is not found in the string, -1
 * is returned instead.
 */
int last_index_of(const string str, const char c)
{
	for (int i = str.length-1; i >= 0; --i)
	{
		if (str[i] == c)
			return i;
	}

	return -1;
}

int index_of(const string str, const char c)
{
	return index_of(str, 0, c);
}

int index_of(const string str, int offset, const char c)
{
	if (offset < 0 || offset >= str.length)
		return -1;

	for (int i = offset; i < str.length; ++i)
	{
		if (str[i] == c)
		{
			return i;
		}
	}

	return -1;
}

bool strequal(const char[] str1, const string str2)
{
	int i = 0;
	foreach (c ; str2)
	{
		if (i >= str1.length) return false;
		if (str1[i] == 0) return false;
		if (str1[i++] != c)
		{
			return false;
		}
	}

	return true;
}

void strcopy(char[] dest, const string src)
{
	int i = 0;
	foreach (c ; src)
	{
		if (i >= dest.length) break;
		dest[i++] = c;
	}

	while (i < dest.length)
	{
		// Pad with zeros
		dest[i++] = 0;
	}
}
