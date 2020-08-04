/*
 *  SYS_PIPE.h
 Created by Marcin Skoczylas on 2013-06-14.
 Copyright 2013 Marcin Skoczylas
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#ifndef _SYS_PIPE_h_
#define _SYS_PIPE_h_

#include "SYS_Defs.h"

class CByteBuffer;

void PIPE_Init();
void PIPE_Printf(const char *format, ...);
void PIPE_SendStr(const char *buffer);
bool PIPE_Send(const unsigned char *buffer, long len);
bool PIPE_SendByteBuffer(CByteBuffer *byteBuffer);

int PIPE_Open(char *device);
void PIPE_SetOptions(char *device, int baudRate);
void PIPE_SetOptions(int fd, int baudRate);

#endif

