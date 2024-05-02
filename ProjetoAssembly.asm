.686
.model flat, stdcall
option casemap :none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data

; Textos
texto1 db "=============== MENU ===============", 0ah, 0h
texto2 db "1 - Criptografar", 0ah, 0h
texto3 db "2 - Descriptografar", 0ah, 0h
texto4 db "3 - Sair", 0ah, 0h
texto5 db "Insira o nome do arquivo de entrada (max 50 caracteres): ", 0ah, 0h
texto6 db "Insira o nome do arquivo de saida (max 50 caracteres): ", 0ah, 0h
texto7 db "Insira a chave (8 digitos de 0 a 7): ", 0ah, 0h

; Escolha do usuario
escolha db 50 dup(0)

temp dword ? 

indice dd 0

; Nome dos arquivos de entrada e saida
entradaName db 50 dup(0)
saidaName db 50 dup(0)

quantiaLida dd 0

; Handles
writeHandle dd 0
readHandle dd 0
entradaHandle dd 0
saidaHandle dd 0

; Chave
chaveASCII db 11 dup(0)
chaveDWORD dd 8 dup(0)

; Buffer
entradaBuffer db 8 dup(0)
saidaBuffer db 8 dup(0)

; Bytes
bytesLidos dd 0
bytesEscritos dd 0


.code
start:

; EXPLICAÇÃO DO CÓDIGO:
; 1 - IMPRIME O MENU DE OPÇÕES NA CONSOLE E CONVERTE O INPUT DO USUARIO PARA DWORD PARA FAZER COMPARAÇÂO
; 2 - ENCERRA O PROGRAMA SE O USUARIO ESCOLHER 3
; 3 - SE O USUÁRIO ESCOLHER 1 OU 2 LEVA PARA A PARTE DE COLOCAR OS NOMES DOS ARQUIVOS E A CHAVE (CHAMAMOS DE ENTRIES)
; 4 - NOS PRÓPRIOS LABELS DE ENTRIES, OS NOMES DOS ARQUIVOS E A CHAVE SÃO TRATADOS PARA SEREM USADOS ADEQUADAMENTE, E O ARQUIVO DE ENTRADA É ABERTO E O DE SAÍDA CRIADO. ALÉM DISSO SÃO CHAMADOS OS LABELS QUE CHAMAMOS DE PREPARE
; 5 - OS LABELS DE PREPARE FARÃO O PUSH DOS PARÂMETROS PARA A PILHA E CHAMARÃO A FUNÇÃO CORRETA (criptografar_func ou descriptografar_func)
; 6 - AS FUNÇÔES ENTÃO FARÃO AS MANIPULAÇÕES ADEQUADAS E ESCREVERÃO O TEXTO DO ARQUIVO DE ENTRADA DE FORMA CRIPTOGRAFADA NO ARQUIVO DE SAIDA
; OBSERVAÇÃO: AO SE DEPARAR COM CARACTERES EM MANDARIM AO ABRIR OS TXT COM BLOCO DE NOTAS, ABRIR O ARQUIVO COM LEITURA EM UTF-8 PARA CORRETA VISUALIZAÇÃO


; Definindo handles 
invoke GetStdHandle, STD_OUTPUT_HANDLE
mov writeHandle, eax
invoke GetStdHandle, STD_INPUT_HANDLE
mov readHandle, eax


; Menu de opcoes
menu:
    invoke WriteConsole, writeHandle, addr texto1, sizeof texto1, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto2, sizeof texto2, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto3, sizeof texto3, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto4, sizeof texto4, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr escolha, sizeof escolha, addr quantiaLida, NULL

    ; Conversao de ASCII para DWORD
    mov esi, offset escolha
    proximo:
        mov al, [esi]
        inc esi
        cmp al, 13
        jne proximo
        dec esi
        xor al, al
        mov [esi], al
    invoke atodw, addr escolha
    cmp eax, 3
    je encerrar
    cmp eax, 2
    je descriptografar_entries
    cmp eax, 1
    je criptografar_entries
    jmp menu


criptografar_entries:
    ; Pegando nome de arquivos e chave
    invoke WriteConsole, writeHandle, addr texto5, sizeof texto5 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr entradaName, sizeof entradaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto6, sizeof texto6 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr saidaName, sizeof saidaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto7, sizeof texto7 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr chaveASCII, sizeof chaveASCII, addr quantiaLida, NULL
    
    ; Tratando os nomes de arquivos
    mov esi, offset entradaName
    proximo1: 
        mov al, [esi]
        inc esi
        cmp al, 13
        jne proximo1
        dec esi
        xor al, al
        mov [esi], al
    mov esi, offset saidaName
    proximo2:
        mov al, [esi]
        inc esi
        cmp al, 13
        jne proximo2
        dec esi
        xor al, al
        mov [esi], al

    ; Tratando a chave
    mov esi, offset chaveASCII
    mov edi, offset chaveDWORD
    xor ecx, ecx
    convert_loop:
        mov al, [esi]
        cmp al, 0
        je resto
        sub al, '0'
        movzx eax, al
        mov ebx, ecx
        shl ebx, 2
        add [edi + ebx], eax
        inc esi
        inc ecx
        jmp convert_loop

    resto:
    ; Abertura e criacao de arquivos
    invoke CreateFile, addr entradaName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov entradaHandle, eax
    invoke CreateFile, addr saidaName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov saidaHandle, eax
    jmp criptografar_prepare

descriptografar_entries:
    invoke WriteConsole, writeHandle, addr texto5, sizeof texto5 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr entradaName, sizeof entradaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto6, sizeof texto6 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr saidaName, sizeof saidaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto7, sizeof texto7 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr chaveASCII, sizeof chaveASCII, addr quantiaLida, NULL
    
    ; Tratando os nomes de arquivos
    mov esi, offset entradaName
    proximoo: 
        mov al, [esi]
        inc esi
        cmp al, 13
        jne proximoo
        dec esi
        xor al, al
        mov [esi], al
    mov esi, offset saidaName
    proximooo:
        mov al, [esi]
        inc esi
        cmp al, 13
        jne proximooo
        dec esi
        xor al, al
        mov [esi], al

    ; Tratando a chave
    mov esi, offset chaveASCII
    mov edi, offset chaveDWORD
    xor ecx, ecx
    convert_loop2:
        mov al, [esi]
        cmp al, 0
        je resto3
        sub al, '0'
        movzx eax, al
        mov ebx, ecx
        shl ebx, 2
        add [edi + ebx], eax
        inc esi
        inc ecx
        jmp convert_loop2

    resto3:
    ; Abertura e criacao de arquivos
    invoke CreateFile, addr entradaName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov entradaHandle, eax
    invoke CreateFile, addr saidaName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov saidaHandle, eax
    jmp descriptografar_prepare


; Faz o push dos parâmetros a serem usados pelas funcoes e depois as chama
criptografar_prepare:
    push offset entradaBuffer
    push offset saidaBuffer
    push offset chaveDWORD
    call criptografar_func
    jmp menu
    
descriptografar_prepare:
    push offset entradaBuffer
    push offset saidaBuffer
    push offset chaveDWORD
    call descriptografar_func
    jmp menu


criptografar_func: 
    push ebp
    mov ebp, esp
    sub esp, 12

    ; Movendo para [ebp - 4] o endereço de entradaBuffer
    mov eax, dword ptr [ebp + 16]
    mov dword ptr [ebp - 4], eax
     
    ; Movendo para [ebp - 8] o endereço de saidaBuffer
    mov eax, dword ptr [ebp + 12]
    mov dword ptr [ebp - 8], eax
    
    ; Movendo para [ebp - 12] o endereço de chaveDWORD
    mov eax, dword ptr [ebp + 8]
    mov dword ptr [ebp - 12], eax

    ; Lida do arquivo de entrada e escrita no de saida
    loopinho:

        ; Limpeza do buffer
        mov ecx, 0
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        clear_loop:
            cmp ecx, 8
            je resto2
            mov byte ptr [esi], 0
            inc esi
            inc ecx
            jmp clear_loop

        resto2:
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        invoke ReadFile, entradaHandle, esi, 8, addr bytesLidos, NULL
        mov eax, bytesLidos
        test eax, eax
        jz fechar       

        ; Criptografa
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        mov edi, dword ptr [ebp - 8] ; Movendo para edi o endereço de saidaBuffer
        mov edx, dword ptr [ebp - 12] ; Movendo para edx o endereço de chaveDWORD
        xor ecx, ecx
        cripto_loop:
            cmp ecx, 8
            je escrever
            mov eax, [edx + ecx * 4]
            movzx ebx, byte ptr [esi + ecx]
            mov [edi + eax], bl
            inc ecx
            cmp ecx, 8
            jl cripto_loop

        escrever:
            mov esi, dword ptr [ebp - 8] ; Movendo para esi o endereço de saidaBuffer          
            invoke WriteFile, saidaHandle, esi, 8, addr bytesEscritos, NULL
            jmp loopinho


    fechar:
        invoke CloseHandle, entradaHandle
        invoke CloseHandle, saidaHandle
        
        mov esp, ebp
        pop ebp
        ret 12

        jmp menu
    
    

descriptografar_func:
    push ebp
    mov ebp, esp
    sub esp, 12

    ; Movendo para [ebp - 4] o endereço de entradaBuffer
    mov eax, dword ptr [ebp + 16]
    mov dword ptr [ebp - 4], eax
     
    ; Movendo para [ebp - 8] o endereço de saidaBuffer
    mov eax, dword ptr [ebp + 12]
    mov dword ptr [ebp - 8], eax
    
    ; Movendo para [ebp - 12] o endereço de chaveDWORD
    mov eax, dword ptr [ebp + 8]
    mov dword ptr [ebp - 12], eax
    

    ; Lida do arquivo de entrada e escrita no de saida
    loopinhoo:
        ; Limpeza do buffer
        mov ecx, 0
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        clear_loop2:
            cmp ecx, 8
            je resto4
            mov byte ptr [esi], 0
            inc esi
            inc ecx
            jmp clear_loop2
            
        resto4:
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        invoke ReadFile, entradaHandle, esi, 8, addr bytesLidos, NULL
        mov eax, bytesLidos
        test eax, bytesLidos
        jz fechar2    

        ; Descriptografa
        mov esi, dword ptr [ebp - 4] ; Movendo para esi o endereço de entradaBuffer
        mov edi, dword ptr [ebp - 8] ; Movendo para edi o endereço de saidaBuffer
        mov edx, dword ptr [ebp - 12] ; Movendo para edx o endereço de chaveDWORD
        xor ecx, ecx
        loop_descripto:
            cmp ecx, 8
            je escrever2
            mov eax, [edx + ecx * 4]
            movzx ebx, byte ptr [esi + eax]
            mov [edi + ecx], bl
            inc ecx
            cmp ecx, 8
            jl loop_descripto
            
        escrever2:
            mov esi, dword ptr [ebp - 8] ; Movendo para esi o endereço de saidaBuffer
            invoke WriteFile, saidaHandle, esi, 8, addr bytesEscritos, NULL
            jmp loopinhoo

    fechar2:
        invoke CloseHandle, entradaHandle
        invoke CloseHandle, saidaHandle

        mov esp, ebp
        pop ebp
        ret 12

        jmp menu


encerrar:
    invoke ExitProcess, 0

end start