#include <windows.h> 

#define DEBUG 0 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 



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
#define ID_RECORD_PROG 24 
#define ID_RECORD_CLEAN 25 
#define ID_AUX_FREEZE 26 
#define ID_AUX_PC 27 
#define ID_AUX_PG 28 
#define ID_AUX_M1 29 
#define ID_AUX_M2 30 
#define ID_MAKE_WELCOME 31 
#define ID_MAKE_GOODBYE 32 
#define ID_DSK_1 35 
#define ID_TOGGLE_HOTKEYS 51 
void registerHotkeys () { 
	RegisterHotKey (NULL, ID_MP1, MOD_NOREPEAT, 'J'); 
	RegisterHotKey (NULL, ID_MP2, MOD_NOREPEAT, 'K'); 
	RegisterHotKey (NULL, ID_BLK, MOD_NOREPEAT, 'D'); 
	RegisterHotKey (NULL, ID_COL1, MOD_NOREPEAT, 'R'); 
	RegisterHotKey (NULL, ID_BARS, MOD_NOREPEAT, 'A'); 
	RegisterHotKey (NULL, ID_RECORD_TWO, MOD_NOREPEAT, 'T'); 
	RegisterHotKey (NULL, ID_RECORD_FOUR, MOD_NOREPEAT, 'F'); 
	RegisterHotKey (NULL, ID_RECORD_PROG, MOD_NOREPEAT, 'G'); 
	RegisterHotKey (NULL, ID_RECORD_CLEAN, MOD_NOREPEAT, 'H'); 
	RegisterHotKey (NULL, ID_AUX_FREEZE, MOD_NOREPEAT, 'Y'); 
	RegisterHotKey (NULL, ID_AUX_PC, MOD_NOREPEAT, 'U'); 
	RegisterHotKey (NULL, ID_AUX_PG, MOD_NOREPEAT, 'I'); 
	RegisterHotKey (NULL, ID_AUX_M1, MOD_NOREPEAT, 'O'); 
	RegisterHotKey (NULL, ID_AUX_M2, MOD_NOREPEAT, 'P'); 
	RegisterHotKey (NULL, ID_MAKE_WELCOME, MOD_NOREPEAT, 'W'); 
	RegisterHotKey (NULL, ID_MAKE_GOODBYE, MOD_NOREPEAT, 'S'); 
	RegisterHotKey (NULL, ID_DSK_1, MOD_NOREPEAT, 'B'); // VK_OEM_4 is [ key for US keyboard. Also see VK_OEM_6 for ] key. 
} 
void unregisterHotkeys () { 
	UnregisterHotKey (NULL, ID_MP1); 
	UnregisterHotKey (NULL, ID_MP2); 
	UnregisterHotKey (NULL, ID_BLK); 
	UnregisterHotKey (NULL, ID_COL1); 
	UnregisterHotKey (NULL, ID_BARS); 
	UnregisterHotKey (NULL, ID_RECORD_TWO); 
	UnregisterHotKey (NULL, ID_RECORD_FOUR); 
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
} 
void registerAlwaysOnHotkeys () { 
	RegisterHotKey (NULL, ID_TOGGLE_HOTKEYS, MOD_NOREPEAT | MOD_CONTROL | MOD_ALT, 'H'); 
} 
void unregisterAlwaysOnHotkeys () { 
	UnregisterHotKey (NULL, ID_TOGGLE_HOTKEYS); 
} 

DWORD enableTimer () { 
	return SetTimer (NULL, 0, 250, (void *) NULL); 
} 
void disableTimer (DWORD timerId) { 
	KillTimer (NULL, timerId); 
} 


int main (int argc, char * argv []) { 
	BOOL isRestart = killProcessByName ("BlackMagic-AdditionalHotkeys.exe", FALSE); 
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
	ruvim_init ("Ruvims-MediaKeys-log.txt", isRestart); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	long long input = 0; 
	unsigned long output = 0; // 0 = PGM, 1 = AUX1&2; 
	MSG msg; 
	BOOL keepRunning = TRUE; 
	BOOL hkRegistered = FALSE; 
	BOOL alwaysOnRegistered = FALSE; 
	BOOL hkTurnedOn = TRUE; 
	DWORD timer = enableTimer (); 
	if (!timer) { 
		DWORD lastError = GetLastError (); 
		print ("Error creating a timer. Last error: "); 
		printHex (lastError); 
		print ("\r\n\r\n"); 
	} else { 
		#ifdef DEBUG 
			#if DEBUG > 0 
				print ("Timer registered: "); 
				printHex (timer); 
				print ("\r\n\r\n"); 
			#endif 
		#endif 
	} 
	while (GetMessageA (&msg, 0, 0, 0) && keepRunning) { 
		switch (msg.message) { 
			case WM_CLOSE: 
				keepRunning = FALSE; 
				break; 
			case WM_TIMER: 
				if (msg.wParam == timer) { 
					HWND hWnd = GetForegroundWindow (); 
					if (hWnd) { 
						char string1 [512]; 
						if (GetWindowText (hWnd, string1, 511) && 
							string1[0] == 'A' && string1[1] == 'T' && string1[2] == 'E' && string1[3] == 'M') { 
							// ATEM! 
							#ifdef DEBUG 
								#if DEBUG > 0 
									print ("Window text: "); 
									print (string1); 
									print ("\n"); 
								#endif 
							#endif 
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
				} else { 
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
						case ID_RECORD_PROG: 
						case ID_RECORD_CLEAN: 
							output = 2; 
					} 
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
					} 
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
			; 
		} 
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


