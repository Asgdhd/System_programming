array_asm: array.asm
	fasm array.asm

array_c: array_asm test.c
	gcc test.c array.o -o test_array

run: array_c test_array
	./test_array

clean:
	rm -f *.o test_array