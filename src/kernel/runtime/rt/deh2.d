/**
 * Written in the D programming language.
 * Implementation of exception handling support routines for Posix and Win64.
 *
 * Copyright: Copyright Digital Mars 2000 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright, Sean Kelly
 * Source: $(DRUNTIMESRC src/rt/_deh2.d)
 */

module rt.deh2;

version = deh2;

// Use deh.d for Win32

version (deh2)
{

//debug=1;
debug import core.stdc.stdio : printf;

extern (C)
{
	extern __gshared
	{
		/* Symbols created by the compiler and inserted into the object file
		 * that 'bracket' the __deh_eh segment
		 */
		void* _deh_beg;
		void* _deh_end;
	}

    Throwable.TraceInfo _d_traceContext(void* ptr = null);

    int _d_isbaseof(ClassInfo oc, ClassInfo c);

    void _d_createTrace(Object*);
}

alias int function() fp_t;   // function pointer in ambient memory model

// DHandlerInfo table is generated by except_gentables() in eh.c

struct DHandlerInfo
{
    uint offset;                // offset from function address to start of guarded section
    uint endoffset;             // offset of end of guarded section
    int prev_index;             // previous table index
    uint cioffset;              // offset to DCatchInfo data from start of table (!=0 if try-catch)
    size_t finally_offset;      // offset to finally code to execute
                                // (!=0 if try-finally)
}

// Address of DHandlerTable, searched for by eh_finddata()

struct DHandlerTable
{
    uint espoffset;             // offset of ESP from EBP
    uint retoffset;             // offset from start of function to return code
    size_t nhandlers;           // dimension of handler_info[] (use size_t to set alignment of handler_info[])
    DHandlerInfo handler_info[1];
}

struct DCatchBlock
{
    ClassInfo type;             // catch type
    size_t bpoffset;            // EBP offset of catch var
    size_t codeoffset;          // catch handler offset
}

// Create one of these for each try-catch
struct DCatchInfo
{
    size_t ncatches;                    // number of catch blocks
    DCatchBlock catch_block[1];         // data for each catch block
}

// One of these is generated for each function with try-catch or try-finally

struct FuncTable
{
    void *fptr;                 // pointer to start of function
    DHandlerTable *handlertable; // eh data for this function
    uint fsize;         // size of function in bytes
}

private
{
    struct InFlight
    {
        InFlight*   next;
        void*       addr;
        Throwable   t;
    }

    InFlight* __inflight = null;
}

void terminate()
{
    asm
    {
        hlt ;
    }
}

/*******************************************
 * Given address that is inside a function,
 * figure out which function it is in.
 * Return DHandlerTable if there is one, NULL if not.
 */

FuncTable *__eh_finddata(void *address)
{
    debug printf("FuncTable.sizeof = %p\n", FuncTable.sizeof);
    debug printf("__eh_finddata(address = %p)\n", address);

	auto pstart = cast(FuncTable *)&_deh_beg;
	auto pend   = cast(FuncTable *)&_deh_end;

    debug printf("_deh_beg = %p, _deh_end = %p\n", pstart, pend);

    for (auto ft = pstart; 1; ft++)
    {
     Lagain:
        if (ft >= pend)
            break;

        version (Win64)
        {
            /* The MS Linker has an inexplicable and erratic tendency to insert
             * 8 zero bytes between sections generated from different .obj
             * files. This kludge tries to skip over them.
             */
            if (ft.fptr == null)
            {
                ft = cast(FuncTable *)(cast(void**)ft + 1);
                goto Lagain;
            }
        }

        debug printf("  ft = %p, fptr = %p, handlertable = %p, fsize = x%03x\n",
              ft, ft.fptr, ft.handlertable, ft.fsize);

        void *fptr = ft.fptr;

        if (fptr <= address &&
            address < cast(void *)(cast(char *)fptr + ft.fsize))
        {
            debug printf("\tfound handler table\n");
            return ft;
        }
    }
    debug printf("\tnot found\n");
    return null;
}


/******************************
 * Given EBP, find return address to caller, and caller's EBP.
 * Input:
 *   regbp       Value of EBP for current function
 *   *pretaddr   Return address
 * Output:
 *   *pretaddr   return address to caller
 * Returns:
 *   caller's EBP
 */

size_t __eh_find_caller(size_t regbp, size_t *pretaddr)
{
    size_t bp = *cast(size_t *)regbp;

    if (bp)         // if not end of call chain
    {
        // Perform sanity checks on new EBP.
        // If it is screwed up, terminate() hopefully before we do more damage.
        if (bp <= regbp)
            // stack should grow to smaller values
            terminate();

        *pretaddr = *cast(size_t *)(regbp + size_t.sizeof);
    }
    return bp;
}


/***********************************
 * Throw a D object.
 */

extern (C) void _d_throwc(Object *h)
{
    size_t regebp;

    debug
    {
        printf("_d_throw(h = %p, &h = %p)\n", h, &h);
        printf("\tvptr = %p\n", *cast(void **)h);
    }

    version (D_InlineAsm_X86)
        asm
        {
            mov regebp,EBP  ;
        }
    else version (D_InlineAsm_X86_64)
        asm
        {
            mov regebp,RBP  ;
        }
    else
        static assert(0);

    _d_createTrace(h);

//static uint abc;
//if (++abc == 2) *(char *)0=0;

//int count = 0;
    while (1)           // for each function on the stack
    {
        size_t retaddr;

        regebp = __eh_find_caller(regebp,&retaddr);
        if (!regebp)
        {   // if end of call chain
            debug printf("end of call chain\n");
            break;
        }

        debug printf("found caller, EBP = %p, retaddr = %p\n", regebp, retaddr);
//if (++count == 12) *(char*)0=0;
        auto func_table = __eh_finddata(cast(void *)retaddr);   // find static data associated with function
        auto handler_table = func_table ? func_table.handlertable : null;
        if (!handler_table)         // if no static data
        {
            debug printf("no handler table\n");
            continue;
        }
        auto funcoffset = cast(size_t)func_table.fptr;
        version (Win64)
        {
            /* If linked with /DEBUG, the linker rewrites it so the function pointer points
             * to a JMP to the actual code. The address will be in the actual code, so we
             * need to follow the JMP.
             */
            if ((cast(ubyte*)funcoffset)[0] == 0xE9)
            {   // JMP target = RIP of next instruction + signed 32 bit displacement
                funcoffset = funcoffset + 5 + *cast(int*)(funcoffset + 1);
            }
        }
        auto spoff = handler_table.espoffset;
        auto retoffset = handler_table.retoffset;

        debug
        {
            printf("retaddr = %p\n", retaddr);
            printf("regebp=%p, funcoffset=%p, spoff=x%x, retoffset=x%x\n",
            regebp,funcoffset,spoff,retoffset);
        }

        // Find start index for retaddr in static data
        auto dim = handler_table.nhandlers;

        debug
        {
            printf("handler_info[%d]:\n", dim);
            for (int i = 0; i < dim; i++)
            {
                auto phi = &handler_table.handler_info.ptr[i];
                printf("\t[%d]: offset = x%04x, endoffset = x%04x, prev_index = %d, cioffset = x%04x, finally_offset = %x\n",
                        i, phi.offset, phi.endoffset, phi.prev_index, phi.cioffset, phi.finally_offset);
            }
        }

        auto index = -1;
        for (int i = 0; i < dim; i++)
        {
            auto phi = &handler_table.handler_info.ptr[i];

            debug printf("i = %d, phi.offset = %04x\n", i, funcoffset + phi.offset);
            if (retaddr > funcoffset + phi.offset &&
                retaddr <= funcoffset + phi.endoffset)
                index = i;
        }
        debug printf("index = %d\n", index);

        if (dim)
        {
            auto phi = &handler_table.handler_info.ptr[index+1];
            debug printf("next finally_offset %p\n", phi.finally_offset);
            auto prev = cast(InFlight*) &__inflight;
            auto curr = prev.next;

            if (curr !is null && curr.addr == cast(void*)(funcoffset + phi.finally_offset))
            {
                auto e = cast(Error)(cast(Throwable) h);
                if (e !is null && (cast(Error) curr.t) is null)
                {
                    debug printf("new error %p bypassing inflight %p\n", h, curr.t);

                    e.bypassedException = curr.t;
                    prev.next = curr.next;
                    //h = cast(Object*) t;
                }
                else
                {
                    debug printf("replacing thrown %p with inflight %p\n", h, __inflight.t);

                    auto t = curr.t;
                    auto n = curr.t;

                    while (n.next)
                        n = n.next;
                    n.next = cast(Throwable) h;
                    prev.next = curr.next;
                    h = cast(Object*) t;
                }
            }
        }

        // walk through handler table, checking each handler
        // with an index smaller than the current table_index
        int prev_ndx;
        for (auto ndx = index; ndx != -1; ndx = prev_ndx)
        {
            auto phi = &handler_table.handler_info.ptr[ndx];
            prev_ndx = phi.prev_index;
            if (phi.cioffset)
            {
                // this is a catch handler (no finally)

                auto pci = cast(DCatchInfo *)(cast(char *)handler_table + phi.cioffset);
                auto ncatches = pci.ncatches;
                for (int i = 0; i < ncatches; i++)
                {
                    auto ci = **cast(ClassInfo **)h;

                    auto pcb = &pci.catch_block.ptr[i];

                    if (_d_isbaseof(ci, pcb.type))
                    {
                        // Matched the catch type, so we've found the handler.

                        // Initialize catch variable
                        *cast(void **)(regebp + (pcb.bpoffset)) = h;

                        // Jump to catch block. Does not return.
                        {
                            size_t catch_esp;
                            fp_t catch_addr;

                            catch_addr = cast(fp_t)(funcoffset + pcb.codeoffset);
                            catch_esp = regebp - handler_table.espoffset - fp_t.sizeof;
                            version (D_InlineAsm_X86)
                                asm
                                {
                                    mov     EAX,catch_esp   ;
                                    mov     ECX,catch_addr  ;
                                    mov     [EAX],ECX       ;
                                    mov     EBP,regebp      ;
                                    mov     ESP,EAX         ; // reset stack
                                    ret                     ; // jump to catch block
                                }
                            else version (D_InlineAsm_X86_64)
                                asm
                                {
                                    mov     RAX,catch_esp   ;
                                    mov     RCX,catch_esp   ;
                                    mov     RCX,catch_addr  ;
                                    mov     [RAX],RCX       ;
                                    mov     RBP,regebp      ;
                                    mov     RSP,RAX         ; // reset stack
                                    ret                     ; // jump to catch block
                                }
                            else
                                static assert(0);
                        }
                    }
                }
            }
            else if (phi.finally_offset)
            {
                // Call finally block
                // Note that it is unnecessary to adjust the ESP, as the finally block
                // accesses all items on the stack as relative to EBP.
                debug printf("calling finally_offset %p\n", phi.finally_offset);

                auto     blockaddr = cast(void*)(funcoffset + phi.finally_offset);
                InFlight inflight;

                inflight.addr = blockaddr;
                inflight.next = __inflight;
                inflight.t    = cast(Throwable) h;
                __inflight    = &inflight;

                version (OSX)
                {
                    version (D_InlineAsm_X86)
                        asm
                        {
                            sub     ESP,4           ;
                            push    EBX             ;
                            mov     EBX,blockaddr   ;
                            push    EBP             ;
                            mov     EBP,regebp      ;
                            call    EBX             ;
                            pop     EBP             ;
                            pop     EBX             ;
                            add     ESP,4           ;
                        }
                    else version (D_InlineAsm_X86_64)
                        asm
                        {
                            sub     RSP,8           ;
                            push    RBX             ;
                            mov     RBX,blockaddr   ;
                            push    RBP             ;
                            mov     RBP,regebp      ;
                            call    RBX             ;
                            pop     RBP             ;
                            pop     RBX             ;
                            add     RSP,8           ;
                        }
                    else
                        static assert(0);
                }
                else
                {
                    version (D_InlineAsm_X86)
                        asm
                        {
                            push    EBX             ;
                            mov     EBX,blockaddr   ;
                            push    EBP             ;
                            mov     EBP,regebp      ;
                            call    EBX             ;
                            pop     EBP             ;
                            pop     EBX             ;
                        }
                    else version (D_InlineAsm_X86_64)
                        asm
                        {
                            sub     RSP,8           ;
                            push    RBX             ;
                            mov     RBX,blockaddr   ;
                            push    RBP             ;
                            mov     RBP,regebp      ;
                            call    RBX             ;
                            pop     RBP             ;
                            pop     RBX             ;
                            add     RSP,8           ;
                        }
                    else
                        static assert(0);
                }

                if (__inflight is &inflight)
                    __inflight = __inflight.next;
            }
        }
    }
    terminate();
}

}