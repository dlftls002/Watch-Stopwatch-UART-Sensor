`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/31 16:07:45
// Design Name: 
// Module Name: tick_gen
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


module tick_gen(

    input   clk,
    input   rst,
    input   clear,
    input   i_run_stop,

    output  reg  o_tick
);

    parameter F_COUNT = 100_000_000/100;
    

//    reg [23:00] r_counter;
    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_counter <= 0;
        end
        else if(clear) begin
            r_counter <= 0;
        end
        else if(~i_run_stop) begin
            r_counter <= r_counter;
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
        else if(clear) begin
            o_tick <= 1'b0;
        end
        else if(~i_run_stop) begin
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
