#ifndef __CSLRLIST_H__
#define __CSLRLIST_H__

#include "SYS_Main.h"

class CSlrListElement
{
public:
	CSlrListElement();
	~CSlrListElement();
	CSlrListElement *next;
	CSlrListElement *prev;

};


class CSlrList
{
public:
	CSlrList();
	~CSlrList();
	
	CSlrListElement *first;
	CSlrListElement *last;

	void Link(CSlrListElement *what);
	void UnLink(CSlrListElement *what);
	void UnLinkAndDeleteElements();
};


#endif