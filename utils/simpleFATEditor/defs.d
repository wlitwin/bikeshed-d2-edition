module defs;

struct BootRecord 
{
	// At cluster 0
	uint root_directory; // Cluster of the root directory
	uint fat_size; // # of clusters FAT takes up, FAT defined to start at cluster 1
	uint cluster_size;
	uint file_system_size;
	uint max_fat_entries;
}

struct Directory
{
	char file_name[112];
	uint type; // 00 - File, FF - Directory, AA - Deleted file, DD - Deleted directory
	uint cluster; // Cluster this file/directory lives in
	uint file_size; // Size of the file 0 for directories
	uint creation; // Creation time, optional
}

enum ClusterType : uint
{
	Free = 0x00,
	Reserved = 0xFFFFFFFE,
	End_Of_Chain = 0xFFFFFFFF,
}

enum DirectoryType : uint
{
	File = 0x00,
	Directory = 0xFF,
	Deleted_File = 0xAA,
	Deleted_Directory = 0xDD,
}
