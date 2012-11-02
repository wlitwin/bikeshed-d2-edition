module kernel.interrupt_defs;

import kernel.interrupts;

import kernel.serial;
import kernel.support : panic;

extern (C) void
isr_save()
{
	asm {
		naked;
		//serial_outln("Got to ISR save!");
		// Need to save all of the registers
		// because the CPU expects these to not change
		pushad;  // 32-bytes
		push DS; // 36-byte
		push ES; // 40-byte
		push FS; // 44-byte
		push GS; // 48-byte
		push SS; // 52-byte


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
