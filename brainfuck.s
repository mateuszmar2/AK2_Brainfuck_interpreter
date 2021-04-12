# Mateusz Marciniec 252765
# Bartosz Szymczak 213769
# Program pyta o zdanie a następnie wypisuje je od końca, czy ja wiem xD
# Pytanie czy robimy kompilator czy interpreter, to do ogarnięcia jeszcze


SYSCALL32 = 0x80                    # wywołanie systemu operacyjnego
SYSEXIT = 1                         # zakończenie procesu
STDIN = 0                           # standardowe wejście
STDOUT = 1                          # standardowe wyjście
SYSREAD = 3                         # numer funkcji read
SYSWRITE = 4                        # numer funkcji write
EXIT_SUCCESS = 0                    # kod błędu przy wyjściu
BUFF_SIZE = 80                      # Długość bufora

.global _start

# segment danych
.section .bss                       # część programu zawierająca dane nie zainicjalizowane
buff:                               # etykieta dla buffora
                                    # zarezerwowanie w segmencie .bss dla tablicy o rozmiarze 30000
.lcomm ARRAY, 30000

.section .data                      # część programu zawierająca dane zainicjalizowane
msg_brainfuck:                      # etykieta dla napisu ze znakiem zachęty
                                    # dyrektywa .ascii rezerwuja pamięć na napis
.ascii "Brainfuck> "
msg_brainfuck_len = . - msg_brainfuck           # długość napisu ze znakiem zachęty

# segment kodu
.text

_start:

# wypisanie napisu ze znakiem zachęty
mov $SYSWRITE, %eax                 # funkcja do wywołania - SYSWRITE
mov $STDOUT, %ebx                   # syst. deskryptor stdout
mov $msg_brainfuck, %ecx            # adres początkowy napisu
mov $msg_brainfuck_len, %edx        # długość łańcucha znaków
int $SYSCALL32                      # wywołanie przerwania programowego

# wczytanie łańcucha
mov $SYSREAD, %eax                  # kod funkcji SYSREAD
mov $STDIN, %ebx                    # systemowy deskryptor stdin
mov $my_buffer, %ecx                # adres początkowy napisu
mov $BUFF_SIZE, %edx                # długość łańcucha
int $SYSCALL32                      # wywołanie przerwania programowego

mov %eax, text_size                 # przypisanie rozmiaru tekstu do text_size

mov text_size, %ecx                 # przypisanie długości zdania do ecx
mov $0, %esi                        # esi jako iterator po konkretnych słowach

loop_push_start:                    # pętla do wrzucania na stos
    movzx my_buffer(%esi), %eax     # przypisz jedną literę do eax
    push %eax                       # wrzuć na stos
    inc %esi                        # inkrementuj iterator
    loop loop_push_start            # zmniejsz ecx o 1 i jeśli != 0 to skocz do etykiety

mov text_size, %ecx                 # przypisanie długości zdania do ecx
mov $0, %esi                        # esi jako iterator po konkretnych słowach

pop %eax                            # ściągnij ze stosu pierwszy znak, czyli znak nowej linii
dec %ecx

loop_pop_start:                     # pętla do ściągania ze stosu
    pop %eax                        # przypisz wartość ze stosu do eax
    mov %al, my_buffer(%esi)        # przypisz dolny bajt do bufora
    inc %esi                        # inkrementuj iterator
    loop loop_pop_start             # zmniejsz ecx o 1 i jeśli != 0 to skocz do etykiety


mov $SYSEXIT, %eax                  # funkcja do wywołania - SYSEXIT
mov $EXIT_SUCCESS, %ebx             # odpowiedni kod podawany na wyjściu
int $SYSCALL32                      # przerwanie systemowe
