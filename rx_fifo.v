//PCLK is internal clock for reading
//SSPCLKIN is external clock for writing
//pwrite will be active low in for readinf RxFiFo(controlled by PSEL)
//PWDATA is RxData
//TxData is PRDATA
//SSPTXINTR is SSPRXINTR
//start_signal not useful for rx

module RxFIFO
    #(parameter data_width = 8,  // number of bits in each data
                address_width = 2,  // total addresses = 2^4
                max_data = 2**address_width // max_data = total_addresses
    )
    (
        input wire PCLK,SSPCLKIN,CLEAR_B,PSEL,
        input wire pwrite,write_cmd, // read and write command 
        input wire [data_width-1:0] RxData,  // write data to FIFO
        output wire [data_width-1:0] PRDATA,  // read data from FIFO
        output wire SSPRXINTR,  // no space to write in FIFO
        output wire start_signal // nothing to read from FIFO
    );

    reg [data_width-1:0] rx_mem [max_data-1:0];
    reg [address_width-1:0] front_reg, front_next; // pointer-front is for reading
    reg [address_width-1:0] rear_reg, rear_next; // pointer-rear is for writing
    reg full_reg, full_next;
    reg empty_reg, empty_next;


    assign SSPRXINTR = full_reg;
    assign start_signal = ~empty_reg;


    wire read_enable; // enable if queue is not full

    reg indicator;
    reg[address_width-1:0] temp_value;


    assign read_enable = ~pwrite & ~empty_reg; 


    assign PRDATA = (read_enable & PSEL) ? rx_mem[front_reg]: 8'bzz;

    always @(posedge PCLK) begin
        if (read_enable & PSEL)begin
            // PRDATA = rx_mem[front_reg];
            // $display("[IN READ]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
        end else begin
          if(~CLEAR_B) begin 
            // front_reg <= 0; 
          end
        end

        //if (PSEL & write_cmd) do something
    end
    always @(posedge PCLK)begin
        if (~CLEAR_B) begin
            empty_reg <= 1'b1;  // empty : nothing to read 
            front_reg <= 0;
            // full_reg <= 1'b0;  // not full : data can be written 
            // $display("In Clear[PCLK],  front_reg = %d",front_reg);

            empty_next <= 1'b1;
            front_next <= 0;

            indicator <= 0;
        end
        else begin
            front_reg <= front_next;
            empty_reg <= empty_next;

            indicator <= 0;

            // if (PSEL & write_cmd) rear_reg <=rear_next;
            // rear_reg <= rear_next;
            // full_reg <= full_next;
            // $display("In PCLK posedge[PCLK], front_next = %d front_reg = %d",front_next,front_reg);
            // $display("In PCLK posedge[PCLK], rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end
    end

    always @(posedge SSPCLKIN) begin
        // if queue_reg is full, then data will not be written
        if (write_cmd & ~full_reg)begin
            rx_mem[rear_reg] <= RxData; 
            //  $display("[In WRITE]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end else begin
        //    if (~CLEAR_B) rear_reg <= 0;
        end
    end

    // status of the queue and location of pointers i.e. front and rear
    always @(posedge SSPCLKIN) begin
        if (~CLEAR_B) begin
            full_reg <= 1'b0;  // not full : data can be written 
            rear_reg <= 0;

            full_next <= 0;
            rear_next <= 0;
            // $display("In Clear,  front_reg = %d",front_reg);
        end
        else begin
            rear_reg <= rear_next;
            full_reg <= full_next;
            // $display("In SSPCLKIN posedge, front_next = %d front_reg = %d",front_next,front_reg);
            // $display("In SSPCLKIN posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end
    end


    // always @(negedge indicator) begin
    //    rear_reg <= temp_value ;
    // end

    // read and write operation
    always @* begin
        // indicator = 0;
        // no operation for {write_cmd, read_cmd} = 00 
        // only read operation
        // front_next = front_reg;
        // rear_next = rear_reg;
        // full_next = full_reg;
        // empty_next = empty_reg;
        // $display("command = %b",pwrite,write_cmd);
        casex ({pwrite,write_cmd}) 
            (2'b00): begin // write = 0, read = 1
                // $display("[ONLY READ before]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                // $display("[ONLY READ before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                if(~empty_reg & PSEL) begin // not empty
                    full_next = 1'b0; // not full as data is read
                    front_next = front_reg + 1;
                    if (front_next  == rear_reg) begin empty_next = 1'b1; end
                    else begin empty_next = 1'b0; end
                end else  front_next = front_reg;
                // $display("[ONLY READ after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                // $display("[ONLY READ after]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
            // only write operation
            (2'b11): begin // write = 1, read = 0 
                // $display("[ONLY WRITE before ]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                //  $display("[ONLY WRITE before ]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                if(~full_reg) begin // not full
                    empty_next = 1'b0;
                    rear_next = rear_reg + 1;
                    if(rear_next == front_reg) begin full_next = 1'b1; end
                    else begin full_next = 1'b0; end  
                    end else rear_next = rear_reg;
                // $display("[ONLY WRITE after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                // $display("[ONLY WRITE after]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
            (2'b01): begin
                // $display("[BOTH before]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                // $display("[BOTH before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                //do read and write
                if(PSEL)begin
                    // full_next = 1'b0; // not full as data is read
                    // indicator = 1;
                    front_next = front_reg + 1;
                    // if (front_next  == rear_reg) begin empty_next = 1'b1; end
                    // empty_next = 1'b0;
                    rear_next = rear_reg + 1;
                    // temp_value = rear_next;  
                //    else begin empty_next = 1'b0; end
                end else begin
                    if(~full_reg) begin // not full
                        empty_next = 1'b0;
                        rear_next = rear_reg + 1;
                        // temp_value = rear_next;
                        // rear_reg = rear_next;
                        if(rear_next == front_reg) begin full_next = 1'b1; end
                        else begin full_next = 1'b0; end  
                        end else rear_next = rear_reg;
                end
                // $display("[BOTH after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                //  $display("[BOTH before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
        endcase
    end
endmodule