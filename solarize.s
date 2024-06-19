; SOLARIZE.COM

; Resident Solarized theme for MS-DOS
; writen by Dmitry Gerasimuk, based on old
; TSR skeleton code for loading high into umb if exists etc.
; Loads/unloads safely.
; ye olde code - Dark Fiber [NuKE]
; (converted from Tasm to Nasm at some point in its lifetime)
;

[bits 16]
[org 0x100]
[cpu 8086]

%define w word
%define d dword

%macro proc16 1
[section .text]

align 2, db 0x90
%1:
%endmacro

%macro setColor 4                     
        mov AX, 1007h              ; Get register for color 
        Mov BL,%1
        Int 10h
        Xor BL, BL
        XChg BH, BL               ;   Put register in BL 
        Mov AX, 1010h             ;   Set RGB for individual colo 
        Mov DH, %2                ;r
        Mov CH, %3                ;g
        Mov CL, %4                ;b
        Int 10h

%endmacro

[section .text]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Resident code chunk here

start:
 
	jmp setup_isr
	db 0x90
alignb 2, db 0x90

old_int_11:	
	dw 0		; segment
	dw 0		; offset
	
old_ax 	dw 0

proc16 my_interrupt
	;; do whatever!
	nop
	nop
	nop
	nop
	mov [cs:old_ax], ax
	cmp ah, 0				; is this a call to set the video mode? (ah = 0)
	jne justCall

	pushf
    mov ax,cs
	push ax
	mov ax, here
	push ax
	mov ax, [cs:old_ax]
	justCall:
	jmp far [cs: old_int_11]
  
	here:
	
	push ax
	push si
	push es
	push di
	push dx
	push cx
	setSolarized:
;     EGA   VGA
; 0x0   0x00  Black
; 0x1   0x01  Blue
; 0x2   0x02  Green
; 0x3   0x03  Cyan
; 0x4   0x04  Red
; 0x5   0x05  Magenta
; 0x6   0x14  Brown
; 0x7   0x07  Light Gray
; 0x8   0x38  Gray
; 0x9   0x39  Light Blue
; 0xA   0x3A  Light Green
; 0xB   0x3B  Light Cyan
; 0xC   0x3C  Light Red
; 0xD   0x3D  Light Magenta
; 0xE   0x3E  Light Yellow
; 0xF   0x3F  White
sti
setColor 0x01, 0, 22, 38 ; auto for color blue
setColor 0x02, 33, 38, 0 ; auto for color green
setColor 0x03, 10, 40, 38 ; auto for color aqua
setColor 0x04, 55, 12, 11 ; auto for color red
setColor 0x05, 27, 28, 49 ; auto for color purple
setColor 0x06, 45, 34, 0 ; auto for color yellow
setColor 0x07, 36, 40, 40 ; auto for color white
setColor 0x08, 25, 30, 32 ; auto for color gray
setColor 0x09, 9, 34, 52 ; auto for color lightblue
setColor 0x0a, 21, 63, 21 ; auto for color lightgreen
setColor 0x0b, 21, 55, 55 ; auto for color lightaqua
setColor 0x0c, 63, 21, 21 ; auto for color lightred
setColor 0x0d, 63, 21, 63 ; auto for color lPurple
setColor 0x0e, 63, 63, 21 ; auto for color lYellow
setColor 0x0f, 63, 63, 63 ; auto for color brightWhite
setColor 0x14, 45, 34, 0 ; auto for VGA brown color  
setColor 0x38, 21, 21, 21 ; auto for VGA color  
setColor 0x39, 21, 21, 63 ; auto for VGA color  
setColor 0x3a, 21, 63, 21 ; auto for VGA color  
 
setColor 0x3b, 21, 55, 55 ; auto for VGA color  
setColor 0x3c, 63, 21, 21 ; auto for VGA color  
setColor 0x3d, 63, 21, 63 ; auto for VGA color  
setColor 0x3e, 63, 63, 21 ; auto for VGA color  
setColor 0x3f, 63, 63, 63 ; auto for VGA color  

setColor 0x00, 0, 10, 13 ; auto for color black
cli
		pop cx
	pop dx
	pop di
	pop es
	pop si
	pop ax
	

	iret


;; paragraph align for tsr memory block
alignb 0x10, db 0
end_tsr_part:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup code down here, nothing resident below here...

proc16 setup_isr
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov sp,end_stack
	mov bx,sp
	add bx,15
	shr bx,1
	shr bx,1
	shr bx,1
	shr bx,1
	mov ah,0x4A
	int 0x21

	;; hook int11 as example
	mov ax,0x3510
	int 0x21

	mov w[old_int_11+2],es
	mov w[old_int_11+0],bx

    ; set to video mode 1 (40x25 text) to force a complete screen mode change
	 
	;; test it is ourself or someone else
	mov di,bx
	mov si,my_interrupt
	mov cx,setup_isr
	sub cx,si
	repe cmpsb
	jnz .go_resident

	;; its us, so detach int 11
	mov dx,w[es: old_int_11+0]
	mov ds,w[es: old_int_11+2]
	mov ax,0x2510
	int 0x21


	;; free tsr memory
	mov ah,0x49
	int 0x21

	mov ax,cs
	mov ds,ax

MOV AH, 12h
MOV BL, 31h
MOV AL, 00h
INT 10h

MOV AH, 00h
MOV AL, 03h
INT 10h
 
mov ax, 0x3
	int 0x10 		

	mov dx,msg_unhook
	mov ah,9
	int 0x21

	;; quit
	mov ah,0x4C
	int 0x21

.go_resident:
	call setup_tsr_memory_block
	;; tsr code block is in BP

	mov ds,bp

	mov ax,0x2510
	mov dx,my_interrupt
	int 0x21

	;; free environment
	mov ax,cs
	mov ds,ax

	mov es,w[0x2C]
	mov ah,0x49
	int 0x21
	
    ; set video mode to 3 to test the interrupt routine 
	mov ax, 0x3 
	int 0x10 	
    mov dx, msg_hook   ; print the message
        mov bl,7
        mov ah,9
        int 21h
    
	  

	 

	mov ax,cs
	cmp ax,bp
	jz .tsr_low_memory

	;; only free ourself if we are not ourselves (tsr in umb)
	mov ah,0x49
	int 0x21
	

	mov ah,0x4C
	int 0x21

.tsr_low_memory:
	;; go tsr
	mov dx,setup_isr		;; already aligned correctly for tsr
	shr dx,1
	shr dx,1
	shr dx,1
	shr dx,1
	mov ah,0x31
	int 0x21
	

proc16 setup_tsr_memory_block
	push ds
	pop es

	mov bp,ds

	mov ax,0x3000
	int 0x21
	cmp al,5
	jb .nd0

	push ax

	;; chain umb
	mov ax,0x5803
	mov bx,1
	int 0x21

	pop ax

.nd0:
	cmp al,3
	jb .alloc_low

	;; last fit allocation strategy
	mov ax,0x5801
	mov bx,2
	int 0x21

	call alloc_block
	jc .nd90

	mov es,ax

	;; if its not umb, dont use it!
	cmp ax,0xA000
	jae .alloc_is_good

	;; free
	mov ah,0x49
	int 0x21

	mov ax,cs
	mov es,ax

.alloc_low:
	;; reset mem strategy to low
	call reset_alloc_low
	call alloc_block
	jc .nd90

	;; is our block below our cs
	mov bx,cs
	cmp ax,bx
	jb .alloc_is_good

	mov es,ax
	mov ah,0x49
	int 0x21
	mov ax,cs
	mov es,ax
	jmp .nd90

.alloc_is_good:
	mov bp,ax

.nd90:
	;; fail!
	call reset_alloc_low

	;; free up old environment blocks
	mov es,w[cs: 0x2c]
	mov ah,0x49
	int 0x21


	;; set owner to itself so dos does not free it up
	mov ax,bp
	dec ax
	mov es,ax
	inc ax
	mov w[es: 1], ax

	;; own memory
	mov ax,cs
	mov ds,ax

	;; lets do a MCB fudge for naming
	mov si,mytsr_name
	mov di,8
	mov cx,4
	rep movsw

	;; copy down
	mov ax,cs
	mov ds,ax
	mov es,bp
	cmp ax,bp
	jz .skip_move

	xor si,si
	xor di,di
	mov cx,end_tsr_part
	shr cx,1
	rep movsw

.skip_move:
	mov ax,cs
	mov ds,ax
	mov es,ax
	ret


proc16 alloc_block
	;; try and allocate upper memory
	mov ax,0x4800
	mov bx,end_tsr_part ;- 0x100
	shr bx,1
	shr bx,1
	shr bx,1
	shr bx,1
	int 0x21
	ret

proc16 reset_alloc_low
	mov ax,0x3000
	int 0x21
	cmp al,5
	jb .nd99

	push ax
	;; unchain UMB's
	mov ax,0x5803
	xor bx,bx
	int 0x21
	pop ax

.nd99:
	;; reset allocation strategy
	cmp al,3
	jb .nd100
	mov ax,0x5801
	xor bx,bx
	int 0x21

.nd100:
	ret

[section .data]
	;; MCB name, must be 8 characters here
mytsr_name: db 'SOLARIZE',0,0,0
 
msg_hook: db 'DS: hooked int 0x10. Run again to remove',0x0d,0x0a,'$'
msg_unhook: db 'DS: unhooked int 0x10 and removed TSR',0x0d,0x0a,'$'
[section .bss]
align 2
	resw 256
end_stack:
