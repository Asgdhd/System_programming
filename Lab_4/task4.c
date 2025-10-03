#include <stdio.h>

int main() {
    int n;
    printf("input positive number n: \n");
    scanf("%d", &n);

    if (n <= 0){
        printf("error: positive number input expected\n");
        return 1;
    }

    int result = 0;
    int s = 0;

    for (int i = 1; i <= n; ++i){
        s = i * (i + 4) * (i + 8);
        if (i % 2 == 0){
            result += s;
        } else {
            result -= s;
        }
    }
    
    printf("result: %d\n", result);
    
    return 0;
}