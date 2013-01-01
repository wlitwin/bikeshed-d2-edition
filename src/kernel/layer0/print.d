module kernel.layer0.print;

// General printing framework, used by the serial writer and the VGA writer

__gshared:
nothrow:
public:

template CreatePrinter(string name, alias wc, alias ws)
{
	const CreatePrinter = 	
		   "template " ~ name ~ "(const char[] format) 
			{
				void " ~ name ~ "(S...)(S args)
				{
					mixin(ConvertFormat!(format, \"" ~
								__traits(identifier, wc) ~ "\",\"" ~
								__traits(identifier, ws) ~ "\", args));
				}
			}

			template " ~ name ~ "ln(const char[] format)
			{
				void " ~ name ~ "ln(S...)(S args)
				{
					"~name~"!(format)(args);
					"~__traits(identifier, wc)~"('\\n');
				}
			}
		   "
		 ;
}

alias void function(char c)   write_char;
alias void function(string s) write_string;

const(char)[] itoa(char buf[], char base, long d)
{
	size_t p = buf.length-1;
	size_t startIndex = 0;
	ulong ud = d;
	bool negative = false;

	int divisor = 10;
	if (base == 'd' && d < 0)
	{
		negative = true;
		ud = -d;
	}
	else if (base == 'x')
		divisor = 16;
	else if (base == 'b')
		divisor = 2;

	do
	{
		int remainder = cast(int)(ud % divisor);
		if (remainder < 10)
			buf[p--] = cast(char)(remainder + '0');
		else
			buf[p--] = cast(char)(remainder + 'A' - 10);
	}
	while (ud /= divisor);

	if (negative)
		buf[p--] = '-';

	return buf[p+1..$];
}

void printInt(long i, const char[] format, write_string ws)
{
	char[20] buf;

	if (format.length is 0)
		ws(cast(string)itoa(buf, 'd', i));
	else if (format[0] is 'd' || format[0] is 'D')
		ws(cast(string)itoa(buf, 'd', i));
	else if (format[0] is 'u' || format[0] is 'U')
		ws(cast(string)itoa(buf, 'u', i));
	else if (format[0] is 'x' || format[0] is 'X')
		ws(cast(string)itoa(buf, 'x', i));
	else if (format[0] is 'b' || format[0] is 'B')
		ws(cast(string)itoa(buf, 'b', i));
};

void printChar(T)(T ch, const char[] format, write_char wc)
{
	wc(ch);
}

void printString(T)(T str, const char[] format, write_string ws)
{
	ws(str);
}

void printPointer(void* p, const char[] format, write_string ws)
{
	ws("0x");
	char[20] buf;
	ws(cast(string)itoa(buf, 'x', cast(ulong)p));
}

void printBoolean(bool b, const char[] format, write_string ws)
{
	if (b) { ws("true");  }
	else   { ws("false"); }
}

template isArrayType(T)
{
	const bool isArrayType = false;
}

template isArrayType(T : T[])
{
	const bool isArrayType = true;
}

template isPointerType(T)
{
	const bool isPointerType = false;
}

template isPointerType(T : T*)
{
	const bool isPointerType = true;
}

template isStringType(T)
{
	const bool isStringType = is(T == string) || is(T == dstring) || is(T == wstring);
}

template isCharType(T)
{
	const bool isCharType = is(T == char) || is(T == dchar) || is(T == wchar);
}

template isIntType(T)
{
	const bool isIntType =  is(T == byte) || is(T == ubyte) ||
		 	 			 	is(T == int)  || is(T == uint)  ||
					 		is(T == long) || is(T == ulong);
}

template MakePrintOther(alias T, const char[] format, size_t index, string ws, string wc)
{
	static if (isIntType!(typeof(T)))
		const char[] MakePrintOther = "printInt(args["~index.stringof~"],\""~format~"\", &"~ws~");";
	else static if (isCharType!(typeof(T)))
		const char[] MakePrintOther = "printChar!("~typeof(T).stringof~")(args["~index.stringof~"],\""~format~"\", &"~wc~");";
	else static if (isStringType!(typeof(T)))
		const char[] MakePrintOther = "printString!("~typeof(T).stringof~")(args["~index.stringof~"],\""~format~"\", &"~ws~");";
	else static if (isPointerType!(typeof(T)))
		const char[] MakePrintOther = "printPointer(args["~index.stringof~"],\""~format~"\", &"~ws~");";
	/*else static if (isArrayType!(T))
		const char[] MakePrintOther = 
		*/
	else static if (is(typeof(T) == bool))
		const char[] MakePrintOther = "printBoolean(args["~index.stringof~"],\""~format~"\", &"~ws~");";
	else
		static assert(false, "Dont' know how to print a " ~ typeof(T).stringof ~ " (arg " ~ index.stringof ~ ")");
}

template ExtractFormatStringImpl(const char[] format)
{
	static assert(format.length !is 0, "Unterminated format specifier");

	static if (format[0] is '}')
		const size_t ExtractFormatStringImpl = 0;
	else
		const size_t ExtractFormatStringImpl = 1 + ExtractFormatStringImpl!(format[1..$]);
}

template CheckFormatAgainstType(const char[] rawFormat, size_t index, alias T)
{
	const char[] format = rawFormat[1..index];

	static if (isIntType!(typeof(T)))
	{
		static assert(format == "" ||
					  format == "b" || format == "B" ||
					  format == "d" || format == "D" ||
					  format == "x" || format == "X" ||
					  format == "u" || format == "U",
					  "Invalid integer format specifier '" ~ format ~ "'");
	}

	const size_t result = index;
}

template ExtractFormatString(const char[] format, alias T)
{
	const size_t ExtractFormatString = CheckFormatAgainstType!(format, ExtractFormatStringImpl!(format), T).result;
}

template MakePrintCommandGenerate(const char command[])
{
	static assert(false, "Unknown command " ~ format);
}

template ExtractCommand(const char format[])
{
	static if (format.length == 0 || format[0] is '}' || format[0] is '!')
		const ExtractCommand = 0;
	else
		const ExtractCommand = 1 + ExtractCommand!(format[1..$]);
}

template MakePrintCommandImpl(const char[] format)
{
	static if (format.length == 0)
	{
		const char[] result = "";
	}
	else static if (format[0] is '!')
	{
		const char[] result = MakePrintCommandImpl!(format[1..$]).result;
	}
	else
	{
		const lengthOfString = ExtractCommand!(format);

		const char[] result = MakePrintCommandGenerate!(format[0..lengthOfString]) ~
			MakePrintCommandImpl!(format[lengthOfString..$]).result;
	}
}

template MakePrintCommand(const char[] format)
{
	const char[] MakePrintCommand = MakePrintCommandImpl!(format).result;
}

template ExtractCommandStringImpl(const char[] format)
{
	static if (format.length == 0 || format[0] is '}')
	{
		const ExtractCommandStringImpl = 0;
	}
	else
	{
		const ExtractCommandStringImpl = 1 + ExtractCommandStringImpl!(format[1..$]);
	}
}

template ExtractCommandString(const char[] format)
{
	const ExtractCommandString = ExtractCommandStringImpl!(format);
}

template ExtractString(const char[] format)
{
	static if (format.length == 0)
	{
		const size_t ExtractString = 0;
	}
	else static if (format[0] is '{')
	{
		static if (format.length > 1 && format[1] is '{')
			const size_t ExtractString = 2 + ExtractString!(format[2..$]);
		else
			const size_t ExtractString = 0;
	}
	else
		const size_t ExtractString = 1 + ExtractString!(format[1..$]);
}

template StripDoubleLeftBrace(const char[] str)
{
	static if (str.length is 0)
		const char[] StripDoubleLeftBrace = "";
	else static if (str.length is 1)
		const char[] StripDoubleLeftBrace = str;
	else
	{
		static if (str[0..2] == "{{")
			const char[] StripDoubleLeftBrace = "{" ~ StripDoubleLeftBrace!(str[2..$]);
		else
			const char[] StripDoubleLeftBrace = str[0] ~ StripDoubleLeftBrace!(str[1..$]);
	}
}

template MakePrintString(const char[] str, string ws)
{
	const char[] MakePrintString = ws ~ "(\"" ~ StripDoubleLeftBrace!(str) ~ "\");";
}

template ConvertFormatImpl(const char[] format, size_t argIndex, string wc, string ws, types...)
{
	static if (format.length == 0)
	{
		static assert(argIndex == types.length, "More parameters than format string specified");
		const char[] result = "";
	}
	else
	{
		static if (format[0] is '{' && (!(format.length > 1 && (format[1] is '{' || format[1] is '!'))))
		{
			static assert(argIndex < types.length, "More format specifiers than parameters given");

			const lengthOfString = ExtractFormatString!(format, types[argIndex]);
			const char[] result = MakePrintOther!(types[argIndex], format[1..lengthOfString], argIndex, ws, wc) ~ 
				ConvertFormatImpl!(format[lengthOfString+1..$], argIndex+1, wc, ws, types).result;
		}
		else static if (format[0] is '{' && format.length > 1 && format[1] is '!')
		{
			const lengthOfString = ExtractCommandString!(format);

			const char[] result = MakePrintCommand!(format[2..lengthOfString]) ~
				ConvertFormatImpl!(format[lengthOfString+1..$], argIndex, wc, ws, types).result;
		}
		else
		{
			const lengthOfString = ExtractString!(format);

			const char[] result = MakePrintString!(format[0..lengthOfString], ws) ~ 
					ConvertFormatImpl!(format[lengthOfString..$], argIndex, wc, ws, types).result;
		}
	}
}

template ConvertFormat(const char format[], string wc, string ws, types...)
{
	const char[] ConvertFormat = ConvertFormatImpl!(format, 0, wc, ws, types).result;
}

