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
chave db 8 dup(0)

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
    invoke WriteConsole, writeHandle, addr texto5, sizeof texto5 - 2, quantiaLida, NULL
    invoke ReadConsole, readHandle, addr entradaName, sizeof entradaName, quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto6, sizeof texto6 - 2, quantiaLida, NULL
    invoke ReadConsole, readHandle, addr saidaName, sizeof saidaName, quantiaLida, NULL
    invoke WriteConsole, writeHandle, addr texto7, sizeof texto7, quantiaLida, NULL
    invoke ReadConsole, readHandle, addr chave, sizeof chave, quantiaLida, NULL
    
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

    ; Abertura e criacao de arquivos
    invoke CreateFile, addr entradaName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov entradaHandle, eax
    invoke CreateFile, addr saidaName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov saidaHandle, eax

    ; Lida do arquivo de entrada e escrita no de saida
    loopinho:
        invoke ReadFile, entradaHandle, addr fileBuffer, 8, addr bytesLidos, NULL
        mov eax, bytesLidos
        test eax, bytesLidos
        jz fechar
        invoke WriteFile, saidaHandle, addr fileBuffer, 8, addr bytesEscritos, NULL
        jmp loopinho

    fechar:
        invoke CloseHandle, entradaHandle
        invoke CloseHandle, saidaHandle
    
    

descriptografar:


encerrar:
    invoke ExitProcess, 0

end start