module kernel.types;

__gshared:
nothrow:
public:

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
