#ifndef _M_COLOR_SPACES_
#define _M_COLOR_SPACES_


typedef struct {
	double r;       // percent
	double g;       // percent
	double b;       // percent
} rgb;

typedef struct {
	double h;       // angle in degrees
	double s;       // percent
	double v;       // percent
} hsv;

hsv      rgb2hsv(rgb in);
rgb      hsv2rgb(hsv in);

#endif
//_M_COLOR_SPACES_