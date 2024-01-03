module uart_receiver #
  (
    parameter int DBITS = 8, // number of data bits in a data word
    parameter int SB_TICK = 16 // number of stop bit / oversampling ticks (1 stop bit)
  )
  (
    input logic ckht, // basys 3 FPGA
    input logic rst, // reset
    input logic rx, // receiver data line
    input logic s_tick, // sample tick from baud rate generator
    output logic rx_done_tick, // signal when a new data word is complete (received)
    output logic [DBITS-1:0] rx_data // data to FIFO
  );
  
  // State Machine States
  typedef enum logic [1:0] {
    idle = 2'b00,
    start = 2'b01,
    data = 2'b10,
    stop = 2'b11
  } state_type;

  // Registers
  state_type state_r, state_n; // state registers
  logic [3:0] s_r, s_n; // number of ticks received from baud rate generator
  logic [2:0] n_r, n_n; // number of bits received in data state
  logic [7:0] b_r, b_n; // reassembled data word

  // Register Logic
  always_ff @(posedge ckht, posedge rst)
    if (rst) begin
      state_r <= idle;
      s_r <= 0;
      n_r <= 0;
      b_r <= 0;
    end
    else begin
      state_r <= state_n;
      s_r <= s_n;
      n_r <= n_n;
      b_r <= b_n;
    end

  // State Machine Logic
  always_comb begin
    state_n = state_r;
    rx_done_tick = 1'b0;
    s_n = s_r;
    n_n = n_r;
    b_n = b_r;

    case (state_r)
      idle:
        if (~rx) begin // when data line goes LOW (start condition)
          state_n = start;
          s_n = 0;
        end
      start:
        if (s_tick)
          if (s_r == 7) begin
            state_n = data;
            s_n = 0;
            n_n = 0;
          end
          else
            s_n = s_r + 1;
      data:
        if (s_tick)
          if (s_r == 15) begin
            s_n = 0;
            b_n = {rx, b_r[7:1]};
            if (n_r == (DBITS - 1))
              state_n = stop;
            else
              n_n = n_r + 1;
          end
          else
            s_n = s_r + 1;
      stop:
        if (s_tick)
          if (s_r == (SB_TICK - 1)) begin
            state_n = idle;
            rx_done_tick = 1'b1;
          end
          else
            s_n = s_r + 1;
    endcase
  end

  // Output Logic
  assign rx_data = b_r;

endmodule
