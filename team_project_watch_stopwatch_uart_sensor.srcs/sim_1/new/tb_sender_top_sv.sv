`timescale 1ns / 1ps

interface sender_interface (
    input logic clk
);
    logic       rst;
    logic       i_start;
    logic [1:0] i_sel;
    logic [1:0] i_sel_2;
    logic [3:0] i_data_1000;
    logic [3:0] i_data_100;
    logic [3:0] i_data_10;
    logic [3:0] i_data_1;

    // FIFO interface
    logic       i_fifo_full;
    logic       o_fifo_push;
    logic [7:0] o_fifo_push_data;

endinterface  //sender_interface

class transaction;

    rand bit [1:0] i_sel;
    rand bit [1:0] i_sel_2;
    rand bit [3:0] i_data_1000;
    rand bit [3:0] i_data_100;
    rand bit [3:0] i_data_10;
    rand bit [3:0] i_data_1;

    logic          i_fifo_full;
    logic          o_fifo_push;
    logic    [7:0] o_fifo_push_data;

    constraint c_data_range {
        i_data_1000 inside {[0 : 9]};
        i_data_100 inside {[0 : 9]};
        i_data_10 inside {[0 : 9]};
        i_data_1 inside {[0 : 9]};
    }

    function void display(string name);
        $display("%t : [%s] mode = %b (%b), data = %1d%1d%1d%1d", $time, name,
                 i_sel, i_sel_2, i_data_1000, i_data_100, i_data_10, i_data_1);
    endfunction  //new()

endclass  //transaction

class generater;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();

            gen2drv_mbox.put(tr);  // to driver
            gen2scb_mbox.put(tr);  // to Scoreboard for expected

            tr.display("GEN");
            @(gen_next_ev);
        end
    endtask
endclass

class driver;
    transaction              tr;
    mailbox #(transaction)   gen2drv_mbox;
    virtual sender_interface sender_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual sender_interface sender_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.sender_if    = sender_if;
    endfunction  //new()

    task preset();
        sender_if.rst         = 1;
        sender_if.i_start     = 0;
        sender_if.i_sel       = 0;
        sender_if.i_sel_2     = 0;
        sender_if.i_data_1000 = 0;
        sender_if.i_data_100  = 0;
        sender_if.i_data_10   = 0;
        sender_if.i_data_1    = 0;
        sender_if.i_fifo_full = 0;
        @(negedge sender_if.clk);
        @(negedge sender_if.clk);
        sender_if.rst = 0;
        @(negedge sender_if.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge sender_if.clk);
            tr.display("DRV");

            sender_if.i_sel       = tr.i_sel;
            sender_if.i_sel_2     = tr.i_sel_2;
            sender_if.i_data_1000 = tr.i_data_1000;
            sender_if.i_data_100  = tr.i_data_100;
            sender_if.i_data_10   = tr.i_data_10;
            sender_if.i_data_1    = tr.i_data_1;

            // i_start pulse
            sender_if.i_start <= 1'b1;
            @(posedge sender_if.clk);
            sender_if.i_start <= 1'b0;

            repeat (30) @(posedge sender_if.clk);
        end
    endtask
endclass

class monitor;
    transaction              tr;
    mailbox #(transaction)   mon2scb_mbox;
    virtual sender_interface sender_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual sender_interface sender_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.sender_if    = sender_if;
    endfunction

    task run();
        forever begin
            @(posedge sender_if.clk);

            // Capture only when SENDER completes a character and pushes it into the FIFO
            if (sender_if.o_fifo_push) begin
                tr = new();
                tr.o_fifo_push_data = sender_if.o_fifo_push_data;

                $display("%t : [MON] Captured Character = '%s' (8'h%h)", $time,
                         string'(tr.o_fifo_push_data), tr.o_fifo_push_data);

                mon2scb_mbox.put(tr);
            end
        end
    endtask
endclass  //monitor

class scoreboard;
    transaction gen_tr;
    transaction mon_tr;

    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_ev;

    string msg_string = "";

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) gen2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    // make expected string data
    function string get_expected_string(transaction t);
        string d1000, d100, d10, d1;

        // Convert 4-bit number to string
        d1000 = $sformatf("%0d", t.i_data_1000);
        d100  = $sformatf("%0d", t.i_data_100);
        d10   = $sformatf("%0d", t.i_data_10);
        d1    = $sformatf("%0d", t.i_data_1);

        case (t.i_sel)
            2'b00: begin  // watch
                if (t.i_sel_2[1] == 1'b0)
                    return {"time=", d1000, d100, "s", d10, d1, "ms"};
                else return {"time=", d1000, d100, "h", d10, d1, "m"};
            end
            2'b01: begin  // stopwatch
                if (t.i_sel_2[1] == 1'b0)
                    return {"stoptime=", d1000, d100, "s", d10, d1, "ms"};
                else return {"stoptime=", d1000, d100, "h", d10, d1, "m"};
            end
            2'b10: begin  // distance
                return {"distance=", d1000, d100, d10, ".", d1, "cm"};
            end
            2'b11: begin  // temp/humid
                if (t.i_sel_2[0] == 1'b0)
                    return {"temp=", d1000, d100, ".", d10, d1, "C"};
                else return {"humid=", d1000, d100, ".", d10, d1};
            end
            default: return "";
        endcase
    endfunction

    task run();
        string expected_string;

        forever begin
            gen2scb_mbox.get(gen_tr);  // Generator send data
            expected_string = get_expected_string(gen_tr);

            gen_tr.display("SCB");

            // Receive Monitor data until the msg is completed
            while (1) begin
                mon2scb_mbox.get(mon_tr);

                if (mon_tr.o_fifo_push_data != 8'd10) begin
                    msg_string = {msg_string, string'(mon_tr.o_fifo_push_data)};
                end else begin
                    break;
                end
            end

            if (msg_string == expected_string) begin
                $display(
                    "%t : [SCB-PASS] Match! \n - Expected : %s \n - Actual   : %s\n",
                    $time, expected_string, msg_string);
                $display(
                    "-------------------------------------------------------------");
            end else begin
                $display(
                    "%t : [SCB-FAIL] Mismatch! \n - Expected : %s \n - Actual   : %s\n",
                    $time, expected_string, msg_string);
                $display(
                    "-------------------------------------------------------------");
            end

            msg_string = "";
            ->gen_next_ev;
        end
    endtask
endclass

class environment;
    generater              gen;
    monitor                mon;
    driver                 drv;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;

    event                  gen_next_ev;

    function new(virtual sender_interface sender_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen2scb_mbox = new();

        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, sender_if);
        mon = new(mon2scb_mbox, sender_if);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_ev);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #500;

        $display("All simulations finished.");

        $stop;
    endtask  //run()

endclass  //environment

module tb_sender_top_sv ();

    logic clk;
    sender_interface sender_if (clk);
    environment env;

    sender_top U_SENDER (
        .i_clk      (clk),
        .i_reset    (sender_if.rst),
        .i_start    (sender_if.i_start),
        .i_sel      (sender_if.i_sel),
        .i_sel_2    (sender_if.i_sel_2),
        .i_data_1000(sender_if.i_data_1000),
        .i_data_100 (sender_if.i_data_100),
        .i_data_10  (sender_if.i_data_10),
        .i_data_1   (sender_if.i_data_1),

        //FIFO interface
        .i_fifo_full     (sender_if.i_fifo_full),
        .o_fifo_push     (sender_if.o_fifo_push),
        .o_fifo_push_data(sender_if.o_fifo_push_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        sender_if.rst = 1;
        #100 sender_if.rst = 0;
        env = new(sender_if);
        env.run();
    end

endmodule
