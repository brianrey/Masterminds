; Traffic Light Controller
; Ver. 0.0.3
; Author: Masterminds (Connor, Brian, Wyatt)

; Required Virtual Devices
#start=Traffic_Lights.exe#

; Memory initialization
ORG 100h 

;Constants
; Internal Light colors, durations and states
	Green EQU 2                     ; Internal state tracking for Green
	Yellow EQU 1                    ; Internal state tracking for Yellow
	Red EQU 0                       ; Internal state tracking for Red
	
	GREEN_TIME EQU 10               ; Green light nominal duration
	YELLOW_TIME EQU 3               ; Yellow light nominal duration
	RED_TIME EQU 15                 ; Red light nominal duration
	
	EMERGENCY_TIME EQU 20           ; Emergency light operation, long Red for emergency vehicles.
	PED_TIME EQU 10                 ; Pedestrian light operation, long Red for walking
	
	NS_DIR EQU 0                    ; Stored value for NS direction
	WE_DIR EQU 1                    ; Vice versa for WE 
	
	Delay_Time EQU 00002H			; Adjust this value for timing speed	
	Current_TL_State DW 00000000b   ; 16 bits to store data in memory (planning for all lights)
	Current_Dir DB NS_DIR           ; Store current light direction (starts on NS)
	
; Traffic Light Controls (only two lights as of now)
    TL_Port EQU 4                   ; Send to Port 4
	TL_NSGreen_Cmd EQU 000100000100b      ; North/South light: Bit 2/8 = Green ON
	TL_NSYellow_Cmd EQU 00010000010b     ; North/South light: Bit 1/7 = Yellow ON
	TL_NSRed_Cmd EQU 00001000001b        ; North/South light: Bit 0/6 = Red ON
                                                                
    TL_WEGreen_Cmd EQU 100000100000b     ;West/East light: Bit 11/5 - Green ON
    TL_WEYellow_Cmd EQU 010000010000b    ;West/East light: Bit 10/4 = Yellow ON
    TL_WERed_Cmd EQU 001000001000b       ;West/East light: Bit 9/3 = Red ON
    
.data
	; Application Messages
    app_welcome DB 'Traffic Light Controller', 0DH, 0AH, '$'
    app_description DB 'Designed to control a single traffic light nominal operations,', 0DH, 0AH, 'handle Pedestrian and Emergency situations.', 0DH, 0AH, '$'
    app_authors DB 'Created by Masterminds: Connor, Brian, Wyatt', 0DH, 0AH, '$'
    app_initialized DB 'Application Initialized. (p = pedestrian, e = emergency, q = quit)', 0DH, 0AH, 'Waiting for input...', 0DH, 0AH, '$'

	; Application Variables
    PEDESTRIAN_PASS_PENDING DB 0 ; 0 = None, 1 = Waiting for Red light so it can be lengthened
    EMERGENCY_PENDING DB 0      ; 0 = None, 1 = Priority Red requested

.code
    JMP MAIN            ; Skip procedures and start at MAIN (allows initialize and welcome content to be at the top for clairity)

;Initialize - Initialize the data segment
INITIALIZE PROC
    MOV AX, @DATA
    MOV DS, AX

    RET
INITIALIZE ENDP

WELCOME_CONTENT PROC
    ; Display Welcome Messages - technically this would not display in headless but maybe there is a little led screen on the board
    LEA DX, app_welcome
    MOV AH, 09H					; Set print string command once and re-call with interrupt
    INT 21H						; Display Welcome Message
    LEA DX, app_description
    INT 21H						; Display Description
    LEA DX, app_authors
    INT 21H						; Display Authors
    LEA DX, app_initialized
    INT 21H                     ; Display initialized message
    RET
WELCOME_CONTENT ENDP

;Main - Main traffic light control loop
MAIN PROC
	; This section is only run once
    CALL INITIALIZE                 ; Initialize application
	CALL WELCOME_CONTENT            ; Print welcome messages

MAIN_LOOP:
	CALL GREEN_PROC
	CALL YELLOW_PROC
	CALL RED_PROC
	JMP MAIN_LOOP 		; Continuous loop of MAIN_LOOP (using JMP allows for no stack overflow from recursion)
MAIN ENDP

;Green - Process light transition, light duration, and check for user input.
GREEN_PROC PROC
    MOV Current_TL_State, Green 	; Sets Current_TL_State to Green for internal tracking of current light.
	
	CMP Current_Dir, NS_DIR
	
	JE NS_GREEN
	
	WE_GREEN:
	    MOV AX, TL_WEGreen_Cmd
	    JMP SET_GREEN
	
	NS_GREEN: 
	    MOV AX, TL_NSGreen_Cmd
	
	SET_GREEN:
	    CALL CMD_TRAFFIC_LIGHT
	    MOV CX, GREEN_TIME

GREEN_LOOP:
    CALL USER_INPUT     			; Check for user input
    CALL DELAY                      ; Call time delay for light
    LOOP GREEN_LOOP     			; Decrements CX and repeats
	RET
GREEN_PROC ENDP

;Yellow - Process light transition, light duration, and check for user input.
YELLOW_PROC PROC
	CMP Current_Dir, NS_DIR
    JE NS_YELLOW

    MOV AX, TL_WEYellow_Cmd
    JMP SET_YELLOW

    NS_YELLOW:
        MOV AX, TL_NSYellow_Cmd
    
    SET_YELLOW:
        CALL CMD_TRAFFIC_LIGHT
        MOV CX, YELLOW_TIME

YELLOW_LOOP:
    CALL USER_INPUT					; Check for user input
    CALL DELAY                      ; Call time delay for light
    LOOP YELLOW_LOOP				; Decrements CX and repeats
	RET
YELLOW_PROC ENDP

;Red - Process light transition, light duration, and check for user input.
RED_PROC PROC
	CMP Current_Dir, NS_DIR
    JE NS_RED

    MOV AX, TL_WERed_Cmd
    JMP SET_RED

    NS_RED:
        MOV AX, TL_NSRed_Cmd
    
    SET_RED:
        CALL CMD_TRAFFIC_LIGHT
        MOV CX, RED_TIME
    
    ; Check if an emergency or pedestrian was triggered
    CMP EMERGENCY_PENDING, 1
    JNE CHECK_PED_PASS_PENDING
    
    ADD CX, EMERGENCY_TIME
    MOV EMERGENCY_PENDING, 0
    MOV PEDESTRIAN_PASS_PENDING, 0 	; Clear pedestrian too if both were set
    JMP RED_LOOP 

CHECK_PED_PASS_PENDING:
    ; Check if a pedestrian is waiting, otherwise normal red
    CMP PEDESTRIAN_PASS_PENDING, 1
    JNE RED_LOOP

    ADD CX, PED_TIME         	    ; Add extra time for the waiting pedestrian
    MOV PEDESTRIAN_PASS_PENDING, 0  ; Clear the flag

RED_LOOP:
    CALL USER_INPUT		; Check for user input
    CALL DELAY          ; Call time delay for light
    LOOP RED_LOOP		; Decrements CX and repeats 

    CMP Current_Dir, NS_DIR
    JE SWITCH  
    
    MOV Current_Dir, NS_DIR
    JMP DONE
    
SWITCH:
    MOV Current_Dir, WE_DIR

DONE:
    RET
    
RED_PROC ENDP

;Input Check - Check for user char input and compare to known input controls (p, e, q), Non-blocking
USER_INPUT PROC
	MOV AH, 01H         ; Check keyboard buffer for character
	INT 16H
	JZ NO_INPUT         ; ZF=1 (Zero Flag) means no key pressed
	
	MOV AH, 00H         ; Read character into AL
	INT 16H

	; Check for commands
	CMP AL, 'p'
	JE CALL_PED         ; Check for lower case 'p'
	CMP AL, 'P'
	JE CALL_PED         ; Check for upper case 'P'
	
	CMP AL, 'e'
	JE CALL_EMER        ; Check for lower case 'e'
	CMP AL, 'E'
	JE CALL_EMER        ; Check for upper case 'E'
	
	CMP AL, 'q'
	JE EXIT_PROGRAM     ; Check for lower case 'q'
	CMP AL, 'Q'
	JE EXIT_PROGRAM     ; Check for upper case 'Q'
	
	RET					; return if no matching input

CALL_PED:
	CALL PEDESTRIAN
	RET					; return after pedestrian procedure

CALL_EMER:
	CALL EMERGENCY
	RET					; return after emergency procedure

NO_INPUT:
	RET					; return if no input
USER_INPUT ENDP

;Exit program
EXIT_PROGRAM:
    HLT					; halt the processor

;Delay - Software delay loop for timing, rough second
DELAY PROC
    PUSH BX                 ; Store the current BX so we don't clobber it, if any.
    MOV BX, Delay_Time      ; Adjust this value for timing speed at the top of the application code.

DELAY_LOOP:
    CALL USER_INPUT         ; Check for user input during delay
    NOP                     ; No operation
    DEC BX                  ; Decrement our separate delay counter, to allow for CX and BX usage at the same time for looping
    JNZ DELAY_LOOP          ; Repeat delay loop until BX is 0
    POP BX                  ; Restore the current BX
    RET
DELAY ENDP

;Emergency - Process transition for emergency
EMERGENCY PROC
	; Check current state in Current_TL_State
        CMP Current_TL_State, Red       ; Internal state tracking check
    	JE RED_EMER
        
        ; If Green or Yellow, speed up transition to Red
        MOV CX, 1
        MOV EMERGENCY_PENDING, 1
        RET
    
    RED_EMER:
        ; If already Red, stay Red longer
        ADD CX, EMERGENCY_TIME
        RET
EMERGENCY ENDP

;Pedestrian - Adjust current timing based on current light color. Reduce time to red and increase red.
PEDESTRIAN PROC
    ; Check current state in Current_TL_State
        CMP Current_TL_State, Green
    	JE GREEN_PED
        CMP Current_TL_State, Yellow
    	JE YELLOW_PED
        CMP Current_TL_State, Red
    	JE RED_PED
        RET
    
    GREEN_PED:
        ; Shorten green time to end soon
        MOV CX, 1 
        MOV PEDESTRIAN_PASS_PENDING, 1 		; Mark that Red should be longer later
        RET
    
    YELLOW_PED:
        ; Yellow is already short
        RET
    
    RED_PED:
        ; Red: stay red longer for safe crossing
        ADD CX, PED_TIME
        RET
PEDESTRIAN ENDP

;Traffic Light Command - Send the color command to the traffic light (caller sets AX to desired color prior to calling this procedure).
CMD_TRAFFIC_LIGHT PROC
	OUT TL_Port, AX
	RET
CMD_TRAFFIC_LIGHT ENDP