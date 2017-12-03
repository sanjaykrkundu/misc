#include "stdio.h"
#include "stdlib.h"
#include "stdbool.h"

#define CHAR_SIZE 26
#define CHAR2INT(x) x-97
typedef struct node trieNode;
void insert(trieNode *, char *);
bool search( trieNode *, char *);
void _delete(trieNode *, char *);
void display( trieNode *);
trieNode* createNode(bool);
bool hasChild( trieNode*);
bool deleteHelper(trieNode *, char *,int);

typedef struct node{
	bool isEndOfWord;
	struct node *child[CHAR_SIZE];
}trieNode;


void insert( trieNode *root, char *string){
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

bool search( trieNode *root, char *string){
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

void _delete(trieNode *root, char *string){
	//free(root);
	root = NULL;
	/*
	root->child[0] = createNode(false);
	//root->child[0]->child[1] = createNode(false);
	printf("%p\n", root->child[0]);
	
	deleteHelper(root->child[0],"a",0);
	
	printf("%p\n", root->child[0]);
	*/
}

bool deleteHelper(trieNode *root, char *string,int index){
	printf("%p\n", root);
	if(!hasChild(root)){
		puts("! has child");
		free(root);
		root = root->child[0];
	}
	printf("%p\n",root);
}


void display( trieNode *root){
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
	//display(root);puts("");
	insert(root,strings[1]);
	//display(root);puts("");
	insert(root,strings[2]);
	//display(root),puts("");
	insert(root,strings[3]);
	//display(root);puts("");
	
	/*
	printf("%s : %d\n",strings[0],search(root,strings[0]));
	printf("%s : %d\n",strings[1],search(root,strings[1]));
	printf("%s : %d\n",strings[2],search(root,strings[2]));
	printf("%s : %d\n",strings[3],search(root,strings[3]));
	printf("th : %d\n",search(root,"th"));
	printf("blog : %d\n",search(root,"blog"));
	printf("home : %d\n",search(root,"home"));
	
	puts("th");
	delete(root,"th");
	display(root);puts("");
	puts("blog");
	delete(root,"blog");
	display(root);puts("");
	puts("home");
	delete(root,"home");
	display(root);puts("");
	
	/*
	puts(strings[0]);
	delete(root,strings[0]);
	display(root);puts("");	
	puts(strings[1]);
	delete(root,strings[1]);
	display(root);puts("");	
	puts(strings[2]);
	delete(root,strings[2]);
	display(root);puts("");	
	*/
	puts(strings[3]);
	_delete(root,strings[3]);
	display(root);puts("");	
	
	return 0;
}
