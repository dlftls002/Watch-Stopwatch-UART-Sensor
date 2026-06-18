`timescale 1ns / 1ps










module pop_controller (
    input i_clk,
    input i_reset,

    input i_empty,
    input i_done,

    output o_tx_start
);

    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam WAIT = 2'b10;

    reg [1:0] c_state, n_state;
    reg r_tx_start, next_r_tx_start;

    assign o_tx_start = r_tx_start;



    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            c_state    <= IDLE;
            r_tx_start <= 1'b0;
        end else begin
            c_state    <= n_state;
            r_tx_start <= next_r_tx_start;
        end
    end

    always @(*) begin
        n_state         = c_state;
        next_r_tx_start = 1'b0;
        case (n_state)
            IDLE: begin
                next_r_tx_start = 1'b0;
                if (!i_empty) begin
                    next_r_tx_start = 1'b1;
                    n_state         = SEND;
                end
            end
            SEND: begin
                next_r_tx_start = 1'b0;
                n_state         = WAIT;
            end
            WAIT: begin
                if (i_done) begin
                    if (!i_empty) begin
                        next_r_tx_start = 1'b1;
                        n_state         = SEND;
                    end else begin
                        n_state = IDLE;
                    end
                end
            end
        endcase
    end
endmodule
