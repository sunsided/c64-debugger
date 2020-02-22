#include "SYS_PIPE.h"
#include "SYS_Main.h"
#include "SYS_Threading.h"
#include "SYS_Funct.h"
#include "CByteBuffer.h"
#include "INT_BinaryProtocol.h"
#include <stdio.h>
#include <fcntl.h>

#if !defined(WIN32)
#include <unistd.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#endif

#define DEBUG_PRINT_PIPE_DATA

#define MAX_PACKET_LENGTH	1024*4

#if defined(MACOS) || defined(LINUX)
int fdWritePIPE = -1;
int fdReadPIPE = -1;

#define FIFO_WRITE_PIPE_PATH "/tmp/c64debugger-%lu-out.pipe"
#define FIFO_READ_PIPE_PATH "/tmp/c64debugger-%lu-in.pipe"
//#define FIFO_WRITE_PIPE_PATH "/tmp/c64debugger-out.pipe"
//#define FIFO_READ_PIPE_PATH "/tmp/c64debugger-in.pipe"

#elif defined(WIN32)

HANDLE hPipeWrite;
HANDLE hPipeRead;
DWORD dwRead;
#define FIFO_WRITE_PIPE_PATH "\\\\.\\pipe\\c64debugger-%d-out"
#define FIFO_READ_PIPE_PATH "\\\\.\\pipe\\d64debugger-%d-in"

#endif

// pass thread
CSlrMutex *mutexPIPE;

class CPipeReadPacketsThread : public CSlrThread
{
public:
	virtual void ThreadRun(void *data);
};


CPipeReadPacketsThread *threadPipeReadPackets;

CByteBuffer *pipeReadByteBuffer;

// data

#define PIPE_BUF_SIZE 1024*1024

static u8 pipePacketMagic[4] = { 0xC0, 0xDE, 0xFE, 0xED };

void PIPE_Init()
{
	LOGD("PIPE_Init");

	mutexPIPE = new CSlrMutex("mutexPIPE");
	pipeReadByteBuffer = new CByteBuffer();
	
	char *buf = SYS_GetCharBuf();
	char *pipeWritePath = SYS_GetCharBuf();
	char *pipeReadPath = SYS_GetCharBuf();

	unsigned long pid = SYS_GetProcessId();

	sprintf(pipeWritePath, FIFO_WRITE_PIPE_PATH, pid);
	sprintf(pipeReadPath, FIFO_READ_PIPE_PATH, pid);

#if defined(LINUX) || defined(MACOS)
	/// Output Pipe
	LOGM("PIPE_Init: Create out fifo pipe at %s", pipeWritePath);
	unlink(pipeWritePath);
	umask(0);
	
	sprintf(buf, "rm -rf %s", pipeWritePath);
	system(buf);
	
	if(mkfifo(pipeWritePath, 0666) == -1)
	{
		LOGError("Create out fifo pipe at %s failed", pipeWritePath);
		return;
	}
	
	fdWritePIPE = open(pipeWritePath, O_RDWR | O_SYNC);
	
	if (fdWritePIPE == -1)
	{
		LOGError("Output pipe at %s failed to open", pipeWritePath);
	}
	else
	{
		LOGM("Output pipe at %s opened for O_RDWR", pipeWritePath);
		
		int flags = fcntl(fdWritePIPE, F_GETFL, 0);
		if(fcntl(fdWritePIPE, F_SETFL, flags | O_NONBLOCK))
		{
			LOGM("Output pipe failed to set O_NONBLOCK");
		}
	}
	
	/// Input Pipe
	LOGM("PIPE_Init: Create in fifo pipe at %s", pipeReadPath);
	unlink(pipeReadPath);
	umask(0);
	
	sprintf(buf, "rm -rf %s", pipeReadPath);
	system(buf);
	
	if(mkfifo(pipeReadPath, 0666) == -1)
	{
		LOGError("Create in fifo pipe at %s failed", pipeReadPath);
		return;
	}
	
	fdReadPIPE = open(pipeReadPath, O_RDWR | O_SYNC);
	
	if (fdReadPIPE == -1)
	{
		LOGError("Input pipe at %s failed to open", pipeReadPath);
	}
	else
	{
		LOGM("Input pipe at %s opened for O_RDWR", pipeReadPath);
		
		int flags = fcntl(fdReadPIPE, F_GETFL, 0);
		if(fcntl(fdReadPIPE, F_SETFL, flags | O_NONBLOCK))
		{
			LOGM("Input pipe failed to set O_NONBLOCK");
		}
	}

#elif defined(WIN32)
	
	// TODO
	
#endif
	
	// PIPEs created
	SYS_ReleaseCharBuf(pipeWritePath);
	SYS_ReleaseCharBuf(pipeReadPath);
	SYS_ReleaseCharBuf(buf);
	
	threadPipeReadPackets = new CPipeReadPacketsThread();
	threadPipeReadPackets->ThreadSetName("PIPEread");
	SYS_StartThread(threadPipeReadPackets);
}

void PIPE_Printf(const char *format, ...)
{
	mutexPIPE->Lock();
	
	static char buffer[PIPE_BUF_SIZE];
	memset(buffer, 0x00, PIPE_BUF_SIZE);
	
	va_list args;
	
	va_start(args, format);
	vsnprintf(buffer, PIPE_BUF_SIZE, format, args);
	va_end(args);

	long len = strlen(buffer)+1;
	
#if defined(LINUX) || defined(MACOS)
	long written = write(fdWritePIPE, buffer, len);
	fsync(fdWritePIPE);

#elif defined(WIN32)
	// TODO
	long written = 0;
#endif
	
	if (written != len)
	{
		LOGError("PIPE_Printf: buffer overflow");
	}

	LOGM("PIPE_Printf done: sent '%s'", buffer);


#ifdef DEBUG_PRINT_PIPE_DATA
	LOGD("PIPE_Printf: buffer='%s' len=%d. Binary:", buffer, strlen(buffer));
#endif
	
	mutexPIPE->Unlock();
	
}

void PIPE_SendStr(const char *buffer)
{
	mutexPIPE->Lock();

	u8 zero = 0x00;

#if defined(LINUX) || defined(MACOS)
	write(fdWritePIPE, buffer, strlen(buffer));
	write(fdWritePIPE, &zero, 1);
	fsync(fdWritePIPE);
#elif defined(WIN32)
	// TODO
	
#endif

	mutexPIPE->Unlock();
}

bool PIPE_Send(const unsigned char *buffer, long len)
{
#if defined(LINUX) || defined(MACOS)
	if (fdWritePIPE < 0)
	{
		LOGError("PIPE_Send: no Write PIPE fd, failing");
		return false;
	}
#elif defined(WIN32)
	// TODO
	return false;

#endif
	
	mutexPIPE->Lock();
	
#ifdef DEBUG_PRINT_PIPE_DATA
	LOGD("PIPE_Send: buffer len=%d. Binary:", buffer, len);
	char *buf = new char[len * 4];
	buf[0] = 0x00;
	
	char *buf2 = SYS_GetCharBuf();
	for (int i = 0; i < len; i++)
	{
		sprintf(buf2, "%02x ", buffer[i]);
		strcat(buf, buf2);
	}
	
	SYS_ReleaseCharBuf(buf2);
	LOGD("%s", buf);
	
	delete [] buf;
#endif
	
#if defined(LINUX) || defined(MACOS)
	long written = write(fdWritePIPE, buffer, len);
	fsync(fdWritePIPE);
#elif defined(WIN32)
	// TODO
	long written = 0;
#endif

	if (written != len)
	{
		LOGError("PIPE_Send: buffer overflow");
		return false;
	}
	
	mutexPIPE->Unlock();
	return true;
}

bool PIPE_SendByteBuffer(CByteBuffer *byteBuffer)
{
	if (PIPE_Send(pipePacketMagic, 4) == false)
	{
		return false;
	}

	u8 lenBuf[4];
	
	lenBuf[0] = (u8) (((byteBuffer->length) >> 24) & 0x00FF);
	lenBuf[1] = (u8) (((byteBuffer->length) >> 16) & 0x00FF);
	lenBuf[2] = (u8) (((byteBuffer->length) >> 8) & 0x00FF);
	lenBuf[3] = (u8) ( (byteBuffer->length) & 0x00FF);

	if (PIPE_Send(lenBuf, 4) == false)
	{
		return false;
	}
	
	if (PIPE_Send(byteBuffer->data, byteBuffer->length) == false)
	{
		return false;
	}
	
	return true;
}

//

void CPipeReadPacketsThread::ThreadRun(void *data)
{
	LOGM("PIPE Read Packets Thread started");
	
#if defined(MACOS) || defined(LINUX)
	if (fdReadPIPE < 0)
	{
		LOGError("CPipeReadPacketsThread::ThreadRun: no Read PIPE fd, failing");
		return;
	}
#elif defined(WIN32)
	// TODO
	return;
#endif

	u8 *readBuffer = new u8[PIPE_BUF_SIZE];
	u8 *readPointer = readBuffer;
	
	long bufferCount = 0;
	
	while (true)
	{
		long count = 0;
		
#if defined(LINUX) || defined(MACOS)
		count = read(fdReadPIPE, readPointer, PIPE_BUF_SIZE);
#elif defined(WIN32)
		// TODO
		
#endif

		if ( (count < 0 && (errno == EAGAIN || errno == EINTR))
			|| (count == 0))
		{
			// no data read
			SYS_Sleep(5);
			continue;
		}
		else if (count > 0)
		{
			readPointer += count;
			bufferCount += count;
			
//			LOGD("count=%d bufferCount=%d", count, bufferCount);
			
			while ( bufferCount > (4 + 4) )
			{
//				LOGD("===>>>> bufferCount=%d", bufferCount);
				
				// check for magic
				if (   readBuffer[0] == pipePacketMagic[0]
					&& readBuffer[1] == pipePacketMagic[1]
					&& readBuffer[2] == pipePacketMagic[2]
					&& readBuffer[3] == pipePacketMagic[3])
				{
					// get length of packet
					u32 packetLength = readBuffer[7] | (readBuffer[6] << 8) | (readBuffer[5] << 16) | (readBuffer[4] << 24);
					
					if (packetLength > MAX_PACKET_LENGTH)
					{
						LOGError("Packet length=%d > MAX_PACKET_LENGTH=%d, resetting", packetLength, MAX_PACKET_LENGTH);
						bufferCount = 0;
						readPointer = readBuffer;
						break;
					}
					
					long packetBufferCount = bufferCount - (4+4);
					
//					LOGD("bufferCount=%d packetBufferCount=%d packetLength=%d", bufferCount, packetBufferCount, packetLength);
					if (packetBufferCount >= packetLength)
					{
//						LOGD("   read packet");
						pipeReadByteBuffer->Clear();
						pipeReadByteBuffer->PutBytes(readBuffer + (4+4), packetLength);
						pipeReadByteBuffer->Rewind();
						
						// parse & interpret received data
//						LOGD("   INT_InterpretBinaryPacket");
						INT_InterpretBinaryPacket(pipeReadByteBuffer);
						
						// move data
						long bytesLeft = bufferCount - (4+4) - (long)packetLength;
//						LOGD("   moving, bytesLeft=%d", bytesLeft);
						
						//	sanity check error: memcpy(readBuffer, readBuffer+packetLength, bytesLeft);
						//                void	*memcpy(void *__dst, const void *__src, size_t __n);
						
						for (int i = 0; i < bytesLeft; i++)
						{
							readBuffer[i] = readBuffer[8 + packetLength + i];
						}
						
						bufferCount -= (8 + packetLength);
						readPointer -= (8 + packetLength);
					}
					else
					{
						break;
					}
				}
				else
				{
					LOGD("** bad magic: %02x %02x %02x %02x, rolling", readBuffer[0], readBuffer[1], readBuffer[2], readBuffer[3]);
					// bad magic, roll one byte and repeat
					for (int i = 1; i < bufferCount; i++)
					{
						readBuffer[i-1] = readBuffer[i];
					}
					
					readPointer--;
					bufferCount--;
					
//					LOGD("  rolled bufferCount=%d", bufferCount);
				}
			}
		}
		else
		{
			LOGError("PIPE read failed: errno=%d", errno);
		}
	}
	
	LOGM("PIPE Read Packets Thread finished");
}

int PIPE_Open(char *device)
{
//	LOGD("PIPE_Open: %s", device);
//	int fd = open(device, O_RDWR | O_NDELAY | O_NOCTTY);
//	
//	if (fd == -1)
//	{
//		LOGError("Failed to open UART device at %s", device);
//		return -1;
//	}
//	
//	PIPE_SetOptions(fd, BAUD_RATE);
//	return fd;
	return -1;
}

void PIPE_SetOptions(char *device, int baudRate)
{
	
//#ifndef USE_PIPE
//	char *buf = SYS_GetCharBuf();
//	
//#ifndef MACOS
//	sprintf(buf, "%s -F %s %d", STTY_PATH, configPIPEWriteDevice, BAUD_RATE);
//#else
//	sprintf(buf, "%s -f %s %d", STTY_PATH, configPIPEWriteDevice, BAUD_RATE);
//#endif
//	
//	int ret = system(buf);
//	if (ret != 0)
//	{
//		LOGError("stty failed with error %d", ret);
//	}
//	SYS_ReleaseCharBuf(buf);
//	
//	//		int flags = fcntl(fd, F_GETFL, 0);
//	//		if(fcntl(fd, F_SETFL, flags | O_NONBLOCK))
//	//		{
//	//			LOGError("UART at %s failed to set O_NONBLOCK", );
//	//		}
//#endif
//	
}

void PIPE_SetOptions(int fd, int baudRate)
{
//	struct termios config;
//	
//	speed_t br = B115200;
//	
//	switch(baudRate)
//	{
//		case 50:		br = B50;		break;
//		case 75:		br = B75;		break;
//		case 110:		br = B110;		break;
//		case 134:		br = B134;		break;
//		case 150:		br = B150;		break;
//		case 200:		br = B200;		break;
//		case 300:		br = B300;		break;
//		case 600:		br = B600;		break;
//		case 1200:		br = B1200;		break;
//		case 1800:		br = B1800;		break;
//		case 2400:		br = B2400;		break;
//		case 4800:		br = B4800;		break;
//		case 9600:		br = B9600;		break;
////		case 14400:		br = B14400;	break;
////		case 28800:		br = B28800;	break;
//		case 19200:		br = B19200;	break;
//		case 38400:		br = B38400;	break;
//		case 57600:		br = B57600;	break;
////		case 76800:		br = B76800;	break;
//		case 115200:	br = B115200;	break;
//		case 230400:	br = B230400;	break;
//		default:
//			SYS_FatalExit("PIPE_SetOptions: unsupported baud rate %d", baudRate);
//	}
//	
//	if (tcgetattr(fd, &config) < 0)
//	{
//		LOGError("UART_SetOptions: can't get serial attributes");
//		return;
//	}
//	
//	if (cfsetispeed(&config, br) < 0)
//	{
//		LOGError("UART_SetOptions: can't set baud rate %d (cfsetispeed failed errno=%d)", baudRate, errno);
//		return;
//	}
//	
//	if (cfsetospeed(&config, br) < 0)
//	{
//		LOGError("UART_SetOptions: can't set baud rate %d (cfsetospeed failed errno=%d)", baudRate, errno);
//		return;
//	}
//	
//	config.c_iflag &= ~(IGNBRK | BRKINT | ICRNL | INLCR | PARMRK | INPCK | ISTRIP | IXON);
//	config.c_oflag = 0;
//	config.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN | ISIG);
//	config.c_cflag &= ~(CSIZE | PARENB);
//	config.c_cflag |= CS8;
//	config.c_cc[VMIN]  = 1;
//	config.c_cc[VTIME] = 0;
//	
//	if (tcsetattr(fd, TCSAFLUSH, &config) < 0)
//	{
//		LOGError("UART_SetOptions: can't set serial attributes");
//		return;
//	}
}

/* TODO: port to Windows
https://stackoverflow.com/questions/26561604/create-named-pipe-c-windows
 
int main(void)
{
	HANDLE hPipe;
	char buffer[1024];
	DWORD dwRead;
	
	
	hPipe = CreateNamedPipe(TEXT("\\\\.\\pipe\\Pipe"),
							PIPE_ACCESS_DUPLEX,
							PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,   // FILE_FLAG_FIRST_PIPE_INSTANCE is not needed but forces CreateNamedPipe(..) to fail if the pipe already exists...
							1,
							1024 * 16,
							1024 * 16,
							NMPWAIT_USE_DEFAULT_WAIT,
							NULL);
	while (hPipe != INVALID_HANDLE_VALUE)
	{
		if (ConnectNamedPipe(hPipe, NULL) != FALSE)   // wait for someone to connect to the pipe
		{
			while (ReadFile(hPipe, buffer, sizeof(buffer) - 1, &dwRead, NULL) != FALSE)
			{
				// add terminating zero
				buffer[dwRead] = '\0';
				
				// do something with data in buffer
				printf("%s", buffer);
			}
		}
		
		DisconnectNamedPipe(hPipe);
	}
	
	return 0;
}

int main(void)
{
	HANDLE hPipe;
	DWORD dwWritten;
	
	
	hPipe = CreateFile(TEXT("\\\\.\\pipe\\Pipe"),
					   GENERIC_READ | GENERIC_WRITE,
					   0,
					   NULL,
					   OPEN_EXISTING,
					   0,
					   NULL);
	if (hPipe != INVALID_HANDLE_VALUE)
	{
		WriteFile(hPipe,
				  "Hello Pipe\n",
				  12,   // = length of string + terminating '\0' !!!
				  &dwWritten,
				  NULL);
		
		CloseHandle(hPipe);
	}
	
	return (0);
}
*/
