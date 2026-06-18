`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/05 10:22:43
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(

    input               clk,
    input               rst,
    input               tx_start,
    input               b_tick,
    input   [07:00]     tx_data,
//    input               i_tx_start,
//    input   [07:00]     i_tx_data,
    

    output  [01:00]     o_debug_state,
    output              o_debug_tx_start,
    output  [07:00]     o_debug_tx_data,
    output              o_debug_tx_done,
    output  [04:00]     o_debug_start_cnt,

    output  reg         tx_done,
    output  reg         tx_busy,
    output              uart_tx

    );



    localparam IDLE = 2'd0,  START = 2'd1, BIT = 2'd2, STOP = 2'd3;

    reg [01:00]     c_st;
    reg [01:00]     n_st;
    reg [01:00]     tx_reg;
    reg [01:00]     tx_next;

    reg [02:00]     b_cnt;

    reg [07:00]     data_in_buf;
    reg [03:00]     tick_cnt;

    reg [04:00]     start_cnt;

    wire    tick_flag;
    wire    tick_flag_b;

    assign o_debug_state = c_st;
    assign o_debug_tx_start = tx_start;
    assign o_debug_tx_data = data_in_buf;
    assign o_debug_tx_done = tx_done;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            start_cnt <= 5'd0;
        end
        else if(tx_start) begin
            start_cnt <= start_cnt + 1'b1;
        end
        else begin
            start_cnt <= start_cnt;
        end
    end

    assign o_debug_start_cnt = start_cnt;

    assign  uart_tx = tx_reg;

    assign tick_flag = (tick_cnt == 4'd15 && b_tick) ? 1'b1 : 1'b0;
 
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tick_cnt <= 4'd0;
        end
        else if((c_st != IDLE) && b_tick) begin
            tick_cnt <= tick_cnt + 1'b1;
        end
        else begin
            tick_cnt <= tick_cnt;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= IDLE;
            tx_reg <= 1'b1;
        end
        else begin
            c_st <= n_st;
            tx_reg <= tx_next;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_cnt <= 3'd0;
        end
        else if((c_st == BIT) && tick_flag) begin
            b_cnt <= b_cnt + 1'b1;
        end
        else begin
            b_cnt <= b_cnt;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tx_busy <= 1'b0;
        end
        else if(tx_start) begin
            tx_busy <= 1'b1;
        end
        else if(c_st == STOP && b_tick) begin
            tx_busy <= 1'b0;
        end
        else begin
            tx_busy <= tx_busy;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tx_done <= 1'b0;
        end
        else if(c_st == STOP && tick_flag) begin
            tx_done <= 1'b1;
        end
        else begin
            tx_done <= 1'b0;
        end
    end



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            data_in_buf <= 8'd0;
        end
        else if(tx_start) begin
            data_in_buf <= tx_data;
        end
        else if(c_st == BIT && tick_flag)begin
            data_in_buf <= data_in_buf >> 1;
        end
        else begin
            data_in_buf <= data_in_buf;
        end
    end  






    always @ (*) begin
        n_st = c_st;
        tx_next = tx_reg;
        case(n_st)
            IDLE    :   begin
                            tx_next = 1'b1;
                            if(tx_start) begin
                                n_st = START;
                            end
                        end

            START   :   begin
                            tx_next = 1'b0;
                            if(tick_flag) begin
                                n_st = BIT;
                            end
                        end

            BIT     :   begin
                            tx_next = data_in_buf[0];
                            if(b_cnt == 3'd7 && tick_flag) begin
                                n_st = STOP;
                            end
                            else if(tick_flag) begin
                                n_st = BIT;
                            end
                                
                        end

            STOP    :   begin
                            tx_next = 1'b1;
                            if(tick_flag) begin
                                n_st = IDLE;
                            end
                        end
        endcase
    end


        
endmodule
