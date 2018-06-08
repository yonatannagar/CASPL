# define some Makefile variables for the compiler and compiler flags
# to use Makefile variables later in the Makefile: $()
CC = gcc
CFLAGS  = -g -Wall -c	
NA = nasm
NAFLAGS = -g -f elf64 -w+all
# All Targets
all: root

# Tool invocations
# Executable "root" depends on the files: 
root: root.o
	$(CC) -no-pie root.o -o root
	@echo "Success!"

root.o: root.s
	$(NA) $(NAFLAGS) root.s -o root.o 

# Clean the build directory and executable
clean: 
	rm -f *.o root
