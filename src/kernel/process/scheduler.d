module kernel.process.scheduler;

import kernel.types;
import kernel.process.pcb;
import kernel.linkedlist;
import kernel.serial;
import kernel.support;
import kernel.memory.iVirtualAllocator : switch_page_directory;

__gshared:
nothrow:
private:

public ProcessControlBlock* g_currentPCB;

private enum NUMBER_OF_READY_QUEUES = Priority.max + 1;
private alias LinkedList!(ProcessControlBlock*) ReadyQueue;
private ReadyQueue[NUMBER_OF_READY_QUEUES] g_ready_queues;

public void 
scheduler_initialize()
{
	g_currentPCB = null;

	serial_outln("Scheduler initialized");
}

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
		return Status.SUCCESS;
	}
	else
	{
		return Status.FAILURE;
	}
}

private void
cleanup(ProcessControlBlock* pcb)
{
	// TODO - Implement cleaning up processes
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
			}
			else
			{
				panic("Dispatch: ready queue ", i, " failed to remove PCB");
			}
		} while(true);
	}

	panic("Dispatch: all ready queues are empty!");
}


