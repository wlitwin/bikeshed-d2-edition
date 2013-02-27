module kernel.layer1.ramfs.path;

import kernel.layer1.strfuncs : index_of, last_index_of;

// This file contains functions that help determine
// the validity of strings that are supposed to
// represent paths to file system files and directories.

__gshared:
nothrow:
public:

/* Determine if a given string is a valid path.
 * Currently the only requirement is that it starts
 * with a slash. All other characters are currently
 * valid. This may change later.
 */
bool valid_path(const string path)
{
	return path.length != 0 && path[0] == '/';
}

/* Get the directory part of a path. If the given
 * string is not a valid path, the empty string
 * is returned.
 */
const(string) get_directory_path(const string path)
{
	if (!valid_path(path)) return "";	

	if (is_directory_path(path)) return path;

	return path[0..last_index_of(path, '/')];
}

/* Determine if a given string is a file path.
 * File paths do not have a '/' at the end.
 * For example: /path/to/file is a file path,
 * but /path/to/file/ is a directory path.
 */
bool is_file_path(const string path)
{
	if (!valid_path(path)) return false;

	return path[$-1] != '/';
}

/* Determine if a given string is a directory
 * path. directory paths have a trailing '/'
 * at the end of the string.
 * For example: /path/to/dir/ is a directory
 * path, but /path/to/dir is a file path.
 */
bool is_directory_path(const string path)
{
	if (!valid_path(path)) return false;

	return path[$-1] == '/';
}

/* Get the file name part of a path. If the path
 * is not a file path, the empty string is returned.
 */
const(string) get_file_name(const string path)
{
	if (!is_file_path(path)) return "";

	return path[last_index_of(path, '/')+1 .. $];
}

/* Determine if the given string is a valid name for
 * a file or directory. Currently anything is valid
 * as long as the name does not contain '/'.
 */
bool is_valid_name(const string name)
{
	return last_index_of(name, '/') == -1;
}

struct PathWalker
{
	string path;
	string curElement;
	int curIndex;

	bool initialize(string val)
	{
		if (!valid_path(val)) return false;

		path = val;
		curIndex = 0;
		nextName();

		return true;
	}

	string getName()
	{
		return curElement;
	}

	bool nextName()
	{
		int first  = index_of(path, curIndex, '/');	
		int second = index_of(path, first+1, '/');

		if (first == -1 && second == -1) return false;

		if (second == -1)
		{
			second = path.length-1;
		}

		curIndex = second;
		curElement = path[first .. second+1];	

		return true;
	}
}
