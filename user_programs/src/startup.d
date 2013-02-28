module _start;

import bikeshedlib.stdlib;

extern (D) void main();

extern (C) void _start()
{
	main();

	exit();

	// Wait to be killed
	while (true)
	{
		asm { hlt; }
	}
}
