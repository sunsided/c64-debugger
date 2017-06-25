#ifndef _SYS_INTERVAL_TREE_H_
#define _SYS_INTERVAL_TREE_H_

#include "SYS_Defs.h"

// Structure to represent an interval
struct ITInterval
{
	int low, high;
	void *userData;
};

// Structure to represent a node in Interval Search Tree
struct ITNode
{
	ITInterval *i;  // 'i' could also be a normal variable
	int max;
	ITNode *left, *right;
};

ITNode *FUN_ITInsert(ITNode *root, ITInterval i);
ITInterval *FUN_ITOverlapSearch(ITNode *root, ITInterval i);


#endif
