module serial_to_parallel
#(  
    parameter N = 8
)
(
    input wire SSPCLKIN, CLEAR_B,
    input wire SSPRXD, // serial data
    input wire SSPFSSIN,
    output reg [N-1:0] RxData,  // parallel data
    output reg receive_signal
);

reg [N-1:0] data_reg;
reg [N-1:0] count_reg, count_next;
reg [N-1:0] RxData_next;

reg rx_state_reg, rx_state_reg_next, start_rx,start_rx_next,receive_signal_next;
localparam  rx =1'b1, no_rx = 1'b0;


// save initial and next value in register
always @(posedge SSPCLKIN) begin
    if(~CLEAR_B) begin
        count_reg <= N-1;
        // data_reg <= 0;
        rx_state_reg <= no_rx;
        start_rx <= 0;

        receive_signal <= 0;
    end
    else begin
        count_reg <= count_next;
        rx_state_reg <= rx_state_reg_next; 
        RxData <=RxData_next;
        start_rx <=start_rx_next;

        receive_signal <= receive_signal_next;
    end
end


always @* begin
    count_next = count_reg;
    rx_state_reg_next =  rx_state_reg ; 
    RxData_next =  RxData;
    start_rx_next = start_rx;

    // receive_signal_next = receive_signal;
   receive_signal_next = 0;
    case (rx_state_reg)
        rx: begin
            if (start_rx & CLEAR_B)begin
                data_reg[count_reg] = SSPRXD;
                // $strobe("In rx state, when start_rx is 1");
                count_next = count_reg - 1;
                if (count_reg == 0)begin
                    count_next = N-1;
                    RxData_next = data_reg;

                    receive_signal_next = 1;

                    // $display(" time = %0d SSPRXD = %b SSPFSSIN = %b  Rx_data:%h",$time,SSPRXD, SSPFSSIN,RxData_next);
                    if (SSPFSSIN)begin
                        start_rx_next = 1;
                        rx_state_reg_next = rx;
                    end
                    else begin
                        start_rx_next = 0;
                        rx_state_reg_next = no_rx;
                    end
                end
            end
        end
        no_rx: begin
            if ((SSPFSSIN == 1) & CLEAR_B)begin
               count_next = N-1;
               start_rx_next = 1;
               rx_state_reg_next = rx; 
            end
        end
    endcase
end
endmodule