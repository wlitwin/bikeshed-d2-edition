import kernel.layer1.malloc;

// A quick note - This linked list will deallocate the entire LinkedNode when
// removing something from the list. This means if T is not a pointer or a
// simple copyable type then it will be invalid memory.

__gshared:
nothrow:

struct LinkedNode(T)
{
	LinkedNode* next;
	LinkedNode* prev;
	T data;
}

struct LinkedList(T)
{
public:
nothrow:
	LinkedNode!T* head;
	LinkedNode!T* tail;
	uint size;

	bool append(ref T val)
	{
		LinkedNode!(T)* new_node = cast(LinkedNode!(T)*)kmalloc(LinkedNode!T.sizeof);

		if (new_node == null)
		{
			return false;
		}

		new_node.data = val;
		new_node.next = null;

		if (head == null)
		{
			head = tail = new_node;
			new_node.prev = null;
		}
		else
		{
			tail.next = new_node;
			new_node.prev = tail;
			tail = new_node;
		}

		++size;
		return true;
	}

	bool remove(LinkedNode!T* node)
	{
		if (empty())
		{
			return false;
		}

		if (node == head && node == tail)
		{
			head = tail = null;
		}
		else if (node == head)
		{
			head = head.next;
			head.prev = null;
		}
		else if (node == tail)
		{
			tail = tail.prev;
			tail.next = null;
		}

		kfree(cast(void*)node);

		--size;
		return true;
	}

	bool remove(ref in T val)
	{
		if (empty())
		{
			return false;
		}

		LinkedNode!T* node = head;
		while (node != null)
		{
			if (node.data == val)
			{
				// The other overload of remove
				// handles decrementing the size
				return remove(node);
			}

			node = node.next;
		}

		return false;
	}

	bool find(scope bool delegate(ref in T obj) nothrow pred, out T found)
	{
		LinkedNode!(T)* node = head;
		while (node != null)
		{
			if (pred(node.data))
			{
				found = node.data;
				return true;
			}
		}

		return false;
	}

	bool insert_ordered(ref T val, bool function(T t1, T t2) nothrow compare)
	{
		LinkedNode!(T)* new_node = cast(LinkedNode!(T)*)kmalloc(LinkedNode!T.sizeof);

		if (new_node == null)
		{
			return false;
		}

		new_node.data = val;

		if (empty())
		{
			head = tail = new_node;
		}
		else
		{
			// Search and find out where to place this node
			LinkedNode!(T)* node = head; 
			while (node != null && compare(node.data, new_node.data))
			{
				node = node.next;
			}

			if (node == head)
			{
				head = new_node;
				new_node.prev = null;
				new_node.next = node;
				node.prev = new_node;
			}
			else if (node == null)
			{
				tail.next = new_node;
				new_node.prev = tail;
				new_node.next = null;
				tail = new_node;
			}
			else
			{
				node.prev.next = new_node;
				new_node.next = node;
				new_node.prev = node.prev;
				node.prev = new_node;
			}
		}

		++size;
		return true;
	}

	bool add_front(ref T val)
	{
		LinkedNode!(T)* new_node = cast(LinkedNode!(T)*)kmalloc(LinkedNode!T.sizeof);

		if (new_node == null)
		{
			return false;
		}

		new_node.data = val;

		if (head == null)
		{
			head = tail = new_node;
		}
		else
		{
			head.prev = new_node;
			new_node.next = head;
			new_node.prev = null;
			head = new_node;
		}

		++size;
		return true;
	}

	bool remove_front(out T outval)
	{
		if (empty())
		{
			return false;
		}

		outval = head.data;	

		if (head == tail)
		{
			kfree(cast(void*)head);
			head = tail = null;
		}
		else
		{
			head = head.next;
			kfree(cast(void*)head.prev);
			head.prev = null;
		}

		--size;
		return true;
	}

	bool empty()
	{
		return size == 0;
	}

	T front()
	{
		if (head != null) 
			return head.data;
		else
			return T.init;	
	}
}
