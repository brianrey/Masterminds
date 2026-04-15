ORG 100h                

MOV CX, 10 ;Total loops
             
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
    
    