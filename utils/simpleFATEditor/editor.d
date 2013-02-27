module editor;

import defs;
import io = std.file;
import std.stdio;
import std.conv;
import std.string;

class Context
{
private:
	ubyte file_system[];
	BootRecord* boot_record;
	Directory* root_directory;
	uint* FAT;
	uint cluster_size;
	uint DIRS_PER_CLUSTER;

	uint cluster_offset(const uint index) const
	{
		return index * cluster_size;
	}

	ubyte* cluster_address(const uint index)
	{
		return &file_system[cluster_offset(index)];
	}

	void empty_directory(Directory* dir)
	{
		zero(dir, DIRS_PER_CLUSTER*Directory.sizeof);
	}

public:
	this(const uint cluster_size, uint file_system_size)
	{
		// Make sure the cluster size is a power of two
		assert((cluster_size & (cluster_size - 1)) == 0, "Bad cluster size: " ~ to!string(cluster_size));
		this.cluster_size = cluster_size;
		// Make sure we can fit at least a cluster, but 
		// probably need more than that anyway
		assert(file_system_size > cluster_size, 
				"File system size too small: " ~ to!string(file_system_size) 
				~ " cluster size: " ~ to!string(cluster_size));

		// TODO Make sure filesystem is large enough for 4 clusters

		// Fix the filesystem size to be a multiple of the cluster_size
		const int max_clusters = file_system_size / cluster_size;
		file_system_size = cluster_size * max_clusters;

		// Allocate the filesystem
		file_system = new ubyte[file_system_size];
		// Setup the Boot Record
		boot_record = cast(BootRecord*)cluster_address(0);
		boot_record.cluster_size = cluster_size;
		boot_record.file_system_size = file_system_size;

		// Calculate the size of the FAT
		const uint fat_clusters = cast(uint)(((max_clusters / uint.sizeof) / cluster_size) + 1);
		boot_record.fat_size = fat_clusters;
		boot_record.max_fat_entries = max_clusters;

		FAT = cast(uint*)cluster_address(1);

		// Mark the Boot Record and FAT sectors as used
		for (int i = 0; i < fat_clusters+1; ++i) 
		{
			FAT[i] = ClusterType.Reserved;
		}

		// Set the root directory directly after the FAT
		DIRS_PER_CLUSTER = cluster_size / Directory.sizeof;
		const uint root_directory_cluster = fat_clusters+1;
		boot_record.root_directory = root_directory_cluster;

		root_directory = cast(Directory*)cluster_address(root_directory_cluster);
		FAT[root_directory_cluster] = ClusterType.End_Of_Chain;	// Currently only lives on 1 cluster
		empty_directory(root_directory); // Null out all entries in the root directory

		writeln("Max Clusters: ", max_clusters);
		writeln("FS Size: ", file_system_size);
		writeln("Cluster Size: ", cluster_size);
		writeln("FAT Clusters: ", fat_clusters);
		writeln("DIRS_PER_CLUSTER: ", DIRS_PER_CLUSTER);
		writeln("Root Dir Cluster: ", root_directory_cluster);
	}

	/* Scans the FAT to see if there are enough free clusters. Returns true if the
	 * file system currently has enough free clusters, false otherwise.
	 *
	 * num_clusters - How many free clusters to look for
	 */
	private bool has_space(uint num_clusters) const
	{
		for (int i = 0; i < boot_record.max_fat_entries && num_clusters > 0; ++i)
		{
			if (FAT[i] == ClusterType.Free) 
			{
				--num_clusters;
			}
		}
		
		return num_clusters == 0;
	}

	/* Finds the next free cluster in the file system, starting from a given
	 * index. If no valid free clusters were found it returns 0.
	 *
	 * start_index - The index to start searching from
	 */
	private uint next_free_fat_index(uint start_index) const
	{
		assert(start_index < boot_record.max_fat_entries, "next_free_fat_index: argument too large");

		for (; start_index < boot_record.max_fat_entries; ++start_index)
		{
			if (FAT[start_index] == ClusterType.Free)
			{
				return start_index;
			}
		}

		return 0; // 0 is not a valid index for the FAT file system (always reserved for boot record)
	}	

	/* Takes an array of data and finds clusters in the file system to put it.
	 * If there's not enough free space it throws an exception.
	 *
	 * data - The data to put into the file system
	 */
	private bool fill_data(ubyte[] data, uint cluster)
	{
		uint num_clusters = cast(uint)(data.length / cluster_size);
		if (!has_space(num_clusters))
		{
			return false;
		}

		// Get the first free cluster
		uint firstCluster = next_free_fat_index(0);

		// Fill the first clusters space
		uint dataOffset = 0;
		ubyte* fsData = cluster_address(firstCluster);	
		for (uint i = 0; i < boot_record.cluster_size && dataOffset < data.length; ++i)
		{
			fsData[i] = data[dataOffset++];	
		}
		--num_clusters;

		// Repeat for remaining clusters
		uint curCluster = firstCluster;
		while (num_clusters > 0)
		{
			// Copy the file data into the cluster
			fsData = cluster_address(curCluster);
			for (uint i = 0; i < boot_record.cluster_size && dataOffset < data.length; ++i)
			{
				fsData[i] = data[dataOffset++];	
			}

			curCluster = next_free_fat_index(curCluster);
			--num_clusters;
		}

		// Mark the the last clusters 'next' pointer to EOC
		FAT[curCluster] = ClusterType.End_Of_Chain;

		cluster = firstCluster;
		return true;
	}

	/* Checks if a given string has the correct path
	 * format. /some/path/to/file. It does not check
	 * if that path actually exists
	 */
	private bool valid_path_string(string path) const
	{
		// Path must start with a slash
		if (path.length == 0 || path[0] != '/') 
			return false;

		// Everything else is valid
		return true;
	}

	/* Get the directory part of the path. If the path
	 * already points to a directory, the same path
	 * is returned. Assumes directories have a / after
	 * them. Therefore /path/to/dir -> /path/to
	 * and /path/to/dir/ -> /path/to/dir
	 *
	 * Empty string is returned if the path is invalid.
	 */
	private string get_directory_path(string path) const
	{
		if (!valid_path_string(path)) return "";

		if (is_directory_path(path)) return path;

		return path[0..lastIndexOf(path, '/')];
	}

	/* Checks if the path is a file. Assumes 
	 * directories end in '/', therefore if the 
	 * string is a valid path and doesn't end
	 * in '/' it's a file.
	 */
	private bool is_file_path(string path) const
	{
		if (!valid_path_string(path)) return false;

		return path[$-1] != '/';
	}

	/* Checks if the path is a directory path. 
	 * Assumes that directories end in '/'.
	 */
	private bool is_directory_path(string path) const
	{
		if (!valid_path_string(path)) return false;

		return path[$-1] == '/';
	}

	/* Get the filename part of the path. Example
	 * /path/to/file -> file
	 * Empty string is returned if the path is invalid.
	 */
	private string get_file_name(string path) const
	{
		if (!is_file_path(path)) return "";

		return path[lastIndexOf(path, '/')+1 .. $-1];
	}

	// Careful this is a closure'd class, it has direct
	// access to things to the outside class.
	class DirectoryWalker
	{
		uint curCluster;
		Directory* dir;
		this()
		{
			dir = root_directory;
			curCluster = boot_record.root_directory;
		}

		/* Move forward a directory. Returns
		 * False if the specified directory
		 * does not exist, or the directory 
		 * is invalid.
		 */
		bool next(string dirName)
		{
			// Scan for the directory name
			if (!valid_single_name(dirName)) return false;

			for (int i = 0; i < DIRS_PER_CLUSTER; ++i)
			{
				if (dir[i].type == DirectoryType.Directory 
					&& dir[i].file_name == dirName)
				{
					curCluster = dir[i].cluster;
					dir = cast(Directory*)cluster_address(curCluster);	
					return true;
				}
			}

			return false;
		}

		bool next(string dir, bool create)
		{
			if (create)
			{
				if (!next(dir))
				{
					// Try to create it
					if (!createDir(dir)) return false;

					return next(dir);
				}

				return true;
			}
			else
			{
				return next(dir);
			}
		}

		bool createDir(string name)
		{
			// Make sure the name does not contain
			// and slashes
			if (!valid_single_name(name)) return false;

			// TODO make sure directory doesn't already exist

			// Don't muck around with the actual current directory
			Directory* dir  = this.dir;
			uint curCluster = this.curCluster;
			
			// Find an empty location
			bool found = false;
			for (int i = 0; i < DIRS_PER_CLUSTER; ++i)
			{
				if (dir[i].type == DirectoryType.Free)
				{
					found = true;
					dir = cast(Directory*)&dir[i];
					break;	
				}

				// Check if there are more directories
				if (i == DIRS_PER_CLUSTER-1 
					&& FAT[curCluster] != ClusterType.End_Of_Chain)
				{
					curCluster = FAT[curCluster];
					i = 0;
				}
			}

			// Couldn't find a free space, try to allocate a new cluster
			// for directories
			if (!found)
			{
				// We need to extend this directory
				if (!has_space(1)) return false;

				uint newCluster = next_free_fat_index(0);
				zero(cluster_address(newCluster), boot_record.cluster_size);

				FAT[curCluster] = newCluster;
				FAT[newCluster] = ClusterType.End_Of_Chain;

				curCluster = newCluster;
				dir = cast(Directory*)cluster_address(curCluster);
			}

			// We need to allocate space for the new directory
			if (!has_space(1)) return false;

			uint newCluster = next_free_fat_index(0);
			zero(cluster_address(newCluster), boot_record.cluster_size);
			FAT[newCluster] = ClusterType.End_Of_Chain;

			// Dir is set to the correct entry
			dir.type = DirectoryType.Directory;	
			dir.cluster = newCluster;	
			strcopy(dir.file_name, name);

			return true;
		}

		bool createFile(string name, ubyte[] data)
		{
			if (!valid_single_name(name)) return false;

			// Find a free spot to place the file		
			// TODO - Should check if a directory exists
			//        with the same name?
			Directory* dir = this.dir;
			uint curCluster = this.curCluster;

			for (int i = 0; i < DIRS_PER_CLUSTER; ++i)
			{
				if (dir[i].type == DirectoryType.Free)
				{
					// Allocate space for the file
					uint fileCluster;
					if (!fill_data(data, fileCluster))
					{
						return false;
					}

					// Place it here
					dir[i].type = DirectoryType.File;
					dir[i].cluster = fileCluster;
					strcopy(dir[i].file_name, name);
					dir[i].file_size = cast(uint)data.length;

					return true;
				}

				if (i == DIRS_PER_CLUSTER-1)
				{
					if (FAT[curCluster] != ClusterType.End_Of_Chain)
					{
						curCluster = FAT[curCluster];
					}
					else
					{
						// Try to extend this directory
						if (!has_space(1)) return false;

						uint newCluster = next_free_fat_index(0);
						FAT[curCluster] = newCluster;
						FAT[newCluster] = ClusterType.End_Of_Chain;
						zero(cluster_address(newCluster), boot_record.cluster_size);

						curCluster = newCluster;
					}

					// Restart the loop from the beginning, curCluster has
					// been updated appropriately
					dir = cast(Directory*)cluster_address(curCluster);
					i = 0;
				}
			}

			return false;
		}

		/* Move back a directory
		 */
		void prev()
		{
			// TODO Implement
			throw new Exception("Not Implemented");
		}
	}

	/* Determines if the string is a valid name
	 * for a file or directory
	 */
	private bool valid_single_name(const string name) const
	{
		return indexOf(name, '/') == -1;
	}

	void addFile(string path, ubyte data[])
	{
		if (!is_file_path(path))
		{
			throw new Exception("Path is not a file path: " ~ path);
		}

		// Split the string into appropriate parts
		string[] directories = split(get_directory_path(path), "/");
		string filename  = get_file_name(path);

		DirectoryWalker dirWalk = new DirectoryWalker();
		for (int i = 1; i < directories.length; ++i)
		{
			if (!dirWalk.next(directories[i], true))
			{
				// Couldn't create/move to that directory for some reason
				throw new Exception("Couldn't add file");
			}
		}

		// Should now be in the correct directory
		if (!dirWalk.createFile(filename, data))
		{
			throw new Exception("Couldn't create file");
		}
	}

	void addDirectory(string path)
	{
		if (!is_directory_path(path))
		{
			throw new Exception("Path is not a directory path: " ~ path);
		}

		string[] directories = split(path, "/");
		DirectoryWalker dirWalk = new DirectoryWalker();
		for (int i = 1; i < directories.length; ++i)
		{
			if (!dirWalk.next(directories[i], true))
			{
				throw new Exception("Couldn't create directory");
			}
		}
	}

	void write(string filename)
	{
		io.write(filename, file_system);
	}
}

void zero(void* p, ulong size_in_bytes)
{
	ubyte* ptr = cast(ubyte*)p;
	uint i = 0;
	while (size_in_bytes > 0) 
	{
		ptr[i++] = 0;
		--size_in_bytes;
	}
}

void strcopy(char[] dest, string src)
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
