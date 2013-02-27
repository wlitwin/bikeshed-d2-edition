module kernel.layer1.ramfs.def;

__gshared:
nothrow:

struct BootRecord // At cluster 0 of the FAT file system
{
	align(1):
	uint root_dir_cluster;  // Cluster of the root directory
	uint fat_size_clusters; // # of clusters the FAT takes up
	uint cluster_size;      // Cluster size in bytes
	uint file_system_size;  // File system size in bytes
	uint max_fat_entries;   // Max number of entries in the FAT
}

struct Directory
{
	align(1):
	char name[112]; // Name of the file or directory
	DirectoryType type; // Type: File, Directory, Free
	uint cluster;   // The cluster the contents start at
	uint file_size; // The size of the file in bytes, 0 for directories
	uint creation;  // The time the file was created
}

// Entries in the FAT correspond to this type
enum ClusterType : uint
{
	Free = 0x00000000,
	Reserved = 0xFFFFFFFE,
	End_Of_Chain = 0xFFFFFFFF,
}

enum DirectoryType : uint
{
	File = 0xEE,
	Directory = 0xFF,
	Free = 0x00,
}
