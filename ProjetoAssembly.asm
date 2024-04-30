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
chave byte 8 dup(0)
chaveTratada dword 8 dup(0)

; Buffer
fileBuffer db 8 dup(0)

; Bytes
bytesLidos dd 0
bytesEscritos dd 0


.code
start:


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
    je descriptografar
    cmp eax, 1
    je criptografar
    jmp menu
    

criptografar:
    invoke WriteConsole, writeHandle, addr texto5, sizeof texto5 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr entradaName, sizeof entradaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto6, sizeof texto6 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr saidaName, sizeof saidaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto7, sizeof texto7 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr chave, sizeof chave, addr quantiaLida, NULL
    
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
    mov esi, offset chave
    mov edi, offset chaveTratada
    convert_loop:
        mov eax, 0
        mov ecx, 10

    char_para_dword_loop:
        movzx ebx, byte ptr [esi]
        cmp ebx, 0
        je end_conversion
        sub ebx, '0'
        imul eax, 10
        add eax, ebx
        inc esi
        loop char_para_dword_loop
        mov [edi], eax
        add edi, 4
        jmp convert_loop

    end_conversion:

    ; Abertura e criacao de arquivos
    invoke CreateFile, addr entradaName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov entradaHandle, eax
    invoke CreateFile, addr saidaName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov saidaHandle, eax

    ; Lida do arquivo de entrada e escrita no de saida
    loopinho:

        ; Limpeza do buffer
        mov ecx, 8
        mov esi, offset fileBuffer
        mov eax, 0
        clear_loop:
            mov [esi], eax
            add esi, 4
            loop clear_loop
    
        invoke ReadFile, entradaHandle, addr fileBuffer, 8, addr bytesLidos, NULL
        mov eax, bytesLidos
        test eax, bytesLidos
        jz fechar       

        ; Criptografa
        mov esi, offset fileBuffer
        mov edi, offset chaveTratada
        mov ecx, 8
        loop_cifra:
            movzx ebx, byte ptr [edi]
            add edi, type chaveTratada
            movzx eax, byte ptr [esi + ebx]
            mov byte ptr [esi + ebx], al
            inc esi
            loop loop_cifra

        
        invoke WriteFile, saidaHandle, addr fileBuffer, 8, addr bytesEscritos, NULL
        jmp loopinho


    fechar:
        invoke CloseHandle, entradaHandle
        invoke CloseHandle, saidaHandle
        jmp menu

        
    

descriptografar:
    invoke WriteConsole, writeHandle, addr texto5, sizeof texto5 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr entradaName, sizeof entradaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto6, sizeof texto6 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr saidaName, sizeof saidaName, addr quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto7, sizeof texto7 - 2, addr quantiaLida, NULL
    invoke ReadConsole, readHandle, addr chave, sizeof chave, addr quantiaLida, NULL
    
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

    ; Abertura e criacao de arquivos
    invoke CreateFile, addr entradaName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov entradaHandle, eax
    invoke CreateFile, addr saidaName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov saidaHandle, eax

    ; Limpeza do buffer
        mov ecx, 8
        mov esi, offset fileBuffer
        mov eax, 0
        clear_loopi:
            mov [esi], eax
            add esi, 4
            loop clear_loopi

    ; Lida do arquivo de entrada e escrita no de saida
    loopinhoo:
        
        invoke ReadFile, entradaHandle, addr fileBuffer, 8, addr bytesLidos, NULL
        mov eax, bytesLidos
        test eax, bytesLidos
        jz fechar2    

        ; Descriptografa
        mov edi, offset fileBuffer
        mov ecx, 8
        mov ebx, 0
        loop_descripto:
            mov eax, ebx
            mov edx, 0
            mov dl, chave[eax]
            mov al, [edi + edx]
            mov [edi + eax], al
            inc ebx
            loop loop_descripto
   
        invoke WriteFile, saidaHandle, addr fileBuffer, 8, addr bytesEscritos, NULL
        jmp loopinhoo

    fechar2:
        invoke CloseHandle, entradaHandle
        invoke CloseHandle, saidaHandle

        jmp menu


encerrar:
    invoke ExitProcess, 0

end start