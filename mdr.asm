; org 07c00h
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

mov bp, message ; ES:BP串地址
mov ax, 1301h ;功能类型
mov bx, 000ch ;页号、属性
mov cx, 10 ;串长度
int 10h ;中断
jmp $ ; 死循环
message db "Hello MBR!"
times 510 - ($ - $$) db 0
db 0x55,0xaa