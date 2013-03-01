module kernel.layer1.process.pcb;

import kernel.layer0.interrupts : InterruptContext;
import kernel.layer0.memory.iVirtualAllocator : PageDirectory;

__gshared:
nothrow:

alias uint Time;
alias ushort Pid;
alias uint Stack;
alias InterruptContext Context;

uint RET(ProcessControlBlock* pcb)
{
	return pcb.context.EAX;
}

uint* ARG(ProcessControlBlock* pcb)
{
	return cast(uint*)(pcb.context + 1);
}

enum Quantum : ubyte
{
	STANDARD = 10,
}

enum State : ubyte
{
	FREE = 0,
	NEW,
	READY,
	RUNNING,
	SLEEPING,
	BLOCKED,
	KILLED,
};

enum Priority : ubyte
{
	HIGH = 0,
	STANDARD,
	LOW,
	IDLE,
};

private Pid current_pid = 1;
public Pid next_pid()
{
	return ++current_pid;
}

struct ProcessControlBlock 
{
public:
nothrow:
	// 4-byte fields
	Context* context; // Must be first
	Stack* stack;
	Time wakeup;
	PageDirectory* page_directory;

	// 2-byte fields
	Pid pid;
	Pid ppid;

	// 1-byte fields
	State state;       // Current process state
	Priority priority; // Current process priority
	Quantum quantum;     // Remaining process quantum
}
