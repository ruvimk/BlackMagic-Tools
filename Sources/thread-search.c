#include <windows.h> 

#define DEBUG 0 

#include <process.h>
#include <Tlhelp32.h>
#include <winbase.h>
#include <string.h>

#ifdef DEBUG 
	#if DEBUG > 0 
		#include <stdlib.h> 
	#endif 
#endif 


DWORD WINAPI GetMainThreadId (DWORD pId); 


void endProcess (DWORD processId) { 
	DWORD threadId = GetMainThreadId (processId); 
	#ifdef DEBUG 
		#if DEBUG > 0 
			DWORD bWritten = 0; 
			WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), "Sending WM_CLOSE ... \r\n", 23, &bWritten, 0); 
		#endif 
	#endif 
	if (!PostThreadMessage (threadId, WM_CLOSE, (WPARAM) NULL, (LPARAM) NULL)) { 
		#ifdef DEBUG 
			#if DEBUG > 0 
				WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), "Error posting WM_CLOSE. \r\n", 26, &bWritten, 0); 
				char string1 [512]; 
				itoa (GetLastError (), string1, 16); 
				WriteFile (GetStdHandle (STD_OUTPUT_HANDLE), string1, strlen (string1), &bWritten, 0); 
			#endif 
		#endif 
		ExitProcess (1); // Exit? 
	} 
} 


// Answer from here: 
// https://stackoverflow.com/questions/7956519/how-to-kill-processes-by-name-win32-api

BOOL WINAPI killProcessByName (const char *filename, BOOL testOnly)
{
    HANDLE hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, (unsigned long) NULL);
	DWORD idCurrent = GetCurrentProcessId (); 
    PROCESSENTRY32 pEntry;
    pEntry.dwSize = sizeof (pEntry);
	DWORD pExitCode = 0; 
    BOOL hRes = Process32First(hSnapShot, &pEntry);
	size_t waitCount = 0; 
	#ifdef DEBUG 
		#if DEBUG > 0 
			HANDLE hStdOut = GetStdHandle (STD_OUTPUT_HANDLE); 
			const char * sEndl = "\r\n"; 
			const char * sTab = "\t"; 
			char string1 [512]; 
			DWORD bWritten = 0; 
			itoa (idCurrent, string1, 10); 
			WriteFile (hStdOut, "Current process ID: ", 20, &bWritten, 0); 
			WriteFile (hStdOut, string1, strlen (string1), &bWritten, 0); 
			WriteFile (hStdOut, sEndl, 2, &bWritten, 0); 
			WriteFile (hStdOut, sEndl, 2, &bWritten, 0); 
		#endif 
	#endif 
    while (hRes)
    {
		#ifdef DEBUG 
			#if DEBUG > 0 
				itoa (pEntry.th32ProcessID, string1, 10); 
				WriteFile (hStdOut, pEntry.szExeFile, strlen (pEntry.szExeFile), &bWritten, 0); 
				WriteFile (hStdOut, sTab, 1, &bWritten, 0); 
				WriteFile (hStdOut, string1, strlen (string1), &bWritten, 0); 
				WriteFile (hStdOut, sEndl, 2, &bWritten, 0); 
			#endif 
		#endif 
        if (strcmp(pEntry.szExeFile, filename) == 0 && pEntry.th32ProcessID != idCurrent)
        {
			// Wait for the process to exit: 
            HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, 0,
                                          (DWORD) pEntry.th32ProcessID);
            if (hProcess != NULL)
            {
				if (!testOnly) 
					endProcess (pEntry.th32ProcessID); // Close it, then wait: 
                // TerminateProcess(hProcess, 9);
				while (GetExitCodeProcess (hProcess, &pExitCode) && pExitCode == STILL_ACTIVE) { 
					Sleep (50); // Wait a little for the process to exit. 
				} 
                CloseHandle(hProcess);
				waitCount++; 
            }
        }
        hRes = Process32Next(hSnapShot, &pEntry);
    }
    CloseHandle(hSnapShot);
	return waitCount > 0; 
}

// Answer from here: 
// https://www.codeproject.com/Questions/78801/How-to-get-the-main-thread-ID-of-a-process-known-b

#ifndef MAKEULONGLONG
#define MAKEULONGLONG(ldw, hdw) ((ULONGLONG(hdw) << 32) | ((ldw) & 0xFFFFFFFF))
#endif
  
#ifndef MAXULONGLONG
#define MAXULONGLONG ((ULONGLONG)~((ULONGLONG)0))
#endif

#ifndef OpenThread 
	HANDLE WINAPI OpenThread (DWORD, BOOL, DWORD); 
#endif 

DWORD WINAPI GetMainThreadId (DWORD dwProcID)
{
    DWORD dwMainThreadID = 0;
  ULONGLONG ullMinCreateTime = MAXULONGLONG;
  
  HANDLE hThreadSnap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if (hThreadSnap != INVALID_HANDLE_VALUE) {
    THREADENTRY32 th32;
    th32.dwSize = sizeof(THREADENTRY32);
    BOOL bOK = TRUE;
    for (bOK = Thread32First(hThreadSnap, &th32); bOK;
         bOK = Thread32Next(hThreadSnap, &th32)) {
      if (th32.th32OwnerProcessID == dwProcID) {
        HANDLE hThread = (HANDLE) OpenThread(THREAD_QUERY_INFORMATION,
                                    TRUE, th32.th32ThreadID);
        if (hThread) {
          FILETIME afTimes[4]; 
		  ZeroMemory (afTimes, sizeof (afTimes)); 
		  unsigned long long test = 0; 
          if (GetThreadTimes(hThread,
                             &afTimes[0], &afTimes[1], &afTimes[2], &afTimes[3])) {
			((unsigned long *) (&test)) [0] = afTimes[0].dwLowDateTime; 
			((unsigned long *) (&test)) [1] = afTimes[0].dwHighDateTime; 
            ULONGLONG ullTest = test; 
            if (ullTest && ullTest < ullMinCreateTime) {
              ullMinCreateTime = ullTest;
              dwMainThreadID = th32.th32ThreadID; // let it be main... :)
            }
          }
          CloseHandle(hThread);
        }
      }
    }
  } 
#ifndef UNDER_CE
    CloseHandle(hThreadSnap);
#else
    CloseToolhelp32Snapshot(hThreadSnap);
#endif
	return dwMainThreadID; 
}

