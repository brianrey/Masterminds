ORG 100h                

;Constants
; Internal Light Colors
	Green EQU 2 
	Yellow EQU 1
	Red EQU 0
	Expected_TL_State DW 00000000b  ; 16 bits to store data in memory (planning for all lights)
	
; Traffic Light Controls (only one light as of now)
    TL_Port EQU 4               ; Send to Port 4
	TL_Green_Cmd EQU 00000100b      ; Bit 2 = Green ON
	TL_Yellow_Cmd EQU 00000010b     ; Bit 1 = Yellow ON
	TL_Red_Cmd EQU 00000001b        ; Bit 0 = Red ON
	           
	;Debugging Controls
	TEST_TL_All_Cmd EQU 00000111b       ; Test pattern for diagnostic, all lights
    TEST_TL_Chaos_L_Cmd EQU 00100100b   ; low byte, Test pattern for diagnostic, all lights
    TEST_TL_Chaos_H_Cmd EQU 00001001b   ; high byte, Test pattern for diagnostic, all lights
    
.data
    app_welcome DB 'Traffic Light Controller'
    app_description DB 'Designed to controll a single traffic light and handle Prdestrian and Emergency situations.'
    app_authors DB 'Created by Masterminds: Connor, Brian, Wyatt'
    newline DB 0DH, 0AH, '$'       

.code
;Initialize - Initialize the data segment
INITIALIZE PROC
    MOV AX, @DATA  
    MOV CX, 10
    MOV DS, AX
INITIALIZE ENDP
             
;Main Process
MAIN PROC
    CALL GREEN    
    CALL YELLOW
    CALL RED
    CALL MAINLOOP
    HLT
MAIN ENDP   

;Main Loop 
MAINLOOP PROC
    DEC CX
    CMP CX, 0
    JNE MAIN
    RET
MAINLOOP ENDP

;Green Light Process
GREEN PROC
    MOV AX, 1
    MOV BX, 10 
    CALL GREENLOOP
    RET 
GREEN ENDP  

GREENLOOP PROC   
    CALL USER
    DEC BX
    CMP BX, 0
    JNE GREENLOOP
    RET
GREENLOOP ENDP 

;Yellow Light Process
YELLOW PROC
    MOV AX, 2
    MOV BX, 5 
    CALL YELLOWLOOP
    RET 
YELLOW ENDP  

YELLOWLOOP PROC   
    CALL USER
    DEC BX
    CMP BX, 0
    JNE YELLOWLOOP
    RET
YELLOWLOOP ENDP  

;Red Light Process
RED PROC
    MOV AX, 2
    MOV BX, 15 
    CALL REDLOOP
    RET 
RED ENDP  

REDLOOP PROC  
    CALL USER
    DEC BX
    CMP BX, 0
    JNE REDLOOP
    RET
REDLOOP ENDP    

USER PROC     
    MOV AH, 01H
    INT 16H
    JZ  NO_PRESS
    
    MOV AH, 00H
    INT 16H
    
NO_PRESS:
    RET

USER ENDP
    
    