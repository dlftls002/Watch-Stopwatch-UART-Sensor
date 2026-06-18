`timescale 1ns / 1ps

interface fifo_interface (
    input logic clk
);
    logic       rst;
    logic       we;
    logic       re;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       empty;
    logic       full;

endinterface  //fifo_interface

class transaction;

    
    function new();
        
    endfunction //new()
endclass //transaction

module tb_uart_fifo_sv ();

    logic clk;
    fifo_interface fifo_if;

    fifo dut (
        .i_clk      (clk),
        .i_reset    (fifo_if.rst),
        .i_push     (fifo_if.we),
        .i_pop      (fifo_if.re),
        .i_push_data(fifo_if.wdata),
        .o_pop_data (fifo_if.rdata),
        .o_empty    (fifo_if.empty),
        .o_full     (fifo_if.full)
    );

    always #5 clk = ~clk;

endmodule
