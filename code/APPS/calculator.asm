.org $9000 ; PROGRAM ROM 1 IN CHIP

; Variables
num_a         .byte 0, 0, 0, 0  ; 32-bit number a (4 bytes)
num_b         .byte 0, 0, 0, 0  ; 32-bit number b (4 bytes)
result        .byte 0, 0, 0, 0  ; 32-bit result (4 bytes)

; Constants
add_operator  .byte 43          ; ASCII value of '+' (for addition)
string_input  .byte "10", 0     ; Example number string "10"
string_input_b .byte "20", 0    ; Example number string "20"

start:
    ; Load the first number (num_a) from the string "10" into num_a (32-bit)
    LDX #0                  ; Start at the first byte of string_input
    JSR string_to_num       ; Convert string_input to num_a

    ; Load the second number (num_b) from the string "20" into num_b (32-bit)
    LDX #0                  ; Start at the first byte of string_input_b
    JSR string_to_num       ; Convert string_input_b to num_b

addition:
    ;;;; Perform 32-bit addition - add all bytes ;;;;
    LDA num_a               ; Load the low byte of num_a
    CLC                     ; Clear the carry flag
    ADC num_b               ; Add the low byte of num_b
    STA result              ; Store the low byte of the result

    ; Add the next byte (second byte)
    LDA num_a + 1           ; Load the second byte of num_a
    ADC num_b + 1           ; Add the second byte of num_b (with carry)
    STA result + 1          ; Store the second byte of the result

    ; Add the third byte (third byte)
    LDA num_a + 2           ; Load the third byte of num_a
    ADC num_b + 2           ; Add the third byte of num_b (with carry)
    STA result + 2          ; Store the third byte of the result

    ; Add the fourth byte (fourth byte)
    LDA num_a + 3           ; Load the fourth byte of num_a
    ADC num_b + 3           ; Add the fourth byte of num_b (with carry)
    STA result + 3          ; Store the fourth byte of the result
    ;;;;;;;;
    JMP end_program         ; Jump to the end of the program
subtraction:
    rts

string_to_num:
    ; Convert a string of ASCII digits to a number (32-bit)
    ; Input: X = 0 (string start index), string_input points to string
    ; Output: num_a (32-bit number)

    LDA string_input, X     ; Load the ASCII digit from the string
    BEQ string_done         ; If we reach the null terminator (0), we're done

    ; Convert the ASCII digit to a numeric value (ASCII '0' = 0, '1' = 1, ..., '9' = 9)
    SEC                     ; Set the carry flag for multiplication
    SBC #48                 ; Subtract ASCII '0' (48) to get the actual number
    STA temp_value          ; Store the result in temp_value

    ; Multiply the current value by 10 (shift left by one decimal place)
    LDA num_a               ; Load current num_a
    ASL A                   ; Shift left by 1 bit (this is effectively *2)
    ASL A                   ; Shift left again (this is effectively *4)
    ASL A                   ; Shift left again (this is effectively *8)
    STA temp_mult           ; Store the multiplication result

    LDA temp_value          ; Load current digit
    ADC temp_mult           ; Add to the result after multiplying
    STA num_a               ; Store in num_a

    INX                     ; Increment string index
    JMP string_to_num       ; Repeat until string is fully processed

string_done:
    RTS                     ; Return from subroutine

end_program:
    RTS                     ; End of program
