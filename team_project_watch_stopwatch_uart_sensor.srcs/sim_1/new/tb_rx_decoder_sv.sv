`timescale 1ns / 1ps

interface rx_interface (
    input logic clk
);

    logic       rst;
    logic       i_uart_rx;
    logic       o_rx_done;  //i_done
    logic       o_rx_start;  //i_start
    logic [7:0] o_rx_data;  //i_data
    logic       o_btn_r;
    logic       o_btn_l;
    logic       o_btn_u;
    logic       o_btn_d;
    logic       o_btn_0;
    logic       o_btn_1;
    logic       o_btn_2;
    logic       o_btn_3;
    logic       o_btn_4;
    logic       o_btn_5;
    logic       o_btn_s;

endinterface  //rx_interface

class transaction;
    logic [7:0] i_uart_data;
    
    logic          o_rx_done;  //i_done
    logic          o_rx_start;  //i_start
    logic    [7:0] o_rx_data;  //i_data
    logic          o_btn_r;
    logic          o_btn_l;
    logic          o_btn_u;
    logic          o_btn_d;
    logic          o_btn_0;
    logic          o_btn_1;
    logic          o_btn_2;
    logic          o_btn_3;
    logic          o_btn_4;
    logic          o_btn_5;
    logic          o_btn_s;

    function void display(string name);
        $display("%t : [%s] input data = %c (%h), rx_data = %h, done = %b",
            $time, name, i_uart_data, i_uart_data, o_rx_data, o_rx_done);
    endfunction  //new()

endclass  //transaction

class generater;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_count);
        // ascii data
        logic [7:0] test_chars[11] = '{8'h72, 8'h6C, 8'h75, 8'h64, 8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h73};
        
        for (int i = 0; i < run_count; i++) begin
            tr = new();
            tr.i_uart_data = test_chars[i];
            tr.display("GEN");
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end
    endtask  //run(int run_count)

endclass  //generater

class driver;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual rx_interface   rx_if;

    // uart speed setting
    // 100,000,000 / 9600 = 10416 clk cycles per bit
    localparam bit_period = 10416;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual rx_interface rx_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.rx_if        = rx_if;
    endfunction  //new()

    task run();
        rx_if.i_uart_rx = 1'b1; // Idle
        forever begin
            gen2drv_mbox.get(tr);
            tr.display("DRV");
            
            // 1. Start Bit
            rx_if.i_uart_rx = 1'b0;
            repeat (bit_period) @(posedge rx_if.clk);

            // 2. Data Bit (LSB First)
            for (int i = 0; i < 8; i++) begin
                rx_if.i_uart_rx = tr.i_uart_data[i];
                repeat (bit_period) @(posedge rx_if.clk);
            end

            // 3. Stop Bit
            rx_if.i_uart_rx = 1'b1;
            repeat (bit_period) @(posedge rx_if.clk);
            repeat (bit_period) @(posedge rx_if.clk);
        end
    endtask

endclass  //driver

class monitor;
    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual rx_interface   rx_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual rx_interface rx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.rx_if        = rx_if;
    endfunction  //new()

    task run();
        forever begin
            // wait done signal
            @(posedge rx_if.o_rx_done);
            tr            = new();
            tr.o_rx_start = rx_if.o_rx_start;
            tr.o_rx_done  = rx_if.o_rx_done;
            tr.o_rx_data  = rx_if.o_rx_data;

            // btn r ~ s(pulse)
            @(posedge rx_if.clk); 
            #1; 
            tr.o_btn_r    = rx_if.o_btn_r;
            tr.o_btn_l    = rx_if.o_btn_l;
            tr.o_btn_u    = rx_if.o_btn_u;
            tr.o_btn_d    = rx_if.o_btn_d;
            tr.o_btn_s    = rx_if.o_btn_s;

            // btn 0 ~ 5 (toggle)
            @(posedge rx_if.clk); 
            #1;
            tr.o_btn_0    = rx_if.o_btn_0;
            tr.o_btn_1    = rx_if.o_btn_1;
            tr.o_btn_2    = rx_if.o_btn_2;
            tr.o_btn_3    = rx_if.o_btn_3;
            tr.o_btn_4    = rx_if.o_btn_4;
            tr.o_btn_5    = rx_if.o_btn_5;
            tr.display("MON");
            mon2scb_mbox.put(tr);
        end
    endtask  //run()

endclass  //monitor

class scoreboard;
    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    event                  gen_next_ev;

    logic [7:0] compare_data[11] = '{8'h72, 8'h6C, 8'h75, 8'h64, 8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h73};
    int         count = 0;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("SCB");
            
            $display("----------------------------------------------------");
            $display("[SCOREBOARD] Scenario %0d/11", count + 1);
            $display(" - COMPARE DATA : 8'h%h (%c)", compare_data[count], compare_data[count]);
            $display(" - INPUT DATA   : 8'h%h (%c)", tr.o_rx_data, tr.o_rx_data);
            
            // 1. check input data match
            if (tr.o_rx_data === compare_data[count])
                $display(" -> RX Data Match : PASS");
            else
                $display(" -> RX Data Match : FAIL");

            // 2. check decoded btn signal
            check_button_status(tr, compare_data[count]);

            $display("====================================================\n");
            
            count++;
            ->gen_next_ev;
        end
    endtask  //run()

    function void check_button_status(transaction t, logic [7:0] exp_data);
        bit is_pass = 0;
        string active_btn = "None";

        case (exp_data)
            8'h72: if (t.o_btn_r) begin is_pass = 1; active_btn = "o_btn_r (Pulse)"; end
            8'h6C: if (t.o_btn_l) begin is_pass = 1; active_btn = "o_btn_l (Pulse)"; end
            8'h75: if (t.o_btn_u) begin is_pass = 1; active_btn = "o_btn_u (Pulse)"; end
            8'h64: if (t.o_btn_d) begin is_pass = 1; active_btn = "o_btn_d (Pulse)"; end
            8'h73: if (t.o_btn_s) begin is_pass = 1; active_btn = "o_btn_s (Pulse)"; end
            8'h30: if (t.o_btn_0) begin is_pass = 1; active_btn = "o_btn_0 (Toggle 0->1)"; end
            8'h31: if (t.o_btn_1) begin is_pass = 1; active_btn = "o_btn_1 (Toggle 0->1)"; end
            8'h32: if (t.o_btn_2) begin is_pass = 1; active_btn = "o_btn_2 (Toggle 0->1)"; end
            8'h33: if (t.o_btn_3) begin is_pass = 1; active_btn = "o_btn_3 (Toggle 0->1)"; end
            8'h34: if (t.o_btn_4) begin is_pass = 1; active_btn = "o_btn_4 (Toggle 0->1)"; end
            8'h35: if (t.o_btn_5) begin is_pass = 1; active_btn = "o_btn_5 (Toggle 0->1)"; end
        endcase

        if (is_pass)
            $display(" -> Button Decode : PASS (Changed signal: %s)", active_btn);
        else
            $display(" -> Button Decode : FAIL (Expected active button for %c but none asserted)", exp_data);
    endfunction

endclass  //scoreboard

class environment;
    generater              gen;
    monitor                mon;
    driver                 drv;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  gen_next_ev;

    function new(virtual rx_interface rx_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, rx_if);
        mon = new(mon2scb_mbox, rx_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        fork
            gen.run(11);
            drv.run();
            mon.run();
            scb.run();
        join_any

        // Drain Time
        #520000;

        $display("All 11 patterns tested successfully.");
        $stop;
    endtask  //run()

endclass  //environment

module tb_rx_decoder_sv ();

    logic clk;
    rx_interface rx_if (clk);
    environment env;

    uart_top U_UART_RX (
        .clk       (clk),
        .rst       (rx_if.rst),
        .i_uart_rx (rx_if.i_uart_rx),
        .o_rx_done (rx_if.o_rx_done),
        .o_rx_start(rx_if.o_rx_start),
        .o_rx_data (rx_if.o_rx_data)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk    (clk),
        .rst    (rx_if.rst),
        .i_data (rx_if.o_rx_data),
        .i_start(rx_if.o_rx_start),
        .i_done (rx_if.o_rx_done),
        .o_btn_r(rx_if.o_btn_r),
        .o_btn_l(rx_if.o_btn_l),
        .o_btn_u(rx_if.o_btn_u),
        .o_btn_d(rx_if.o_btn_d),
        .o_btn_0(rx_if.o_btn_0),
        .o_btn_1(rx_if.o_btn_1),
        .o_btn_2(rx_if.o_btn_2),
        .o_btn_3(rx_if.o_btn_3),
        .o_btn_4(rx_if.o_btn_4),
        .o_btn_5(rx_if.o_btn_5),
        .o_btn_s(rx_if.o_btn_s)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rx_if.rst = 1;
        #100 rx_if.rst = 0;
        env = new(rx_if);
        env.run();
    end

endmodule
