module wmaster (
    input wire  rst_i,
    input wire  clk_i,
    input wire [25:0]   addressBus,
    inout wire [31:0]   dataBus,
    input wire  memoryRead,
    input wire  memoryWrite,
    input wire  mwr_arm,
    input wire mem_req,
    input wire[31:0]  dat_i,
    input wire  ack_i,
    input wire  tagn_i,


    output wire [25:0]  adr_o,
    output wire [31:0]  dat_o,      //DAT_O()
    output wire  we_o,
    output wire  stb_o,
    output wire  cyc_o,
    output wire  tagn_o
);


    reg stb_o_reg,cyc_o_reg,tagn_o_reg,we_o_reg;
    reg stb_o_reg_next,cyc_o_reg_next,tagn_o_reg_next,we_o_reg_next;



    reg [25:0] adr_o_reg,adr_o_reg_next;
    reg[31:0] dataBus_in,dataBus_out, dataBus_out_next,dat_o_reg,dat_o_reg_next;



    //specify master states[IDLE,MEM_STATE, SSP_STATE]
    reg [1:0] master_state,master_state_next;


    //output of master wish bone
    assign stb_o = stb_o_reg;
    assign cyc_o = cyc_o_reg;
    assign tagn_o = tagn_o_reg;
    assign we_o = we_o_reg;

    // assign dataBus_in = (1)? dataBus : 'z;
    // assign dataBus = (1)? dataBus_out : 'z; 
    // assign dataBus_out = ()dataBus_out_reg;

    assign  dat_o = (memoryWrite) ? dataBus : 32'bz;

    assign  dataBus =  (we_o) ? 32'bz: dataBus_out;

    // assign  dataBus_in = (memoryWrite)? dataBus : 32'hz;

    //
    assign adr_o = adr_o_reg;


    always @(posedge clk_i)begin
    if (~rst_i)begin
        //initialize master wishbone here
        stb_o_reg <= 0;
        cyc_o_reg <= 0;

        master_state <= 0;  //IDLE state
    end 
    else begin
        stb_o_reg <=stb_o_reg_next;
        cyc_o_reg <=cyc_o_reg_next;
        tagn_o_reg <=tagn_o_reg_next;
        we_o_reg <=we_o_reg_next;

        master_state <=master_state_next;
        adr_o_reg <= adr_o_reg_next;

        dat_o_reg <= dat_o_reg_next;
        dataBus_out <= dataBus_out_next;
    end
    end

    always @* begin
    stb_o_reg_next = stb_o_reg;
    cyc_o_reg_next = cyc_o;

    tagn_o_reg_next = tagn_o_reg;
    we_o_reg_next= we_o_reg; 

    dat_o_reg_next = dat_o_reg;
    dataBus_out_next = dataBus_out;


    casex (master_state)
        2'b00: begin //do nothing here for now( maybe IDLE state)
        //continously 
                if ({memoryRead,memoryWrite} == 2'b10) begin
                    adr_o_reg_next = addressBus;
                    tagn_o_reg_next = 1'b1;
                    we_o_reg_next = 1'b0;
                    //no select signal for this wishbone
                    cyc_o_reg_next = 1'b1; //indicate start of the cycle
                    stb_o_reg_next = 1'b1; // now we've qualified the address and read command
                    
                    master_state_next = 2'b10;
                end
                else if ({memoryRead,memoryWrite} == 2'b01) begin
                    //intialize the write cycle
                    adr_o_reg_next = addressBus;
                    tagn_o_reg_next = 1'b1;
                    we_o_reg_next = 1'b1;


                    //no select signal for this wishbone
                    cyc_o_reg_next = 1'b1;
                    stb_o_reg_next = 1'b1;
                
                    // dat_o_reg_next = (memoryWrite) ? dataBus : 32'hz;
                    // dat_o_reg_next = dataBus;
                    master_state_next = 2'b01;
                end
        end
        2'b10:begin
        //intialize the read cycle here
                // adr_o_reg_next = addressBus;
                // tagn_o_reg_next = 1'b1;
                // we_o_reg_next = 1'b0;
                // //no select signal for this wishbone
                // cyc_o_reg_next = 1'b1; //indicate start of the cycle
                // stb_o_reg_next = 1'b1; // now we've qualified the address and read command
               if (ack_i) begin
                    stb_o_reg_next = 0;
                    cyc_o_reg_next = 0;
                    tagn_o_reg_next = 0; //for now we set tag back to zero

                    // dataBus =  (we_o_reg) ? 32'hz:dat_i;
                    dataBus_out_next = dat_i;
                    master_state_next = 2'b00; //wait for another program
                end
        end
        2'b01: begin
                //    //intialize the write cycle
                //         adr_o_reg_next = addressBus;
                //         tagn_o_reg_next = 1'b1;
                //         we_o_reg_next = 1'b1;

                //         //no select signal for this wishbone
                //         cyc_o_reg_next = 1'b1;
                //         stb_o_reg_next = 1'b1;
                if (ack_i) begin
                    // dataBus = dat_i;
                    master_state_next = 2'b00; //wait or process another program 
                    //reset comm signals
                    we_o_reg_next = 0;
                    stb_o_reg_next = 0;
                    cyc_o_reg_next = 0;
                    tagn_o_reg_next = 0; //for now we set tag back to zero
                end
        end
        // 2'b11: begin   //WAIT state
        //         //lets use this as the waiting state
        //         // we only have to monitor ack_i signal
        //         //we don't need to monitor tagn_i for  now
        //         if (ack_i) begin //check for ack signal from the slave
        //                 //start latching data
        //                 if (we_o_reg) begin 
        //                     dataBus = dat_i;
        //                     we_o_reg_next = 0; //just take it back to normal state(not writing)
        //                 end 
        //                 stb_o_reg_next = 0;
        //                 cyc_o_reg_next = 0;

        //                 tagn_o_reg_next = 0 //for now we set tag back to zero

        //                 //then go back to idle state
        //                 master_state_next = 1'b00;
        //         end
        // end
    endcase 
end

endmodule