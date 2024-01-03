module read_fifo_rx(
	input logic ckht,
	input logic rst,
	input logic ena_rx,
	input logic uart_rx_empty,
	input logic [7:0] uart_rx_data,
	output logic uart_rx_ena,
	output logic [7:0] data_rx
);

logic [7:0] data_rx_r, data_rx_n;
logic uart_rx_ena_t;

always_ff @(posedge ckht, posedge rst)
    if (rst) 
        data_rx_r <= 0;
    else 
        data_rx_r <= data_rx_n;
		  
assign uart_rx_ena_t = ena_rx && ~uart_rx_empty;

always_comb begin
	data_rx_n = data_rx_r;
	if (uart_rx_ena_t) 
		data_rx_n = uart_rx_data;
end

assign data_rx = data_rx_r;
assign uart_rx_ena = uart_rx_ena_t;

endmodule 

