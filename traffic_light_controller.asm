; Traffic Light Controller
; Ver. 0.0.1
; Author: Masterminds

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
    app_description 'Designed to controll a single traffic light and handle Prdestrian and Emergency situations.'
    app_authors DB 'Created by Masterminds: Connor, Brian, Wyatt'
    newline DB 0DH, 0AH, '$'

.ode
;Initialize - Initialize the data segment
INITIALIZE PROC
    MOV AX, @DATA
    MOV DS, AS
INITIALIZE ENDP

;Main - Main traffic light control loop
MAIN PROC
	CALL GREEN_PROC
	CALL YELLOW_PROC
	CALL RED_PROC
	CALL MAIN ; continuous loop of MAIN
MAIN ENDP

;Green - Process light transition, light duration, and check for user input.
GREEN_PROC PROC
    ;Set register (one of em) to 3
	;Turn on that red light (roxanne)
	CALL USER_INPUT
	;Loop it! For a time
	RET
GREEN_PROC ENDP

;Yellow - Process light transition, light duration, and check for user input.
YELLOW_PROC PROC
	;Set register (one of em) to 2
	;Turn on that yellow light
	CALL USER_INPUT
	;Loop it! For a time
	RET
YELLOW_PROC ENDP

;Red - Process light transition, light duration, and check for user input.
RED_PROC PROC
	;Set register (one of em) to 3
	;Turn on that red light (roxanne)
	CALL USER_INPUT
	;Loop it! For a time
	RET
RED_PROC ENDP

;Input Check - Check for user char input and compare to known input controls
USER_INPUT PROC
	;Check if input
	; No input 
	RET
	; If pedestrian, 
	CALL PEDESTRIAN
	
	; If emergency, 
	CALL EMERGENCY
	
USER_INPUT ENDP

;Emergency - Process transition for emer
EMERGENCY PROC
	;ROXANNE (red light)
	
	;Jump to MAIN / green (restart loops)
	CALL MAIN
EMERGENCY ENDP

;Procedure name and description
PEDESTRIAN PROC
    ;Check current light
    ;If green
		;Shorten time at green (shorten counter?)
		; call normal Yellow
		; call Red (roxanne) increased time
		
        ;Jump to MAIN / green (restart loops)
	    CALL MAIN
    ;If yellow 
		;Continue as normal
		;Red increased time
		
        ;Jump to MAIN / green (restart loops)
	    CALL MAIN
    ;If red
		;increased red time
		
        ;Jump to MAIN / green (restart loops)
	    CALL MAIN
PEDESTRIAN ENDP