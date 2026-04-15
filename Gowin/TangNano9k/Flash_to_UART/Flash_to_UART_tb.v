module test();
  reg clk = 0;
  reg uart_rx = 1;
  wire uart_tx;
  wire [5:0] led;
  reg btn1 = 1;
  reg btn2 = 1;

    wire flashClk;
    wire flashMiso;
    wire flashMosi;
    wire flashCs;

wire [255:0] top_dataBuffer;

wire sr_S;
wire sr_R;
reg sr_Q = 0;

always @(negedge clk) begin
    if (sr_S == 1) begin
        sr_Q <= 1;
   
    end
    if (sr_R == 1) begin
        sr_Q <= 0;
    
    end
end


  UART #(8'd8, 23'd8) u(
    clk,
    uart_rx,
    uart_tx,
    led,
      btn1, btn2,

    top_dataBuffer,
    sr_Q, sr_R
  );


  flashReader #(32'd10) flash(
    clk,

    top_dataBuffer, // 32 bytes
    sr_Q, sr_S, // set to 1 to start reading data from address to buffer

    flashClk,
    flashMiso,
    flashMosi,
    flashCs
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
    
    btn1 = 0;
    #1000 
     btn1 = 1;
     #5000 
    $finish;
  end

  initial begin
    $dumpfile("Flash_to_UART.vcd");
    $dumpvars(0,test);
  end

  endmodule