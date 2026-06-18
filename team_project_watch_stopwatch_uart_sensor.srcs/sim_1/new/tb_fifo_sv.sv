`timescale 1ns / 1ps

interface fifo_interface (
    input logic clk
);
    logic       rst;
    logic       i_push;
    logic       i_pop;
    logic [7:0] i_push_data;

    logic [7:0] o_pop_data;
    logic       o_empty;
    logic       o_full;

endinterface

class transaction;
    rand bit       i_push;
    rand bit       i_pop;
    rand bit [7:0] i_push_data;

    logic    [7:0] o_pop_data;
    logic          o_empty;
    logic          o_full;

    function void display(string name);
        $display(
            "%t : [%s] push = %h, push_data = %2h, full = %h, pop = %h, pop_data = %2h, empty = %h",
            $time, name, i_push, i_push_data, o_full, i_pop, o_pop_data,
            o_empty);
    endfunction
endclass

class generater;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        // // 1. Full
        // repeat (16) begin
        //     tr = new();
        //     // i_push = 1, i_pop = 0
        //     tr.randomize() with {
        //         i_push == 1'b1;
        //         i_pop == 1'b0;
        //     };
        //     gen2drv_mbox.put(tr);
        //     tr.display("GEN");
        //     @(gen_next_ev);
        // end

        // // 2. Empty
        // repeat (16) begin
        //     tr = new();
        //     // i_push = 0, i_pop = 1
        //     tr.randomize() with {
        //         i_push == 1'b0;
        //         i_pop == 1'b1;
        //     };
        //     gen2drv_mbox.put(tr);
        //     tr.display("GEN");
        //     @(gen_next_ev);
        // end

        // 3. randomize
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("GEN");
            @(gen_next_ev);
        end

    endtask  //run(int run_count)

endclass

class driver;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task preset();
        fifo_if.rst         = 1;
        fifo_if.i_push      = 0;
        fifo_if.i_pop       = 0;
        fifo_if.i_push_data = 0;
        @(negedge fifo_if.clk);
        @(negedge fifo_if.clk);
        fifo_if.rst = 0;
        @(negedge fifo_if.clk);
        // assertion
    endtask

    task push();
        fifo_if.i_push    = tr.i_push;
        fifo_if.i_push_data = tr.i_push_data;
        fifo_if.i_pop    = tr.i_pop;
    endtask  //push()

    task pop();
        fifo_if.i_push    = tr.i_push;
        fifo_if.i_push_data = tr.i_push_data;
        fifo_if.i_pop    = tr.i_pop;
    endtask  //pop()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_if.clk);
            #1;
            tr.display("DRV");
            if (tr.i_push) push();
            else fifo_if.i_push = 0;
            if (tr.i_pop) pop();
            else fifo_if.i_pop = 0;
        end
    endtask  //run()

    // task run();
    //     forever begin
    //         gen2drv_mbox.get(tr);
    //         @(posedge fifo_if.clk);

    //         fifo_if.i_push      <= tr.i_push;
    //         fifo_if.i_pop       <= tr.i_pop;
    //         fifo_if.i_push_data <= tr.i_push_data;

    //         tr.display("DRV");
    //     end
    // endtask  //run()

endclass

class monitor;
    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task run();
        forever begin
            tr = new();
            @(negedge fifo_if.clk);
            tr.i_push    = fifo_if.i_push;
            tr.i_pop    = fifo_if.i_pop;
            tr.i_push_data = fifo_if.i_push_data;
            tr.o_pop_data = fifo_if.o_pop_data;
            tr.o_full  = fifo_if.o_full;
            tr.o_empty = fifo_if.o_empty;
            tr.display("MON");
            mon2scb_mbox.put(tr);
        end
    endtask  //run()

endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    logic [7:0] fifo_queue[$];
    logic [7:0] compare_data;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("SCB");
            // push
            if (tr.i_push & (!tr.o_full)) begin
                fifo_queue.push_front(tr.i_push_data);
            end
            if (tr.i_pop & (!tr.o_empty)) begin
                // pass, fail
                compare_data = fifo_queue.pop_back();
                if (compare_data == tr.o_pop_data) begin
                    $display("Pass");
                end else begin
                    $display("Fail");
                end
            end
            ->gen_next_ev;
        end
    endtask
endclass

class environment;
    generater              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  gen_next_ev;

    function new(virtual fifo_interface fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, fifo_if);
        mon = new(mon2scb_mbox, fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        drv.preset();
        fork
            gen.run(10000);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $stop;
    endtask  //run()
endclass

module tb_fifo_sv ();
    logic clk;
    fifo_interface fifo_if (clk);
    environment env;

    fifo dut (
        .i_clk      (clk),
        .i_reset    (fifo_if.rst),
        .i_push     (fifo_if.i_push),
        .i_pop      (fifo_if.i_pop),
        .i_push_data(fifo_if.i_push_data),
        .o_pop_data (fifo_if.o_pop_data),
        .o_empty    (fifo_if.o_empty),
        .o_full     (fifo_if.o_full)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(fifo_if);
        env.run();
    end

endmodule
