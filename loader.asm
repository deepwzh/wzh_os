%include "boot.inc"
; org 
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

jmp loader_start
GDT_BASE: dd 0x00000000
          dd 0x00000000
CODE_DESC: dd 0x0000FFFF
           dd DESC_CODE_HIGH4
DATA_STACK_DESC: dd 0x0000FFFF
                 dd DESC_DATA_HIGH4
VIDEO_DESC: dd 0x80000007
            dd DESC_VIDEO_HIGH4
GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1
; times 60 dq 0
SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

gdt_ptr dw GDT_LIMIT
            dd GDT_BASE
message: db "Hello Loader!"

loader_start:

;实模式下打印字符串
mov ax, 0xb800
mov gs, ax
; mov byte [gs:0x00], '2'
; mov byte [gs:0x01], 0xA0
mov bp, message
mov bx, 80*2 ; 每行80个字符，跳到第二行
mov di,0
mov cx,13
print:
mov al, [bp+di]
mov byte [gs:bx], al
add bx, 1
mov byte [gs:bx], 0xA4
add bx, 1
add di, 1
cmp cx, di
jnz print



; 打开A20
in al, 0x92
or al, 0000_0010b
out 0x92, al

; 加载GDT
lgdt [gdt_ptr]

mov eax, cr0
or eax, 0x00000001 
mov cr0, eax
; 

jmp dword SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
mov ax, SELECTOR_DATA
mov ds, ax
mov es, ax
mov ss, ax
mov esp, LOADER_STACK_TOP ;??
mov ax, SELECTOR_VIDEO
mov gs, ax

mov byte [gs:320], 'P'
mov byte [gs:322], 'r'
mov byte [gs:324], 'o'
mov byte [gs:326], 't'
mov byte [gs:328], 'e'
mov byte [gs:330], 'c'
mov byte [gs:332], 't'
mov byte [gs:334], ' '
mov byte [gs:336], 'm'
mov byte [gs:338], 'o'
mov byte [gs:340], 'd'
mov byte [gs:342], 'e'
jmp $