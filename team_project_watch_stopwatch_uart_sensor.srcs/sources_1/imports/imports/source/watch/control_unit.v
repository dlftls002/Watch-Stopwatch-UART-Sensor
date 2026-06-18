`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/29 16:16:13
// Design Name: 
// Module Name: control_unit
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


module control_unit(

    input               clk,
    input               rst,
    
    input   [05:00]     i_mode,
    input               i_btn_r,
    input               i_btn_l,

    output  [05:00]     o_mode,
    output              o_run_stop,
    output              o_clear,
    output              o_sr04,
    output              o_dht11,
    output              o_sec_1,
    output              o_sec_10,
    output              o_min_1,
    output              o_min_10,
    output              o_hour_1,
    output              o_hour_10

    );

    localparam STOP = 4'b0000, RUN = 4'b0001, CLEAR = 4'b0010,
               SEC_1 = 4'b0011, SEC_10 = 4'b0100, MIN_1 = 4'b0101, MIN_10 = 4'b0110 ,HOUR_1 = 4'b0111, HOUR_10 = 4'b1000,
               SR04 = 4'b1001, DHT11 = 4'b1010;
               

    reg     [03:00]     current_state;
    reg     [03:00]     next_state;

    assign o_mode = i_mode;

    assign o_clear    = (current_state == CLEAR) ? 1'b1 : 1'b0;
    assign o_run_stop = (current_state == RUN  ) ? 1'b1 : 1'b0;
    assign o_sr04     = (current_state == SR04) ? 1'b1 : 1'b0;
    assign o_dht11    = (current_state == DHT11) ? 1'b1 : 1'b0;

    assign o_sec_1   =    (current_state == SEC_1  ) ? 1'b1 : 1'b0;
    assign o_sec_10  =    (current_state == SEC_10 ) ? 1'b1 : 1'b0;
    assign o_min_1   =    (current_state == MIN_1  ) ? 1'b1 : 1'b0;
    assign o_min_10  =    (current_state == MIN_10 ) ? 1'b1 : 1'b0;
    assign o_hour_1  =    (current_state == HOUR_1 ) ? 1'b1 : 1'b0;
    assign o_hour_10 =    (current_state == HOUR_10) ? 1'b1 : 1'b0;



    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            current_state <= STOP;
        end
        else begin
            current_state <= next_state;
        end
    end


   wire     stopwatch_mode;
   wire     watch_mode;
   wire     dht11_mode;
   wire     sr04_mode;


   assign stopwatch_mode = ~i_mode[1] && ~i_mode[4] &&  i_mode[0];
   assign watch_mode     = ~i_mode[1] &&  i_mode[4] && ~i_mode[0];
   assign dht11_mode     =  i_mode[1] && ~i_mode[4] &&  i_mode[0];
   assign sr04_mode      =  i_mode[1] && ~i_mode[4] && ~i_mode[0];
    
    
    always @ (*) begin
        next_state = current_state;
        case(current_state) 
            STOP :  begin
                        if(i_mode[4]) begin
                            next_state = SEC_1;
                        end
                        else if(i_btn_r && stopwatch_mode) begin
                            next_state = RUN;
                        end
                        else if(i_btn_l && stopwatch_mode) begin
                            next_state = CLEAR;
                        end
                        else if(i_btn_r && dht11_mode) begin
                            next_state = DHT11;
                        end
                        else if(i_btn_r && sr04_mode) begin
                            next_state = SR04;
                        end
                    end
            RUN :   begin
                        if(i_btn_r && stopwatch_mode) begin
                            next_state = STOP;
                        end
                    end
                
            CLEAR : next_state = STOP;

            DHT11 : next_state = STOP;

            SR04  : next_state = STOP;


            SEC_1 : begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = HOUR_10;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = SEC_10;
                        end
                    end

            SEC_10 :begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = SEC_1;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = MIN_1;
                        end
                    end

            MIN_1 : begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = SEC_10;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = MIN_10;
                        end
                    end

            MIN_10 :begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = MIN_1;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = HOUR_1;
                        end
                    end


            HOUR_1 :begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = MIN_10;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = HOUR_10;
                        end
                    end

            HOUR_10:begin
                        if(!i_mode[4]) begin
                            next_state = STOP;
                        end
                        else if(i_btn_r && watch_mode) begin
                            next_state = HOUR_1;
                        end
                        else if(i_btn_l && watch_mode) begin
                            next_state = SEC_1;
                        end
                    end

        endcase
    end
    
endmodule
