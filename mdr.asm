; org 07c00h
%include "boot.inc"
; %include "function.inc"
SECTION MBR vstart=0x7c00
mov ax, cs 
mov es, ax
;;;;; 清屏
mov ax, 0600h
mov bx, 0700h
mov cx, 0h ;左上角
mov dx, 184fh ;右下角
int 10h
;; 置光标位置
mov ah, 2
; mov bh, 0
mov bh, 00h
mov dx, 0000h
int 10h





; int 1301h
;;;;; 输出字符串 
;;;;;;;;;;;;;;;;;;;;打印字符串BIOS中断实现
; mov bp, message ; ES:BP串地址
; mov ax, 1301h ;功能类型
; mov bx, 000ch ;页号、属性
; mov cx, 10 ;串长度
; int 10h ;中断
;;打印字符串
;;;;;;;;;;;;;;;;;;;;打印字符串直接读写端口
mov ax, 0xb800
mov gs, ax
; mov byte [gs:0x0], 'a'
; mov byte [gs:0x1], 0xA4
mov bp, message
mov bx, 0
mov di, 0
mov cx,10
; call print_str
print:
mov al, [bp+di]
mov byte [gs:bx], al
add bx, 1
mov byte [gs:bx], 0xA4
add bx, 1
add di, 1
cmp cx, di
jnz print
mov eax, LOADER_START_SECTOR
mov bx, LOADER_BASE_ADDR
mov cx, 10
call rd_disk_m_16
jmp LOADER_BASE_ADDR
;实模式下读取硬盘n个扇区
;eax LBA地址
;bx 要写的内存地址
;cx要读的扇区数
rd_disk_m_16:
  mov esi, eax
  mov dx, 0x1f2
  mov al, cl
  out dx, al
  mov eax, esi

  mov dx, 0x1f3
  out dx, al
  shr eax, 8
  mov dx, 0x1f4
  out dx, al
  shr eax, 8
  mov dx, 0x1f5
  out dx, al

  shr eax, 8
  and al, 0x0f
  or al, 0xe0
  mov dx, 0x1f6
  out dx, al

  mov dx, 0x1f7
  mov al, 0x20
  out dx, al

  .not_ready:
  in al,dx
  and al, 0x88
  cmp al, 0x08
  jnz .not_ready

  ;数据准备好了
  mov ax, 256
  mul cx
  mov cx, ax
  mov dx, 0x1f0
  .go_on_read:
      in ax,dx
      mov [bx], ax
      add bx, 2
      loop .go_on_read
  ret

; 死循环
message db "Hello MBR!"

times 510 - ($ - $$) db 0
db 0x55,0xaa