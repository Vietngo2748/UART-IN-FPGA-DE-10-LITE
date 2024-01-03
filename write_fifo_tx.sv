module write_to_fifo(
    input logic ckht, rst,
    input logic data_in,
    output logic data_out
);

typedef enum logic [1:0] {
    S1,
    S2,
    S3
} state;

state current_state, next_state;
logic [1:0] counter;

always_ff @(posedge ckht, posedge rst) begin
    if (rst)
        current_state <= S1;
    else
        current_state <= next_state;
end

always_comb begin
    case (current_state)
        S1: begin
            if (data_in)
                next_state = S2;
            else
                next_state = S1;
        end
        S2: begin
            if (counter == 2'b11)
                next_state = S3;
            else
                next_state = S2;
        end
        S3: begin
            next_state = S1;
        end
        default: next_state = S1;
    endcase
end

always_ff @(posedge ckht, posedge rst) begin
    if (rst)
        counter <= 2'b00;
    else if (current_state == S2)
        counter <= counter + 1;
    else if (current_state == S3)
        counter <= 2'b00;
end

always_comb begin
    if (current_state == S3)
        data_out = 1'b1;
    else
        data_out = 1'b0;
end

endmodule
