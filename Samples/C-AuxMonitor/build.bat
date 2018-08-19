mkdir TemporaryBuildFiles
nasm -fobj ..\..\Sources\BlackMagic-Interface.asm -o .\BlackMagic-Interface.obj
dmc ..\..\Sources\thread-search -i ..\..\Headers -c
dmc gdi32.lib BlackMagic-AuxMonitor thread-search.obj BlackMagic-Interface.obj ole32.lib oleaut32.lib -o BlackMagic-AuxMonitor.exe -i ..\..\Headers
@echo off
move *.map TemporaryBuildFiles
move *.obj TemporaryBuildFiles
to-win BlackMagic-AuxMonitor.exe