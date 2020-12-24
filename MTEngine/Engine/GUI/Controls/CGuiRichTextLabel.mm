/*
 *  CGuiMultilineLabel.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#define DEFAULT_LABEL_ZOOM 1.0

#include "CGuiRichTextLabel.h"
#include "VID_GLViewController.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CContinuousParamLinear.h"
#include "CContinuousParamSin.h"

#define PARSE_NUM_COLORS 10
const char *colorNames[PARSE_NUM_COLORS] = {
		"black",
		"white",
		"gray",
		"red",
		"green",
		"blue",
		"cyan",
		"yellow",
		"purple"
};

const float colorVals[PARSE_NUM_COLORS][3] = {
		{0.0f, 0.0f, 0.0f},	//black
		{1.0f, 1.0f, 1.0f},	//white
		{0.5f, 0.5f, 0.5f},	//gray
		{1.0f, 0.0f, 0.0f},	//red
		{0.0f, 1.0f, 0.0f},	//green
		{0.0f, 0.0f, 1.0f},	//blue
		{0.0f, 1.0f, 1.0f},	//cyan
		{1.0f, 1.0f, 0.0f},	//yellow
		{1.0f, 0.0f, 1.0f}	//purple
};


bool CGuiRichTextLabelCallback::RichTextLabelClicked(CGuiRichTextLabel *button)
{
	return true;
}

bool CGuiRichTextLabelCallback::RichTextLabelPressed(CGuiRichTextLabel *button)
{
	return true;
}


CGuiRichTextLabel::CGuiRichTextLabel(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float scale, CGuiRichTextLabelCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->sizeX = DEFAULT_LABEL_ZOOM * sizeX;
	this->sizeY = DEFAULT_LABEL_ZOOM * sizeY;

	this->scale = scale;

	this->startFontColorR = 1.0f;
	this->startFontColorG = 1.0f;
	this->startFontColorB = 1.0f;
	this->startFontColorA = 1.0f;

	this->Init();
	
	this->text = NULL;
	SetText(text);
}

CGuiRichTextLabel::CGuiRichTextLabel(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float scale, CGuiRichTextLabelCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->callback = callback;
	
	this->posX = posX;
	this->posY = posY;
	this->sizeX = DEFAULT_LABEL_ZOOM * sizeX;
	this->sizeY = DEFAULT_LABEL_ZOOM * sizeY;
	
	this->scale = scale;
	
	this->startFontColorR = 1.0f;
	this->startFontColorG = 1.0f;
	this->startFontColorB = 1.0f;
	this->startFontColorA = 1.0f;

	this->Init();
	
	this->text = NULL;
	SetText(text);
}

void CGuiRichTextLabel::Init()
{
	this->name = "CGuiMultilineLabel:Text";
	this->beingClicked = false;
	this->transparentToTaps = false;

	tagStopChars.clear();
	tagStopChars.push_back(' ');
	tagStopChars.push_back('=');
	tagStopChars.push_back('>');
	tagOpenStopChars.push_back('<');
	whiteSpaceChars.push_back(' ');
	
	this->SetParametersNoParse(guiMain->fntEngineDefault, scale, 1.0f, 1.0f, 1.0f, 1.0f, RICH_TEXT_LABEL_ALIGNMENT_RIGHT);
}

void CGuiRichTextLabel::SetParameters(CSlrFont *font, float scale, float r, float g, float b, float a, byte alignment)
{
	this->SetParametersNoParse(font, scale, r, g, b, a, alignment);
	this->Parse();
}

void CGuiRichTextLabel::SetParametersNoParse(CSlrFont *font, float scale, float r, float g, float b, float a, byte alignment)
{
	this->currentAlignment = alignment;
	
	this->currentFont = font;
	this->currentFontScale = 1.0f; //scale;

	this->startFontColorR = r;
	this->startFontColorG = g;
	this->startFontColorB = b;
	this->startFontColorA = a;

	this->currentFontColorR = r;
	this->currentFontColorG = g;
	this->currentFontColorB = b;
	this->currentFontColorA = a;
	
	this->scale = scale;	
}

void CGuiRichTextLabel::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiElement::SetPosition(posX, posY, posZ, sizeX, sizeY);
	this->Parse();
}

void CGuiRichTextLabel::SetPositionNoParse(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiElement::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

CGuiRichTextLabel::~CGuiRichTextLabel()
{
	this->DeleteElements();

	if (this->text != NULL)
	{
		delete this->text;
	}
}

void CGuiRichTextLabel::SetText(const char *text)
{
	this->beingClicked = false;
	this->clickConsumed = false;

	if (this->text != NULL)
	{
		delete this->text;
	}
	this->text = new CSlrString(text);

	this->Parse();
}

void CGuiRichTextLabel::SetText(CSlrString *text)
{
	this->beingClicked = false;
	this->clickConsumed = false;
	
	if (this->text != NULL)
	{
		delete this->text;
	}
	this->text = new CSlrString(text);
	
	this->Parse();
}

void CGuiRichTextLabel::UpdateFont()
{
	currentSpaceWidth = this->currentFont->GetCharWidth(' ', this->currentFontScale * this->scale) * 2.0f;
	currentFontHeight = this->currentFont->GetLineHeight() * this->currentFontScale * this->scale;
}

void CGuiRichTextLabel::DeleteElements()
{
	/*
	u32 i = 0;
	LOGD("size=%d", this->elements.size());
	
	for (std::list<CGuiRichTextLabelElement *>::iterator it = elements.begin(); it != elements.end(); it++)
	{
		CGuiRichTextLabelElement *elem = *it;
		LOGD("i=%d type=%d", i, elem->type);
		
		i++;
	}
	 */
	
	//i = 0;
	while(!(this->elements.empty()))
	{
		CGuiRichTextLabelElement *el = this->elements.front();
		//LOGD("deleting i=%d el=%d ", i, el->type);
		
		this->elements.pop_front();
		
		//LOGD("delete el");
		delete el;
		
		//i++;
	}
}

void CGuiRichTextLabel::Parse()
{
	LOGD("CGuiRichTextLabel::Parse:");

	this->text->DebugPrint("text=");

	this->DeleteElements();

	textElements.clear();
	tags.clear();
	vals.clear();

	currentAlignment = RICH_TEXT_LABEL_ALIGNMENT_LEFT;
	currentFontColorR = startFontColorR;
	currentFontColorG = startFontColorG;
	currentFontColorB = startFontColorB;
	currentFontColorA = startFontColorA;
	currentGapHeight = 0.0f;
	
	currentBlinkMode = RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_OFF;
	currentBlinkParamMin = 0.0f;
	currentBlinkParamMax = 1.0f;
	currentBlinkParamNumFrames = FRAMES_PER_SECOND;

	this->UpdateFont();

	this->currentX = 0;
	this->currentY = 0;

	u32 pos = 0;
	u32 retPos = 0;

	while(pos < text->GetLength())
	{
//		LOGD("pos=%d c=%c (%4.4x)", pos, text->GetChar(pos), text->GetChar(pos));
//		text->DebugPrint("text", pos);

		if (text->CompareWith(pos, '<'))
		{
			unsigned long tt1 = SYS_GetCurrentTimeInMillis();
			
			tags.clear();
			vals.clear();

			while(pos < text->GetLength())
			{
				pos++;
				pos = text->SkipChars(pos, whiteSpaceChars);

				// get tag name
				CSlrString *tag = text->GetWord(pos, &retPos, tagStopChars);
				tags.push_back(tag);

				//tag->DebugPrint("tag=");

				pos = retPos;

				//text->DebugPrint("text", pos);

				if (text->CompareWith(pos, '='))
				{
					// value
					pos++;
					pos = text->SkipChars(pos, whiteSpaceChars);

					CSlrString *val = text->GetWord(pos, &retPos, tagStopChars);
					vals.push_back(val);

					//val->DebugPrint("value=");

					pos = retPos;

				}
				else
				{
					// just push empty string
					vals.push_back(new CSlrString());
					//LOGD("value=NULL");
				}

				if (text->CompareWith(pos, '>'))
				{
					break;
				}
			}

//			LOGD(">>>>>>>>>>>>>>>>>>>>>> parsing tags");
			u32 tn = 0;
			std::list<CSlrString *>::iterator itVals = vals.begin();
			for (std::list<CSlrString *>::iterator itTags = tags.begin(); itTags != tags.end(); itTags++, itVals++)
			{
//				LOGD("=== #%d", tn);
				CSlrString *tag = (*itTags);
				CSlrString *value = (*itVals);

//				tag->DebugPrint("tag=");
//				value->DebugPrint("val=");
				tn++;
			}

			CSlrString *tag = tags.front();
			CSlrString *value = vals.front();

			if (tag->Equals("color"))
			{
				// color by value
				if (value->Contains(','))
				{
					std::vector<CSlrString *> *colors = value->Split(',');

					if (colors->size() == 3)
					{
						this->currentFontColorR = ((float)(*colors)[0]->ToInt()) / 255.0f;
						this->currentFontColorG = ((float)(*colors)[1]->ToInt()) / 255.0f;
						this->currentFontColorB = ((float)(*colors)[2]->ToInt()) / 255.0f;
					}
					else if (colors->size() == 4)
					{
						this->currentFontColorR = ((float)(*colors)[0]->ToInt()) / 255.0f;
						this->currentFontColorG = ((float)(*colors)[1]->ToInt()) / 255.0f;
						this->currentFontColorB = ((float)(*colors)[2]->ToInt()) / 255.0f;
						this->currentFontColorA = ((float)(*colors)[3]->ToInt()) / 255.0f;
					}
					else
					{
						LOGError("tags parse error: bad colors <color=r,g,b|r,g,b,a>");
						value->DebugPrint("value");
					}

					CSlrString::DeleteVector(colors);
				}
				else
				{
					bool found = false;
					for (u32 i = 0; i < PARSE_NUM_COLORS; i++)
					{
						if (value->Equals((char*)colorNames[i]))
						{
							this->currentFontColorR = colorVals[i][0];
							this->currentFontColorG = colorVals[i][1];
							this->currentFontColorB = colorVals[i][2];
							found = true;
							break;
						}
					}

					if (!found)
					{
						LOGError("tags parse error: bad color");
						value->DebugPrint("value");
					}
				}
			}
			else if (tag->Equals("img") || tag->Equals("image"))
			{
				value->DebugPrint("image");

				char *imagePath = value->GetStdASCII();
				CSlrImage *image = RES_GetImageOrPlaceholder(imagePath, true, true);
				delete imagePath;
				
				bool widthExists = TagExists("width");
				bool heightExists = TagExists("height");

				float w = image->width;
				float h = image->height;

				if (widthExists == true && heightExists == false)
				{
					float aspect = image->width / image->height;
					w = GetFloatValueForTag("width", image->width);
					h = w / aspect;
				}
				else if (widthExists == false && heightExists == true)
				{	
					float aspect = image->width / image->height;
					h = GetFloatValueForTag("height", image->height);
					w = h * aspect;
				}

				float offsetX = GetFloatValueForTag("offsetX", 0.0f);
				float offsetY = GetFloatValueForTag("offsetY", 0.0f);

				//CSlrImage *image, float x, float y, float z, float sizeX, float sizeY, float spaceWidth, float gapHeight, byte alignment);

				CGuiRichTextLabelElementImage *elemText = new CGuiRichTextLabelElementImage(image,
													  0.0f, 0.0f, 0.0f, w * this->scale, h * this->scale,
													  offsetX * this->scale, offsetY * this->scale,
													  currentSpaceWidth, currentGapHeight, currentAlignment,
													  currentBlinkMode, currentBlinkParamMin, currentBlinkParamMax, currentBlinkParamNumFrames);
				this->textElements.push_back(elemText);
			}
			else if (tag->Equals("blink"))
			{
				value->DebugPrint("blink");
				
				if (value->Equals("off"))
				{
					currentBlinkMode = RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_OFF;
				}
				else if (value->Equals("lin") || value->Equals("linear") || value->Equals("l"))
				{
					currentBlinkMode = RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_LINEAR;
				}
				else if (value->Equals("sin") || value->Equals("sinus") || value->Equals("s"))
				{
					currentBlinkMode = RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_SINUS;
				}
				
				currentBlinkParamMin = GetFloatValueForTag("min", currentBlinkParamMin);
				currentBlinkParamMax = GetFloatValueForTag("max", currentBlinkParamMax);
				
				if (TagExists("freq"))
				{
					currentBlinkParamNumFrames = (u32)((GetFloatValueForTag("freq", 0) * FRAMES_PER_SECOND) / 2.0f) ;
				}
				else if (TagExists("frequency"))
				{
					currentBlinkParamNumFrames = (u32)((GetFloatValueForTag("frequency", 0) * FRAMES_PER_SECOND) / 2.0f);
				}
				else if (TagExists("f"))
				{
					currentBlinkParamNumFrames = (u32)((GetFloatValueForTag("f", 0) * FRAMES_PER_SECOND) / 2.0f);
				}
			}
			else if (tag->Equals("br"))
			{
				// new line
				CGuiRichTextLabelElementLineBreak *elemNL = new CGuiRichTextLabelElementLineBreak(currentFontHeight, currentSpaceWidth, currentGapHeight, currentAlignment, currentBlinkMode, currentBlinkParamMin, currentBlinkParamMax, currentBlinkParamNumFrames);
				this->textElements.push_back(elemNL);
			}
			else if (tag->Equals("left"))
			{
				this->currentAlignment = RICH_TEXT_LABEL_ALIGNMENT_LEFT;
			}
			else if (tag->Equals("right"))
			{
				this->currentAlignment = RICH_TEXT_LABEL_ALIGNMENT_RIGHT;
			}
			else if (tag->Equals("justify"))
			{
				this->currentAlignment = RICH_TEXT_LABEL_ALIGNMENT_JUSTIFY;
			}
			else if (tag->Equals("center"))
			{
				this->currentAlignment = RICH_TEXT_LABEL_ALIGNMENT_CENTER;
			}
			else
			{
				LOGError("unknown tag");
				tag->DebugPrint("tag");
				value->DebugPrint("value");
			}
			
			CSlrString::DeleteListElements(&tags);
			CSlrString::DeleteListElements(&vals);

			//LOGD("<<<<<<<<<<<<<<<<<<<<<<< parsing tags done");
			
			pos++;
		}
		else
		{
			// text
			CSlrString *disp = text->GetWord(pos, &retPos, tagOpenStopChars);

			pos = retPos;

			//disp->DebugPrint("disp=");

			this->AddTextElements(disp);
			
			delete disp;
		}

		//LOGD("-----------");
	}
	
	this->MakeTextLayout();
	
	this->sizeY = currentY;

	// clean up
	while(!(this->textElements.empty()))
	{
		CGuiRichTextLabelElement *el = this->textElements.front();
		this->textElements.pop_front();

		if (el->type == RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
		{
			delete el;
		}
	}
	
	//LOGD("CGuiRichTextLabel::Parse done");
	//LOGD("...");
}

bool CGuiRichTextLabel::TagExists(char *tagName)
{
	for (std::list<CSlrString *>::iterator itTags = tags.begin(); itTags != tags.end(); itTags++)
	{
		CSlrString *tag = (*itTags);
		if (tag->Equals(tagName))
		{
			return true;
		}
	}
	return false;
}

CSlrString *CGuiRichTextLabel::GetValueForTag(char *tagName)
{
	std::list<CSlrString *>::iterator itVals = vals.begin();
	for (std::list<CSlrString *>::iterator itTags = tags.begin(); itTags != tags.end(); itTags++, itVals++)
	{
		CSlrString *tag = (*itTags);
		CSlrString *value = (*itVals);

		if (tag->Equals(tagName))
		{
			return value;
		}
	}

	return NULL;
}

float CGuiRichTextLabel::GetFloatValueForTag(char *tagName, float defaultValue)
{
	CSlrString *val = GetValueForTag(tagName);
	if (val == NULL)
	{
		return defaultValue;
	}

	return val->ToFloat();
}

int CGuiRichTextLabel::GetIntValueForTag(char *tagName, int defaultValue)
{
	CSlrString *val = GetValueForTag(tagName);
	if (val == NULL)
	{
		return defaultValue;
	}

	return val->ToInt();
}

void CGuiRichTextLabel::AddTextElements(CSlrString *str)
{
	LOGD("CGuiRichTextLabel::AddTextElement");
	str->DebugPrint("AddTextElement str=");

	std::vector<CSlrString *> *words = str->Split(this->whiteSpaceChars);
	for(std::vector<CSlrString *>::iterator it = words->begin(); it != words->end(); it++)
	{
		CSlrString *oneWord = *it;

		// placeholder, pos to be updated after parsing
		CGuiRichTextLabelElementText *elemText = new CGuiRichTextLabelElementText(oneWord,
											  currentFont, 0.0f, 0.0f, 0.0f,
											  currentFontColorR, currentFontColorG, currentFontColorB, currentFontColorA, currentFontScale * this->scale, currentFontHeight, currentSpaceWidth, currentGapHeight, currentAlignment, currentBlinkMode, currentBlinkParamMin, currentBlinkParamMax, currentBlinkParamNumFrames);


		this->textElements.push_back(elemText);
	}
	
	delete words;

}

void CGuiRichTextLabel::MakeTextLayout()
{
	LOGD("CGuiRichTextLabel::MakeTextLayout");

	std::vector<CGuiRichTextLabelElement *> line;

	float px = this->currentX;
	for(std::list<CGuiRichTextLabelElement *>::iterator itWord = textElements.begin(); itWord != textElements.end(); itWord++)
	{
		CGuiRichTextLabelElement *oneText = *itWord;

		bool breakLine = false;
		float pt = px + oneText->textWidth;

		if (oneText->type == RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
		{
			breakLine = true;
		}
		else if (pt > this->sizeX)
		{
			breakLine = true;
		}

		if (breakLine)
		{
			float maxFontHeight = 0.0f;

			// end of line
			if (line.empty())
			{
				if (oneText->type != RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
				{
					// word does not fit at all, simply display it
					oneText->UpdatePos(px, currentY, 0.0f);
					this->AddElement(oneText);
				}

				// new line, word did fit
				line.clear();
				px = 0;
				maxFontHeight = oneText->fontHeight;
			}
			else
			{
				// add all words
				// TODO: here is assumption that we always take space width of last word in a line
				float spaceWidth = oneText->spaceWidth;

				px -= spaceWidth;

				if (oneText->alignment == RICH_TEXT_LABEL_ALIGNMENT_JUSTIFY
						&& oneText->type != RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
				{
					float dx = sizeX - px;
					spaceWidth += dx / (line.size()-1);
				}
				else if (oneText->alignment == RICH_TEXT_LABEL_ALIGNMENT_CENTER)
				{
					float dx = sizeX - px;
					currentX = dx/2.0f;
				}
				else if (oneText->alignment == RICH_TEXT_LABEL_ALIGNMENT_RIGHT)
				{
					float dx = sizeX - px;
					currentX = dx;
				}

				for (std::vector<CGuiRichTextLabelElement *>::iterator itLineWord = line.begin(); itLineWord != line.end(); itLineWord++)
				{
					CGuiRichTextLabelElement *lineWord = *itLineWord;
					float wordWidth = lineWord->textWidth;

					lineWord->UpdatePos(currentX, currentY, 0.0f);
					this->AddElement(lineWord);

					currentX += wordWidth + spaceWidth;

					if (maxFontHeight < lineWord->fontHeight)
					{
						maxFontHeight = lineWord->fontHeight;
					}
				}

				// new line
				line.clear();

				if (oneText->type != RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
				{
					// word did not fit, put in new line
					px = oneText->textWidth;
					line.push_back(oneText);

					spaceWidth = oneText->spaceWidth;
					px += spaceWidth;
				}
				else
				{
					px = 0;
				}
			}

			currentX = 0;
			currentY += maxFontHeight + oneText->gapHeight;
		}
		else
		{
			px = pt;
			line.push_back(oneText);
			px += oneText->spaceWidth;
		}
	}

	LOGD("-------------- ADD LINE");

	bx1 = currentX;
	by1 = currentY;

	// add last line words:
	if (!line.empty())
	{
		float spaceWidth = 0.0f;
		float maxFontHeight = 0.0f;

		CGuiRichTextLabelElement *lineWord = line.back();
		if (lineWord->alignment == RICH_TEXT_LABEL_ALIGNMENT_CENTER
				|| lineWord->alignment == RICH_TEXT_LABEL_ALIGNMENT_RIGHT)
		{
			float px = 0;
			for (std::vector<CGuiRichTextLabelElement *>::iterator itLineWord = line.begin(); itLineWord != line.end(); itLineWord++)
			{
				CGuiRichTextLabelElement *lineWord = *itLineWord;
				float wordWidth = lineWord->textWidth;

				spaceWidth = lineWord->spaceWidth;
				px += wordWidth + spaceWidth;
			}

			px -= spaceWidth;

			if (lineWord->alignment == RICH_TEXT_LABEL_ALIGNMENT_CENTER)
			{
				float dx = sizeX - px;
				currentX = dx / 2.0f;
			}
			else //if (lineWord->alignment == RICH_TEXT_LABEL_ALIGNMENT_RIGHT)
			{
				float dx = sizeX - px;
				currentX = dx;
			}
		}

		for (std::vector<CGuiRichTextLabelElement *>::iterator itLineWord = line.begin(); itLineWord != line.end(); itLineWord++)
		{
			CGuiRichTextLabelElement *lineWord = *itLineWord;
			float wordWidth = lineWord->textWidth;

			spaceWidth = lineWord->spaceWidth;

			lineWord->UpdatePos(currentX, currentY, 0.0f);
			this->AddElement(lineWord);

			currentX += wordWidth + spaceWidth;

			if (maxFontHeight < lineWord->fontHeight)
			{
				maxFontHeight = lineWord->fontHeight;
			}
		}

		currentX -= spaceWidth;
		currentY += maxFontHeight;
	}

	bx2 = currentX;
	by2 = currentY;
}

void CGuiRichTextLabel::AddElement(CGuiRichTextLabelElement *el)
{
	//LOGD("CGuiRichTextLabel::AddElement: el=%d", el->type);

	if (el->type == RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK)
	{
		SYS_FatalExit("CGuiRichTextLabel::AddElement: RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK");
	}

	this->elements.push_back(el);
}

void CGuiRichTextLabel::Render()
{
	if (this->visible)
	{
		//BlitRectangle(posX, posY, posZ, sizeX, sizeY, 1.0f, 0.0f, 0.0f, 1.0f);

		PushMatrix2D();

		Translate2D(this->posX, this->posY, this->posZ);

		//BlitFilledRectangle(bx1, by1, 0, bx2-bx1, by2-by1, 1.0f, 0.0f, 1.0f, 1.0f);

//		CSlrString *str = new CSlrString("test ma kota");
//		this->currentFont->BlitTextColor(str, 50, 50, 0, 1.0f, 1.0, 0.0, 0.0, 1.0);

		for (std::list<CGuiRichTextLabelElement *>::iterator it = elements.begin(); it != elements.end(); it++)
		{
			CGuiRichTextLabelElement *elem = *it;
			elem->Render();
		}

		PopMatrix2D();
	}
}

void CGuiRichTextLabel::Render(GLfloat posX, GLfloat posY)
{
	PushMatrix2D();
	Translate2D(posX, posY, 0.0f);
	this->Render();
	PopMatrix2D();
}

// @returns is consumed
bool CGuiRichTextLabel::DoTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = true;
		clickConsumed = this->Clicked(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->RichTextLabelClicked(this);
		}
		return clickConsumed;
	}

	clickConsumed = false;
	return false;
}

bool CGuiRichTextLabel::DoFinishTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->RichTextLabelPressed(this);
		}
		return clickConsumed;
	}

	return false;
}

// @returns is consumed
bool CGuiRichTextLabel::DoDoubleTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	if (beingClicked == false)
	{
		beingClicked = false;
		if (IsInside(posX, posY))
		{
			beingClicked = true;
			clickConsumed = this->Clicked(posX, posY);
			if (!clickConsumed && callback != NULL)
			{
				clickConsumed = callback->RichTextLabelClicked(this);
			}
			return clickConsumed;
		}
	}
	clickConsumed = false;
	return false;
}

bool CGuiRichTextLabel::DoFinishDoubleTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->RichTextLabelPressed(this);
		}
		return clickConsumed;
	}

	return false;
}

bool CGuiRichTextLabel::Clicked(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	LOGG("CGuiMultilineLabel::Clicked: %f %f", posX, posY);
	return false;
}

bool CGuiRichTextLabel::Pressed(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	LOGG("CGuiMultilineLabel::Pressed: %f %f", posX, posY);
	return false;
}

bool CGuiRichTextLabel::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	LOGG("CGuiMultilineLabel::DoMove: %f %f", x, y);
	clickConsumed = false;
	if (IsInside(x, y))
	{
		beingClicked = true;
		return true; //this->Pressed(posX, posY);
	}
	else
	{
		beingClicked = false;
	}

	return false;
}

bool CGuiRichTextLabel::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	LOGG("CGuiMultilineLabel::FinishMove: %f %f", x, y);
	if (IsInside(x, y))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		return clickConsumed;
	}

	beingClicked = false;

	return false;
}

void CGuiRichTextLabel::FinishTouches()
{
	if (this->transparentToTaps)
		return;

	beingClicked = false;
}

void CGuiRichTextLabel::DoLogic()
{
	if (!this->visible)
		return;
	
	for (std::list<CGuiRichTextLabelElement *>::iterator it = elements.begin(); it != elements.end(); it++)
	{
		CGuiRichTextLabelElement *elem = *it;
		elem->DoLogic();
	}
}

CGuiRichTextLabelElement::CGuiRichTextLabelElement()
{
	this->type = RICH_TEXT_LABEL_ELEMENT_TYPE_UNKNOWN;
	this->x = 0; this->y = 0; this->z = 0; this->textWidth = 0; this->fontHeight = 0; this->spaceWidth = 0; this->gapHeight = 0; this->alignment = 0;
}

CGuiRichTextLabelElement::CGuiRichTextLabelElement(float x, float y, float z, float textWidth, float fontHeight, float spaceWidth, float gapHeight, byte alignment, byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames)
{
	this->type = RICH_TEXT_LABEL_ELEMENT_TYPE_UNKNOWN;

	this->x = x;
	this->y = y;
	this->z = z;

	this->textWidth = textWidth;
	this->fontHeight = fontHeight;
	this->spaceWidth = spaceWidth;
	this->gapHeight = gapHeight;
	this->alignment = alignment;
	
	this->blinkMode = blinkMode;
	this->blinkParamMin = blinkParamMin;
	this->blinkParamMax = blinkParamMax;
	this->blinkParamNumFrames = blinkParamNumFrames;

	this->blinkParam = NULL;
}

void CGuiRichTextLabelElement::UpdatePos(float x, float y, float z)
{
	this->x = x;
	this->y = y;
	this->z = z;
}

void CGuiRichTextLabelElement::DoLogic()
{
	if (this->blinkParam)
	{
		this->blinkParam->DoLogic();
	}
}

void CGuiRichTextLabelElement::Render()
{
}

void CGuiRichTextLabelElement::InitBlink()
{
	if (this->blinkMode == RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_LINEAR)
	{
		this->blinkParam = new CContinuousParamLinear(this->blinkParamMin, this->blinkParamMax, this->blinkParamNumFrames);
		this->blinkParam->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_UP_DOWN;
	}
}


CGuiRichTextLabelElement::~CGuiRichTextLabelElement()
{
}

CGuiRichTextLabelElementText::CGuiRichTextLabelElementText(CSlrString *str, CSlrFont *font, float x, float y, float z, float r, float g, float b, float a, float scale,
		float fontHeight, float spaceWidth, float gapHeight, byte alignment, byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames)
{
	//LOGD("CGuiRichTextLabelElementText: callno=%d", callno);
	this->type = RICH_TEXT_LABEL_ELEMENT_TYPE_TEXT;
	this->text = str;
	this->font = font;
	this->x = x;
	this->y = y;
	this->z = z;
	this->r = r;
	this->g = g;
	this->b = b;
	this->a = a;
	this->scale = scale;

	this->textWidth = font->GetTextWidth(text, scale);
	this->spaceWidth = spaceWidth;
	this->fontHeight = fontHeight;
	this->gapHeight = gapHeight;
	this->alignment = alignment;
	
	this->blinkParam = NULL;
	this->blinkMode = blinkMode;
	this->blinkParamMin = blinkParamMin;
	this->blinkParamMax = blinkParamMax;
	this->blinkParamNumFrames = blinkParamNumFrames;

	this->InitBlink();
	
	//this->text->DebugPrint("CGuiRichTextLabelElementText text=");
}

void CGuiRichTextLabelElementText::Render()
{
	//BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)

	float alpha = a;
	
	if (this->blinkParam != NULL)
	{
		alpha = a * this->blinkParam->GetValue();
	}
	
	//LOGD("CGuiRichTextLabelElementText::Render: r=%f g=%f b=%f alpha=%f", r, g, b, alpha);
	//text->DebugPrint("text=");
	this->font->BlitTextColor(text, x, y, z, scale, r, g, b, alpha);

}

CGuiRichTextLabelElementText::~CGuiRichTextLabelElementText()
{
	delete text;
}

CGuiRichTextLabelElementImage::CGuiRichTextLabelElementImage(CSlrImage *image,
		float x, float y, float z, float sizeX, float sizeY, float offsetX, float offsetY,
		float spaceWidth, float gapHeight, byte alignment, byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames)
{
	this->type = RICH_TEXT_LABEL_ELEMENT_TYPE_IMAGE;
	this->image = image;
	this->x = x + offsetX;
	this->y = y + offsetY;
	this->z = z;
	this->textWidth = sizeX;
	this->fontHeight = sizeY;
	this->spaceWidth = spaceWidth;
	this->gapHeight = gapHeight;
	this->alignment = alignment;

	this->blinkParam = NULL;
	this->blinkMode = blinkMode;
	this->blinkParamMin = blinkParamMin;
	this->blinkParamMax = blinkParamMax;
	this->blinkParamNumFrames = blinkParamNumFrames;

	this->InitBlink();
	
	this->offsetX = offsetX;
	this->offsetY = offsetY;
}

void CGuiRichTextLabelElementImage::UpdatePos(float x, float y, float z)
{
	this->x = x + offsetX;
	this->y = y + offsetY;
	this->z = z;
}

void CGuiRichTextLabelElementImage::Render()
{
	if (this->blinkParam != NULL)
	{
		float alpha = this->blinkParam->GetValue();	//a *
		this->image->RenderAlpha(x, y, z, textWidth, fontHeight, alpha);
	}
	else
	{
		this->image->Render(x, y, z, textWidth, fontHeight);
	}
}


CGuiRichTextLabelElementImage::~CGuiRichTextLabelElementImage()
{
	RES_ReleaseImage(this->image);
}

CGuiRichTextLabelElementLineBreak::CGuiRichTextLabelElementLineBreak(float fontHeight, float spaceWidth, float gapHeight, byte alignment, byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames)
{
	this->type = RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK;
	this->fontHeight = fontHeight;
	this->spaceWidth = spaceWidth;
	this->gapHeight = gapHeight;
	this->alignment = alignment;
	
	this->blinkParam = NULL;
	this->blinkMode = blinkMode;
	this->blinkParamMin = blinkParamMin;
	this->blinkParamMax = blinkParamMax;
	this->blinkParamNumFrames = blinkParamNumFrames;
}

void CGuiRichTextLabelElementLineBreak::Render()
{
	SYS_FatalExit("CGuiRichTextLabelElementLineBreak::Render()");
}

CGuiRichTextLabelElementLineBreak::~CGuiRichTextLabelElementLineBreak()
{
}

#ifdef RICH_TEXT_USE_ELEMENTS_POOL
CPool CGuiRichTextLabelElement::poolElements(RICH_TEXT_ELEMENTS_POOL, sizeof(CGuiRichTextLabelElement));
CPool CGuiRichTextLabelElementText::poolElementsText(RICH_TEXT_ELEMENTS_POOL, sizeof(CGuiRichTextLabelElementText));
CPool CGuiRichTextLabelElementImage::poolElementsImage(RICH_TEXT_ELEMENTS_POOL, sizeof(CGuiRichTextLabelElementImage));
CPool CGuiRichTextLabelElementLineBreak::poolElementsLineBreak(RICH_TEXT_ELEMENTS_POOL, sizeof(CGuiRichTextLabelElementLineBreak));
#endif
