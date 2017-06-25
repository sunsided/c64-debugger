#include "FUN_IntervalTree.h"
#include "DBG_Log.h"

// A utility function to create a new Interval Search Tree Node
ITNode *newNode(ITInterval i)
{
	ITNode *temp = new ITNode;
	temp->i = &i; //new ITInterval(i);
	temp->max = i.high;
	temp->left = temp->right = NULL;
	
	return temp;
};

// A utility function to insert a new Interval Search Tree Node
// This is similar to BST Insert.  Here the low value of interval
// is used tomaintain BST property
ITNode *insert(ITNode *root, ITInterval i)
{
	// Base case: Tree is empty, new node becomes root
	if (root == NULL)
		return newNode(i);
 
	// Get low value of interval at root
	int l = root->i->low;
 
	// If root's low value is smaller, then new interval goes to
	// left subtree
	if (i.low < l)
		root->left = insert(root->left, i);
 
	// Else, new node goes to right subtree.
	else
		root->right = insert(root->right, i);
 
	// Update the max value of this ancestor if needed
	if (root->max < i.high)
		root->max = i.high;
 
	return root;
}

ITNode *FUN_ITInsert(ITNode *root, ITInterval i)
{
	return insert(root, i);
}

// A utility function to check if given two intervals overlap
bool doOVerlap(ITInterval i1, ITInterval i2)
{
	if (i1.low <= i2.high && i2.low <= i1.high)
		return true;
	return false;
}

// The main function that searches a given interval i in a given
// Interval Tree.
ITInterval *overlapSearch(ITNode *root, ITInterval i)
{
	// Base Case, tree is empty
	if (root == NULL) return NULL;
 
	// If given interval overlaps with root
	if (doOVerlap(*(root->i), i))
		return root->i;
 
	// If left child of root is present and max of left child is
	// greater than or equal to given interval, then i may
	// overlap with an interval is left subtree
	if (root->left != NULL && root->left->max >= i.low)
		return overlapSearch(root->left, i);
 
	// Else interval can only overlap with right subtree
	return overlapSearch(root->right, i);
}

ITInterval *FUN_ITOverlapSearch(ITNode *root, ITInterval i)
{
	return overlapSearch(root, i);
}


void inorder(ITNode *root)
{
	if (root == NULL) return;
 
	inorder(root->left);
 
	LOGD("[%d, %d] max=%d", root->i->low, root->i->high, root->max);
 
	inorder(root->right);
}


