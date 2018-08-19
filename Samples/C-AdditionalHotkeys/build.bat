mkdir TemporaryBuildFiles
nasm -fobj ..\..\Sources\BlackMagic-Interface.asm -o .\BlackMagic-Interface.obj
dmc ..\..\Sources\thread-search -i ..\..\Headers -c
dmc BlackMagic-AdditionalHotkeys thread-search.obj BlackMagic-Interface.obj ole32.lib oleaut32.lib -o BlackMagic-AdditionalHotkeys.exe -i ..\..\Headers
@echo off
move *.map TemporaryBuildFiles
move *.obj TemporaryBuildFiles
to-win BlackMagic-AdditionalHotkeys.exe