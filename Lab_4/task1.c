#include <stdio.h>

int main() {
    int n;
    printf("input positive number n: \n");
    scanf("%d", &n);

    if (n <= 0){
        printf("error: positive number input expected\n");
        return 1;
    }

    int count = n / 481;
    
    printf("the amount of numbers between 1 and n that are divisible by both 37 and 13: %d\n", count);
    
    return 0;
}