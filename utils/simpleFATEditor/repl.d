import editor;

import std.stdio;
import io = std.file;
import std.string;

bool ls(Context context, string[] command)
{
	if (command[0] != "ls") return false;

	if (command.length == 2)
	{
		DirInfo[] dirInfo = context.getDirectoyListing(command[1]);
		foreach (di ; dirInfo)
		{
			if (di.isFile)
			{
				writeln(di.name, " - ", di.size, " bytes");
			}
			else
			{
				writeln(di.name, "/");
			}
		}

		if (dirInfo.length == 0)
		{
			writeln(command[1] ~ " is empty");
		}

		return true;
	}

	return false;
}

bool makeDir(Context context, string[] command)
{
	if (command[0] != "mkdir" || command.length != 2) 
	{
		return false;
	}

	context.addDirectory(command[1]);

	return true;
}

bool insertFile(Context context, string[] command)
{
	if (command[0] != "if" ||
		command.length != 3) return false;

	ubyte[] bytes = cast(ubyte[]) io.read(command[1]);

	context.addFile(command[2], bytes);

	return true;
}

bool saveFS(Context context, string[] command)
{
	if (command[0] != "save"
		|| command.length != 2) return false;	

	context.write(command[1]);

	return true;
}

alias bool function(Context context, string[] cmd) CommandFunc;

void main()
{
	// 4KiB clusters, 1MiB total space
	Context context = new Context(4096, 102400);

	static CommandFunc[] commands = 
	[
		&ls,
		&makeDir,
		&insertFile,
		&saveFS,
	];

top:do
	{
		write("> "); 
		stdout.flush();

		string buf = stdin.readln();
		if (buf == null) return;

		buf = chomp(buf);
		if (buf.length == 0) continue;

		string[] command = split(buf, " ");

		foreach (cmdFunc; commands)
		{
			try
			{
				if (cmdFunc(context, command))
				{
					continue top;
				}
			}
			catch (Exception e)
			{
				writeln(e.msg);
				continue top;
			}
		}

		writeln("Invalid Command");
	} while(true);
}
