

 WriteString:
 WriteSymbol:
  lodsb
  or     al, al
  jz     WriteString_done
  
  mov    ah, 0xe
  mov    bx, 9
  int    0x10
  
  jmp    WriteSymbol
 
 WriteString_done:
ret


 Reboot:
  xor    ax, ax
  int    0x16
  db  0xEA
  dw  0x0000
  dw  0xFFFF

ReadSector:
  xor     cx, cx                      ; Try count = 0

 readsect:
  push    ax
  push    cx
  push    bx

   ;Sector   = (LBA mod SectorsPerTrack) + 1
   ;Cylinder = (LBA / SectorsPerTrack) / NumHeads
   ;Head     = (LBA / SectorsPerTrack) mod NumHeads

  mov     bx, [iTrackSect]
  xor     dx, dx
  div     bx


  inc     dx
  mov     cl, dl
  
  mov     bx, [iHeadCnt]
  xor     dx, dx
  div     bx
  mov     ch, al
  xchg    dl, dh

  mov     ax, 0x0201
  mov     dl, [iBootDrive]
  pop     bx

  ;xchg bx, bx
  int     0x13

  jc      readfail
  

  pop     cx
  pop     ax

  ret


 readfail:

  pop     cx
  inc     cx                 ; Next try
  cmp     cx, 4              ; Max 4 times
  je      bootFailure

  xor     ax, ax
  int     0x13

  pop     ax
  jmp     readsect
