#include <stdio.h>

int main(){
    long long n = 5607798014ULL;  // Беззнаковый тип
    int sum = 0;
    
    while (n > 0) {
        sum += n % 10;
        n /= 10;
    }
    
    printf("%d\n", sum);
    return 0;
}