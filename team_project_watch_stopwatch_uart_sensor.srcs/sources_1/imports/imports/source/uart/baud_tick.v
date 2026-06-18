`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/05 09:53:15
// Design Name: 
// Module Name: baud_tick
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


module baud_tick(

    input   clk,
    input   rst,

    output  reg  b_tick

    );

    parameter   BAUDRATE = 9600;
    parameter   F_COUNT = 100_000_000 / BAUDRATE / 16;


//    reg [09:00]     clk_cnt;
    reg     [$clog2(F_COUNT)-1 : 0] clk_cnt;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            clk_cnt <= 0;
        end
        else if(clk_cnt == F_COUNT - 1) begin
            clk_cnt <= 0;
        end
        else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_tick <= 1'b0;
        end
        else if(clk_cnt == F_COUNT - 1) begin
            b_tick <= 1'b1;
        end
        else begin
            b_tick <= 1'b0;
        end
    end




endmodule
