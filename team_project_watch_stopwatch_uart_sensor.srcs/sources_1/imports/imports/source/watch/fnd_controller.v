`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/22 15:24:39
// Design Name: 
// Module Name: fnd_controller
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


module fnd_controller(

    input                   clk,
    input                   rst,
    input       [15:00]     i_fnd_data,
    input       [03:00]     i_onoff,
    input                   i_dot,
    input       [01:00]     i_dot_sel,


    output      [03:00]     o_fnd_digit,
    output      [07:00]     o_fnd_data


    );



//    wire        [03:00]      w_digit_1;
//    wire        [03:00]      w_digit_10;
//    wire        [03:00]      w_digit_100;
//    wire        [03:00]      w_digit_1000;

    wire        [02:00]      w_cnt8_digit_sel;
    wire                     w_clk_div_1khz;




    wire        [03:00]      w_data;

    wire [03:00]  w_1_onoff   ; 
    wire [03:00]  w_10_onoff   ;
    wire [03:00]  w_100_onoff   ;   
    wire [03:00]  w_1000_onoff ;

//    assign  o_time_data = {w_digit_hour_10, w_digit_hour_1, w_digit_min_10, w_digit_min_1,
//                           w_digit_sec_10, w_digit_sec_1, w_digit_msec_10, w_digit_msec_1};






    clk_div U_CLK_DIV (

        .clk        (clk),
        .rst        (rst),
        .o_1khz     (w_clk_div_1khz)
    );


    counter_8 U_COUNTER_4 (

    .clk        (w_clk_div_1khz),
    .rst        (rst),
    .o_digit_sel  (w_cnt8_digit_sel)
    );


    decoder_2x4 U_DECODER_2x4(

    .i_digit_sel(w_cnt8_digit_sel[01:00]),
    .o_fnd_digit(o_fnd_digit)

);



 




    wire    test;
    wire    test2;

    assign test  = (i_dot_sel == 2'b10) ? i_dot : 1'b1;
    
    assign test2 = (i_dot_sel != 2'b10) ? i_dot : 1'b1;

    


    assign  w_1_onoff    = (i_onoff[0] && i_dot ) ? 4'b1111 : i_fnd_data[03:00];
    assign  w_10_onoff   = (i_onoff[1] && i_dot ) ? 4'b1111 : i_fnd_data[07:04];
    assign  w_100_onoff  = (i_onoff[2] && i_dot ) ? 4'b1111 : i_fnd_data[11:08];
    assign  w_1000_onoff = (i_onoff[3] && i_dot ) ? 4'b1111 : i_fnd_data[15:12];


    mux_8x1 U_MUX_MIN_HOUR(

    .i_sel            (w_cnt8_digit_sel     ),
    .i_digit_1        (w_1_onoff     ),
    .i_digit_10       (w_10_onoff     ),
    .i_digit_100      (w_100_onoff     ),
    .i_digit_1000     (w_1000_onoff     ),
    .i_digit_dot_1    (4'hf                 ),
    .i_digit_dot_10   ({3'b111, test}                ),
    .i_digit_dot_100  ({3'b111, test2}),
    .i_digit_dot_1000 (4'hf                 ),

    .mux_out          (w_data   )
    
    );


    bcd U_BCD (
        .bcd        (w_data),
        .o_fnd_data   (o_fnd_data)
    );



endmodule


module counter_8(

    input               clk,
    input               rst,
    
    output   [02:00]     o_digit_sel
);

    reg     [03:00]     counter_r;

    assign  o_digit_sel = counter_r;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            counter_r <= 3'd0;
        end
        else begin
            counter_r <= counter_r + 1'b1;
        end
    end


endmodule

module decoder_2x4 (

    input           [01:00]     i_digit_sel,
    output reg      [03:00]     o_fnd_digit

);

    always @ (i_digit_sel) begin
        case(i_digit_sel)
            2'b00 : o_fnd_digit = 4'b1110;
            2'b01 : o_fnd_digit = 4'b1101;
            2'b10 : o_fnd_digit = 4'b1011;
            2'b11 : o_fnd_digit = 4'b0111;
        endcase
    end
    
endmodule
                



module mux_8x1(

    input       [02:00]     i_sel,
    input       [03:00]     i_digit_1,
    input       [03:00]     i_digit_10,
    input       [03:00]     i_digit_100,
    input       [03:00]     i_digit_1000,
    input       [03:00]     i_digit_dot_1,
    input       [03:00]     i_digit_dot_10,
    input       [03:00]     i_digit_dot_100,
    input       [03:00]     i_digit_dot_1000,

    output reg  [03:00]     mux_out

);

    always @ (*) begin
        case(i_sel)
            3'b000 : mux_out = i_digit_1;
            3'b001 : mux_out = i_digit_10;
            3'b010 : mux_out = i_digit_100;
            3'b011 : mux_out = i_digit_1000;
            3'b100 : mux_out = i_digit_dot_1;
            3'b101 : mux_out = i_digit_dot_10;
            3'b110 : mux_out = i_digit_dot_100;
            3'b111 : mux_out = i_digit_dot_1000;
        endcase
    end

endmodule


module bcd (
    
    input           [03:00]     bcd,
    output  reg     [07:00]     o_fnd_data      

);

    always @ (bcd) begin
        case(bcd)
            4'd0 : o_fnd_data = 8'hc0;
            4'd1 : o_fnd_data = 8'hf9;
            4'd2 : o_fnd_data = 8'ha4;
            4'd3 : o_fnd_data = 8'hb0;
            4'd4 : o_fnd_data = 8'h99;
            4'd5 : o_fnd_data = 8'h92;
            4'd6 : o_fnd_data = 8'h82;
            4'd7 : o_fnd_data = 8'hf8;
            4'd8 : o_fnd_data = 8'h80;
            4'd9 : o_fnd_data = 8'h90;
            4'd10 : o_fnd_data = 8'hff;
            4'd11 : o_fnd_data = 8'hff;
            4'd12 : o_fnd_data = 8'hff;
            4'd13 : o_fnd_data = 8'hff;
            4'd14 : o_fnd_data = 8'h7f;
            4'd15 : o_fnd_data = 8'hff;

            default : o_fnd_data = 8'hff;
        endcase
    end

endmodule



module clk_div(
    input           clk,
    input           rst,
    output   reg    o_1khz
);

    reg   [16:00]   counter_r;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            counter_r <= 17'd0;
        end
        else if(counter_r == 17'd99999) begin
            counter_r <= 17'd0;
        end 
        else begin
            counter_r <= counter_r + 1'b1;
        end
    end        

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            o_1khz <= 1'b0;
        end
        else if(counter_r == 17'd99999) begin
            o_1khz <= 1'b1;
        end
        else begin
            o_1khz <= 1'b0;
        end
    end
    

endmodule

