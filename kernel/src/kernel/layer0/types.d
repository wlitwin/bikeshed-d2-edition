module kernel.layer0.types;

__gshared:
nothrow:
public:

enum GDT_CODE = 0x0010;
enum GDT_DATA = 0x0018;
enum GDT_STACK = 0x0020;
enum EFLAGS_MB1 = 0x2;
enum EFLAGS_IF = 0x200;
enum DEFAULT_EFLAGS = EFLAGS_MB1 | EFLAGS_IF;

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
