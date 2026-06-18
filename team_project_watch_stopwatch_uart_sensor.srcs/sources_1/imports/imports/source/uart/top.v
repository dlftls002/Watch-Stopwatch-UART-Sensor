`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/07 18:04:22
// Design Name: 
// Module Name: top
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


module top(

    input               clk,
    input               rst,
    input   [05:00]     i_sw,    // sw[0] up/down
    input               i_btn_r, // i_run_stop
    input               i_btn_l, // i_clear
    input               i_btn_u,
    input               i_btn_d,
    input               i_rx,
    input               i_echo,

    inout               io_dht11,

    output              o_cntl_5,
    output  [01:00]     o_data_sel,
    output              o_trigger,
    output  [03:00]     o_fnd_digit,
    output  [07:00]     o_fnd_data,
    output              o_tx
    
    );


    wire                    w_rx_done;
    wire                    w_rx_start;
    wire    [07:00]         w_rx_data;
    wire                    w_tx_start;
    wire                    w_tx_done;

    wire    [07:00]         w_data;
    wire                    w_ascii_dec_r; 
    wire                    w_ascii_dec_l; 
    wire                    w_ascii_dec_u; 
    wire                    w_ascii_dec_d; 
    wire                    w_ascii_dec_0; 
    wire                    w_ascii_dec_1; 
    wire                    w_ascii_dec_2; 
    wire                    w_ascii_dec_3; 
    wire                    w_ascii_dec_4; 
    wire                    w_ascii_dec_5; 
    wire                    w_ascii_dec_s; 
    
    wire                    w_hm_sms;

    wire    [01:00]         w_data_sel;
    wire                    w_cntl_5;
    wire    [15:00]         w_mux_data;
    wire                    w_fifo_tx_start;
    wire                    w_fifo_empty;
    wire    [07:00]         w_fifo_pop_data;
    wire                    w_fifo_full;
    wire                    w_fifo_push;
    wire    [07:00]         w_fifo_push_data;

    assign  o_data_sel = w_data_sel;
    assign  o_cntl_5 = w_cntl_5;



    ascii_decoder U_ASCII_DECODER(

    .clk            (clk        ),
    .rst            (rst        ),

    .i_data         (w_rx_data  ),
    .i_start        (w_rx_start ),
    .i_done         (w_rx_done  ),

    .o_btn_r        (w_ascii_dec_r),
    .o_btn_l        (w_ascii_dec_l),
    .o_btn_u        (w_ascii_dec_u),
    .o_btn_d        (w_ascii_dec_d),
    .o_btn_0        (w_ascii_dec_0),
    .o_btn_1        (w_ascii_dec_1),
    .o_btn_2        (w_ascii_dec_2),
    .o_btn_3        (w_ascii_dec_3),
    .o_btn_4        (w_ascii_dec_4),
    .o_btn_5        (w_ascii_dec_5),
    .o_btn_s        (w_ascii_dec_s)
    );



    wire    [01:00]     w_debug_tx_state;
    wire    [07:00]     w_debug_tx_data;
    wire                w_debug_tx_start;
    wire                w_debug_tx_done;
    wire    [04:00]     w_debug_start_cnt;

    uart_top U_UART_TOP(

    .clk            (clk            ),
    .rst            (rst            ),

    .i_uart_rx      (i_rx           ),
    .i_tx_start     (w_fifo_tx_start),
    .i_tx_data      (w_fifo_pop_data),


    .o_debug_state       (w_debug_tx_state)           ,             
    .o_debug_tx_start    (w_debug_tx_start)           ,              
    .o_debug_tx_data     (w_debug_tx_data)           ,               
    .o_debug_tx_done     (w_debug_tx_done)           ,               
    .o_debug_start_cnt      (w_debug_start_cnt),

    .o_rx_done      (w_rx_done      ),
    .o_rx_start     (w_rx_start     ),
    .o_rx_data      (w_rx_data      ),
    .o_tx_done      (w_tx_done      ),
    .o_uart_tx      (o_tx           )

    );


//    ila_0 U_ILA(
//        .clk(clk),
//
//
//        .probe0(w_debug_tx_start),
//        .probe1(w_debug_tx_done),
//        .probe2(w_debug_tx_state),
//        .probe3(w_debug_tx_data),
//        .probe4(w_debug_start_cnt)
//        );



    sender_top U_SENDER_TOP(

    .i_clk              (clk                ),
    .i_reset            (rst                ),

    .i_start            (w_ascii_dec_s      ),
    .i_sel              (w_data_sel         ),
    .i_sel_2            ({w_hm_sms,w_cntl_5}),
    .i_data_1000        (w_mux_data[15:12]  ),
    .i_data_100         (w_mux_data[11:08]  ),
    .i_data_10          (w_mux_data[07:04]  ),
    .i_data_1           (w_mux_data[03:00]  ),

     //FIFO interface
    .i_fifo_full        (w_fifo_full        ),
    .o_fifo_push        (w_fifo_push        ),
    .o_fifo_push_data   (w_fifo_push_data   )
    );



    pop_controller U_POP_CONTROLLER(

    .i_clk              (clk                ),
    .i_reset            (rst                ),
    .i_empty            (w_fifo_empty       ),
    .i_done             (w_tx_done          ),

    .o_tx_start         (w_fifo_tx_start    )

    );

    fifo #(.DEPTH(16), .BIT_WIDTH(8)) 

    U_FIFO(
    .i_clk              (clk                ),
    .i_reset            (rst                ),
    .i_push             (w_fifo_push        ),
    .i_pop              (w_fifo_tx_start    ),
    .i_push_data        (w_fifo_push_data   ),
    .o_pop_data         (w_fifo_pop_data    ),
    .o_empty            (w_fifo_empty       ),
    .o_full             (w_fifo_full        )

    );



    top_10000_counter U_STW_SW(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_sw           (i_sw           ),    
    .i_btn_r        (i_btn_r        ), 
    .i_btn_l        (i_btn_l        ), 
    .i_btn_u        (i_btn_u        ),
    .i_btn_d        (i_btn_d        ),

    .i_echo         (i_echo         ),

    .io_dht11       (io_dht11       ),

    .i_ascii_dec_r  (w_ascii_dec_r  ),
    .i_ascii_dec_l  (w_ascii_dec_l  ),
    .i_ascii_dec_u  (w_ascii_dec_u  ),
    .i_ascii_dec_d  (w_ascii_dec_d  ),
    .i_ascii_dec_0  (w_ascii_dec_0  ),
    .i_ascii_dec_1  (w_ascii_dec_1  ),
    .i_ascii_dec_2  (w_ascii_dec_2  ),
    .i_ascii_dec_3  (w_ascii_dec_3  ),
    .i_ascii_dec_4  (w_ascii_dec_4  ),
    .i_ascii_dec_5  (w_ascii_dec_5  ),

    .o_hm_sms       (w_hm_sms       ),
    .o_cntl_5       (w_cntl_5       ),
    .o_data_sel     (w_data_sel     ),
    .o_trigger      (o_trigger      ),
    .o_mux_data     (w_mux_data     ),
    .o_fnd_digit    (o_fnd_digit    ),
    .o_fnd_data     (o_fnd_data     )

    );


endmodule
