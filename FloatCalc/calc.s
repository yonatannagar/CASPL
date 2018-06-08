section .data                    	; data section, read-write
an:	DQ	 0

section .bss
bn1:	resq	2		;will be the ptr to BN1
bn2:	resq	2		;will be the ptr to BN2
	
section .text                    	
        global 	s_add
	global 	s_sub

	
	extern	mini_bignum
	extern 	extend_bignum
	extern 	bn_free

	

	
s_add:	
        push    rbp              	; save Base Pointer (bp) original value
        mov     rbp, rsp         	; use base pointer to access stack contents

	;; rdi = *bn1, rsi = *bn2 | assume bn1 >= bn2
	mov	[bn1], rdi
	mov	[bn2], rsi
	
.continue:
	xor	rcx, rcx
	
	mov 	rdi, [bn1]	
	mov 	rcx, QWORD[edi]		;rcx = longer number counter
	mov	r10, QWORD[edi+8]	;r10 <- *bn1 char array
	
	xor	r8, r8
	mov	rdi, [bn2]
	mov 	r8, QWORD[edi] 		;r8 = shorter number counter
	mov 	r11, QWORD[edi+8]	;r11 <- *bn2 char array

	
	;; fix pointers to LSBs
	add 	r10, rcx
	dec 	r10

	add 	r11, r8
	dec 	r11


	;; clear carry flag and registers A B
	xor 	r15b, r15b
	xor 	rax, rax
	xor	rbx, rbx
	
.for:
	cmp	r8, 0
	je 	.c		;shorter number finished, jump to continuation

	;; load dl bl with chars
	mov 	al, BYTE[r10]	;dl<-bn1[i]
	mov 	bl, BYTE[r11]	;bl<-bn2[j]

	sub 	al, '0'
	sub 	bl, '0'
	add	al, bl		;a += b
	add	al, r15b	;a += carryflag
	xor	r15, r15	;clear carryflag

	
	cmp	al, 9		;check result is under 10
	jna	.single_digit	;jump if single digit (al<10)
	
	mov	r15b, 1		;carry flag
	sub	al, 10

.single_digit:

	add 	al, '0'
	mov 	BYTE[r10], al
	dec 	r8
	jmp	.end_itr
	
.c:
	cmp 	r15b, 0		;check for carryflag
	je	.end_itr	; if no carryflag, jump

	
	mov	al, BYTE[r10]
	sub	al, '0'
	inc 	al
	xor 	r15b, r15b
	
	cmp 	al, 9
	jna 	.csave

	mov 	r15b, 1
	sub	al, 10
.csave:
	add	al, '0'
	mov 	BYTE[r10], al
	
	jmp 	.end_itr
	
.end_itr:
	;; move pointers to next place in their responsive arrays
	dec 	r10
	dec	r11
	
	loop 	.for		;auto-dec rcx

	;;fix carry
	cmp 	r15b, 0
	je 	.end_routine
	
	;; helper func: extend_bignum

	xor 	rax, rax	
	xor	rdi, rdi
	mov	rdi, [bn1]
	mov	rsi, '1'

	call 	extend_bignum
	mov	[bn1], rax
	jmp	.end_routine	;skip no shift procedure



.end_routine:

	;; frees memory : bn2
	mov 	rdi, [bn2]	
	call 	bn_free

	mov	rax, [bn1]	
	mov	rsp, rbp
	pop	rbp
	ret

	

s_sub:
	push 	rbp
	mov	rbp, rsp
	
	;; rdi = *bn1, rsi = *bn2 | assume bn1 >= bn2
	mov 	[bn1], rdi	; [bn1]<- *to bignum1
	mov 	[bn2], rsi	; [bn2]<- *to bignum2
	
	xor	rcx, rcx	; rcx will be length(bn1)
	xor	r8, r8		; r8 will be length(bn2)
	xor 	r10, r10	; r10 will be ptr to bn1 array @ index
	xor	r11, r11	; r11 will be ptr to bn2 array @ index
	
	mov 	rcx, QWORD[edi]		;rcx = longer number counter
	mov	r10, QWORD[edi+8]	;r10 <- *bn1 char array
	
	mov 	r8, QWORD[esi] 		;r8 = shorter number counter
	mov 	r11, QWORD[esi+8]	;r11 <- *bn2 char array

	add 	r10, rcx	;r10 <-bn1.LSB
	dec 	r10

	add 	r11, r8		;r11 <-bn2.LSB
	dec 	r11
	
	xor 	rax, rax	;clear computational registers
	xor 	rbx, rbx	;clear computational registers
	xor	r15, r15	;clear borrowflag

.for:

	cmp	r8, 0
	je 	.c		;smaller number finished, jump to continuation
	;; load char values into A,B
	mov	al, [r10]
	mov	bl, [r11]

	sub	al, '0'
	sub	bl, '0'
	sub	al, bl
	sub	al, r15b
	xor 	r15b, r15b
	
	cmp	al, 10
	jb	.no_borrow
	
	add	al, 10
	mov	r15b, 1
	
.no_borrow:
	add 	al, '0'	
	mov	BYTE[r10], al
	dec	r8
	jmp	.end_itr


.c:
	cmp 	r15b, 0
	je	.end_itr	;noborrow

	mov	al, BYTE[r10]
	sub	al, '0'
	dec 	al
	xor 	r15b, r15b
	
	cmp 	al, 10
	jb 	.csave

	mov 	r15b, 1
	add	al, 10
	
.csave:
	add	al, '0'
	mov 	BYTE[r10], al
	
	jmp 	.end_itr

	
.end_itr:
	;; move pointers, loop
	dec 	r10
	dec	r11
	loop 	.for

	mov	rdi, [bn1]
	call	mini_bignum
	mov	[bn1], eax	;fix blank 0s if there are

	;; frees memory : bn2
 	mov 	rdi, [bn2]
 	call 	bn_free

	mov	rax, [bn1]	
	mov	rsp, rbp
	pop	rbp
	ret
