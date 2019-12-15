

use16
org  0x7C00

LOAD_SEGMENT = 0x1010
FAT_SEGMENT  = 0x0EE0
FAT_DATA_SEGMENT = 0x07E0
KERNEL_SEGMENT = 0x0900



main:
    jmp start

bootsector:
 iOEM:        db "YesOS   "
 iSectSize:   dw  0x200
 iClustSize:  db  1
 iResSect:    dw  1
 iFatCnt:     db  2
 iRootSize:   dw  224
 iTotalSect:  dw  2880
 iMedia:      db  0xF0
 iFatSize:    dw  9
 iTrackSect:  dw  18
 iHeadCnt:    dw  2
 iHiddenSect: dd  0
 iSect32:     dd  0
 iBootDrive:  db  0
 iReserved:   db  0
 iBootSign:   db  0x29
 iVolID:      db "seri"
 acVolLabel:  db "MYVOLUME   "
 acFSType:    db "FAT12   "

include "macros.asm"

start:
;===================================================================================
;                              INIT SEGMENTS
;===================================================================================
   cli
   mov     [iBootDrive], dl
   mov     sp, 0x7c00
   sti

   mov ax, 42h
   mov dx, SetIntHandler
   pushf
   call    0x0000:SetIntHandler

   mov ax, 40h
   mov dx, loadFileByName
   int 42h


   mov     ax, FAT_DATA_SEGMENT
   mov     es, ax

   mWriteString loadmsg


;===================================================================================
;                              LOAD FILES NAMES
;===================================================================================

   mov     ax, 32
   xor     dx, dx
   mul     word [iRootSize]
   div     word [iSectSize]
   mov     cx, ax

   mov     [root_sectors], cx

   xor   ax, ax
   mov   al, byte [iFatCnt]
   mov   bx, word [iFatSize]
   mul   bx
   add   ax, word  [iResSect]

   mov   [root_start], ax

   xor    bx, bx
   call   ReadSector

;===================================================================================
;                              LOAD KERNEL
;===================================================================================
    mov    [loadSegment], word KERNEL_SEGMENT
    mov    ax, kernelName


    int    40h
    mov    [loadSegment], word LOAD_SEGMENT

    jmp    FAT_DATA_SEGMENT:1200;KERNEL_SEGMENT:0
;===================================================================================
;                              LOAD FILE NAME   AX - LOAD FILE NAME
;===================================================================================
;===================================================================================
;                              SET FILE START
;===================================================================================

loadFileByName:

    push es

    mov    si, ax
    mov    ax, fileName
    mov    di, ax

    mov    cx, 11
    xor    ax, ax
    mov    es, ax


    rep    movsb
    pop es

    push   es
    push   ds


    xor    ax, ax
    mov    ds, ax

    xor bx, bx
    jmp check_entry

 read_next_sector:
    push   cx
    push   ax
    xor    bx, bx
    call   ReadSector

  check_entry:

    mov    cx, 11
    mov    di, bx
    lea    si, [fileName]

    repz   cmpsb

    je     found_file
    add    bx, 32
    cmp    bx, word [iSectSize]
    jne    check_entry
    
    pop    ax
    inc    ax
    pop    cx

    loopnz read_next_sector

    jmp    bootFailure

  found_file:
    mov    ax, [es:bx+0x1a]
    mov    [file_strt], ax

;===================================================================================
;                              READ & LOAD FAT TABLE
;===================================================================================


    mov   ax, FAT_SEGMENT
    mov   es, ax
    mov   ax, word [iResSect]
    mov   cx, word [iFatSize]
    xor   bx, bx
  read_next_fat_sector:

    call  ReadSector

    inc   ax
    add   bx, word [iSectSize]
    loopnz read_next_fat_sector

;===================================================================================
;                              READ FILE
;===================================================================================

    mov     ax, [loadSegment]
    mov     es, ax

    xor     bx, bx
    mov     cx, [file_strt]
    
  read_file_next_sector:

    mov     ax, cx
    add     ax, [root_start]
    add     ax, [root_sectors]
    sub     ax, 2

    push    cx

    call    ReadSector
    pop     cx
    add     bx, [iSectSize]
    

    push    ds
    mov     dx, FAT_SEGMENT
    mov     ds, dx

    mov     si, cx
    mov     dx, cx
    shr     dx, 1
    add     si, dx

    mov     dx, [ds:si]
    test    dx, 1
    jz      read_next_file_even
    and     dx, 0x0fff
    jmp     read_next_file_cluster_done

read_next_file_even:    
    shr     dx, 4

read_next_file_cluster_done:

    pop     ds
    mov     cx, dx
    cmp     cx, 0xff8
    jl      read_file_next_sector

    pop   ds
    pop   es
iret
;===================================================================================
;                              GO KERNEL
;===================================================================================

SetIntHandler:
    push es
    xor bx, bx
    mov es, bx
    xor ah, ah
    shl ax, 2
    mov di, ax
    mov [es:di], dx
    mov [es:di+2], ds
    pop es
iret

bootFailure:
    mWriteString diskerror
    call   Reboot
    jmp $


include "functions.asm"


kernelName:      db "KERNEL  IMG"
diskerror:      db "Disk error",0
loadmsg:        db "Loading OS",0;
fileName:       db 11 dup ?
loadSegment:    dw ?

root_start:   db 0,0
root_sectors:   db 0,0
file_strt:   db 0,0

times 510-($-$$) db 0
BootMagic  dw 0xAA55
