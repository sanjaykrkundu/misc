#include "stdio.h"
#include "memory.h"
#include "time.h"

//extern int encode(char *src, char *paper, int n);
//extern void decode(char *src, char *paper, int n);

int encode(char *src, char *paper, int n);
void decode(char *src, char *paper, int n);

static unsigned int seed = 5;
static int hit[26] = {82,15,28,43,127,22,20,61,30,2,8,40,24,67,75,19,1,60,63,91,20,10,24,2,20};
static char alpha[963];
static char dic[1024];
static char dics[1024][8];
static char src[65536];
static char dest[65536];
static char paper[65536];
static char backup_paper[65536];


unsigned int random(){
    seed = seed * 25419903917ULL + 11ULL >> 16;
    return (unsigned int) seed;
}


void build_dic(){
    int i =0, j=0;
    for (int  c = 0; c < 963; c++)
    {
        if(j>hit[i]){
            i++;
            j=0;
        }

        alpha[c] = 'a' + i;
        j++;
    }

    for(int c = 0; c < 1024; c++){
        int l = 1+ random() %7;
        dic[c]= l;
        for(int d = 0; d<l;d++){
            dics[c][d] = alpha[random()%963];
        }
    }
    
}

int main(){

build_dic();

time_t TIME = clock();
int RATE = 0;



for (int c = 0; c <1 ; c++)
{
    int papern ;
    int pl = 0;
    while(true){
        int i = random() % 1024;
        if(pl+ dic[i]>65535) break;
        for (int j = 0;  j < dic[i]; j++)
        {
            paper[pl++] = dics[i][j];
        }
        paper[pl++] = ' ';
    }
    papern = pl;
    for (int i = 0; i < papern; i++)
    {
        backup_paper[i] = paper[i];
    }
    printf("PAPER : %s \n",paper);
    int s = encode(src,backup_paper,papern);
    printf("SRC : %s \n",src);
    for(int i=s;i<65536;i++){
        src[i]= 0;
    }
    printf("SRC : %s \n",src);
    decode(src,dest,s);
    printf("DEST : %s \n",dest);
    if(memcmp(paper,dest,papern)!=0){
        RATE += 10000000;
    }else{
        RATE+=s;
    }
}

TIME = clock() - TIME;
printf("SOL : %.5f\n",RATE + TIME/100000.);

return 0;
}



int encode(char *src, char *paper, int n){

return 0;
}
void decode(char *src, char *paper, int n){

}