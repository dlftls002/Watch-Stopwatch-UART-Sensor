`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/07 15:22:48
// Design Name: 
// Module Name: atscii2dec
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


module ascii_decoder(


    input               clk,
    input               rst,
    input   [07:00]     i_data,
    input               i_start,
    input               i_done,

    output              o_btn_r,
    output              o_btn_l,
    output              o_btn_u,
    output              o_btn_d,
    output              o_btn_0,
    output              o_btn_1,
    output              o_btn_2,
    output              o_btn_3,
    output              o_btn_4,
    output              o_btn_5,
    output              o_btn_s



    );

    reg [03:00]         r_tmp;
    reg                 r_btn_r_dly0;
    reg                 r_btn_l_dly0;
    reg                 r_btn_u_dly0;
    reg                 r_btn_d_dly0;
    reg                 r_btn_0_dly0;
    reg                 r_btn_1_dly0;
    reg                 r_btn_2_dly0;
    reg                 r_btn_3_dly0;
    reg                 r_btn_4_dly0;
    reg                 r_btn_5_dly0;
    reg                 r_btn_s_dly0;

    reg                 r_btn_0;
    reg                 r_btn_1;
    reg                 r_btn_2;
    reg                 r_btn_3;
    reg                 r_btn_4;
    reg                 r_btn_5;

    reg [07:00]         r_data;
    
    wire                w_btn_r;
    wire                w_btn_l;
    wire                w_btn_u;
    wire                w_btn_d;
    wire                w_btn_0;
    wire                w_btn_1;
    wire                w_btn_2;
    wire                w_btn_3;
    wire                w_btn_4;
    wire                w_btn_5;
    wire                w_btn_s;

    wire                w_btn_0_r;
    wire                w_btn_1_r;
    wire                w_btn_2_r;
    wire                w_btn_3_r;
    wire                w_btn_4_r;
    wire                w_btn_5_r;

//    assign o_s_en = w_btn_s;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_data <= 8'd0;
        end
        else if(i_start) begin
            r_data <= 8'd0;
        end
        else if(i_done) begin
            r_data <= i_data;
        end
        else begin
            r_data <= r_data;
        end
    end



    always @ (*) begin
        case(r_data)
            8'h72 : r_tmp = 4'd1;           //righjt
            8'h6C : r_tmp = 4'd2;           //left
            8'h75 : r_tmp = 4'd3;           //up
            8'h64 : r_tmp = 4'd4;           //down
            8'h30 : r_tmp = 4'd5;           //0
            8'h31 : r_tmp = 4'd6;           //1
            8'h32 : r_tmp = 4'd7;           //2
            8'h33 : r_tmp = 4'd8;           //3
            8'h73 : r_tmp = 4'd9;           //s : state, time
            8'h34 : r_tmp = 4'd10;          //4
            8'h35 : r_tmp = 4'd11;          //5
            
            default : r_tmp = 4'd0;
        endcase
    end

    assign w_btn_r = (r_tmp == 4'd1 ) ? 1'b1 : 1'b0;
    assign w_btn_l = (r_tmp == 4'd2 ) ? 1'b1 : 1'b0;
    assign w_btn_u = (r_tmp == 4'd3 ) ? 1'b1 : 1'b0;
    assign w_btn_d = (r_tmp == 4'd4 ) ? 1'b1 : 1'b0;
    assign w_btn_0 = (r_tmp == 4'd5 ) ? 1'b1 : 1'b0;
    assign w_btn_1 = (r_tmp == 4'd6 ) ? 1'b1 : 1'b0;
    assign w_btn_2 = (r_tmp == 4'd7 ) ? 1'b1 : 1'b0;
    assign w_btn_3 = (r_tmp == 4'd8 ) ? 1'b1 : 1'b0;
    assign w_btn_4 = (r_tmp == 4'd10) ? 1'b1 : 1'b0;
    assign w_btn_5 = (r_tmp == 4'd11) ? 1'b1 : 1'b0;
    assign w_btn_s = (r_tmp == 4'd9 ) ? 1'b1 : 1'b0;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_r_dly0 <= 1'b0;
            r_btn_l_dly0 <= 1'b0;
            r_btn_u_dly0 <= 1'b0;
            r_btn_d_dly0 <= 1'b0;
            r_btn_0_dly0 <= 1'b0;
            r_btn_1_dly0 <= 1'b0;
            r_btn_2_dly0 <= 1'b0;
            r_btn_3_dly0 <= 1'b0;
            r_btn_4_dly0 <= 1'b0;
            r_btn_5_dly0 <= 1'b0;
            r_btn_s_dly0 <= 1'b0;
        end
        else begin
            r_btn_r_dly0 <= w_btn_r;
            r_btn_l_dly0 <= w_btn_l;
            r_btn_u_dly0 <= w_btn_u;
            r_btn_d_dly0 <= w_btn_d;
            r_btn_0_dly0 <= w_btn_0; 
            r_btn_1_dly0 <= w_btn_1;
            r_btn_2_dly0 <= w_btn_2;
            r_btn_3_dly0 <= w_btn_3;
            r_btn_4_dly0 <= w_btn_4;
            r_btn_5_dly0 <= w_btn_5;
            r_btn_s_dly0 <= w_btn_s;
        end
    end



    assign o_btn_r = (w_btn_r && ~r_btn_r_dly0) ? 1'b1 : 1'b0;
    assign o_btn_l = (w_btn_l && ~r_btn_l_dly0) ? 1'b1 : 1'b0;
    assign o_btn_u = (w_btn_u && ~r_btn_u_dly0) ? 1'b1 : 1'b0;
    assign o_btn_d = (w_btn_d && ~r_btn_d_dly0) ? 1'b1 : 1'b0;
    assign o_btn_s = (w_btn_s && ~r_btn_s_dly0) ? 1'b1 : 1'b0;

    assign w_btn_0_r = (w_btn_0 && ~r_btn_0_dly0) ? 1'b1 : 1'b0;
    assign w_btn_1_r = (w_btn_1 && ~r_btn_1_dly0) ? 1'b1 : 1'b0;
    assign w_btn_2_r = (w_btn_2 && ~r_btn_2_dly0) ? 1'b1 : 1'b0;
    assign w_btn_3_r = (w_btn_3 && ~r_btn_3_dly0) ? 1'b1 : 1'b0;
    assign w_btn_4_r = (w_btn_4 && ~r_btn_4_dly0) ? 1'b1 : 1'b0;
    assign w_btn_5_r = (w_btn_5 && ~r_btn_5_dly0) ? 1'b1 : 1'b0;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_0 <= 1'b0;
        end
        else if(w_btn_0_r) begin
            r_btn_0 <= ~r_btn_0;
        end
        else begin
            r_btn_0 <= r_btn_0;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_1 <= 1'b0;
        end
        else if(w_btn_1_r) begin
            r_btn_1 <= ~r_btn_1;
        end
        else begin
            r_btn_1 <= r_btn_1;
        end
    end


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_2 <= 1'b0;
        end
        else if(w_btn_2_r) begin
            r_btn_2 <= ~r_btn_2;
        end
        else begin
            r_btn_2 <= r_btn_2;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_3 <= 1'b0;
        end
        else if(w_btn_3_r) begin
            r_btn_3 <= ~r_btn_3;
        end
        else begin
            r_btn_3 <= r_btn_3;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_4 <= 1'b0;
        end
        else if(w_btn_4_r) begin
            r_btn_4 <= ~r_btn_4;
        end
        else begin
            r_btn_4 <= r_btn_4;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_btn_5 <= 1'b0;
        end
        else if(w_btn_5_r) begin
            r_btn_5 <= ~r_btn_5;
        end
        else begin
            r_btn_5 <= r_btn_5;
        end
    end


    assign o_btn_0 = r_btn_0;
    assign o_btn_1 = r_btn_1;
    assign o_btn_2 = r_btn_2;
    assign o_btn_3 = r_btn_3;
    assign o_btn_4 = r_btn_4;
    assign o_btn_5 = r_btn_5;

    

endmodule