import kernel.layer1.linkedlist;
import kernel.layer1.process.pcb;
import kernel.layer1.process.scheduler;
import kernel.layer1.clock : system_time;
import kernel.layer1.elf.loader : load_from_file;

import kernel.layer0.interrupts;
import kernel.layer0.support;
import kernel.layer0.serial;
import kernel.layer0.types;
import kernel.layer0.memory.util;
import kernel.layer0.memory.iVirtualAllocator;

import glue : alloca;

__gshared:
nothrow:
private:

enum Syscalls : uint
{
	FORK = 0,
	EXEC,
	EXIT,
	MSLEEP,
	READ,
	WRITE,
	KILL,
	GET_PRIORTY,
	GET_PID,
	GET_PPID,
	GET_STATE,
	GET_TIME,
	SET_PRIORITY,
	SET_TIME,
}

enum INT_VEC_SYSCALL = 0x80;

void function(ProcessControlBlock*) syscall_table[Syscalls.max+1];

alias LinkedList!(ProcessControlBlock*) SleepQueue;

private SleepQueue g_sleep_queue;

public void
syscalls_initialize()
{
	syscall_table[Syscalls.FORK]         = &sys_fork;
	syscall_table[Syscalls.EXEC]         = &sys_exec;
	syscall_table[Syscalls.EXIT]         = &sys_exit;
	syscall_table[Syscalls.MSLEEP]       = &sys_msleep;
	syscall_table[Syscalls.READ]         = &sys_read;
	syscall_table[Syscalls.WRITE]        = &sys_write;
	syscall_table[Syscalls.KILL]         = &sys_kill;
	syscall_table[Syscalls.GET_PRIORTY]  = &sys_get_priority;
	syscall_table[Syscalls.GET_PID]      = &sys_get_pid;
	syscall_table[Syscalls.GET_PPID]     = &sys_get_ppid;
	syscall_table[Syscalls.GET_STATE]    = &sys_get_state;
	syscall_table[Syscalls.GET_TIME]     = &sys_get_time;
	syscall_table[Syscalls.SET_PRIORITY] = &sys_set_priority;
	syscall_table[Syscalls.SET_TIME]     = &sys_set_time;
	
	install_isr(INT_VEC_SYSCALL, &isr_syscall);

	serial_outln("Syscalls initialized");
}

extern (C) void
isr_syscall(int vector, int code)
{
	if (g_currentPCB == null)
	{
		panic("ISR Syscall: No current PCB!");
	}

	if (g_currentPCB.context == null)
	{
		panic("ISR Syscall: No current context for the PCB!");
	}

	uint syscall_number = RET(g_currentPCB);
	if (syscall_number >= Syscalls.max+1)
	{
		serial_outln("BAD SYSCALL ", syscall_number);
		// Bad system call, kill the process
		syscall_number = Syscalls.EXIT;
	}

	syscall_table[syscall_number](g_currentPCB);

	__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
}

void sys_fork(ProcessControlBlock* pcb)
{
	ProcessControlBlock* new_pcb = alloc_pcb();
	if (new_pcb == null)
	{
		// Set the return value
		pcb.context.EAX = Status.FAILURE;
		return;
	}

	// Duplicate the parents PCB
	memcpy(cast(void*)new_pcb, cast(void*)pcb, ProcessControlBlock.sizeof);

	// Create a new page directory
	new_pcb.page_directory = clone_page_directory();

	// Fix the PCB fields
	new_pcb.pid = next_pid();
	new_pcb.ppid = pcb.pid;
	new_pcb.state = State.NEW;
	new_pcb.priority = Priority.HIGH;

	// Assign the PID return values for the two processes
	uint* ptr = cast(uint*)ARG(pcb)[1];	
	*ptr = new_pcb.pid;

	// The reason the page directories need to keep switching
	// is because the parent and child share the same virtual
	// address for their stack. So if the page directory wasn't
	// changed then the return value would just be overwritten
	// for the parent and the child would never get a proper
	// return value

	// Switch the page directory
	switch_page_directory(new_pcb.page_directory);

	ptr = cast(uint*)ARG(new_pcb)[1];
	*ptr = 0;

	switch_page_directory(pcb.page_directory);

	// Add this PCB to the master list
	g_pcb_list.append(new_pcb);

	/* We decide to schedule the child and let the parent continue
	 */
	Status status = schedule(new_pcb);
	if (status != Status.SUCCESS)
	{
		pcb.context.EAX = Status.FAILURE;
		cleanup(new_pcb);
	}
	else
	{
		// Set the return values for the parent and child
		pcb.context.EAX = Status.SUCCESS;
		switch_page_directory(new_pcb.page_directory);
		new_pcb.context.EAX = Status.SUCCESS;
		switch_page_directory(pcb.page_directory);
	}
}

void sys_exec(ProcessControlBlock* pcb)
{
	// Need to copy the string to the kernel stack
	string* file = cast(string*) (&ARG(pcb)[1]);
	serial_outln("File: ", *file, " Length: ", file.length);
	if (file.length > 200)
	{
		pcb.context.EAX = Status.BAD_PARAM;
		return;
	}

	serial_outln("File size: ", file.sizeof);

	// Copy the string onto the local stack
	struct Str
	{
		uint length;
		char* ptr;
	}

	Str str;
	str.length = file.length;
	str.ptr = cast(char*) alloca(file.length)[0..file.length];

	for (uint i = 0; i < str.length; ++i)
	{
		str.ptr[i] = file.ptr[i];
		serial_outln(str.ptr[i]);
	}

	string* s = cast(string*) &str;
	serial_outln("Str: ", *s, " Length: ", s.length);

	reset_page_directory();
	if (load_from_file(pcb, *s) != Status.SUCCESS)
	{
		panic("Exec failed");
	}

	pcb.context.EAX = Status.SUCCESS;
}

void sys_exit(ProcessControlBlock* pcb)
{
	// Deallocate everything used by this process
	cleanup(pcb);

	// Run some other process
	dispatch();
}

void sys_msleep(ProcessControlBlock* pcb)
{
	uint sleep_time = ARG(pcb)[1];
	
	if (sleep_time == 0)
	{
		// Pre-empt this process and let someone else go
		Status status = schedule(pcb);
		if (status != Status.SUCCESS)
		{
			// Couldn't reschedule for some reason
			pcb.context.EAX = Status.FAILURE;
			return;
		}
	}
	else
	{
		// Put it on the sleep queue
		pcb.wakeup = system_time + sleep_time;
		Status status = add_to_sleep_queue(pcb);
		if (status != Status.SUCCESS)
		{
			// Couldn't put this process to sleep
			pcb.context.EAX = Status.FAILURE;
			return;
		}
	}

	pcb.context.EAX = Status.SUCCESS;
	dispatch();
}

void sys_read(ProcessControlBlock* pcb)
{
	pcb.context.EAX = Status.FEATURE_UNIMPLEMENTED;
}

void sys_write(ProcessControlBlock* pcb)
{
	pcb.context.EAX = Status.FEATURE_UNIMPLEMENTED;
}

void sys_kill(ProcessControlBlock* pcb)
{
	Pid pid = cast(Pid)ARG(pcb)[1];

	// Find the PCB to kill
	bool compare(ref in ProcessControlBlock* pcb) nothrow
	{
		return pcb.pid == pid;
	}

	ProcessControlBlock* found_pcb = null;

	if (g_pcb_list.find(&compare, found_pcb))
	{
		// Mark this process as killed
		found_pcb.state = State.KILLED;	
		pcb.context.EAX = Status.SUCCESS;
	}
	else
	{
		// Didn't find the process
		pcb.context.EAX = Status.NOT_FOUND;
	}
}

void sys_get_priority(ProcessControlBlock* pcb)
{
	pcb.context.EAX = pcb.priority;
}

void sys_get_pid(ProcessControlBlock* pcb)
{
	pcb.context.EAX = pcb.pid;
}

void sys_get_ppid(ProcessControlBlock* pcb)
{
	pcb.context.EAX = pcb.ppid;
}

void sys_get_state(ProcessControlBlock* pcb)
{
	pcb.context.EAX = pcb.state;
}

void sys_get_time(ProcessControlBlock* pcb)
{
	pcb.context.EAX = system_time;
}

void sys_set_priority(ProcessControlBlock* pcb)
{
	Priority priority = cast(Priority)ARG(pcb)[1];

	if (priority <= Priority.max)
	{
		pcb.priority = priority;	
		pcb.context.EAX = Status.SUCCESS;
	}
	else
	{
		pcb.context.EAX = Status.FAILURE;
	}
}

void sys_set_time(ProcessControlBlock* pcb)
{
	system_time = ARG(pcb)[1];
	pcb.context.EAX = Status.SUCCESS;
}
