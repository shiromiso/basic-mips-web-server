#/bin/bash
mipsel-linux-gnu-as main.s -o main.o
mipsel-linux-gnu-gcc main.o -o main -nostdlib -static
