module kernel.layer1.ramfs.fat;

import kernel.layer1.ramfs.def;
import kernel.layer1.ramfs.path;

// For printing debug information
import kernel.layer0.serial;

// For string operations
import kernel.layer1.strfuncs;

// Implementation of the Simple FAT FS
// Currently it's read-only

__gshared:
nothrow:

private:

// Assumes the FS lives in RAM
struct Context
{
private:
	BootRecord* boot_record;
	uint* FAT;
	ubyte* file_system;
	uint DIRS_PER_CLUSTER;

	/* Turn a cluster into a byte offset in the filesystem.
	 * Returns the index in the filesystem byte array of
	 * the cluster. Use cluster_address to get an actual
	 * memory location.
	 */
	uint cluster_offset(const uint index) const	
	{
		return index * boot_record.cluster_size;
	}

	/* Turns a cluster index into a memory address.
	 */
	ubyte* cluster_address(const uint index)
	{
		return &file_system[cluster_offset(index)];
	}

	/* Get a pointer to the root directory of the file system.
	 */
	Directory* get_root_directory()
	{
		return cast(Directory*) cluster_address(boot_record.root_dir_cluster);
	}

	/* Determine if the FAT has num_clusters free.
	 */
	bool has_space(uint num_clusters) const
	{
		for (int i = 0;
			  i < boot_record.max_fat_entries
			  && num_clusters > 0;
			  ++i)
		{
			if (FAT[i] == ClusterType.Free)
			{
				--num_clusters;
			}
		}

		return num_clusters == 0;
	}

	/* Find the next FAT entry that is marked as
	 * free. It starts looking from the passed 
	 * index.
	 */
	uint next_free_fat_index(uint index) const
	{
		assert(index < boot_record.max_fat_entries,
				"FAT: next_free_fat_index - argument too large");

		for (; index < boot_record.max_fat_entries; ++index)
		{
			if (FAT[index] == ClusterType.Free)
			{
				return index;
			}
		}

		// 0 is an invalid index always. It's reserved for
		// the boot record, so returning this means it's
		// no free entries were found.
		return 0;
	}

	struct DirectoryWalker
	{
		uint curCluster;
		Directory* curDir;
		Context* context;

		void initialize(Context* context)
		{
			curDir = context.get_root_directory();
			curCluster = context.boot_record.root_dir_cluster;
		}

		bool next(const string name)
		{
			if (!is_valid_name(name)) return false;

			// Don't modify the current directory and cluster
			// until we find a match
			uint cluster = curCluster;
			Directory* dir = curDir;
			for (int i = 0; i < context.DIRS_PER_CLUSTER; ++i)
			{
				if (dir[i].type == DirectoryType.Directory
					&& strequal(dir[i].name, name))
				{
					// Change the current directory
					curCluster = dir[i].cluster;
					curDir = cast(Directory*) context.cluster_address(curCluster);
					return true;
				}

				// Check if this directory extends onto 
				// another cluster
				if (i == context.DIRS_PER_CLUSTER-1
					&& context.FAT[cluster] != ClusterType.End_Of_Chain)
				{
					i = 0; // Keep looping
					cluster = context.FAT[cluster];
					dir = cast(Directory*) context.cluster_address(cluster);
				}
			}

			// Couldn't find the directory
			return false;
		}

		bool read(const string name,
				  ubyte* data,
				  uint file_offset,
				  uint num_bytes)
		{
			if (!is_valid_name(name)) return false;

			// Don't modify the current directory
			uint cluster = curCluster;	
			Directory* dir = curDir;

			for (int i = 0; i < context.DIRS_PER_CLUSTER; ++i)
			{
				if (dir[i].type == DirectoryType.File
					&& strequal(dir[i].name, name))
				{
					// Check to make sure the file offset
					// is within bounds
					if (file_offset >= dir[i].file_size) {
						return false;
					}

					// Make sure the num_bytes and file_offset
					// stay within bounds
					if (num_bytes > (dir[i].file_size - file_offset)) 
					{
						num_bytes = dir[i].file_size - file_offset;
					}

					// Seek to that offset in the file
					// and read num_bytes
					uint file_cluster = dir[i].cluster;

					while (file_offset > context.boot_record.cluster_size)
					{
						file_offset -= context.boot_record.cluster_size;
						assert(context.FAT[file_cluster] != ClusterType.End_Of_Chain, 
								"FAT: End of Chain reached while seeking");
						file_cluster = context.FAT[file_cluster];
					}

					ubyte* file_data = context.cluster_address(file_cluster) + file_offset;

					// Read num_bytes, slow byte copy ... TODO - Faster
					uint di = 0;
					uint fi = 0;
					while (num_bytes > 0)
					{
						data[di++] = file_data[fi++];
						--num_bytes;
					}

					return true;
				}

				if (i == context.DIRS_PER_CLUSTER-1
					&& context.FAT[cluster] != ClusterType.End_Of_Chain)
				{
					i = 0;
					cluster = context.FAT[cluster];
					dir = cast(Directory*) context.cluster_address(cluster);
				}
			}

			return false;
		}
	}
	
public:
	this(ubyte* location)
	{
		// Grab the boot record and perform some checks
		file_system = location;
		boot_record = cast(BootRecord*) location;
	
		// Make sure cluster size is a power of two
		assert((boot_record.cluster_size & 
				(boot_record.cluster_size - 1)) == 0,
				"FAT: Bad cluster size");

		// Determine how many directories per cluster
		// Assumes a cluster is always larger than a Directory,
		// would be kinda hard the other way around...
		DIRS_PER_CLUSTER = boot_record.cluster_size / Directory.sizeof;

		// The start of the FAT is always at cluster 1
		FAT = cast(uint*) cluster_address(1);		
	}

	bool read(string path, ubyte* data, 
			  uint file_offset, uint num_bytes)
	{
		if (!is_file_path(path)) return false;	

		DirectoryWalker dirWalker;
		dirWalker.initialize(&this);

		PathWalker pathWalker;
		pathWalker.initialize(get_directory_path(path));
		const string filename = get_file_name(path);
		do
		{
			if (!dirWalker.next(pathWalker.getName()))
			{
				return false;
			}
		} while (pathWalker.nextName());

		return dirWalker.read(filename, data, file_offset, num_bytes);
	}
}
