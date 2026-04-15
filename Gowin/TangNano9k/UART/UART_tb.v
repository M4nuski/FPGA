module test();
  reg clk = 0;
  reg uart_rx = 1;
  wire uart_tx;
  wire [5:0] led;
  reg btn = 1;

  uart #(8'd8) u(
    clk,
    uart_rx,
    uart_tx,
    led,
    btn
  );


 
always
    #1  clk = ~clk;

  initial begin
    $display("Starting UART RX");
    $monitor("LED Value %b", led);
    #10 uart_rx=0;
    #16 uart_rx=1;
    #16 uart_rx=0;
    #16 uart_rx=0;
    #16 uart_rx=0;
    #16 uart_rx=0;
    #16 uart_rx=1;
    #16 uart_rx=1;
    #16 uart_rx=0;
    #16 uart_rx=1;

    #32 // delay

    #16 uart_rx=0; // start
    #16 uart_rx=1; // MSB 7
    #16 uart_rx=0; // 6
    #16 uart_rx=1; // 5
    #16 uart_rx=0; // 4
    #16 uart_rx=1; // 3
    #16 uart_rx=0; // 2
    #16 uart_rx=1; // 1
    #16 uart_rx=0; // LSB 0
    #16 uart_rx=1; // stop

    #20 // delay

    #16 uart_rx=0; // start
    #16 uart_rx=0; // MSB 7
    #16 uart_rx=1; // 6
    #16 uart_rx=0; // 5
    #16 uart_rx=1; // 4
    #16 uart_rx=0; // 3
    #16 uart_rx=1; // 2
    #16 uart_rx=0; // 1
    #16 uart_rx=1; // LSB 0
    #16 uart_rx=1; // stop

    #5 // delay

    #16 uart_rx=0; // start
    #16 uart_rx=1; // MSB 7
    #16 uart_rx=0; // 6
    #16 uart_rx=1; // 5
    #16 uart_rx=0; // 4
    #16 uart_rx=1; // 3
    #16 uart_rx=0; // 2
    #16 uart_rx=1; // 1
    #16 uart_rx=0; // LSB 0
    #16 uart_rx=1; // stop

    #1000 $finish;
  end

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0,test);
  end

  endmodule