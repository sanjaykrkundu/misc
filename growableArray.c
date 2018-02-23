#include <stdio.h>
#include <stdlib.h>

char* pointer = NULL;
int size=4;

void readInput(){
    int i;
    char ch;
    
    pointer = (char*)malloc(sizeof(char)*size);
    
	printf("Enter a sentance : \n");
	
	for(i = 0; i <size; i++) {
	    
	    if(scanf("%c",&ch)== -1)
            break;
        
        pointer[i]=ch;
        
        if(i==size-2){
            size*=2;
            pointer = (char*)realloc(pointer,size);
        }
        printf("%d : %c %s %d\n", i,ch,pointer,size);
	}
	
}



int main(void) {
    readInput();
    printf("\nsantance :  %s\n",pointer);
    
	return 0;
}

