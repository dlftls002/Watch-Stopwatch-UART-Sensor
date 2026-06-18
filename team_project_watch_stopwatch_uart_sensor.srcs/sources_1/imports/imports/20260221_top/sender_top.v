`timescale 1ns / 1ps

module sender_top (
    input i_clk,
    input i_reset,

    input       i_start,
    input [1:0] i_sel,
    input [1:0] i_sel_2,
    input [3:0] i_data_1000,
    input [3:0] i_data_100,
    input [3:0] i_data_10,
    input [3:0] i_data_1,

    //FIFO interface
    input        i_fifo_full,
    output       o_fifo_push,
    output [7:0] o_fifo_push_data
);

    reg start_d;
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            start_d <= 1'b0;
        end else begin
            start_d <= i_start;
        end
    end
    assign start_pulse = i_start & ~start_d;

    // 10진수 → ASCII 변환
    wire [7:0] d1000 = i_data_1000 + 8'h30;
    wire [7:0] d100 = i_data_100 + 8'h30;
    wire [7:0] d10 = i_data_10 + 8'h30;
    wire [7:0] d1 = i_data_1 + 8'h30;

    // 문자 인덱스
    reg [4:0] char_index;
    reg [4:0] msg_len;

    // message 배열
    reg [7:0] message[0:20];

    integer i;

    always @(*) begin
        // 기본값
        msg_len = 0;
        for (i = 0; i <= 20; i = i + 1) begin
            message[i] = 8'd0;
        end

        case (i_sel)
            2'b00: begin  //시계
                casez (i_sel_2)
                    2'b0?: begin
                        msg_len = 13;
                        // time=00s00ms + LF
                        message[0] = "t";
                        message[1] = "i";
                        message[2] = "m";
                        message[3] = "e";
                        message[4] = "=";
                        message[5] = d1000;
                        message[6] = d100;
                        message[7] = "s";
                        message[8] = d10;
                        message[9] = d1;
                        message[10] = "m";
                        message[11] = "s";
                        message[12] = 8'd10;
                    end
                    2'b1?: begin
                        msg_len = 12;
                        // time=00h00m + LF
                        message[0] = "t";
                        message[1] = "i";
                        message[2] = "m";
                        message[3] = "e";
                        message[4] = "=";
                        message[5] = d1000;
                        message[6] = d100;
                        message[7] = "h";
                        message[8] = d10;
                        message[9] = d1;
                        message[10] = "m";
                        message[11] = 8'd10;
                    end
                endcase
            end
            2'b01: begin  //스톱워치
                casez (i_sel_2)
                    2'b0?: begin
                        msg_len = 17;
                        // stop_time=MM:SS + LF
                      //  message[0] = "s";
                      //  message[1] = 8'd46;
                      //  message[2] = "p";
                      //  message[3] = 8'd95;
                        message[0] = "s";
                        message[1] = "t";
                        message[2] = "o";
                        message[3] = "p";
                        message[4] = "t";
                        message[5] = "i";
                        message[6] = "m";
                        message[7] = "e";
                        message[8] = "=";
                        message[9] = d1000;
                        message[10] = d100;
                        message[11] = "s";
                        message[12] = d10;
                        message[13] = d1;
                        message[14] = "m";
                        message[15] = "s";
                        message[16] = 8'd10;
                    end

                    2'b1?: begin
                        msg_len = 16;
                        // stop_time=MM:SS + LF
                        message[0] = "s";
                        message[1] = "t";
                        message[2] = "o";
                        message[3] = "p";
                       // message[0] = "s";
                       // message[1] = 8'd46;
                       // message[2] = "p";
                       // message[3] = 8'd95;
                        message[4] = "t";
                        message[5] = "i";
                        message[6] = "m";
                        message[7] = "e";
                        message[8] = "=";
                        message[9] = d1000;
                        message[10] = d100;
                        message[11] = "h";
                        message[12] = d10;
                        message[13] = d1;
                        message[14] = "m";
                        message[15] = 8'd10;
                    end
                endcase
            end

            2'b10: begin  //거리
                msg_len = 17;
                // distanceXXX.Xcm + LF
                message[0] = "d";
                message[1] = "i";
                message[2] = "s";
                message[3] = "t";
                message[4] = "a";
                message[5] = "n";
                message[6] = "c";
                message[7] = "e";
                message[8] = "=";
                message[9] = d1000;
                message[10] = d100;
                message[11] = d10;
                message[12] = 8'd46;
                message[13] = d1;
                message[14] = "c";
                message[15] = "m";
                message[16] = 8'd10;
            end
            2'b11: begin  //온습도
                casez (i_sel_2)
                    2'b?0: begin
                        msg_len = 12;
                        // temp=XX.XXC + LF
                        message[0] = "t";
                        message[1] = "e";
                        message[2] = "m";
                        message[3] = "p";
                        message[4] = "=";
                        message[5] = d1000;
                        message[6] = d100;
                        message[7] = 8'd46;
                        message[8] = d10;
                        message[9] = d1;
                        message[10] = 8'd67;
                        message[11] = 8'd10;
                    end
                    2'b?1: begin
                        msg_len     = 12;
                        // humid=00:00 + LF
                        message[0]  = "h";
                        message[1]  = "u";
                        message[2]  = "m";
                        message[3]  = "i";
                        message[4]  = "d";
                        message[5]  = "=";
                        message[6]  = d1000;
                        message[7]  = d100;
                        message[8]  = 8'd46;
                        message[9]  = d10;
                        message[10] = d1;
                        message[11] = 8'd10;
                    end
                endcase
            end
        endcase
    end

    //FSM state
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;

    reg [1:0] c_state, n_state;
    reg       r_fifo_push;
    reg [7:0] r_fifo_push_data;

    assign o_fifo_push      = r_fifo_push;
    assign o_fifo_push_data = r_fifo_push_data;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            IDLE: begin
                if (start_pulse) begin
                    n_state = SEND;
                end
            end
            SEND: begin
                if (!i_fifo_full) begin
                    // 마지막 문자 보내는 순간에 IDLE로 전이
                    if (char_index == msg_len - 1) begin
                        n_state = IDLE;
                    end
                end else begin
                    n_state = WAIT;
                end
            end

            WAIT: begin
                if (!i_fifo_full) begin
                    if (char_index == msg_len - 1) n_state = IDLE;
                    else n_state = SEND;
                end
            end
        endcase
    end


    // PUSH signal send to FIFO (순차 논리)
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            char_index       <= 0;
            r_fifo_push      <= 0;
            r_fifo_push_data <= 8'd0;
        end else begin
            r_fifo_push <= 0;
            case (c_state)
                IDLE: begin
                    char_index  <= 0;
                    r_fifo_push <= 0;
                end

                SEND: begin
                    r_fifo_push <= 0;
                    if (!i_fifo_full && (char_index < msg_len)) begin
                        r_fifo_push <= 1;
                        r_fifo_push_data <= message[char_index];
                        char_index <= char_index + 1;
                    end

                end

                WAIT: begin
                    if (!i_fifo_full && (char_index < msg_len)) begin
                        r_fifo_push <= 1;
                        r_fifo_push_data <= message[char_index];
                        char_index <= char_index + 1;
                    end
                end
            endcase
        end
    end
endmodule
