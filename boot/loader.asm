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
times 59 dq 0
times 5 db 0
;+512字节0xb00 + 0x3 + 0x200 - 0x3 = 0xb00
total_mem_bytes dd 0 ; 内存大小存于这个地方
SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

gdt_ptr dw GDT_LIMIT
            dd GDT_BASE;0xb06
;0xb0a

ards_buf times 244 db 0
ards_nr dw 0
loader_start:

mov ebx, 0
mov di, ards_buf
mov ecx, 20
mov edx, 0x534d4150
.gogogo:
mov eax, 0x0000e820
int 0x15
add di, cx
inc word [ards_nr]
cmp ebx, 0
jnz .gogogo



;计算内存大小

xor edx, edx
mov cx, [ards_nr]
mov ebx, ards_buf
.q:
mov eax, [ebx + 0]
add eax, [ebx + 8]
add ebx, 20
cmp edx, eax
jge .u
mov edx, eax
.u:
loop .q
mov [total_mem_bytes],edx ; 将内存大小保存

;实模式下打印字符串
mov ax, 0xb800
mov gs, ax ;0x00000c50
; mov ax, 0x900
; mov ds, 
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
call setup_page

sgdt [gdt_ptr]

mov ebx, [gdt_ptr + 2]
or dword [ebx + 0x18 + 4], 0xc0000000
add dword [gdt_ptr + 2], 0xc0000000
add esp, 0xc0000000

; cr3写入页目录地址
mov eax, PAGE_DIR_TABLE_POS
mov cr3, eax
; cr0 PG=1
mov eax, cr0
or eax,0x80000000 ;
mov cr0, eax
lgdt [gdt_ptr] ;?

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
message: db "Hello Loader!"
setup_page:
mov ecx, 4096 ; cx->ecx
mov esi, 0
.clear_page_dir:
mov byte [PAGE_DIR_TABLE_POS + esi], 0x00
inc esi
loop .clear_page_dir

.create_pde:
mov eax, PAGE_DIR_TABLE_POS
add eax, 0x1000
mov ebx, eax
or eax, PG_US_U | PG_RW_W | PG_P
mov [PAGE_DIR_TABLE_POS + 0x00], eax
mov [PAGE_DIR_TABLE_POS + 0xc00], eax
sub eax, 0x1000
mov [PAGE_DIR_TABLE_POS + 0xffc], eax

mov ecx, 256
mov edi, 0
mov eax, PG_US_U | PG_RW_W | PG_P
.create_pte:
mov [ebx + edi*4], eax
add eax, 0x1000
inc edi
loop .create_pte

mov eax, PAGE_DIR_TABLE_POS
add eax, 0x2000
or eax, PG_US_U | PG_RW_W | PG_P
mov ecx,254
mov ebx, 0x301 ; 0x300项对应0xc0000000, 0x301对应0xc0400000，即0xc0400000-0xffc00000的映射
.create_kernel_pde:
mov [PAGE_DIR_TABLE_POS + ebx*4], eax
inc ebx
add eax, 0x1000
loop .create_kernel_pde
ret
