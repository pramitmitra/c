#include <stdio.h>
#include<stdlib.h>
int main()
{
   int num;
   FILE *fptr;
   fptr = fopen("/Users/pmitra/Documents/myProjects/C/program.txt","w");

   if(fptr == NULL)
   {
      printf("Error!");   
      exit(1);             
   }

   printf("Enter num: ");
   scanf("%d",&num);

   fprintf(fptr,"%d",num);
  //fprintf(fptr, "\s"," ");
   fclose(fptr);

   return 0;
}