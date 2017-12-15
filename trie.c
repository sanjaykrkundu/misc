#include "stdio.h"
#include "stdlib.h"
#include "stdbool.h"

#define CHAR_SIZE 26
#define CHAR2INT(x) x-97

typedef struct node trieNode;
void insert(trieNode *, char *);
bool search(trieNode *, char *);
void delete(trieNode **, char *);
void display(trieNode *);
trieNode* createNode(bool);
bool hasChild(trieNode*);
bool deleteHelper(trieNode **, char *,int);

typedef struct node{
	bool isEndOfWord;
	struct node *child[CHAR_SIZE];
}trieNode;

void insert(trieNode *root, char *string){
	int counter = 0;
	char ch;
	trieNode *tempNode = root;

	while((ch=string[counter++])!='\0'){
		if(tempNode->child[CHAR2INT(ch)]==NULL){
			trieNode *node = createNode(false);
			tempNode->child[CHAR2INT(ch)] = node;
		}
		tempNode = tempNode->child[CHAR2INT(ch)];
	}
	tempNode->isEndOfWord = true;
}

bool search(trieNode *root, char *string){
	int counter = 0;
	char ch;
	trieNode *tempNode = root;
	while((ch=string[counter++])!='\0' && tempNode->child[CHAR2INT(ch)]!=NULL){
			tempNode = tempNode->child[CHAR2INT(ch)];
	}
	if(tempNode->isEndOfWord)
		return true;
	return false;
}

void delete(trieNode **root, char *string){
	deleteHelper(root,string,0);
	//*root=NULL;
}

bool deleteHelper(trieNode **node, char *string,int index){
	
	if(string[index] == '\0')
		return true;
	
	if(*node == NULL)
		return true;
	
	if(deleteHelper(&((*node)->child[CHAR2INT(string[index])]),string,index+1)){
		if((*node)->isEndOfWord){
			*node = NULL;
			return false;
		}
		if(hasChild(*node)){
			return false;
		}
		else 
			return true;
			
	}
	return false;
}

void display(trieNode *root){
	int i;
	trieNode *node = root;
	for(i=0;i<CHAR_SIZE;i++){
		if(node->child[i]!=NULL){
			printf("%c",i+97);
			display(node->child[i]);
		}
	}

}

trieNode* createNode(bool endOfWord){
	int i;
	trieNode *node = (trieNode*)malloc(sizeof(trieNode));
	node->isEndOfWord = endOfWord;
	for(i=0;i<CHAR_SIZE;i++)
		node->child[i] = NULL;
	return node;
}

bool hasChild( trieNode* node){
	int i;
	for(i=0;i<CHAR_SIZE;i++){
		if(node->child[i]!=NULL)
			return true;
	}
	return false;
}

int main(){
	char *strings[] = {"the","these","their","thaw"};
	trieNode *root = createNode(false);
	
	insert(root,strings[0]);
	insert(root,strings[1]);
	insert(root,strings[2]);
	insert(root,strings[3]);
	display(root);puts("");
	

	return 0;
}