#ifndef _win_registry_h_
#define _win_registry_h_

#include <windows.h>
#include <winreg.h>

// code taken from: https://aticleworld.com/reading-and-writing-windows-registry/

BOOL CreateRegistryKey(HKEY hKeyParent,LPCSTR subkey);
BOOL WriteDwordInRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName,DWORD data);
BOOL readDwordValueRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, DWORD *readData);
BOOL writeStringInRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, LPCSTR strData);
BOOL readUserInfoFromRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, LPCSTR *readData);

#endif