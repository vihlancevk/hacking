.model tiny
.186
.data

VIDEOSEG = 0b800h

CONSOLE_WIDTH  = 25d
CONSOLE_LENGTH = 80d

X = 22d
Y = 10d
START_POINT = (Y * 80d + X) * 2d

FRAME_WIDTH  db 0d
FRAME_LENGTH db 0d

Elems db 2bh, 2dh, 2bh, 0b3h, 20h, 0b3h, 2bh, 2dh, 2bh
; + - +
; |   |
; + - +

LINE_COLOR = 70h

ERRRO_MSG db 'Invalid password length!$'
WELCOME_MSG db 'Enter the password (6 characters):$'
ENTERED_PASSWORD db 0ffh, 8 dup(00h)
VALID_PASSWORD db '123456'

locals @@ ; (lb - global label, @@lb - local label)

;------------------------------------------------
; The function clears the screen
;
; Entry: none
; Note: ES - videoseg addr (0b800h)
; Exit: none
; Destr: AX, CX, SI
;------------------------------------------------

ClearScreen	proc

	mov ax, VIDEOSEG
	mov es, ax

	mov cx, 25d * 80d * 2d
	mov si, 0d
@@lp:
	mov al, 0d
	mov es:[si], al

	inc si

	loop @@lp

	ret

ClearScreen	endp

;------------------------------------------------
; The function sets the parameters of the frame
;
; Entry: - AX - FRAME_WIDTH
;		 - BX - FRAME_LENGTH
; Exit: none
; Destr: AX, BX, SI
;------------------------------------------------

SetFrameSize	proc

	add ax, 2d
	mov si, offset FRAME_LENGTH
	mov ds:[si], al
	mov si, offset FRAME_WIDTH
	add bx, 2d
	mov ds:[si], bl

	ret

SetFrameSize	endp

;------------------------------------------------
; Draw a line in a frame
;
; Entry:	AH - color (attr) of line
;			CX - lenght of string
;			SI - addr of 3-byte array containing line elements
;			DI - adress of start of line
;			ES - videoseg addr (0b800h)
; Exit:		none
; Destr:	AX, CX, DI, SI
;------------------------------------------------

DrawLine	proc	; cld (Clear Dest Flag) (++), std (Set   Dest Flag) (--)

	mov al, ds:[si]		; lodcb (Load String of )
	inc si

	mov es:[di], ax		; stosw (Store String of Words)
	add di, 2d			

	mov al, ds:[si]		; lodcb
	inc si

	sub cx, 2d
	jbe @@stop_line

@@next_sym:
	mov es:[di], ax		; rep stosw
	add di, 2d
	loop @@next_sym

	mov al, ds:[si]		; lodsb

	mov es:[di], ax		; stosw
	add di, 2d

@@stop_line:
	ret

DrawLine	endp

;------------------------------------------------
; Draw frame
;
; Entry:	- FRAME_WIDTH
;			- FRAME_LENGTH
; Note:		ES - videoseg addr (0b800h)
; Exit:		none
; Destr:	AX, BX, CX, DX, DI, SI, ES
;------------------------------------------------

DrawFrame	proc

	mov ax, VIDEOSEG
	mov es, ax
	
	;================================================
	; Draw first line of frame
	;------------------------------------------------
	mov ah, LINE_COLOR
	mov cl, FRAME_LENGTH
	mov si, offset Elems
	mov di, START_POINT
	call DrawLine
	;================================================

	;================================================
	; Draw the main part of frame
	;------------------------------------------------
	mov dx, 1d	

	mov cl, ds:[FRAME_WIDTH]
	sub cx, 2d

@@lp:
	mov di, START_POINT		
	mov ah, dl
	mov al, CONSOLE_LENGTH * 2d
	mul ah
	add di, ax
		
	mov ah, LINE_COLOR
	mov bx, cx
	mov cl, FRAME_LENGTH
	mov si, offset Elems
	add si, 3d
	call DrawLine

	inc dx
	mov cx, bx
	loop @@lp
	;================================================	
		
	;================================================
	; Draw last line of frame
	;------------------------------------------------
	mov cl, ds:[FRAME_LENGTH]
       
    mov si, offset Elems
	add si, 6d

	mov di, START_POINT
	mov ah, dl
	mov al, CONSOLE_LENGTH * 2d
	mul ah
	add di, ax
	
    mov ah, LINE_COLOR
	call DrawLine
	;================================================
		
	ret

DrawFrame endp

;------------------------------------------------
; Print the message to the screen
;
; Entry: SI - addr of the msg
; Note: - ES - videoseg addr (0b800h)
;		- DI - addr of the space on the screen
; Exit:		none
; Destr: AX, SI, DI
;------------------------------------------------

PrintMsg	proc

	mov ax, VIDEOSEG
	mov es, ax

	mov di, START_POINT
	mov ah, 1
	mov al, CONSOLE_LENGTH * 2d
	mul ah
	add di, ax
	add di, 2d

@@print_sym:
	mov ax, '$'
	cmp ds:[si], al
	je @@stop_print

	mov ax, ds:[si]
	mov es:[di], al
	add di, 2d
	inc si
	jmp @@print_sym

@@stop_print:
	ret

PrintMsg	endp

;------------------------------------------------
; String length counting function (the string must
; end with the character $)
;
; Entry:	DI - addr of the beginning of the string
; Note:		$ - 24h (ASCII code)
; Exit:		CX - string length
; Destr:	AX, CX, DI
;------------------------------------------------

strlen	proc

	mov al, 24h
	mov cx, 00h		; cx - length of the string	

@@next_strlen:
    cmp [di], al
    je @@stop_strlen
    
    inc cl
    inc di
    jmp @@next_strlen
	
@@stop_strlen:
    ret

strlen 	endp

;------------------------------------------------
; Displays a frame with text on the screen
;
; Entry:	DI - addr the msg
; Exit:		none
; Destr:	AX, CX, DI, SI
;------------------------------------------------

DrawFrameAndMsg	proc

	push di

	call ClearScreen

	call strlen
	mov ax, cx
	mov bx, 2d
	call SetFrameSize
	call DrawFrame

	pop si
	call PrintMsg

	ret

DrawFrameAndMsg	endp

;------------------------------------------------
; Entered password
;
; Entry:	DX - addr the buffer for a password
; Exit:		none
; Destr:	AX, BX, DX, SI, DI
;------------------------------------------------

EnterPassword	proc

	mov ah, 0ah
	int 21h

	mov si, dx
	inc si
	mov al, 6d
	cmp ds:[si], al
	je @@return

	mov di, offset ERRRO_MSG
	call DrawFrameAndMsg
	jmp return

@@return:
	add si, 7d
	mov al, '$'
	mov ds:[si], al

	ret

EnterPassword	endp

;------------------------------------------------
; The function compares the first num characters
; of string1 with the first num characters of string2 (the strings must
; end with the character $)
;
; Entry:	- SI - addr of str1
;           - DI - addr of str2
;           - AX - number of characters
; Note:	    $ - 24h (ASCII code)
; Exit:		- a zero value indicates that the contents of
;             both memory blocks are equal
;           - CX - a value 1 indicates
;             that string1 is greater than string2,
;             a 2 indicates the opposite
; Destr:	AX, BX, CX, DX, DI, SI, SP
;------------------------------------------------

strncmp	proc
	
    xor bh, bh
    xor cx, cx
	xor dx, dx
		
@@next_ncmp: 
    mov bl, dl
    sub si, bx
    mov bl, dh
    sub di, bx
    mov dx, 0d
	mov bl, 24h
	cmp cl, al
	je @@cmp_eq
        
    add si, cx
    add dl, cl
    cmp [si], bl
    je @@cmp_exp
            
    add di, cx
    add dh, cl
    cmp [di], bl
    jne @@cmp_ncmp
        
    mov cl, 31h
    jmp @@stop_ncmp
                
@@cmp_ncmp:
    inc cl
    mov bl, [di]
    cmp [si], bl
    je @@next_ncmp
        
    dec cl
    cmp [si], bl
    jl @@cmp_less
        
    mov cl, 31h
    jmp @@stop_ncmp

@@cmp_less:
    mov cl, 32h
	jmp @@stop_ncmp 

@@cmp_eq:
	mov cl, 30h
	jmp @@stop_ncmp
						
@@cmp_exp:
	mov bl, [di]
	cmp [si], bl
	je @@cmp_eq
        
    mov cl, 32h
    jmp @@stop_ncmp 

@@stop_ncmp:
	ret

strncmp	endp

.code
org 100h

.getch	macro
	nop
	xor ah, ah
	int 16h
	nop
	endm

Start:
	
	mov di, offset WELCOME_MSG
	call DrawFrameAndMsg

	mov dx, offset ENTERED_PASSWORD
	call EnterPassword

return:
	.getch
	call ClearScreen
    mov ax, 4c00h
    int 21h        
        
end Start
