
module top (
    input wire clk,     // 47
    input wire uart_rx, // 40
    output wire uart_tx // 44
);

reg reset = 1;
reg [3:0] seq = 0; //reset
reg [31:0] rxData = 32'h40414243;
wire axi_inData_available;
reg axi_inData_readyToRead = 0;
wire [7:0] inData;
reg [7:0] outData;
wire axi_outData_readyToRead;
reg axi_outData_available = 0;

always @(negedge clk) begin
    case (seq) 
        0: begin
            reset <= 0;
            seq <= 1;
        end

        1: if (axi_outData_readyToRead) begin
            axi_outData_available <= 1;
            if (axi_outData_readyToRead & axi_outData_available) begin
                outData <= rxData[7:0];
                seq <= 2;
                axi_outData_available <= 0;  
            end
        end   
       
        2: begin    
            axi_inData_readyToRead <= 1;
            if (axi_inData_available & axi_inData_readyToRead) begin
                rxData[7:0] <= inData;
                axi_inData_readyToRead <= 0;
                seq <= 3;
            end
        end
        3: seq <= 1;
    endcase
end


UART uart(
    ~reset,
    clk,

    uart_rx,
    axi_inData_available,
    axi_inData_readyToRead,
    inData,

    uart_tx,
    axi_outData_readyToRead,
    axi_outData_available,
    outData
);


endmodule