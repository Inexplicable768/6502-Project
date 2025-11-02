;==================================================
;  SuperBIOS 6502  (for Ben Eater + Pi Pico VGA)
;  Copyright (c) 2025 Alex Hauptman - Gamma Software
;==================================================

; MEMORY MAP
; $0000-$00FF  Zero page
; $0100-$01FF  Stack Memory
; $0200-$7FFF  RAM
; $8000-$BFFF  ROM (BIOS / system)
; $C000-$FFFF  ROM / vectors

.org $8000

; Serial interface chip registers
ACIA_DATA   = $6000
ACIA_STATUS = $6001
ACIA_CMD    = $6002
ACIA_CTRL   = $6003

; Reset vector routine
 
RESET:
init_videocard:
        sei                     ; disable interrupts
        cld                     ; clear decimal mode
        ldx #$FF
        txs                     ; init stack pointer

        lda #$00
        sta ACIA_CMD            ; reset ACIA
        lda #%00011111          ; 115200 baud, 8N1, no parity
        sta ACIA_CTRL

        jsr print_hello         ; show BIOS banner
        jmp main_loop           ; go wait for commands

 
; Print HELLO banner
 
print_hello:
        ldx #0
.print_loop:
        lda HELLO_MSG,x
        beq .done
        jsr put_char
        inx
        bne .print_loop
.done:
        jsr new_line
        rts

 
; Print new line
 
new_line:
        lda #$0D
        jsr put_char
        lda #$0A
        jsr put_char
        rts

 
; Send character to ACIA / VGA serial output
 
put_char:
        pha
.wait_tx:
        lda ACIA_STATUS
        and #%00010000          ; transmitter ready?
        beq .wait_tx
        pla
        sta ACIA_DATA
        rts

 
; Send string (address in $00/$01)
 
print_string:
        ldy #0
.nextchar:
        lda ($00),y
        beq .done
        jsr put_char
        iny
        bne .nextchar
.done:
        rts

 
; Simple VGA command stubs (handled by Pico)
 
put_pixel:      ; A=Xcoord_hi, X=Ycoord_hi, Y=color
        ; send VGA draw pixel command to Pico
        ; e.g. prefix byte $01 followed by params
        lda #$01
        jsr send_command
        rts

draw_rect:      ; rectangle drawing stub
        lda #$02
        jsr send_command
        rts

fill_screen:    ; fill color (A=color)
        lda #$03
        jsr send_command
        rts

 
; Send general command byte to Pico
 
send_command:
        pha
.wait_tx2:
        lda ACIA_STATUS
        and #%00010000
        beq .wait_tx2
        pla
        sta ACIA_DATA
        rts

 
; Main idle loop — waits for commands or demo
 
main_loop:
        jmp main_loop

 
; DATA SECTION
 
HELLO_MSG:
        .byte $0D, $0A
        .byte "-= Loaded SuperBIOS Version 1.0 =-",0
BOOT_MSG:
        .byte "1. Place a bootable 3.5 inch floppy in drive A",0
        .byte "2. Exit to BASIC",0
 
; INTERRUPT VECTORS

        .org $FFFA
        .word 0          ; NMI
        .word RESET      ; RESET vector
        .word 0          ; IRQ/BRK
