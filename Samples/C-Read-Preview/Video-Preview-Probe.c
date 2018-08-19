#include <windows.h> 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

#define DEBUG 0 



DWORD enableTimer () { 
	return SetTimer (NULL, 0, 250, (void *) NULL); 
} 
void disableTimer (DWORD timerId) { 
	KillTimer (NULL, timerId); 
} 


int main (int argc, char * argv []) { 
	BOOL isRestart = killProcessByName ("Video-Preview-Probe.exe", FALSE); 
	ruvim_init ("Video-Preview-Probe-log.txt", isRestart); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	long long input = 0; 
	MSG msg; 
	BOOL keepRunning = TRUE; 
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
	long long prevInput = 0; 
	while (GetMessageA (&msg, 0, 0, 0) && keepRunning) { 
		switch (msg.message) { 
			case WM_CLOSE: 
				keepRunning = FALSE; 
				break; 
			case WM_TIMER: 
				if (msg.wParam == timer) { 
					if (!bm_get_preview_input (&input)) { 
						print ("Error getting preview input. "); 
						disableTimer (timer); 
						bm_close (); 
						ruvim_cleanup (); 
						return 2; 
					} 
					if (input != prevInput) { 
						print ("BlackMagic Preview Input: "); 
						printHex (input); 
						print ("\r\n"); 
						prevInput = input; 
					} 
				} 
				break; 
			default: 
			; 
		} 
	} 
	disableTimer (timer); 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 


