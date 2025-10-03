#include <stdio.h>

int main() {
    int n;
    printf("input positive number n: \n");
    scanf("%d", &n);

    if (n <= 0){
        printf("error: positive number input expected\n");
        return 1;
    }

    int count = n % 4;
    int result = 0;

    switch(n % 4) {
        case 0:
            result = -n;
            break;
        case 1:
            result = 1;
            break;
        case 2:
            result = n + 1;
            break;
        case 3:
            result = 0;
            break;
    }
    
    printf("result: %d\n", result);
    
    return 0;
}