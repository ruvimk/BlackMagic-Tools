#include <windows.h> 

#define DEBUG 0 

#include <thread-search.h> 
#include <BlackMagic-Interface.h> 

// Tutorial: 
// https://msdn.microsoft.com/en-us/library/windows/desktop/ff381409(v=vs.85).aspx 

LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam); 

BOOL isRunning = 0; 
long long aux_outputs [3] = {0}; 

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
	// BOOL isRestart = killProcessByName ("BlackMagic-AuxMonitor.exe", FALSE); 
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
		"Aux Monitor", 
		WS_OVERLAPPEDWINDOW, 
		needX, needY, 320, 250, 
		NULL, // Parent 
		NULL, // Menu 
		wc.hInstance, 
		NULL // Additional application data 
	); 
	ShowWindow (hWindow, SW_SHOWDEFAULT); 
	UpdateWindow (hWindow); 
	// Set window as always on top: 
	SetWindowPos (hWindow, 
		HWND_TOPMOST, 
		needX, 
		needY, 
		320, 
		250, 
		SWP_SHOWWINDOW); 
	while (GetMessageA (&msg, 0, 0, 0) && isRunning) { 
		switch (msg.message) { 
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
						if (changed) 
							InvalidateRect (hWindow, NULL, 1); 
					} else { 
						BOOL changed = 0; 
						for (size_t i = 0; i < 3; i++) { 
							long long prev = aux_outputs[i]; 
							aux_outputs[i] = -1; 
							changed |= aux_outputs[i] != prev; 
						} 
						if (changed) 
							InvalidateRect (hWindow, NULL, 1); 
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
	bm_close (); 
	ruvim_cleanup (); 
	return 0; 
} 

LRESULT CALLBACK WindowProc (HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) { 
	static HBITMAP bmBackground = NULL; 
	static HFONT hCustomFont = NULL; 
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
			target.right = 290; 
			target.bottom = 60; 
			char string1 [64]; 
			get_bm_input_name (aux_outputs[0], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			target.top += 65; 
			target.bottom += 65; 
			get_bm_input_name (aux_outputs[1], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			target.top += 68; 
			target.bottom += 68; 
			get_bm_input_name (aux_outputs[2], string1); 
			DrawText (hdc, string1, strlen (string1), &target, DT_CENTER); 
			SelectObject (hdc, oldFont); 
			// Done: 
			EndPaint (hWnd, &ps); 
			return 0; 
		default: ; 
	} 
	return DefWindowProc (hWnd, uMsg, wParam, lParam); 
} 


