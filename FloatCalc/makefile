# define some Makefile variables for the compiler and compiler flags
# to use Makefile variables later in the Makefile: $()
CC = gcc
CFLAGS  = -g -Wall -c	
NA = nasm
NAFLAGS = -g -f elf64 -w+all
# All Targets
all: calc

# Tool invocations
# Executable "calc" depends on the files: 
calc: main.o calc.o
	@echo 'Building target: calc'
	$(CC) main.o calc.o -o calc 
	@echo 'Finished building target: calc'


main.o: main.c    
	$(CC) $(CFLAGS) -o main.o main.c

calc.o: calc.s
	$(NA) $(NAFLAGS) calc.s -o calc.o 

# Clean the build directory and executable
clean: 
	rm -f *.o calc
