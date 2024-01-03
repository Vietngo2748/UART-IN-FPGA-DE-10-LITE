module fifo_tx 
    #(
        parameter DATA_SIZE = 8,
                  ADDR_SPACE_EXP = 2 
    )
    (
        input logic ckht,           // FPGA clock
        input logic rst,            // reset button
        input logic wr,             // signal start writing to FIFO
        input logic rd,             // signal start reading from FIFO
        input logic [DATA_SIZE-1:0] wr_data,   // data word into FIFO
        output logic [DATA_SIZE-1:0] rd_data,  // data word out of FIFO
        output logic empty,                  // FIFO is empty (no read)
        //output logic [1:0] wr_op1,
        output logic full                    // FIFO is full (no write)
    );

    // signal declaration
    logic [DATA_SIZE-1:0] array_r [2**ADDR_SPACE_EXP-1:0];		// memory array register
    logic [ADDR_SPACE_EXP-1:0] wr_ptr_r, wr_ptr_n, wr_ptr_s;
    logic [ADDR_SPACE_EXP-1:0] rd_ptr_r, rd_ptr_n, rd_ptr_s;
    logic full_r, empty_r, full_n, empty_n;
    logic wr_en;
    logic [1:0] wr_op;

    // register file (memory) write operation
    always_ff @(posedge ckht,posedge rst)
		if(rst)
			array_r[wr_ptr_r] <= 0;
      else if(wr_en)
            array_r[wr_ptr_r] <= wr_data;

    // register file (memory) read operation
    assign rd_data = array_r[rd_ptr_r];

    // only allow write operation when FIFO is NOT full
    assign wr_en = wr & ~full_r;

    // FIFO control logic
    // register logic
    always_ff @(posedge ckht, posedge rst)
        if (rst) begin
            wr_ptr_r <= 0;
            rd_ptr_r <= 0;
            full_r <= 1'b0;
            empty_r <= 1'b1; // FIFO is empty after reset
        end else begin
            wr_ptr_r <= wr_ptr_n;
            rd_ptr_r <= rd_ptr_n;
            full_r <= full_n;
            empty_r <= empty_n;
        end

    // next state logic for read and write address pointers
    always_comb begin
        // successive pointer values
        wr_ptr_s = wr_ptr_r + 1;
        rd_ptr_s = rd_ptr_r + 1;
        wr_op = {wr, rd};

        // default: keep old values
        wr_ptr_n = wr_ptr_r;
        rd_ptr_n = rd_ptr_r;
        full_n = full_r;
        empty_n = empty_r;

        // Button press logic
        case (wr_op) // check both buttons
            // 2'b00: neither buttons pressed, do nothing
            2'b01: // read button pressed?
                if (~empty_r) begin // FIFO not empty
                    rd_ptr_n = rd_ptr_s;
                    full_n = 1'b0; // after read, FIFO not full anymore
                    if (rd_ptr_s == wr_ptr_r)
                        empty_n = 1'b1;
                end
            2'b10: // write button pressed?
                if (~full_r) begin // FIFO not full
                    wr_ptr_n = wr_ptr_s;
                    empty_n = 1'b0; // after write, FIFO not empty anymore
                    if (wr_ptr_s == rd_ptr_r)
                        full_n = 1'b1;
                end
            2'b11: begin // write and read
                wr_ptr_n = wr_ptr_s;
                rd_ptr_n = rd_ptr_s;
            end
        endcase
    end

    // output
    assign full = full_r;
    assign empty = empty_r;

endmodule
