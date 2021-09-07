#include "win-registry.h"
#include <stdlib.h>
#include <stdio.h>

#define TOTAL_BYTES_READ    1024
#define OFFSET_BYTES 1024
//Create key in registry
BOOL CreateRegistryKey(HKEY hKeyParent,LPCSTR subkey)
{
    DWORD dwDisposition; //It verify new key is created or open existing key
    HKEY  hKey;
    DWORD Ret;
    Ret =
        RegCreateKeyEx(
            hKeyParent,
            subkey,
            0,
            NULL,
            REG_OPTION_NON_VOLATILE,
            KEY_ALL_ACCESS,
            NULL,
            &hKey,
            &dwDisposition);
    if (Ret != ERROR_SUCCESS)
    {
        printf("Error opening or creating key.\n");
        return FALSE;
    }
    RegCloseKey(hKey);
    return TRUE;
}
//Write data in registry
BOOL WriteDwordInRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName,DWORD data)
{
    DWORD Ret;
    HKEY hKey;
    //Open the key
    Ret = RegOpenKeyEx(
              hKeyParent,
              subkey,
              0,
              KEY_WRITE,
              &hKey
          );
    if (Ret == ERROR_SUCCESS)
    {
        //Set the value in key
        if (ERROR_SUCCESS !=
                RegSetValueEx(
                    hKey,
                    valueName,
                    0,
                    REG_DWORD,
                    reinterpret_cast<BYTE *>(&data),
                    sizeof(data)))
        {
            RegCloseKey(hKey);
            return FALSE;
        }
        //close the key
        RegCloseKey(hKey);
        return TRUE;
    }
    return FALSE;
}
//Read data from registry
BOOL readDwordValueRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, DWORD *readData)
{
    HKEY hKey;
    DWORD Ret;
    //Check if the registry exists
    Ret = RegOpenKeyEx(
              hKeyParent,
              subkey,
              0,
              KEY_READ,
              &hKey
          );
    if (Ret == ERROR_SUCCESS)
    {
        DWORD data;
        DWORD len = sizeof(DWORD);//size of data
        Ret = RegQueryValueEx(
                  hKey,
                  valueName,
                  NULL,
                  NULL,
                  (LPBYTE)(&data),
                  &len
              );
        if (Ret == ERROR_SUCCESS)
        {
            RegCloseKey(hKey);
            (*readData) = data;
            return TRUE;
        }
        RegCloseKey(hKey);
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}
//Write range and type into the registry
BOOL writeStringInRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, LPCSTR strData)
{
    DWORD Ret;
    HKEY hKey;
    //Check if the registry exists
    Ret = RegOpenKeyEx(
              hKeyParent,
              subkey,
              0,
              KEY_WRITE,
              &hKey
          );
    if (Ret == ERROR_SUCCESS)
    {
        if (ERROR_SUCCESS !=
                RegSetValueEx(
                    hKey,
                    valueName,
                    0,
                    REG_SZ,
                    (LPBYTE)(strData),
                    ((((DWORD)lstrlen(strData) + 1)) * 2)))
        {
            RegCloseKey(hKey);
            return FALSE;
        }
        RegCloseKey(hKey);
        return TRUE;
    }
    return FALSE;
}
//read customer infromation from the registry
BOOL readUserInfoFromRegistry(HKEY hKeyParent, LPCSTR subkey, LPCSTR valueName, LPCSTR *readData)
{
    HKEY hKey;
    DWORD len = TOTAL_BYTES_READ;
    DWORD readDataLen = len;
    LPCSTR readBuffer = (LPCSTR )malloc(sizeof(LPCSTR)* len);
    if (readBuffer == NULL)
        return FALSE;
    //Check if the registry exists
    DWORD Ret = RegOpenKeyEx(
                    hKeyParent,
                    subkey,
                    0,
                    KEY_READ,
                    &hKey
                );
    if (Ret == ERROR_SUCCESS)
    {
        Ret = RegQueryValueEx(
                  hKey,
                  valueName,
                  NULL,
                  NULL,
                  (BYTE*)readBuffer,
                  &readDataLen
              );
        while (Ret == ERROR_MORE_DATA)
        {
            // Get a buffer that is big enough.
            len += OFFSET_BYTES;
            readBuffer = (LPCSTR)realloc((void*)readBuffer, len);
            readDataLen = len;
            Ret = RegQueryValueEx(
                      hKey,
                      valueName,
                      NULL,
                      NULL,
                      (BYTE*)readBuffer,
                      &readDataLen
                  );
        }
        if (Ret != ERROR_SUCCESS)
        {
            RegCloseKey(hKey);
            return false;;
        }
        *readData = readBuffer;
        RegCloseKey(hKey);
        return true;
    }
    else
    {
        return false;
    }
}