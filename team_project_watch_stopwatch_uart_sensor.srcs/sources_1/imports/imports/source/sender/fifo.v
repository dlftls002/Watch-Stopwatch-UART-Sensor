`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 16,
    parameter BIT_WIDTH = 8
) (
    input        i_clk,
    input        i_reset,
    input        i_push,
    input        i_pop,
    input  [7:0] i_push_data,
    output [7:0] o_pop_data,
    output       o_empty,
    output       o_full
);

//    wire [$clog2(DEPTH) - 1 : 0] w_wptr, w_rptr;
    wire [$clog2(DEPTH) - 1  : 0] w_wptr, w_rptr;

    register_file #(
        .DEPTH(DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) U_REG_FILE (
        .i_clk      (i_clk),
        .i_push_data(i_push_data),
        .w_addr     (w_wptr),
        .r_addr     (w_rptr),
        .we         (i_push && (~o_full)),
        .pop_data   (o_pop_data)
    );

    control_unit_fifo #(
        .DEPTH(DEPTH)
    ) U_CONTROL_UNIT (
        .i_clk  (i_clk),
        .i_reset(i_reset),
        .i_push (i_push),
        .i_pop  (i_pop),
        .o_wptr (w_wptr),
        .o_rptr (w_rptr),
        .o_full (o_full),
        .o_empty(o_empty)
    );

endmodule

module register_file #(
    parameter DEPTH = 16,
    parameter BIT_WIDTH = 8
) (
    input                      i_clk,
    input  [    BIT_WIDTH-1:0] i_push_data,
    input  [$clog2(DEPTH)-1:0] w_addr,
    input  [$clog2(DEPTH)-1:0] r_addr,
    input                      we,
    output [    BIT_WIDTH-1:0] pop_data
);

    //ram
    reg [BIT_WIDTH-1:0] register_file[0:DEPTH-1];

    //push, write
    always @(posedge i_clk) begin //memory는 초기화 하지 않아서 reset이 없음
        if (we) begin
            register_file[w_addr] <= i_push_data;
        end
    end

    //pop, read
    assign pop_data = register_file[r_addr];

endmodule

module control_unit_fifo #(
    parameter DEPTH = 16
) (
    input        i_clk,
    input        i_reset,
    input        i_push,
    input        i_pop,
    output [3:0] o_wptr,
    output [3:0] o_rptr,
    output       o_full,
    output       o_empty
);

    reg [1:0] c_state, n_state;
    reg [$clog2(DEPTH)-1:0] wptr_reg, wptr_next;
    reg [$clog2(DEPTH)-1:0] rptr_reg, rptr_next;
    reg full_reg, full_next, empty_reg, empty_next;

    assign o_wptr  = wptr_reg;
    assign o_rptr  = rptr_reg;
    assign o_full  = full_reg;
    assign o_empty = empty_reg;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            c_state   <= 2'd0;
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            c_state   <= n_state;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        n_state    = c_state;
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            i_push, i_pop
        })
            //push
            2'b10: begin
                if (!o_full) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end

            //pop
            2'b01: begin
                if (!o_empty) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end

            //push, pop
            2'b11: begin
                if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end

        endcase
    end

endmodule
