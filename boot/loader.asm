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
loader_start: ;0xc00

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

;实模式下打印字符串0xc52
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



; 打开A20 ;0xc79
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
;0xc96
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


mov eax, KERNEL_START_SECTOR
mov ebx, KERNEL_BIN_BASE_ADDR
mov ecx, 200
call rd_disk_m_32
call kernel_init
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
mov esp, 0xc009f000
jmp KERNEL_ENTRY_POINT ;内核入口
message: db "Hello Loader!"
kernel_init:
xor eax, eax ; 
xor ebx, ebx ;ebx记录程序头表的地址
xor ecx, ecx ;ecx 记录program header数量 
xor edx, edx ; edx 记录program header 尺寸

mov ebx, [KERNEL_BIN_BASE_ADDR + 28]
mov cx, [KERNEL_BIN_BASE_ADDR + 44]
mov dx, [KERNEL_BIN_BASE_ADDR + 42]

add ebx, KERNEL_BIN_BASE_ADDR

.each_segment:
cmp byte [ebx + 0], PT_NULL
je .PTNULL
push dword [ebx + 16] ;size
mov eax, [ebx + 4]
add eax, KERNEL_BIN_BASE_ADDR
push eax;src
push dword [ebx + 8];dst
call mem_cpy
add esp, 12 ;清理参数
.PTNULL:
add ebx, edx
loop .each_segment
ret
;内存复制(dst32,src32,size32)
mem_cpy:
cld ; 地址方向设置默认（向上）
push ebp
mov ebp, esp
push ecx
mov edi, [bp + 8] ;dst
mov esi, [bp + 12] ;src
mov ecx, [bp + 16]; size
rep movsb
pop ecx
pop ebp
ret
;配置页表
setup_page:
;清空页表所在的内存
mov ecx, 4096 ; cx->ecx
mov esi, 0
.clear_page_dir:
mov byte [PAGE_DIR_TABLE_POS + esi], 0x00
inc esi
loop .clear_page_dir

;创建页目录
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
;创建内核页表
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
;创建内核页目录
.create_kernel_pde:
mov [PAGE_DIR_TABLE_POS + ebx*4], eax
inc ebx
add eax, 0x1000
loop .create_kernel_pde
ret
;实模式下读取硬盘n个扇区
;eax LBA地址
;bx 要写的内存地址
;cx要读的扇区数
rd_disk_m_32:
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
  mov eax, 128
  mul ecx
  mov ecx, eax
  mov dx, 0x1f0
  .go_on_read:
      in eax,dx
      mov [ebx], eax
      add ebx, 4
      loop .go_on_read
  ret