module kernel.process.pcb;

import kernel.interrupt_defs : InterruptContext;

__gshared:
nothrow:

alias uint Time;
alias ushort Pid;
alias uint Stack;
alias InterruptContext Context;

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
	Context* context;
	Stack* stack;
	Time wakeup;

	// 2-byte fields
	Pid pid;
	Pid ppid;

	// 1-byte fields
	State state;       // Current process state
	Priority priority; // Current process priority
	ubyte quantum;     // Remaining process quantum
}
