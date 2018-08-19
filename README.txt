Welcome! 

I am Ruvim Kondratyev, and this is some code I wrote for accessing the BlackMagic API from 
the programming languages C and Assembly. I wrote this because my computer didn't have 
enough space and I didn't have enough time to install Visual Studio on my computer to do 
BlackMagic API the actual IDL way. I just wanted a quick fix, so I started by writing the 
assembly files to do the C++ COM stuff, and then added C code to my projects. 

The prerequisites for this is to install NASM and DMC. 


The Netwide Assembler (NASM) may be found here: 
http://www.nasm.us/

Please add the path to nasm/bin to your Windows PATH environment variable before running the build.bat 
files provided with this code. 


The Digital Mars C compiler (DMC) may be found here: 
http://www.digitalmars.com/download/freecompiler.html

Use the "Digital Mars C/C++ Compiler" link. The STLport is *NOT* required for this code. It is all 
in C, no C++ code what-so-ever. If you wish to use C++, use the BlackMagic IDL with Visual Studio. 

As with NASM, add the Digital Mars "bin" folder path to your PATH environment variable before proceeding. 


The folder structure is as usual: 
Headers		-> C header files (.h) to #include<> in your programs. 
Sources		-> C source files (.c), and assembly source files (.asm), to 
			build before you may build your own program. 
			The provided build.bat scripts show how to build and use these. 
Samples		-> Sample programs. 


The build.bat procedure goes as: 
- Create a folder, "TemporaryBuildFiles" 
- Assemble BlackMagic-Interface.asm into an OBJ. 
- Compile thread-search.c into an OBJ. 
- Compile the sample program, incorporating code from the above two OBJs. 
- Move the temporary *.map and *.obj files into the temporary folder. 


The sample programs are these: 
- ASM-VideoKeyer		-> Shows how to use assembly language to access the 
					BlackMagic C++ COM API. This one does not 
					use the BlackMagic-Interface OBJ because 
					it has a lot of calls to the BlackMagic 
					API, some of which I haven't actually 
					implemented in BlackMagic-Interface.ASM; 
					I just left it like that. 
- C-PreviewHotkeys		-> A program in C that starts ATEM Software Control when you 
					start it. It also restarts itself when you try to 
					start it again. When it detects that you are viewing 
					the ATEM remote on your computer, it registers some 
					hotkeys, and when you're looking at something else 
					(not the remote), it unregisters them so that you 
					may use those keys for typing. When you hit the 
					hotkeys from the ATEM window, it switches the 
					switcher preview to the input corresponding to 
					the hotkey you used. 
- C-Read-Preview		-> Simple demonstration in C of how to read which input 
					is on the preview. 

