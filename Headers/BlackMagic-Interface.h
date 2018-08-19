#include <windows.h> 

DWORD printText (const char * s, unsigned int l) { 
	DWORD bWritten = 0; 
	WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), s, l, &bWritten, 0); 
	return bWritten; 
} 
DWORD print (const char * s) { 
	return printText (s, strlen (s)); 
} 
DWORD printHex (long long iValue) { 
	char hex [16] = { '0' }; 
	char * p = &hex[15]; 
	long long v = iValue; 
	while (p >= hex) { 
		char c = v & 0x0F; 
		if (c || v) 
			*p = c >= 0x0A ? 
				c - 0x0A + 'A' 
				: c + '0'; 
		else *p = ' '; 
		p--; 
		v = v >> 4; 
	} 
	DWORD bWritten = 0; 
	WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), hex, 16, &bWritten, 0); 
	return bWritten; 
} 
DWORD printDec (long iValue) { 
	char hex [10] = { '0' }; 
	char * p = &hex[9]; 
	long long v = iValue; 
	while (p >= hex) { 
		char c = v % 10; 
		if (c || v) 
			*p = c + '0'; 
		else *p = ' '; 
		p--; 
		v = v / 10; 
	} 
	DWORD bWritten = 0; 
	WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), hex, 10, &bWritten, 0); 
	return bWritten; 
} 

DWORD WINAPI bm_init (); // Returns 0 if success. 
void WINAPI bm_close (); 

DWORD WINAPI bm_restart (); 
DWORD WINAPI bm_check (); // Returns 0 if success. 

BOOL WINAPI bm_set_program_input (long long iInput); 
BOOL WINAPI bm_set_preview_input (long long iInput); 
BOOL WINAPI bm_get_program_input (long long * lpInput); 
BOOL WINAPI bm_get_preview_input (long long * lpInput); 
BOOL WINAPI bm_is_in_transition (); 

void * WINAPI bm_get_downstream_key (); 

BOOL WINAPI bm_dsk_get_on_air (void * downstream_key); 
void WINAPI bm_dsk_set_on_air (void * downstream_key, BOOL on_air); 
HRESULT WINAPI bm_dsk_perform_auto_transition (void * downstream_key); 
BOOL WINAPI bm_dsk_is_transitioning (void * downstream_key); 
BOOL WINAPI bm_dsk_is_auto_transitioning (void * downstream_key); 
unsigned int WINAPI bm_dsk_get_frames_remaining (void * downstream_key); 
void WINAPI bm_dsk_init_for_dark_overlay (void * downstream_key, long long fill_source_id, long long key_source_id); 

void * WINAPI bm_get_input (unsigned long input_index); 
HRESULT WINAPI bm_get_input_type (void * input, DWORD * type); 
DWORD WINAPI bm_set_aux_outputs (unsigned long aux_start_index, unsigned long aux_stop_index, long long input_id, unsigned long max_retries_per_aux); 
long long WINAPI bm_get_aux_output (unsigned long aux_index); 
DWORD WINAPI bm_set_media_player_source (unsigned long mp_start_index, unsigned long mp_stop_index, unsigned long media_source_index, unsigned long max_retries); 

void * WINAPI bm_get_mix_block (); 
void * WINAPI bm_get_key (); 

BOOL WINAPI bm_is_key1_live (); 

void WINAPI bm_free (void * object); 

void WINAPI ruvim_init (const char * log_filename, BOOL log_append); 
void WINAPI ruvim_cleanup (); 


#define INPUT_1 		0x001 
#define INPUT_2 		0x002 
#define INPUT_3 		0x003 
#define INPUT_4 		0x004 
#define INPUT_5 		0x005 
#define INPUT_6 		0x006 
#define INPUT_7 		0x007 
#define INPUT_8 		0x008 
#define INPUT_9 		0x009 
#define INPUT_10		0x00A 

#define INPUT_BLK		0x000 
#define INPUT_COL1		0x7D1 
#define INPUT_COL2		0x7D2 
#define INPUT_BARS		0x3E8 
#define INPUT_MP1		0xBC2 
#define INPUT_MP2		0xBCC 
#define INPUT_MP1_KEY	0xBC3 
#define INPUT_MP2_KEY	0xBCD 
#define INPUT_KEY_MASK	0xFAA 

#define INPUT_PROGRAM	0x271A 
#define INPUT_PREVIEW	0x271B 

#define INPUT_CLEAN1	0x1B59 
#define INPUT_CLEAN2	0x1B5A 

#define MOD_ALT 		0x0001 
#define MOD_CTRL		0x0002 
#define MOD_SHIFT		0x0004 
#define MOD_WIN 		0x0008 
#define MOD_NOREPEAT	0x4000 




#include <stdlib.h> 
#include <string.h> 

void get_bm_input_name (long long input, char * out_name) { 
	switch (input) { 
		case -1: 
			strcpy (out_name, "ERROR"); 
			break; 
		case INPUT_BLK: 
			strcpy (out_name, "BLACK"); 
			break; 
		case INPUT_COL1: 
			strcpy (out_name, "COLOR1"); 
			break; 
		case INPUT_COL2: 
			strcpy (out_name, "COLOR2"); 
			break; 
		case INPUT_BARS: 
			strcpy (out_name, "BARS"); 
			break; 
		case INPUT_MP1: 
			strcpy (out_name, "MP1"); 
			break; 
		case INPUT_MP2: 
			strcpy (out_name, "MP2"); 
			break; 
		case INPUT_MP1_KEY: 
			strcpy (out_name, "MP1 KEY"); 
			break; 
		case INPUT_MP2_KEY: 
			strcpy (out_name, "MP2 KEY"); 
			break; 
		case INPUT_KEY_MASK: 
			strcpy (out_name, "K MASK"); 
			break; 
		case INPUT_PROGRAM: 
			strcpy (out_name, "PGM"); 
			break; 
		case INPUT_PREVIEW: 
			strcpy (out_name, "PVW"); 
			break; 
		case INPUT_CLEAN1: 
			strcpy (out_name, "CLEAN1"); 
			break; 
		case INPUT_CLEAN2: 
			strcpy (out_name, "CLEAN2"); 
			break; 
		default: 
		itoa (input, out_name, 10); 
	} 
} 



