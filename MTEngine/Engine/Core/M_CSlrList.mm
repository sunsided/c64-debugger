#include "M_CSlrList.h"

// why to define this?
// answer: code has to be portable, I know some compilers where STL is not supported
// TODO: convert to template

CSlrListElement::CSlrListElement()
{
	next = NULL;
	prev = NULL;
}

CSlrListElement::~CSlrListElement()
{
	if (next != NULL || prev != NULL)
	{
		LOGError("delete linked CSlrListElement");
	}
}

CSlrList::CSlrList()
{
	first = NULL;
	last = NULL;
}

CSlrList::~CSlrList()
{
	if (first != NULL)
	{
		LOGError("Delete CSlrList - has elements!");
	}
}

void CSlrList::Link(CSlrListElement *what)
{
	if (first == NULL)
	{
		first = what;
	}
	else
	{
		last->next = what;
	}
	what->next = NULL;
	what->prev = last;
	last = what;
}

void CSlrList::UnLink(CSlrListElement *what)
{
	if (what->prev == NULL)
		first = what->next;
	else
		what->prev->next = what->next;

	if (what->next == NULL)
		last = what->prev;
	else
		what->next->prev = what->prev;

	what->next = NULL;
	what->prev = NULL;
}

void CSlrList::UnLinkAndDeleteElements()
{
	CSlrListElement *listElem;
	CSlrListElement *listElemNext;

	for (listElem = this->first; listElem != NULL; listElem = listElemNext)
	{
		listElemNext = listElem->next;
		this->UnLink(listElem);
		delete listElem;
	}
}