#include <windows.h> 
#include <winsock.h> 

#include <string.h> 

#ifndef DEBUG 
#define DEBUG 0 
#endif 

#if DEBUG 
#include <stdio.h> 
#endif 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

// Tutorial: 
// https://msdn.microsoft.com/en-us/library/windows/desktop/ff381409(v=vs.85).aspx 

LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam); 

BOOL isRunning = 0; 

HINSTANCE hInstance; 

#ifndef LR_LOADFROMFILE 
	#define LR_LOADFROMFILE 0x10 
#endif 

#define nullptr NULL 
typedef unsigned char uint8_t; 

DWORD WINAPI ServerThread (LPVOID lpParam); 
DWORD WINAPI ServeClientThread (LPVOID lpParam); 

long long aux_outputs [3] = {0}; 
long long i_program = 0; 
long long i_preview = 0; 
BOOL i_transition = FALSE; 

void registerHotkeys (); 
void unregisterHotkeys (); 

DWORD WINAPI changeAux12 (LPVOID lpParam); 
DWORD WINAPI changeAux3 (LPVOID lpParam); 
DWORD WINAPI changeMP1 (LPVOID lpParam); 


#define ID_MP1 17 
#define ID_MP2 18 
#define ID_BLK 19 
#define ID_COL1 20 
#define ID_BARS 21 
#define ID_RECORD_TWO 22 
#define ID_RECORD_FOUR 23 
#define ID_RECORD_FIVE 24 
#define ID_RECORD_PROG 25 
#define ID_RECORD_CLEAN 26 
#define ID_AUX_FREEZE 27 
#define ID_AUX_PC 28 
#define ID_AUX_PG 29 
#define ID_AUX_M1 30 
#define ID_AUX_M2 31 
#define ID_MAKE_WELCOME 32 
#define ID_MAKE_GOODBYE 33 
#define ID_DSK_1 35 
#define ID_PERFORM_CUT 38 
#define ID_PERFORM_AUTO 39 
#define ID_EMERGENCY_RETURN 40 
#define ID_PREVIEW_1 41 
#define ID_PREVIEW_2 42 
#define ID_PREVIEW_3 43 
#define ID_PREVIEW_4 44 
#define ID_PREVIEW_5 45 
#define ID_PREVIEW_6 46 
#define ID_PREVIEW_7 47 
#define ID_PREVIEW_8 48 
#define ID_PREVIEW_9 49 
#define ID_PREVIEW_10 50 
#define ID_NUM_PREVIEW_1 51 
#define ID_NUM_PREVIEW_2 52 
#define ID_NUM_PREVIEW_3 53 
#define ID_NUM_PREVIEW_4 54 
#define ID_NUM_PREVIEW_5 55 
#define ID_NUM_PREVIEW_6 56 
#define ID_NUM_PREVIEW_7 57 
#define ID_NUM_PREVIEW_8 58 
#define ID_NUM_PREVIEW_9 59 
#define ID_NUM_PREVIEW_10 60 
#define ID_TOGGLE_HOTKEYS 81 
void registerHotkeys () { 
	RegisterHotKey (NULL, ID_MP1, MOD_NOREPEAT, 'J'); 
	RegisterHotKey (NULL, ID_MP2, MOD_NOREPEAT, 'K'); 
	RegisterHotKey (NULL, ID_BLK, MOD_NOREPEAT, 'D'); 
	RegisterHotKey (NULL, ID_COL1, MOD_NOREPEAT, 'R'); 
	RegisterHotKey (NULL, ID_BARS, MOD_NOREPEAT, 'A'); 
	RegisterHotKey (NULL, ID_RECORD_TWO, MOD_NOREPEAT, 'T'); 
	RegisterHotKey (NULL, ID_RECORD_FOUR, MOD_NOREPEAT, 'F'); 
	RegisterHotKey (NULL, ID_RECORD_FIVE, MOD_NOREPEAT, 'V'); 
	RegisterHotKey (NULL, ID_RECORD_PROG, MOD_NOREPEAT, 'G'); 
	RegisterHotKey (NULL, ID_RECORD_CLEAN, MOD_NOREPEAT, 'H'); 
	RegisterHotKey (NULL, ID_AUX_FREEZE, MOD_NOREPEAT, 'Y'); 
	RegisterHotKey (NULL, ID_AUX_PC, MOD_NOREPEAT, 'U'); 
	RegisterHotKey (NULL, ID_AUX_PG, MOD_NOREPEAT, 'I'); 
	RegisterHotKey (NULL, ID_AUX_M1, MOD_NOREPEAT, 'O'); 
	RegisterHotKey (NULL, ID_AUX_M2, MOD_NOREPEAT, 'P'); 
	RegisterHotKey (NULL, ID_MAKE_WELCOME, MOD_NOREPEAT, 'W'); 
	RegisterHotKey (NULL, ID_MAKE_GOODBYE, MOD_NOREPEAT, 'S'); 
	RegisterHotKey (NULL, ID_DSK_1, MOD_NOREPEAT, VK_F8); // VK_OEM_4 is [ key for US keyboard. Also see VK_OEM_6 for ] key. 
	RegisterHotKey (NULL, ID_PERFORM_CUT, MOD_NOREPEAT, VK_SPACE); 
	RegisterHotKey (NULL, ID_PERFORM_AUTO, MOD_NOREPEAT, VK_RETURN); 
	RegisterHotKey (NULL, ID_EMERGENCY_RETURN, MOD_NOREPEAT, VK_ESCAPE); 
	size_t i; 
	for (i = ID_PREVIEW_1; i <= ID_PREVIEW_10; i++) 
		RegisterHotKey (NULL, i, MOD_NOREPEAT, i == ID_PREVIEW_10 ? '0' : ('1' + i - ID_PREVIEW_1)); 
	for (i = ID_NUM_PREVIEW_1; i <= ID_NUM_PREVIEW_10; i++) 
		RegisterHotKey (NULL, i, MOD_NOREPEAT, i == ID_NUM_PREVIEW_10 ? VK_NUMPAD0 : (VK_NUMPAD1 + i - ID_NUM_PREVIEW_1)); 
} 
void unregisterHotkeys () { 
	UnregisterHotKey (NULL, ID_MP1); 
	UnregisterHotKey (NULL, ID_MP2); 
	UnregisterHotKey (NULL, ID_BLK); 
	UnregisterHotKey (NULL, ID_COL1); 
	UnregisterHotKey (NULL, ID_BARS); 
	UnregisterHotKey (NULL, ID_RECORD_TWO); 
	UnregisterHotKey (NULL, ID_RECORD_FOUR); 
	UnregisterHotKey (NULL, ID_RECORD_FIVE); 
	UnregisterHotKey (NULL, ID_RECORD_PROG); 
	UnregisterHotKey (NULL, ID_RECORD_CLEAN); 
	UnregisterHotKey (NULL, ID_AUX_FREEZE); 
	UnregisterHotKey (NULL, ID_AUX_PC); 
	UnregisterHotKey (NULL, ID_AUX_PG); 
	UnregisterHotKey (NULL, ID_AUX_M1); 
	UnregisterHotKey (NULL, ID_AUX_M2); 
	UnregisterHotKey (NULL, ID_MAKE_WELCOME); 
	UnregisterHotKey (NULL, ID_MAKE_GOODBYE); 
	UnregisterHotKey (NULL, ID_DSK_1); 
	UnregisterHotKey (NULL, ID_PERFORM_CUT); 
	UnregisterHotKey (NULL, ID_PERFORM_AUTO); 
	UnregisterHotKey (NULL, ID_EMERGENCY_RETURN); 
	size_t i; 
	for (i = ID_PREVIEW_1; i <= ID_PREVIEW_10; i++) 
		UnregisterHotKey (NULL, i); 
	for (i = ID_NUM_PREVIEW_1; i <= ID_NUM_PREVIEW_10; i++) 
		UnregisterHotKey (NULL, i); 
} 
void registerAlwaysOnHotkeys () { 
	RegisterHotKey (NULL, ID_TOGGLE_HOTKEYS, MOD_NOREPEAT | MOD_CONTROL | MOD_ALT, 'H'); 
} 
void unregisterAlwaysOnHotkeys () { 
	UnregisterHotKey (NULL, ID_TOGGLE_HOTKEYS); 
} 

DWORD enableTimer () { 
	return SetTimer (NULL, 0, 100, (void *) NULL); 
} 
void disableTimer (DWORD timerId) { 
	KillTimer (NULL, timerId); 
} 

BOOL shouldHotkeysBeOn (const char * current_foreground_window_title) { 
	const char * title = current_foreground_window_title; 
	return (title[0] == 'A' && title[1] == 'T' && title[2] == 'E' && title[3] == 'M') || 
		(title[0] == 'O' && title[1] == 'B' && title[2] == 'S' && title[3] == ' '); 
} 


BOOL scrollBackwards = FALSE; 
BOOL nowScrolling = FALSE; 


SOCKET serverSocket; 
BOOL wsaReady = FALSE; 



int main (int argc, char * argv []) { 
	// BOOL isRestart = killProcessByName ("BlackMagic-AuxMonitor.exe", FALSE); 
	BOOL isRestart = killProcessByName ("BlackMagic-HotkeysAndMonitor.exe", FALSE); 
	const char * procName = "ATEM Software Control.exe"; 
	const char * atemPath = "C:\\Program Files (x86)\\Blackmagic Design\\Blackmagic ATEM Switchers\\ATEM Software Control\\ATEM Software Control.exe"; 
	const char * cwdPath = "C:\\Program Files (x86)\\Blackmagic Design\\Blackmagic ATEM Switchers\\ATEM Software Control\\"; 
	STARTUPINFO atemStartInfo; 
	for (unsigned int i = 0; i < sizeof (STARTUPINFO); i++) 
		((char *)(&atemStartInfo)) [i] = 0; 
	atemStartInfo.cb = sizeof (STARTUPINFO); 
	PROCESS_INFORMATION atemProcInfo; 
	if (!killProcessByName (procName, TRUE) && // <-- checks if ATEM is already started. 
			!CreateProcess (atemPath, (char *) NULL, NULL, NULL, FALSE, 0, NULL, cwdPath, &atemStartInfo, &atemProcInfo)) { 
		DWORD lastError = GetLastError (); 
		print ("Error starting ATEM switcher. \r\nLast error: "); 
		printHex (lastError); 
		print ("\r\n"); 
	} 
	ruvim_init ("AuxMonitor-log.txt", 0); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	MSG msg; 
	long long input = 0; 
	unsigned long output = 0; // 0 = PGM, 1 = AUX1&2; 
	BOOL keepRunning = TRUE; 
	BOOL hkRegistered = FALSE; 
	BOOL alwaysOnRegistered = FALSE; 
	BOOL hkTurnedOn = TRUE; 
	DWORD timer = enableTimer (); 
	if (!timer) { 
		DWORD lastError = GetLastError (); 
		printf ("Error creating a timer. Last error: %d\n", lastError); 
	} else { 
		#ifdef DEBUG 
			#if DEBUG > 0 
				printf ("Timer registered: %d\n", timer); 
			#endif 
		#endif 
	} 
	isRunning = 1; 
	HANDLE hServerThread = CreateThread (NULL, 0, ServerThread, nullptr, 0, NULL); 
	hInstance = GetModuleHandle (NULL); 
	WNDCLASSEX wc; 
	ZeroMemory (&wc, sizeof (wc)); 
	wc.cbSize = sizeof (wc); 
	wc.lpfnWndProc = WindowProc; 
	wc.hInstance = hInstance; 
	wc.lpszClassName = "BlackMagic-AuxMonitor-WndClass"; 
	wc.hIcon = LoadIcon (NULL, IDI_APPLICATION); 
	wc.hIconSm = wc.hIcon; 
	wc.hCursor = LoadCursor (NULL, IDC_ARROW); 
	wc.hbrBackground = (HBRUSH) (COLOR_WINDOW + 1); 
	RegisterClassEx (&wc); 
	RECT taskbarRect; 
	HWND taskbarWnd = FindWindow ("Shell_traywnd", NULL); 
	DWORD needX = CW_USEDEFAULT; 
	DWORD needY = CW_USEDEFAULT; 
	if (taskbarWnd && GetWindowRect (taskbarWnd, &taskbarRect)) { 
		if (taskbarRect.right > 320 && taskbarRect.top > 250) { 
			needX = 0; //taskbarRect.right - 320; 
			needY = taskbarRect.top - 250; 
		} 
	} 
	HWND hWindow = CreateWindowEx (0, // Window styles. 
		wc.lpszClassName, 
		"ATEM Hotkeys, Monitor, & Tally", 
		WS_OVERLAPPEDWINDOW | WS_VSCROLL, 
		needX, needY, 380, 250, 
		NULL, // Parent 
		NULL, // Menu 
		wc.hInstance, 
		NULL // Additional application data 
	); 
	SetScrollRange (hWindow, SB_VERT, 0, 100, TRUE); 
	ShowWindow (hWindow, SW_SHOWDEFAULT); 
	UpdateWindow (hWindow); 
	// Set window as always on top: 
	SetWindowPos (hWindow, 
		HWND_TOPMOST, 
		needX, 
		needY, 
		380, 
		250, 
		SWP_SHOWWINDOW); 
	while (isRunning && GetMessageA (&msg, 0, 0, 0)) { 
		switch (msg.message) { 
			case WM_CLOSE: 
				keepRunning = FALSE; 
				if (wsaReady) { 
					wsaReady = FALSE; 
					WSACleanup (); 
				} 
				break; 
			case WM_TIMER: 
				if (msg.wParam == timer) { 
					// Task: see if the aux outputs' state changed or not. 
					// If changed, redraw the window. 
					if (!bm_check ()) { // Reconnect to the switcher if we did get disconnected ... 
						BOOL changed = 0; 
						for (size_t i = 0; i < 3; i++) { 
							long long prev = aux_outputs[i]; 
							aux_outputs[i] = bm_get_aux_output (i); 
							changed |= aux_outputs[i] != prev; 
						} 
						long long old_pgm = i_program; 
						long long old_pvw = i_preview; 
						BOOL old_transition = i_transition; 
						bm_get_program_input (&i_program); 
						bm_get_preview_input (&i_preview); 
						i_transition = bm_is_in_transition (); 
						if (old_pvw == i_program) { 
							// Program and preview were swapped. 
							scrollBackwards = !scrollBackwards; 
							#if DEBUG 
								printf ("Program is now previous preview value; toggling scrollBackwards flag; it is now: %d\n", scrollBackwards); 
							#endif 
						} 
						changed |= old_pgm != i_program || old_pvw != i_preview || old_transition != i_transition; 
						if (!nowScrolling) { 
							double transitionPosition = 0; 
							bm_get_transition_position (&transitionPosition); 
							unsigned short vbar_position = (unsigned short) (transitionPosition * 100); 
							if (scrollBackwards) 
								vbar_position = 100 - vbar_position; 
							SetScrollPos (hWindow, SB_VERT, vbar_position, TRUE); 
							ShowScrollBar (hWindow, SB_VERT, TRUE); 
							UpdateWindow (hWindow); 
						} 
						if (changed) 
							InvalidateRect (hWindow, NULL, 1); 
					} else { 
						BOOL changed = 0; 
						for (size_t i = 0; i < 3; i++) { 
							long long prev = aux_outputs[i]; 
							aux_outputs[i] = -1; 
							changed |= aux_outputs[i] != prev; 
						} 
						long long old_pgm = i_program; 
						long long old_pvw = i_preview; 
						BOOL old_transition = i_transition; 
						i_program = i_preview = 0; 
						i_transition = FALSE; 
						changed |= old_pgm != i_program || old_pvw != i_preview || old_transition != i_transition; 
						if (changed) 
							InvalidateRect (hWindow, NULL, 1); 
					} 
					// Do the hotkeys check: 
					HWND hWnd = GetForegroundWindow (); 
					if (hWnd) { 
						char string1 [512]; 
						if (GetWindowText (hWnd, string1, 511) && 
							shouldHotkeysBeOn (string1)) { 
							// ATEM! 
							if (!hkRegistered && hkTurnedOn) { 
								registerHotkeys (); 
								hkRegistered = TRUE; 
							} 
							if (!alwaysOnRegistered) { 
								registerAlwaysOnHotkeys (); 
								alwaysOnRegistered = TRUE; 
							} 
						} else { 
							if (hkRegistered) { 
								#ifdef DEBUG 
									#if DEBUG > 0 
										print ("UnregisterHotKey (); \n"); 
									#endif 
								#endif 
								unregisterHotkeys (); 
								hkRegistered = FALSE; 
							} 
							if (alwaysOnRegistered) { 
								unregisterAlwaysOnHotkeys (); 
								alwaysOnRegistered = FALSE; 
							} 
						} 
					} else { 
						if (hkRegistered) { 
							unregisterHotkeys (); 
							hkRegistered = FALSE; 
						} 
						if (alwaysOnRegistered) { 
							unregisterAlwaysOnHotkeys (); 
							alwaysOnRegistered = FALSE; 
						} 
					} 
				} 
				break; 
			case WM_HOTKEY: 
				if (bm_check ()) { 
					break; // Just ignore this hotkey if we are disconnected from the switcher. 
				} 
				long long needInput = -1; 
				output = 0; 
				#ifdef DEBUG 
					#if DEBUG > 0 
						print ("WM_HOTKEY. Hotkeys registered: "); 
						printHex (hkRegistered); 
						print ("\n"); 
					#endif 
				#endif 
				if (msg.wParam == ID_MAKE_WELCOME || msg.wParam == ID_MAKE_GOODBYE) { 
					DWORD threadId = 0; 
					LPVOID param = (LPVOID) (msg.wParam == ID_MAKE_WELCOME ? 0 : 2); 
					#ifdef DEBUG 
						#if DEBUG > 0 
							print ("Thread param: "); 
							printHex ((long long) param); 
							print ("\n"); 
						#endif 
					#endif 
					CreateThread (NULL, // Default security attributes. 
								0, // Default stack size. 
								changeMP1, 
								param, // No argument. 
								0, // Default creation flags. 
								&threadId); 
				} else if (msg.wParam == ID_DSK_1) { 
					// Downstream key! 
					void * downstream_key = bm_get_downstream_key (); // Get the first downstream key. 
					if (downstream_key) { 
						// HRESULT result = bm_dsk_perform_auto_transition (downstream_key); 
						// if (bm_dsk_get_on_air (downstream_key)) 
							// print ("On air. \n"); 
						// else print ("Off air. \n"); 
						// bm_dsk_set_on_air (downstream_key, !bm_dsk_get_on_air (downstream_key)); 
						// print ("PerformAutoTransition () returned: "); 
						// printHex (result); 
						// print ("\n"); 
						bm_dsk_perform_auto_transition (downstream_key); 
						if (bm_dsk_is_transitioning (downstream_key) || bm_dsk_is_auto_transitioning (downstream_key)) 
							print ("Transitioning! \n"); 
						else print ("Not transitioning? \n"); 
						bm_free (downstream_key); 
					} //else print ("Could not get downstream key 0 ... \n"); 
				} else if (msg.wParam >= ID_PERFORM_CUT && msg.wParam <= ID_PERFORM_AUTO) { 
					switch (msg.wParam) { 
						case ID_PERFORM_CUT: 
							bm_perform_cut (); 
							break; 
						case ID_PERFORM_AUTO: 
							bm_perform_auto_transition (); 
							break; 
					} 
				} else if (msg.wParam == ID_EMERGENCY_RETURN) { 
					// Turn off hotkeys, and set record setting to program: 
					void * downstream_key = bm_get_downstream_key (); 
					if (downstream_key) { 
						bm_dsk_set_on_air (downstream_key, FALSE); 
						bm_free (downstream_key); 
					} 
					enable_key1_live (FALSE); 
					DWORD threadId = 0; 
						CreateThread (NULL, 
							0, 
							changeAux3, 
							(LPVOID) INPUT_PROGRAM, 
							0, 
							&threadId); 
				} else { 
					#if DEBUG 
						print ("Hotkey pressed. ID: "); 
						printHex (msg.wParam); 
						print ("\n"); 
					#endif 
					switch (msg.wParam) { 
						case ID_AUX_M1: 
						case ID_AUX_M2: 
						case ID_AUX_PC: 
						case ID_AUX_PG: 
						case ID_AUX_FREEZE: 
							output = 1; 
							break; 
						case ID_RECORD_TWO: 
						case ID_RECORD_FOUR: 
						case ID_RECORD_FIVE: 
						case ID_RECORD_PROG: 
						case ID_RECORD_CLEAN: 
							output = 2; 
						default: 
						if (msg.wParam >= ID_PREVIEW_1 && msg.wParam <= ID_PREVIEW_10) 
							output = 0; 
						else if (msg.wParam >= ID_NUM_PREVIEW_1 && msg.wParam <= ID_NUM_PREVIEW_10) 
							output = 0; 
					} 
					#if DEBUG 
						print ("Output selected: "); 
						printHex (output); 
						print ("\n"); 
					#endif 
					switch (msg.wParam) { 
						case ID_MP1: 
						case ID_AUX_M1: 
							needInput = INPUT_MP1; 
							break; 
						case ID_MP2: 
						case ID_AUX_M2: 
							needInput = INPUT_MP2; 
							break; 
						case ID_BLK: 
							needInput = INPUT_BLK; 
							break; 
						case ID_COL1: 
							needInput = INPUT_COL1; 
							break; 
						case ID_BARS: 
							needInput = INPUT_BARS; 
							break; 
						case ID_AUX_PC: 
							needInput = INPUT_1; 
							break; 
						case ID_RECORD_TWO: 
							needInput = INPUT_2; 
							break; 
						case ID_RECORD_FOUR: 
							needInput = INPUT_4; 
							break; 
						case ID_RECORD_FIVE: 
							needInput = INPUT_5; 
							break; 
						case ID_AUX_PG: 
						case ID_RECORD_PROG: 
							needInput = INPUT_PROGRAM; 
							break; 
						case ID_RECORD_CLEAN: 
							needInput = INPUT_CLEAN1; 
							break; 
						case ID_AUX_FREEZE: 
							needInput = bm_get_aux_output (0); // Get front projector's output. 
							BOOL success = needInput == INPUT_PROGRAM ? 
								bm_get_program_input (&needInput) : 
									needInput == INPUT_PREVIEW ? 
										bm_get_preview_input (&needInput) : 
											TRUE; 
							if (!success) { 
								print ("Error getting program input. "); 
								disableTimer (timer); 
								if (hkRegistered) 
									unregisterHotkeys (); 
								if (alwaysOnRegistered) 
									unregisterAlwaysOnHotkeys (); 
								bm_close (); 
								ruvim_cleanup (); 
								return 2; 
							} 
							break; 
						case ID_TOGGLE_HOTKEYS: 
							if (hkTurnedOn) { 
								hkTurnedOn = FALSE; 
								unregisterHotkeys (); 
								hkRegistered = FALSE; 
							} else { 
								hkTurnedOn = TRUE; 
							} 
							break; 
						default: 
						if (msg.wParam >= ID_PREVIEW_1 && msg.wParam <= ID_PREVIEW_10) 
							needInput = msg.wParam + INPUT_1 - ID_PREVIEW_1; 
						else if (msg.wParam >= ID_NUM_PREVIEW_1 && msg.wParam <= ID_NUM_PREVIEW_10) 
							needInput = msg.wParam + INPUT_1 - ID_NUM_PREVIEW_1; 
					} 
					#if DEBUG 
						print ("Input selected: "); 
						printHex (needInput); 
						print ("\n"); 
					#endif 
					if (needInput >= 0) { 
						if (!bm_get_preview_input (&input)) { 
							print ("Error getting preview input. "); 
							disableTimer (timer); 
							if (hkRegistered) 
								unregisterHotkeys (); 
							if (alwaysOnRegistered) 
								unregisterAlwaysOnHotkeys (); 
							bm_close (); 
							ruvim_cleanup (); 
							return 2; 
						} 
						#ifdef DEBUG 
							#if DEBUG > 0 
								print ("Preview input: "); 
								printHex (input); 
								print ("\r\n"); 
							#endif 
						#endif 
						if (output == 1) { 
							DWORD threadId = 0; 
							CreateThread (NULL, // Default security attributes. 
								0, // Default stack size. 
								changeAux12, 
								(LPVOID) (needInput), // No argument. 
								0, // Default creation flags. 
								&threadId); 
						} else if (output == 2) { 
							DWORD threadId = 0; 
							CreateThread (NULL, 
								0, 
								changeAux3, 
								(LPVOID) needInput, 
								0, 
								&threadId); 
						} else { 
							if (!bm_set_preview_input (needInput)) { 
								print ("Error setting preview input. "); 
								disableTimer (timer); 
								if (hkRegistered) 
									unregisterHotkeys (); 
								if (alwaysOnRegistered) 
									unregisterAlwaysOnHotkeys (); 
								bm_close (); 
								ruvim_cleanup (); 
								return 3; 
							} 
						} 
						#ifdef DEBUG 
							#if DEBUG > 0 
								print ("Changed preview input to: "); 
								printHex (needInput); 
								print ("\r\n"); 
							#endif 
						#endif 
					} 
				} 
				break; 
			default: 
				TranslateMessage (&msg); 
				DispatchMessage (&msg); 
		} 
		if (msg.message == WM_DESTROY) 
			break; 
	} 
	disableTimer (timer); 
	if (hkRegistered) 
		unregisterHotkeys (); 
	if (alwaysOnRegistered) 
		unregisterAlwaysOnHotkeys (); 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 

void create_tally_text (long long input_code, char * text) { 
	if (input_code == INPUT_PREVIEW || input_code == INPUT_PROGRAM) { 
		long long actual = input_code == INPUT_PREVIEW ? i_preview : i_program; 
		char highlevel_text [64]; 
		char number_text [64]; 
		get_bm_input_name (input_code, highlevel_text); 
		get_bm_input_name (actual, number_text); 
		strcpy (text, number_text); 
		strcat (text, " ("); 
		strcat (text, highlevel_text); 
		strcat (text, ")"); 
	} else { 
		// char highlevel_text [64]; 
		// get_bm_input_name (input_code, highlevel_text); 
		// strcpy (text, highlevel_text); 
		// strcat (text, " - "); 
		// strcat (text, highlevel_text); 
		get_bm_input_name (input_code, text); 
	} 
} 

LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) { 
	static HBITMAP bmBackground = NULL; 
	static HFONT hCustomFont = NULL; 
	static unsigned short prevVScrollPosition = 0; 
	static unsigned short firstVScrollPosition = 0; 
	switch (uMsg) { 
		case WM_CREATE: 
			isRunning = 1; 
			bmBackground = LoadImage (hInstance, "background.bmp", IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE); 
			if (!bmBackground) { 
				printf ("Error loading bitmap. Error code: %d\n", GetLastError ()); 
			} 
			// Create font for text parts: 
			HFONT hFont = GetStockObject (DEFAULT_GUI_FONT); 
			LOGFONT logFont; 
			GetObject (hFont, sizeof (LOGFONT), &logFont); 
			logFont.lfHeight = 42; // Change this to whatever font size needed. 
			hCustomFont = CreateFontIndirect (&logFont); 
			return 0; 
		case WM_DESTROY: 
			isRunning = 0; 
			if (bmBackground) 
				DeleteObject (bmBackground); 
			if (hCustomFont) 
				DeleteObject (hCustomFont); 
			PostQuitMessage (0); 
			return 0; 
		case WM_PAINT: 
			PAINTSTRUCT ps; 
			HDC hdc = BeginPaint (hWnd, &ps); 
			// Draw the background: 
			HDC hMemDC = CreateCompatibleDC (hdc); 
			HGDIOBJ oldBitmap = SelectObject (hMemDC, bmBackground); 
			BITMAP needBitmap; 
			GetObject (bmBackground, sizeof (needBitmap), &needBitmap); 
			BitBlt (hdc, 0, 0, needBitmap.bmWidth, needBitmap.bmHeight, hMemDC, 0, 0, SRCCOPY); 
			SelectObject (hMemDC, oldBitmap); 
			DeleteDC (hMemDC); 
			// Text parts: 
			HFONT oldFont = SelectObject (hdc, hCustomFont); 
			RECT target; 
			target.left = 125; 
			target.top = 16; 
			target.right = 290 + 40; 
			target.bottom = 60; 
			char string1 [64]; 
			create_tally_text (aux_outputs[0], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			target.top += 65; 
			target.bottom += 65; 
			create_tally_text (aux_outputs[1], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			target.top += 68; 
			target.bottom += 68; 
			create_tally_text (aux_outputs[2], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			SelectObject (hdc, oldFont); 
			// Done: 
			EndPaint (hWnd, &ps); 
			return 0; 
		case WM_VSCROLL: 
			unsigned short vbar_position = HIWORD (wParam); 
			if (LOWORD (wParam) == SB_THUMBTRACK) { 
				if (!nowScrolling) 
					firstVScrollPosition = vbar_position; 
				if (vbar_position == firstVScrollPosition && prevVScrollPosition == 0) { 
					vbar_position = 0; 
				} else if (vbar_position == firstVScrollPosition && prevVScrollPosition == 100) { 
					vbar_position = 100; 
				} 
				SetScrollPos (hWnd, SB_VERT, vbar_position, TRUE); 
				double needPosition = ((double) (scrollBackwards ? 100 - vbar_position : vbar_position)) / 100.0; 
				#if DEBUG 
				printf ("Scroll position: %d; ", vbar_position); 
				printf ("Transition: %g\n", needPosition); 
				#endif 
				bm_set_transition_position (needPosition); 
				if (vbar_position == 100 && !scrollBackwards) { 
					scrollBackwards = TRUE; 
					#if DEBUG 
						printf ("Reached end of scroll range; set scrollBackwards=TRUE\n"); 
					#endif 
				} else if (vbar_position == 0 && scrollBackwards) { 
					scrollBackwards = FALSE; 
					#if DEBUG 
						printf ("Reached end of scroll range; set scrollBackwards=FALSE\n"); 
					#endif 
				} 
				prevVScrollPosition = vbar_position; 
				nowScrolling = TRUE; 
			} else if (LOWORD (wParam) == SB_ENDSCROLL) { 
				ShowScrollBar (hWnd, SB_VERT, TRUE); 
				// Update program and preview inputs NOW, so that the other code doesn't flip the scrollBackwards flag - we already flipped it in the vbar_position == 100 'if' block above. 
				bm_get_program_input (&i_program); 
				bm_get_preview_input (&i_preview); 
				i_transition = bm_is_in_transition (); 
				nowScrolling = FALSE; 
			} 
			return 0; 
		default: ; 
	} 
	return DefWindowProc (hWnd, uMsg, wParam, lParam); 
} 



DWORD WINAPI ServerThread (LPVOID lpParam) { 
	WORD sockVer; 
	WSADATA wsaData; 
	sockVer = MAKEWORD (2, 2); 
	WSAStartup (sockVer, &wsaData); 
	wsaReady = TRUE; 
	serverSocket = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP); 
	if (serverSocket == INVALID_SOCKET) { 
		printf ("Unable to create server socket. Error code: %x\n", WSAGetLastError ()); 
		WSACleanup (); 
		ExitThread (1); 
	} 
	SOCKADDR_IN s_in; 
	s_in.sin_family = AF_INET; 
	s_in.sin_port = htons (50513); 
	s_in.sin_addr.s_addr = INADDR_ANY; 
	int boundResult = bind (serverSocket, (LPSOCKADDR) (&s_in), sizeof (s_in)); 
	if (boundResult == SOCKET_ERROR) { 
		closesocket (serverSocket); 
		WSACleanup (); 
		ExitThread (1); 
	} 
	int listenResult = listen (serverSocket, 10); 
	if (listenResult == SOCKET_ERROR) { 
		closesocket (serverSocket); 
		WSACleanup (); 
		ExitThread (1); 
	} 
	SOCKET clientSocket; 
	while (isRunning) { 
		clientSocket = accept (serverSocket, NULL, NULL); 
		if (clientSocket == INVALID_SOCKET) { 
			Sleep (1000); 
			continue; 
		} 
		CreateThread (NULL, 0, ServeClientThread, (LPVOID) clientSocket, 0, NULL); 
	} 
	if (wsaReady) { 
		wsaReady = TRUE; 
		WSACleanup (); 
	} 
	ExitThread (0); 
	return 0; 
} 

BOOL isCameraInput (uint8_t cameraNumber, long long input) { 
	return input == cameraNumber || 
		(cameraNumber == i_program && (input == INPUT_PROGRAM || input == INPUT_CLEAN1 || input == INPUT_CLEAN2)) || 
		(cameraNumber == i_preview && (input == INPUT_PREVIEW || i_transition)); 
} 

// size_t madeCount = 0; 
DWORD makeState (uint8_t cameraNumber) { 
	uint8_t result [4]; 
	// if (madeCount == 0) { 
		// printf ("Camera: %d\n", cameraNumber); 
		// printf ("Aux 0: %x\n", aux_outputs[0]); 
		// printf ("Aux 1: %x\n", aux_outputs[1]); 
		// printf ("Aux 2: %x\n", aux_outputs[2]); 
		// printf ("Pgm: %x\n", i_program); 
		// printf ("Pvw: %x\n", i_preview); 
		// printf ("Transition: %d\n", i_transition); 
	// } 
	// madeCount++; 
	result[0] = isCameraInput (cameraNumber, aux_outputs[2]); // Check if this camera's video signal is going to the aux. 
	result[1] = isCameraInput (cameraNumber, aux_outputs[0]) || isCameraInput (cameraNumber, aux_outputs[1]); // Is going to the projector? 
	result[2] = i_preview == cameraNumber; 
	result[3] = 0; 
	return ((DWORD *) result) [0]; 
} 

DWORD WINAPI ServeClientThread (LPVOID lpParam) { 
	SOCKET clientSocket = (SOCKET) lpParam; 
	char buffer [8]; 
	int result; 
	DWORD state = 0; 
	DWORD prev = 0; 
	result = recv (clientSocket, buffer, sizeof (buffer), 0); 
	if (result == SOCKET_ERROR) { 
		closesocket (clientSocket); 
		ExitThread (1); 
	} 
	uint8_t cameraNumber = 0; 
	size_t i; 
	for (i = 0; i < 8 && buffer[i] != '/'; i++) { 
		// Do nothing. 
	} 
	if (buffer[i] == '/' && i + 1 < 7) { 
		char c = buffer[i + 1]; 
		if (c >= '0' && c <= '9') 
			cameraNumber = c - '0'; 
		printf ("Connected camera: %d\n", cameraNumber); 
	} 
	void * dsk = cameraNumber == 1 ? bm_get_downstream_key () : nullptr; 
	const char * quick_header = "HTTP/1.0 200 OK\nContent-Type: text/plain\n\n"; 
	send (clientSocket, quick_header, strlen (quick_header), 0); 
	result = send (clientSocket, (const char *) &state, sizeof (state), 0); 
	DWORD lastSend = GetTickCount (); 
	do { 
		state = makeState (cameraNumber); 
		if (cameraNumber == 1) { 
			state |= bm_dsk_get_on_air (dsk); 
			state |= bm_is_key1_live (); 
		} 
		DWORD now = GetTickCount (); 
		if (state != prev || now - lastSend > 100) { 
			result = send (clientSocket, (const char *) &state, sizeof (state), 0); 
			if (state != prev) { 
				printf ("Camera state: %x\n", state); 
			} 
			lastSend = now; 
			prev = state; 
		} 
		if (result == SOCKET_ERROR) { 
			printf ("Error sending data over socket. Last error: %x\n", WSAGetLastError ()); 
			printf ("Disconnected camera: %d\n", cameraNumber); 
			closesocket (clientSocket); 
			ExitThread (1); 
		} 
		Sleep (20); 
	} while (isRunning); 
	printf ("Disconnected camera: %d\n", cameraNumber); 
	if (dsk) bm_free (dsk); 
	closesocket (clientSocket); 
	ExitThread (0); 
	return 0; 
} 



DWORD WINAPI changeAux12 (LPVOID lpParam) { 
	long long needInput = (long long) (lpParam); 
	bm_set_aux_outputs (0, 2, needInput, 256); 
	ExitThread (0); 
	return 0; 
} 
DWORD WINAPI changeAux3 (LPVOID lpParam) { 
	long long needInput = (long long) (lpParam); 
	bm_set_aux_outputs (2, 3, needInput, 256); 
	ExitThread (0); 
	return 0; 
} 
DWORD WINAPI changeMP1 (LPVOID lpParam) { 
	unsigned long source = (unsigned long) lpParam; 
	bm_set_media_player_source (0, 1, source, 256); 
	ExitThread (0); 
	return 0; 
} 


