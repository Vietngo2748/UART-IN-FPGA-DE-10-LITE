module uart_transmitter  
    #(
        parameter DBITS = 8,
                  SB_TICK = 16
    )
    (
        input logic ckht,                   // basys 3 FPGA
        input logic rst,                    // reset
        input logic s_tick,                 // from baud rate generator
        input logic tx_fifo_empty,          // begin data transmission (FIFO NOT empty)
        input logic [DBITS-1:0] tx_data,    // data word from FIFO
        output reg tx_done_tick,            // end of transmission
        output logic tx                     // transmitter data line
    );
    
    // State Machine States
    typedef enum logic [1:0] {
        idle  = 2'b00,
        start = 2'b01,
        data  = 2'b10,
        stop  = 2'b11
    } state_type;

    // Registers                    
    state_type state_r, state_n;          // state registers
    logic [3:0] s_r, s_n;                // number of ticks received from baud rate generator
    logic [2:0] n_r, n_n;                // number of bits transmitted in data state
    logic [DBITS-1:0] b_r, b_n;          // assembled data word to transmit serially
    logic tx_r, tx_n;                    // data filter for potential glitches
    
    // Register Logic
    always_ff @(posedge ckht, posedge rst)
        if (rst) begin
            state_r <= idle;
            s_r <= 4'b0;
            n_r <= 3'b0;
            b_r <= 8'b0;
            tx_r <= 1'b1;
        end else begin
            state_r <= state_n;
            s_r <= s_n;
            n_r <= n_n;
            b_r <= b_n;
            tx_r <= tx_n;
        end
    
    // State Machine Logic
    always_comb begin
        state_n = state_r;
        tx_done_tick = 1'b0;
        s_n = s_r;
        n_n = n_r;
        b_n = b_r;
        tx_n = tx_r;
        
        case (state_r)
            idle: begin                     // no data in FIFO
                tx_n = 1'b1;               // transmit idle
                if (~tx_fifo_empty) begin   // when FIFO is NOT empty
                    state_n = start;
                    s_n = 4'b0;
                    b_n = tx_data;
                end
            end
            
            start: begin
                tx_n = 1'b0;               // start bit
                if (s_tick)
                    if (s_r == 15) begin
                        state_n = data;
                        s_n = 4'b0;
                        n_n = 3'b0;
                    end else
                        s_n = s_r + 1;
            end
            
            data: begin
                tx_n = b_r[0];
                if (s_tick)
                    if (s_r == 15) begin
                        s_n = 4'b0;
                        b_n = {1'b0, b_r[7:1]};
                        if (n_r == (DBITS - 1))
                            state_n = stop;
                        else
                            n_n = n_r + 1;
                    end else
                        s_n = s_r + 1;
            end
            
            stop: begin
                tx_n = 1'b1;               // back to idle
                if (s_tick)
                    if (s_r == (SB_TICK - 1)) begin
                        state_n = idle;
                        tx_done_tick = 1'b1;
                    end else
                        s_n = s_r + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_r;
 
endmodule
