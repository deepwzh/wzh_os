nasm -I include/ mdr.asm -o boot.bin 
nasm -I include/ loader.asm -o loader.bin

dd if=boot.bin of=hd.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=hd.img bs=512 count=1 seek=2 conv=notrunc

..\qemu\qemu-system-i386.exe -hda hd.img
