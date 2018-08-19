use32 

%define INCLUDE_BLACKMAGIC_COM 1 

%define SEND_KEYBOARD_CONTROLS 0 

%define DM_C_COMPATIBLE 1 

%define DEBUG 1 

%if DM_C_COMPATIBLE 
	extern __imp__ExitProcess@4 
	extern __imp__OpenFile@12 
	extern __imp__WriteFile@20 
	extern __imp__ReadFile@20 
	extern __imp__CloseHandle@4 
	extern __imp__GetTickCount@0 
	extern __imp__Sleep@4 
	extern __imp__CreateThread@24 
	extern __imp__CreateFileA@28 
	
	extern __imp__RegisterHotKey@16 
	extern __imp__UnregisterHotKey@8 
	extern __imp__GetMessageA@16 
	extern __imp__MapVirtualKeyA@8 
	
	%if SEND_KEYBOARD_CONTROLS > 0 
		extern __imp__SendInput@12 
	%endif 
	extern __imp__GetMessageExtraInfo@0 
%else 
	extern ExitProcess 
	extern OpenFile 
	extern WriteFile 
	extern ReadFile 
	extern CloseHandle 
	extern GetTickCount 
	extern Sleep 
	extern CreateThread 
	extern CreateFileA 
	
	extern RegisterHotKey 
	extern UnregisterHotKey 
	extern GetMessageA 
	extern MapVirtualKeyA 
	
	%if SEND_KEYBOARD_CONTROLS > 0 
		extern SendInput 
	%endif 
	extern GetMessageExtraInfo 
%endif 


%if DM_C_COMPATIBLE 
	
%else 
	import ExitProcess kernel32.dll 
	import OpenFile kernel32.dll 
	import WriteFile kernel32.dll 
	import ReadFile kernel32.dll 
	import CloseHandle kernel32.dll 
	import GetTickCount kernel32.dll 
	import Sleep kernel32.dll 
	import CreateThread kernel32.dll 
	import CreateFile kernel32.dll 
	
	import RegisterHotKey user32.dll 
	import UnregisterHotKey user32.dll 
	import GetMessageA user32.dll 
	
	%if SEND_KEYBOARD_CONTROLS > 0 
		import SendInput user32.dll 
		import MapVirtualKeyA user32.dll 
		import GetMessageExtraInfo user32.dll 
		
		%define MapVirtualKey MapVirtualKeyA 
	%endif 
	
	%define GetMessage GetMessageA 
	%define CreateFile CreateFileA 
%endif 


extern _killProcessByName@8 

global _start 



%macro save 0 
	push ebx 
	push ecx 
	push edx 
%endmacro 
%macro restore 0 
	pop edx 
	pop ecx 
	pop ebx 
%endmacro 

%macro delay 1 
	push dword %1 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__Sleep@4] 
	%else 
		call [Sleep] 
	%endif 
%endmacro 

%macro imhere 0 
	%ifdef DEBUG 
		%if DEBUG > 0 
			pushfd 
			pushad 
			call lock_log 
			push dword __LINE__ 
			call stillhere 
			call unlock_log 
			popad 
			popfd 
		%endif 
	%endif 
%endmacro 
%macro debug_hex 1 
	%ifdef DEBUG 
		%if DEBUG > 0 
			pushfd 
			pushad 
			push dword %1 
			call lock_log 
			push dword __LINE__ 
			call print_debug_int_prefix 
			;push dword %1 
			call log_hex 
			push dword sEndl 
			call log 
			call unlock_log 
			popad 
			popfd 
		%endif 
	%endif 
%endmacro 
%macro debug_dec 1 
	%ifdef DEBUG 
		%if DEBUG > 0 
			pushfd 
			pushad 
			push dword %1 
			call lock_log 
			push dword __LINE__ 
			call print_debug_int_prefix 
			;push dword %1 
			call log_dec 
			push dword sEndl 
			call log 
			call unlock_log 
			popad 
			popfd 
		%endif 
	%endif 
%endmacro 




%if INCLUDE_BLACKMAGIC_COM > 0 
	
	%if DM_C_COMPATIBLE > 0 
		extern __imp__CoInitialize@4 
		extern __imp__CoCreateInstance@20 
		
		extern __imp__SysAllocString@4 
		extern __imp__SysFreeString@4 
	%else 
		extern CoInitialize 
		extern CoCreateInstance 
		
		extern SysAllocString 
		extern SysFreeString 
		
		import CoInitialize ole32.dll 
		import CoCreateInstance ole32.dll 
		
		import SysAllocString OleAut32.dll 
		import SysFreeString OleAut32.dll 
	%endif 
	
%endif 



%define INPUT_KEYBOARD 1 

%define MOD_ALT 		0x0001 
%define MOD_CTRL		0x0002 
%define MOD_CONTROL		MOD_CTRL 
%define MOD_SHIFT		0x0004 
%define MOD_WIN 		0x0008 
%define MOD_NOREPEAT	0x4000 

%define VK_ESCAPE	0x1B 

%define VK_F1		0x70 
%define VK_F2		0x71 
%define VK_F3		0x72 
%define VK_F4		0x73 
%define VK_F5		0x74 
%define VK_F6		0x75 
%define VK_F7		0x76 
%define VK_F8		0x77 
%define VK_F9		0x78 
%define VK_F10		0x79 
%define VK_F11		0x7A 
%define VK_F12		0x7B 

%define WM_HOTKEY				0x0312 
%define WM_CLOSE				0x0010 

%define KEYEVENTF_KEYUP			0x0002 
%define KEYEVENTF_SCANCODE		0x0008 
%define KEYEVENTF_UNICODE		0x0004 



section .text 
lock_log: 
mov al, [bLogInUse] 
test al, al 
jnz lock_log 
mov byte [bLogInUse], 1 
ret 

unlock_log: 
mov byte [bLogInUse], 0 
ret 

section .data 
bLogInUse			dd 0 

myMaskLeft			dq -16.0 
myMaskRight			dq +16.0 

DARK_OVERLAY_CLIP	dq +13.0e-2 
DARK_OVERLAY_GAIN	dq +50.0e-2 

dSmall				dq +0.0000001 
dZero				dq +0.0 

section .text 
..start: 

_start: 
main: 

push dword 0 ;; Not a test. 
push dword mImageName 
call _killProcessByName@8 
mov [mInstanceIsARestartOfTheApp], eax 
test eax, eax 
jz .truncate_log_file 

.open_log_for_appending: 
;; Open a file for appending: 
push dword 0 
push dword 0x80 ;; FILE_ATTRIBUTE_NORMAL 
push dword 4 ;; OPEN_ALWAYS 
push dword 0 
push dword 1 ;; Others can read the file, but not write to it while it's open. 
push dword 4 ;; FILE_APPEND_DATA 
push dword sFilenameLog 
%if DM_C_COMPATIBLE > 0 
	call [__imp__CreateFileA@28] 
%else 
	call [CreateFile] 
%endif 

jmp .done_opening_log_file 

.truncate_log_file: 
;; Open a file: 
push dword 1 | 0x1000 
push dword ofstruct 
push dword sFilenameLog 
%if DM_C_COMPATIBLE > 0 
	call [__imp__OpenFile@12] 
%else 
	call [OpenFile] 
%endif 
.done_opening_log_file: 
mov [hLog], eax 

cmp eax, 0 
jnz .log_open_ok 
mov dword [iExitCode], 1 
jmp .done 
.log_open_ok: 

push dword lStarted 
call log 

;; Initialize the animation started time parameter: 
%if DM_C_COMPATIBLE > 0 
	call [__imp__GetTickCount@0] 
%else 
	call [GetTickCount] 
%endif 
mov [iAnimationStarted], eax 
mov dword [iAnimationDone], 1 

;; Start the thread that will do the animations for us: 
push dword 0 ;; No thread ID needed. 
push dword 0 ;; Flags: 0 -> start the thread immediately. 
push dword 0 ;; No parameter. 
push dword thread_keyer 
push dword 0 ;; Default stack size. 
push dword 0 ;; No security attributes. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__CreateThread@24] 
%else 
	call [CreateThread] 
%endif 
mov [hThread], eax 

;; Do stuff: 
push dword VK_F10 
push dword MOD_CTRL | MOD_ALT | MOD_NOREPEAT 
push dword [uiHotkeyIdE] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 
test eax, eax 
jz .hotkey_already_registred ;; Exit now if cannot register the 'exit' hotkey. 

push dword VK_F9 
push dword MOD_NOREPEAT 
push dword [uiHotkeyId1] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

push dword VK_F9 
push dword MOD_NOREPEAT | MOD_CONTROL 
push dword [uiHotkeyId1_ctrl] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

; push dword VK_F9 
; push dword MOD_SHIFT | MOD_NOREPEAT 
; push dword [uiHotkeyId1b] 
; push dword 0 ;; No window. 
; call [RegisterHotKey] 

; debug_dec eax 

; push dword VK_F9 
; push dword MOD_CTRL | MOD_NOREPEAT 
; push dword [uiHotkeyId1c] 
; push dword 0 ;; No window. 
; call [RegisterHotKey] 

; debug_dec eax 

push dword VK_F10 
push dword MOD_NOREPEAT 
push dword [uiHotkeyId2] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

push dword VK_F10 
push dword MOD_NOREPEAT | MOD_CONTROL 
push dword [uiHotkeyId2_ctrl] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

; push dword VK_F11 
; push dword MOD_NOREPEAT 
; push dword [uiHotkeyId3] 
; push dword 0 ;; No window. 
; %if DM_C_COMPATIBLE > 0 
	; call [__imp__RegisterHotKey@16] 
; %else 
	; call [RegisterHotKey] 
; %endif 

push dword VK_F11 
push dword MOD_NOREPEAT | MOD_CONTROL 
push dword [uiHotkeyId3_ctrl] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

push dword VK_F8 
push dword MOD_NOREPEAT 
push dword [uiHotkeyId5a] 
push dword 0 ;; No window 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

push dword VK_F8 
push dword MOD_NOREPEAT | MOD_CONTROL 
push dword [uiHotkeyId5b] 
push dword 0 ;; No window 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

push dword 'U' 
push dword MOD_CTRL | MOD_ALT | MOD_NOREPEAT 
push dword [uiHotkeyId4a] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

push dword 'I' 
push dword MOD_CTRL | MOD_ALT | MOD_NOREPEAT 
push dword [uiHotkeyId4b] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

push dword 'O' 
push dword MOD_CTRL | MOD_ALT | MOD_NOREPEAT 
push dword [uiHotkeyId4c] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 

debug_dec eax 

push dword 'P' 
push dword MOD_CTRL | MOD_ALT | MOD_NOREPEAT 
push dword [uiHotkeyId4d] 
push dword 0 ;; No window. 
%if DM_C_COMPATIBLE > 0 
	call [__imp__RegisterHotKey@16] 
%else 
	call [RegisterHotKey] 
%endif 


;; Loop while there are messages: 
.message_loop: 
	mov eax, [iAppDone] 
	test eax, eax 
	jnz .done_message_loop 
	
	push dword 0 
	push dword 0 
	push dword 0 
	push dword msg 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__GetMessageA@16] 
	%else 
		call [GetMessage] 
	%endif 
	cmp eax, 0 
	jz .done_message_loop 
	
	mov eax, [msg.message] 
	cmp eax, WM_HOTKEY 
	jz .handle_hotkey 
	
	cmp eax, WM_CLOSE 
	jz .done_message_loop__wm_close 
	
	jmp .message_loop 
	
	.handle_hotkey: 
		push dword lHkReceived 
		call log 
		
		call bm_check 
		
		debug_hex eax 
		
		test eax, eax 
		jnz .message_loop ;; This means we were unable to reconnect to the switcher; just ignore this hotkey in that case, so we jump back to waiting for more messages. 
		
		imhere 
		
		mov eax, [msg.wParam] 
		cmp eax, [uiHotkeyId1] 
		jz .hotkey_1 
		cmp eax, [uiHotkeyId1_ctrl] 
		jz .hotkey_1 
		cmp eax, [uiHotkeyId1b] 
		jz .hotkey_1b 
		cmp eax, [uiHotkeyId1c] 
		jz .hotkey_1c 
		cmp eax, [uiHotkeyId2] 
		jz .hotkey_2 
		cmp eax, [uiHotkeyId2_ctrl] 
		jz .hotkey_2 
		cmp eax, [uiHotkeyId3] 
		jz .hotkey_3 
		cmp eax, [uiHotkeyId3_ctrl] 
		jz .hotkey_3 
		cmp eax, [uiHotkeyId5a] 
		jz .hotkey_5 
		cmp eax, [uiHotkeyId5b] 
		jz .hotkey_5 
		cmp eax, [uiHotkeyId4a] 
		jl .not_hotkey4 
		cmp eax, [uiHotkeyId4d] 
		jle .hotkey_4 
		.not_hotkey4: 
		cmp eax, [uiHotkeyIdE] 
		jz .hotkey_exit 
		
		jmp .message_loop 
		
		.hotkey_1: 
			push dword lH1Received 
			call log 
			
			%if SEND_KEYBOARD_CONTROLS > 0 
				push dword VK_F4 
				call simulate_key 
			%endif 
			
			;; Start an animation. 
			%if DM_C_COMPATIBLE > 0 
				call [__imp__GetTickCount@0] 
			%else 
				call [GetTickCount] 
			%endif 
			mov dword [iAnimationStarted], eax 
			mov dword [iAnimationType], 0 ;; Wipe transition. 
			mov dword [iAnimationDone], 0 
			
			push dword lH1Processed 
			call log 
			
			jmp .message_loop 
		.hotkey_1b: 
		.hotkey_1c: 
			push dword lH1BReceived 
			call log 
			
			%if SEND_KEYBOARD_CONTROLS > 0 
				push dword VK_F4 
				call simulate_key 
			%endif 
			
			;; Start an animation. 
			%if DM_C_COMPATIBLE > 0 
				call [__imp__GetTickCount@0] 
			%else 
				call [GetTickCount] 
			%endif 
			mov [iAnimationStarted], eax 
			mov dword [iAnimationType], 2 ;; Fade transition. 
			mov dword [iAnimationDone], 0 
			
			push dword lH1bProcessed 
			call log 
			
			jmp .message_loop 
		.hotkey_2: 
			push dword lH2Received 
			call log 
			
			%if DM_C_COMPATIBLE > 0 
				call [__imp__GetTickCount@0] 
			%else 
				call [GetTickCount] 
			%endif 
			mov [iAnimationStarted], eax 
			
			mov eax, [iAnimationType] 
			or eax, 0x01 ;; Turn this into an ON->OFF animation. 
			mov [iAnimationType], eax 
			
			mov dword [iAnimationDone], 0 
			
			push dword lH2Processed 
			call log 
			
			jmp .message_loop 
		.hotkey_3: 
			push dword lH3Received 
			call log 
			
			mov dword [iAnimationDone], 1 ;; Force the animation to be "done". 
			mov dword [iToggleKey], 1 
			
			jmp .message_loop 
		.hotkey_4: 
			push dword sLogProjectorChange 
			call log 
			
			mov eax, [msg.wParam] 
			
			debug_hex eax 
			
			cmp eax, [uiHotkeyId4a] 
			jz .hotkey_4.a 
			cmp eax, [uiHotkeyId4b] 
			jz .hotkey_4.b 
			cmp eax, [uiHotkeyId4c] 
			jz .hotkey_4.c 
			cmp eax, [uiHotkeyId4d] 
			jz .hotkey_4.d 
			jmp .message_loop 
			
			.hotkey_4.a: 
				mov edx, 0x0001 ;; Computer (input 1) 
				jmp .hotkey_4.cont 
			.hotkey_4.b: 
				mov edx, 0x271A ;; Live (program) 
				jmp .hotkey_4.cont 
			.hotkey_4.c: 
				mov edx, 0x0BC2 
				jmp .hotkey_4.cont 
			.hotkey_4.d: 
				mov edx, 0x0BCC 
			.hotkey_4.cont: 
			
			mov [iNeedProjectors], edx 
			
			debug_hex edx 
			
			jmp .message_loop 
		.hotkey_5: 
			;; This hotkey means to transition a dark overlay to ON or to OFF ... 
			
			push ebp 
			mov ebp, esp 
			sub esp, 4 
			
			call bm_get_downstream_key@0 
			mov [ebp-4], eax 
			test eax, eax 
			jz .no_key_returned 
			
			push dword 0 
			push dword 1 
			push dword 0 
			push dword 1 
			push eax 
			call bm_dsk_init_for_dark_overlay 
			
			push dword [ebp-4] 
			call bm_dsk_perform_auto_transition 
			
			push dword [ebp-4] 
			call bm_free 
			
			.no_key_returned: 
			
			mov esp, ebp 
			pop ebp 
			
			jmp .message_loop 
		.hotkey_exit: 
			push dword lExReceived 
			call log 
			
			;; Don't jump anywhere; just exit to 
			;; .done_message_loop 
			
			jmp .done_message_loop 
.done_message_loop__wm_close: 
push dword lMsgClose 
call log 
.done_message_loop: 

mov dword [iAppDone], 1 ;; Mark the end of the app. 

push dword [uiHotkeyId1] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId2] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

; push dword [uiHotkeyId3] 
; push dword 0 
; %if DM_C_COMPATIBLE 
	; call [__imp__UnregisterHotKey@8] 
; %else 
	; call [UnregisterHotKey] 
; %endif 

push dword [uiHotkeyId1_ctrl] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId2_ctrl] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId3_ctrl] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId5a] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId5b] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId4a] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId4b] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId4c] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyId4d] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

push dword [uiHotkeyIdE] 
push dword 0 
%if DM_C_COMPATIBLE 
	call [__imp__UnregisterHotKey@8] 
%else 
	call [UnregisterHotKey] 
%endif 

.hotkey_already_registred: 

mov dword [iAppDone], 1 ;; Do this again for the 'hotkey_already_registered' jump to also cover. 


.close_and_done: 
;; Write finishing message: 
push dword lStopping 
call log 
;; Put a couple of new-lines: 
push dword sEndl 
call log 
push dword sEndl 
call log 
;; Close the file: 
push dword [hLog] 
%if DM_C_COMPATIBLE > 0 
	call [__imp__CloseHandle@4] 
%else 
	call [CloseHandle] 
%endif 

;; Don't need a CloseHandle () on a NULL ... 
cmp dword [hThread], 0 
jz .done 

;; Close our handle to the thread: 
push dword [hThread] 
%if DM_C_COMPATIBLE > 0 
	call [__imp__CloseHandle@4] 
%else 
	call [CloseHandle] 
%endif 

.done: 
push dword [iExitCode] 
%if DM_C_COMPATIBLE > 0 
	call [__imp__ExitProcess@4] 
%else 
	call [ExitProcess] 
%endif 


close_app: 
mov dword [iAppDone], 1 
ret 



section .data 
sStillHere1			db __FILE__, ": ", 0 
sStillHereN			db "0000", 0 

sStillHereTab		db 9, "-> ", 0 

section .text 

log_dec: 
push ebp 
mov ebp, esp 
sub esp, 8 
pushfd 
pushad 
	;; Make number: 
	lea ebx, [ebp-8] 
	mov eax, [sStillHereN + 4] 
	mov [ebx+4], eax 
	mov dword [ebx], "    " ;; Start with all spaces. 
	mov eax, [ebp+8] 
	xor edx, edx 
	mov ecx, 10 
	;; Digit 4: 
	div ecx 
	add dl, 48 
	mov [ebx+3], dl 
	;; Just print if no more digits: 
	test eax, eax 
	jz .print 
	;; Digit 3: 
	xor edx, edx 
	div ecx 
	add dl, 48 
	mov [ebx+2], dl 
	;; Just print if no more digits: 
	test eax, eax 
	jz .print 
	;; Digit 2: 
	xor edx, edx 
	div ecx 
	add dl, 48 
	mov [ebx+1], dl 
	;; Just print if no more digits: 
	test eax, eax 
	jz .print 
	;; Digit 1: 
	xor edx, edx 
	div ecx 
	add dl, 48 
	mov [ebx], dl 
	.print: 
	;; Print!: 
	push ebx 
	call log 
popad 
popfd 
mov esp, ebp 
pop ebp 
ret 4 

stillhere: 
push ebp 
mov ebp, esp 
sub esp, 8 
pushfd 
pushad 
	push dword sStillHere1 
	call log 
	push dword [ebp+8] 
	call log_dec 
	push dword sEndl 
	call log 
popad 
popfd 
mov esp, ebp 
pop ebp 
ret 4 

print_debug_int_prefix: 
push ebp 
mov ebp, esp 
sub esp, 8 
pushfd 
pushad 
	push dword sStillHere1 
	call log 
	push dword [ebp+8] 
	call log_dec 
	push dword sStillHereTab 
	call log 
popad 
popfd 
mov esp, ebp 
pop ebp 
ret 4 


log_hex: 
push ebp 
mov ebp, esp 
sub esp, 12 
pushfd 
pushad 
;; Procedure: 
;; Make a string: 
mov edx, [ebp+8] 
lea ebx, [ebp-12] 
mov ecx, 8 
mov byte [ebx+ecx], 0 ;; NULL string terminator. 
.digit0: 
dec ecx 
mov eax, edx 
and eax, 0x0F 
cmp eax, 0x0A 
jnl .a0 
add al, '0' 
jmp .digit_make 
.a0: 
add al, 'A' - 0x0A 
.digit_make: 
mov [ebx+ecx], al 
shr edx, 4 
test ecx, ecx 
jnz .digit0 
.print_digits: 
push ebx 
call log 
.done: 
popad 
popfd 
mov esp, ebp 
pop ebp 
ret 4 



log: 
cmp dword [hLog], 0 
jnz .log_ok 
xor eax, eax 
jmp .no_log 
.log_ok: 
push ebp 
mov ebp, esp 
sub esp, 4 
;; Count the number of characters in the string: 
mov ebx, [ebp+8] 
xor ecx, ecx 
.counting: 
mov al, [ebx+ecx] 
inc ecx 
cmp al, 0 
jnz .counting 
dec ecx 
;; Write data: 
push dword 0 
	lea ebx, [ebp-4] 
push ebx ;; Here, WriteFile () will save how many bytes were actually written. 
push ecx ;; This is the size of the buffer to write. 
push dword [ebp+8] ;; The memory address of the function argument string. 
push dword [hLog] 
%if DM_C_COMPATIBLE > 0 
	call [__imp__WriteFile@20] 
%else 
	call [WriteFile] 
%endif 
;; Return the number of bytes written: 
mov eax, [ebp-4] 
mov esp, ebp 
pop ebp 
.no_log: 
ret 4 


%if SEND_KEYBOARD_CONTROLS > 0 
	simulate_key: 
	push ebp 
	mov ebp, esp 

	mov eax, [ebp+8] 
	mov [myInput.ki.wVk], ax 

	push dword 0 
	push eax 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__MapVirtualKey@8] 
	%else 
		call [MapVirtualKey] 
	%endif 
	mov [myInput.ki.wScan], eax 
	
	%if DM_C_COMPATIBLE > 0 
		call [__imp__GetMessageExtraInfo@0] 
	%else 
		call [GetMessageExtraInfo] 
	%endif 
	mov [myInput.ki.dwExtraInfo], eax 

	;; Send a KEY_DOWN message: 
	mov dword [myInput.ki.dwFlags], 0 
	push dword [myInputSize] 
	push dword myInput 
	push dword 1 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__SendInput@12] 
	%else 
		call [SendInput] 
	%endif 
	
	;; Send a KEY_UP message: 
	mov dword [myInput.ki.dwFlags], KEYEVENTF_KEYUP 
	push dword [myInputSize] 
	push dword myInput 
	push dword 1 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__SendInput@12] 
	%else 
		call [SendInput] 
	%endif 
	
	mov esp, ebp 
	pop ebp 
	ret 4 
%endif 



thread_keyer: 
push ebp 
mov ebp, esp 
sub esp, 64 ;; 12 + 32 + 4 + 8 + 4 + 4 

xor eax, eax, 
mov [ebp-4], eax 
mov [ebp-12], eax ;; isAnimationStarted 
mov [ebp-48], eax ;; Does Key1 need to be enabled when not displaying our things? 

call bm_init 

key_wait_loop: 
	cmp dword [iAppDone], 0 
	jnz key_wait_loop_done 
	
	cmp dword [iToggleKey], 0 
	jnz .toggle_key 
	
	mov eax, [iNeedProjectors] 
	test eax, eax 
	jns .change_projectors 
	
	cmp dword [iAnimationDone], 0 
	jnz .continue_with_animation_done  
	
	%if DM_C_COMPATIBLE > 0 
		call [__imp__GetTickCount@0] 
	%else 
		call [GetTickCount] 
	%endif 
	sub eax, [iAnimationStarted] 
	mov [ebp-8], eax 
	
	cmp eax, [iAnimationLength] 
	jng .step_animation 
	
	jmp .finish_animation 
	
	.toggle_key: 
		imhere 
		
		; call bm_check 
		
		; debug_hex eax 
		
		; test eax, eax 
		; jnz .continue_loop 
		
		call toggle_key1 
		
		imhere 
		
		test eax, eax 
		jnz .hk3.success 
			push dword lH3ProcessedF 
			jmp .hk3.do_log 
		.hk3.success: 
			push dword lH3ProcessedT 
		.hk3.do_log: 
		call log 
		
		push dword sEndl 
		call log 
		
		mov dword [iToggleKey], 0 
		
		call bm_get_key 
		mov [ebp-60], eax 
		test eax, eax 
		jz .skip_enable_mask 
			imhere 
			
			;; Arguments: 
			sub esp, 8 
			movsd xmm0, qword [myMaskRight] 
			movsd qword [esp], xmm0 
			
			imhere 
			
			;; Call: 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+92] ;; SetMaskRight () 
			push ecx ;; Arg0 
			call eax 
			
			;; Close: 
			mov ecx, [ebp-60] ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
		.skip_enable_mask: 
		
		imhere 
		
		jmp .continue_loop 
	.change_projectors: 
		push dword sLogProjectorCode 
		call log 
		
		push dword 256 ;; Max retries 
		push dword 0 ;; Input ID hi-dword. 
		push dword [iNeedProjectors] ;; Input ID lo-dword. 
		push dword 2 ;; Stop before the aux input #3. 
		push dword 0 ;; Start at aux input #1. 
		call _bm_set_aux_outputs@20 
		
		mov dword [iNeedProjectors], -1 ;; -1 means don't change projectors. 
		
		jmp key_wait_loop 
	.start_animation: 
		;; Do pre-animation code. 
		
		imhere 
		
		debug_dec [iAnimationType] 
		
		;; Check if this animation type makes sense, and 
		call is_key1_live 
		mov ecx, dword [iAnimationType] ;; Grab the animation type. 
		not ecx ;; Turn all 1s into 0s, and all 0s into 1s, so that our logic works below. 
		and ecx, 1 ;; Just keep the ON/OFF flag (1 = OFF). 
		xor eax, ecx 
		jz .finish_animation ;; If the animation type is ON and the key state is ON, then don't do the animation. And vice versa. 
		
		; mov eax, [iAnimationType] 
		; test eax, 1 ;; Check if this is an ON->OFF animation. 
		; jnz .skip_checking_key_live 
			; imhere 
			; call is_key1_live 
			; mov [ebp-48], eax ;; Key1 live flag. 
		; .skip_checking_key_live: 
		
		imhere 
		
		call bm_get_key 
		mov [ebp-60], eax 
		test eax, eax 
		jz .skip_init_mask 
			imhere 
			
			;; Arguments: 
			sub esp, 8 
			movsd xmm0, qword [myMaskLeft] 
			test dword [iAnimationType], 1 
			jz .continue_init_mask 
				movsd xmm0, qword [myMaskRight] 
			.continue_init_mask: 
			movsd qword [esp], xmm0 
			
			imhere 
			
			;; Call: 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+92] ;; SetMaskRight () 
			push ecx ;; Arg0 
			call eax 
			
			;; Close: 
			mov ecx, [ebp-60] ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
		.skip_init_mask: 
		
		imhere 
		
		push dword 1 ;; TRUE 
		call enable_key1_live 
		
		imhere 
		
		mov dword [ebp-12], 1 ;; Set flag mIsAnimationStarted 
		ret 
	.step_animation: 
		imhere 
		
		; call bm_check 
		; test eax, eax 
		; jz .step_animation_check_ok 
			; ;; Cancel the animation, since we don't have access to the switcher. 
			; mov dword [iAnimationDone], 1 
			
			; imhere 
			
			; push dword sMsgAnimationCanceledBecauseNoSwitcher 
			; call log 
			; push dword sEndl 
			; call log 
			
			; jmp .continue_loop 
		; .step_animation_check_ok: 
		
		imhere 
		
		%ifdef DEBUG 
			%if DEBUG > 0 
				push dword sLogCheckOK 
				call log 
			%endif 
		%endif 
		
		mov eax, [ebp-12] ;; mIsAnimationStarted 
		test eax, eax 
		jnz .animation_already_started 
			imhere 
			call .start_animation ;; Do pre-animation steps. 
			imhere 
		.animation_already_started: 
		
		imhere 
		
		%ifdef DEBUG 
			%if DEBUG > 0 
				push dword lAnPStep 
				call log 
			%endif 
		%endif 
		
		lea ebx, [ebp-44] ;; Mask values. 
		; fld qword [ebx+24] ;; Right 
		; fsub qword [ebx+16] ;; Left 
		fld qword [myMaskRight] 
		fsub qword [myMaskLeft] 
		fild dword [ebp-8] ;; Elapsed 
		fidiv dword [iAnimationLength] ;; Length 
		fmul 
		; fadd qword [ebx+16] ;; Left 
		fadd qword [myMaskLeft] 
		fstp qword [ebp-56] 
		
		imhere 
		
		; fld qword [ebx+0] 
		; fistp dword [ebp-64] 
		; debug_dec [ebp-64] 
		
		; fld qword [ebx+8] 
		; fistp dword [ebp-64] 
		; debug_dec [ebp-64] 
		
		; fld qword [ebx+16] 
		; fistp dword [ebp-64] 
		; debug_dec [ebp-64] 
		
		; fld qword [ebx+24] 
		; fistp dword [ebp-64] 
		; debug_dec [ebp-64] 
		
		mov eax, [iAnimationType] 
		test eax, 1 ;; See if ON->OFF type; 
		jz .continue_forward 
			;; We need to animate this backwards. 
			imhere 
			; fld qword [ebx+24] ;; Right 
			fld qword [myMaskRight] 
			fsub qword [ebp-56] ;; Previous "New Right" 
			; fadd qword [ebx+16] ;; Left 
			fadd qword [myMaskLeft] 
			fstp qword [ebp-56] ;; Now "New Right" 
		.continue_forward: 
		
		imhere 
		
		call bm_get_key 
		mov [ebp-60], eax 
		test eax, eax 
		jz .skip_animating_mask 
			imhere 
			
			;; Arguments: 
			sub esp, 8 
			movsd xmm0, qword [ebp-56] 
			movsd qword [esp], xmm0 
			
			imhere 
			
			;; Call: 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+92] ;; SetMaskRight () 
			push ecx ;; Arg0 
			call eax 
			
			fld qword [ebp-56] 
			fistp dword [ebp-64] 
			debug_dec [ebp-64] 
			
			imhere 
			
			
			;; TODO: Any other settings, etc. 
			
			
			;; Close: 
			mov ecx, [ebp-60] ;; THIS pointer. 
			mov eax, [ecx] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
		.skip_animating_mask: 
		
		imhere 
		
		;; TODO: Set all the parameters to their current animated values. 
		
		
		;jmp .continue_loop 
		
		push dword 10 ;; 10 ms is the minimum wait time for the Win32 Sleep () function. 
		%if DM_C_COMPATIBLE > 0 
			call [__imp__Sleep@4] 
		%else 
			call [Sleep] 
		%endif 
		
		jmp key_wait_loop 
	.finish_animation: 
		imhere 
		
		debug_dec [iAnimationType] 
		
		; call bm_check 
		
		imhere 
		
		mov eax, [iAnimationType] 
		test eax, 1 ;; ON->OFF? 
		jz .off_to_on 
			
			imhere 
			
			;push dword [ebp-48] ;; Grab what it was before we started animating things. 
			push dword 0 
			call enable_key1_live 
			
			jmp .done_key_finalizing 
		.off_to_on: 
			
			imhere 
			
			call bm_get_key 
			mov [ebp-60], eax 
			debug_hex eax 
			test eax, eax 
			jz .skip_finalizing_key_mask 
			.try_finish_mask_size: 
				
				imhere 
				
				;; Arguments: 
				sub esp, 8 
				movsd xmm0, qword [myMaskRight] 
				movsd qword [esp], xmm0 
				
				debug_hex eax 
				
				;; Call: 
				mov ecx, [ebp-60] ;; THIS pointer. 
				mov eax, [ecx] ;; VTable. 
				mov eax, [eax+92] ;; SetMaskRight () 
				push ecx ;; Arg0 
				call eax 
				
				imhere 
				
				;; TODO: Any other settings, etc. 
				
				lea ebx, [ebp-56] ;; Where to store 'double' of mask_right. 
				mov ecx, [ebp-60] ;; Key. 
				push ebx ;; Argument 1: double * out_maskRight 
				mov eax, [ecx] ;; VTable 
				push ecx ;; Arg0 
				call dword [eax+88] ;; GetMaskRight () 
				
				imhere 
				
				debug_hex dword [ebp-56] 
				debug_hex dword [ebp-52] 
				
				debug_hex dword [myMaskRight + 0] 
				debug_hex dword [myMaskRight + 4] 
				
				movsd xmm0, qword [ebp-56] 
				movsd xmm1, qword [myMaskRight] 
				comisd xmm0, xmm1 
				jz .done_off_to_on ;; If the value we get is equal to the target mask right (+16), then we're done! 
				
				;; Otherwise, we have to try again in a bit. 
				
				imhere 
				
				;; Wait 25 ms: 
				push dword 25 
				%if DM_C_COMPATIBLE > 0 
					call [__imp__Sleep@4] 
				%else 
					call [Sleep] 
				%endif 
				
				imhere 
				
				jmp .try_finish_mask_size ;; Retry. 
				
				.done_off_to_on: 
				imhere 
				;; Close: 
				mov ecx, [ebp-60] ;; THIS pointer. 
				mov eax, [ecx] ;; VTable. 
				mov eax, [eax+8] ;; Release () 
				push ecx ;; Arg0 
				call eax 
			.skip_finalizing_key_mask: 
			
			imhere 
			
		.done_key_finalizing: 
		
		imhere 
		
		cmp dword [iAnimationDone], 0 
		jnz .continue_loop 
		mov dword [ebp-12], 0 ;; Clear mIsAnimationStarted, for next time. 
		mov dword [iAnimationDone], 1 ;; Set the animation-done flag, so we know in the next loop iteration not to do this again. 
		
		push dword lAnPDone 
		call log 
		push dword sEndl 
		call log 
		
		imhere 
		
		
		test byte [iAnimationType], 1 ;; OFF 
		jz .continue_loop ;; Skip taking it off if this is not an OFF type. 
		call .take_screen_off 
		
		imhere 
		
		jmp .continue_loop 
	.take_screen_off: 
		imhere 
		
		%if SEND_KEYBOARD_CONTROLS > 0 
			;; Take words, etc., off the projector screen: 
			push dword VK_ESCAPE 
			call simulate_key 
		%endif 
		
		imhere 
		
		ret 
	.continue_with_animation_done: 
		mov dword [ebp-12], 0 ;; Clear mIsAnimationStarted flag. 
	.continue_loop: 
	
	push dword 25 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__Sleep@4] 
	%else 
		call [Sleep] 
	%endif 
	
	jmp key_wait_loop 
key_wait_loop_done: 

call bm_close 

thread_keyer_done: 
mov eax, [ebp-4] 
mov esp, ebp 
pop ebp 
ret 4 



toggle_key1: 
	imhere 
	call is_key1_live 
	debug_hex eax 
	imhere 
	;; Negate the boolean in al: 
	inc al 
	and al, 0x01 
	;; Set that as the new state: 
	imhere 
	push eax 
	call enable_key1_live 
	imhere 
ret 

touch_key1: 
	imhere 
	call is_key1_live 
	debug_hex eax 
	imhere 
	;; Set that as the new state: 
	imhere 
	push eax 
	call enable_key1_live 
	imhere 
ret 

is_key1_live: 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	;; Procedure: 
	imhere 
	call bm_get_key 
	test eax, eax 
	jz .done 
	
	imhere 
	
	mov [ebp-4], eax 
	
	debug_hex [ebp-4] 
	
	push dword sLogVTable 
	call log 
	mov eax, [ebp-4] ;; THIS 
	mov eax, [eax] ;; VTable 
	debug_hex eax 
	
	mov eax, [ebp-4] 
	mov ecx, eax ;; THIS pointer. 
	lea ebx, [ebp-8] 
	mov eax, [eax] ;; VTable. 
	push ebx 
	mov eax, [eax+44] ;; GetOnAir () 
	push ecx ;; Arg0 
	call eax 
	test eax, eax 
	jns .get_onair_ok 
		
		imhere 
		
		debug_hex eax 
		
		call .free_key 
		imhere 
		xor eax, eax ;; FALSE 
		jmp .done 
		
	.get_onair_ok: 
	
	imhere 
	
	;; Key live: 
	debug_hex [ebp-8] 
	
	call .free_key 
	
	imhere 
	
	mov eax, [ebp-8] 
	jmp .done 
	
	.free_key: 
		mov eax, [ebp-4] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		ret 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 

enable_key1_live: 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	;; Procedure: 
	imhere 
	call bm_get_key 
	test eax, eax 
	jz .done 
	
	imhere 
	
	mov [ebp-4], eax 
	
	debug_hex eax 
	
	imhere 
	
	debug_dec [ebp+8] 
	
	mov eax, [ebp-4] 
	mov ecx, eax ;; THIS pointer. 
	mov eax, [eax] ;; VTable. 
	push dword [ebp+8] 
	mov eax, [eax+48] ;; SetOnAir () 
	push ecx ;; Arg0 
	call eax 
	test eax, eax 
	jns .set_onair_ok 
		
		imhere 
		
		debug_hex eax 
		debug_dec eax 
		
		call is_key1_live.free_key 
		imhere 
		xor eax, eax ;; FALSE -> no success. 
		jmp .done 
		
	.set_onair_ok: 
	
	imhere 
	
	call is_key1_live.free_key 
	
	mov eax, 1 ;; TRUE -> success. 
	
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_reset_mask@4: 
	push ebp 
	mov ebp, esp 
	imhere 
	mov eax, [ebp+8] 
	mov ecx, eax ;; THIS pointer. 
	test eax, eax 
	jz .done 
		imhere 
		debug_dec eax 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+96] ;; ResetMask () 
		push ecx ;; Arg0 
		call eax 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_enable_mask@8: 
	imhere 
	mov ecx, [esp+4] ;; THIS pointer. 
	test ecx, ecx 
	jz .done 
		imhere 
		mov eax, [esp+8] 
		push eax 
		mov eax, [ecx] ;; VTable. 
		mov eax, [eax+60] ;; SetMasked () 
		push ecx ;; Arg0 
		call eax 
		debug_dec eax 
	.done: 
	imhere 
ret 8 

bm_read_mask@8: 
	imhere 
	push ebp 
	mov ebp, esp 
	mov ebx, [ebp+12] 
	xor ecx, ecx 
	xor eax, eax 
	.clear_first: ;; Clear the 'double []' to all 0s: 
		imhere 
		mov [ebx+ecx*4], eax 
		inc ecx 
		imhere 
		cmp ecx, 8 
		jl .clear_first 
	.read_mask: 
	debug_dec [ebp+8] 
	debug_dec [ebp+12] 
	mov ecx, [ebp+8] ;; THIS pointer. 
	push dword [ebp+12] ;; top = (double [4]) [0] 
	mov eax, [ecx] ;; VTable. 
	debug_dec eax 
	mov eax, [eax+64] ;; GetMaskTop () 
	debug_dec eax 
	push ecx ;; Arg0 
	call eax 
	debug_hex eax 
	test eax, eax 
	jns .read_mask_ok1 
		imhere 
		
		push dword sErrorReadingMask 
		call log 
		
		xor eax, eax 
		jmp .done 
	.read_mask_ok1: 
	imhere 
	mov ecx, [ebp+8] ;; THIS pointer. 
	mov eax, [ebp+12] 
	add eax, 8 ;; 1 double 
	push eax ;; double * bottom 
	mov eax, [ecx] ;; VTable. 
	mov eax, [eax+72] ;; GetMaskBottom () 
	push ecx ;; Arg0 
	call eax 
	imhere 
	test eax, eax 
	jns .read_mask_ok2 
		imhere 
		
		push dword sErrorReadingMask 
		call log 
		
		xor eax, eax 
		jmp .done 
	.read_mask_ok2: 
	imhere 
	mov ecx, [ebp+8] ;; THIS pointer. 
	mov eax, [ebp+12] 
	add eax, 16 ;; 2 doubles 
	push eax ;; double * left 
	mov eax, [ecx] ;; VTable. 
	mov eax, [eax+80] ;; GetMaskLeft () 
	push ecx ;; Arg0 
	call eax 
	imhere 
	test eax, eax 
	jns .read_mask_ok3 
		imhere 
		
		push dword sErrorReadingMask 
		call log 
		
		xor eax, eax 
		jmp .done 
	.read_mask_ok3: 
	imhere 
	mov ecx, [ebp+8] ;; THIS pointer. 
	mov eax, [ebp+12] 
	add eax, 24 ;; 3 doubles 
	push eax ;; double * right 
	mov eax, [ecx] ;; VTable. 
	mov eax, [eax+88] ;; GetMaskRight () 
	push ecx ;; Arg0 
	call eax 
	imhere 
	test eax, eax 
	jns .read_mask_ok4 
		imhere 
		
		push dword sErrorReadingMask 
		call log 
		
		xor eax, eax 
		jmp .done 
	.read_mask_ok4: 
	mov eax, 1 ;; TRUE -> success; 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 8 

bm_enable_key1_mask: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	;; Procedure: 
	imhere 
	call bm_get_key 
	mov [ebp-4], eax ;; Key. 
	imhere 
	test eax, eax 
	jz .done 
		imhere 
		
		push dword [ebp+8] 
		push eax 
		call bm_enable_mask@8 
		
		imhere 
		
		mov ecx, [ebp-4] ;; THIS pointer. 
		mov eax, [ecx] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_reset_and_read_default_key1_mask: 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	;; Procedure: 
	debug_dec ebp 
	call bm_get_key 
	mov [ebp-4], eax ;; Key. 
	debug_dec eax 
	debug_dec ebp 
	mov eax, [ebp-4] 
	test eax, eax 
	jz .done 
		imhere 
		
		debug_dec [ebp-4] 
		debug_dec ebp 
		
		;; Reset mask: 
		push eax 
		call bm_reset_mask@4 
		
		debug_dec [ebp-4] 
		debug_dec ebp 
		
		;; Read the values that we just reset to default: 
		push dword [ebp+8] 
		push dword [ebp-4] 
		call bm_read_mask@8 
		mov [ebp-8], eax ;; BOOL 
		
		debug_dec [ebp-4] 
		
		mov ecx, [ebp-4] ;; THIS pointer. 
		mov eax, [ecx] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		mov eax, [ebp-8] ;; BOOL 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 4 


_bm_set_media_player_source@16: 
	push ebp 
	mov ebp, esp 
	sub esp, 50 
	save 
	
	debug_hex ebp 
	
	xor eax, eax 
	mov [ebp-12], eax 
	mov [ebp-28], eax 
	mov [ebp-38], eax 
	%if INCLUDE_BLACKMAGIC_COM > 0 
		imhere 
		
		.get_switcher: 
		imhere 
		mov eax, [mSwitcher] 
		mov ecx, eax ;; THIS pointer! 
		test eax, eax 
		jnz .got_switcher_ok 
			imhere 
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If successful, then go get the switcher again. 
			jmp .done 
		.got_switcher_ok: 
		
		imhere 
		
		debug_hex dword [ebp-12] 
		
		;; Arguments: 
		lea ebx, [ebp-4] 
		push ebx 
		push dword IBMDSwitcherMediaPlayerIterator 
		
		;; Call: 
		debug_hex eax 
		mov eax, [eax] ;; Get VTable. 
		debug_hex eax 
		mov eax, [eax+72] ;; Switcher->CreateIterator () 
		debug_hex eax 
		push ecx ;; Arg0 
		call eax 
		
		debug_hex eax 
		
		debug_hex dword [ebp-12] 
		
		test eax, eax 
		jns .get_mebi_ok 
			imhere 
			
			debug_hex eax 
			
			push dword sGetKeyError1 
			call log 
			
			imhere 
			
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If restart was successful, then try again. 
			
			xor eax, eax 
			jmp .done 
			
		.get_mebi_ok: 
		imhere 
		
		.get_again: 
		
		debug_hex dword [ebp-12] 
		
		imhere 
		
		lea ebx, [ebp-8] 
		push ebx 
		mov eax, [ebp-4] 
		imhere 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		imhere 
		mov eax, [eax+12] 
		imhere 
		push ecx ;; Arg0 
		call eax 
		mov [ebp-16], eax 
		
		debug_hex eax 
		
		debug_hex dword [ebp-12] 
		
		mov eax, [ebp-8] 
		test eax, eax 
		jz .done_free 
		
		; lea ebx, [ebp-20] 
		; mov dword [ebx], 0 
		; push ebx 
		; push dword [ebp-8] 
		; call _bm_get_input_type@8 
		
		; mov eax, [ebp-20] 
		; cmp eax, 'oxua' 
		; jnz .skip_checking_index 
			
			
			lea ebx, [ebp-24] 
			mov dword [ebx], 0 
			push ebx 
			push dword IBMDSwitcherMediaPlayer 
			
			mov ecx, [ebp-8] 
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			debug_hex esp 
			call dword [eax+0] ;; QueryInterface 
			debug_hex esp 
			debug_hex eax 
			test eax, eax 
			js .skip_checking_index 
			
			debug_hex dword [ebp-24] 
			
			debug_hex dword [ebp-12] 
			
			mov ecx, [ebp-24] 
			test ecx, ecx 
			jz .skip_checking_index 
			mov eax, [ecx] ;; VTable. 
			
			
			
		; Continue: 
		
		mov eax, [ebp-12] 
		debug_hex eax 
		debug_hex dword [ebp+12] 
		cmp eax, [ebp+12] 
		jnl .done_get_again 
		
		debug_hex ebp 
		
		cmp eax, [ebp+8] 
		jl .free_aux_object 
			
			imhere 
			
			mov dword [ebp-42], 0 
			
			debug_hex eax 
			
			debug_hex esp 
			
			.try_again: 
			
			mov ecx, [ebp-24] ;; THIS 
			
			push dword [ebp+16] 
			push dword 'spms' ;; LE of 'smps' 
			push ecx ;; Arg0 
			mov ecx, [ebp-24] ;; THIS 
			mov eax, [ecx] ;; VTable. 
			debug_hex eax 
			mov eax, [eax+16] ;; SetSource () 
			imhere 
			debug_hex dword [eax] 
			debug_hex esp 
			call eax 
			debug_hex esp 
			debug_hex eax 
			test eax, eax 
			js .free_aux_object 
			
			lea ebx, [ebp-50] 
			push ebx 
			lea ebx, [ebp-46] 
			push ebx 
			
			mov ecx, [ebp-24] ;; THIS 
			mov eax, [ecx] ;; VTable 
			push ecx ;; Arg0 
			call [eax+12] ;; GetSource () 
			test eax, eax 
			js .done_trying_again 
			
			mov eax, [ebp-50] 
			cmp eax, [ebp+16] 
			jz .done_trying_again 
			
			jmp .not_changed 
			
			.done_trying_again: 
			
			debug_hex esp 
			
			inc dword [ebp-28] 
			
			debug_hex esp 
			
			jmp .free_aux_object 
			
		.not_changed: 
			push dword 10 ;; Wait a little 
			%if DM_C_COMPATIBLE > 0 
				call [__imp__Sleep@4] 
			%else 
				call [Sleep] 
			%endif 
			debug_hex dword [ebp-42] 
			debug_hex dword [ebp+24] 
			mov eax, [ebp-42] 
			inc dword [ebp-42] 
			cmp eax, [ebp+20] 
			jl .try_again 
		.free_aux_object: 
			
			debug_hex dword [ebp-12] 
			
			mov ecx, [ebp-24] 
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			call dword [eax+8] ;; Release () 
			
			imhere 
			
		.skip_setting_input: 
		
		debug_hex dword [ebp-12] 
		
		mov eax, [ebp-12] 
		inc eax 
		mov [ebp-12], eax 
		
		debug_hex dword [ebp-12] 
		
		.skip_checking_index: 
		
		imhere 
		
		mov ecx, [ebp-8] 
		test ecx, ecx 
		jz .done_get_again 
		debug_hex ecx 
		mov eax, [ecx] ;; VTable. 
		debug_hex eax 
		push ecx ;; Arg0 
		call dword [eax+8] ;; Release () 
		debug_hex eax 
		
		xor eax, eax 
		mov [ebp-8], eax 
		
		debug_hex ebp 
		
		jmp .get_again 
		
		.done_get_again: 
		
		mov ecx, [ebp-8] 
		test eax, eax 
		jz .done_free 
			
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			call dword [eax+8] ;; Release () 
			
		.done_free: 
		
		
		debug_hex eax 
		debug_hex [ebp-8] 
		
		test eax, eax 
		jns .get_first_block_ok 
			imhere 
			
			debug_hex eax 
			
			mov eax, [ebp-4] 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [eax] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
			
			imhere 
			
			push dword sGetKeyError2 
			call log 
			xor eax, eax 
			jmp .done 
			
		.get_first_block_ok: 
		
		imhere 
		
		mov eax, [ebp-4] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		imhere 
		
		;; Return the mix effect block in EAX: 
		mov eax, [ebp-8] 
		
	%endif 
	
	.done: 
	
	mov eax, [ebp-28] 
	
	debug_hex ebp 
	
	restore 
	mov esp, ebp 
	pop ebp 
ret 12 

_bm_set_aux_outputs@20: 
	push ebp 
	mov ebp, esp 
	sub esp, 42 
	save 
	
	xor eax, eax 
	mov [ebp-12], eax 
	mov [ebp-28], eax 
	mov [ebp-38], eax 
	%if INCLUDE_BLACKMAGIC_COM > 0 
		imhere 
		
		.get_switcher: 
		imhere 
		mov eax, [mSwitcher] 
		mov ecx, eax ;; THIS pointer! 
		test eax, eax 
		jnz .got_switcher_ok 
			imhere 
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If successful, then go get the switcher again. 
			jmp .done 
		.got_switcher_ok: 
		
		imhere 
		
		debug_hex dword [ebp-12] 
		
		;; Arguments: 
		lea ebx, [ebp-4] 
		push ebx 
		push dword IBMDSwitcherInputIterator 
		
		;; Call: 
		debug_hex eax 
		mov eax, [eax] ;; Get VTable. 
		debug_hex eax 
		mov eax, [eax+72] ;; Switcher->CreateIterator () 
		debug_hex eax 
		push ecx ;; Arg0 
		call eax 
		
		debug_hex eax 
		
		debug_hex dword [ebp-12] 
		
		test eax, eax 
		jns .get_mebi_ok 
			imhere 
			
			debug_hex eax 
			
			push dword sGetKeyError1 
			call log 
			
			imhere 
			
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If restart was successful, then try again. 
			
			xor eax, eax 
			jmp .done 
			
		.get_mebi_ok: 
		imhere 
		
		.get_again: 
		
		debug_hex dword [ebp-12] 
		
		imhere 
		
		lea ebx, [ebp-8] 
		push ebx 
		mov eax, [ebp-4] 
		imhere 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		imhere 
		mov eax, [eax+12] 
		imhere 
		push ecx ;; Arg0 
		call eax 
		mov [ebp-16], eax 
		
		debug_hex eax 
		
		debug_hex dword [ebp-12] 
		
		mov eax, [ebp-8] 
		test eax, eax 
		jz .done_free 
		
		; lea ebx, [ebp-20] 
		; mov dword [ebx], 0 
		; push ebx 
		; push dword [ebp-8] 
		; call _bm_get_input_type@8 
		
		; mov eax, [ebp-20] 
		; cmp eax, 'oxua' 
		; jnz .skip_checking_index 
			
			
			lea ebx, [ebp-24] 
			mov dword [ebx], 0 
			push ebx 
			push dword IBMDSwitcherInputAux 
			
			mov ecx, [ebp-8] 
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			debug_hex esp 
			call dword [eax+0] ;; QueryInterface 
			debug_hex esp 
			debug_hex eax 
			test eax, eax 
			js .skip_checking_index 
			
			debug_hex dword [ebp-24] 
			
			debug_hex dword [ebp-12] 
			
			mov ecx, [ebp-24] 
			test ecx, ecx 
			jz .skip_checking_index 
			mov eax, [ecx] ;; VTable. 
			
			
			
		; Continue: 
		
		mov eax, [ebp-12] 
		debug_hex eax 
		debug_hex dword [ebp+12] 
		cmp eax, [ebp+12] 
		jnl .done_get_again 
		
		debug_hex ebp 
		
		cmp eax, [ebp+8] 
		jl .free_aux_object 
			
			imhere 
			
			
			
			debug_hex eax 
			
			debug_hex esp 
			
			xor eax, eax 
			mov [ebp-42], eax 
			
			; %ifdef DEBUG 
				; %if DEBUG > 0 
			lea ebx, [ebp-36] 
			push ebx 
			push dword [ebp-24] ;; THIS, Arg0 
			
			mov ecx, dword [ebp-24] ;; THIS 
			mov eax, [ecx] ;; VTable. 
			debug_hex esp 
			call [eax+12] ;; GetInputSource () 
			debug_hex esp 
			debug_hex eax 
			
			debug_hex dword [ebp-36] 
			debug_hex dword [ebp-32] 
				; %endif 
			; %endif 
			
			mov eax, [ebp-36] 
			cmp eax, [ebp+16] 
			jnz .began_with_different_input ;; Skip this if the input is already equal to the one we want to set. 
				inc dword [ebp-38] ;; Increment 'already was' count. 
				jmp .free_aux_object 
			.began_with_different_input: 
			.make_change: 
			
			mov ecx, [ebp-24] ;; THIS 
			
			debug_hex dword [ebp+20] 
			debug_hex dword [ebp+16] 
			push dword [ebp+20] 
			push dword [ebp+16] 
			push ecx ;; Arg0 
			mov ecx, [ebp-24] ;; THIS 
			mov eax, [ecx] ;; VTable. 
			debug_hex eax 
			mov eax, [eax+16] ;; SetInputSource () 
			imhere 
			debug_hex dword [eax] 
			debug_hex esp 
			call eax 
			debug_hex esp 
			debug_hex eax 
			test eax, eax 
			js .free_aux_object 
			
			debug_hex esp 
			
			%ifdef DEBUG 
				%if DEBUG > 0 
					lea ebx, [ebp-36] 
					push ebx 
					push dword [ebp-24] ;; THIS, Arg0 
					
					mov ecx, dword [ebp-24] ;; THIS 
					mov eax, [ecx] ;; VTable. 
					debug_hex esp 
					call [eax+12] ;; GetInputSource () 
					debug_hex esp 
					debug_hex eax 
					
					debug_hex dword [ebp-36] 
					debug_hex dword [ebp-32] 
				%endif 
			%endif 
			
			; %ifdef DEBUG 
				; %if DEBUG > 0 
			lea ebx, [ebp-36] 
			push ebx 
			push dword [ebp-24] ;; THIS, Arg0 
			
			mov ecx, dword [ebp-24] ;; THIS 
			mov eax, [ecx] ;; VTable. 
			debug_hex esp 
			call [eax+12] ;; GetInputSource () 
			debug_hex esp 
			debug_hex eax 
			
			debug_hex dword [ebp-36] 
			debug_hex dword [ebp-32] 
			
			mov eax, [ebp-36] 
			cmp eax, [ebp+16] 
			jnz .not_changed ;; Skip incrementing success count if the input was *not* actually changed. 
				; %endif 
			; %endif 
			
			inc dword [ebp-28] 
			
			debug_hex esp 
			
			jmp .free_aux_object 
			
		.not_changed: 
			push dword 10 ;; Wait a little 
			%if DM_C_COMPATIBLE > 0 
				call [__imp__Sleep@4] 
			%else 
				call [Sleep] 
			%endif 
			debug_hex dword [ebp-42] 
			debug_hex dword [ebp+24] 
			mov eax, [ebp-42] 
			inc dword [ebp-42] 
			cmp eax, [ebp+24] 
			jl .make_change ;; Try again if there are still retries left. 
		.free_aux_object: 
			
			debug_hex dword [ebp-12] 
			
			mov ecx, [ebp-24] 
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			call dword [eax+8] ;; Release () 
			
			imhere 
			
		.skip_setting_input: 
		
		debug_hex dword [ebp-12] 
		
		mov eax, [ebp-12] 
		inc eax 
		mov [ebp-12], eax 
		
		debug_hex dword [ebp-12] 
		
		.skip_checking_index: 
		
		imhere 
		
		mov ecx, [ebp-8] 
		test ecx, ecx 
		jz .done_get_again 
		debug_hex ecx 
		mov eax, [ecx] ;; VTable. 
		debug_hex eax 
		push ecx ;; Arg0 
		call dword [eax+8] ;; Release () 
		debug_hex eax 
		
		xor eax, eax 
		mov [ebp-8], eax 
		
		debug_hex ebp 
		
		jmp .get_again 
		
		.done_get_again: 
		
		mov ecx, [ebp-8] 
		test eax, eax 
		jz .done_free 
			
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			call dword [eax+8] ;; Release () 
			
		.done_free: 
		
		
		debug_hex eax 
		debug_hex [ebp-8] 
		
		test eax, eax 
		jns .get_first_block_ok 
			imhere 
			
			debug_hex eax 
			
			mov eax, [ebp-4] 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [eax] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
			
			imhere 
			
			push dword sGetKeyError2 
			call log 
			xor eax, eax 
			jmp .done 
			
		.get_first_block_ok: 
		
		imhere 
		
		mov eax, [ebp-4] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		imhere 
		
		;; Return the mix effect block in EAX: 
		mov eax, [ebp-8] 
		
	%endif 
	
	.done: 
	
	mov eax, [ebp-28] 
	
	restore 
	mov esp, ebp 
	pop ebp 
ret 20 


section .data 
sAtemIp				db "atem-ip.txt", 0 
hAtemTxt			dd 0 
szAtemIp			dd 0 

hrSwitcherConnect	dd 0 

sCoError1			db "CoInitialize () failed. ", 13, 10, 0 
sCoError2			db "Could not create Switcher Discovery instance. Is the ATEM Switcher Software installed? ", 13, 10, 0 
sCoError3			db "Error reading IP address from file 'atem-ip.txt'. ", 13, 10, 0 

sCoError4a			db "Error connecting: bmdSwitcherConnectToFailureNoResponse", 13, 10, 0 
sCoError4b			db "Error connecting: bmdSwitcherConnectToFailureIncompatibleFirmware", 13, 10, 0 
sCoError4c			db "Error connecting: bmdSwitcherConnectToFailureCorruptData", 13, 10, 0 
sCoError4d			db "Error connecting: bmdSwitcherConnectToFailureStateSync", 13, 10, 0 
sCoError4e			db "Error connecting: bmdSwitcherConnectToFailureStateSyncTimedOut", 13, 10, 0 
sCoError4e_tryingAgain	db "Trying again in 0.5 seconds ... ", 13, 10, 0 
sCoError4e_maxRetryReached	db "Maximum retry attempts reached. Quitting ... ", 13, 10, 0 
sCoError4f			db "Error connecting, and the fail reason is unknown. ", 13, 10, 0 

sCoInitOk			db "COM initialized fine. ", 13, 10, 0 

sErrorReadingMask	db "Error reading one or more key mask values. ", 13, 10, 0 

mSwitcherDiscovery	dd 0 
mSwitcher			dd 0 

mFailReason			dd 0 

%define CLSCTX_ALL			0x17 

%define bmdSwitcherConnectToFailureNoResponse                        0x63666E72 
%define bmdSwitcherConnectToFailureIncompatibleFirmware              0x63666966 
%define bmdSwitcherConnectToFailureCorruptData                       0x63666364 
%define bmdSwitcherConnectToFailureStateSync                         0x63667373 
%define bmdSwitcherConnectToFailureStateSyncTimedOut                 0x63667374 

;							    [le]     -[le]-[le]-[BE]-[BE] 
;CBMDSwitcherDiscovery		db "{BA726CE9-B8F5-4B1B-AA00-1A2DF3998B45}", 0 
;IBMDSwitcherDiscovery		db "{2CEFAB87-89E6-442F-A4F6-8FE63A50E17E}", 0 

CBMDSwitcherDiscovery		db 0xE9, 0x6C, 0x72, 0xBA, ; E96C72BA 
								db 0xF5, 0xB8, \
								0x1B, 0x4B, \
								0xAA, 0x00, \
								0x1A, 0x2D, 0xF3, 0x99, 0x8B, 0x45 
IBMDSwitcherDiscovery		db 0x87, 0xAB, 0xEF, 0x2C, \
								0xE6, 0x89, \
								0x2F, 0x44, \
								0xA4, 0xF6, \
								0x8F, 0xE6, 0x3A, 0x50, 0xE1, 0x7E 
IBMDSwitcherMixEffectBlockIterator db 0x3B, 0xDE, 0x0B, 0x93, ; B3DE0B93 
								db 0x78, 0x4A, \
								0xD0, 0x43, \
								0x8F, 0xD3, \
								0x6E, 0x82, 0xAB, 0xA0, 0xE1, 0x17 
IBMDSwitcherKeyIterator				db 0x73, 0x74, 0xC5, 0xEC, \
								0x93, 0x09, \
								0x4F, 0x44, \
								0xB3, 0xCF, \
								0xED, 0x59, 0x3C, 0xA2, 0x5B, 0x09 
IBMDSwitcherDownstreamKeyIterator	db 0x50, 0x87, 0x96, 0xF2, \
								0x9B, 0x70, \
								0xC8, 0x42, \
								0xB4, 0x50, \
								0x92, 0xCA, 0x2B, 0x06, 0x5D, 0x14 
IBMDSwitcherInputIterator	db 0x88, 0x98, 0x5E, 0x27, \
								0x65, 0x2F, \
								0x2E, 0x4B, \
								0x94, 0x34, \
								0x19, 0x37, 0xA7, 0x2B, 0x9E, 0xC4 
IBMDSwitcherInputAux		db 0xA8, 0x45, 0xC7, 0x52, \
								0xB1, 0x89, \
								0x9A, 0x44, \
								0xA1, 0x49, \
								0xC4, 0x3F, 0x51, 0x08, 0xDA, 0xE7 
IBMDSwitcherMediaPlayerIterator db 0x6F, 0x81, 0x10, 0xE9, \
								0xCB, 0x59, \
								0x24, 0x42, \
								0xA7, 0x7F, \
								0x06, 0xDE, 0x3D, 0x23, 0x22, 0x75 
IBMDSwitcherMediaPlayer			db 0x1F, 0x0E, 0x24, 0xB5, \
								0x0A, 0xCE, \
								0x38, 0x4C, \
								0x9F, 0xAB, \
								0xD7, 0xFA, 0xC2, 0x27, 0x20, 0x5A 
;; Done with UUIDs. 

;IBMDSwitcherMixEffectBlockIterator			db "{930BDE3B-4A78-43D0-8FD3-6E82ABA0E117}", 0 
;IBMDSwitcherKeyIterator						db "{ECC57473-0993-444F-B3CF-ED593CA25B09}", 0 

sGetKeyError1				db "Error getting mix effect block iterator. ", 13, 10, 0 
sGetKeyError2				db "Error using Next () on the mix effect block; cannot get first block. ", 13, 10, 0 
sGetKeyError3				db "Error getting key iterator for mix effect block. ", 13, 10, 0 
sGetKeyError4				db "Error using Next () on the key iterator; cannot get first key. ", 13, 10, 0 

mLastPowerStatus			dd 0 

idxPowerStatusMsgNum		dd 14 
sPowerStatusMsg				db "Power Status: ", 0 

section .text 

bm_init: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	;; Read IP address from a file: 
	mov ebx, ipAtem 
	xor ecx, ecx 
	.zero_ip: 
	imhere 
	mov byte [ebx+ecx], 0 
	inc ecx 
	cmp ecx, 16 ;; sizeof (ipAtem) 
	jl .zero_ip 
	
	.read_ip: 
	push dword 0x0 
	push dword ofstruct2 
	push dword sAtemIp 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__OpenFile@12] 
	%else 
		call [OpenFile] 
	%endif 
	mov [hAtemTxt], eax 
	
	test eax, eax 
	jz .ip_read_error 
	
	push dword 0 
	push dword szAtemIp 
	push dword 16 ;; Sizeof (ipAtem) 
	push dword ipAtem 
	push eax 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__ReadFile@20] 
	%else 
		call [ReadFile] 
	%endif 
	test eax, eax 
	jz .ip_read_error 
	
	;; Minimum IP size (x.x.x.x) = 7, so if less, then it's probably an error: 
	cmp dword [szAtemIp], 7 
	jl .ip_read_error 
	
	push dword [hAtemTxt] 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__CloseHandle@4] 
	%else 
		call [CloseHandle] 
	%endif 
	
	jmp .ip_read_ok 
	
	.ip_read_error: 
	push dword sCoError3 
	call log 
	
	mov eax, [hAtemTxt] 
	test eax, eax 
	jz .ip_read_error.no_need_to_close 
	
	push eax 
	%if DM_C_COMPATIBLE > 0 
		call [__imp__CloseHandle@4] 
	%else 
		call [CloseHandle] 
	%endif 
	
	.ip_read_error.no_need_to_close: 
	
	mov eax, 3 
	jmp .done 
	
	.ip_read_ok: 
	
	;; Log the IP address read from the file: 
	push dword ipAtem 
	call log 
	
	push dword sEndl 
	call log 
	
	%if INCLUDE_BLACKMAGIC_COM > 0 
		push dword 0 ;; Reserved parameter. Should be NULL. 
		%if DM_C_COMPATIBLE > 0 
			call [__imp__CoInitialize@4] 
		%else 
			call [CoInitialize] 
		%endif 
		test eax, eax 
		jns .co_init_ok ;; HRESULT 
		
		push dword sCoError1 
		call log 
		
		mov eax, 1 
		jmp .done 
		
		.co_init_ok: 
		imhere 
		
		push dword mSwitcherDiscovery 
		push dword IBMDSwitcherDiscovery 
		push dword CLSCTX_ALL 
		push dword 0 ;; NULL 
		push dword CBMDSwitcherDiscovery 
		%if DM_C_COMPATIBLE > 0 
			call [__imp__CoCreateInstance@20] 
		%else 
			call [CoCreateInstance] 
		%endif 
		debug_hex eax 
		debug_hex eax 
		test eax, eax 
		jns .co_create_ok ;; HRESULT 
		
		push dword sCoError2 
		call log 
		
		mov eax, 2 
		debug_dec eax 
		debug_hex eax 
		jmp .done 
		
		.co_create_ok: 
		
		imhere 
		
		;; Connect to the switcher: 
		mov ebx, lsIpAtem 
		mov edx, ipAtem 
		xor ecx, ecx 
		xor ax, ax 
		.make_bstr_ip_wchars: 
		mov al, [edx+ecx] 
		mov [ebx+ecx*2], ax 
		inc ecx 
		test al, al 
		jnz .make_bstr_ip_wchars 
		
		mov dword [ebp-4], 0 ;; Retry count. 
		
		.connect: 
		imhere 
		.make_bstr_ip_obj: 
		push dword lsIpAtem 
		%if DM_C_COMPATIBLE > 0 
			call [__imp__SysAllocString@4] 
		%else 
			call [SysAllocString] 
		%endif 
		mov [bstrIpAtem], eax 
		
		imhere 
		
		;; Arguments to ConnectTo (): 
		push dword mFailReason 
		push dword mSwitcher 
		push eax 
		
		;; Function call itself: 
		mov eax, [mSwitcherDiscovery] 
		mov ecx, eax ;; THIS pointer! 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+12] ;; ConnectTo () 
		push ecx ;; Arg0 
		call eax 
		mov [hrSwitcherConnect], eax 
		
		imhere 
		
		call .release_discovery 
		mov eax, [hrSwitcherConnect] 
		
		imhere 
		
		test eax, eax 
		jns .switcher_connect_ok 
		
		imhere 
		
		mov eax, [mFailReason] 
		cmp eax, bmdSwitcherConnectToFailureNoResponse 
		jz .switcher_connect.error4a 
		cmp eax, bmdSwitcherConnectToFailureIncompatibleFirmware 
		jz .switcher_connect.error4b 
		cmp eax, bmdSwitcherConnectToFailureCorruptData 
		jz .switcher_connect.error4c 
		cmp eax, bmdSwitcherConnectToFailureStateSync 
		jz .switcher_connect.error4d 
		cmp eax, bmdSwitcherConnectToFailureStateSyncTimedOut 
		jz .switcher_connect.error4e 
		mov ebx, sCoError4f 
		jmp .switcher_connect.log_error 
		
		.switcher_connect.error4a: 
			mov ebx, sCoError4a 
			jmp .switcher_connect.log_error 
		.switcher_connect.error4b: 
			mov ebx, sCoError4b 
			jmp .switcher_connect.log_error 
		.switcher_connect.error4c: 
			mov ebx, sCoError4c 
			jmp .switcher_connect.log_error 
		.switcher_connect.error4d: 
			mov ebx, sCoError4d 
			jmp .switcher_connect.log_error 
		.switcher_connect.error4e: 
			mov ebx, sCoError4e 
			push ebx 
			call log 
			
			push dword sCoError4e_tryingAgain 
			call log 
			
			push dword 500 
			%if DM_C_COMPATIBLE > 0 
				call [__imp__Sleep@4] 
			%else 
				call [Sleep] 
			%endif 
			
			imhere 
			
			cmp dword [ebp-4], 50 ;; 25 seconds (50 * 0.5 s) 
			jng .switcher_connect.retry_now 
			
			imhere 
			
			push dword sCoError4e_maxRetryReached 
			call log 
			
			call close_app 
			
			imhere 
			
			jmp .done 
		.switcher_connect.retry_now: 
			inc dword [ebp-4] ;; Retry count. 
			
			jmp .connect ;; Try again. 
		.switcher_connect.log_error: 
			push ebx 
			call log 
			mov eax, 4 
			jmp .done 
		.switcher_connect_ok: 
		
		imhere 
		
		
		
		jmp .done_connecting 
		.release_discovery: 
			imhere 
			mov ecx, [mSwitcherDiscovery] ;; THIS pointer. 
			test ecx, ecx 
			jz .release_discovery.done 
			mov eax, [ecx] ;; VTable. 
			push ecx ;; Arg0 
			call [eax+8] ;; Release () 
			.release_discovery.done: 
			imhere 
			ret 
	%else 
		xor eax, eax 
		jmp .done 
	%endif 
	
	.done_connecting: 
	
	push dword sCoInitOk 
	call log 
	
	xor eax, eax ;; Returns 0 if success. 
	.done: 
	debug_dec eax 
	mov esp, ebp 
	pop ebp 
ret 

bm_close: 
	%if INCLUDE_BLACKMAGIC_COM > 0 
		imhere 
		
		mov eax, [mSwitcher] 
		mov ecx, eax ;; THIS pointer! 
		test eax, eax 
		jz .skip_release_switcher 
		
		imhere 
		
		mov eax, [eax] ;; Get VTable. 
		mov eax, [eax+8] ;; IUnknown->Release (); 
		push ecx ;; Arg0 
		call eax 
		
		.skip_release_switcher: 
		imhere 
		
	%endif 
	
	xor eax, eax ;; Returns 0 if success. 
	mov [mSwitcher], eax ;; Clear the mSwitcher pointer. 
	.done: 
ret 

bm_restart: 
	call bm_close 
	call bm_init 
ret 

bm_check: 
	push ebp 
	mov ebp, esp 
	sub esp, 72 
	;; Procedure: 
	
	imhere 
	call touch_key1 
	test eax, eax 
	jz .yes_restart 
	.all_ok: 
	imhere 
	.compare_last_status: 
	mov eax, [ebp-4] 
	cmp eax, [mLastPowerStatus] 
	jz .last_status_same 
		imhere 
		
		;; Power status: 
		debug_hex [ebp-4] 
		
		mov eax, [ebp-4] 
		mov [mLastPowerStatus], eax 
	.last_status_same: 
	imhere 
	xor eax, eax 
	jmp .done 
	.yes_restart: 
		imhere 
		
		push dword sAttemptingRestart 
		call log 
		
		call bm_restart 
		mov [ebp-4], eax ;; Result. 
		imhere 
		test eax, eax 
		jz .restart_ok 
			imhere 
			
			push dword sRestartFailed 
			jmp .print_restart_msg 
		.restart_ok: 
			imhere 
			push dword sRestartSuccess 
		.print_restart_msg: 
		call log 
		
		mov eax, [ebp-4] ;; Result. 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 


bm_get_key: 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	;; Procedure: 
	imhere 
	call bm_get_mix_block 
	debug_hex eax 
	mov [ebp-4], eax 
	
	imhere 
	
	;; Mix block: 
	debug_hex [ebp-4] 
	
	mov eax, [ebp-4] 
	debug_hex eax 
	test eax, eax 
	jz .done 
		imhere 
		
		push eax 
		call bm_get_key@4 
		mov [ebp-8], eax 
		
		imhere 
		
		call .close 
		
		imhere 
		
		mov eax, [ebp-8] 
		jmp .done 
	.close: 
		imhere 
		;; Free the block, and exit: 
		mov eax, [ebp-4] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		imhere 
		
		ret 
	.done: 
	imhere 
	debug_dec eax 
	mov esp, ebp 
	pop ebp 
ret 

bm_get_key@4: 
	push ebp 
	mov ebp, esp 
	sub esp, 12 
	;; Procedure: 
	imhere 
	mov eax, [ebp+8] 
	debug_hex eax 
	debug_dec eax 
	test eax, eax 
	jz .done 
		imhere 
		
		mov ecx, eax ;; THIS pointer. 
		mov [ebp-4], eax 
		
		debug_hex eax 
		
		;; Arguments: 
		lea ebx, [ebp-8] 
		push ebx 
		push dword IBMDSwitcherKeyIterator 
		
		;; Call: 
		mov eax, [eax] ;; VTable. 
		debug_hex eax 
		mov eax, [eax+12] ;; CreateIterator () 
		debug_hex eax 
		push ecx ;; Arg0 
		call eax 
		debug_hex eax 
		test eax, eax 
		jns .get_keyit_ok 
			imhere 
			
			debug_hex eax 
			
			;; Print an error message: 
			push dword sGetKeyError3 
			call log 
			
			xor eax, eax 
			jmp .done 
		.get_keyit_ok: 
		
		imhere 
		
		lea ebx, [ebp-12] 
		push ebx 
		mov eax, [ebp-8] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+12] ;; Next () 
		push ecx ;; Arg0 
		call eax 
		imhere 
		test eax, eax 
		jns .get_key_ok 
			imhere 
			
			debug_hex eax 
			
			call .free_stuff 
			
			xor eax, eax 
			jmp .done 
			
		.get_key_ok: 
		
		imhere 
		
		call .free_stuff 
		
		mov eax, [ebp-12] 
		jmp .done 
		
		.free_stuff: 
			;; Free the key iterator: 
			mov eax, [ebp-8] 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [eax] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
			
			ret 
	.done: 
	imhere 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_get_downstream_key@0: 
_bm_get_downstream_key@0: 
	push ebp 
	mov ebp, esp 
	sub esp, 12 
	save 
	;; Procedure: 
	imhere 
	mov eax, [mSwitcher] 
	debug_hex eax 
	debug_dec eax 
	test eax, eax 
	jz .done 
		imhere 
		
		mov ecx, eax ;; THIS pointer. 
		mov [ebp-4], eax 
		
		debug_hex eax 
		
		;; Arguments: 
		lea ebx, [ebp-8] 
		push ebx 
		push dword IBMDSwitcherDownstreamKeyIterator 
		
		;; Call: 
		mov eax, [eax] ;; VTable. 
		debug_hex eax 
		mov eax, [eax+72] ;; CreateIterator () 
		debug_hex eax 
		push ecx ;; Arg0 
		call eax 
		debug_hex eax 
		test eax, eax 
		jns .get_keyit_ok 
			imhere 
			
			debug_hex eax 
			
			;; Print an error message: 
			push dword sGetKeyError3 
			call log 
			
			xor eax, eax 
			jmp .done 
		.get_keyit_ok: 
		
		debug_hex dword [ebp-8] 
		
		imhere 
		
		lea ebx, [ebp-12] 
		push ebx 
		mov eax, [ebp-8] 
		debug_hex eax 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		debug_hex eax 
		mov eax, [eax+12] ;; Next () 
		debug_hex eax 
		push ecx ;; Arg0 
		call eax 
		imhere 
		test eax, eax 
		jns .get_key_ok 
			imhere 
			
			debug_hex eax 
			
			call .free_stuff 
			
			xor eax, eax 
			jmp .done 
			
		.get_key_ok: 
		
		imhere 
		
		call .free_stuff 
		
		mov eax, [ebp-12] 
		jmp .done 
		
		.free_stuff: 
			;; Free the key iterator: 
			mov eax, [ebp-8] 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [eax] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
			
			ret 
	.done: 
	restore 
	imhere 
	debug_hex eax 
	mov esp, ebp 
	pop ebp 
ret 0 

bm_dsk_get_on_air: 
_bm_dsk_get_on_air@4: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	save 
	
	xor eax, eax 
	mov [ebp-4], eax 
	
	imhere 
	
	mov eax, [ebp+8] 
	debug_hex eax 
	mov ecx, eax 
	mov eax, [eax] 
	debug_hex eax 
	lea ebx, [ebp-4] 
	push ebx 
	push ecx 
	debug_hex dword [eax+52] 
	call dword [eax+52] ;; GetOnAir () 
	
	;; Use the following type of code to check for errors: 
	; test eax, eax 
	; jns .ok 
		
		
	; .ok: 
	;; We just return a BOOL here though, no error codes, so we'll just return FALSE if the API was not successful ... 
	
	imhere 
	
	restore 
	
	mov eax, [ebp-4] 
	
	mov esp, ebp 
	pop ebp 
ret 4 

bm_dsk_set_on_air: 
_bm_dsk_set_on_air@8: 
	push ebp 
	mov ebp, esp 
	save 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	push dword [ebp+12] 
	mov eax, [eax] 
	push ecx 
	call dword [eax+56] ;; SetOnAir () 
	
	delay 10 
	
	restore 
	mov esp, ebp 
	pop ebp 
ret 8 

bm_dsk_perform_auto_transition: ;; Returns HRESULT from PerformAutoTransition () 
_bm_dsk_perform_auto_transition@4: 
	push ebp 
	mov ebp, esp 
	save 
	
	imhere 
	
	; xor edx, edx 
	
	; .loop: 
	; cmp edx, 1024 
	; jnl .end_loop 
	
	mov eax, [ebp+8] 
	debug_hex eax 
	mov ecx, eax 
	mov eax, [eax] 
	debug_hex eax 
	push ecx 
	call dword [eax+60] ;; PerformAutoTransition () 
	
	delay 40 
	
	; push dword [ebp+8] 
	; call bm_dsk_get_frames_remaining 
	; cmp eax, 30 
	; jl .end_loop 
	
	; inc edx 
	; jmp .loop 
	; .end_loop: 
	
	restore 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_dsk_is_transitioning: 
_bm_dsk_is_transitioning@4: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	save 
	
	xor eax, eax 
	mov [ebp-4], eax 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	lea ebx, [ebp-4] 
	push ebx 
	mov eax, [eax] 
	push ecx 
	call dword [eax+64] ;; IsTransitioning () 
	
	mov eax, [ebp-4] 
	restore 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_dsk_is_auto_transitioning: 
_bm_dsk_is_auto_transitioning@4: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	save 
	
	xor eax, eax 
	mov [ebp-4], eax 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	lea ebx, [ebp-4] 
	push ebx 
	mov eax, [eax] 
	push ecx 
	call dword [eax+68] ;; IsAutoTransitioning () 
	
	mov eax, [ebp-4] 
	restore 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_dsk_get_frames_remaining: 
_bm_dsk_get_frames_remaining@4: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	save 
	
	xor eax, eax 
	mov [ebp-4], eax 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	lea ebx, [ebp-4] 
	push ebx 
	mov eax, [eax] 
	push ecx 
	call dword [eax+72] ;; GetFramesRemaining () 
	
	mov eax, [ebp-4] 
	restore 
	mov esp, ebp 
	pop ebp 
ret 4 

bm_dsk_init_for_dark_overlay: 
_bm_dsk_init_for_dark_overlay@20: 
	push ebp 
	mov ebp, esp 
	sub esp, 4 
	save 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	push dword [ebp+24] ;; Input source high dword 
	push dword [ebp+20] ;; Input source low dword 
	mov eax, [eax] 
	push ecx 
	call dword [eax+16] ;; SetInputCut () 
	
	delay 10 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	push dword [ebp+16] ;; Source high dword 
	push dword [ebp+12] ;; Source low dword 
	mov eax, [eax] 
	push ecx 
	call dword [eax+24] ;; SetInputFill () 
	
	delay 10 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	movsd xmm0, qword [DARK_OVERLAY_CLIP] 
	sub esp, 8 
	movsd qword [esp], xmm0 
	mov eax, [eax] 
	push ecx 
	call dword [eax+88] ;; SetClip () 
	
	delay 10 
	
	mov eax, [ebp+8] 
	mov ecx, eax 
	movsd xmm0, qword [DARK_OVERLAY_GAIN] 
	sub esp, 8 
	movsd qword [esp], xmm0 
	mov eax, [eax] 
	push ecx 
	call dword [eax+96] ;; SetGain () 
	
	delay 10 
	
	restore 
	mov esp, ebp 
	pop ebp 
ret 20 

bm_get_mix_block: 
	push ebp 
	mov ebp, esp 
	sub esp, 8 
	%if INCLUDE_BLACKMAGIC_COM > 0 
		imhere 
		
		.get_switcher: 
		imhere 
		mov eax, [mSwitcher] 
		mov ecx, eax ;; THIS pointer! 
		test eax, eax 
		jnz .got_switcher_ok 
			imhere 
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If successful, then go get the switcher again. 
			xor eax, eax ;; return nullptr 
			jmp .done 
		.got_switcher_ok: 
		
		imhere 
		
		;; Arguments: 
		lea ebx, [ebp-4] 
		push ebx 
		push dword IBMDSwitcherMixEffectBlockIterator 
		
		debug_hex eax 
		
		;; Call: 
		mov eax, [eax] ;; Get VTable. 
		mov eax, [eax+72] ;; Switcher->CreateIterator () 
		push ecx ;; Arg0 
		call eax 
		
		imhere 
		
		test eax, eax 
		jns .get_mebi_ok 
			imhere 
			
			debug_hex eax 
			
			push dword sGetKeyError1 
			call log 
			
			imhere 
			
			call bm_restart 
			test eax, eax 
			jz .get_switcher ;; If restart was successful, then try again. 
			
			xor eax, eax 
			jmp .done 
			
		.get_mebi_ok: 
		imhere 
		
		lea ebx, [ebp-8] 
		push ebx 
		mov eax, [ebp-4] 
		imhere 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		imhere 
		mov eax, [eax+12] 
		imhere 
		push ecx ;; Arg0 
		call eax 
		
		debug_hex eax 
		debug_hex [ebp-8] 
		
		test eax, eax 
		jns .get_first_block_ok 
			imhere 
			
			debug_hex eax 
			
			mov eax, [ebp-4] 
			mov ecx, eax ;; THIS pointer. 
			mov eax, [eax] ;; VTable. 
			mov eax, [eax+8] ;; Release () 
			push ecx ;; Arg0 
			call eax 
			
			imhere 
			
			push dword sGetKeyError2 
			call log 
			xor eax, eax 
			jmp .done 
			
		.get_first_block_ok: 
		
		imhere 
		
		mov eax, [ebp-4] 
		mov ecx, eax ;; THIS pointer. 
		mov eax, [eax] ;; VTable. 
		mov eax, [eax+8] ;; Release () 
		push ecx ;; Arg0 
		call eax 
		
		imhere 
		
		;; Return the mix effect block in EAX: 
		mov eax, [ebp-8] 
		
	%endif 
	
	.done: 
	debug_hex eax 
	mov esp, ebp 
	pop ebp 
ret 

bm_free: 
_bm_free@4: 
	mov eax, [esp+4] 
	save 
	test eax, eax 
	jz .done 
	mov ecx, eax 
	mov eax, [ecx] ;; VTable. 
	push ecx ;; Arg0 
	call [eax+8] ;; Release () 
	.done: 
	restore 
ret 4 


section .data 

;typedef [v1_enum] enum	_BMDSwitcherMixEffectBlockPropertyId {
%define bmdSwitcherMixEffectBlockPropertyIdProgramInput              0x70676970 ;	// Int type (BMDSwitcherInputId), Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdPreviewInput              0x70766970 ;	// Int type (BMDSwitcherInputId), Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdTransitionPosition        0x74737073 ;	// Float type, Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdTransitionFramesRemaining 0x7466726D ;	// Int type, Get only
%define bmdSwitcherMixEffectBlockPropertyIdInTransition              0x69697473 ;	// Flag type, Get only
%define bmdSwitcherMixEffectBlockPropertyIdFadeToBlackFramesRemaining 0x6666726D ;	// Int type, Get only
%define bmdSwitcherMixEffectBlockPropertyIdInFadeToBlack             0x69696662 ;	// Flag type, Get only
%define bmdSwitcherMixEffectBlockPropertyIdPreviewLive               0x70766C76 ;	// Flag type, Get only
%define bmdSwitcherMixEffectBlockPropertyIdPreviewTransition         0x70767473 ;	// Flag type, Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdInputAvailabilityMask     0x6961766D ;	// Int type (BMDSwitcherInputAvailability), Get only
%define bmdSwitcherMixEffectBlockPropertyIdFadeToBlackRate           0x66746272 ;	// Int type, Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdFadeToBlackFullyBlack     0x66746262 ;	// Flag type, Get/Set
%define bmdSwitcherMixEffectBlockPropertyIdFadeToBlackInTransition   0x66746274 ;	// Flag type, Get only
;} BMDSwitcherMixEffectBlockPropertyId;

section .text 






section .data 
iExitCode			dd 0 
iAppDone			dd 0 
uiHotkeyId1			dd 137 
uiHotkeyId1_ctrl	dd 136 
uiHotkeyId1b		dd 147 
uiHotkeyId1c		dd 157 
uiHotkeyId2			dd 138 
uiHotkeyId2_ctrl	dd 135 
uiHotkeyId3			dd 139 
uiHotkeyId3_ctrl	dd 134 
uiHotkeyId4a		dd 141 
uiHotkeyId4b		dd 142 
uiHotkeyId4c		dd 143 
uiHotkeyId4d		dd 144 
uiHotkeyId5a		dd 145 
uiHotkeyId5b		dd 146 
uiHotkeyIdE			dd 150 
sFilenameLog		db "VideoKeyer-log.txt", 0 
lStarted			db "Application started. ", 13, 10, 0 
lStopping			db "Exiting application. ", 13, 10, 0 
lMsgClose			db "WM_CLOSE message received. ", 13, 10, 0 
lHkReceived			db "Hotkey received. ", 13, 10, 0 
lH1Received			db "Hotkey means to do task 1. ", 13, 10, 0 
lH1BReceived		db "Hotkey means to do task 1B. ", 13, 10, 0 
lH2Received			db "Hotkey means to do task 2. ", 13, 10, 0 
lH3Received			db "Hotkey means to do task 3. ", 13, 10, 0 
lExReceived			db "Hotkey means to exit. ", 13, 10, 0 

lH1Processed		db "Task 1 started. ", 13, 10, 0 
lH1bProcessed		db "Task 1B started. ", 13, 10, 0 
lH2Processed		db "Task 2 started. ", 13, 10, 0 
lH3ProcessedT		db "Task 3 done. Success: TRUE; ", 13, 10, 0 
lH3ProcessedF		db "Task 3 done. Success: FALSE; ", 13, 10, 0 

lH1BMEnabled		db "Hotkey 1: BlackMagic code enabled. ", 13, 10, 0 
lAnPStep			db "Animation progress: stepping ... ", 13, 10, 0 
lAnPDone			db "Animation progress: done. ", 13, 10, 0 
sMsgAnimationCanceledBecauseNoSwitcher: 
db "Animation canceled because the switcher connection failed. ", 13, 10, 0 

sAttemptingRestart	db "Cannot access switcher. Attempting to restart the Switcher connection ... ", 13, 10, 0 
sRestartSuccess		db "Switcher connection restart successful. ", 13, 10, 0 
sRestartFailed		db "Switcher connection restart failed. ", 13, 10, 0 

sLogIntPrefix		db "Logging Integer: ", 0 
sEndl				db 13, 10, 0 

sLogKeyReturned		db "Key returned: ", 0 
sLogVTable			db "VTable: ", 0 

sLogMixBlockReturned db "MixBlock returned: ", 0 

sLogKeyLive			db "Key live: ", 0 

sLogCheckOK			db "Checked OK. ", 13, 10, 0 

sLogProjectorChange	db "Projector change. ", 13, 10, 0 
sLogProjectorCode	db "Projector code! ", 13, 10, 0 

iAnimationStarted	dd 0 
iAnimationLength	dd 1000 
iAnimationDone		dd 1 
iAnimationType		dd 0 ;; Type. Use 1 for wipe left->right to ON; 0 for wipe left<-right to OFF; more to come later. 
;; More types: 2 -> fade ON; 3 -> fade OFF; 
iToggleKey			dd 0 
iNeedProjectors		dd -1 

;; TODO: Store PREVIEW and states of keys 2-4 while a fade plays. 

msg: 
.hwnd dd 0 
.message dd 0 
.wParam dd 0 
.lParam dd 0 
.time dd 0 
.pt.x dd 0 
.pt.y dd 0 

myInput: 
.inputType dd INPUT_KEYBOARD 
.ki.wVk dw VK_ESCAPE 
.ki.wScan dw 0 
.ki.dwFlags dd 0 
.ki.time dd 0 
.ki.dwExtraInfo dd 0 

myInputSize dd 7 * 4 ;; sizeof (INPUT) --> largest possible size, since it has a 'union' in it. 


mImageName							db "Ruvims-VideoKeyer.exe", 0 
mInstanceIsARestartOfTheApp			dd 0 ;; Tells whether "VideoKeyer.exe" has already been running when this instance has been opened. 



section .bss 
hLog				resd 1 
hThread				resd 1 

ofstruct			resb 136 
ofstruct2			resb 136 

ipAtem				resb 16 
lsIpAtem			resw 16 
bstrIpAtem			resd 1 

