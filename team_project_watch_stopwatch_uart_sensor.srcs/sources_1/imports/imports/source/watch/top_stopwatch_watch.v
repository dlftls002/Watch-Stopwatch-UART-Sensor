`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/30 14:13:13
// Design Name: 
// Module Name: top_stopwatch_watch
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


module top_10000_counter(

    input                   clk,
    input                   rst,
    input       [05:00]     i_sw,    // sw[0] up/down
    input                   i_btn_r, // i_run_stop
    input                   i_btn_l, // i_clear
    input                   i_btn_u,
    input                   i_btn_d,

    input                   i_echo,

    inout                   io_dht11,

    input                   i_ascii_dec_r,
    input                   i_ascii_dec_l,
    input                   i_ascii_dec_u,
    input                   i_ascii_dec_d,
    input                   i_ascii_dec_0,
    input                   i_ascii_dec_1,
    input                   i_ascii_dec_2,
    input                   i_ascii_dec_3,
    input                   i_ascii_dec_4,
    input                   i_ascii_dec_5,

    output                  o_hm_sms,
    output                  o_cntl_5,
    output      [01:00]     o_data_sel,
    output                  o_trigger,
    output      [15:00]     o_mux_data,
    output      [03:00]     o_fnd_digit,
    output      [07:00]     o_fnd_data

    );



    wire                w_btn_dbn_run; 
    wire                w_btn_dbn_clr;
    wire                w_btn_dbn_u;
    wire                w_btn_dbn_d;



    wire    [05:00]     w_cntl_mode;
    wire                w_cntl_run;
    wire                w_cntl_clr;
    wire                w_cntl_dht11;
    wire                w_cntl_sr04;
    wire                w_cntl_sec_1;
    wire                w_cntl_sec_10;
    wire                w_cntl_min_1;
    wire                w_cntl_min_10;
    wire                w_cntl_hour_1;
    wire                w_cntl_hour_10;

    wire    [05:00]     w_sw;


    wire    [03:00]            w_stw_msec_1;
    wire    [03:00]            w_stw_msec_10;
    wire    [03:00]            w_stw_sec_1;
    wire    [02:00]            w_stw_sec_10;
    wire    [03:00]            w_stw_min_1;
    wire    [02:00]            w_stw_min_10;
    wire    [03:00]            w_stw_hour_1;
    wire    [01:00]            w_stw_hour_10;

    wire    [03:00]            w_watch_msec_1;
    wire    [03:00]            w_watch_msec_10;
    wire    [03:00]            w_watch_sec_1;
    wire    [02:00]            w_watch_sec_10;
    wire    [03:00]            w_watch_min_1;
    wire    [02:00]            w_watch_min_10;
    wire    [03:00]            w_watch_hour_1;
    wire    [01:00]            w_watch_hour_10;

    wire    [15:00]            w_watch_hour_min;
    wire    [15:00]            w_watch_sec_msec;
    wire    [15:00]            w_stw_hour_min;
    wire    [15:00]            w_stw_sec_msec;




    assign w_sw = (i_sw | {i_ascii_dec_5, i_ascii_dec_4, i_ascii_dec_3, i_ascii_dec_2, i_ascii_dec_1, i_ascii_dec_0 });

    assign w_watch_hour_min     =   ({2'b00, w_watch_hour_10, w_watch_hour_1, 1'b0, w_watch_min_10, w_watch_min_1});
    assign w_watch_sec_msec     =   ({1'b0,  w_watch_sec_10,  w_watch_sec_1,  w_watch_msec_10,  w_watch_msec_1});

    assign w_stw_hour_min     =   ({2'b00, w_stw_hour_10, w_stw_hour_1, 1'b0, w_stw_min_10, w_stw_min_1});
    assign w_stw_sec_msec     =   ({1'b0,  w_stw_sec_10,  w_stw_sec_1,  w_stw_msec_10,  w_stw_msec_1});

    //run_stop
    btn_debounce U_BTN_DBN_RUN(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_btn          (i_btn_r        ),

    .o_btn          (w_btn_dbn_run  )

    );

    //clear
    btn_debounce U_BTN_DBN_CLR(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_btn          (i_btn_l        ),

    .o_btn          (w_btn_dbn_clr  )

    );

    //btn_up
    btn_debounce U_BTN_DBN_U(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_btn          (i_btn_u        ),

    .o_btn          (w_btn_dbn_u    )

    );
    
    //btn_up
    btn_debounce U_BTN_DBN_D(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_btn          (i_btn_d        ),

    .o_btn          (w_btn_dbn_d    )

    );


    //countrol_unit
    control_unit U_CNTL(

    .clk            (clk            ),
    .rst            (rst            ),
    
    .i_mode         (w_sw           ),
    .i_btn_r        (w_btn_dbn_run || i_ascii_dec_r  ),
    .i_btn_l        (w_btn_dbn_clr || i_ascii_dec_l ),

    .o_mode         (w_cntl_mode    ),
    .o_run_stop     (w_cntl_run     ),
    .o_clear        (w_cntl_clr     ),
    .o_dht11        (w_cntl_dht11   ),
    .o_sr04         (w_cntl_sr04    ),
    .o_sec_1        (w_cntl_sec_1   ),
    .o_sec_10       (w_cntl_sec_10  ),
    .o_min_1        (w_cntl_min_1   ),
    .o_min_10       (w_cntl_min_10  ),
    .o_hour_1       (w_cntl_hour_1  ),
    .o_hour_10      (w_cntl_hour_10 )

    );





    top_stopwatch U_SW(

    .clk            (clk            ),
    .rst            (rst            ),
    .i_mode         (w_cntl_mode[3] || i_ascii_dec_3 ),
    .i_clear        (w_cntl_clr     ),
    .i_run_stop     (w_cntl_run     ),

    .o_msec_1       (w_stw_msec_1     ),
    .o_msec_10      (w_stw_msec_10    ),
    .o_sec_1        (w_stw_sec_1      ),
    .o_sec_10       (w_stw_sec_10     ),
    .o_min_1        (w_stw_min_1      ),
    .o_min_10       (w_stw_min_10     ),
    .o_hour_1       (w_stw_hour_1     ),
    .o_hour_10      (w_stw_hour_10    )

);


    wire    w_sec_1_onoff;
    wire    w_sec_10_onoff;
    wire    w_min_1_onoff;
    wire    w_min_10_onoff;
    wire    w_hour_1_onoff;
    wire    w_hour_10_onoff;

    top_watch U_WATCH(

    .clk            (clk            ),
    .rst            (rst            ),
    .up             (w_btn_dbn_u    ||  i_ascii_dec_u    ),        //btn_up
    .down           (w_btn_dbn_d    ||  i_ascii_dec_d   ),        //btn_down

    .sec_1            (w_cntl_sec_1     ),
    .sec_10           (w_cntl_sec_10    ),
    .min_1            (w_cntl_min_1     ),
    .min_10           (w_cntl_min_10    ),
    .hour_1           (w_cntl_hour_1    ),     
    .hour_10          (w_cntl_hour_10   ),     


    .o_sec_1_onoff    (w_sec_1_onoff    ),
    .o_sec_10_onoff   (w_sec_10_onoff   ),
    .o_min_1_onoff    (w_min_1_onoff    ),
    .o_min_10_onoff   (w_min_10_onoff   ),
    .o_hour_1_onoff   (w_hour_1_onoff   ),
    .o_hour_10_onoff  (w_hour_10_onoff  ),

    .o_msec_1         (w_watch_msec_1   ),
    .o_msec_10        (w_watch_msec_10  ),
    .o_sec_1          (w_watch_sec_1    ),
    .o_sec_10         (w_watch_sec_10   ),
    .o_min_1          (w_watch_min_1    ),
    .o_min_10         (w_watch_min_10   ),
    .o_hour_1         (w_watch_hour_1   ),
    .o_hour_10        (w_watch_hour_10  )

);



    wire    [15:00]     w_data;



    
    wire    [15:00]     w_sr04_data;
    wire    [15:00]     w_dht11_data;
    
    wire    [15:00]     w_stw_data;
    wire    [15:00]     w_watch_data;
    wire    [03:00]     w_onoff;
    wire                w_dot;
    wire    [15:00]     w_distance;
    wire                w_trigger;

    wire    [01:00]     w_data_sel;

    wire    [03:00]     w_watch_onoff;


    assign o_hm_sms = (w_cntl_mode[2] || i_ascii_dec_2);

    assign  w_sr04_data = {w_distance};

    assign w_data_sel = ({{w_cntl_mode[1] || i_ascii_dec_1}, {w_cntl_mode[0] || i_ascii_dec_0}});

    assign  w_dot = w_watch_msec_10 < 5; 

    assign w_data = w_data_sel == 2'b00 ? w_watch_data :
                    w_data_sel == 2'b01 ? w_stw_data :
                    w_data_sel == 2'b10 ? w_sr04_data : w_dht11_data;


    

    assign w_stw_data   = (w_cntl_mode[2] || i_ascii_dec_2) ? w_stw_hour_min   : w_stw_sec_msec;
    assign w_watch_data = (w_cntl_mode[2] || i_ascii_dec_2) ? w_watch_hour_min : w_watch_sec_msec;

    assign w_onoff = (w_cntl_mode[2] || i_ascii_dec_2)    ? ({w_hour_10_onoff, w_hour_1_onoff, w_min_10_onoff, w_min_1_onoff}) :
                                                            ({w_sec_10_onoff, w_sec_1_onoff, 2'b00});

    assign w_watch_onoff = (w_data_sel == 2'b00) ? w_onoff : 0;



    assign o_data_sel = w_data_sel;
    assign o_cntl_5 = w_cntl_mode[5];

    assign o_mux_data = w_data;

    top_sr04 U_SR04(
    .clk(clk),
    .rst(rst),
    .i_btn(w_cntl_sr04),
    .i_echo(i_echo),


    .o_time (w_distance),
    .o_trigger (o_trigger)


    );

    dht11_top U_DHT11(

    .clk(clk),
    .rst(rst),
    .i_btn(w_cntl_dht11),
    .sw(w_cntl_mode[5]),

    .dht11_io(io_dht11),


    .o_data(w_dht11_data),

    .o_done(),
    .o_valid(),
    .o_c_st(),
    .o_dcnt()

    );




    fnd_controller U_FND_CNTL(

    .clk            (clk            ),
    .rst            (rst            ),
    

    .i_dot_sel      (w_data_sel     ),
    .i_fnd_data     (w_data         ),
    .i_onoff        (w_watch_onoff  ),
    .i_dot          (w_dot          ),



    .o_fnd_digit    (o_fnd_digit    ),
    .o_fnd_data     (o_fnd_data     )


    );

endmodule
