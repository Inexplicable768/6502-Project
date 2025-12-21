;==================================================
;  SuperBIOS 6502  (for Ben Eater + Pi Pico VGA)
;==================================================
; 640x480 video mode

; MEMORY MAP - 64 KB of adressable memory
;Zero Page	  $0000-$00FF	256 B
;Stack	          $0100-$01FF	256 B
;RAM	          $0200-$7FFF	32,256 B
;BIOS	          $8000-$8FFF	4 KB

;Program ROM 1	  $9000-$ABFF	7 KB - Calculator
;Program ROM 2	  $AC00-$C7FF	7 KB - Text Editor
;Program ROM 3	  $C800-$E3FF	7 KB - Clock
;Program ROM 4	  $E400-$FFF9	7 KB - Tetris
;Interrupt Vectors $FFFA-$FFFF	6 B

 ; Hardware Definitions
 
        .org $8000

ACIA_DATA   = $6000
ACIA_STATUS = $6001
ACIA_CMD    = $6002
ACIA_CTRL   = $6003

INPUT_BUFFER = $0200    ; start of shell i/o RAM
BUFFER_SIZE  = 32       ; 32 byte 

; keep track of the cursor position then when it gets to bottom send command 0x4 to pico
result:  .byte 0     ; result container for math
CURSOR_X: .byte 0  ; column
CURSOR_Y: .byte 0  ; row
GRAPHICS_MODE: .byte 0 ; 0 = text mode, 1 = video mode
TEXTMODE_W = 80
TEXTMODE_H = 50

 ; RESET Vector — system startup
 
RESET:
init_system:  ; Show banner at top and info
        sei                     ; disable interrupts
        cld                     ; clear decimal mode
        ldx #$FF
        txs                     ; initialize stack pointer

        ; Initialize ACIA (serial interface)
        lda #$00
        sta ACIA_CMD            ; reset ACIA
        lda #%00011111          ; 115200 baud, 8N1, no parity
        sta ACIA_CTRL

        ; Print BIOS banner
        lda #<HELLO_MSG
        sta $00
        lda #>HELLO_MSG
        sta $01
        jsr print_string
        
        ; Print option message
        jsr new_line
        lda #<BOOT_MSG
        sta $00
        lda #>BOOT_MSG
        sta $01
        jsr print_string

        jmp main_loop           ; enter idle/command loop

; MAIN PROGRAM LOOP
main_loop: 

        ; read user commands

        jmp main_loop   ; repeat

 

 ; Print new line
 
new_line:
        lda #$0D
        jsr put_char
        lda #$0A
        jsr put_char
        rts


 ; Send a character to ACIA / serial output
 
put_char:
        pha
.wait_tx:
        lda ACIA_STATUS
        and #%00010000          ; transmitter ready?
        beq .wait_tx
        pla
        sta ACIA_DATA
        rts


 ; Read a character from ACIA (blocking)
; Returns char in A
 
read_char:
.wait_rx:
        lda ACIA_STATUS
        and #%00001000          ; data received?
        beq .wait_rx
        lda ACIA_DATA
        rts

; read a line of text
read_line:
        ldx #0
.rl_loop:
        jsr read_char       ; get a character
        cmp #$0D            ; Enter pressed?
        beq .done

        jsr put_char        ; echo it
        sta INPUT_BUFFER,x  ; store it
        inx
        cpx #BUFFER_SIZE
        bne .rl_loop
.done:
        lda #0
        sta INPUT_BUFFER,x  ; null terminator
        jsr new_line
        rts

 ; Print zero-terminated string
; Address in $00/$01
 
print_string:
        ldy #0
.ps_loop:
        lda ($00),y
        beq .done
        jsr put_char
        iny
        bne .ps_loop
.done:
        rts


 ; Send command byte to Pico (for VGA, etc.)
 
send_command:
        pha
.wait_tx2:
        lda ACIA_STATUS
        and #%00010000
        beq .wait_tx2
        pla
        sta ACIA_DATA
        rts


 ; VGA / Pico Command Stubs
 
put_pixel:      ; A=X, X=Y, Y=color
        lda #$01
        jsr send_command
        rts

draw_rect:      ; draw rectangle
        lda #$02
        jsr send_command
        rts

fill_screen:    ; fill screen with color in A. #00 means blank
        lda #$03
        jsr send_command
        rts
scroll_screen:
        lda #$04
        jsr send_command
        rts

 ;;;; Simple command prompt / shell
 

compare_string:
        ldy #0
.cs_loop:     ; basically keep incrementing y until we get to the max chars
        lda INPUT_BUFFER,y
        cmp ($00),y
        bne .not_equal
        beq .check_end
.check_end:
        beq .equal           ; if both are zero, done
        iny
        bne .cs_loop
.not_equal:
        clc                  ; clear Z
        lda #1               ; any nonzero value
        rts
.equal:
        lda #0
        rts                  ; Z=1 (A=0)

 ; Commands
 

cmd_help:
        lda #<HELP_MSG
        sta $00
        lda #>HELP_MSG
        sta $01
        jsr print_string
        jmp main_loop

cmd_clear:
        lda #$00
        jsr fill_screen
        jsr new_line
        lda #<CLR_MSG
        sta $00
        lda #>CLR_MSG
        sta $01
        jsr print_string
        jmp main_loop

cmd_load:
        lda #<BOOT_MSG2
        sta $00
        lda #>BOOT_MSG2
        sta $01
        jsr print_string
        ; (In future: jump to BASIC / floppy bootloader)
        jmp main_loop


;;; PS/2 KEYBOARD INPUT READING ;;;


;;;;;;;;;;;;; Data Section

DIRS:
        .byte "CMD:\>", $0D,$0A
        .byte "". $0D,$0A
HELLO_MSG:
        .byte $0D, $0A
        .byte "-= SuperBIOS 6502 v1.1 for Pico VGA =-",0

BOOT_MSG: ; ask user what to do when the bios starts up
        .byte "Enter "load" to load a program. Enter help for commands",0

HELP_MSG:
        .byte $0D, $0A     ; new line
        .byte "Commands:",$0D,$0A
        .byte "help", $0D,$0A
        .byte "cls", $0D,$0A
        .byte "time", $0D,$0A
        .byte "specs", $0D,$0A      ; pc specs and hardware info
        .byte "load", $0D,$0A
        .byte "quit", $0D,$0A,0

CLR_MSG:
        .byte "Screen cleared.",$0D,$0A,0

RECT_MSG:
        .byte "Rectangle command sent.",$0D,$0A,0
BOOT_MSG2:
        .byte "Booting BASIC...",$0D,$0A,0



 ; Interrupt Vectors
 
.org $FFFA
        .word 0          ; NMI
        .word RESET      ; RESET vector
        .word 0          ; IRQ/BRK


