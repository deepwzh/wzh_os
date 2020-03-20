@echo off
cd boot
nasm -I include/ mdr.asm -o ../productions/boot.bin 
nasm -I include/ loader.asm -o ../productions/loader.bin
cd ..
cd productions
dd if=boot.bin of=hd0.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=hd0.img bs=512 count=10 seek=2 conv=notrunc
if "%1" == "b" (
  bochs -f bochsrc 
) ^
else if "%1" == "d" (
  bochsdbg -f bochsrc
)^
else (
  qemu-system-x86_64.exe  -drive file=hd0.img,media=disk,index=0,format=raw
) 
cd ..