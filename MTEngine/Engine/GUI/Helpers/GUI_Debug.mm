#include "GUI_Debug.h"
#include "VID_GLViewController.h"

void BlitDebugBoxWithGrid(const float x, const float y, const float z, const float sizeX, const float sizeY, const float lineThick, float r, float g, float b, float a)
{
	const float lineThick2 = 2.0f*lineThick;
	BlitFilledRectangle(x, y, z, lineThick, sizeY, r, g, b, a);
	BlitFilledRectangle(x + lineThick, y, z, sizeX - lineThick2, lineThick, r, g, b, a);
	BlitFilledRectangle(x + sizeX - lineThick, y, z, lineThick, sizeY, r, g, b, a);
	BlitFilledRectangle(x + lineThick, y + sizeY - lineThick, z, sizeX - lineThick2, lineThick, r, g, b, a);
	
	const int numRects = 3;
	
	const int numSteps = numRects+1;
		
	const float fSteps = (float)numSteps-1.0f;
	
	const float sx = sizeX / fSteps;
	const float sy = sizeY / fSteps;

	const float lineThick2d = lineThick/2.0f;
	const float lineThick2d2d = lineThick2d/2.0f;
	const float lineThickMark = lineThick*1.5f;
	const float lineThickMark2d = lineThickMark/2.0f;
	const float gridThick = lineThick*0.25f;
	const float gridThick2d = gridThick/2.0f;
	const float gridLineOffset = (lineThick2d - gridThick) / 2.0f;

	float px = x;
	float py = y;
	
	const float pex = x + sizeX - lineThickMark;
	const float pey = y + sizeY - lineThickMark;
	
	const float lr = 0.0f; const float lg = 0.0f; const float lb = 0.0f; const float la= 0.5f * a;
	const float gr = 0.0f; const float gg = 0.0f; const float gb = 0.0f; const float ga= 0.2f * a;

	BlitFilledRectangle(px, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	BlitFilledRectangle(px, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	BlitFilledRectangle(px, y, z, gridThick, sizeY, gr, gg, gb, ga);
	
	BlitFilledRectangle(x, py, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	BlitFilledRectangle(pex, py, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	BlitFilledRectangle(x, py, z, sizeX, gridThick, gr, gg, gb, ga);

	px += sx;
	py += sy;

	const int numStepsM1 = numSteps-1;

	for (int i = 1; i < numStepsM1; i++)
	{
		BlitFilledRectangle(px - lineThick2d2d, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
		BlitFilledRectangle(px - lineThick2d2d, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);

		BlitFilledRectangle(x, py - lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
		BlitFilledRectangle(pex, py - lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);

		BlitFilledRectangle(px - gridThick2d, y, z, gridThick, sizeY, gr, gg, gb, ga);
		BlitFilledRectangle(x, py - gridThick2d, z, sizeX, gridThick, gr, gg, gb, ga);

		px += sx;
		py += sy;
	}
	
	BlitFilledRectangle(px - lineThick2d2d, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	BlitFilledRectangle(px - lineThick2d2d, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);

	BlitFilledRectangle(x, py-lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	BlitFilledRectangle(pex, py-lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);

	BlitFilledRectangle(px - gridThick, y, z, gridThick, sizeY, gr, gg, gb, ga);
	BlitFilledRectangle(x, py - gridThick, z, sizeX, gridThick, gr, gg, gb, ga);

}

void BlitDebugBox(const float x, const float y, const float z, const float sizeX, const float sizeY, const float lineThick, float r, float g, float b, float a)
{
	const float lineThick2 = 2.0f*lineThick;
	BlitFilledRectangle(x, y, z, lineThick, sizeY, r, g, b, a);
	BlitFilledRectangle(x + lineThick, y, z, sizeX - lineThick2, lineThick, r, g, b, a);
	BlitFilledRectangle(x + sizeX - lineThick, y, z, lineThick, sizeY, r, g, b, a);
	BlitFilledRectangle(x + lineThick, y + sizeY - lineThick, z, sizeX - lineThick2, lineThick, r, g, b, a);
	
	const int numRects = 3;
	
	const int numSteps = numRects+1;
	
	const float fSteps = (float)numSteps-1.0f;
	
	const float sx = sizeX / fSteps;
	const float sy = sizeY / fSteps;
	
	const float lineThick2d = lineThick/2.0f;
	const float lineThick2d2d = lineThick2d/2.0f;
	const float lineThickMark = lineThick*3.0f;
	
	float px = x;
	float py = y;
	
	const float pex = x + sizeX - lineThickMark;
	const float pey = y + sizeY - lineThickMark;
	
	const float lr = 0.0f; const float lg = 0.0f; const float lb = 0.0f; const float la= 0.7f * a;
	
	BlitFilledRectangle(px, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	BlitFilledRectangle(px, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	
	BlitFilledRectangle(x, py, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	BlitFilledRectangle(pex, py, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	
	px += sx;
	py += sy;
	
	const int numStepsM1 = numSteps-1;
	
	for (int i = 1; i < numStepsM1; i++)
	{
		BlitFilledRectangle(px - lineThick2d2d, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
		BlitFilledRectangle(px - lineThick2d2d, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);
		
		BlitFilledRectangle(x, py - lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
		BlitFilledRectangle(pex, py - lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
		
		px += sx;
		py += sy;
	}
	
	BlitFilledRectangle(px - lineThick2d2d, y, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	BlitFilledRectangle(px - lineThick2d2d, pey, z, lineThick2d, lineThickMark, lr, lg, lb, la);
	
	BlitFilledRectangle(x, py-lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	BlitFilledRectangle(pex, py-lineThick2d2d, z, lineThickMark, lineThick2d, lr, lg, lb, la);
	
}
