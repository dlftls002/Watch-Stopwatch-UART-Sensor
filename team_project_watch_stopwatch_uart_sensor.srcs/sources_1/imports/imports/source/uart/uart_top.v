`timescale 1ns / 1ps


module uart_top(

    input   clk,
    input   rst,
    input   i_uart_rx,
    input   i_tx_start,
    input   [07:00] i_tx_data,


    output [01:00]  o_debug_state,
    output          o_debug_tx_start,
    output [07:00]  o_debug_tx_data,
    output          o_debug_tx_done,
    output  [04:00]     o_debug_start_cnt,


    output  o_rx_done,
    output  o_rx_start,
    output  [07:00] o_rx_data,

    output  o_tx_done,
    output  o_uart_tx

);

    wire            w_baud_tick;
    wire            w_rx_done;
    wire            w_tx_start;
    wire [07:00]    w_tx_data;
    wire [07:00]    w_rx_data;
    wire            w_rx_done_dly1;


    reg [01:00]     r_rx_done_dly1;




    assign  o_rx_data   =   w_rx_data;
    assign  o_rx_done   =   w_rx_done;


    baud_tick U_BAUD_TICK(

    .clk(clk),
    .rst(rst),

    .b_tick(w_baud_tick)
    
    );

    uart_tx U_UART_TX(

    .clk(clk),
    .rst(rst),
    .tx_start(i_tx_start),
    .b_tick(w_baud_tick),

    .o_debug_state          (o_debug_state   )    ,
    .o_debug_tx_start       (o_debug_tx_start)    ,
    .o_debug_tx_data        (o_debug_tx_data )    ,
    .o_debug_tx_done        (o_debug_tx_done )    ,
    .o_debug_start_cnt      (o_debug_start_cnt),

    .tx_data(i_tx_data),   //0011_0000
    .tx_done(o_tx_done),
    .tx_busy(),
    .uart_tx(o_uart_tx)

    );


    uart_rx U_UART_RX(

    .clk(clk),
    .rst(rst),
    .rx(i_uart_rx),
    .b_tick(w_baud_tick),

    .rx_start(o_rx_start),
    .rx_data(w_rx_data),
    .rx_done(w_rx_done)

);


endmodule
