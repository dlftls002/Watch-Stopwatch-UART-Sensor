`timescale 1ns / 1ps

interface tx_interface (
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

    // FIFO monitoring
    logic       o_fifo_push;
    logic [7:0] o_fifo_push_data;

    // UART monitoring
    logic       o_uart_tx;
endinterface

class transaction;
    rand bit [1:0] i_sel;
    rand bit [1:0] i_sel_2;
    rand bit [3:0] i_data_1000;
    rand bit [3:0] i_data_100;
    rand bit [3:0] i_data_10;
    rand bit [3:0] i_data_1;

    string expected_string;

    constraint c_data_range {
        i_data_1000 inside {[0 : 9]};
        i_data_100 inside {[0 : 9]};
        i_data_10 inside {[0 : 9]};
        i_data_1 inside {[0 : 9]};
    }

    function void display(string name);
        $display("%t : [%s] mode = %b (%b), data = %1d%1d%1d%1d", $time, name,
                 i_sel, i_sel_2, i_data_1000, i_data_100, i_data_10, i_data_1);
    endfunction
endclass

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
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            tr.display("GEN");
            @(gen_next_ev);
        end
    endtask
endclass

class driver;
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual tx_interface   tx_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual tx_interface tx_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.tx_if        = tx_if;
    endfunction

    task preset();
        tx_if.rst         = 1;
        tx_if.i_start     = 0;
        tx_if.i_sel       = 0;
        tx_if.i_sel_2     = 0;
        tx_if.i_data_1000 = 0;
        tx_if.i_data_100  = 0;
        tx_if.i_data_10   = 0;
        tx_if.i_data_1    = 0;
        @(negedge tx_if.clk);
        @(negedge tx_if.clk);
        tx_if.rst = 0;
        @(negedge tx_if.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge tx_if.clk);
            tr.display("DRV");
            tx_if.i_sel       = tr.i_sel;
            tx_if.i_sel_2     = tr.i_sel_2;
            tx_if.i_data_1000 = tr.i_data_1000;
            tx_if.i_data_100  = tr.i_data_100;
            tx_if.i_data_10   = tr.i_data_10;
            tx_if.i_data_1    = tr.i_data_1;
            tx_if.i_start <= 1'b1;
            @(posedge tx_if.clk);
            tx_if.i_start <= 1'b0;

            // UART 전송은 매우 느리므로(9600 baud), 문장이 다 전송될 때까지 충분히 대기
            // 1 byte = 약 1ms. 15 byte = 15ms = 15,000,000 ns (1.5M clocks)
            #20_000_000;
        end
    endtask
endclass

class monitor;
    mailbox #(string) mon2scb_mbox;
    virtual tx_interface tx_if;

    // 9600 Baud Rate 기준 1 bit의 시간 (ns) = 1,000,000,000 / 9600 = 104166.66 ns
    localparam real BIT_PERIOD = 104166;

    function new(mailbox#(string) mon2scb_mbox, virtual tx_interface tx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.tx_if        = tx_if;
    endfunction

    task run();
        fork
            begin
                logic [7:0] rx_data;
                string msg_string = "";

                forever begin
                    @(negedge tx_if.o_uart_tx);  // Start Bit 감지
                    #(BIT_PERIOD / 2);  // Start bit의 중앙으로 이동

                    if (tx_if.o_uart_tx == 1'b0) begin // 유효한 Start bit인지 확인
                        for (int i = 0; i < 8; i++) begin
                            #(BIT_PERIOD);    // 다음 데이터 비트의 중앙으로 이동
                            rx_data[i] = tx_if.o_uart_tx;
                        end
                        #(BIT_PERIOD);  // Stop bit 위치로 이동

                        if (rx_data != 8'd10) begin
                            msg_string = {msg_string, string'(rx_data)};
                        end else begin
                            mon2scb_mbox.put(msg_string);
                            msg_string = "";
                        end
                    end
                end

                begin
                    forever begin
                        @(posedge tx_if.clk);
                        if (tx_if.o_fifo_push) begin
                            $display(
                                "%t : [MON-FIFO] Pushed to FIFO = '%s' (8'h%h)",
                                $time, string'(tx_if.o_fifo_push_data),
                                tx_if.o_fifo_push_data);
                        end
                    end
                end
            end
        join
    endtask

endclass

class scoreboard;
    transaction            gen_tr;
    mailbox #(string)      mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event                  gen_next_ev;

    function new(mailbox#(string) mon2scb_mbox,
                 mailbox#(transaction) gen2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    // 하드웨어 로직을 흉내내어 예상되는 정답 문자열을 만드는 함수
    function string get_expected_string(transaction t);
        string d1000, d100, d10, d1;
        d1000 = $sformatf("%0d", t.i_data_1000);
        d100  = $sformatf("%0d", t.i_data_100);
        d10   = $sformatf("%0d", t.i_data_10);
        d1    = $sformatf("%0d", t.i_data_1);
        case (t.i_sel)
            2'b00: begin
                if (t.i_sel_2[1] == 1'b0)
                    return {"time=", d1000, d100, "s", d10, d1, "ms"};
                else return {"time=", d1000, d100, "h", d10, d1, "m"};
            end
            2'b01: begin
                if (t.i_sel_2[1] == 1'b0)
                    return {"stoptime=", d1000, d100, "s", d10, d1, "ms"};
                else return {"stoptime=", d1000, d100, "h", d10, d1, "m"};
            end
            2'b10:   return {"distance=", d1000, d100, d10, ".", d1, "cm"};
            2'b11: begin
                if (t.i_sel_2[0] == 1'b0)
                    return {"temp=", d1000, d100, ".", d10, d1, "C"};
                else return {"humid=", d1000, d100, ".", d10, d1};
            end
            default: return "";
        endcase
    endfunction

    task run();
        string expected_string;
        string actual_string;
        forever begin
            gen2scb_mbox.get(gen_tr);
            expected_string = get_expected_string(gen_tr);
            mon2scb_mbox.get(
                actual_string); // Monitor에서 복원된 UART 문자열 수신

            if (actual_string == expected_string) begin
                $display(
                    "%t : [SCB-PASS] Match! \n - Expected : %s \n - Actual   : %s\n",
                    $time, expected_string, actual_string);
            end else begin
                $display(
                    "%t : [SCB-FAIL] Mismatch! \n - Expected : %s \n - Actual   : %s\n",
                    $time, expected_string, actual_string);
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
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(string)      mon2scb_mbox;
    event                  gen_next_ev;

    function new(virtual tx_interface tx_if);
        gen2drv_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, tx_if);
        mon = new(mon2scb_mbox, tx_if);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_ev);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(5);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #1000;
        $display("All simulations finished.");
        $stop;
    endtask
endclass

module tb_sender_fifo_uart_sv ();
    logic clk;
    tx_interface tx_if (clk);
    environment       env;

    // 모듈 내부 연결용 Wire 선언
    wire              w_fifo_full;
    wire              w_fifo_push;
    wire        [7:0] w_fifo_push_data;
    wire              w_fifo_empty;
    wire        [7:0] w_fifo_pop_data;
    wire              w_fifo_tx_start;
    wire              w_tx_done;
    wire              w_baud_tick;

    assign tx_if.o_fifo_push = w_fifo_push;
    assign tx_if.o_fifo_push_data = w_fifo_push_data;

    // 1. Sender Top 연결
    sender_top U_SENDER_TOP (
        .i_clk           (clk),
        .i_reset         (tx_if.rst),
        .i_start         (tx_if.i_start),
        .i_sel           (tx_if.i_sel),
        .i_sel_2         (tx_if.i_sel_2),
        .i_data_1000     (tx_if.i_data_1000),
        .i_data_100      (tx_if.i_data_100),
        .i_data_10       (tx_if.i_data_10),
        .i_data_1        (tx_if.i_data_1),
        .i_fifo_full     (w_fifo_full),
        .o_fifo_push     (w_fifo_push),
        .o_fifo_push_data(w_fifo_push_data)
    );

    // 2. FIFO 연결
    fifo #(
        .DEPTH(16),
        .BIT_WIDTH(8)
    ) U_FIFO (
        .i_clk      (clk),
        .i_reset    (tx_if.rst),
        .i_push     (w_fifo_push),
        .i_pop      (w_fifo_tx_start),
        .i_push_data(w_fifo_push_data),
        .o_pop_data (w_fifo_pop_data),
        .o_empty    (w_fifo_empty),
        .o_full     (w_fifo_full)
    );

    // 3. Pop Controller 연결
    pop_controller U_POP_CONTROLLER (
        .i_clk     (clk),
        .i_reset   (tx_if.rst),
        .i_empty   (w_fifo_empty),
        .i_done    (w_tx_done),
        .o_tx_start(w_fifo_tx_start)
    );

    // 4. Baud Tick 연결
    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (tx_if.rst),
        .b_tick(w_baud_tick)
    );

    // 5. UART TX 연결
    uart_tx U_UART_TX (
        .clk              (clk),
        .rst              (tx_if.rst),
        .tx_start         (w_fifo_tx_start),
        .b_tick           (w_baud_tick),
        .tx_data          (w_fifo_pop_data),
        .o_debug_state    (),
        .o_debug_tx_start (),
        .o_debug_tx_data  (),
        .o_debug_tx_done  (),
        .o_debug_start_cnt(),
        .tx_done          (w_tx_done),
        .tx_busy          (),
        .uart_tx          (tx_if.o_uart_tx)
    );

    always #5 clk = ~clk;  // 100MHz Clock

    initial begin
        clk = 0;
        env = new(tx_if);
        env.run();
    end
endmodule
