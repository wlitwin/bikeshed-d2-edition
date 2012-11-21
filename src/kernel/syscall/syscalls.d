module kernel.syscall.syscalls;

import kernel.linkedlist;
import kernel.process.pcb;
import kernel.interrupts;
import kernel.process.scheduler;
import kernel.support;
import kernel.serial;

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
	if (syscall_number >= Syscalls.max)
	{
		// Bad system call, kill the process
		syscall_number = Syscalls.EXIT;
	}

	syscall_table[syscall_number](g_currentPCB);

	__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
}

void sys_fork(ProcessControlBlock* pcb)
{
}

void sys_exec(ProcessControlBlock* pcb)
{
}

void sys_msleep(ProcessControlBlock* pcb)
{
}

void sys_read(ProcessControlBlock* pcb)
{
}

void sys_write(ProcessControlBlock* pcb)
{
}

void sys_kill(ProcessControlBlock* pcb)
{
}

void sys_get_priority(ProcessControlBlock* pcb)
{
}

void sys_get_pid(ProcessControlBlock* pcb)
{
}

void sys_get_ppid(ProcessControlBlock* pcb)
{
}

void sys_get_state(ProcessControlBlock* pcb)
{
}

void sys_get_time(ProcessControlBlock* pcb)
{
}

void sys_set_priority(ProcessControlBlock* pcb)
{
}

void sys_set_time(ProcessControlBlock* pcb)
{
}
