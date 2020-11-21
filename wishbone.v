module wishbone(
    input wire clk,clear_i,ssp_clear,

    //input to wishbone master
    input wire [25:0]   i_addressBus_master,
    inout wire [31:0]   i_dataBus_master,
    inout wire [31:0]   i_dataBus_slave,
    output wire[7:0] pr_data_temp,
    input wire  i_memoryRead,
    input wire  i_memoryWrite,
    input wire  i_mwr_arm,
    input wire  i_mem_req,

    //ssp
    input wire SSPCLKIN,
    input wire SSPRXD,
    input wire SSPFSSIN,

    output wire phi1,
    output wire phi2,
    output wire clear_o,
    output wire[25:0] mem_adr_o,
    output wire mem_r_o,
    output wire mem_w_o,
    //

    output wire SSPCLKOUT,
    output wire SSPFSSOUT,
    output wire SSPTXD,
    output wire SSPOE_B,
    output wire ssp_sel_o
);

    //cmu pinout
    wire clk_o;
    wire SSPTXINTR,SSPRXINTR;



    //wishbone master pinout
    wire [31:0] dat_o_master;
    wire[25:0] adr_o_master;
    wire we_o,stb_o,cyc_o,tagn_o_master;




    //wishbone slave pinout
    // wire ssp_sel_o;
    wire ssp_w_o;
    wire[31:0] dat_o_slave;
    wire ack_o_slave,tagn_o_slave;


    // wire[31:0] ssp_databus; //for reading from ssp
    
    // wire[31:0] pr_data_temp_full;

    // localparam[23:0] zero_pad = 24'b0;
    // assign pr_data_temp_full ={zero_pad,pr_data_temp};

    // assign ssp_databus = (adr_o_master == 26'h0010001) ? pr_data_temp_full : 32'bz;
    
    // assign i_dataBus_slave = (ssp_w_o) ? i_dataBus_slave : ssp_databus;


    // assign i_dataBus_master = (we_o) ? i_dataBus_master : 32'bz; 
    



    cmu(.clk(clk),.clear(clear_i),.ssp_int_i({SSPTXINTR,SSPRXINTR}),
            .phi1(phi1),.phi2(phi2),.clk_o(clk_o),
            .clear_o(clear_o));


    SSP(.PCLK(clk_o), .CLEAR_B(ssp_clear),.PSEL(ssp_sel_o),.pwrite(ssp_w_o),.SSPCLKIN(SSPCLKIN),
        .SSPFSSIN(SSPFSSIN),.SSPRXD(SSPRXD),.PWDATA(i_dataBus_slave[7:0]),.PRDATA(pr_data_temp),
        .SSPCLKOUT(SSPCLKOUT),.SSPFSSOUT(SSPFSSOUT),.SSPTXD(SSPTXD),.SSPOE_B(SSPOE_B),
        .SSPTXINTR(SSPTXINTR),.SSPRXINTR(SSPRXINTR)
        );

    wmaster(.rst_i(clear_o),.clk_i(clk_o),.addressBus(i_addressBus_master),.dataBus(i_dataBus_master),
            .memoryRead(i_memoryRead),.memoryWrite(i_memoryWrite),.mwr_arm(i_mwr_arm),.mem_req(i_mem_req),
            .dat_i(dat_o_slave),.ack_i(ack_o_slave),.tagn_i(tagn_o_slave), .adr_o(adr_o_master),.dat_o(dat_o_master),
            .we_o(we_o),.stb_o(stb_o),.cyc_o(cyc_o),.tagn_o(tagn_o_master)
    );


    wslave(.rst_i(clear_o),.clk_i(clk_o),.dataBus(i_dataBus_slave),.adr_i(adr_o_master),.dat_i(dat_o_master),.we_i(we_o),
            .stb_i(stb_o),.cyc_i(cyc_o),.tagn_i(tagn_o_master),.dat_o(dat_o_slave),.mem_adr_o(mem_adr_o),.mem_r_o(mem_r_o),
            .mem_w_o(mem_w_o),.ack_o(ack_o_slave),.tagn_o(tagn_o_slave),.ssp_sel_o(ssp_sel_o),.ssp_w_o(ssp_w_o)
    );



endmodule