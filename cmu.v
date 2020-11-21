module cmu(
    input wire clk,
    input wire clear,
    input wire[1:0]  ssp_int_i,
    output wire  phi1,phi2,
    output wire  clk_o,
    output wire  clear_o
);
localparam phi1_count = 0;
localparam phi2_count = 2;

reg phi1_reg, phi2_reg;
reg [1:0] count_reg, count_reg_next;
reg state;   //free running state(1), hold state(0)

assign phi1 = phi1_reg;
assign phi2 = phi2_reg;
assign clear_o = clear;
assign clk_o = clk;

always @(ssp_int_i[1]) begin
   if (ssp_int_i[1] )state = 0; //go to hold state; 
   else if (~ssp_int_i[1]) state = 1; //go back to free running
end

always @(posedge clk) begin
    if (~clear)begin
        count_reg <= 0;
    end
    else begin
        count_reg <= count_reg_next;
    end
end

always @* begin
   count_reg_next = count_reg;

   case (state)
        1'b1:begin
           phi1_reg = (count_reg == phi1_count)? 1 : 0;
           phi2_reg = (count_reg == phi2_count)? 1 : 0; 

           count_reg_next = (count_reg == 3)? 0 : count_reg + 1;
        end
        1'b0:begin
            //hold two clocks
            phi1_reg = 0;
            phi2_reg = 0;
        end
   endcase  
end
endmodule