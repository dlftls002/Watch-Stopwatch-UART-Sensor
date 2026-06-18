`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/31 21:38:36
// Design Name: 
// Module Name: top_stopwathch
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


module top_stopwatch(

    input   clk,
    input   rst,
    input   i_mode,
    input   i_clear,
    input   i_run_stop,

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


    tick_gen U_TICK(

    .clk            (clk            ),
    .rst            (rst            ),
    .clear          (i_clear        ),
    .i_run_stop     (i_run_stop     ),

    .o_tick         (w_tick         )
    );

    tick_cnt #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(4), .TIMES_1(10), .TIMES_10(10)) 
    MSEC_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_mode         (i_mode         ),
    .i_clear        (i_clear        ),
    .i_run_stop     (i_run_stop     ),
    .i_tick         (w_tick         ),

    .o_count_1      (o_msec_1),   
    .o_count_10     (o_msec_10         ),
    .o_tick         (w_msec_tick    )
    );


    tick_cnt #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(3), .TIMES_1(10), .TIMES_10(6)) 
    SEC_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_mode         (i_mode         ),
    .i_clear        (i_clear        ),
    .i_run_stop     (i_run_stop     ),
    .i_tick         (w_msec_tick    ),


    .o_count_1      (o_sec_1),   
    .o_count_10     (o_sec_10            ),
    .o_tick         (w_sec_tick     )
    );

    tick_cnt #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(3), .TIMES_1(10), .TIMES_10(6)) 
    MIN_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_mode         (i_mode         ),
    .i_clear        (i_clear        ),
    .i_run_stop     (i_run_stop     ),
    .i_tick         (w_sec_tick     ),


    .o_count_1      (o_min_1),   
    .o_count_10     (o_min_10          ),
    .o_tick         (w_min_tick     )
    );

    tick_cnt_h #(.BIT_WIDTH_1(4), .BIT_WIDTH_10(2), .TIMES_1(10), .TIMES_10(3), .TIMES_1_MAX(3), .TIMES_10_MAX(2)) 
    HOUR_COUNTER(
    .clk            (clk            ),
    .rst            (rst            ),
    .i_mode         (i_mode         ),
    .i_clear        (i_clear        ),
    .i_run_stop     (i_run_stop     ),
    .i_tick         (w_min_tick     ),


    .o_count_1      (o_hour_1),   
    .o_count_10     (o_hour_10         ),
    .o_tick         (w_hour_tick    )
    );


endmodule
