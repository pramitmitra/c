// // Program to build the following shape

// *
// **
// ***
// ****
// *****

#include<stdio.h>

int main()

{
  int i,j;
        for (i=1; i<=5; i++)
        {
          for (j=i; j>0; j--)
          {
             printf ("*");
            }
            printf("\n");
          }
 return 0;
}