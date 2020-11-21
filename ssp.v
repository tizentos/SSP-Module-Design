module SSP
#(
    parameter N =8
)
(
    input wire PCLK,CLEAR_B,PSEL,pwrite,SSPCLKIN,
    input wire SSPFSSIN,SSPRXD,
    input wire [N-1:0] PWDATA,
    output wire [N-1:0] PRDATA,  
    output wire SSPCLKOUT,
    output wire SSPFSSOUT,                      
    output wire SSPTXD, // serial data
    output wire SSPOE_B, 
    output wire SSPTXINTR,  //frame control
    output wire SSPRXINTR
);

wire receive_signal;
wire start_signal;
wire [N-1:0] TxData,RxData;
wire rx_fifo_start_signal;


sspclkout_module(.PCLK(PCLK),.CLEAR_B(CLEAR_B),.SSPCLKOUT(SSPCLKOUT));


TxFIFO(.PCLK(PCLK),.SSPCLKOUT(SSPCLKOUT),.CLEAR_B(CLEAR_B),.PSEL(PSEL),
        .read_cmd(SSPFSSOUT),.pwrite(pwrite),.PWDATA(PWDATA),
        .TxData(TxData),.SSPTXINTR(SSPTXINTR),.start_signal(start_signal));


parallel_to_serial(.SSPCLKOUT(SSPCLKOUT), .CLEAR_B(CLEAR_B),
                        .TxData(TxData),.start_signal(start_signal),
                        .SSPTXD(SSPTXD),
                        .SSPOE_B(SSPOE_B),.SSPFSSOUT(SSPFSSOUT));


serial_to_parallel(.SSPCLKIN(SSPCLKOUT), .CLEAR_B(CLEAR_B),.SSPRXD(SSPTXD),
                   .SSPFSSIN(SSPFSSOUT),.RxData(RxData),
                   .receive_signal(receive_signal));

RxFIFO(.PCLK(PCLK),.SSPCLKIN(SSPCLKOUT),.CLEAR_B(CLEAR_B),.PSEL(PSEL),
        .pwrite(pwrite),.write_cmd(receive_signal),.RxData(RxData),
        .PRDATA(PRDATA),.SSPRXINTR(SSPRXINTR),.start_signal(rx_fifo_start_signal));

endmodule

