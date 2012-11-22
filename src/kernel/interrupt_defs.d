module kernel.interrupt_defs;

import kernel.interrupts;

import kernel.serial;
import kernel.support : panic;

__gshared:
nothrow:
public:

struct InterruptContext
{
	align(4):
	uint SS;
	uint GS;
	uint FS;
	uint ES;
	uint DS;
	uint EDI;
	uint ESI;
	uint EBP;
	uint ESP; // ESP prior to contents being pushed
	uint EBX;
	uint EDX;
	uint ECX;
	uint EAX;
	uint vector;
	uint error_code;
	uint EIP; // Instruction causing the error
	uint CS;
	uint EFL;
}

InterruptContext* g_interruptContext = void;

extern (C) void
isr_save()
{
	asm {
		// Don't create function preamble or cleanup
		naked; 

		// Need to save all of the registers
		// because the CPU expects these to not change
		pushad;  // 32-bytes
		push DS; // 36-byte
		push ES; // 40-byte
		push FS; // 44-byte
		push GS; // 48-byte
		push SS; // 52-byte

		// Set the current interrupt context
		mov EAX, ESP;
		add EAX, 0;
		mov g_interruptContext, EAX;

		mov EAX, [ESP + 52]; // ISR number
		mov EBX, [ESP + 56]; // Error code

		push EBX;
		push EAX;
		mov ECX, [__isr_table + EAX*4];
		call ECX;
		add ESP, 8;


		pop SS;
		pop GS;
		pop FS;
		pop ES;
		pop DS;
		popad;
		add ESP, 8; // Error code and vector
		iretd;
	}
}

// Would like to turn these into a macro, but currently the templates
// are being a little annoying. Using the templates blows the final binary
// up to 16MiB, which is a little rediculous for the state of this kernel.
// Thankfully Vim has magical powers and this didn't have to be typed by hand!
extern (C) void idt_handler_0() { asm { naked; push 0; push 0; jmp isr_save; } }
extern (C) void idt_handler_1() { asm { naked; push 0; push 1; jmp isr_save; } }
extern (C) void idt_handler_2() { asm { naked; push 0; push 2; jmp isr_save; } }
extern (C) void idt_handler_3() { asm { naked; push 0; push 3; jmp isr_save; } }
extern (C) void idt_handler_4() { asm { naked; push 0; push 4; jmp isr_save; } }
extern (C) void idt_handler_5() { asm { naked; push 0; push 5; jmp isr_save; } }
extern (C) void idt_handler_6() { asm { naked; push 0; push 6; jmp isr_save; } }
extern (C) void idt_handler_7() { asm { naked; push 0; push 7; jmp isr_save; } }
extern (C) void idt_handler_8() { asm { naked; push 8; jmp isr_save; } }
extern (C) void idt_handler_9() { asm { naked; push 0; push 9; jmp isr_save; } }
extern (C) void idt_handler_10() { asm { naked; push 10; jmp isr_save; } }
extern (C) void idt_handler_11() { asm { naked; push 11; jmp isr_save; } }
extern (C) void idt_handler_12() { asm { naked; push 12; jmp isr_save; } }
extern (C) void idt_handler_13() { asm { naked; push 13; jmp isr_save; } }
extern (C) void idt_handler_14() { asm { naked; push 14; jmp isr_save; } }
extern (C) void idt_handler_15() { asm { naked; push 0; push 15; jmp isr_save; } }
extern (C) void idt_handler_16() { asm { naked; push 0; push 16; jmp isr_save; } }
extern (C) void idt_handler_17() { asm { naked; push 17; jmp isr_save; } }
extern (C) void idt_handler_18() { asm { naked; push 0; push 18; jmp isr_save; } }
extern (C) void idt_handler_19() { asm { naked; push 0; push 19; jmp isr_save; } }
extern (C) void idt_handler_20() { asm { naked; push 0; push 20; jmp isr_save; } }
extern (C) void idt_handler_21() { asm { naked; push 0; push 21; jmp isr_save; } }
extern (C) void idt_handler_22() { asm { naked; push 0; push 22; jmp isr_save; } }
extern (C) void idt_handler_23() { asm { naked; push 0; push 23; jmp isr_save; } }
extern (C) void idt_handler_24() { asm { naked; push 0; push 24; jmp isr_save; } }
extern (C) void idt_handler_25() { asm { naked; push 0; push 25; jmp isr_save; } }
extern (C) void idt_handler_26() { asm { naked; push 0; push 26; jmp isr_save; } }
extern (C) void idt_handler_27() { asm { naked; push 0; push 27; jmp isr_save; } }
extern (C) void idt_handler_28() { asm { naked; push 0; push 28; jmp isr_save; } }
extern (C) void idt_handler_29() { asm { naked; push 0; push 29; jmp isr_save; } }
extern (C) void idt_handler_30() { asm { naked; push 0; push 30; jmp isr_save; } }
extern (C) void idt_handler_31() { asm { naked; push 0; push 31; jmp isr_save; } }
extern (C) void idt_handler_32() { asm { naked; push 0; push 32; jmp isr_save; } }
extern (C) void idt_handler_33() { asm { naked; push 0; push 33; jmp isr_save; } }
extern (C) void idt_handler_34() { asm { naked; push 0; push 34; jmp isr_save; } }
extern (C) void idt_handler_35() { asm { naked; push 0; push 35; jmp isr_save; } }
extern (C) void idt_handler_36() { asm { naked; push 0; push 36; jmp isr_save; } }
extern (C) void idt_handler_37() { asm { naked; push 0; push 37; jmp isr_save; } }
extern (C) void idt_handler_38() { asm { naked; push 0; push 38; jmp isr_save; } }
extern (C) void idt_handler_39() { asm { naked; push 0; push 39; jmp isr_save; } }
extern (C) void idt_handler_40() { asm { naked; push 0; push 40; jmp isr_save; } }
extern (C) void idt_handler_41() { asm { naked; push 0; push 41; jmp isr_save; } }
extern (C) void idt_handler_42() { asm { naked; push 0; push 42; jmp isr_save; } }
extern (C) void idt_handler_43() { asm { naked; push 0; push 43; jmp isr_save; } }
extern (C) void idt_handler_44() { asm { naked; push 0; push 44; jmp isr_save; } }
extern (C) void idt_handler_45() { asm { naked; push 0; push 45; jmp isr_save; } }
extern (C) void idt_handler_46() { asm { naked; push 0; push 46; jmp isr_save; } }
extern (C) void idt_handler_47() { asm { naked; push 0; push 47; jmp isr_save; } }
extern (C) void idt_handler_48() { asm { naked; push 0; push 48; jmp isr_save; } }
extern (C) void idt_handler_49() { asm { naked; push 0; push 49; jmp isr_save; } }
extern (C) void idt_handler_50() { asm { naked; push 0; push 50; jmp isr_save; } }
extern (C) void idt_handler_51() { asm { naked; push 0; push 51; jmp isr_save; } }
extern (C) void idt_handler_52() { asm { naked; push 0; push 52; jmp isr_save; } }
extern (C) void idt_handler_53() { asm { naked; push 0; push 53; jmp isr_save; } }
extern (C) void idt_handler_54() { asm { naked; push 0; push 54; jmp isr_save; } }
extern (C) void idt_handler_55() { asm { naked; push 0; push 55; jmp isr_save; } }
extern (C) void idt_handler_56() { asm { naked; push 0; push 56; jmp isr_save; } }
extern (C) void idt_handler_57() { asm { naked; push 0; push 57; jmp isr_save; } }
extern (C) void idt_handler_58() { asm { naked; push 0; push 58; jmp isr_save; } }
extern (C) void idt_handler_59() { asm { naked; push 0; push 59; jmp isr_save; } }
extern (C) void idt_handler_60() { asm { naked; push 0; push 60; jmp isr_save; } }
extern (C) void idt_handler_61() { asm { naked; push 0; push 61; jmp isr_save; } }
extern (C) void idt_handler_62() { asm { naked; push 0; push 62; jmp isr_save; } }
extern (C) void idt_handler_63() { asm { naked; push 0; push 63; jmp isr_save; } }
extern (C) void idt_handler_64() { asm { naked; push 0; push 64; jmp isr_save; } }
extern (C) void idt_handler_65() { asm { naked; push 0; push 65; jmp isr_save; } }
extern (C) void idt_handler_66() { asm { naked; push 0; push 66; jmp isr_save; } }
extern (C) void idt_handler_67() { asm { naked; push 0; push 67; jmp isr_save; } }
extern (C) void idt_handler_68() { asm { naked; push 0; push 68; jmp isr_save; } }
extern (C) void idt_handler_69() { asm { naked; push 0; push 69; jmp isr_save; } }
extern (C) void idt_handler_70() { asm { naked; push 0; push 70; jmp isr_save; } }
extern (C) void idt_handler_71() { asm { naked; push 0; push 71; jmp isr_save; } }
extern (C) void idt_handler_72() { asm { naked; push 0; push 72; jmp isr_save; } }
extern (C) void idt_handler_73() { asm { naked; push 0; push 73; jmp isr_save; } }
extern (C) void idt_handler_74() { asm { naked; push 0; push 74; jmp isr_save; } }
extern (C) void idt_handler_75() { asm { naked; push 0; push 75; jmp isr_save; } }
extern (C) void idt_handler_76() { asm { naked; push 0; push 76; jmp isr_save; } }
extern (C) void idt_handler_77() { asm { naked; push 0; push 77; jmp isr_save; } }
extern (C) void idt_handler_78() { asm { naked; push 0; push 78; jmp isr_save; } }
extern (C) void idt_handler_79() { asm { naked; push 0; push 79; jmp isr_save; } }
extern (C) void idt_handler_80() { asm { naked; push 0; push 80; jmp isr_save; } }
extern (C) void idt_handler_81() { asm { naked; push 0; push 81; jmp isr_save; } }
extern (C) void idt_handler_82() { asm { naked; push 0; push 82; jmp isr_save; } }
extern (C) void idt_handler_83() { asm { naked; push 0; push 83; jmp isr_save; } }
extern (C) void idt_handler_84() { asm { naked; push 0; push 84; jmp isr_save; } }
extern (C) void idt_handler_85() { asm { naked; push 0; push 85; jmp isr_save; } }
extern (C) void idt_handler_86() { asm { naked; push 0; push 86; jmp isr_save; } }
extern (C) void idt_handler_87() { asm { naked; push 0; push 87; jmp isr_save; } }
extern (C) void idt_handler_88() { asm { naked; push 0; push 88; jmp isr_save; } }
extern (C) void idt_handler_89() { asm { naked; push 0; push 89; jmp isr_save; } }
extern (C) void idt_handler_90() { asm { naked; push 0; push 90; jmp isr_save; } }
extern (C) void idt_handler_91() { asm { naked; push 0; push 91; jmp isr_save; } }
extern (C) void idt_handler_92() { asm { naked; push 0; push 92; jmp isr_save; } }
extern (C) void idt_handler_93() { asm { naked; push 0; push 93; jmp isr_save; } }
extern (C) void idt_handler_94() { asm { naked; push 0; push 94; jmp isr_save; } }
extern (C) void idt_handler_95() { asm { naked; push 0; push 95; jmp isr_save; } }
extern (C) void idt_handler_96() { asm { naked; push 0; push 96; jmp isr_save; } }
extern (C) void idt_handler_97() { asm { naked; push 0; push 97; jmp isr_save; } }
extern (C) void idt_handler_98() { asm { naked; push 0; push 98; jmp isr_save; } }
extern (C) void idt_handler_99() { asm { naked; push 0; push 99; jmp isr_save; } }
extern (C) void idt_handler_100() { asm { naked; push 0; push 100; jmp isr_save; } }
extern (C) void idt_handler_101() { asm { naked; push 0; push 101; jmp isr_save; } }
extern (C) void idt_handler_102() { asm { naked; push 0; push 102; jmp isr_save; } }
extern (C) void idt_handler_103() { asm { naked; push 0; push 103; jmp isr_save; } }
extern (C) void idt_handler_104() { asm { naked; push 0; push 104; jmp isr_save; } }
extern (C) void idt_handler_105() { asm { naked; push 0; push 105; jmp isr_save; } }
extern (C) void idt_handler_106() { asm { naked; push 0; push 106; jmp isr_save; } }
extern (C) void idt_handler_107() { asm { naked; push 0; push 107; jmp isr_save; } }
extern (C) void idt_handler_108() { asm { naked; push 0; push 108; jmp isr_save; } }
extern (C) void idt_handler_109() { asm { naked; push 0; push 109; jmp isr_save; } }
extern (C) void idt_handler_110() { asm { naked; push 0; push 110; jmp isr_save; } }
extern (C) void idt_handler_111() { asm { naked; push 0; push 111; jmp isr_save; } }
extern (C) void idt_handler_112() { asm { naked; push 0; push 112; jmp isr_save; } }
extern (C) void idt_handler_113() { asm { naked; push 0; push 113; jmp isr_save; } }
extern (C) void idt_handler_114() { asm { naked; push 0; push 114; jmp isr_save; } }
extern (C) void idt_handler_115() { asm { naked; push 0; push 115; jmp isr_save; } }
extern (C) void idt_handler_116() { asm { naked; push 0; push 116; jmp isr_save; } }
extern (C) void idt_handler_117() { asm { naked; push 0; push 117; jmp isr_save; } }
extern (C) void idt_handler_118() { asm { naked; push 0; push 118; jmp isr_save; } }
extern (C) void idt_handler_119() { asm { naked; push 0; push 119; jmp isr_save; } }
extern (C) void idt_handler_120() { asm { naked; push 0; push 120; jmp isr_save; } }
extern (C) void idt_handler_121() { asm { naked; push 0; push 121; jmp isr_save; } }
extern (C) void idt_handler_122() { asm { naked; push 0; push 122; jmp isr_save; } }
extern (C) void idt_handler_123() { asm { naked; push 0; push 123; jmp isr_save; } }
extern (C) void idt_handler_124() { asm { naked; push 0; push 124; jmp isr_save; } }
extern (C) void idt_handler_125() { asm { naked; push 0; push 125; jmp isr_save; } }
extern (C) void idt_handler_126() { asm { naked; push 0; push 126; jmp isr_save; } }
extern (C) void idt_handler_127() { asm { naked; push 0; push 127; jmp isr_save; } }
extern (C) void idt_handler_128() { asm { naked; push 0; push 128; jmp isr_save; } }
extern (C) void idt_handler_129() { asm { naked; push 0; push 129; jmp isr_save; } }
extern (C) void idt_handler_130() { asm { naked; push 0; push 130; jmp isr_save; } }
extern (C) void idt_handler_131() { asm { naked; push 0; push 131; jmp isr_save; } }
extern (C) void idt_handler_132() { asm { naked; push 0; push 132; jmp isr_save; } }
extern (C) void idt_handler_133() { asm { naked; push 0; push 133; jmp isr_save; } }
extern (C) void idt_handler_134() { asm { naked; push 0; push 134; jmp isr_save; } }
extern (C) void idt_handler_135() { asm { naked; push 0; push 135; jmp isr_save; } }
extern (C) void idt_handler_136() { asm { naked; push 0; push 136; jmp isr_save; } }
extern (C) void idt_handler_137() { asm { naked; push 0; push 137; jmp isr_save; } }
extern (C) void idt_handler_138() { asm { naked; push 0; push 138; jmp isr_save; } }
extern (C) void idt_handler_139() { asm { naked; push 0; push 139; jmp isr_save; } }
extern (C) void idt_handler_140() { asm { naked; push 0; push 140; jmp isr_save; } }
extern (C) void idt_handler_141() { asm { naked; push 0; push 141; jmp isr_save; } }
extern (C) void idt_handler_142() { asm { naked; push 0; push 142; jmp isr_save; } }
extern (C) void idt_handler_143() { asm { naked; push 0; push 143; jmp isr_save; } }
extern (C) void idt_handler_144() { asm { naked; push 0; push 144; jmp isr_save; } }
extern (C) void idt_handler_145() { asm { naked; push 0; push 145; jmp isr_save; } }
extern (C) void idt_handler_146() { asm { naked; push 0; push 146; jmp isr_save; } }
extern (C) void idt_handler_147() { asm { naked; push 0; push 147; jmp isr_save; } }
extern (C) void idt_handler_148() { asm { naked; push 0; push 148; jmp isr_save; } }
extern (C) void idt_handler_149() { asm { naked; push 0; push 149; jmp isr_save; } }
extern (C) void idt_handler_150() { asm { naked; push 0; push 150; jmp isr_save; } }
extern (C) void idt_handler_151() { asm { naked; push 0; push 151; jmp isr_save; } }
extern (C) void idt_handler_152() { asm { naked; push 0; push 152; jmp isr_save; } }
extern (C) void idt_handler_153() { asm { naked; push 0; push 153; jmp isr_save; } }
extern (C) void idt_handler_154() { asm { naked; push 0; push 154; jmp isr_save; } }
extern (C) void idt_handler_155() { asm { naked; push 0; push 155; jmp isr_save; } }
extern (C) void idt_handler_156() { asm { naked; push 0; push 156; jmp isr_save; } }
extern (C) void idt_handler_157() { asm { naked; push 0; push 157; jmp isr_save; } }
extern (C) void idt_handler_158() { asm { naked; push 0; push 158; jmp isr_save; } }
extern (C) void idt_handler_159() { asm { naked; push 0; push 159; jmp isr_save; } }
extern (C) void idt_handler_160() { asm { naked; push 0; push 160; jmp isr_save; } }
extern (C) void idt_handler_161() { asm { naked; push 0; push 161; jmp isr_save; } }
extern (C) void idt_handler_162() { asm { naked; push 0; push 162; jmp isr_save; } }
extern (C) void idt_handler_163() { asm { naked; push 0; push 163; jmp isr_save; } }
extern (C) void idt_handler_164() { asm { naked; push 0; push 164; jmp isr_save; } }
extern (C) void idt_handler_165() { asm { naked; push 0; push 165; jmp isr_save; } }
extern (C) void idt_handler_166() { asm { naked; push 0; push 166; jmp isr_save; } }
extern (C) void idt_handler_167() { asm { naked; push 0; push 167; jmp isr_save; } }
extern (C) void idt_handler_168() { asm { naked; push 0; push 168; jmp isr_save; } }
extern (C) void idt_handler_169() { asm { naked; push 0; push 169; jmp isr_save; } }
extern (C) void idt_handler_170() { asm { naked; push 0; push 170; jmp isr_save; } }
extern (C) void idt_handler_171() { asm { naked; push 0; push 171; jmp isr_save; } }
extern (C) void idt_handler_172() { asm { naked; push 0; push 172; jmp isr_save; } }
extern (C) void idt_handler_173() { asm { naked; push 0; push 173; jmp isr_save; } }
extern (C) void idt_handler_174() { asm { naked; push 0; push 174; jmp isr_save; } }
extern (C) void idt_handler_175() { asm { naked; push 0; push 175; jmp isr_save; } }
extern (C) void idt_handler_176() { asm { naked; push 0; push 176; jmp isr_save; } }
extern (C) void idt_handler_177() { asm { naked; push 0; push 177; jmp isr_save; } }
extern (C) void idt_handler_178() { asm { naked; push 0; push 178; jmp isr_save; } }
extern (C) void idt_handler_179() { asm { naked; push 0; push 179; jmp isr_save; } }
extern (C) void idt_handler_180() { asm { naked; push 0; push 180; jmp isr_save; } }
extern (C) void idt_handler_181() { asm { naked; push 0; push 181; jmp isr_save; } }
extern (C) void idt_handler_182() { asm { naked; push 0; push 182; jmp isr_save; } }
extern (C) void idt_handler_183() { asm { naked; push 0; push 183; jmp isr_save; } }
extern (C) void idt_handler_184() { asm { naked; push 0; push 184; jmp isr_save; } }
extern (C) void idt_handler_185() { asm { naked; push 0; push 185; jmp isr_save; } }
extern (C) void idt_handler_186() { asm { naked; push 0; push 186; jmp isr_save; } }
extern (C) void idt_handler_187() { asm { naked; push 0; push 187; jmp isr_save; } }
extern (C) void idt_handler_188() { asm { naked; push 0; push 188; jmp isr_save; } }
extern (C) void idt_handler_189() { asm { naked; push 0; push 189; jmp isr_save; } }
extern (C) void idt_handler_190() { asm { naked; push 0; push 190; jmp isr_save; } }
extern (C) void idt_handler_191() { asm { naked; push 0; push 191; jmp isr_save; } }
extern (C) void idt_handler_192() { asm { naked; push 0; push 192; jmp isr_save; } }
extern (C) void idt_handler_193() { asm { naked; push 0; push 193; jmp isr_save; } }
extern (C) void idt_handler_194() { asm { naked; push 0; push 194; jmp isr_save; } }
extern (C) void idt_handler_195() { asm { naked; push 0; push 195; jmp isr_save; } }
extern (C) void idt_handler_196() { asm { naked; push 0; push 196; jmp isr_save; } }
extern (C) void idt_handler_197() { asm { naked; push 0; push 197; jmp isr_save; } }
extern (C) void idt_handler_198() { asm { naked; push 0; push 198; jmp isr_save; } }
extern (C) void idt_handler_199() { asm { naked; push 0; push 199; jmp isr_save; } }
extern (C) void idt_handler_200() { asm { naked; push 0; push 200; jmp isr_save; } }
extern (C) void idt_handler_201() { asm { naked; push 0; push 201; jmp isr_save; } }
extern (C) void idt_handler_202() { asm { naked; push 0; push 202; jmp isr_save; } }
extern (C) void idt_handler_203() { asm { naked; push 0; push 203; jmp isr_save; } }
extern (C) void idt_handler_204() { asm { naked; push 0; push 204; jmp isr_save; } }
extern (C) void idt_handler_205() { asm { naked; push 0; push 205; jmp isr_save; } }
extern (C) void idt_handler_206() { asm { naked; push 0; push 206; jmp isr_save; } }
extern (C) void idt_handler_207() { asm { naked; push 0; push 207; jmp isr_save; } }
extern (C) void idt_handler_208() { asm { naked; push 0; push 208; jmp isr_save; } }
extern (C) void idt_handler_209() { asm { naked; push 0; push 209; jmp isr_save; } }
extern (C) void idt_handler_210() { asm { naked; push 0; push 210; jmp isr_save; } }
extern (C) void idt_handler_211() { asm { naked; push 0; push 211; jmp isr_save; } }
extern (C) void idt_handler_212() { asm { naked; push 0; push 212; jmp isr_save; } }
extern (C) void idt_handler_213() { asm { naked; push 0; push 213; jmp isr_save; } }
extern (C) void idt_handler_214() { asm { naked; push 0; push 214; jmp isr_save; } }
extern (C) void idt_handler_215() { asm { naked; push 0; push 215; jmp isr_save; } }
extern (C) void idt_handler_216() { asm { naked; push 0; push 216; jmp isr_save; } }
extern (C) void idt_handler_217() { asm { naked; push 0; push 217; jmp isr_save; } }
extern (C) void idt_handler_218() { asm { naked; push 0; push 218; jmp isr_save; } }
extern (C) void idt_handler_219() { asm { naked; push 0; push 219; jmp isr_save; } }
extern (C) void idt_handler_220() { asm { naked; push 0; push 220; jmp isr_save; } }
extern (C) void idt_handler_221() { asm { naked; push 0; push 221; jmp isr_save; } }
extern (C) void idt_handler_222() { asm { naked; push 0; push 222; jmp isr_save; } }
extern (C) void idt_handler_223() { asm { naked; push 0; push 223; jmp isr_save; } }
extern (C) void idt_handler_224() { asm { naked; push 0; push 224; jmp isr_save; } }
extern (C) void idt_handler_225() { asm { naked; push 0; push 225; jmp isr_save; } }
extern (C) void idt_handler_226() { asm { naked; push 0; push 226; jmp isr_save; } }
extern (C) void idt_handler_227() { asm { naked; push 0; push 227; jmp isr_save; } }
extern (C) void idt_handler_228() { asm { naked; push 0; push 228; jmp isr_save; } }
extern (C) void idt_handler_229() { asm { naked; push 0; push 229; jmp isr_save; } }
extern (C) void idt_handler_230() { asm { naked; push 0; push 230; jmp isr_save; } }
extern (C) void idt_handler_231() { asm { naked; push 0; push 231; jmp isr_save; } }
extern (C) void idt_handler_232() { asm { naked; push 0; push 232; jmp isr_save; } }
extern (C) void idt_handler_233() { asm { naked; push 0; push 233; jmp isr_save; } }
extern (C) void idt_handler_234() { asm { naked; push 0; push 234; jmp isr_save; } }
extern (C) void idt_handler_235() { asm { naked; push 0; push 235; jmp isr_save; } }
extern (C) void idt_handler_236() { asm { naked; push 0; push 236; jmp isr_save; } }
extern (C) void idt_handler_237() { asm { naked; push 0; push 237; jmp isr_save; } }
extern (C) void idt_handler_238() { asm { naked; push 0; push 238; jmp isr_save; } }
extern (C) void idt_handler_239() { asm { naked; push 0; push 239; jmp isr_save; } }
extern (C) void idt_handler_240() { asm { naked; push 0; push 240; jmp isr_save; } }
extern (C) void idt_handler_241() { asm { naked; push 0; push 241; jmp isr_save; } }
extern (C) void idt_handler_242() { asm { naked; push 0; push 242; jmp isr_save; } }
extern (C) void idt_handler_243() { asm { naked; push 0; push 243; jmp isr_save; } }
extern (C) void idt_handler_244() { asm { naked; push 0; push 244; jmp isr_save; } }
extern (C) void idt_handler_245() { asm { naked; push 0; push 245; jmp isr_save; } }
extern (C) void idt_handler_246() { asm { naked; push 0; push 246; jmp isr_save; } }
extern (C) void idt_handler_247() { asm { naked; push 0; push 247; jmp isr_save; } }
extern (C) void idt_handler_248() { asm { naked; push 0; push 248; jmp isr_save; } }
extern (C) void idt_handler_249() { asm { naked; push 0; push 249; jmp isr_save; } }
extern (C) void idt_handler_250() { asm { naked; push 0; push 250; jmp isr_save; } }
extern (C) void idt_handler_251() { asm { naked; push 0; push 251; jmp isr_save; } }
extern (C) void idt_handler_252() { asm { naked; push 0; push 252; jmp isr_save; } }
extern (C) void idt_handler_253() { asm { naked; push 0; push 253; jmp isr_save; } }
extern (C) void idt_handler_254() { asm { naked; push 0; push 254; jmp isr_save; } }
extern (C) void idt_handler_255() { asm { naked; push 0; push 255; jmp isr_save; } }
extern (C) void idt_handler_256() { asm { naked; push 0; push 256; jmp isr_save; } }

void setup_idt_table()
{
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
}
