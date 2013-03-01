module kernel.layer1.process.scheduler;

import kernel.layer0.types;
import kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.memory.iVirtualAllocator : switch_page_directory, g_kernelTable, free_page_directory;

import kernel.layer1.process.pcb;
import kernel.layer1.blockallocator;
import kernel.layer1.linkedlist;
import kernel.layer1.elf.loader;
import kernel.layer1.addressspace;

__gshared:
nothrow:
private:

public ProcessControlBlock* g_currentPCB;

private enum NUMBER_OF_READY_QUEUES = Priority.max + 1; // The count starts at 0
private alias LinkedList!(ProcessControlBlock*) ReadyQueue;
private ReadyQueue[NUMBER_OF_READY_QUEUES] g_ready_queues;

public LinkedList!(ProcessControlBlock*) g_pcb_list;

private BlockAllocator!(ProcessControlBlock)* g_pcb_allocator = void;

private ProcessControlBlock* g_idle_pcb;

public void 
scheduler_initialize()
{
	g_currentPCB = null;

	g_pcb_allocator = BlockAllocator!(ProcessControlBlock).create_allocator(
			cast(ProcessControlBlock*)0xD0000000, 
			cast(ProcessControlBlock*)0xD1000000);

	// Need to make sure constructors work
	g_pcb_list.init();
	for (int i = 0; i < g_ready_queues.length; ++i)
	{
		g_ready_queues[i].init();
	}

	g_currentPCB = alloc_pcb();
	g_currentPCB.pid = next_pid();
	g_currentPCB.ppid = 0;
	g_currentPCB.state = State.READY;
	g_currentPCB.quantum = Quantum.STANDARD;
	g_currentPCB.priority = Priority.IDLE;
	
	g_currentPCB.page_directory = new_address_space();
	switch_page_directory(g_currentPCB.page_directory);

	serial_outln("KERNEL PD: ", cast(uint) g_kernelTable);
	serial_outln("PCB PD   : ", cast(uint) g_currentPCB.page_directory);

	if (load_from_file(g_currentPCB, "/idle") != Status.SUCCESS)
	{
		panic("ELF: Didn't load properly");
	}

	if (schedule(g_currentPCB) != Status.SUCCESS)
	{
		panic("Could't schedule idle process");
	}

	//switch_page_directory(g_kernelTable);

	serial_outln("Scheduler initialized");
}

public ProcessControlBlock*
alloc_pcb()
{
	return g_pcb_allocator.alloc();
}

/*
public void
free_pcb(ProcessControlBlock* pcb)
{
	g_pcb_allocator.free(pcb);	
}
*/

private bool pcb_priority_compare(ProcessControlBlock* pcb1, ProcessControlBlock* pcb2)
{
	return pcb1.priority < pcb2.priority;
}

public Status 
schedule(ProcessControlBlock* pcb)
{
	if (pcb == null)
	{
		return Status.BAD_PARAM;
	}

	Priority p = pcb.priority;
	if (p >= NUMBER_OF_READY_QUEUES)
	{
		return Status.BAD_PRIO;
	}

	pcb.state = State.READY;
	
	if (g_ready_queues[p].insert_ordered(pcb, &pcb_priority_compare))
	{
		serial_outln("Added to read queue");
		return Status.SUCCESS;
	}
	else
	{
		return Status.FAILURE;
	}
}

// Called by the clock ISR
public void
update_pcbs()
{
	if (g_currentPCB.quantum < 1)
	{
		Status status = schedule(g_currentPCB);
		if (status != Status.SUCCESS)
		{
			serial_outln("Failed to schedule");
			cleanup(g_currentPCB);
		}
		dispatch();
	}
	else
	{
		g_currentPCB.quantum--;
	}
}

public void
cleanup(ProcessControlBlock* pcb)
{
	if (pcb == null)
	{
		return;
	}

	pcb.state = State.FREE;

	// Remove it from the global list
	g_pcb_list.remove(pcb);

	if (pcb != g_currentPCB)
	{
		free_page_directory(pcb.page_directory);
	}
	else
	{
		free_page_directory(pcb.page_directory);
		switch_page_directory(g_kernelTable);
	}

	g_pcb_allocator.free(pcb);
}

public void
dispatch()
{
	serial_outln("DISPATCH");
	for (int i = 0; i < g_ready_queues.length; ++i)
	{
		do
		{
			if (g_ready_queues[i].empty())
			{
				break;
			}

			if (g_ready_queues[i].remove_front(g_currentPCB))
			{
				if (g_currentPCB.state == State.KILLED)
				{
					cleanup(g_currentPCB);
					// Find someone else to schedule
					continue;
				}

				g_currentPCB.state = State.RUNNING;
				g_currentPCB.quantum = Quantum.STANDARD;
				switch_page_directory(g_currentPCB.page_directory);

				serial_outln("Chose pcb");
				return;
			}
			else
			{
				panic("Dispatch: ready queue ", i, " failed to remove PCB");
			}
		} while(true);
	}

	panic("Dispatch: all ready queues are empty!");
}


