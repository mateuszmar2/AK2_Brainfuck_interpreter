# Mateusz Marciniec 252765
# Bartosz Szymczak 213769
# Program pyta o kod a następnie go wykonuje
# Po zrobieniu działającej wersji rozszerzenie o optymalizacje i wczytywanie z pliku


SYSCALL32 = 0x80                    # wywołanie systemu operacyjnego
SYSEXIT = 1                         # zakończenie procesu
STDIN = 0                           # standardowe wejście
STDOUT = 1                          # standardowe wyjście
SYSREAD = 3                         # numer funkcji read
SYSWRITE = 4                        # numer funkcji write
EXIT_SUCCESS = 0                    # kod błędu przy wyjściu
BUFF_SIZE = 30000                   # Długość bufora

.global _start

# segment danych
.section .bss                       # część programu zawierająca dane nie zainicjalizowane
ARRAY:          .skip 30000         # zarezerwowanie w segmencie .bss dla tablicy o rozmiarze 30000, zainicjowana 0
JUMPTABLE:      .skip 128000
CODEBUFF: 	    .skip 500000

.section .data                      # część programu zawierająca dane zainicjalizowane

msg_brainfuck:                      # etykieta dla napisu ze znakiem zachęty
.ascii "Brainfuck> "                # dyrektywa .ascii rezerwuja pamięć na napis                                    
                
msg_brainfuck_len = . - msg_brainfuck  # długość napisu ze znakiem zachęty

msg_end_line:                       # etykieta dla napisu końca linii
.ascii "\0 "                         # dyrektywa .ascii rezerwuja pamięć na napis                                    
                
msg_end_line_len = . - msg_end_line  # długość napisu końca linii

text_size: .int 0                   # miejsce na długość wpisanego tekstu

# segment kodu
.text

newline:	.asciz "\n"

_start:

# wypisz string na stdout
# arg1 - adres łańcucha
# arg2 - długość łańcucha
.macro write str, str_size
 mov $SYSWRITE, %eax                # funkcja do wywołania - SYSWRITE w %eax
 mov $STDOUT, %ebx                  # syst. deskryptor stdout
 mov \str, %ecx                     # adres początkowy napisu
 mov \str_size, %edx                # długość łańcucha
 int $SYSCALL32                     # wykonanie funcji systemowej.
.endm 

# wywołanie makra write w celu wypissania "Brainfuck> "
write $msg_brainfuck, $msg_brainfuck_len

# wczytanie łańcucha z kodem
mov $SYSREAD, %eax                  # kod funkcji SYSREAD
mov $STDIN, %ebx                    # systemowy deskryptor stdin
mov $CODEBUFF, %ecx                 # adres początkowy napisu
mov $BUFF_SIZE, %edx                # długość łańcucha
int $SYSCALL32                      # wywołanie przerwania programowego

mov %eax, text_size                 # przypisanie rozmiaru tekstu do text_size
inc %eax
movzx msg_end_line, %ebx            # dopisz znak końca linii na końcu wyrażenia, nie wiem czy potrzebne
mov %ebx, ARRAY(%eax)


# mov text_size, %ecx                 # przypisanie długości zdania do ecx
# mov $0, %esi                        # esi jako iterator po konkretnych słowach

# kod jest wczytany teraz główna część programu
brainfuck:
mov $0, %esi                        # 0 jako bieżący indeks w tablicy z kodem
mov $ARRAY, %edi                    # bieżący adres w tablicy do EDI

brainfuck_loop:
    cmpb $'>', CODEBUFF(%esi)
    je inc_pointer                  # jeżeli równe inkrementuj wartość wskaźnika

    cmpb $'<', CODEBUFF(%esi)
    je dec_pointer                  # jeżeli równe dekrementuj wartość wskaźnika

    cmpb $'+', CODEBUFF(%esi)
    je inc_value                    # jeżeli równe inkrementuj wartość wskazywaną przez wskaźnik

    cmpb $'-', CODEBUFF(%esi)
    je dec_value                    # jeżeli równe dekrementuj wartość wskazywaną przez wskaźnik

    cmpb $'.', CODEBUFF(%esi)
    je output_value                 # jeżeli równe wypisz wartość wskazywaną przez wskaźnik

    cmpb $',', CODEBUFF(%esi)
    je input_value                  # jeżeli równe pobierz bajt i wpisz pod adresem wskazywanym przez wskaźnik

    cmpb $'[', CODEBUFF(%esi)
    je left_bracket                 # skocz bezpośrednio za odpowiadający mu ], jeśli w bieżącej pozycji znajduje się 0

    cmpb $']', CODEBUFF(%esi)
    je right_bracket                # skocz do odpowiadającego mu [

	cmpb $0, CODEBUFF(%esi)
	je	brainfuck_end               # '\0' oznacza że osiągnięto koniec wyrażenia, zakończ program

brainfuck_loop_end:
    inc %esi
    jmp brainfuck_loop

inc_pointer:
    inc %edi
    jmp brainfuck_loop_end

dec_pointer:
    dec %edi
    jmp brainfuck_loop_end

inc_value:
    incb (%edi)
    jmp brainfuck_loop_end

dec_value:
    decb (%edi)
    jmp brainfuck_loop_end

output_value:
    write %edi, $1
    jmp brainfuck_loop_end

input_value:
    mov $SYSREAD, %eax                  # kod funkcji SYSREAD
    mov $STDIN, %ebx                    # systemowy deskryptor stdin
    mov %edi, %ecx                      # adres początkowy napisu
    mov $1, %edx                        # długość łańcucha
    int $SYSCALL32                      # wywołanie przerwania programowego
    jmp brainfuck_loop_end

left_bracket:                           
    cmp $0, %edi                        # Jeśli w bieżącej pozycji znajduje się 0
    je find_right_bracket               # to skacze zaraz za zamykający nawias

# specjalny przypadek dla [-], który zeruje komórkę
    mov %esi, %eax
    inc %eax
    cmpb $'-', CODEBUFF(%eax)
    jne chceck_zero_end
    inc %eax
    cmpb $']', CODEBUFF(%eax)
    jne chceck_zero_end
    movb $0, (%edi)
    add $2, %esi
    jmp brainfuck_loop_end

chceck_zero_end:
    push %esi    
    jmp brainfuck_loop_end

find_right_bracket:                                       
    mov %esi, %ebx
    mov $0, %edx
    cmpw $0, JUMPTABLE(%edx, %ebx, 2)   # sprawdza czy prawy nawias znajduje się w JUMPTABLE  
    jg jump_matching                    # jeśli > 0 czyli istnieje

# jeśli nie istnieje to znajdź
    mov $0, %ecx                        # wpisz 0 do licznika nawiasów, zlicza on ilość pętli wewnętrznych
    find_right_bracket_loop:
        inc %esi                        # przejdź do następnego znaku w kodzie
        cmpb $'[', CODEBUFF(%esi)       # sprawdź czy to lewy nawias
        jne check_right
        inc %ecx                        # inkrementuj licznik ilości pętli wewnętrznych
        
        check_right:                    # sprawdź czy to jest prawy nawias
            cmpb $']', CODEBUFF(%esi)   # sprawdź czy to prawy nawias
            jne check_right_end         # jeśli nie jest nawiasem zamykającym to idź do końca procedury
            cmp $0, %ecx                
            je find_right_bracket_loop_end  # jeśli znaleziono właściwy nawias
            dec %ecx                    # znaleziono nawias jednej z pętli wewnętrznej więc dekrementuj licznik
            
            check_right_end:
                jmp find_right_bracket_loop  # wróć do początku pętli
    
        find_right_bracket_loop_end:
            mov $0, %edx
            mov %esi, %eax
            movw %ax, JUMPTABLE(%edx, %esi, 2)  # dodaj adres prawego nawiasu do JUMPTABLE
            jmp brainfuck_loop_end              # wróć do głównej pętli

jump_matching:                          # przeskakuje do zamykającego nawiasu
    mov $0, %edx
    movw JUMPTABLE(%edx, %ebx, 2), %ax  # przepisz adres zamykającego nawiasu do ax
    mov %eax, %esi                     # przepisz adres do wskaźnika po kodzie
    jmp brainfuck_loop_end



right_bracket:
    cmpb $0, (%edi)                     # jeżeli nie jest 0 to wróć do lewego nawiasu
    jne find_left_bracket

# jeśli jest równe 0 to zrzuć jeden nawias otwierający ze stosu
    add $8, %esp
    jmp brainfuck_loop_end

    find_left_bracket:
        mov (%esp), %esi
        jmp brainfuck_loop_end


brainfuck_end:                      # wypisz znak nowej linii i zakończ program
write $newline, $msg_end_line_len
mov $SYSEXIT, %eax                  # funkcja do wywołania - SYSEXIT
mov $EXIT_SUCCESS, %ebx             # odpowiedni kod podawany na wyjściu
int $SYSCALL32                      # przerwanie systemowe


# r12 interowanie po kodzie brainfuckowym - ESI
# r13 interowanie po tablicy - EDI

