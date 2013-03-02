module bikeshedlib.stdlib;

__gshared:
nothrow:

enum INT_SYS_CALL = 0x80;

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

Status fork() 
{
	asm {
		naked;
		mov EAX, Syscalls.FORK;
		int INT_SYS_CALL;
		ret;
	}
}

void exec()
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

uint get_priority()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_PRIORTY;
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

uint get_ppid()
{
	asm {
		naked;
		mov EAX, Syscalls.GET_PPID;
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
