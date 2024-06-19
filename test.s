; setting solarized palette in dos
; Restoring the pallete

cr      equ     0dh
lf      equ     0ah

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


org 100h
jmp     Begin

PaletteStripe 	db 	' ',07h,' ',07h,' ',07h,0xDC,01h,0xDC,02h,0xDC,03h
	        db 	0xDC,04h,0xDC,05h,0xDC,06h
	        db 	0xDC,07h,0xDC,08h,0xDC,09h
	        db 	0xDC,0Ah,0xDC,0Bh,0xDC,0Ch

	        db     	0xDC,0Dh,0xDC,0Eh,0xDC,0Fh
            db      cr,07h,lf,07h
            


PaletteStripeLen  dw	$-PaletteStripe

Msg     db      cr,lf,' . Print Color Stripe',cr,lf,' . github.com/dmitrygerasimuk/msdos-solarized-theme',cr,lf,'$'
Begin:

     

         mov dx, Msg   ; print the message
        mov bl,7
        mov ah,9
        int 21h
        mov ah,03h
        int 10h
        ; now DH AND DL are set to current cursor position
       ; mov dh, DH      ; y value coords for palette stripe to print (bottom of the screen)
        ;mov dl, DL      ; x value 
        
        mov bp, PaletteStripe
        mov cx, [PaletteStripeLen]
        shr cx,1
        mov bh,0
        mov ah, 13h
        mov al,2
        int 10h

     

        mov ax, 4c00h ; return to DOS
        int 21h
