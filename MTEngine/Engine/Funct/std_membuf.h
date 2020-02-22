#ifndef _STD_MEMBUF_H_
#define _STD_MEMBUF_H_

//#include <fstream>
//#include <iostream>
//#include <string>
//#include <vector>

class std_membuf : public std::basic_streambuf<char>
{
public:
	std_membuf(unsigned char *data, size_t n) {
		char *p = (char*)data;
		setg(p, p, p + n);
		setp(p, p + n);
	}
};

//Usage:
//
//char *mybuffer;
//size_t length;
//// ... allocate "mybuffer", put data into it, set "length"
//
//std_membuf mb(mybuffer, length);
//istream reader(&mb);
//// use "reader"

#endif
// _STD_MEMBUF_H_

