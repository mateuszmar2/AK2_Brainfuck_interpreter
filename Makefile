run_brainfuck: brainfuck

brainfuck: brainfuck.o
	ld brainfuck.o -o brainfuck -m elf_i386
	./brainfuck

brainfuck.o: brainfuck.s
	clear
	as brainfuck.s -o brainfuck.o --32 -g