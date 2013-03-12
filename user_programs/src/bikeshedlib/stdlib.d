module bikeshedlib.stdlib;

__gshared:
nothrow:

enum INT_SYS_CALL = 0x80;

alias ushort Pid;

enum Priority : ubyte
{
	HIGH = 0,
	STANDARD,
	LOW,
	IDLE,
};

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

enum Status : uint
{
	SUCCESS = 0,
	FAILURE,
	BAD_PARAM,
	ALLOC_FAILED,
	NOT_FOUND,
	NO_QUEUES,
	BAD_PRIO,
	FEATURE_UNIMPLEMENTED,
	STATUS_SENTINEL,
}

extern (C):

Status fork(Pid* pid) 
{
	asm {
		naked;
		mov EAX, Syscalls.FORK;
		int INT_SYS_CALL;
		ret;
	}
}

void exec(string file)
{
	asm {
		naked;
		mov EAX, Syscalls.EXEC;
		int INT_SYS_CALL;
		ret;
	}
}

uint get_pid()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_PID;
		int INT_SYS_CALL;
		ret;
	}
}

uint get_ppid()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_PPID;
		int INT_SYS_CALL;
		ret;
	}
}

State get_state()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_STATE;
		int INT_SYS_CALL;
		ret;
	}
}

void set_priority(Priority prio)
{
	asm {
		naked;
		mov EAX, Syscalls.SET_PRIORITY;
		int INT_SYS_CALL;
		ret;
	}
}

Priority get_priority()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_PRIORTY;
		int INT_SYS_CALL;
		ret;
	}
}

Status msleep(uint time)
{
	asm {
		naked;
		mov EAX, Syscalls.MSLEEP;
		int INT_SYS_CALL;
		ret;
	}
}

uint get_time()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_TIME;
		int INT_SYS_CALL;
		ret;
	}
}

Status set_time(uint time)
{
	asm {
		naked;
		mov EAX, Syscalls.SET_TIME;
		int INT_SYS_CALL;
		ret;
	}
}

void exit()
{
	asm {
		naked;
		mov EAX, Syscalls.EXIT;
		int INT_SYS_CALL;
		ret;
	}
}
