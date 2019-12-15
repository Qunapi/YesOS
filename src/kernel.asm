
format binary as 'img'
use16
org  1200h

FAT_DATA_SEGMENT = 0x7E0
KERNEL_SEGMENT = 0x0900

include "macros.asm"



main:

   mov ax, FAT_DATA_SEGMENT;0
   mov ds, ax
   mov es, ax
   mWriteString msg

   mov al, 20h
   mov dx, Int20h
   int 42h

;===================================================================================
;                              DISPLAY FILES NAMES
;===================================================================================

start:
     jmp viewStart


bootFailure:
     call   Reboot
  
include "functions.asm"

Int20h:

   mov ax, FAT_DATA_SEGMENT
   mov ds, ax
   mov es, ax

   xor ax, ax
   mov ss, ax

   mov sp, 0x7bfe;c00;bfe

   mov    ah, 0
   mov    al, 0x03;
   int    10h

   popf

   jmp start



msg:          db "2nd stage bootloader...",13,10,0
rebootmsg:    db "Press any key to reboot.",13,10,0
diskerror:    db "Disk error. ",0
;filename:   db "RACE13H COM"



iBootDrive:  db  0             ; holds drive that the boot sector came from
iTrackSect:  dw  18            ; Sectors per track
iHeadCnt:    dw  2             ; number of read-write heads

include "view.asm"
