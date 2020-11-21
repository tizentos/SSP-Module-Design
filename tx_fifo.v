module TxFIFO
    #(parameter data_width = 8,  // number of bits in each data
                address_width = 2,  // total addresses = 2^4
                max_data = 2**address_width // max_data = total_addresses
    )
    (
        input wire PCLK,SSPCLKOUT,CLEAR_B,PSEL,
        input wire pwrite,read_cmd, // read and write command 
        input wire [data_width-1:0] PWDATA,  // write data to FIFO
        output reg [data_width-1:0] TxData,  // read data from FIFO
        output wire SSPTXINTR,  // no space to write in FIFO
        output wire start_signal // nothing to read from FIFO
    );

    reg [data_width-1:0] tx_mem [max_data-1:0];
    reg [address_width-1:0] front_reg, front_next; // pointer-front is for reading
    reg [address_width-1:0] rear_reg, rear_next; // pointer-rear is for writing
    reg full_reg, full_next;
    reg empty_reg, empty_next;


    assign SSPTXINTR = full_reg;
    assign start_signal = ~empty_reg;

    wire write_enable; // enable if queue is not full

    assign write_enable = pwrite & ~full_reg; 


    always @(posedge SSPCLKOUT) begin
        if (read_cmd)begin
            TxData <= tx_mem[front_reg];
            // $display("[IN READ]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
        end else begin
          if(~CLEAR_B) begin 
            // front_reg <= 0; 
          end
        end
    end
    always @(posedge SSPCLKOUT)begin
        if (~CLEAR_B) begin
            empty_reg <= 1'b1;  // empty : nothing to read 
            front_reg <= 0;
            full_reg <= 1'b0;  // not full : data can be written 


            empty_next <= 1'b1;  // empty : nothing to read 
            front_next <= 2'b0;
            full_next <= 1'b0;
            // $display("In Clear[SSPCLKOUT],  front_reg = %d",front_reg);
        end
        else begin
            front_reg <= front_next;
            empty_reg <= empty_next;
            full_reg <= full_next;
            // $display("In PCLK posedge[SSPCLKOUT], front_next = %d front_reg = %d",front_next,front_reg);
            // $display("In PCLK posedge[SSPCLKOUT], rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end
    end

    always @(posedge PCLK) begin
        // if queue_reg is full, then data will not be written
        if (write_enable & PSEL)begin
            tx_mem[rear_reg] <= PWDATA; 
            //  $display("[In WRITE]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end else begin
        //    if (~CLEAR_B) rear_reg <= 0;
        end
    end

    // status of the queue and location of pointers i.e. front and rear
    always @(posedge PCLK) begin
        if (~CLEAR_B) begin
   
            rear_reg <= 0;
            rear_next <= 0;
            // $display("In Clear,  front_reg = %d",front_reg);
        end
        else begin
            rear_reg <= rear_next;

            // $display("In PCLK posedge, front_next = %d front_reg = %d",front_next,front_reg);
            // $display("In PCLK posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
        end
    end

    // read and write operation
    always @* begin
       
        // no operation for {write_cmd, read_cmd} = 00 
        // only read operation
        // front_next = front_reg;
        // rear_next = rear_reg;
        // full_next = full_reg;
        // empty_next = empty_reg;
        $display("command = %b",pwrite,read_cmd);
        casex ({pwrite,read_cmd}) 
            (2'b01): begin // write = 0, read = 1
                $display("[ONLY READ before]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                $display("[ONLY READ before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                if(~empty_reg) begin // not empty
                    full_next = 1'b0; // not full as data is read
                    front_next = front_reg + 1;
                    if (front_next  == rear_reg) begin empty_next = 1'b1; end
                    else begin empty_next = 1'b0; end
                end else  front_next = front_reg;
                $display("[ONLY READ after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                $display("[ONLY READ after]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
            // only write operation
            (2'b10): begin // write = 1, read = 0 
                $display("[ONLY WRITE before ]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                 $display("[ONLY WRITE before ]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                if(~full_reg & PSEL) begin // not full
                    empty_next = 1'b0;
                    rear_next = rear_reg + 1;
                    if(rear_next == front_reg) begin full_next = 1'b1; end
                    else begin full_next = 1'b0; end  
                    end else rear_next = rear_reg;
                $display("[ONLY WRITE after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                $display("[ONLY WRITE after]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
            (2'b11): begin
                $display("[BOTH before]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                $display("[BOTH before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
                //do read and write
                if(~empty_reg)begin
                    full_next = 1'b0; // not full as data is read
                    front_next = front_reg + 1;
                    if (front_next  == rear_reg) begin empty_next = 1'b1; end
                   else begin empty_next = 1'b0; end
                end else  front_next = front_reg;
                if( PSEL) begin // not full
                    empty_next = 1'b0;
                    rear_next = rear_reg + 1;
                    if(rear_next == front_reg) begin full_next = 1'b1; end
                    else begin full_next = 1'b0; end  
                    end else rear_next = rear_reg;
                $display("[BOTH after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
                 $display("[BOTH before]In always posedge, rear_next = %d rear_reg = %d",rear_next,rear_reg);
            end
        //     default: begin
        //         $display("[DEFAULT before]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
        //         front_next = front_reg;
        //         rear_next = rear_reg;
        //         full_next = full_reg;
        //         empty_next = empty_reg;
        //         $display("[DEFAULT after]In always posedge, front_next = %d front_reg = %d",front_next,front_reg);
        //  end
        endcase
    end
endmodule

