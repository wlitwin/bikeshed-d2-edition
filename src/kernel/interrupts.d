module kernel.interrupts;

import kernel.interrupt_defs;
import kernel.templates;
import kernel.support;
import kernel.serial;

__gshared:

alias extern(C) void function(int vector, int code) isr_handler;
alias extern(C) void function() idt_handler;

isr_handler __isr_table[256];
idt_handler __idt_table[256];

enum IDT_ADDRESS = 0x2500;

enum INT_VEC_DIVIDE_ERROR    = 0x0;
enum INT_VEC_DEBUG_EXCEPTION = 0x1;
enum INT_VEC_NMI_INTERRUPT   = 0x2;
enum INT_VEC_BREAKPOINT      = 0x3;
enum INT_VEC_INTO_DETECTED_OVERFLOW = 0x4;
enum INT_VEC_BOUND_RANGE_EXCEEDED = 0x5;
enum INT_VEC_INVALID_OPCODE = 0x6;
enum INT_VEC_DEVICE_NOT_AVAILABLE = 0x7;
enum INT_VEC_COPROCESSOR_OVERRUN = 0x8;
enum INT_VEC_INVALID_TSS = 0xa;
enum INT_VEC_SEGMENT_NOT_PRESENT = 0xb;
enum INT_VEC_STACK_FAULT = 0xc;
enum INT_VEC_GENERAL_PROTECTION = 0xd;
enum INT_VEC_PAGE_FAULT = 0xe;
enum INT_VEC_COPROCESSOR_ERROR = 0x10;
enum INT_VEC_ALIGNMENT_CHECK = 0x11;
enum INT_VEC_MACHINE_CHECK = 0x12;
enum INT_VEC_SIMD_FP_EXCEPTION = 0x13;
enum INT_VEC_TIMER = 0x20;
enum INT_VEC_KEYBOARD = 0x21;
enum INT_VEC_SERIAL_PORT_2 = 0x23;
enum INT_VEC_SERIAL_PORT_1 = 0x24;
enum INT_VEC_PARALLEL_PORT = 0x25;
enum INT_VEC_FLOPPY_DISK = 0x26;
enum INT_VEC_MYSTERY = 0x27;
enum INT_VEC_MOUSE = 0x2c;

enum PIC_MASTER_IMR_PORT = 0x21;
enum PIC_MASTER_SLAVE_LINE = 0x04;
enum PIC_SLAVE_ID = 0x02;
enum PIC_SLAVE_IMR_PORT  = 0xA1;
enum PIC_NEEDICW4 = 0x01;
enum PIC_ICW1BASE = 0x10;
enum PIC_86MODE = 0x01;
enum PIC_MASTER_CMD_PORT = 0x20;
enum PIC_SLAVE_CMD_PORT = 0xA0;
enum PIC_EOI = 0x20;

enum IDT_PRESENT = 0x8000;
enum IDT_DPL_0 = 0x0000;
enum IDT_INT32_GATE = 0x0e00;

struct IDT_Gate
{
	short offset_15_0;
	short segment_selector;
	short flags;
	short offset_31_16;
}

public void
enable_interrupts()
{
	asm
	{
		sti;
	}
}

public void
disable_interrupts()
{
	asm
	{
		cli;
	}
}

public void
init_interrupts()
{
	serial_outln("\nInterrupts: Initializing");
	serial_outln("Interrupts: table size: ", __idt_table.sizeof, " ", __isr_table.sizeof);
	init_idt();
	init_pic();	
	serial_outln("Interrupts: Finished");
}

void
install_isr(int vector, isr_handler handler)
{
	__isr_table[vector] = handler;
}

private:

template createIDTStubs(long howMany = 255)
{
	static if (howMany < 0)
	{
		const string createIDTStubs = "";
	}
	// Error ISRs, these ISRs push an error code onto the
	// stack, so we need to handle that
	else static if (howMany == 0x08 || howMany == 0x0a ||
					howMany == 0x0b || howMany == 0x0c ||
					howMany == 0x0d || howMany == 0x0e ||
					howMany == 0x11)
	{
		const string createIDTStubs = createIDTStubs!(howMany-1) ~ 
			"extern (C) void idt_handler_" ~ itoa!(howMany) ~ "() {
				asm { 
					naked; 
					push " ~ itoa!(howMany) ~ ";
					jmp [__isr_table + 4*" ~ itoa!(howMany) ~ "];
					add ESP, 8;
					iret;
				}
			}\n";
	}
	else
	{
		const string createIDTStubs = createIDTStubs!(howMany-1) ~ 
			"extern (C) void idt_handler_" ~ itoa!(howMany) ~ "() {
				asm {
					naked; 
					push 0;
					push " ~ itoa!(howMany) ~ ";
					jmp [__isr_table + 4*" ~ itoa!(howMany) ~ "];
					add ESP, 8;
					iret;
				}
			}\n";
	}
}




template initializeIDTHandlers(long howMany = 255)
{
	static if (howMany < 0)
	{
		const string initializeIDTHandlers = "";
	}
	else
	{
		const string initializeIDTHandlers = initializeIDTHandlers!(howMany-1) 
			~ "__idt_table[" ~ itoa!(howMany) ~ "] = &idt_handler_" 
			~ itoa!(howMany) ~ ";\n";
	}
}

void
init_idt()
{
	// Make sure interrupts are off
	asm { cli; }

	__idt_table[0] = &idt_handler_0;
	__idt_table[1] = &idt_handler_1;
	__idt_table[2] = &idt_handler_2;
	__idt_table[3] = &idt_handler_3;
	__idt_table[4] = &idt_handler_4;
	__idt_table[5] = &idt_handler_5;
	__idt_table[6] = &idt_handler_6;
	__idt_table[7] = &idt_handler_7;
	__idt_table[8] = &idt_handler_8;
	__idt_table[9] = &idt_handler_9;
	__idt_table[10] = &idt_handler_10;
	__idt_table[11] = &idt_handler_11;
	__idt_table[12] = &idt_handler_12;
	__idt_table[13] = &idt_handler_13;
	__idt_table[14] = &idt_handler_14;
	__idt_table[15] = &idt_handler_15;
	__idt_table[16] = &idt_handler_16;
	__idt_table[17] = &idt_handler_17;
	__idt_table[18] = &idt_handler_18;
	__idt_table[19] = &idt_handler_19;
	__idt_table[20] = &idt_handler_20;
	__idt_table[21] = &idt_handler_21;
	__idt_table[22] = &idt_handler_22;
	__idt_table[23] = &idt_handler_23;
	__idt_table[24] = &idt_handler_24;
	__idt_table[25] = &idt_handler_25;
	__idt_table[26] = &idt_handler_26;
	__idt_table[27] = &idt_handler_27;
	__idt_table[28] = &idt_handler_28;
	__idt_table[29] = &idt_handler_29;
	__idt_table[30] = &idt_handler_30;
	__idt_table[31] = &idt_handler_31;
	__idt_table[32] = &idt_handler_32;
	__idt_table[33] = &idt_handler_33;
	__idt_table[34] = &idt_handler_34;
	__idt_table[35] = &idt_handler_35;
	__idt_table[36] = &idt_handler_36;
	__idt_table[37] = &idt_handler_37;
	__idt_table[38] = &idt_handler_38;
	__idt_table[39] = &idt_handler_39;
	__idt_table[40] = &idt_handler_40;
	__idt_table[41] = &idt_handler_41;
	__idt_table[42] = &idt_handler_42;
	__idt_table[43] = &idt_handler_43;
	__idt_table[44] = &idt_handler_44;
	__idt_table[45] = &idt_handler_45;
	__idt_table[46] = &idt_handler_46;
	__idt_table[47] = &idt_handler_47;
	__idt_table[48] = &idt_handler_48;
	__idt_table[49] = &idt_handler_49;
	__idt_table[50] = &idt_handler_50;
	__idt_table[51] = &idt_handler_51;
	__idt_table[52] = &idt_handler_52;
	__idt_table[53] = &idt_handler_53;
	__idt_table[54] = &idt_handler_54;
	__idt_table[55] = &idt_handler_55;
	__idt_table[56] = &idt_handler_56;
	__idt_table[57] = &idt_handler_57;
	__idt_table[58] = &idt_handler_58;
	__idt_table[59] = &idt_handler_59;
	__idt_table[60] = &idt_handler_60;
	__idt_table[61] = &idt_handler_61;
	__idt_table[62] = &idt_handler_62;
	__idt_table[63] = &idt_handler_63;
	__idt_table[64] = &idt_handler_64;
	__idt_table[65] = &idt_handler_65;
	__idt_table[66] = &idt_handler_66;
	__idt_table[67] = &idt_handler_67;
	__idt_table[68] = &idt_handler_68;
	__idt_table[69] = &idt_handler_69;
	__idt_table[70] = &idt_handler_70;
	__idt_table[71] = &idt_handler_71;
	__idt_table[72] = &idt_handler_72;
	__idt_table[73] = &idt_handler_73;
	__idt_table[74] = &idt_handler_74;
	__idt_table[75] = &idt_handler_75;
	__idt_table[76] = &idt_handler_76;
	__idt_table[77] = &idt_handler_77;
	__idt_table[78] = &idt_handler_78;
	__idt_table[79] = &idt_handler_79;
	__idt_table[80] = &idt_handler_80;
	__idt_table[81] = &idt_handler_81;
	__idt_table[82] = &idt_handler_82;
	__idt_table[83] = &idt_handler_83;
	__idt_table[84] = &idt_handler_84;
	__idt_table[85] = &idt_handler_85;
	__idt_table[86] = &idt_handler_86;
	__idt_table[87] = &idt_handler_87;
	__idt_table[88] = &idt_handler_88;
	__idt_table[89] = &idt_handler_89;
	__idt_table[90] = &idt_handler_90;
	__idt_table[91] = &idt_handler_91;
	__idt_table[92] = &idt_handler_92;
	__idt_table[93] = &idt_handler_93;
	__idt_table[94] = &idt_handler_94;
	__idt_table[95] = &idt_handler_95;
	__idt_table[96] = &idt_handler_96;
	__idt_table[97] = &idt_handler_97;
	__idt_table[98] = &idt_handler_98;
	__idt_table[99] = &idt_handler_99;
	__idt_table[100] = &idt_handler_100;
	__idt_table[101] = &idt_handler_101;
	__idt_table[102] = &idt_handler_102;
	__idt_table[103] = &idt_handler_103;
	__idt_table[104] = &idt_handler_104;
	__idt_table[105] = &idt_handler_105;
	__idt_table[106] = &idt_handler_106;
	__idt_table[107] = &idt_handler_107;
	__idt_table[108] = &idt_handler_108;
	__idt_table[109] = &idt_handler_109;
	__idt_table[110] = &idt_handler_110;
	__idt_table[111] = &idt_handler_111;
	__idt_table[112] = &idt_handler_112;
	__idt_table[113] = &idt_handler_113;
	__idt_table[114] = &idt_handler_114;
	__idt_table[115] = &idt_handler_115;
	__idt_table[116] = &idt_handler_116;
	__idt_table[117] = &idt_handler_117;
	__idt_table[118] = &idt_handler_118;
	__idt_table[119] = &idt_handler_119;
	__idt_table[120] = &idt_handler_120;
	__idt_table[121] = &idt_handler_121;
	__idt_table[122] = &idt_handler_122;
	__idt_table[123] = &idt_handler_123;
	__idt_table[124] = &idt_handler_124;
	__idt_table[125] = &idt_handler_125;
	__idt_table[126] = &idt_handler_126;
	__idt_table[127] = &idt_handler_127;
	__idt_table[128] = &idt_handler_128;
	__idt_table[129] = &idt_handler_129;
	__idt_table[130] = &idt_handler_130;
	__idt_table[131] = &idt_handler_131;
	__idt_table[132] = &idt_handler_132;
	__idt_table[133] = &idt_handler_133;
	__idt_table[134] = &idt_handler_134;
	__idt_table[135] = &idt_handler_135;
	__idt_table[136] = &idt_handler_136;
	__idt_table[137] = &idt_handler_137;
	__idt_table[138] = &idt_handler_138;
	__idt_table[139] = &idt_handler_139;
	__idt_table[140] = &idt_handler_140;
	__idt_table[141] = &idt_handler_141;
	__idt_table[142] = &idt_handler_142;
	__idt_table[143] = &idt_handler_143;
	__idt_table[144] = &idt_handler_144;
	__idt_table[145] = &idt_handler_145;
	__idt_table[146] = &idt_handler_146;
	__idt_table[147] = &idt_handler_147;
	__idt_table[148] = &idt_handler_148;
	__idt_table[149] = &idt_handler_149;
	__idt_table[150] = &idt_handler_150;
	__idt_table[151] = &idt_handler_151;
	__idt_table[152] = &idt_handler_152;
	__idt_table[153] = &idt_handler_153;
	__idt_table[154] = &idt_handler_154;
	__idt_table[155] = &idt_handler_155;
	__idt_table[156] = &idt_handler_156;
	__idt_table[157] = &idt_handler_157;
	__idt_table[158] = &idt_handler_158;
	__idt_table[159] = &idt_handler_159;
	__idt_table[160] = &idt_handler_160;
	__idt_table[161] = &idt_handler_161;
	__idt_table[162] = &idt_handler_162;
	__idt_table[163] = &idt_handler_163;
	__idt_table[164] = &idt_handler_164;
	__idt_table[165] = &idt_handler_165;
	__idt_table[166] = &idt_handler_166;
	__idt_table[167] = &idt_handler_167;
	__idt_table[168] = &idt_handler_168;
	__idt_table[169] = &idt_handler_169;
	__idt_table[170] = &idt_handler_170;
	__idt_table[171] = &idt_handler_171;
	__idt_table[172] = &idt_handler_172;
	__idt_table[173] = &idt_handler_173;
	__idt_table[174] = &idt_handler_174;
	__idt_table[175] = &idt_handler_175;
	__idt_table[176] = &idt_handler_176;
	__idt_table[177] = &idt_handler_177;
	__idt_table[178] = &idt_handler_178;
	__idt_table[179] = &idt_handler_179;
	__idt_table[180] = &idt_handler_180;
	__idt_table[181] = &idt_handler_181;
	__idt_table[182] = &idt_handler_182;
	__idt_table[183] = &idt_handler_183;
	__idt_table[184] = &idt_handler_184;
	__idt_table[185] = &idt_handler_185;
	__idt_table[186] = &idt_handler_186;
	__idt_table[187] = &idt_handler_187;
	__idt_table[188] = &idt_handler_188;
	__idt_table[189] = &idt_handler_189;
	__idt_table[190] = &idt_handler_190;
	__idt_table[191] = &idt_handler_191;
	__idt_table[192] = &idt_handler_192;
	__idt_table[193] = &idt_handler_193;
	__idt_table[194] = &idt_handler_194;
	__idt_table[195] = &idt_handler_195;
	__idt_table[196] = &idt_handler_196;
	__idt_table[197] = &idt_handler_197;
	__idt_table[198] = &idt_handler_198;
	__idt_table[199] = &idt_handler_199;
	__idt_table[200] = &idt_handler_200;
	__idt_table[201] = &idt_handler_201;
	__idt_table[202] = &idt_handler_202;
	__idt_table[203] = &idt_handler_203;
	__idt_table[204] = &idt_handler_204;
	__idt_table[205] = &idt_handler_205;
	__idt_table[206] = &idt_handler_206;
	__idt_table[207] = &idt_handler_207;
	__idt_table[208] = &idt_handler_208;
	__idt_table[209] = &idt_handler_209;
	__idt_table[210] = &idt_handler_210;
	__idt_table[211] = &idt_handler_211;
	__idt_table[212] = &idt_handler_212;
	__idt_table[213] = &idt_handler_213;
	__idt_table[214] = &idt_handler_214;
	__idt_table[215] = &idt_handler_215;
	__idt_table[216] = &idt_handler_216;
	__idt_table[217] = &idt_handler_217;
	__idt_table[218] = &idt_handler_218;
	__idt_table[219] = &idt_handler_219;
	__idt_table[220] = &idt_handler_220;
	__idt_table[221] = &idt_handler_221;
	__idt_table[222] = &idt_handler_222;
	__idt_table[223] = &idt_handler_223;
	__idt_table[224] = &idt_handler_224;
	__idt_table[225] = &idt_handler_225;
	__idt_table[226] = &idt_handler_226;
	__idt_table[227] = &idt_handler_227;
	__idt_table[228] = &idt_handler_228;
	__idt_table[229] = &idt_handler_229;
	__idt_table[230] = &idt_handler_230;
	__idt_table[231] = &idt_handler_231;
	__idt_table[232] = &idt_handler_232;
	__idt_table[233] = &idt_handler_233;
	__idt_table[234] = &idt_handler_234;
	__idt_table[235] = &idt_handler_235;
	__idt_table[236] = &idt_handler_236;
	__idt_table[237] = &idt_handler_237;
	__idt_table[238] = &idt_handler_238;
	__idt_table[239] = &idt_handler_239;
	__idt_table[240] = &idt_handler_240;
	__idt_table[241] = &idt_handler_241;
	__idt_table[242] = &idt_handler_242;
	__idt_table[243] = &idt_handler_243;
	__idt_table[244] = &idt_handler_244;
	__idt_table[245] = &idt_handler_245;
	__idt_table[246] = &idt_handler_246;
	__idt_table[247] = &idt_handler_247;
	__idt_table[248] = &idt_handler_248;
	__idt_table[249] = &idt_handler_249;
	__idt_table[250] = &idt_handler_250;
	__idt_table[251] = &idt_handler_251;
	__idt_table[252] = &idt_handler_252;
	__idt_table[253] = &idt_handler_253;
	__idt_table[254] = &idt_handler_254;
	__idt_table[255] = &idt_handler_255;

	serial_outln("Setup IDT table");
	// Setup the idt table
	// Parentheses are important for mixins!
//	mixin(initializeIDTHandlers!(255));

	for (int i = 0; i < 256; ++i)
	{
		// TODO - probably don't need the ISR stub table
		set_idt_entry(i, __idt_table[i]);
		install_isr(i, &__default_unexpected_handler);
	}

	install_isr(INT_VEC_KEYBOARD, &__default_expected_handler);
	install_isr(INT_VEC_SERIAL_PORT_1, &__default_expected_handler);
	install_isr(INT_VEC_MYSTERY,  &__default_mystery_handler);

	// We could check to see if they were on and turn them
	// but leave them off for now and the caller will have
	// to turn interrupts back on
	//enable_interrupts();
	serial_outln("Done with IDT");
}

void
init_pic()
{
	asm { cli; }
	serial_outln("Initializing the pic");
	__outb(PIC_MASTER_CMD_PORT, PIC_ICW1BASE | PIC_NEEDICW4);
	__outb(PIC_SLAVE_CMD_PORT,  PIC_ICW1BASE | PIC_NEEDICW4);

	serial_outln("pic 2");
	__outb(PIC_MASTER_IMR_PORT, 0x20);
	__outb(PIC_SLAVE_IMR_PORT,  0x28);

	serial_outln("pic 3");
	__outb(PIC_MASTER_IMR_PORT, PIC_MASTER_SLAVE_LINE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_SLAVE_ID);

	serial_outln("pic 3");
	__outb(PIC_MASTER_IMR_PORT, PIC_86MODE);
	__outb(PIC_SLAVE_IMR_PORT,  PIC_86MODE);
	
	serial_outln("pic 4");
	__outb(PIC_MASTER_IMR_PORT, 0x0);
	__outb(PIC_SLAVE_IMR_PORT,  0x0);
	serial_outln("Finished with the pic");
}

void
set_idt_entry(int entry, idt_handler handler)
{
	IDT_Gate* g = cast(IDT_Gate*)IDT_ADDRESS + entry;

	g.offset_15_0 = cast(int)handler & 0xFFFF;
	g.segment_selector = 0x0010;
	g.flags = cast(short) (IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE);
	g.offset_31_16 = (cast(int)handler >> 16) & 0xFFFF;
}


extern (C) void
__default_expected_handler(int vector, int code)
{
	serial_outln("Expected interrupt ", vector);
	serial_outln("Error code: ", code);

	if (vector >= 0x20 && vector < 0x30)
	{
		__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
		if (vector > 0x28)
		{
			__outb(PIC_SLAVE_CMD_PORT, PIC_EOI);
		}
	}
	else
	{
		serial_outln("Something's wrong!");
		panic();
	}
}

extern (C) void
__default_mystery_handler(int vector, int code)
{
	serial_outln("Got mystery interrupt");
	__outb(PIC_MASTER_CMD_PORT, PIC_EOI);
}

extern (C) void 
__default_unexpected_handler(int vector, int code)
{
	serial_outln("Unexpected interrupt: ", vector);
	serial_outln("Error code: ", code);
	panic();
}
