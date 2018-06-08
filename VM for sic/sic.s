section .data

counter: dq	0
fs_in:	 db	"%ld",  0
fs_out:	 db 	"%ld ", 0
fs_newline:	db 0xA, 0

section .bss

Mem:		resq 	1
IO:		resq	1

sic_a:		resq 	1
sic_b:		resq 	1
sic_c:		resq 	1
;; ----------------------------------------------------------MACROS----------------------------------------------------------------- ;;
%macro 	inc_counter 0
	
	mov	rax, qword[counter]
	inc	rax
	mov	qword[counter], rax
	
%endmacro

%macro 	newline 0
	
	mov	rdi, fs_newline
	mov	rax, 0
	call	printf
	
%endmacro
	
%macro 	move3	1
	
	mov	rax, qword[%1]
	add	rax, 24
	mov	qword[%1], rax


	
%endmacro
	
%macro 	is_end 3

	mov	rax, [%1]
	mov	rbx, [%2]
	mov	rcx, [%3]

	mov	rax, qword[rax]
	mov	rbx, qword[rbx]
	mov	rcx, qword[rcx]

	or	rax, rbx
	or 	rax, rcx

	cmp	rax, 0

%endmacro

%macro 	deref 3

	mov	r10, [%1]
	mov	r10, [r10] 	
	mov	r11, qword[Mem]
	lea 	rax, [r11 + r10 * 8]
	mov 	r8, rax
	mov	rax, [rax]

	mov	r10, [%2]
	mov	r10, [r10]
	mov	r11, qword[Mem]
	lea	rbx, [r11 + r10 * 8]
	mov	rbx, [rbx]

	mov	r10, [%3]
	mov	rcx, [r10]
	;; rax = M[M[A]]
	;; rbx = M[M[B]]
	;; rcx = M[M[C]]
	;; r8 = *M[A]
	
%endmacro

section .text
	extern calloc, scanf, free, printf
	global main

;; ------------------------------------------------------------MAIN----------------------------------------------------------------- ;;
	
main:
	enter 	0, 0
	nop
	;; USE RBP AS OLD RSP

	;; scanf loop till EOF
.loop:
	mov	rdi, fs_in
	mov	rsi, IO
	xor 	rax, rax
	call	scanf

	;; if scanf received EOF => eax  == -1
	cmp	eax, -1
	jz	.alloc

	push	qword[IO]

	inc_counter
	jmp 	.loop
	;; memory allocation and filling
.alloc:
	mov	rdi, qword[counter]
	mov	rsi, 8
	xor	rax, rax
	call 	calloc

	;; rax = ptr to mem_array
	mov	qword[Mem], rax
	;;;;;;;; fill array:

	mov	rcx, qword[counter] ; counter

	;; fixing ptrs to start of their respective arrays
	mov	r8, qword[Mem]
	mov	r9, rbp
	sub	r9, 8
	
.loop2:
	
	mov	rax, qword[r9] 	
	mov	qword[r8], rax

	add	r8, 8
	sub	r9, 8
	
	dec	rcx
	cmp	rcx, 0
	jnz 	.loop2

	mov	rsp, rbp
	;; run in 3s - 0 0 0 = EOF for sic
.run:
	;; if counter < 3 => jmp .dump (not enough cmds)
	mov	rdx, qword[counter]
	cmp	rdx, 3
	jb	.dump
	
	;; set to cmd args 0 1 2
	mov	rax, qword[Mem]
	mov	qword[sic_a], rax

	add	rax, 8
	mov	qword[sic_b], rax

	add	rax, 8
	mov	qword[sic_c], rax
	
	;; loop label
.while:
	;; if A & B & C == 0 => jmp to .dump
	deref 	sic_a, sic_b, sic_c
	;; rax = A, rbx = B, rcx = C
	;; LOGIC ::=
	;; (A -= B)<0 ? goto C : A+=3, B+=3, C+=3
	sub 	rax, rbx
	mov	qword[r8], rax

	cmp 	rax, 0
	jge 	.move_3
	
	;; goto C
	mov	rax, qword[Mem]
	lea	rax, [rax + rcx * 8]
	;; now  A = *C
	mov	qword[sic_a], rax
	add	rax, 8
	mov	qword[sic_b], rax
	add	rax, 8
	mov	qword[sic_c], rax
		
	jmp 	.end_while
.move_3:
	move3 	sic_a
	move3	sic_b
	move3	sic_c
	
.end_while:
	is_end	sic_a, sic_b, sic_c
	jne 	.while
	
	
	;; print loop memorydump
.dump:
	mov	rcx, qword[counter]
	mov	r15, qword[Mem]
	
.loop3:
	push	rcx
	
	mov	rdi, fs_out
	mov	rsi, qword[r15]
	mov	rax, 0
	call	printf

	pop 	rcx

	add	r15, 8
	loop	.loop3

	newline 		; newline after memory dump to insure flushing stdout
	
	;; exit routine
.exit:

	mov	rdi, qword[Mem]
	call	free

	leave
	ret
