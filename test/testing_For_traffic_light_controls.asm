; Traffic Light Controller
; Ver. 0.0.1

; Initialize traffic light
#start=Traffic_Lights.exe#  ; Required to launch the simulator in Emu8086

.data
; Internal Light Colors
	Green EQU 2 
	Yellow EQU 1
	Red EQU 0
; Traffic Light Controls
    TL_Port EQU 4               ; Send to Port 4
	TL_Green_Cmd EQU 00000100b      ; Bit 2 = Green ON
	TL_Yellow_Cmd EQU 00000010b     ; Bit 1 = Yellow ON
	TL_Red_Cmd EQU 00000001b        ; Bit 0 = Red ON
	;Debugging Controls
	TEST_TL_All_Cmd EQU 00000111b       ; Test pattern for diagnostic, all lights
    TEST_TL_Chaos_L_Cmd EQU 00100100b   ; low byte, Test pattern for diagnostic, all lights
    TEST_TL_Chaos_H_Cmd EQU 00001001b   ; high byte, Test pattern for diagnostic, all lights
; Time Durations
	Emergency_Red_Dur EQU 9s             ; (as Red Light)
	Ped_Walk_Dur EQU 8s                ; (as Red Light)  CONSIDER; LED COUNT DOWN?
    Green_Dur EQU 3s
	Yellow_Dur EQU 3s
	Red_Dur EQU 3s


MOV AL, TL_Green_Cmd            ; Set traffic light green
OUT TL_Port, AL                 ; Send to Traffic Light Port
CALL DELAY                      ; Wait

MOV AL, TL_Yellow_Cmd          
OUT TL_Port, AL
CALL DELAY

MOV AL, TEST_TL_All_Cmd             ;Diagnositic Lights, Bit 0,1,2 all 1 (on)
OUT TL_Port, AL
CALL DELAY

MOV AL, TL_Red_Cmd                  ; Bit 0 = Red ON
OUT TL_Port, AL
CALL DELAY

HLT                        ; Terminate program

; --- Delay Procedure using Interrupt 15h ---
DELAY PROC
    MOV AH, 86h            ; BIOS wait function
    MOV CX, 001Eh          ; High word of microseconds
    MOV DX, 8480h          ; Low word (001E8480h = 2,000,000us = 2s)
    INT 15h                ; Trigger BIOS delay
    RET
DELAY ENDP
