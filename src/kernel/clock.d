module kernel.clock;

import kernel.serial;
import kernel.support;
import kernel.interrupts;

enum TIMER_BASE_PORT = 0x40; // I/O Port for the timer

enum TIMER_0_LOAD = 0x30; // Load LSB, then MSB
enum TIMER_0_SQUARE = 0x06; // Square wave mode

enum TIMER_0_PORT = TIMER_BASE_PORT;
enum TIMER_1_PORT = TIMER_BASE_PORT + 1;
enum TIMER_2_PORT = TIMER_BASE_PORT + 2;
enum TIMER_CONTROL_PORT = TIMER_BASE_PORT + 3;

enum TIMER_FREQUENCY = 1193182;
enum CLOCK_FREQUENCY = 100;

void init_clock()
{
	serial_outln("\nClock: intializing");

	uint divisor = TIMER_FREQUENCY / CLOCK_FREQUENCY;
	
	__outb(TIMER_CONTROL_PORT, TIMER_0_LOAD | TIMER_0_SQUARE);
	__outb(TIMER_0_PORT, divisor & 0xFF); // LSB of divisor
	__outb(TIMER_0_PORT, (divisor >> 8) & 0xFF); // MSB of divisor

	install_isr(INT_VEC_TIMER, &isr_clock);

	serial_outln("Clock: Finished");
}

private extern (C)
void isr_clock(int vector, int code)
{
	serial_outln("Timer interrupt");
}
