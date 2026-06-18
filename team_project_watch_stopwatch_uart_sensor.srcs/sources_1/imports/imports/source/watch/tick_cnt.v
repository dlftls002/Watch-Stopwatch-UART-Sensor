`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/31 21:52:24
// Design Name: 
// Module Name: tick_cnt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tick_cnt#(
    parameter BIT_WIDTH_1 = 4,
    parameter BIT_WIDTH_10 = 4,
    parameter TIMES_1 = 9,
    parameter TIMES_10 = 9)
    (
    input   clk,
    input   rst,
    input   i_tick,
    input   i_run_stop,
    input   i_clear,
    input   i_mode,

    output          [BIT_WIDTH_1-1:0]      o_count_1,
    output          [BIT_WIDTH_10-1:0]     o_count_10,
    output  reg                         o_tick

);


    reg [BIT_WIDTH_1-1:0]     r_tcnt_1;
    reg [BIT_WIDTH_10-1:0]    r_tcnt_10;

    reg    r_tick_1;

    assign o_count_1 = r_tcnt_1;
    assign o_count_10 = r_tcnt_10;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tcnt_1 <= 0;
        end
        else if(i_clear) begin
            r_tcnt_1 <= 0;
        end
        else if(~i_mode && i_tick && (r_tcnt_1 == TIMES_1 - 1)) begin
            r_tcnt_1 <= 0;
        end
        else if(i_mode && i_tick && (r_tcnt_1 == 0)) begin
            r_tcnt_1 <= TIMES_1 - 1;
        end
        else if(i_run_stop && ~i_mode && i_tick) begin
            r_tcnt_1 <= r_tcnt_1 + 1'b1;
        end
        else if(i_run_stop && i_mode && i_tick) begin
            r_tcnt_1 <= r_tcnt_1 - 1'b1;
        end
        else begin
            r_tcnt_1 <= r_tcnt_1;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tick_1 <= 1'b0;
        end
        else if(i_clear) begin
            r_tick_1 <= 1'b0;
        end
        else if(!i_run_stop) begin
            r_tick_1 <= 1'b0;
        end
        else if(~i_mode && i_tick && (r_tcnt_1 == TIMES_1 - 1)) begin
            r_tick_1 <= 1'b1;
        end
        else if(i_mode && i_tick && (r_tcnt_1 == 14'd0)) begin
            r_tick_1 <= 1'b1;
        end
        else begin
            r_tick_1 <= 1'b0;
        end
    end



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tcnt_10 <= 0;
        end
        else if(i_clear) begin
            r_tcnt_10 <= 0;
        end
        else if(~i_mode && r_tick_1 && (r_tcnt_10 == TIMES_10 - 1)) begin
            r_tcnt_10 <= 0;
        end
        else if(i_mode && r_tick_1 && (r_tcnt_10 == 0)) begin
            r_tcnt_10 <= TIMES_10 - 1;
        end
        else if(i_run_stop && ~i_mode && r_tick_1) begin
            r_tcnt_10 <= r_tcnt_10 + 1'b1;
        end
        else if(i_run_stop && i_mode && r_tick_1) begin
            r_tcnt_10 <= r_tcnt_10 - 1'b1;
        end
        else begin
            r_tcnt_10 <= r_tcnt_10;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            o_tick <= 1'b0;
        end
        else if(i_clear) begin
            o_tick <= 1'b0;
        end
        else if(!i_run_stop) begin
            o_tick <= 1'b0;
        end
        else if(~i_mode && r_tick_1 && (r_tcnt_10 == TIMES_10 - 1)) begin
            o_tick <= 1'b1;
        end
        else if(i_mode && r_tick_1 && (r_tcnt_10 == 14'd0)) begin
            o_tick <= 1'b1;
        end
        else begin
            o_tick <= 1'b0;
        end
    end



//reg [BIT_WIDTH-1 : 0] counter_reg;
//reg [BIT_WIDTH-1 : 0] counter_next;
//
//assign o_count = counter_reg;
//
//always @ (posedge clk or posedge rst) begin
//    if(rst) begin
//        counter_reg <= 0;
//    end
//    else begin
//        counter_reg <= counter_next;
//    end
//end
//
//always @ (*) begin
//    counter_next = counter_reg;
//    
//    if(rst) begin
//        counter_next = 0;
//    end
//    else if(counter_reg == (TIMES - 1)) begin
//        counter_next = 0;
//    end
//    else if(i_clear) begin
//        counter_next = 0;
//    end
//    else if(~i_run_stop) begin
//        counter_next = counter_next;
//    end
//    else if(i_tick) begin
//        counter_next = counter_reg + 1'b1;
//    end
//    else begin
//        counter_next = counter_reg;
//    end
//end
//
//
//
//always @ (*) begin
//    o_tick = 1'b0;
//    if(rst) begin
//        o_tick = 1'b0;
//    end
//    else if(i_clear) begin
//        o_tick = 1'b0;
//    end
//    else if(counter_reg == (TIMES - 1)) begin
//        o_tick = 1'b1;
//    end
//    else if(~i_run_stop) begin
//        o_tick = 1'b0;
//    end 
//    else begin
//        o_tick = 1'b0;
//    end
//end



endmodule
