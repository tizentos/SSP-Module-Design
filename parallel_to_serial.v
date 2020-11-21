module parallel_to_serial
#(  
    parameter N = 8
)
(
    input wire SSPCLKOUT, CLEAR_B,
    input wire [N-1:0] TxData, // parallel data
    input wire start_signal,                        
    output reg SSPTXD, // serial data
    output reg SSPOE_B, 
    output wire SSPFSSOUT  //frame control
);

reg [N-1:0] data_reg, data_next;
reg [N-1:0] count_reg, count_next;

reg SSPOE_B_next;
reg SSPFSSOUT_internal,SSPOE_B_internal;

assign SSPFSSOUT = SSPFSSOUT_internal;
// assign SSPOE_B = SSPOE_B_internal;

//new implmentation
localparam  tx =2'b01, no_tx = 2'b00, bf_tx=2'b10;
reg [1:0] tx_state_reg, tx_state_next;
reg finish_tx,tx_command;
reg finish_tx_next;


// save initial and next value in register
always @(posedge SSPCLKOUT) begin
    if(~CLEAR_B) begin
        count_reg <= N-1;
        data_reg <= 0;
        //new implmentation
        tx_state_reg <= no_tx;
        tx_command <= 1'b0;
        finish_tx <= 1'b0;

        // SSPTXD = 0;
        // SSPFSSOUT = 0;
        // SSPOE_B = 1'b1;
    end
    else begin
        count_reg <= count_next;
        
        data_reg <= data_next;
        tx_state_reg <= tx_state_next;
        finish_tx <=finish_tx_next;
    end
end

always @(negedge SSPCLKOUT)
    if (~CLEAR_B) SSPOE_B = 1'b1;
    else SSPOE_B = SSPOE_B_next;

always @* begin
    case (tx_state_reg)
          tx:begin
            if (finish_tx & CLEAR_B) begin 
                tx_state_next = no_tx;
                tx_command = 1'b0;
                SSPOE_B_next = 1'b1;
                // if(start_signal)begin 
                //     SSPFSSOUT = 1'b1; 
                //     tx_state_next = tx;
                //     tx_command = 1'b1;
                //     finish_tx_next = 1'b0;
                //     count_next = N-1;
                //     SSPOE_B_next = 1'b0;
                // end
            end
            SSPFSSOUT_internal = 1'b0;
            tx_command = 1'b1;

            SSPTXD = data_next[count_reg];
            count_next = count_reg - 1;
            if (count_reg == 0) begin
                count_next = N-1;
                finish_tx_next = 1'b1;
                tx_command = 1'b0;
                tx_state_next = no_tx;
                if(start_signal & CLEAR_B)begin 
                    SSPFSSOUT_internal = 1'b1; 
                    tx_state_next = tx;
                    tx_command = 1'b1;
                    finish_tx_next = 1'b0;
                    count_next = N-1;
                    SSPOE_B_next = 1'b0;
                    data_next = TxData;
                end
            end else begin
                data_next = TxData;
            end
           end
          no_tx: 
            begin
            // SSPOE_B_next = 1'b1;
            // SSPFSSOUT = 1'b0;
            // SSPTXD = 0;
                //   tx_command = 1'b0;
     
            // finish_tx_next = 1'b0;
            if (start_signal & CLEAR_B) begin
                count_next = count_reg; 
                tx_state_next = tx;
                tx_command = 1'b1;
                SSPOE_B_next = 1'b0;
                SSPFSSOUT_internal = 1'b1;
                data_next = TxData;
                data_reg = TxData;
            end
            else begin
                count_next = count_reg; 
                tx_state_next = no_tx;
                tx_command = 1'b0;
                SSPOE_B_next = 1'b1;
                SSPFSSOUT_internal = 1'b0;
                finish_tx_next = 1'b0;
            end
            end
        //   bf_tx:begin
        //     //   SSPFSSOUT = 1;
        //       tx_command = 1;
        //       finish_tx_next = 1'b0;
        //       SSPOE_B_next = 1'b0;
        //       SSPFSSOUT = 1'b0;
        //       tx_state_next = tx;
        //   end
    endcase
end

endmodule
