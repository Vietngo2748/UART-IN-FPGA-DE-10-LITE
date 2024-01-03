module baud_rate_generator #
  (
    parameter int N = 5, // number of counter bits
    parameter int M = 27 // counter limit value
  )
  (
    input logic ckht, //  
    input logic rst, // reset
    output logic tick // sample tick
  );

  // Counter Register
  logic [N-1:0] r_r; // counter value
  logic [N-1:0] r_n; // next counter value

  // Register Logic
  always_ff @(posedge ckht, posedge rst)
    if (rst)
      r_r <= 0;
    else
      r_r <= r_n;

  // Next Counter Value Logic
  assign r_n = (r_r == (M-1)) ? 0 : r_r + 1;

  // Output Logic
  assign tick = (r_r == (M-1)) ? 1'b1 : 1'b0;

endmodule
