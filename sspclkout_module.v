module sspclkout_module
(
    input wire PCLK,CLEAR_B, 
    output wire SSPCLKOUT
);

reg state, state_next;
localparam tick = 1'b1;

reg SSPCLKOUT_internal;

assign SSPCLKOUT = SSPCLKOUT_internal;
always @(posedge PCLK)
begin
    // if (~CLEAR_B) SSPCLKOUT <= 0;

    state = state_next;
end

always @(posedge PCLK) begin
    case (state)
        tick:begin
            SSPCLKOUT_internal <= ~SSPCLKOUT_internal;
        end
        default: begin 
            // count_next = 0;
            state_next = tick;
            SSPCLKOUT_internal = 0; 
        end
    endcase 
end   

endmodule