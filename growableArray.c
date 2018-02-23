#include <stdio.h>
#include <stdlib.h>

void assignDoubleMemory(char **pointer,int *size){
    *size = (*size) * 2;
    *pointer =(char*)realloc(*pointer,*size);
}

char*  readInput(int *size){
    int i;
    char ch;
    char* pointer = (char*)malloc(sizeof(char)*(*size));
	
	for(i = 0; i <*size; i++) {
	    if(scanf("%c",&ch)== -1)
            break;

        pointer[i]=ch;

        if(i==(*size)-2){
            assignDoubleMemory(&pointer, size);
        }
        //printf("%d : %c %s %d\n", i,ch,pointer,*size);
	}
	return pointer;
}

int main(void) {
    int size = 4;
    char * pointer = readInput(&size);
    
    printf("\nsentance :  %s\n %d",pointer,size);
    
	return 0;
}
