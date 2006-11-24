// Launcher.cpp : Defines the entry point for the application.
//

#include <windows.h>

// Taken from tchar.h
#ifdef UNICODE
#define _T(x)      L ## x
#else
#define _T(x)		x
#endif

#define PATH_TO_WISH _T("\\bin\\wish.exe")
#define LEN_OF_WISH 15
#define PATH_TO_AMSN _T("\\scripts\\amsn")
#define LEN_OF_AMSN 13

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	TCHAR exePath[MAX_PATH] = {_T('\0')};
	LPTSTR endOfPath = NULL;
	LPTSTR pCmd = NULL;
        BOOL process_created;

	int lnOfPath, ret;
	
	STARTUPINFO startinfo = {sizeof(STARTUPINFO),NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL};
	PROCESS_INFORMATION pi = { NULL,NULL,0,0 };

	GetModuleFileName(NULL,exePath,sizeof(exePath));

	endOfPath = exePath + lstrlen(exePath);
	while ((endOfPath != exePath) && (*endOfPath != _T('\\'))) {
		endOfPath = CharPrev(exePath,endOfPath);
	}
	*endOfPath = _T('\0');

	lnOfPath = lstrlen(exePath);
	if (lnOfPath == 0) {
		exePath[0] = _T('.');
		exePath[1] = _T('\0');
		lnOfPath = 1;
	}

	//Don't forget the ending \0 in the counts
	pCmd = (LPTSTR) HeapAlloc(GetProcessHeap(),HEAP_ZERO_MEMORY,(2*lnOfPath + LEN_OF_WISH + LEN_OF_AMSN + 6) * sizeof(TCHAR));

	wsprintf(pCmd,_T("\"%s%s\" \"%s%s\""),exePath,PATH_TO_WISH,exePath,PATH_TO_AMSN);

	process_created = CreateProcess(NULL,pCmd,NULL,NULL,FALSE,0,NULL,exePath,&startinfo,&pi);

	if (process_created  == 0) {
		ret = GetLastError();
		wsprintf(exePath, _T("Cannot run aMSN : error %u"), ret);
		MessageBox(NULL,exePath, _T("aMSN Launcher"),MB_ICONERROR | MB_OK);
	}
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	HeapFree(GetProcessHeap(),0,pCmd);

	return process_created? 0 : -1;
}



