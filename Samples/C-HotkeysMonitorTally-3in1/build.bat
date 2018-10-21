mkdir TemporaryBuildFiles
nasm -fobj ..\..\Sources\BlackMagic-Interface.asm -o .\BlackMagic-Interface.obj
dmc ..\..\Sources\thread-search -i ..\..\Headers -c
dmc -D gdi32.lib wsock32.lib BlackMagic-HotkeysMonitorTallyServer thread-search.obj BlackMagic-Interface.obj ole32.lib oleaut32.lib -o BlackMagic-HotkeysMonitorTallyServer.exe -i ..\..\Headers
@echo off
move *.map TemporaryBuildFiles
move *.obj TemporaryBuildFiles
REM to-win BlackMagic-HotkeysMonitorTallyServer.exe