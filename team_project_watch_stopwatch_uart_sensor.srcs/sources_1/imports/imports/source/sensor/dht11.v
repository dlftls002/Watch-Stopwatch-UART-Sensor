`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/16 13:44:19
// Design Name: 
// Module Name: dh11
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


module dht11_top(

    input   clk,
    input   rst,
    input   i_btn,
    input   sw,

    inout   dht11_io,

//    output  [03:00]     o_fnd_digit,
//    output  [07:00]     o_fnd_data,

//    output  [15:00]     o_humidity,
//    output  [15:00]     o_temperature,

    output  [15:00]     o_data,

    output              o_done,
    output              o_valid,
    output  [02:00]     o_c_st,
    output  [05:00]     o_dcnt

    );

    wire    w_tick;
    wire    w_db_btn;

    wire    [15:00]     o_humidity;
    wire    [15:00]     o_temperature;


    wire    [15:00]     w_d_sel;




    tick_gen_1us U_TG_dht11(

    .clk(clk),
    .rst(rst),
    
    .o_tick_1us(w_tick)

    );



    dht11 U_DHT11(


    .clk(clk),
    .rst(rst),
    .i_start(i_btn),

    .i_tick(w_tick),

    .dht11_io(dht11_io),

    .o_humidity         (o_humidity   ),
    .o_temperature      (o_temperature),
    .o_done             (o_done      ),
    .o_valid            (o_valid      ),
    .o_c_st             (o_c_st       ),
    .o_dcnt             (o_dcnt)

);

    assign o_data = sw ? o_humidity : o_temperature;




endmodule


module dht11(


    input               clk,
    input               rst,
    input               i_start,

    input               i_tick,

    inout               dht11_io,

    output  [15:00]     o_humidity,
    output  [15:00]     o_temperature,
    output              o_done,
    output              o_valid,
    output  [02:00]     o_c_st,
    output  [05:00]     o_dcnt

);


    parameter IDLE = 3'd0, START = 3'd1, WAIT = 3'd2, SYNC_L = 3'd3, SYNC_H = 3'd4, DATA_S = 3'd5, DATA_C = 3'd6, STOP = 3'd7; 

    reg [02:00] c_st, n_st;

    reg [03:00] r_tick_10us;
    reg [10:00] r_tcnt;
    reg         r_sel;
    reg         r_data;
    reg         r_dht11_io_dly0;
    reg         r_dht11_io_dly1;
    reg         r_dht11_io_dly2;
    reg         r_dht11_io_dly3;
    reg         r_dht11_io_dly4;
    reg [05:00] r_dcnt;
    reg [39:00] r_dht11_data;
    reg [07:00] r_checksum;
    reg         r_checksum_pf;
    reg         r_done_test;
    reg [31:00] tmp_data1;
    reg [31:00] r_done_data;


    wire        w_tick_10us;
    wire        w_start_done;
    wire        w_dht11_r;
    wire        w_dht11_f;
    wire        w_dht11_dly0_r;
    wire        w_dht11_dly0_f;
    wire        w_dht11_dly1_r;
    wire        w_dht11_dly1_f;
    wire        w_dht11_dly2_r;
    wire        w_dht11_dly2_f;
    wire        w_dht11_dly3_r;
    wire        w_dht11_dly3_f;
    wire        w_data;
    wire        w_data_s_done;
    wire        w_stop_done;

    wire    [03:00]     tmp_1;
    wire    [03:00]     tmp_10;



    assign tmp_1  = r_dht11_data[07:00] % 10;
    assign tmp_10 = (r_dht11_data[07:00]/10) % 10;

//    assign o_humidity = tmp_data1[31:16];
//    assign o_temperature = tmp_data1[15:00];
    assign o_humidity    = r_done_data[31:16];
    assign o_temperature = r_done_data[15:00];
    assign o_valid       = r_checksum_pf;
    assign o_c_st        = c_st;
    assign o_dcnt        = r_dcnt;

    
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_done_test <= 1'b0;
        end
        else if(w_stop_done) begin
            r_done_test <= 1'b1;
        end
        else begin
            r_done_test <= r_done_test;
        end
    end



    assign o_done = r_done_test;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_done_data <= 32'd0;
        end
        else if(w_stop_done) begin
            r_done_data <= tmp_data1;
        end
        else begin
            r_done_data <= r_done_data;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tick_10us <= 4'd0;
        end
        else if(r_tick_10us == 4'd9 && i_tick) begin
            r_tick_10us <= 4'd0;
        end
        else if(i_tick) begin
            r_tick_10us <= r_tick_10us + 1'b1;
        end
        else begin
            r_tick_10us <= r_tick_10us;
        end
    end

    assign w_tick_10us = (r_tick_10us == 4'd9 && i_tick);

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_tcnt <= 11'd0;
        end
        else if(i_start || w_start_done || w_wait_done || w_data_done) begin
            r_tcnt <= 11'd0;
        end
        else if((c_st == DATA_S) && w_dht11_dly0_r) begin
            r_tcnt <= 11'd0;
        end
        else if((c_st != IDLE) && w_tick_10us) begin
            r_tcnt <= r_tcnt + 1'b1;
        end
        else begin
            r_tcnt <= r_tcnt;
        end
    end

    assign w_start_done = ((c_st == START) && (r_tcnt == 1900) && w_tick_10us);

    assign w_wait_done  = ((c_st == WAIT) && (r_tcnt == 2) && w_tick_10us);

    assign w_data_s_done = ((c_st == DATA_S) && w_dht11_dly0_r);

    assign w_data_c_done = ((c_st == DATA_C) && w_dht11_dly0_f);

    assign w_data = (w_data_c_done &&  (r_tcnt >= 5));

    assign w_data_done = (r_dcnt == 39 && w_data_c_done);

    assign w_stop_done = ((c_st == STOP) && r_tcnt == 6 && w_tick_10us);

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_checksum <= 8'd0;
        end
        else if(i_start) begin
            r_checksum <= 8'd0;
        end
//        else if(r_dcnt[]) begin
//            r_checksum <= r_checksum;
//        end
        else if((c_st == DATA_S) && (r_dcnt[02:00] == 3'b000) && w_dht11_dly1_f) begin
            r_checksum <= r_checksum + r_dht11_data[07:00];
        end
//        else if(r_dcnt == (6'd8 || 6'd16 || 6'd24) && w_dht11_dly0_f) begin
//            r_checksum <= r_checksum + r_dht11_data[39:32];
//        end
        else begin
            r_checksum <= r_checksum;
        end
    end







    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tmp_data1 <= 32'd0;
        end
        else if(i_start) begin
            tmp_data1 <= 32'd0;
        end
        else if((c_st == DATA_S) && (r_dcnt[02:00] == 3'b000) && w_dht11_dly2_f) begin
            tmp_data1 <= ({tmp_data1[31:08], tmp_10, tmp_1});
        end
        else if((c_st == DATA_S) && (r_dcnt[02:00] == 3'b000) && w_dht11_dly3_f && r_dcnt[5] != 1'b1) begin
            tmp_data1 <= tmp_data1 << 8;
        end
        else begin
            tmp_data1 <= tmp_data1;
        end
    end



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_checksum_pf <= 1'b0;
        end
        else if(i_start) begin
            r_checksum_pf <= 1'b0;
        end
        else if(r_dcnt == 40 && w_dht11_dly1_f && (r_checksum == r_dht11_data[07:00])) begin
            r_checksum_pf <= 1'b1;
        end
        else begin
            r_checksum_pf <= r_checksum_pf;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_data <= 40'd0;
        end
        else if(i_start) begin
            r_dht11_data <= 40'd0;
        end
        else if(w_data_c_done) begin
            r_dht11_data <= {r_dht11_data[38:00], w_data};
        end
        else begin
            r_dht11_data <= r_dht11_data;
        end
    end



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dcnt <= 6'd0;
        end
        else if(i_start) begin
            r_dcnt <= 6'd0;
        end
        else if(w_data_c_done) begin
            r_dcnt <= r_dcnt + 1'b1;
        end
        else begin
            r_dcnt <= r_dcnt;
        end
    end


    assign dht11_io = (r_sel) ? r_data : 1'bz;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_sel <= 1'b1;
        end
        else if(i_start) begin
            r_sel <= 1'b1;
        end
        else if(w_wait_done) begin
            r_sel <= 1'b0;
        end
        else if(w_stop_done) begin
            r_sel <= 1'b1;
        end
        else begin
            r_sel <= r_sel;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_data <= 1'b1;
        end
        else if(i_start) begin
            r_data <= 1'b0;
        end
        else if(w_start_done) begin
            r_data <= 1'b1;
        end
        else begin
            r_data <= r_data;
        end
    end

//    always @ (posedge clk or posedge rst) begin
//        if(rst) begin
//            r_dht11_io_dly0 <= 1'b0;
//        end
//        else if(c_st == WAIT) begin
//            r_dht11_io_dly0 <= dht11_io;
//        end
//        else begin
//            r_dht11_io_dly0 <= r_dht11_io_dly0;
//        end
//    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_io_dly0 <= 1'b0;
        end
        else begin
            r_dht11_io_dly0 <= dht11_io;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_io_dly1 <= 1'b0;
        end
        else begin
            r_dht11_io_dly1 <= r_dht11_io_dly0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_io_dly2 <= 1'b0;
        end
        else begin
            r_dht11_io_dly2 <= r_dht11_io_dly1;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_io_dly3 <= 1'b0;
        end
        else begin
            r_dht11_io_dly3 <= r_dht11_io_dly2;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_dht11_io_dly4 <= 1'b0;
        end
        else begin
            r_dht11_io_dly4 <= r_dht11_io_dly3;
        end
    end

    assign w_dht11_tr =  dht11_io && ~r_dht11_io_dly0;
    assign w_dht11_tf = ~dht11_io &&  r_dht11_io_dly0;


    assign w_dht11_dly0_r =  r_dht11_io_dly0 && ~r_dht11_io_dly1;
    assign w_dht11_dly0_f = ~r_dht11_io_dly0 &&  r_dht11_io_dly1;

    assign w_dht11_dly1_r =  r_dht11_io_dly1 && ~r_dht11_io_dly2;
    assign w_dht11_dly1_f = ~r_dht11_io_dly1 &&  r_dht11_io_dly2;

    assign w_dht11_dly2_r =  r_dht11_io_dly2 && ~r_dht11_io_dly3;
    assign w_dht11_dly2_f = ~r_dht11_io_dly2 &&  r_dht11_io_dly3;

    assign w_dht11_dly3_r =  r_dht11_io_dly3 && ~r_dht11_io_dly4;
    assign w_dht11_dly3_f = ~r_dht11_io_dly3 &&  r_dht11_io_dly4;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= 0;
        end
        else begin
            c_st <= n_st;
        end
    end

    always @ (*) begin
        n_st = c_st;
        case(n_st)

            IDLE    :   begin
                            if(i_start) begin
                                n_st = START;
                            end
                        end

            START   :   begin
                            if(w_start_done) begin
                                n_st = WAIT;
                            end
                        end

            WAIT    :   begin
                            if(w_wait_done) begin
//                                n_st = SYNC;
                                n_st = SYNC_L;
                            end
                        end

//            SYNC    :   begin
//                            if(w_dht11_dly0_f) begin
//                                n_st = SYNC_L;
//                            end
//                        end
            SYNC_L  :   begin
                            if(w_dht11_dly0_r) begin
                                n_st = SYNC_H;
                            end
                        end
            SYNC_H  :   begin
                            if(w_dht11_dly0_f) begin
                                n_st = DATA_S;
                            end
                        end

            DATA_S  :   begin
                            if(w_data_s_done) begin
                                n_st = DATA_C;
                            end
                        end
            
            DATA_C  :   begin
                            if(w_data_done) begin
                                n_st = STOP;
                            end
                            else if(w_dht11_dly0_f) begin
                                n_st = DATA_S;
                            end
                        end

            STOP    :   begin
                            if(w_stop_done) begin
                                n_st = IDLE;
                            end
                        end
                    
        
        endcase
    end

            




endmodule



module tick_gen_1us(

    input   clk,
    input   rst,
    
    output  o_tick_1us

    );

    reg [06:00] clk_cnt;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            clk_cnt <= 7'd0;
        end
        else if(clk_cnt >= 7'd99) begin
            clk_cnt <= 7'd0;
        end
        else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    assign o_tick_1us = (clk_cnt == 7'd99) ? 1'b1 : 1'b0;


endmodule


