`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/01 20:05:22
// Design Name: 
// Module Name: tick_gen_watch
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


module tick_gen_watch(

    input   clk,
    input   rst,

    output  reg  o_tick
);

    parameter F_COUNT = 100_000_000/100;
//    parameter F_COUNT = 100_000_0/100;
    

    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_counter <= 0;
        end
        else if(r_counter == F_COUNT-1) begin
            r_counter <= 0;
        end
//        else if(r_counter == 99) begin
//            r_counter <= 24'd0;
//        end
        else begin
            r_counter <= r_counter + 1'b1;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            o_tick <= 1'b0;
        end
        else if(r_counter == F_COUNT - 1) begin
            o_tick <= 1'b1;
        end
 //       else if(r_counter == 99) begin
 //           o_tick <= 1'b1;
 //       end
        else begin
            o_tick <= 1'b0;
        end
    end

endmodule
