`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/01 20:03:12
// Design Name: 
// Module Name: tick_cnt_watch
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


module tick_cnt_watch_h #(
    parameter BIT_WIDTH_1  = 7,
    parameter BIT_WIDTH_10 = 7,
    parameter TIMES_1 = 100,
    parameter TIMES_10 = 100,
    parameter TIMES_1_MAX = 3,
    parameter TIMES_10_MAX = 2,
    parameter START_1 = 0,
    parameter START_10 = 0)
    (
    input   clk,
    input   rst,
    input   i_tick,
    input   down_1,
    input   down_10,
    input   up_1,
    input   up_10,

    output          [BIT_WIDTH_1-1:0]      o_count_1,
    output          [BIT_WIDTH_10-1:0]     o_count_10,
    output  reg                         o_tick

);

    reg     [BIT_WIDTH_1-1:0]     r_tcnt_1;
    reg     [BIT_WIDTH_10-1:0]     r_tcnt_10;

    assign o_count_1  = r_tcnt_1;
    assign o_count_10 = r_tcnt_10;

    reg    r_tick_1;

    wire    max;




    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tcnt_1 <= START_1;
        end
        else if((i_tick || up_1) && (r_tcnt_1 == TIMES_1_MAX) && (r_tcnt_10 == TIMES_10_MAX)) begin
            r_tcnt_1 <= 0;
        end
        else if(down_1 && (r_tcnt_1 == 0) && (r_tcnt_10 == 0)) begin
            r_tcnt_1 <= TIMES_1_MAX;
        end
        else if((i_tick || up_1) && (r_tcnt_1 == TIMES_1 - 1)) begin
            r_tcnt_1 <= 0;
        end
        else if(down_1 && (r_tcnt_1 == 0)) begin
            r_tcnt_1 <= TIMES_1 - 1;
        end
        else if(up_1 || i_tick) begin
            r_tcnt_1 <= r_tcnt_1 + 1'b1;
        end
        else if(down_1) begin
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
        else if((i_tick || up_1) && (r_tcnt_1 == TIMES_1_MAX) && (r_tcnt_10 == TIMES_10_MAX)) begin
            r_tick_1 <= 1'b1;
        end
        else if((i_tick || up_1) && (r_tcnt_1 == TIMES_1 - 1)) begin
            r_tick_1 <= 1'b1;
        end
        else begin
            r_tick_1 <= 1'b0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tcnt_10 <= START_10;
        end
        else if((r_tick_1 || up_10) && (r_tcnt_10 == TIMES_10 - 1)) begin
            r_tcnt_10 <= 0;
        end
        else if(down_10 && (r_tcnt_10 == 0)) begin
            r_tcnt_10 <= TIMES_10 - 1;
        end
        else if(up_10 || r_tick_1) begin
            r_tcnt_10 <= r_tcnt_10 + 1'b1;
        end
        else if(down_10) begin
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
        else if((r_tick_1 || up_10) && (r_tcnt_10 == TIMES_10 - 1)) begin
            o_tick <= 1'b1;
        end
        else begin
            o_tick <= 1'b0;
        end
    end


endmodule
