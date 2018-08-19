#include <windows.h> 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

#define DEBUG 0 



int main (int argc, char * argv []) { 
	ruvim_init ("AuxChanger-log.txt", FALSE); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	// DWORD outputs_changed = bm_set_aux_outputs (0, 2, INPUT_MP1, 256); 
	DWORD error_level = bm_set_media_player_source (0, 1, 0); 
	// print ("Output changed count: "); 
	// printHex (outputs_changed); 
	print ("Error level: "); 
	printHex (error_level); 
	print ("\r\n"); 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 


