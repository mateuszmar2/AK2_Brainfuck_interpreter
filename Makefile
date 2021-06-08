brainfuck: brainfuck.s
	clear
	gcc brainfuck.s -o brainfuck -m32

clean:
	rm -f brainfuck
