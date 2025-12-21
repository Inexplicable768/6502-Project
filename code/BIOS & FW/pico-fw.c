// firmware of raspberi pi pico to control picovga via uart
// The pico will be used for receiving commands over UART to draw on the VGA display
// It supports basic commands to put pixels, draw rectangles, fill screen, scroll text, and clear screen.


#include "pico/stdlib.h"
#include "hardware/uart.h"
#include "picovga.h"
#include "FontIbm8x8.h"

#define UART_ID uart0
#define BAUD_RATE 115200
#define UART_RX_PIN 0

#define CMD_PUT_PIXEL   0x01
#define CMD_DRAW_RECT   0x02
#define CMD_FILL_SCREEN 0x03
#define CMD_SCROLL_UP   0x04
#define CMD_CLEAR_SCREEN 0x05

#define COLS  80
#define ROWS  50

// Text buffer for terminal
char screen[ROWS][COLS];
int cursor_x = 0;
int cursor_y = 0;

void scroll_up() {
    for (int y = 1; y < ROWS; y++)
        memcpy(screen[y - 1], screen[y], COLS);
    memset(screen[ROWS - 1], ' ', COLS);
    cursor_y = ROWS - 1;
}

void draw_text_screen() {
    for (int y = 0; y < ROWS; y++) {
        DrawText(&vga_canvas, screen[y], 0, y * 8, 0x07, &FontIbm8x8, 8, 1, 1);
    }
}

void put_char_vga(char c) {
    if (c == '\r') { cursor_x = 0; return; }
    if (c == '\n') { cursor_y++; cursor_x = 0;
        if (cursor_y >= ROWS) scroll_up(); return;
    }

    if (cursor_x >= COLS) { cursor_x = 0; cursor_y++; }
    if (cursor_y >= ROWS) scroll_up();

    screen[cursor_y][cursor_x++] = c;
    DrawText(&vga_canvas, &screen[cursor_y][cursor_x-1],
             (cursor_x - 1) * 8, cursor_y * 8, 0x07, &FontIbm8x8, 8, 1, 1);
}

// === Command interpreter ===
void handle_command(uint8_t cmd) {
    uint8_t x, y, w, h, color;

    switch (cmd) {
        case CMD_PUT_PIXEL:
            x = uart_getc(UART_ID);
            y = uart_getc(UART_ID);
            color = uart_getc(UART_ID);
            SetPix(&vga_canvas, x, y, color);
            break;

        case CMD_DRAW_RECT:
            x = uart_getc(UART_ID);
            y = uart_getc(UART_ID);
            w = uart_getc(UART_ID);
            h = uart_getc(UART_ID);
            color = uart_getc(UART_ID);
            FillRect(&vga_canvas, x, y, x + w, y + h, color);
            break;

        case CMD_FILL_SCREEN:
            color = uart_getc(UART_ID);
            FillRect(&vga_canvas, 0, 0, 639, 479, color);
            break;

        case CMD_SCROLL_UP:
            scroll_up();
            draw_text_screen();
            break;

        case CMD_CLEAR_SCREEN:
            FillRect(&vga_canvas, 0, 0, 639, 479, 0);
            memset(screen, ' ', sizeof(screen));
            cursor_x = cursor_y = 0;
            break;

        default: // DRAW TEXT
            // printable text
            put_char_vga((char)cmd);
            break;
    }
}
// VIDEO MODE IS 640x480 with 64 allowed colors
// TEXT MODE IS 80x50
int main() {
    stdio_init_all();
    uart_init(UART_ID, BAUD_RATE);
    gpio_set_function(UART_RX_PIN, GPIO_FUNC_UART);

    pico_vga_init();
    Video(0, VGARES_640x480, GF_MTEXT, NULL, NULL);
    FillRect(&vga_canvas, 0, 0, 639, 479, 0);

    while (1) {
        if (uart_is_readable(UART_ID)) {
            uint8_t b = uart_getc(UART_ID);
            handle_command(b);
        }
    }
}
