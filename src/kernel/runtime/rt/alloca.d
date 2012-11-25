/**
 * Implementation of alloca() standard C routine.
 *
 * Copyright: Copyright Digital Mars 2000 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright
 * Source: $(DRUNTIMESRC src/rt/_alloca.d)
 */

module rt.alloca;

version = alloca;

// Use DMC++'s alloca() for Win32

version (alloca)
{

/+
#if DOS386
extern size_t _x386_break;
#else
extern size_t _pastdata;
#endif
+/

/*******************************************
 * Allocate data from the caller's stack frame.
 * This is a 'magic' function that needs help from the compiler to
 * work right, do not change its name, do not call it from other compilers.
 * Input:
 *      nbytes  number of bytes to allocate
 *      ECX     address of variable with # of bytes in locals
 *              This is adjusted upon return to reflect the additional
 *              size of the stack frame.
 * Returns:
 *      EAX     allocated data, null if stack overflows
 */

extern (C) void* __alloca(int nbytes)
{
  version (D_InlineAsm_X86)
  {
    asm
    {
        naked                   ;
        mov     EDX,ECX         ;
        mov     EAX,4[ESP]      ; // get nbytes
        push    EBX             ;
        push    EDI             ;
        push    ESI             ;


        add     EAX,3           ;
        and     EAX,0xFFFFFFFC  ; // round up to dword


        jnz     Abegin          ;
        mov     EAX,4           ; // allow zero bytes allocation, 0 rounded to dword is 4..
    Abegin:
        mov     ESI,EAX         ; // ESI = nbytes
        neg     EAX             ;
        add     EAX,ESP         ; // EAX is now what the new ESP will be.
        jae     Aoverflow       ;
    }

    version (Unix)
    {
    asm
    {
        cmp     EAX,_pastdata   ;
        jbe     Aoverflow       ; // Unlikely - ~2 Gbytes under UNIX
    }
    }

    asm
    {
        // Copy down to [ESP] the temps on the stack.
        // The number of temps is (EBP - ESP - locals).
        mov     ECX,EBP         ;
        sub     ECX,ESP         ;
        sub     ECX,[EDX]       ; // ECX = number of temps (bytes) to move.
        add     [EDX],ESI       ; // adjust locals by nbytes for next call to alloca()
        mov     ESP,EAX         ; // Set up new stack pointer.
        add     EAX,ECX         ; // Return value = ESP + temps.
        mov     EDI,ESP         ; // Destination of copy of temps.
        add     ESI,ESP         ; // Source of copy.
        shr     ECX,2           ; // ECX to count of dwords in temps
                                  // Always at least 4 (nbytes, EIP, ESI,and EDI).
        rep                     ;
        movsd                   ;
        jmp     done            ;

    Aoverflow:
        // Overflowed the stack.  Return null
        xor     EAX,EAX         ;

    done:
        pop     ESI             ;
        pop     EDI             ;
        pop     EBX             ;
        ret                     ;
    }
  }
  else
        static assert(0);
}

}
