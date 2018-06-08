	;; ------------------------------------------------------I/O FORMATS---------------------------------------------------;;
	
section .data
fs_epsilon:
	db "epsilon = %lf", 0
fs_order:
	db 0xA,"order = %ld", 0
fs_coeff:
	db 0xA,"coeff %ld = %lf %lf", 0
fs_init:
	db 0xA,"initial = %lf %lf", 0

	
fs_print_epsilon:
	db "epsilon out: %.17g", 0xA, 0
fs_print_order:
	db "order out: %ld", 0xA, 0
fs_print_init:
	db "init out: %.17g %.17g", 0xA, 0 
fs_print_result:
	db "root = %.17g %.17g", 0xA, 0
fs_print_error:
	db "Error: derivative goes to 0, computation failed", 0xA, 0
	
zero:	dq 0
	;; ---------------------------------------------------UNINIT LABELS-----------------------------------------------------;;
	
section .bss
	
res_real:	resq	1	
res_img:	resq	1
epsilon:	resq	1
order:		resq	1
d_order		resq	1
coeff:		resq 	1
	
in_real:	resq	1
in_img:		resq 	1
	
initial_real:	resq	1
initial_img:	resq	1

z_real:		resq	1
z_img:		resq	1

fz_real:	resq	1
fz_img:		resq	1

dfz_real:	resq	1
dfz_img:	resq	1

div_real:	resq	1
div_img:	resq	1
	
tmp_real:	resq	1
tmp_img:	resq 	1
	
f_real:		resq 	1
f_img:		resq	1

df_real:	resq	1
df_img:		resq	1


	;; -------------------------------------------------------MACROES-------------------------------------------------------;;
	
%macro allocate_memory 4		;get labels in order: f_real f_img df_real df_img
	mov	rdi, [order]	
	
	mov	rsi, 8
	mov	rax, rdi
	mul	rsi
	
	mov	rbx, 4
	mul	rbx
	
	add	rax, 16
	mov	rdi, rax
	xor	rax, rax
	
	call 	malloc
	;; 	rax = *place in memory

	mov	QWORD[%1], rax
	;; f_real = rax (first place in memory)	
	mov	r10, QWORD[%1]
	mov	rdi, [order]
	inc	rdi
	lea	r10, [r10 + 8*rdi]
	
	mov	QWORD[%2], r10	
	;; f_img = rax + (order+1)*8

	lea	r10, [r10 + 8*rdi]
	mov	QWORD[%3], r10	
	;; df_real = rax + (order+1)*8 + (order+1)*8
	dec	rdi
	lea	r10, [r10 + 8*rdi]
	
	mov	QWORD[%4], r10
	;; df_img = rax + (order+1)*8 + (order+1)*8 + order*8
	;; all arrays are set
	

%endmacro

%macro get_from_arr 2 		; array, index
	
	mov	r15, %1
	mov	r14, qword[r15]
	mov	rax, %2
	lea	r15, [r14 + 8*rax]
	
%endmacro

	
%macro set_in_arr 3		; array, index, element

	mov	r15, %1
	mov	rax, %2
	mov	r15, qword[r15]
	lea	r15, [r15 + 8*rax]
	movsd	xmm0, %3
	movsd	QWORD[r15], xmm0

%endmacro

	
	
	;; -------------------------------------------------------CODE----------------------------------------------------------;;	
	;; ---------------------------------------------------------------------------------------------------------------------;;
	
section	.text
	global 	main
	extern 	printf, scanf, malloc, free, fflush, stdout
	;; -------------------------------------------------SMALL_ENOUGH--------------------------------------------------------;;
	;; rdi = *point.real, rsi = *point.img
small_enough:
	enter	0, 0
	finit

	mov	rax, 0		;false

	fld	QWORD[rdi]
	fld	QWORD[rdi]
	fmul

	fld	QWORD[rsi]
	fld	QWORD[rsi]
	fmul

	fadd

	fld 	QWORD[epsilon]
	fld	QWORD[epsilon]
	fmul

	;; (eps^2  ??  a^2 + b^2)
	fcomi

	jbe	.ret
	mov	rax, 1 		;fix to true
	
.ret:
	leave
	ret


	;; --------------------------------------------------COMPLEX_ADD-------------------------------------------------------;;
comp_add:
	enter 	32, 0
	finit
	;; rdi = real1, rsi = img1
	;; rdx = real2, rcx = img2
	fld 	QWORD[rdi]
	fld 	QWORD[rdx]
	fadd

	fst 	QWORD[rbp-32]
	movsd	xmm0, QWORD[rbp-32]
	;; xmm0 = result_real

	fld	QWORD[rsi]
	fld	QWORD[rcx]
	fadd

	fst	QWORD[rbp-16]
	movsd	xmm1, QWORD[rbp-16]
	;; xmm1 = result_img

	leave
	ret

	;; --------------------------------------------------COMPLEX_SUB-------------------------------------------------------;;
comp_sub:
	enter 	32, 0
	finit
	;; rdi = real1, rsi = img1
	;; rdx = real2, rcx = img2
	fld 	QWORD[rdi]
	fld 	QWORD[rdx]
	fsub

	fst 	QWORD[rbp-32]
	movsd	xmm0, QWORD[rbp-32]
	;; xmm0 = result_real

	fld	QWORD[rsi]
	fld	QWORD[rcx]
	fsub

	fst	QWORD[rbp-16]
	movsd	xmm1, QWORD[rbp-16]
	;; xmm1 = result_img

	leave
	ret
	;; --------------------------------------------------COMPLEX_MUL-------------------------------------------------------;;
comp_mul:
	enter	32, 0
	finit
	;; rdi = real1, rsi = img1
	;; rdx = real2, rcx = img2
	;; (a+bi)(c+di) = (ac-bd) + (ad+bc)i
	fld 	QWORD[rdi]
	fld 	QWORD[rdx]
	fmul
	fld	QWORD[rsi]
	fld	QWORD[rcx]
	fmul
	fsub
	
	fst	QWORD[rbp-32]
	movsd	xmm0, QWORD[rbp-32]
	;; xmm0 = (ac-bd)
	
	fld	QWORD[rdi]
	fld	QWORD[rcx]
	fmul
	fld 	QWORD[rsi]
	fld	QWORD[rdx]
	fmul
	fadd

	fst	QWORD[rbp-16]
	movsd	xmm1, QWORD[rbp-16]
	;; xmm1 = (ad+bc)

	leave
	ret
	;; --------------------------------------------------COMPLEX_DIV-------------------------------------------------------;;
comp_div:
	enter	48, 0
	finit
	;; rdi = a, rsi = b
	;; rdx = c, rcx = d
	;; (a+bi) / (c+di) = ( (ac+bd) / (c^2 + d^2) ) + ( (bc - ad) / (c^2 + d^2) )i
	
	;; calc c^2 + d^2 store to stack
	fldz
	
	fld	QWORD[rdx]
	fld	QWORD[rdx]
	fmul

	fld	QWORD[rcx]
	fld	QWORD[rcx]
	fmul

	fadd
	
	fcomi
	je	error
	
	fst	QWORD[rbp-48]
	;; [rbp-48] = c^2 + d^2

	fld	QWORD[rdi]
	fld	QWORD[rdx]
	fmul

	fld	QWORD[rsi]
	fld	QWORD[rcx]
	fmul

	fadd

	fld	QWORD[rbp-48]

	fdiv
	fst	QWORD[rbp-32]
	
	movsd	xmm0, QWORD[rbp-32]
	;; xmm0 = result_real

	
	fld 	QWORD[rsi]
	fld	QWORD[rdx]
	fmul

	fld	QWORD[rdi]
	fld	QWORD[rcx]
	fmul

	fsub

	fld	QWORD[rbp-48]

	fdiv

	fst 	QWORD[rbp-16]
	movsd	xmm1, QWORD[rbp-16]
	;; xmm1 = result_img

	leave
	ret

	;; -----------------------------------------------------EVAL-----------------------------------------------------------;;
	;; eval(point_real:rdi, point_img:rsi, array_real:rdx, array_img:rcx, function_size:r8) => (result_real:xmm0, result_img:xmm1)
	
eval:
	enter 	0, 0

	mov	r10, rdx	;r10 = array_real[0]
	mov	r11, rcx	;r11 = array_img[0]

	mov	r12, rdi	;r12 = *point.real
	mov	r13, rsi	;r13 = *point.img

	
	get_from_arr	r10, r8 ; r15 = array_real[poly_order]
 	movsd	xmm0, QWORD[r15]

	;; tmp_real = array_real[poly_order]
	movsd	QWORD[tmp_real], xmm0
	
	get_from_arr	r11, r8	; r15 = array_img[poly_order]
 	movsd	xmm1, [r15]

	;; tmp_img = array_img[poly_order]
	movsd	QWORD[tmp_img], xmm1

	cmp 	r8, 0
	jbe 	.continue
	
	mov	r9, r8		; r9 (loop_counter)  = poly_order

.horner:
	dec	r9
	mov	rdi, r12
	mov 	rsi, r13

	
	mov	rdx, tmp_real
	mov	rcx, tmp_img
	
	call 	comp_mul
	movsd	QWORD[tmp_real], xmm0
	movsd	QWORD[tmp_img], xmm1

	mov	rdi, r12
	mov	rsi, r13
	get_from_arr	r10, r9
	mov	rdi, r15
	get_from_arr	r11, r9
	mov	rsi, r15
	mov	rdx, tmp_real
	mov	rcx, tmp_img
	call 	comp_add

	movsd	QWORD[tmp_real], xmm0
	movsd	QWORD[tmp_img], xmm1

	cmp 	r9, 0
	ja	.horner
.continue:	
	movsd	xmm0, QWORD[tmp_real]
	movsd	xmm1, QWORD[tmp_img]
	
	leave
	ret

	;; ----------------------------------------------GENERATE_DERIVATIVE---------------------------------------------------;;
	; generate_derivative(rdi=f_real, rsi=f_img, rdx=d_real, rcx=d_img, r8=order)=>void
generate_derivative:

	enter 0,0
	finit
	
	mov QWORD [d_order],r8			;d_order=order
	;; convert order to float
	fild QWORD [d_order]
	fst QWORD [d_order]
.for:
	
	
	get_from_arr f_real,r8
	mov r11, r15			;r11=f_real[i]
	get_from_arr f_img,r8
	mov r12, r15			;r12=f_img[i]
	
	push rdi
	push rsi
	push rdx
	push rcx

	;; prepare for comp_mul
	mov rdi, r11			;rdi=f_real[i]
	mov rsi, r12			;rsi=f_img[i]
	mov rdx, d_order		;rdx=i
	mov rcx,zero			;rcx=0
	call comp_mul


	movsd QWORD [tmp_real], xmm0			;tmp_real=result_real 
	movsd QWORD[tmp_img], xmm1			;tmp_img=result_img

	pop rcx
	pop rdx
	pop rsi
	pop rdi

	
	dec r8
	;;fix order again
	mov QWORD[d_order],r8
	fild QWORD [d_order]
	fst QWORD [d_order]
	set_in_arr df_real, r8, [tmp_real]		;d_real[i-1]=(i)*f_real[i]
	set_in_arr df_img, r8, [tmp_img]		;d_img[i-1]=(i)*f_img[i]
	
	cmp r8,0
	ja .for
	leave
	ret
	
	;; -----------------------------------------------------MAIN-----------------------------------------------------------;;
main:
	enter 	0, 0
	nop
	finit			
	
.get_epsilon:
	mov 	rdi, fs_epsilon
	mov 	rsi, epsilon
	mov 	rax, 0
	call 	scanf

.get_order:
	mov	rdi, fs_order
	mov	rsi, order
	mov 	rax, 0
	call 	scanf

.generate_polynome:
	allocate_memory f_real, f_img, df_real, df_img
	
	;; f_real = new array[order+1]
	;; f_img = new array[order+1]
	;; df_real = new array[order]
	;; df_img = new array[order]
	
	mov	rcx, [order]
	inc	rcx 		;rcx = order+1

.for:

	push	rcx

	
	mov	rdi, fs_coeff
	mov	rsi, coeff
	mov	rdx, in_real
	mov	rcx, in_img
	mov	rax, 0
	call 	scanf

	pop	rcx
	;; filled coeff #, in_real, in_img
	;; next: move to appropriate place in the array
	set_in_arr 	f_real, [coeff], [in_real]
	set_in_arr 	f_img, [coeff], [in_img]

	dec	rcx
	cmp	rcx, 0
	jnz	.for

	mov rdi, f_real		
	mov rsi, f_img
	mov rdx, df_real
	mov rcx, df_img
	mov r8, [order]
	call generate_derivative 
	
	
.get_initial:
	mov	rdi, fs_init
	mov	rsi, initial_real
	mov	rdx, initial_img
	mov	rax, 0
	call 	scanf
	

	;; START WORKING
	;; (small_enough) jmp
	mov	r15, qword[initial_real]
	mov	[z_real], r15
	mov	r15, qword[initial_img]
	mov	[z_img], r15
	;; loop iteration : zn+1 = zn - f(zn) / df(zn) 

.loop:
	;; 1. calc f(zn)
	mov	rdi, z_real
	mov	rsi, z_img
	mov	rdx, f_real
	mov	rcx, f_img
	mov	r8, [order]
	call 	eval

	movsd	[fz_real], xmm0
	movsd	[fz_img], xmm1

	mov	rdi, fz_real
	mov	rsi, fz_img
	
	call 	small_enough

	cmp	rax, 1
	je	.done


	;; 2. calc df(zn)
	mov	rdi, z_real
	mov	rsi, z_img
	mov	rdx, df_real
	mov	rcx, df_img
	mov	r15, [order]
	dec 	r15
	mov	r8, r15
	call 	eval

	movsd	[dfz_real], xmm0
	movsd	[dfz_img], xmm1
	;; check if df(zn) == 0
	finit
	fldz
	fld 	qword[dfz_real]
	fcomi
	je	error

	finit
	fldz
	fld	qword[dfz_img]
	fcomi
	je	error
	;; 3. calc f(zn) / df(zn)
	mov	rdi, fz_real
	mov	rsi, fz_img
	mov	rdx, dfz_real
	mov	rcx, dfz_img
	call 	comp_div

	movsd	[div_real], xmm0
	movsd 	[div_img], xmm1
	;; 4. calc zn - f(zn) / df(zn)
	mov	rdi, z_real
	mov	rsi, z_img
	mov	rdx, div_real
	mov	rcx, div_img

	call 	comp_sub

	movsd	[z_real], xmm0
	movsd	[z_img], xmm1

	jmp 	.loop
	;; put: rdi <- new real, rsi <- new img. then jmp


.done:
	mov 	rdi, fs_print_result
	mov	rax, 2
	movsd	xmm0, qword[z_real]
	movsd	xmm1, qword[z_img]
	call	printf

.done2:
	mov	rdi, [f_real]
	call	free

	mov	rdi, [stdout]
	call	fflush
	
	mov rax, 60		;close to shell
	syscall




error:
	mov	rdi, fs_print_error
	mov	rax, 0
	call 	printf
	jmp 	main.done2
	
