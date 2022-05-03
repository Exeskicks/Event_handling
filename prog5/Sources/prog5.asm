.386

.MODEL      flat, stdcall
OPTION      casemap:none

; включаемые файлы
   include c:\MASM32\INCLUDE\windows.inc
   include c:\MASM32\INCLUDE\masm32.inc
   include c:\MASM32\INCLUDE\gdi32.inc
   include c:\MASM32\INCLUDE\user32.inc
   include c:\MASM32\INCLUDE\kernel32.inc
; включаемые библиотеки
   includelib c:\MASM32\LIB\masm32.lib
   includelib c:\MASM32\LIB\gdi32.lib
   includelib c:\MASM32\LIB\user32.lib
   includelib c:\MASM32\LIB\kernel32.lib
  

cdXPos      EQU  128         ; Constante double X-Posición de la ventana(esq sup izqda)
cdYPos      EQU  128         ; Constante double Y-Posición de la ventana(esq sup izqda)
cdXSize     EQU  320+6        ; Constante double X-tamaño de la ventana
cdYSize     EQU  200+32       ; Constante double Y-tamaño de la ventana
cdColFondo  EQU  COLOR_BTNFACE + 1  ; Color de fondo de la ventana: gris de un botón de comando
cdVIcono    EQU  IDI_APPLICATION ; Icono de la ventana, véase Resource.H
cdVCursor   EQU  IDC_ARROW   ; Cursor para la ventana
cdVBarTipo  EQU  NULL                              ; Normal, con icono
cdVBtnTipo  EQU  WS_GROUP+WS_SYSMENU+WS_VISIBLE    ; Todos los botones visibles, pero sólo activos minimizar y cerrar
IDB_MAIN    EQU  101

WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD

.DATA
  NombreClase   DB "SimpleWinClass", 0
  MsgCabecera   DB "Dibujando un BMP en nuestra ventana (MASM)", 0
  wc            WNDCLASSEX  <>
  MsgError      DB 'Carga inicial fallida.',0

.DATA?
  CommandLine DD ?
  hBitmap     dd ?

.CODE
  start:
    INVOKE    GetModuleHandle, NULL
    MOV       wc.hInstance, EAX
    INVOKE    GetCommandLine
    MOV       CommandLine, EAX
    INVOKE    WinMain, wc.hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    INVOKE    ExitProcess, EAX

  WinMain PROC hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    ;  Propósito: Inicializamos la ventana principal de la aplicación y captura errores, si los hubiere
    ;  Entrada  : hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    ;  Salida   : Ninguna
    ;  Destruye : Ninguna
    LOCAL     msg:MSG
    LOCAL     hwnd:HWND
    ; Si inicializamos wc con sus valores corremos el riesgo de hacerlo desordenadamente en caso
    ; de que se cambie la definición de la estructura WNDCLASSEX
    MOV       wc.cbSize, SIZEOF WNDCLASSEX
    MOV       wc.style, CS_HREDRAW OR CS_VREDRAW
    MOV       wc.lpfnWndProc, OFFSET WndProc
    MOV       wc.cbClsExtra, NULL
    MOV       wc.cbWndExtra, NULL 
    ; hInstance ya está valorado arriba
    MOV       wc.hbrBackground, cdColFondo  ; Color de fondo de la ventana
    MOV       wc.lpszMenuName, NULL
    MOV       wc.lpszClassName, OFFSET NombreClase
    INVOKE    LoadIcon, NULL, cdVIcono
    MOV       wc.hIcon, EAX
    MOV       wc.hIconSm, EAX
    INVOKE    LoadCursor, NULL, cdVCursor
    MOV       wc.hCursor, EAX
    INVOKE    RegisterClassEx, ADDR wc
    TEST      EAX, EAX
    JZ        L_Error
    INVOKE    CreateWindowEx,cdVBarTipo,ADDR NombreClase,ADDR MsgCabecera,\
              cdVBtnTipo,cdXPos, cdYPos, cdXSize, cdYSize,\
              NULL,NULL,hInst,NULL
    TEST      EAX, EAX
    JZ        L_Error
    MOV       hwnd, EAX
    INVOKE    ShowWindow, hwnd, SW_SHOWNORMAL
    INVOKE    UpdateWindow, hwnd

    .WHILE    TRUE
        INVOKE    GetMessage, ADDR msg, NULL, 0, 0
        .BREAK    .IF (!EAX)
        INVOKE    TranslateMessage, ADDR msg
        INVOKE    DispatchMessage, ADDR msg
    .ENDW
    JMP       L_Fin
    
    L_Error:
      INVOKE    MessageBox, NULL,ADDR MsgError, NULL, MB_ICONERROR+MB_OK

    L_Fin:
    MOV       EAX, msg.wParam
    RET
  WinMain ENDP
  
  WndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    ;  Propósito: Procesa los mensajes provenientes de las ventanas
    ;  Entrada  : hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    ;  Salida   : Ninguna
    ;  Destruye : Ninguna
    LOCAL     ps:PAINTSTRUCT
    LOCAL     hdc:HDC
    LOCAL     hMemDC:HDC
    LOCAL     rect:RECT
    .IF       uMsg == WM_DESTROY
        invoke    DeleteObject,hBitmap
        INVOKE    PostQuitMessage, NULL
    .ELSEIF   uMsg == WM_CREATE
        invoke    LoadBitmap,wc.hInstance,IDB_MAIN
        mov       hBitmap,eax
   .elseif uMsg==WM_PAINT
        invoke    BeginPaint,hWnd,addr ps
        mov       hdc,eax
        invoke    CreateCompatibleDC,hdc   ; Crea un contexto de dispositivo de memoria
        mov       hMemDC,eax    ; Selecciona nuestro bmp en el hMemDC reemplazando el objeto previo del mismo tipo.
        invoke    SelectObject,hMemDC,hBitmap
        invoke    GetClientRect,hWnd,addr rect  ; Recupera las coordenadas de un área de ventana cliente
        invoke    BitBlt,hdc,0,0,rect.right,rect.bottom,hMemDC,0,0,SRCCOPY  ; Ejecuta una transferencia de bit-bloque de datos de color correspondiente a un rectángulo desde un dispositivo fuente a otro destino
        invoke    DeleteDC,hMemDC  ; Borra el contexto de dispositivo especificado
        invoke    EndPaint,hWnd,addr ps
    .ELSE
        INVOKE    DefWindowProc, hWnd, uMsg, wParam, lParam
        RET
    .ENDIF
    XOR       EAX, EAX
    RET
  WndProc ENDP
END start