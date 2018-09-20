#include <windows.h> 
#include <winsock.h> 

#define DEBUG 0 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

#define nullptr NULL 
typedef unsigned char uint8_t; 

DWORD WINAPI ServerThread (LPVOID lpParam); 
DWORD WINAPI ServeClientThread (LPVOID lpParam); 

BOOL isRunning = 0; 
long long aux_outputs [3] = {0}; 
long long i_program = 0; 
long long i_preview = 0; 
BOOL i_transition = FALSE; 

HINSTANCE hInstance; 

#ifndef LR_LOADFROMFILE 
	#define LR_LOADFROMFILE 0x10 
#endif 

DWORD enableTimer () { 
	return SetTimer (NULL, 0, 100, (void *) NULL); 
} 
void disableTimer (DWORD timerId) { 
	KillTimer (NULL, timerId); 
} 


int main (int argc, char * argv []) { 
	BOOL isRestart = killProcessByName ("BlackMagic-TallyServer.exe", FALSE); 
	ruvim_init ("AuxMonitor-log.txt", 0); 
	if (bm_init ()) { 
		print ("Error initializing BlackMagic interface. "); 
		ruvim_cleanup (); 
		return 1; 
	} 
	MSG msg; 
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
	size_t i; 
	while (TRUE) { 
		if (!bm_check ()) { 
			for (i = 0; i < 3; i++) 
				aux_outputs[i] = bm_get_aux_output (i); 
			bm_get_program_input (&i_program); 
			bm_get_preview_input (&i_preview); 
			i_transition = bm_is_in_transition (); 
		} else { 
			for (i = 0; i < 3; i++) 
				aux_outputs[i] = 0; 
			i_program = i_preview = 0; 
			i_transition = FALSE; 
		} 
		// for (i = 0; i < 3; i++) 
			// aux_outputs[i] = INPUT_PROGRAM; 
		// aux_outputs[2] = INPUT_PREVIEW; 
		// i_program = 1; 
		// i_preview = 2; 
		Sleep (500); 
	} 
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 


DWORD WINAPI ServerThread (LPVOID lpParam) { 
	WORD sockVer; 
	WSADATA wsaData; 
	sockVer = MAKEWORD (2, 2); 
	WSAStartup (sockVer, &wsaData); 
	SOCKET serverSocket = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP); 
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
	WSACleanup (); 
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
	const char * quick_header = "HTTP/1.0 200 OK\nContent-Type: text/plain\n\n"; 
	send (clientSocket, quick_header, strlen (quick_header), 0); 
	result = send (clientSocket, (const char *) &state, sizeof (state), 0); 
	DWORD lastSend = GetTickCount (); 
	do { 
		state = makeState (cameraNumber); 
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
	closesocket (clientSocket); 
	ExitThread (0); 
	return 0; 
} 


