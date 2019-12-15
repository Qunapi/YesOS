include "proc16.inc"

use16

BG_BLUE = 0x10
BG_RED = 0x40
BG_WHITE = 0xf0
BG_GREEN = 0xa0



viewStart:
  call clearScreen


   ;disable blinking
   ;==================
   mov    ax, 0x1003
   int    10h

   mov ah, 0x01
   mov cx, 2607h
   int 10h
   ;==================



  call displayMenu

  jmp $


displayMenu:


  ; Draw main rec
  stdcall drawRect, 10, 3, 64, 20, BG_BLUE
  stdcall drawRect, 8, 2, 64, 20, BG_WHITE
  call drawlogo

  mov ah, 0bh
  mov bl, 9
  INT 10h

  cmp byte [currentMenu], 1
  jne @f
  call displayMainMenu
  jmp .end
@@:
  cmp byte [currentMenu], 2
  jne @f
  call displayFileManager
.end:
  ;mov byte [currentMenu], 1
  jmp displayMenu


@@:

ret

displayMainMenu:
  ;powerBtn
  stdcall drawRect, 2, 22, 4, 2, BG_RED
  call drawMenuOptions

  cmp byte [selectedOption], 2
  jne @f
  stdcall drawRect, 2, 22, 4, 2, BG_GREEN

@@:
.wrongKey:
  mov     ah, 0x0
  int     0x16

  cmp     ah, 72  ;^

  je      .up
  cmp     ah, 80  ;down

  je      .down
  cmp     ah, 28  ;enter
  je      .enterKey
  jmp     .wrongKey

.keyPressed:
 xchg bx, bx
 cmp byte[selectedOption], 0
 jne  @f
 mov byte[selectedOption], 1
@@:
 cmp byte[selectedOption], 3
 jne @f
 mov byte[selectedOption], 1
@@:

ret

.up:
   dec     byte [selectedOption]
   jmp .keyPressed

.down:
   inc     byte [selectedOption]
   jmp .keyPressed

.enterKey:
   cmp byte [selectedOption],1
   jne @f
   mov byte [currentMenu], 2
@@:
   cmp byte [selectedOption], 2
   jne @f
   ;power off
   mov ax, 5307h
   mov cx, 3
   mov bx, 1
   int 15h

@@:
   jmp .keyPressed

;======================== FILE MANAGER =================================================
displayFileManager:

FILENAME_X = 30
FILENAME_Y = 14


  mov    ax, 0;FAT_DATA_SEGMENT
  mov    si, ax
  mov    byte [fileNumber], 0
  mov    dx, FILENAME_Y
DisplayFileName:
  inc dx
  stdcall moveCursor, FILENAME_X, dx
  inc     byte [fileNumber]

  mov     al, [selectedFile]
  mov     al, [fileNumber]
  cmp     al, [selectedFile]
  jne     @f
  call    drawCursor

@@:
  mov     cx, 11

  mov     ah, 0xe

WriteNameSymbol:
  lodsb
  mov     bx, 9
  int     0x10
  loop    WriteNameSymbol
  add     si, 32 - 11

  cmp     byte [si], 0

  jnz     DisplayFileName


wrongKey:
  mov     ah, 0x0
  int     0x16

  cmp     ah, 1  ;esc
  je      .esc
  cmp     ah, 72  ;^
  je      .up
  cmp     ah, 80  ;down
  je      .down
  cmp     ah, 28  ;enter
  je      .enterKey
  jmp     displayMenu

  ret

.esc:
  mov byte [currentMenu], 1
  jmp displayMenu

.up:
  cmp     byte [selectedFile], 1
  je      @f
  dec     byte [selectedFile]
@@:
  jmp     displayMenu

.down:
  mov     al, [selectedFile]
  cmp     al, [fileNumber]
  je      @f
  inc     byte [selectedFile]
@@:
  jmp     displayMenu
;============================= ENTER KEY ============================
.enterKey:
  call clearScreen
  mov   ax, 0
  xor cx, cx
  mov   cl, [selectedFile]
  dec   cx

@@:
  add   ax, 32
  loop  @b

  xor   bx, bx

  int   40h

   mov ss, ax
   mov sp, 0x7c00

    pushf

    mov ax, 1000h    ; Set up registers
    mov ds, ax
    mov es, ax

    mov ss, ax

    mov sp, 0xFFFE


    push 0               ; 0x0000 for ret
    mov ax, 0x20CD       ; call int 20h
    mov [es:0], ax  ; ret in app will jump here \

    jmp 1000h:100h

;========================================================================================


drawMenuOptions:
  MENU_X = 34
  MENU_Y = 16
  mov ax, menuOptions;
  mov si, ax
  mov ah, 0xE
  stdcall moveCursor, MENU_X, MENU_Y

  cmp     byte [selectedOption], 1
  jne     @f
  call    drawCursor
@@:
.nextChar:
  lodsb
  int 10h
  cmp al, 0
  jne .nextChar
ret

drawlogo:

  LOGO_X = 12
  LOGO_START_Y = 4
  push cx;
  mov cx, 1
  mov bx, LOGO_START_Y
  stdcall moveCursor, LOGO_X, bx

  mov ah,0xe
  mov si, OSLogo
.nextChar:
  lodsb
  int 10h
  cmp al, 13
  jne @f
  inc bx
  stdcall moveCursor, LOGO_X, bx
@@:
  cmp al, 0
  jne .nextChar

  pop cx
ret
     ;DH    row (0-based)
     ;DL    column (0-based)
proc moveCursor uses ax dx,\
              x, y
  mov ah, 2h
  mov dh, byte [y]
  mov dl, byte [x]
  int 10h
  ret
endp


proc drawRect uses es ax cx dx,\
               x, y, width, height, color
    mov dx, [color]
    mov ax, [y]
    mov bx, 10
    mul bl
    add ax, 0xb800
    push es
    mov es, ax
    mov cx, [height]
.line:
    push cx
    mov cx, [width]
    mov bx, [x]
    shl bx, 1
    inc bx
.element:
    mov [es:bx], dx
    add bx, 2
    loop .element
    pop cx
    mov ax, es
    add ax, 10
    mov es, ax
    loop .line
    pop es
    ret
endp

drawCursor:
   mov ah, 0xe
   mov    al, '>'
   int    10h
   mov    al, ' '
   int    10h
   ret

clearScreen:
   mov    ah, 0
   mov    al, 0x03
   int    10h
   ret

selectedOption: db 1
currentMenu: db 1
selectedFile: db 1
fileNumber:   db 1
menuOptions: db 'File system',13,10,0

     OSLogo: db " Y88b   d88P                    .d88888b.   .d8888b.",10,13,\
                "  Y88b d88P                    d88P' 'Y88b d88P  Y88b",10,13,\
                "   Y88o88P                     888     888 Y88b." ,10,13,\
                "    Y888P   .d88b.  .d8888b    888     888  'Y888b.",10,13,\
                "     888   d8P  Y8b 88K        888     888     'Y88b.",10,13 ,\
                "     888   88888888 'Y8888b.   888     888       '888",10,13 ,\
                "     888   Y8b.          X88   Y88b. .d88P Y88b  d88P" ,10,13 ,\
                "     888    'Y8888   88888P'    'Y88888P'   'Y8888P'"    ,10,13,0

