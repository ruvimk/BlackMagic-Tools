mkdir TemporaryBuildFiles
nasm -fobj ..\..\Sources\BlackMagic-Interface.asm -o .\BlackMagic-Interface.obj
dmc ..\..\Sources\thread-search -i ..\..\Headers -c
dmc Video-Preview-Probe thread-search.obj BlackMagic-Interface.obj ole32.lib oleaut32.lib -o Video-Preview-Probe.exe -i ..\..\Headers
@echo off
move *.map TemporaryBuildFiles
move *.obj TemporaryBuildFiles