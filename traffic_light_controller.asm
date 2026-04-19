; Traffic Light Controller
; Ver. 0.0.3
; Author: Masterminds (Connor, Brian, Wyatt)

; Required Virtual Devices
#start=Traffic_Lights.exe#

; Memory initialization
ORG 100h 

;Constants
; Internal Light colors, durations and states
	Green EQU 2 
	Yellow EQU 1
	Red EQU 0
	Delay_Time EQU 00050H			; Adjust this value for timing speed	
	Current_TL_State DW 00000000b  ; 16 bits to store data in memory (planning for all lights)
	
; Traffic Light Controls (only one light as of now)
    TL_Port EQU 4               ; Send to Port 4
	TL_Green_Cmd EQU 00000100b      ; South light: Bit 2 = Green ON
	TL_Yellow_Cmd EQU 00000010b     ; South light: Bit 1 = Yellow ON
	TL_Red_Cmd EQU 00000001b        ; South light: Bit 0 = Red ON
    
.data
	; Application Messages
    app_welcome DB 'Traffic Light Controller', 0DH, 0AH, '$'
    app_description DB 'Designed to control a single traffic light and handle Pedestrian and Emergency situations.', 0DH, 0AH, '$'
    app_authors DB 'Created by Masterminds: Connor, Brian, Wyatt', 0DH, 0AH, '$'
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
    RET
WELCOME_CONTENT ENDP

;Main - Main traffic light control loop
MAIN PROC
	; This section is only run once
    CALL INITIALIZE
	CALL WELCOME_CONTENT

MAIN_LOOP:
	CALL GREEN_PROC
	CALL YELLOW_PROC
	CALL RED_PROC
	JMP MAIN_LOOP 		; Continuous loop of MAIN_LOOP (using JMP allows for no stack overflow from recursion)
MAIN ENDP

;Green - Process light transition, light duration, and check for user input.
GREEN_PROC PROC
    MOV Current_TL_State, Green 	; Sets Current_TL_State to Green for internal tracking of current light.
	MOV AX, TL_Green_Cmd			; Sets AX to Green command for the CMD_TRAFFIC_LIGHT procedure
	CALL CMD_TRAFFIC_LIGHT			; Sends the ligt set in AX to the configured traffic light port
    MOV CX, 10          			; 10 units of time

GREEN_LOOP:
    CALL USER_INPUT     			; Polling for 'p', 'e', 'q', 'P', 'E', 'Q'
    CALL DELAY
    LOOP GREEN_LOOP     			; Decrements CX and repeats
	RET
GREEN_PROC ENDP

;Yellow - Process light transition, light duration, and check for user input.
YELLOW_PROC PROC
	MOV Current_TL_State, Yellow 	; Sets Current_TL_State to Yellow for internal tracking of current light.
	MOV AX, TL_Yellow_Cmd			; Sets AX to Yellow command for the CMD_TRAFFIC_LIGHT procedure
	CALL CMD_TRAFFIC_LIGHT			; Sends the ligt set in AX to the configured traffic light port
    MOV CX, 5           			; 5 units of time

YELLOW_LOOP:
    CALL USER_INPUT					; Polling for 'p', 'e', 'q', 'P', 'E', 'Q'
    CALL DELAY
    LOOP YELLOW_LOOP				; Decrements CX and repeats
	RET
YELLOW_PROC ENDP

;Red - Process light transition, light duration, and check for user input.
RED_PROC PROC
	MOV Current_TL_State, Red 		; Sets Current_TL_State to Red for internal tracking of current light.
	MOV AX, TL_Red_Cmd				; Sets AX to Red command for the CMD_TRAFFIC_LIGHT procedure
	CALL CMD_TRAFFIC_LIGHT			; Sends the ligt set in AX to the configured traffic light port
    MOV CX, 15						; 15 units of time
    
    ; Check if an emergency or pedestrian was triggered
    CMP EMERGENCY_PENDING, 1
    JNE CHECK_PED_PASS_PENDING
    ADD CX, 20						; Add time for emergency first responders
    MOV EMERGENCY_PENDING, 0
    MOV PEDESTRIAN_PASS_PENDING, 0 	; Clear pedestrian too if both were set
    JMP RED_LOOP

CHECK_PED_PASS_PENDING:
    ; Check if a pedestrian is waiting
    CMP PEDESTRIAN_PASS_PENDING, 1
    JNE RED_LOOP
    ADD CX, 10         					; Add extra time for the waiting pedestrian
    MOV PEDESTRIAN_PASS_PENDING, 0 		; Clear the flag

RED_LOOP:
    CALL USER_INPUT			; Polling for 'p', 'e', 'q', 'P', 'E', 'Q'
    CALL DELAY
    LOOP RED_LOOP			; Decrements CX and repeats
	RET
RED_PROC ENDP

;Input Check - Check for user char input and compare to known input controls (p, e, q), Non-blocking
USER_INPUT PROC
	MOV AH, 01H         ; Check keyboard buffer
	INT 16H
	JZ NO_INPUT         ; ZF=1 means no key pressed
	
	MOV AH, 00H         ; Read key into AL
	INT 16H

	; Check for commands
	CMP AL, 'p'
	JE CALL_PED
	CMP AL, 'P'
	JE CALL_PED
	
	CMP AL, 'e'
	JE CALL_EMER
	CMP AL, 'E'
	JE CALL_EMER
	
	CMP AL, 'q'
	JE EXIT_PROGRAM
	CMP AL, 'Q'
	JE EXIT_PROGRAM
	
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
    HLT					; halt the processor OR SOMETHING BETTER TODO

;Delay - Software delay loop for timing, rough second
DELAY PROC
    PUSH CX
    MOV CX, Delay_Time      ; Adjust this value for timing speed at the top of the application code.
DELAY_LOOP:
    NOP
    LOOP DELAY_LOOP
    POP CX
    RET
DELAY ENDP

;Emergency - Process transition for emergency
EMERGENCY PROC
	; Check current state in Current_TL_State
    CMP Current_TL_State, Red
	JE RED_EMER
    
    ; If Green or Yellow, speed up transition to Red
    MOV CX, 1
    MOV EMERGENCY_PENDING, 1
    RET

RED_EMER:
    ; If already Red, stay Red longer
    ADD CX, 20
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
    ADD CX, 10
    RET
PEDESTRIAN ENDP

CMD_TRAFFIC_LIGHT PROC
	; caller puts the color in AX
	OUT TL_Port, AX
	RET
CMD_TRAFFIC_LIGHT ENDP
    