`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/01 18:46:06
// Design Name: 
// Module Name: top_watch
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


module top_watch(

    input   clk,
    input   rst,
    input   up,        //btn_down
    input   down,        //btn_up

    input   sec_1,
    input   sec_10,
    input   min_1,
    input   min_10,
    input   hour_1,
    input   hour_10,

//    input   sw_l2,
//    input   sw_r2,

    output  o_sec_1_onoff,
    output  o_sec_10_onoff,
    output  o_min_1_onoff,
    output  o_min_10_onoff,
    output  o_hour_1_onoff,
    output  o_hour_10_onoff,

    output  [03:00] o_msec_1,
    output  [03:00] o_msec_10,
    output  [03:00] o_sec_1,
    output  [02:00] o_sec_10,
    output  [03:00] o_min_1,
    output  [02:00] o_min_10,
    output  [03:00] o_hour_1,
    output  [01:00] o_hour_10

);


    
    wire    w_tick;
    wire    w_msec_tick;
    wire    w_sec_tick;
    wire    w_min_tick;
    wire    w_hour_tick;

    
    assign  o_sec_1_onoff   = sec_1   ? 1'b1 : 1'b0;
    assign  o_sec_10_onoff  = sec_10  ? 1'b1 : 1'b0;
    assign  o_min_1_onoff   = min_1   ? 1'b1 : 1'b0;
    assign  o_min_10_onoff  = min_10  ? 1'b1 : 1'b0;
    assign  o_hour_1_onoff  = hour_1  ? 1'b1 : 1'b0;
    assign  o_hour_10_onoff = hour_10 ? 1'b1 : 1'b0;



    tick_gen_watch U_TICK(

    .clk            (clk            ),
    .rst            (rst            ),

    .o_tick         (w_tick         )
    );

    tick_cnt_watch #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(4), .TIMES_1(10), .TIMES_10(10), .START_1(0), .START_10(0)) 
    MSEC_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_tick         (w_tick         ),
    .up_1           (1'b0           ),
    .up_10          (1'b0           ),
    .down_1         (1'b0           ),
    .down_10        (1'b0           ),

    .o_count_1      (o_msec_1       ),
    .o_count_10     (o_msec_10      ),
    .o_tick         (w_msec_tick    )
    );


    tick_cnt_watch #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(3), .TIMES_1(10), .TIMES_10(6), .START_1(0), .START_10(3)) 
    SEC_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_tick         (w_msec_tick    ),
    .up_1           (up && sec_1    ),
    .up_10          (up && sec_10   ),
    .down_1         (down && sec_1  ),
    .down_10        (down && sec_10 ),


    .o_count_1      (o_sec_1        ),
    .o_count_10     (o_sec_10       ),
    .o_tick         (w_sec_tick     )
    );

    tick_cnt_watch #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(3), .TIMES_1(10), .TIMES_10(6), .START_1(1), .START_10(2)) 
    MIN_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_tick         (w_sec_tick     ),
    .up_1           (up && min_1    ),
    .up_10          (up && min_10   ),
    .down_1         (down && min_1  ),
    .down_10        (down && min_10 ),


    .o_count_1      (o_min_1        ),
    .o_count_10     (o_min_10       ),
    .o_tick         (w_min_tick     )
    );

    tick_cnt_watch_h #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(2), .TIMES_1(10), .TIMES_10(3), .TIMES_1_MAX(3), .TIMES_10_MAX(2), .START_1(1), .START_10(2)) 
    HOUR_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_tick         (w_min_tick     ),
    .up_1           (up && hour_1   ),
    .up_10          (up && hour_10  ),
    .down_1         (down && hour_1 ),
    .down_10        (down && hour_10),

    .o_count_1      (o_hour_1       ),
    .o_count_10     (o_hour_10      ),
    .o_tick         (w_hour_tick    )
    );



endmodule
