; NOTICE: this only works for the LCD without my vga card
; I still included this here as well


; LCD Control Pins
PORTA     = $00
PORTB     = $01       
LCD_D4    = $24      ; Data Pin D4
LCD_D5    = $25      ; Data Pin D5
LCD_D6    = $26      ; Data Pin D6
LCD_D7    = $27      ; Data Pin D7

PHASE:  .byte #$00   ; keep track of which message we are on in memory for pre-programmed booting process

; messages for the user

msg_0:  .byte "BIOS Starting", 0

.org $8000         ; Start address of program

Start:
    JSR InitLCD         ; Initialize LCD
    JSR PrintMessage    ; print to the LCD
    JSR PollInput       ; user input from buttons
    JMP Start           ; Loop forever
Interupt:               ; execute next program in ROM or read from disk
    RTS
; Initialize the LCD
InitLCD:
    LDA #$33           ; Function set: 8-bit mode
    JSR SendCommand
    LDA #$32           ; Function set: 4-bit mode
    JSR SendCommand
    LDA #$28           ; Function set: 2-line display, 5x7 font
    JSR SendCommand
    LDA #$0C           ; Display ON, Cursor OFF
    JSR SendCommand
    LDA #$06           ; Entry mode: Increment cursor
    JSR SendCommand
    LDA #$01           ; Clear display
    JSR SendCommand
    RTS

; Send a command to the LCD
SendCommand:
    LDX #$00           ; Clear register
    LDA LCD_CTRL
    AND #$FE           ; RS = 0 (command mode)
    STA LCD_CTRL
    LDA A
    JSR SendData
    RTS

; Send a data byte to the LCD
SendData:
    LDX #$04
    STX LCD_EN
    STX LCD_RS
    STX LCD_D4
    STX LCD_D5
    STX LCD_D6
    STX LCD_D7
    RTS

; Print message to LCD
PrintMessage:
    LDX PHASE
    JSR IncPhase
PrintLoop:
    LDA msg_0, X
    BEQ EndPrint
    JSR SendData
    INX
    JMP PrintLoop
EndPrint:
    RTS
