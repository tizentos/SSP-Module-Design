module wslave (
    input wire  rst_i,
    input wire clk_i,
    inout wire [31:0]   dataBus,
    input wire [25:0]  adr_i,
    input wire [31:0]  dat_i,      //DAT_O()
    input wire  we_i,
    input wire  stb_i,
    input wire  cyc_i,
    input wire  tagn_i,

    output wire[31:0]  dat_o,
    output wire [25:0]  mem_adr_o,
    output wire  mem_r_o,
    output wire  mem_w_o,
    output wire  ack_o,
    output wire  tagn_o,

    output wire  ssp_sel_o,
    output wire  ssp_w_o
);


    reg mem_r_o_reg,mem_w_o_reg,ack_o_reg,tagn_o_reg;
    reg mem_r_o_reg_next, mem_w_o_reg_next, ack_o_reg_next, tagn_o_reg_next;

    reg [25:0] mem_adr_o_reg,mem_adr_o_reg_next;
    reg ssp_sel_o_reg,ssp_w_o_reg;
    reg ssp_sel_o_reg_next, ssp_w_o_reg_next;

    reg [2:0] slave_state,slave_state_next;
    reg [1:0] in_state,in_state_next;

    reg[31:0] dataBus_in,dataBus_out,dataBus_out_next,dat_o_reg,dat_o_reg_next;



    assign dataBus = (ssp_sel_o & (adr_i == 26'h0010000) ) ? dataBus_out: 32'bz;

    // assign dataBus = (we_i)? dat_i :32'hzz;
    assign dat_o = dat_o_reg;

    // assign dataBus_in = (1)? dataBus:'z;
    // assign dataBus = (1)? dataBus_out: 'z;

    assign mem_r_o = mem_r_o_reg;
    assign mem_w_o = mem_w_o_reg;
    assign mem_adr_o = mem_adr_o_reg;


    assign ack_o =ack_o_reg;
    assign tagn_o = tagn_o_reg;
    assign ssp_sel_o = ssp_sel_o_reg;
    assign ssp_w_o = ssp_w_o_reg;



    always @(posedge stb_i)begin
    if (rst_i) slave_state = {adr_i[16],adr_i[0],1'b1};
    end

    always @(posedge clk_i)begin
    if (~rst_i)begin
        ack_o_reg <= 0;
        tagn_o_reg <= 0;
        mem_r_o_reg <= 0;
        mem_w_o_reg <= 0;

        ssp_sel_o_reg <= 0;
        ssp_w_o_reg <= 0;  //check if this initialization works for your SSP

        //    slave_state <= 3'b000;
    end
    else begin
        ack_o_reg <=ack_o_reg_next;
        tagn_o_reg <= tagn_o_reg_next;
        mem_r_o_reg <= mem_r_o_reg_next;
        mem_w_o_reg <= mem_w_o_reg_next;

        mem_adr_o_reg <=mem_adr_o_reg_next;

        ssp_sel_o_reg <= ssp_sel_o_reg_next;
        ssp_w_o_reg <=ssp_w_o_reg_next; 

        slave_state <=slave_state_next;
        in_state <= in_state_next;


        dat_o_reg <= dat_o_reg_next;
        dataBus_out <= dataBus_out_next;
    end 
    end


    always @* begin
        ack_o_reg_next = ack_o_reg;
        tagn_o_reg_next = tagn_o_reg;
        mem_r_o_reg_next = mem_r_o_reg;
        mem_w_o_reg_next = mem_w_o_reg;

        ssp_sel_o_reg_next = ssp_sel_o_reg;
        ssp_w_o_reg_next =ssp_w_o_reg;

        dat_o_reg_next = dat_o_reg;
        dataBus_out_next = dataBus_out;


        casez (slave_state)
            3'b0?1:begin     //MEM state
                mem_adr_o_reg_next = adr_i;
                if (we_i)begin
                mem_r_o_reg_next = 0;
                mem_w_o_reg_next = 1; 
                end
                else begin
                    mem_r_o_reg_next = 1;
                    mem_w_o_reg_next = 0;
                end
                slave_state_next = 3'b000; //goto to ACK state
                in_state_next = 2'b00;
            end
            3'b101:begin  //WRITE/TX state
                //pwrite must be asserted
                mem_adr_o_reg_next = adr_i;
                if (we_i)begin
                    ssp_sel_o_reg_next = 1;
                    ssp_w_o_reg_next = we_i;

                    // dataBus = (we_i) ? dat_i: 32'hz;
                    dataBus_out_next = dat_i;
                end
                slave_state_next = 3'b000;
                in_state_next = 2'b10;
            end
            3'b111: begin  //READ from SSP state
                mem_adr_o_reg_next = adr_i;
                if (~we_i)begin
                 ssp_sel_o_reg_next = 1;
                 ssp_w_o_reg_next = we_i; 
                end
                slave_state_next = 3'b000;
                in_state_next =  2'b01; //in_state for reading from SSP
            end
            3'b000: begin //ACK state
                //you need another case or if statement to give the proper ack response
                // mem_adr_o_reg_next = adr_i;
                casex(in_state)
                    2'b00:begin   //coming from MEM operation
                        if (~mem_r_o_reg  & mem_w_o_reg) begin
                        //when we are wirting to mem.data
                        //this state won't occur, this feature is reserved 
                        in_state_next = 2'b11;
                        end
                        else if(mem_r_o_reg & ~mem_w_o_reg)begin
                            //we can read from mem.data
                            //send ack signal
                            //include data in databus
                            tagn_o_reg_next = 1;
                            ack_o_reg_next = 1;
                            // dat_o_reg_next = (mem_r_o_reg) ? dataBus: 32'bz;
                            dat_o_reg_next = dataBus;
                            in_state_next = 2'b11;
                        end 
                        else begin
                        //do nothing
                        in_state_next =2'b11; 
                        end

                        //reset eveything back to normal
                        mem_r_o_reg_next = 0;
                        mem_w_o_reg_next = 0;
                    end
                    2'b01:begin //ack If we are reading from SSP 
                        ssp_sel_o_reg_next = 0;  //set PSEL back to  zero

                        
                        tagn_o_reg_next = 1;
                        ack_o_reg_next = 1;

                        // dataBus_in = (we_i)? 32'bz:dataBus;
                        // dat_o_reg = {24'h0,dataBus_in[7:0]};  //pad with zero
                        dat_o_reg_next = dataBus;
                        in_state_next = 2'b11;
                    end  
                    2'b10: begin   //ack if we are writing to SSP
                        ssp_sel_o_reg_next = 0;  //set PSEL back to  zero
                        
                        ssp_w_o_reg_next = 0;
                        tagn_o_reg_next =1;
                        ack_o_reg_next=1;
                        in_state_next = 2'b11;

                        // dataBus = dat_i; 
                        end
                    2'b11: begin
                        ssp_sel_o_reg_next = 0; //just in case, deselect SSP

                        ack_o_reg_next = 0;
                        tagn_o_reg_next = 0;
                    end

                endcase

            end
        endcase
    end

endmodule


