module kernel.layer0.memory.mmap_list;

import kernel.layer0.serial;
import kernel.layer0.support : panic;
import kernel.layer0.memory.memory : KERNEL_END;

__gshared:
nothrow:

align(1)
struct MemoryMap
{
	uint start;
	uint length;
}


private MemoryMap* g_mmap_start = void;
private int g_mmap_count = void;

void
initialize_mmap_list()
{
	// Assume the KERNEL_END symbol is at a 4-byte boundary
	g_mmap_start = cast(MemoryMap*) &KERNEL_END;
	g_mmap_count = 0;
}

int
get_mmap_count()
{
	return g_mmap_count;
}

MemoryMap*
get_mmap_start()
{
	return g_mmap_start;
}

void
add_usable_region(const uint region_start, const uint region_length)
{
	if (g_mmap_count == 0)
	{
		g_mmap_start.start  = region_start;
		g_mmap_start.length = region_length;
	}
	else
	{
		const uint rs_plus_rl = region_start + region_length;

		MemoryMap* cur_mmap = g_mmap_start;
		for (int i = 0; i < g_mmap_count; ++i, ++cur_mmap)
		{
			const uint mm_start  = cur_mmap.start;
			const uint mm_length = cur_mmap.length;
			const uint ms_plus_ml = mm_start + mm_length;

			// Check if the current mmap includes the current
			// SMAP range entirely
			if (region_start >= mm_start && rs_plus_rl <= ms_plus_ml)
			{
				return;
			}
			// Check if the SMAP entry overlaps towards the
			// beginning of the current MMAP entry
			else if (region_start <= mm_start && mm_start <= rs_plus_rl)
			{
				cur_mmap.start = region_start;
				if (rs_plus_rl > ms_plus_ml)
				{
					cur_mmap.length = region_length;
				}
				else
				{
					cur_mmap.length = ms_plus_ml - region_start;
				}
				return;
			}
			else if (mm_start <= region_start && region_start <= ms_plus_ml)
			{
				if (rs_plus_rl > ms_plus_ml)
				{
					cur_mmap.length = rs_plus_rl - mm_start;
				}
				return;
			}
		}

		// Can't combine... So make a new one
		cur_mmap.start  = region_start;
		cur_mmap.length = region_length;
	}

	++g_mmap_count;
}

void
reserve_region(const uint region_start, const uint region_length)
{
	MemoryMap* cur_mmap = g_mmap_start;
	MemoryMap* end_mmap = g_mmap_start + g_mmap_count;
	// Need to loop through and check all entries
	// A couple possibilities:
	//    - An entire region gets removed
	//    - A region gets split into two
	//    - Part of a region is removed (front or back)
	const uint rs_plus_rl = region_start + region_length;

	for (int i = 0; i < g_mmap_count; ++i, ++cur_mmap)
	{
		const uint mm_start  = cur_mmap.start;
		const uint mm_length = cur_mmap.length;
		const uint ms_plus_ml = mm_start + mm_length;

		// Region overlaps the whole block
		if (region_start <= mm_start &&
			rs_plus_rl >= ms_plus_ml)
		{
			// This region is dead
			cur_mmap.start  = -1;
			cur_mmap.length = -1;
		}
		// Region overlaps the left portion
		else if (region_start <= mm_start &&
				 mm_start < rs_plus_rl &&
				 ms_plus_ml > rs_plus_rl)
		{
			cur_mmap.start = rs_plus_rl;
			cur_mmap.length = ms_plus_ml - rs_plus_rl;
		}
		// Region overlaps the right portion
		else if (mm_start < region_start &&
				 region_start < ms_plus_ml &&
				 ms_plus_ml <= rs_plus_rl)
		{
			cur_mmap.length = region_start - mm_start;
		}
		// Region cuts out a middle portion
		else if (mm_start < region_start &&
				 ms_plus_ml > rs_plus_rl)
		{
			end_mmap.start  = rs_plus_rl;
			end_mmap.length = ms_plus_ml - rs_plus_rl;
			++end_mmap;

			cur_mmap.length = region_start - mm_start;
		}
	}

	// Do a second pass removing entries
	cur_mmap = g_mmap_start;
	int new_count = 0;
	while (cur_mmap != end_mmap)
	{
		if (cur_mmap.start < 0)
		{
			// Need to move entries over
			MemoryMap* mm_look_ahead = cur_mmap + 1;
			while (mm_look_ahead != end_mmap)
			{
				if (mm_look_ahead.start < 0) { ++mm_look_ahead; }
				else { break; }
			}
			
			if (mm_look_ahead == end_mmap)
			{
				// Done, the rest of the entries are marked 'deleted'
				break;
			}

			// Start copying
			cur_mmap.start  = mm_look_ahead.start;
			cur_mmap.length = mm_look_ahead.length;

			mm_look_ahead.start  = -1;
			mm_look_ahead.length = -1;
		}

		// Advance the current pointer
		++new_count;
		++cur_mmap;
	}

	g_mmap_count = new_count;
}

bool
is_range_usable(const uint region_start, const uint region_length)
{
	const(MemoryMap)* cur_mmap = g_mmap_start;
	for (int i = 0; i < g_mmap_count; ++i, ++cur_mmap)
	{
		if (region_start >= cur_mmap.start &&
			(region_start+region_length) <= (cur_mmap.start+cur_mmap.length))
		{
			return true;
		}
	}

	return false;
}

bool
is_region_reserved(const uint region_start, const uint region_length)
{
	return !is_range_usable(region_start, region_length);
}

void
print_mmap_list()
{
	const(MemoryMap)* mm = g_mmap_start;
	serial_outln("MMAP:");
	for (int i = 0; i < g_mmap_count; ++i, ++mm)
	{
		serial_outln("\tRegion Start: ", mm.start, " L: ", mm.length);
		//serial_outln("\tRegion Length:", mm.length);
	}
}
