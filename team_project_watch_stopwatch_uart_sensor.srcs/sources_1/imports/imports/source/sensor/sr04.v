`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/12 12:51:22
// Design Name: 
// Module Name: tick_gen_1us
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

module top_sr04 (
    input   clk,
    input   rst,
    input   i_btn,
    input   i_echo,


//    output  [03:00] o_fnd_digit,
//    output  [07:00] o_fnd_data,
    output  [15:00] o_time,
    output  o_trigger


);

    wire    w_tick;


    tick_gen_1us_sr04 U_TG_sr04(

    .clk(clk),
    .rst(rst),
    
    .o_tick_1us(w_tick)

    );


    sr04_controller U_SR04(

    .clk(clk),
    .rst(rst),
    .i_start(i_btn),
    .i_echo(i_echo),
    .i_tick(w_tick),

    .o_trigger(o_trigger),
    .o_time(o_time)

    );



endmodule




module sr04_controller (

    input clk,
    input rst,
    input i_start,
    input i_echo,
    input i_tick,

    output reg         o_trigger,
    output  [15:00] o_time


);


    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10;

    reg [03:00]     t_cnt;

    reg [01:00]     c_st, n_st;

    reg [15:00]     r_time;
    reg [03:00]     r_dec_cnt;

    reg [03:00]     d_cnt;
    reg [03:00]     d_cnt10;
    reg [03:00]     d_cnt100;
    reg [03:00]     d_cnt1000;

    reg [09:00]     quo_cnt;
    reg [15:00]     mod_cnt;

//    reg [09:00]     f_cnt;

    reg             b_dly0;
    reg             b_dly1;
    reg             b_dly2;

    wire            b_f;
    wire            b_dly0_f;
    wire            b_dly1_f;

    wire        w_cnt1_up;
    wire        w_cnt10_up;
    wire        w_cnt100_up;
    wire        w_cnt1000_up;

    assign    w_cnt10_up  = ((c_st == DATA) && t_cnt == 9 && i_tick);
    assign    w_cnt100_up = (w_cnt10_up && d_cnt10 == 9);
    assign    w_cnt1000_up = (w_cnt100_up && d_cnt100 == 9);



    assign b_dly0_f = ~b_dly0 && (b_dly1);
    assign b_dly1_f = ~b_dly1 &&  b_dly2;

    assign o_time = r_time;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_time <= 16'd0;
        end
        else if((c_st == IDLE) && b_dly1_f) begin
            r_time <= {d_cnt1000 ,d_cnt100, d_cnt10, t_cnt};
        end
        else begin
            r_time <= r_time;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            d_cnt10 <= 4'd0;
        end
        else if(i_start) begin
            d_cnt10 <= 4'd0;
        end
        else if(d_cnt1000 == 4) begin
            d_cnt10 <= d_cnt10;
        end
        else if(w_cnt100_up) begin
            d_cnt10 <= 4'd0;
        end
        else if(w_cnt10_up) begin
            d_cnt10 <= d_cnt10 + 1'b1;
        end
        else begin
            d_cnt10 <= d_cnt10;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            d_cnt100 <= 4'd0;
        end
        else if(i_start) begin
            d_cnt100 <= 4'd0;
        end
        else if(d_cnt1000 == 4) begin
            d_cnt100 <= d_cnt100;
        end
        else if(w_cnt1000_up) begin
            d_cnt100 <= 4'd0;
        end
        else if(w_cnt100_up) begin
            d_cnt100 <= d_cnt100 + 1'b1;
        end
        else begin
            d_cnt100 <= d_cnt100;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            d_cnt1000 <= 4'd0;
        end
        else if(i_start) begin
            d_cnt1000 <= 4'd0;
        end
        else if(w_cnt1000_up) begin
            d_cnt1000 <= d_cnt1000 + 1'b1;
        end
        else begin
            d_cnt1000 <= d_cnt1000;
        end
    end





    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            o_trigger <= 1'b0;
        end
        else if((c_st == IDLE) && i_start) begin
            o_trigger <= 1'b1;
        end
        else if((c_st == START) && t_cnt == 2 && i_tick) begin
            o_trigger <= 1'b0;
        end
        else begin
            o_trigger <= o_trigger;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= 2'b00;
        end
        else begin
            c_st <= n_st;
        end
    end
    
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            t_cnt <= 4'd0;
        end
        else if(i_start) begin
            t_cnt <= 4'd0;
        end
        else if((c_st == START) && t_cnt == 2 && i_tick) begin
            t_cnt <= 4'd0;
        end
        else if((c_st == START)&& i_tick) begin
            t_cnt <= t_cnt + 1'b1;
        end
        else if((c_st == DATA) && i_tick && t_cnt == 9) begin
            t_cnt <= 4'd0;
        end
        else if((c_st == DATA) && i_tick && i_echo) begin
            t_cnt <= t_cnt + 1'b1;
        end
        else begin
            t_cnt <= t_cnt;
        end
    end 



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_dly0 <= 1'b0;
        end
        else begin
            b_dly0 <= i_echo;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_dly1 <= 1'b0;
        end
        else begin
            b_dly1 <= b_dly0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_dly2 <= 1'b0;
        end
        else begin
            b_dly2 <= b_dly1;
        end
    end


    always @ (*) begin
        n_st = c_st;
        case(c_st)
            IDLE : begin
                        if(i_start) begin
                            n_st = START;
                        end
                    end
            START : begin
                        if((t_cnt == 2 && i_tick)) begin
                            n_st = DATA;
                        end
                    end
            DATA :  begin
                        if(b_dly0_f) begin
                            n_st = IDLE;
                        end
                    end
        endcase
    end


            




endmodule


module tick_gen_1us_sr04(

    input   clk,
    input   rst,
    
    output  o_tick_1us

    );

    reg [9:00] clk_cnt;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            clk_cnt <= 10'd0;
        end
        else if(clk_cnt >= 10'd579) begin
            clk_cnt <= 10'd0;
        end
        else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    assign o_tick_1us = (clk_cnt == 10'd579) ? 1'b1 : 1'b0;


endmodule


