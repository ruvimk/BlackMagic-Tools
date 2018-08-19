#include <windows.h> 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

#define DEBUG 0 



int main (int argc, char * argv []) { 
	ruvim_init ("Read-Inputs-log.txt", FALSE); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	BOOL keepGoing = TRUE; 
	DWORD inputType = 0; 
	unsigned long iIndex = 0; 
	while (keepGoing) { 
		print ("Index: "); 
		printHex (iIndex); 
		print ("\r\n"); 
		unsigned long i = iIndex; 
		// printHex (iIndex); 
		void * input = bm_get_input (i); 
		printHex (iIndex); // Makes it work! 
		iIndex++; 
		if (!input) { 
			keepGoing = FALSE; 
			continue; 
		} 
		bm_get_input_type (input, &inputType); 
		bm_free (input); 
		
		print ("Input type: "); 
		printText ((char *) (&inputType), sizeof (DWORD)); 
		print ("\r\n"); 
		// printHex (iIndex); 
		// index = index + 1; 
	} 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 


