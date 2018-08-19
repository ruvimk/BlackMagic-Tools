mkdir TemporaryBuildFiles
nasm -fobj VideoKeyer.asm
dmc ..\..\Sources\thread-search -i ..\..\Headers -c
dmc VideoKeyer.obj thread-search.obj ole32.lib oleaut32.lib -o VideoKeyer.exe -i ..\..\Headers
@echo off 
move *.map TemporaryBuildFiles
move *.obj TemporaryBuildFiles