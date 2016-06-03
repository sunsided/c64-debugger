class Utf8
{
public:
    Utf8(const wchar_t* wsz): m_utf8(NULL)
    {
    	// OS X uses 32-bit wchar
    	const int bytes = wcslen(wsz) * sizeof(wchar_t);
        // comp_bLittleEndian is in the lib I use in order to detect PowerPC/Intel
    	CFStringEncoding encoding = comp_bLittleEndian ? kCFStringEncodingUTF32LE
                                                       : kCFStringEncodingUTF32BE;
    	CFStringRef str = CFStringCreateWithBytesNoCopy(NULL, 
    	                                               (const UInt8*)wsz, bytes, 
    	                                                encoding, false, 
    	                                                kCFAllocatorNull
    	                                                );

    	const int bytesUtf8 = CFStringGetMaximumSizeOfFileSystemRepresentation(str);
    	m_utf8 = new char[bytesUtf8];
    	CFStringGetFileSystemRepresentation(str, m_utf8, bytesUtf8);
    	CFRelease(str);
    }	

    ~Utf8() 
    { 
    	if( m_utf8 )
    	{
    		delete[] m_utf8;
    	}
    }

public:
    operator const char*() const { return m_utf8; }

private:
    char* m_utf8;
};

Usage:

const wchar_t wsz = L"Here is some Unicode content: éà€œæ";
const Utf8 utf8 = wsz;
FILE* file = fopen(utf8, "r");

