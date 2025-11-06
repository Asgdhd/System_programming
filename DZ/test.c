#include <stdio.h>
#include <stdlib.h>

extern void* array_create(unsigned long n);
extern unsigned long array_get_len(void* arr);
extern unsigned long array_get(void* arr, unsigned long i);
extern void array_set(void* arr, unsigned long i, unsigned long v);
extern void array_free(void);
extern int array_push_back(void* arr, unsigned long v);
extern unsigned long array_pop_front(void* arr);
extern void array_remove_evens(void* arr);
extern void* array_get_odd_numbers(void* arr);
extern unsigned long array_count_ending_with_1(void* arr);

void print_array(void* arr) {
    unsigned long len = array_get_len(arr);
    printf("Массив: ");
    for (unsigned long i = 0; i < len; i++) {
        printf("%lu ", array_get(arr, i));
    }
    printf("\n");
}

void demo() {
    void* arr = array_create(7);
    for (int i = 0; i < 7; i++) array_set(arr, i, i);
    print_array(arr);

    array_push_back(arr, 61);
    printf("\nПосле добавления 61:\n");
    print_array(arr);

    printf("\nУдалён: %lu\n", array_pop_front(arr));
    print_array(arr);

    printf("\nЧисел, оканчивающихся на 1: %lu\n", array_count_ending_with_1(arr));

    void* odds = array_get_odd_numbers(arr);
    printf("\nНечётные:\n");
    print_array(odds);

    array_remove_evens(arr);
    printf("\nПосле удаления чётных:\n");
    print_array(arr);

    array_free();
}

void interactive() {
    void* arr = NULL;
    int cmd;
    unsigned long a, b;

    printf("\nИнтерактивный режим\n");
    printf("Команды:\n");
    printf("1 - создать массив длины N\n");
    printf("2 - добавить элемент V в конец\n");
    printf("3 - удалить первый элемент\n");
    printf("4 - показать нечётные числа\n");
    printf("5 - удалить чётные числа\n");
    printf("6 - посчитать числа, оканчивающиеся на 1\n");
    printf("7 - напечатать массив\n");
    printf("0 - выход\n\n");

    while (1) {
        printf("> ");
        if (scanf("%d", &cmd) != 1) break;

        switch (cmd) {
            case 0:
                goto exit_loop;

            case 1:
                if (scanf("%lu", &a) == 1) {
                    if (arr) array_free();
                    arr = array_create(a);
                    printf("Создан массив длины %lu\n", a);
                }
                break;

            case 2:
                if (arr && scanf("%lu", &a) == 1) {
                    if (array_push_back(arr, a)) {
                        printf("Добавлено %lu\n", a);
                    }
                }
                break;

            case 3:
                if (arr) {
                    printf("Удалено: %lu\n", array_pop_front(arr));
                }
                break;

            case 4:
                if (arr) {
                    void* odds = array_get_odd_numbers(arr);
                    print_array(odds);
                }
                break;

            case 5:
                if (arr) {
                    array_remove_evens(arr);
                    printf("Чётные удалены\n");
                }
                break;

            case 6:
                if (arr) {
                    printf("Оканчивающихся на 1: %lu\n", array_count_ending_with_1(arr));
                }
                break;

            case 7:
                if (arr) {
                    print_array(arr);
                }
                break;

            default:
                printf("Неизвестная команда\n");
        }
    }

exit_loop:
    if (arr) array_free();
}

int main() {
    int mode;
    printf("1 - Демонстрация\n2 - Интерактивный режим\nВыбор: ");
    scanf("%d", &mode);

    if (mode == 1) {
        demo();
    } else if (mode == 2) {
        interactive();
    } else {
        printf("Неверный выбор\n");
    }

    return 0;
}