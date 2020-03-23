nasm -I boot/include/ boot/mdr.asm -o productions/boot.bin 
nasm -I boot/include/ boot/loader.asm -o productions/loader.bin
nasm -f elf32 -o lib/kernel/print.o lib/kernel/print.asm
gcc -m32 -I lib/kernel/ -c -o kernel/main.o kernel/main.c
ld -m elf_i386 -Ttext 0xc0001500 -e main -o productions/kernel.bin kernel/main.o lib/kernel/print.o # gcc-multilib
cd productions
dd if=boot.bin of=hd0.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=hd0.img bs=512 count=4 seek=2 conv=notrunc
dd if=kernel.bin of=hd0.img bs=512 count=200 seek=10 conv=notrunc
if [ "$1" == "b" ]
then
  bochs.exe -f bochsrc 
elif [ "$1" == "d" ] 
then
  bochsdbg.exe -f bochsrc
else 
  qemu-system-x86_64.exe  -drive file=hd0.img,media=disk,index=0,format=raw

fi
cd ..