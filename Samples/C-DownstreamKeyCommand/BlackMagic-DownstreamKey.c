#include <windows.h> 
#include <string.h> 

#include <BlackMagic-Interface.h> 

int main (int argc, char * argv []) { 
	ruvim_init ("Ruvims-MediaKeys-log.txt", FALSE); 
	if (bm_init ()) { 
		print ("-1: Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	void * downstream_key = bm_get_downstream_key (); // Get the first downstream key. 
	if (downstream_key) { 
		for (unsigned int command_index = 1; command_index < argc; command_index++) { 
			if (!strcmp (argv[command_index], "transition")) 
				bm_dsk_perform_auto_transition (downstream_key); 
			else if (!strcmp (argv[command_index], "init")) 
				bm_dsk_init_for_dark_overlay (downstream_key, 1, 1); 
		} 
		int keyState = (bm_dsk_get_on_air (downstream_key) ? 1 : 0) + 
					   (bm_is_key1_live () ? 2 : 0); 
		char string1 [32]; 
		string1[0] = keyState + 48; 
		string1[1] = 0; 
		print (string1); 
		print ("\n"); 
		bm_free (downstream_key); 
	} else print ("-2: Could not get downstream key 0 ... \n"); 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 

