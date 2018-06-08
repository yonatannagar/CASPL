# All Targets
all: sic

# Tool invocations
# Executable "sic" depends on the files: 
sic: sic.o
	gcc -no-pie sic.o -o sic
	rm -f *.o


sic.o: sic.s
	nasm -g -f elf64 -w+all sic.s -o sic.o 

# Clean the build directory and executable
clean: 
	rm -f *.o sic
