`timescale 1ns / 1ps



module btn_debounce(

    input   clk,
    input   rst,
    input   i_btn,

    output  o_btn

    );

    parameter   CLK_DIV = 100_000;
    parameter   F_COUNT = 100_000_000;


    reg [09:00] r_counter;
    reg         r_clk_100khz;    
    reg [07:00] r_debounce;
    reg         r_debounce_dly0;

    wire        w_debounce;

    assign w_debounce = &r_debounce;
    assign o_btn = w_debounce && ~r_debounce_dly0;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_counter <= 10'd0;
        end
        else if(r_counter == 10'd999) begin
            r_counter <= 10'd0;
        end
        else begin
            r_counter <= r_counter + 1'b1;
        end
    end
    
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_clk_100khz <= 1'b0;
        end
        else if(r_counter == 10'd999) begin
            r_clk_100khz <= 1'b1;
        end
        else begin
            r_clk_100khz <= 1'b0;
        end
    end

    always @ (posedge r_clk_100khz or posedge rst) begin
        if(rst) begin
            r_debounce <= 8'd0;
        end
        else begin
            r_debounce <= {i_btn, r_debounce[07:01]};
        end
    end
    
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            r_debounce_dly0 <= 1'b0;
        end
        else begin
            r_debounce_dly0 <= w_debounce;
        end
    end



endmodule
