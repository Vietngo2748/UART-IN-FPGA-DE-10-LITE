module UART
    #(parameter DBITS = 8,
                SB_TICK = 16,
                BR_LIMIT = 27,		//baudrate 115200
                BR_BITS = 5,	
                FIFO_EXP = 2)
    (
        input logic ckht,          // FPGA clock
        input logic rst,           // reset
		  input logic [DBITS-1:0] fifo_tx_data_in1,
		  input logic uart_rx,       // serial data in
		  //input logic fifo_tx_ena_wr,
		  output logic fifo_tx_full,
		  output logic [DBITS-1:0] fifo_tx_data_out,
		  output logic checkreadtx, checkempty,
		  output logic uart_tx,      // serial data out  
		  output logic [DBITS-1:0] fifo_rx_data_out, // data to Rx FIFO
		  output logic [DBITS-1:0] uart_to_fifo,
		  output logic [DBITS-1:0] datafromread,
		  output logic checkreadfromrx,
		  output logic fifo_rx_empty // no data to read from FIFO
	 );
	 logic s_tick;
	 logic fifo_tx_rd;
	 logic fifo_tx_empty;
	 logic fifo_rx_not_empty;
	 logic [DBITS-1:0] fifo_rx_data_in;
	 logic fifo_rx_ena_rd;
	 
	baud_rate_generator #(
        .M(BR_LIMIT),
        .N(BR_BITS)
    ) BAUD_RATE_GEN (
        .ckht(ckht),
        .rst(rst),
        .tick(s_tick)
    );
	
	uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .ckht(ckht),
            .rst(rst),
            .rx(uart_rx),
            .s_tick(s_tick),
            .rx_done_tick(fifo_rx_wr),
            .rx_data(fifo_rx_data_in)
         );
			
	 fifo_rx
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_RX_UNIT
         (
            .ckht(ckht),
            .rst(rst),
            .wr(fifo_rx_wr),
	        .rd(fifo_rx_ena_rd),
	        .wr_data(fifo_rx_data_in),
	        .rd_data(fifo_rx_data_out),
	        .empty(fifo_rx_empty)
	        //.full(rx_full)            
	      );
			
	read_fifo_rx READ_FIFO_RX
		 (
			.ckht(ckht),
			.rst(rst),
			.uart_rx_data(fifo_rx_data_out),
			.ena_rx(ckht),
			.uart_rx_empty(fifo_rx_empty),
			.data_rx(datafromread),
			.uart_rx_ena(fifo_rx_ena_rd)
		);

	uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .ckht(ckht),
            .rst(rst),
				.s_tick(s_tick),
            .tx_fifo_empty(fifo_tx_empty),
            .tx_data(fifo_tx_data_out),
            .tx_done_tick(fifo_tx_rd),
            .tx(uart_tx)
         );
			
	fifo_tx
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_TX_UNIT
         (
            .ckht(ckht),
            .rst(rst),
            .wr(not_empty_to_wr),
	        .rd(fifo_tx_rd),
	        .wr_data(datafromread),
	        .rd_data(fifo_tx_data_out),
	        .empty(fifo_tx_empty),
	        .full(fifo_tx_full)                // intentionally disconnected
	      );
	write_to_fifo write_to_fifo
			(
				.ckht(ckht),
				.rst(rst),
				.data_in(fifo_rx_not_empty),
				.data_out(not_empty_to_wr)
			);
	
assign checkreadtx = fifo_tx_rd;
assign checkempty = fifo_tx_empty;
assign uart_to_fifo = fifo_rx_data_in;
assign checkreadfromrx = fifo_rx_ena_rd;
assign fifo_rx_not_empty = ~fifo_rx_empty;

endmodule 