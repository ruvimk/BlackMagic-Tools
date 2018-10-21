#include <windows.h> 
#include <stdio.h> 

#ifndef DEBUG 
#define DEBUG 0 
#endif 

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
#define ID_TOGGLE_HOTKEYS 51 
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
	RegisterHotKey (NULL, ID_DSK_1, MOD_NOREPEAT, VK_ESCAPE); // VK_OEM_4 is [ key for US keyboard. Also see VK_OEM_6 for ] key. 
	size_t i; 
	for (i = ID_PREVIEW_1; i <= ID_PREVIEW_10; i++) 
		RegisterHotKey (NULL, i, MOD_NOREPEAT, i == ID_PREVIEW_10 ? '0' : ('1' + i - ID_PREVIEW_1)); 
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
	size_t i; 
	for (i = ID_PREVIEW_1; i <= ID_PREVIEW_10; i++) 
		UnregisterHotKey (NULL, i); 
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

BOOL shouldHotkeysBeOn (const char * current_foreground_window_title) { 
	const char * title = current_foreground_window_title; 
	return (title[0] == 'A' && title[1] == 'T' && title[2] == 'E' && title[3] == 'M') || 
		(title[0] == 'O' && title[1] == 'B' && title[2] == 'S' && title[3] == ' '); 
} 

int main (int argc, char * argv []) { 
	ruvim_init ("Ruvims-MediaKeys-log.txt", FALSE); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	long long input = 0; 
	unsigned long output = 0; // 0 = PGM, 1 = AUX1&2; 
	// bm_perform_auto_transition (); 
	// bm_perform_cut (); 
	// bm_perform_fade_to_black (); 
	double position = 0; 
	bm_get_transition_position (&position); 
	printf ("Position: %g\n", position); 
	// bm_set_transition_position (0.5); 
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


