TODO:


	LOGD("CGuiRichTextLabel::Parse:");

	this->text->DebugPrint("text");

	u32 pos = 0;
	u32 retPos = 0;

	std::list<CSlrString *> tags;
	std::list<CSlrString *> vals;

	while(pos < text->GetLength())
	{
		//LOGD("pos=%d c=%c (%4.4x)", pos, text->GetChar(pos), text->GetChar(pos));
		//text->DebugPrint("text", pos);

		if (text->CompareWith(pos, '<'))
		{
			while(pos < text->GetLength())
			{
				pos++;
				pos = text->SkipChars(pos, whiteSpaceChars);

				// get tag name
				CSlrString *tag = text->GetWord(pos, &retPos, tagStopChars);
				tag->DebugPrint("tag");
				tags.push_back(tag);

				pos = retPos;

				//text->DebugPrint("text", pos);

				if (text->CompareWith(pos, '='))
				{
					// value
					pos++;
					pos = text->SkipChars(pos, whiteSpaceChars);

					CSlrString *val = text->GetWord(pos, &retPos, tagStopChars);
					val->DebugPrint("value");
					vals.push_back(val);

					pos = retPos;

				}
				else
				{
					// just push the same value of tag to compare pointers
					vals.push_back(tag);
					LOGD("value=NULL");
				}

				if (text->CompareWith(pos, '>'))
				{
					break;
				}
			}

			// parse tags

			pos++;

		}
		else
		{
			// text
			CSlrString *disp = text->GetWord(pos, &retPos, tagOpenStopChars);

			pos = retPos;
			disp->DebugPrint("disp");

		}

		LOGD("-----------");
	}

	LOGD("CGuiRichTextLabel::Parse done");

