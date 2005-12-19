/***************************************************************************
 *   Copyright (C) 2005 by Le philousophe - Phil                           *
 *   lephilousophe@users.sourceforge.net                                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#include <windows.h>
#include "wa_ipc.h"

typedef LPVOID (WINAPI *virtAllocEx)(
  HANDLE hProcess,  // process within which to allocate memory
  LPVOID lpAddress, // desired starting address of allocation
  DWORD dwSize,     // size, in bytes, of region to allocate
  DWORD flAllocationType,
                    // type of allocation
  DWORD flProtect   // type of access protection
);

typedef BOOL (WINAPI *virtFreeEx)(
  HANDLE hProcess,  // process within which to free memory
  LPVOID lpAddress, // starting address of memory region to free
  DWORD dwSize,     // size, in bytes, of memory region to free
  DWORD dwFreeType  // type of free operation
);

//getMetaInfo : used to grab some information about a filename designed to work with win9x/NT
int getMetaInfo(HWND hwWinamp,const char* filename,const char* field,char *buffer,unsigned long cbSize){
	OSVERSIONINFO osVer;
	extendedFileInfoStruct extFileStruct;
	DWORD ret;
	int successful;
	extendedFileInfoStruct* extFileStructRemote;
	char* fileNameRemote;
	char* fieldRemote;
	char* bufferRemote;

	//Win NT decls
	HINSTANCE hKernel;
	virtAllocEx allocEx;
	virtFreeEx freeEx;
	DWORD dwWinAmpProcId;
	HANDLE hWinampProc;

	//Win 9x/ME decls
	HANDLE hFileExtFileStruct;
	HANDLE hFileFileName;
	HANDLE hFileField;
	HANDLE hFileBuffer;


	successful=FALSE;

	osVer.dwOSVersionInfoSize=sizeof(osVer);
	GetVersionEx(&osVer);

	if (osVer.dwPlatformId==VER_PLATFORM_WIN32_NT){
		//We are under NT-like so we use VirtualAllocEx method
		//Get pointers to Virtual*Ex
		hKernel=GetModuleHandle("kernel32.dll");
		allocEx=(virtAllocEx) GetProcAddress(hKernel,"VirtualAllocEx");
		freeEx=(virtFreeEx) GetProcAddress(hKernel,"VirtualFreeEx");

		//Get handle over WinAmp process
		GetWindowThreadProcessId(hwWinamp,&dwWinAmpProcId);
		hWinampProc=OpenProcess(PROCESS_VM_OPERATION|PROCESS_VM_WRITE|PROCESS_VM_READ,FALSE,dwWinAmpProcId);

		//Allocate the buffers in WinAmp address space
		extFileStructRemote=(extendedFileInfoStruct*) allocEx(hWinampProc,NULL,sizeof(extFileStruct),MEM_COMMIT,PAGE_READWRITE);
		fileNameRemote=(char*) allocEx(hWinampProc,NULL,strlen(filename)+1,MEM_COMMIT,PAGE_READWRITE);
		fieldRemote=(char*) allocEx(hWinampProc,NULL,strlen(field)+1,MEM_COMMIT,PAGE_READWRITE);
		bufferRemote=(char*) allocEx(hWinampProc,NULL,cbSize,MEM_COMMIT,PAGE_READWRITE);

		//Fill the buffers allocated
		WriteProcessMemory(hWinampProc,fileNameRemote,(void *)filename,strlen(filename)+1,&ret);
		WriteProcessMemory(hWinampProc,fieldRemote,(void *) field,strlen(field)+1,&ret);
		extFileStruct.filename=fileNameRemote;
		extFileStruct.metadata=fieldRemote;
		extFileStruct.ret=bufferRemote;
		extFileStruct.retlen=cbSize;
		WriteProcessMemory(hWinampProc,extFileStructRemote,&extFileStruct,sizeof(extFileStruct),&ret);
		
		//Send request to Winamp
		if(SendMessage(hwWinamp,WM_WA_IPC,(WPARAM)extFileStructRemote,IPC_GET_EXTENDED_FILE_INFO)){
			ReadProcessMemory(hWinampProc,bufferRemote,buffer,cbSize,&ret);
			successful = TRUE;
		}

		//Clean the Winamp address space
		freeEx(hWinampProc,extFileStructRemote,0,MEM_DECOMMIT);
		freeEx(hWinampProc,fileNameRemote,0,MEM_DECOMMIT);
		freeEx(hWinampProc,fieldRemote,0,MEM_DECOMMIT);
		freeEx(hWinampProc,bufferRemote,0,MEM_DECOMMIT);

		//Close the process
		CloseHandle(hWinampProc);

		return successful;
	}
	else if (osVer.dwPlatformId==VER_PLATFORM_WIN32_WINDOWS) {
		//We are under 9x/Me so we use file mapping method

		//Allocate the buffers in global address space
		hFileExtFileStruct=CreateFileMapping((HANDLE) -1,NULL,PAGE_READWRITE|SEC_COMMIT,0,sizeof(extFileStruct),NULL);
		hFileFileName=CreateFileMapping((HANDLE) -1,NULL,PAGE_READWRITE|SEC_COMMIT,0,strlen(filename)+1,NULL);
		hFileField=CreateFileMapping((HANDLE) -1,NULL,PAGE_READWRITE|SEC_COMMIT,0,strlen(field)+1,NULL);
		hFileBuffer=CreateFileMapping((HANDLE) -1,NULL,PAGE_READWRITE|SEC_COMMIT,0,cbSize,NULL);

		extFileStructRemote=(extendedFileInfoStruct*) MapViewOfFile(hFileExtFileStruct,FILE_MAP_WRITE,0,0,0);
		fileNameRemote=(char*) MapViewOfFile(hFileFileName,FILE_MAP_WRITE,0,0,0);
		fieldRemote=(char*) MapViewOfFile(hFileField,FILE_MAP_WRITE,0,0,0);
		bufferRemote=(char*) MapViewOfFile(hFileBuffer,FILE_MAP_WRITE,0,0,0);

		//Fill the buffers allocated
		strcpy(fileNameRemote,filename);
		strcpy(fieldRemote,field);
		extFileStructRemote->filename=fileNameRemote;
		extFileStructRemote->metadata=fieldRemote;
		extFileStructRemote->ret=bufferRemote;
		extFileStructRemote->retlen=cbSize;

		//Send request to Winamp
		if(SendMessage(hwWinamp,WM_WA_IPC,(WPARAM)extFileStructRemote,IPC_GET_EXTENDED_FILE_INFO)){
			memcpy(buffer,bufferRemote,cbSize);
			successful=TRUE;
		}

		//Clean the global address space
		UnmapViewOfFile(extFileStructRemote);
		UnmapViewOfFile(fileNameRemote);
		UnmapViewOfFile(fieldRemote);
		UnmapViewOfFile(bufferRemote);
		CloseHandle(hFileExtFileStruct);
		CloseHandle(hFileFileName);
		CloseHandle(hFileField);
		CloseHandle(hFileBuffer);

		return successful;
	}
	else
		return FALSE;

}

int getFileName(HWND hwWinamp,unsigned long index,char* filename,unsigned long cbSize){
	DWORD dwWinAmpProcId;
	HANDLE hWinampProc;
	void* filenameRemote;
	DWORD ret;
	int successful=FALSE;

	//Get the process ID
	GetWindowThreadProcessId(hwWinamp,&dwWinAmpProcId);
	//Get a handle over Winamp
	hWinampProc=OpenProcess(PROCESS_VM_OPERATION|PROCESS_VM_WRITE|PROCESS_VM_READ,FALSE,dwWinAmpProcId);
	
	//Get the pointer over the current filename
	filenameRemote=(void *) SendMessage(hwWinamp,WM_WA_IPC,index,IPC_GETPLAYLISTFILE);
	if(filenameRemote!=NULL){
		//Copy into our address space the file name
		ReadProcessMemory(hWinampProc,filenameRemote,filename,cbSize,&ret);
		successful=TRUE;
	}

	//Close the handle we got
	CloseHandle(hWinampProc);

	return successful;
}

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	HWND hwWinamp;
	
	long position;
	long playState;
	unsigned long successful;
	char artist[1024]={'\0'};
	char title[1024]={'\0'};
	char file[1024]={'\0'};
	char *buffer;

	if((hwWinamp=FindWindow("Winamp v1.x",NULL))==NULL){ //WinAmp isn't launched so we say it's stopped
		WriteFile(GetStdHandle(STD_OUTPUT_HANDLE),"0\n",2,&successful,NULL);
		return 0;
	}
	//Get the playing status
	playState=(LONG)SendMessage(hwWinamp,WM_WA_IPC,0,IPC_ISPLAYING);
	//Get the postion in the play list
	position=SendMessage(hwWinamp,WM_WA_IPC,0,IPC_GETLISTPOS);

	//Get informations about the filename
	getFileName(hwWinamp,position,file,sizeof(file));
	getMetaInfo(hwWinamp,file,"ARTIST",artist,sizeof(artist));
	getMetaInfo(hwWinamp,file,"title",title,sizeof(artist));
	//Put informations on the output :
	//Status
	//Artist
	//Title
	//File
	buffer=(char *) HeapAlloc(GetProcessHeap(),0,4096);

	wsprintf(buffer,"%u\n%s\n%s\n%s\n",playState,title,artist,file);
	WriteFile(GetStdHandle(STD_OUTPUT_HANDLE),buffer,lstrlen(buffer),&successful,NULL);

	HeapFree(GetProcessHeap(),0,buffer);

	return 0;
}



