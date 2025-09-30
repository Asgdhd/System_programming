#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int is_integer(const char *str) {
    if (str == NULL || *str == '\0') {
        return 0;
    }
    
    int i = 0;
    if (str[0] == '-') {
        i = 1;
        if (str[1] == '\0') return 0;
    }
    
    for (; str[i] != '\0'; i++) {
        if (!isdigit(str[i])) {
            return 0;
        }
    }

    return 1;
}

int main(int argc, char *argv[]) {
    if (argc != 4){
        printf("error: invalid input, 3 numbers expected\n");
        return 1;
    }

    for (int i = 1; i < 4; ++i){
        if (!is_integer(argv[i])){
            printf("error: invalid input, 3 numbers expected\n");
            return 1;
        }
    }
    
    long long a = atoll(argv[1]);
    long long b = atoll(argv[2]);
    long long c = atoll(argv[3]);

    printf("%lld\n", (((a - a) + a) - c));
    return 0;
}