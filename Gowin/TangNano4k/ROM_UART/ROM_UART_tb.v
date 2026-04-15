module test();
    reg btn = 0;
    reg clk = 0;
    reg uart_rx = 1;
    wire uart_tx;
    top ROM_UART(
        btn,
        clk,
        uart_rx,
        uart_tx
    );

    always #1 clk = ~clk;

    initial begin
        $display("Starting UART RX");

        #100
        #100 btn=1;

        #5000

        #468 uart_rx=0; // start
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1; // stop

        #5000

        #468 uart_rx=0; // start
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=0;
        #468 uart_rx=1;
        #468 uart_rx=1; // stop

         #5000

          #5000

        $finish;
    end

    initial begin
        $dumpfile("ROM_UART.vcd");
        $dumpvars(0, test);
    end

endmodule