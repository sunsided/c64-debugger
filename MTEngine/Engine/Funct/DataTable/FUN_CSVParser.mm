#include "FUN_CSVParser.h"
#include "SYS_Main.h"
#include "CDataTable.h"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "utf8.h"
#include "std_membuf.h"

using namespace std;

CDataTable *FUN_ParseCSV(char *fileName)
{
	LOGD("FUN_ParseCSV");
	
	ifstream reader(fileName);
	if (!reader.is_open())
	{
		SYS_FatalExit("FUN_ParseCSV: could not open %s", fileName);
	}
	
	SYS_FatalExit("not implemented");
	return NULL;
}

CDataTable *FUN_ParseCSV(CByteBuffer *byteBuffer)
{
	return FUN_ParseCSV(byteBuffer, ',');
}

CDataTable *FUN_ParseCSV(CByteBuffer *byteBuffer, u16 separatorChar)
{
	LOGD("FUN_ParseCSV");
	
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	istream reader(&mb);
	
	CDataTable *dataTable = new CDataTable();

	u32 row = 0;
	u32 col = 0;

	unsigned lineNum = 1;
	string line;
	line.clear();

	// Play with all the lines in the file
	while (getline(reader, line))
	{
		// check for invalid utf-8 (for a simple yes/no check, there is also utf8::is_valid function)
		string::iterator end_it = utf8::find_invalid(line.begin(), line.end());
		if (end_it != line.end())
		{
			LOGError("Invalid UTF-8 encoding detected at line %d", lineNum);
			//cout << "This part is fine: " << string(line.begin(), end_it) << "\n";
		}

		// Get the line length (at least for the valid part)
		//int length = utf8::distance(line.begin(), end_it);
		//LOGD("========================= Length of line %d is %d", lineNum, length);

		// Convert it to utf-16
		vector<unsigned short> utf16line;
		utf8::utf8to16(line.begin(), end_it, back_inserter(utf16line));

		CSlrString *str = new CSlrString(utf16line);
		//LOGD("========================= str len=%d", str->GetLength());
		//str->DebugPrint("========================= str=");

		CSlrString *val = NULL;
		bool insideQ = false;
		for (u32 i = 0; i < str->GetLength(); i++)
		{
			if (val == NULL)
			{
				val = new CSlrString();
			}

			u16 ch = str->GetChar(i);

			if (insideQ)
			{
				if (ch == '"')
				{
					if (str->GetLength() > i+1)
					{
						if (str->GetChar(i+1) == '"')
						{
							val->Concatenate(ch);
							continue;
						}
					}

					insideQ = false;
					continue;
				}

				//LOGD("insideQ val->Concatenate %d %c", ch, ch);
				val->Concatenate(ch);
				//val->DebugPrint("val=");
			}
			else
			{
				if (ch == '"')
				{
					insideQ = true;
					continue;
				}

				if (ch == separatorChar)
				{
					// finalize str
					//LOGD("finalize str");
					//val->DebugPrint("");

					CDataTableCellString *cellString = new CDataTableCellString(val);
					dataTable->SetData(col, row, cellString);

					col++;

					val = NULL;
					continue;
				}

				//LOGD("notIQ val->Concatenate %d %c", ch, ch);
				val->Concatenate(ch);
				//val->DebugPrint("val=");
			}
		}

		if (val != NULL)
		{
			//LOGD("(val != NULL)");
			//val->DebugPrint("val=");
			
			if (!val->IsEmpty())
			{
				CDataTableCellString *cellString = new CDataTableCellString(val);
				dataTable->SetData(col, row, cellString);
			}
			else
			{
				delete val;
			}
		}
		
		delete str;

		row++;
		col = 0;

		lineNum++;
	}

	LOGM("FUN_ParseCSV done");
	//dataTable->DebugPrint("FUN_CSVParser");

	return dataTable;
}

void FUN_ExportCSV(CDataTable *dataTable, u16 charSeparator, char *fileName)
{
	LOGTODO("UTF8 is not done...");
	FILE *fp = fopen(fileName, "wb");
	
//	// BOM
//	const byte BOM[2] = { 0xFE, 0xFF };
//	fwrite(BOM, 2, 1, fp);
	
	/// convert to char*
	for (int row = 0; row < dataTable->GetNumRows(); row++)
	{
		for (int col = 0; col < dataTable->GetNumCols(); col++)
		{
			CSlrString *str = dataTable->GetString(col, row);
			
			if (str != NULL)
			{
				u32 len;
				u16 *utf16 = str->GetUTF16(&len);
				
				for (u32 i = 0; i < len; i++)
				{
					char c = utf16[i];
					fwrite(&c, 1, 1, fp);
				}
				delete utf16;
				
				char c = (char)charSeparator;
				fwrite(&c, 1, 1, fp);
			}
		}
		
		char c = '\n';
		fwrite(&c, 1, 1, fp);

	}
	
	fclose(fp);
}


//// USOS
////////////
//// USOS
//
//CByteBuffer *byteBuffer = new CByteBuffer();
//CSlrFile *file = RES_GetFile("in-moodle", DEPLOY_FILE_TYPE_TXT);
//byteBuffer->readFromFileNoHeader(file);
//CDataTable *moodle = FUN_ParseCSV(byteBuffer, ',');
//
//file = RES_GetFile("in-usos", DEPLOY_FILE_TYPE_CSV);
//byteBuffer->readFromFileNoHeader(file);
//
//CDataTable *usos = FUN_ParseCSV(byteBuffer, ';');
//
//usos->SetFont(guiMain->fntDefault, 1.0f);
//moodle->SetFont(guiMain->fntDefault, 1.0f);
//
//viewDataTable = new CGuiViewDataTable(10, 15, posZ, SCREEN_WIDTH-20, SCREEN_HEIGHT-20);
//this->AddGuiElement(viewDataTable);
//viewDataTable->SetDataTable(usos);
//
/////
//int usosImie = 4;
//int usosNazwisko = 3;
//int usosOcena = 6;
//
//int moodleImie = 0;
//int moodleNazwisko = 1;
//int moodleOcena = 10;
//
//for (int i = 1; i < moodle->GetNumRows(); i++)
//{
//	LOGD("row %d", i);
//	
//	CSlrString *imie = moodle->GetString(moodleImie, i);
//	CSlrString *nazwisko = moodle->GetString(moodleNazwisko, i);
//	CSlrString *ocena = moodle->GetString(moodleOcena, i);
//	
//	float oc = ocena->ToFloat();
//	
//	float ocUsos = 2.0f;
//	if (oc >= 50.0f)
//	{
//		ocUsos = 3.0f;
//		if (oc >= 60.0f)
//		{
//			ocUsos = 3.5f;
//			
//			if (oc >= 70.0f)
//			{
//				ocUsos = 4.0f;
//				if (oc >= 80.0f)
//				{
//					ocUsos = 4.5f;
//					if (oc >= 90.0f)
//					{
//						ocUsos = 5.0f;
//					}
//				}
//			}
//		}
//	}
//	
//	LOGD("oc=%f ocUsos=%f", oc, ocUsos);
//	
//	for (int u = 1; u < usos->GetNumRows(); u++)
//	{
//		CSlrString *uNazwisko = usos->GetString(usosNazwisko, u);
//		
//		if (uNazwisko->CompareWith(nazwisko))
//		{
//			CSlrString *uImie = usos->GetString(usosImie, u);
//			if (uImie->CompareWith(imie))
//			{
//				nazwisko->DebugPrint("nazwisko=");
//				imie->DebugPrint("imie=");
//				
//				CSlrString *ocStr = NULL;
//				if (ocUsos == 5.0f)
//				{
//					ocStr = new CSlrString("5");
//				}
//				else if (ocUsos == 4.5f)
//				{
//					ocStr = new CSlrString("4.5");
//				}
//				else if (ocUsos == 4.0f)
//				{
//					ocStr = new CSlrString("4");
//				}
//				else if (ocUsos == 3.5f)
//				{
//					ocStr = new CSlrString("3.5");
//				}
//				else if (ocUsos == 3.0f)
//				{
//					ocStr = new CSlrString("3");
//				}
//				else
//				{
//					ocStr = new CSlrString("2");
//				}
//				CDataTableCell *cellOcena = new CDataTableCellString(ocStr);
//				usos->SetData(usosOcena, u, cellOcena);
//			}
//		}
//	}
//}
//
//FUN_ExportCSV(usos, ';', "/Users/mars/Desktop/tout.txt");


