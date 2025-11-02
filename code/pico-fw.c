while (true) {
    if (uart_is_readable(uart0)) {
        uint8_t cmd = uart_getc(uart0);
        switch(cmd) {
            case 0x01:  // Print char
                while (!uart_is_readable(uart0)) {}
                char c = uart_getc(uart0);
                draw_char(c);
                break;

            case 0x02:  // Draw pixel
                while (uart_is_readable(uart0) < 3) {}
                uint8_t x = uart_getc(uart0);
                uint8_t y = uart_getc(uart0);
                uint8_t color = uart_getc(uart0);
                draw_pixel(x, y, color);
                break;
            case 0x03:
                clear_screen();
                break;
        }
    }
}
