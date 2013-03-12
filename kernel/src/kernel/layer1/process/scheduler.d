module kernel.layer1.process.scheduler;

import kernel.layer0.types;
import kernel.layer0.serial;
import kernel.layer0.support;
import kernel.layer0.memory.memory : g_memoryInfo, PAGE_SIZE;
import kernel.layer0.memory.iVirtualAllocator : switch_page_directory, g_kernelTable, free_page_directory;

import kernel.layer1.process.pcb;
import kernel.layer1.blockallocator;
import kernel.layer1.linkedlist;
import kernel.layer1.elf.loader;
import kernel.layer1.addressspace;
import kernel.layer1.clock : system_time;

__gshared:
nothrow:
private:

public ProcessControlBlock* g_currentPCB;

private enum NUMBER_OF_READY_QUEUES = Priority.max + 1; // The count starts at 0
private alias LinkedList!(ProcessControlBlock*) ReadyQueue;
private ReadyQueue[NUMBER_OF_READY_QUEUES] g_ready_queues;

public LinkedList!(ProcessControlBlock*) g_pcb_list;
public LinkedList!(ProcessControlBlock*) g_sleep_queue;

private BlockAllocator!(ProcessControlBlock)* g_pcb_allocator = void;

private ProcessControlBlock* g_idle_pcb;

public void 
scheduler_initialize()
{
	g_currentPCB = null;

	const uint PCB_ALLOCATOR_START = (g_memoryInfo.kernel_end & 0xFFFFF000) + PAGE_SIZE;
	const uint PCB_ALLOCATOR_END   = PCB_ALLOCATOR_START + 0x100000;

	// Update the kernel's end location
	g_memoryInfo.kernel_end = PCB_ALLOCATOR_END;
	serial_outln("NEW KERNEL END: ", g_memoryInfo.kernel_end);

	g_pcb_allocator = BlockAllocator!(ProcessControlBlock).create_allocator(
			cast(ProcessControlBlock*)PCB_ALLOCATOR_START,
			cast(ProcessControlBlock*)PCB_ALLOCATOR_END);

	// Need to make sure constructors work
	g_pcb_list.init();
	for (int i = 0; i < g_ready_queues.length; ++i)
	{
		g_ready_queues[i].init();
	}

	g_idle_pcb = g_currentPCB = alloc_pcb();
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

	//switch_page_directory(g_kernelTable);

	if (schedule(g_currentPCB) != Status.SUCCESS)
	{
		panic("Could't schedule idle process");
	}


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

private bool pcb_sleep_compare(ProcessControlBlock* pcb1, ProcessControlBlock* pcb2)
{
	return pcb1.wakeup < pcb2.wakeup;
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
	
	if (g_ready_queues[p].append(pcb))
	{
		//serial_outln("Added to read queue");
		return Status.SUCCESS;
	}
	else
	{
		return Status.FAILURE;
	}
}

public Status
add_to_sleep_queue(ProcessControlBlock* pcb)
{
	if (pcb == null)
	{
		panic("Add Sleep Queue: Got NULL pcb!");
		return Status.BAD_PARAM;
	}

	if (g_sleep_queue.insert_ordered(pcb, &pcb_sleep_compare))
	{
		pcb.state = State.SLEEPING;
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
	// Check for sleeping processes that need to be awakened
	do
	{
		ProcessControlBlock* head = g_sleep_queue.front();
		if (head == null || head.wakeup > system_time) {
			break;
		}

		// We need to wake this one up
		if (!g_sleep_queue.remove_front())
		{
			panic("Failed to remove from sleep queue!");
		}

		// Reset the wakeup time just in case
		head.wakeup = 0;

		// Schedule it
		if (schedule(head) != Status.SUCCESS)
		{
			// TODO - Kill the process?
			panic("Failed to schedule awakened process");
		}
	} while (true);

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

	// Remove it from the ready or sleep queues
	switch (pcb.state)
	{
		case State.SLEEPING:
			g_sleep_queue.remove(pcb);
			break;
		case State.RUNNING:
			g_ready_queues[pcb.priority].remove(pcb);
			break;
		default:
			break;
	}

	// TODO Free state unnecessary
	pcb.state = State.KILLED;

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


