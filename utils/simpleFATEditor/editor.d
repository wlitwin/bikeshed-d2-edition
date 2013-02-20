module editor;

import defs;
import io = std.file;
import std.stdio;
import std.conv;

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

	void addFile(string path, ubyte data[])
	{
		
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

void strcopy(char dest[], string src)
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
