`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/06 11:32:45
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(

    input                    clk,
    input                    rst,
    input                    rx,
    input                    b_tick,

    output  reg              rx_start,
    output  reg  [07:00]     rx_data,
    output  reg              rx_done

);

    localparam IDLE = 2'd0,  START = 2'd1, BIT = 2'd2, STOP = 2'd3;


    reg [01:00]     c_st, n_st;

    reg [04:00]     tick_cnt;
    reg [02:00]     b_cnt;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            rx_start <= 1'b0;
        end
        else if((c_st == IDLE) && !rx && b_tick) begin
            rx_start <= 1'b1;
        end
        else begin
            rx_start <= 1'b0;
        end
    end



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tick_cnt <= 5'd0;
        end
        else if((c_st == START) && tick_cnt == 5'd7 && b_tick) begin
            tick_cnt <= 5'd0;
        end
        else if((c_st == STOP) && tick_cnt == 5'd15 && b_tick) begin
            tick_cnt <= 5'd0;
        end
        else if((c_st == BIT) && tick_cnt == 5'd15 && b_tick) begin
            tick_cnt <= 5'd0;
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
            b_cnt <= 3'd0;
        end
        else if ((c_st == BIT) && tick_cnt == 4'd15 && b_tick) begin
            b_cnt <= b_cnt + 1'b1;
        end
        else begin
            b_cnt <= b_cnt;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            rx_data <= 8'd0;
        end
        else if((c_st == BIT) && tick_cnt == 4'd15 && b_tick) begin
            rx_data <= {rx,rx_data[07:01]};
        end
        else begin
            rx_data <= rx_data;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            rx_done <= 1'b0;
        end
        else if((c_st == STOP) && tick_cnt == 5'd15 && b_tick) begin
            rx_done <= 1'b1;
        end
        else begin
            rx_done <= 1'b0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= IDLE;
        end
        else begin
            c_st <= n_st;
        end
    end
    
    always @ (*) begin
        n_st = c_st;
        case(c_st)
            IDLE : begin
                        if(b_tick & !rx) begin
                            n_st = START;
                        end
                    end
            START : begin
                        if(b_tick & (tick_cnt == 5'd7)) begin
                            n_st = BIT;
                        end
                    end
            BIT :   begin
                        if(tick_cnt == 4'd15 && b_cnt == 3'd7 && b_tick) begin
                            n_st = STOP;
                        end
                            
                    end
            STOP :  begin
                        if(tick_cnt == 5'd15 && b_tick) begin
                            n_st = IDLE;
                        end
                    end

        endcase
    end


endmodule
