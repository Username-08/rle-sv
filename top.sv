`timescale 1ns / 1ps

module top
#(
        parameter   DBITS = 8,          // number of data bits in a word
                    SB_TICK = 16,       // number of stop bit / oversampling ticks
                    BR_LIMIT = 651,     // baud rate generator counter limit
                    BR_BITS = 10,       // number of baud rate generator counter bits
    )
(
    input logic rx, clk, reset, t,
    output logic tx,
    output logic [7:0] p, written
    );
    logic tick;                          // sample tick from baud rate generator
    logic rx_done_tick;                  // data word received
    logic tx_done_tick;                  // data transmission complete
    logic tx_empty;
    logic tx_fifo_not_empty;
    logic [DBITS-1:0] tx_fifo_out;
    logic [DBITS-1:0] rx_data_out;
    logic [7:0] mem [0:255]; 
    logic [7:0] d, dprev;
    logic [7:0] raddr = 0;
    logic [7:0] waddr = 0;
    logic [7:0] b_tr = 0;
    logic [7:0] b_wr = 0;
    logic isfirstbit = 1;
    logic tfirstbit = 1;
    logic [7:0] dout = 32;
    logic [7:0] count = 48;
    logic tx_en = 0;
    logic tx_stop;
    assign tdone = tx_stop;

    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk_100MHz(clk), 
            .reset(reset),
            .tick(tick)
         );
         //---------------------
             uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .clk_100MHz(clk),
            .reset(reset),
            .rx(rx),
            .sample_tick(tick),
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
         );
         //--------------------------
         uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk_100MHz(clk),
            .reset(reset),
            .tx_start(t),
            .tx_stop(tx_en),
            .sample_tick(tick),
            .data_in(dout),
            .tx_done(tx_done_tick),
            .tx(tx)
         );
    logic [4:0] rx_st = 0;
    logic [4:0] tx_st = 0;
    logic [4:0] rxns = 0;
    logic [4:0] txns = 0;

    always @(posedge clk) begin
        if (reset) begin
            rx_st = 0;
            tx_st = 0;
            rxns = 0;
            txns = 0;
            dout <= 32;
            b_tr = 0;
            b_wr = 0;
            isfirstbit = 1;
            tfirstbit = 1;
            tx_en = 0; 
            count = 48;  
        end
        rx_st = rxns;
        tx_st = txns;
        case (rx_st)
            0: begin
                if (rx_done_tick) begin
                    if (isfirstbit) begin
                        d <= rx_data_out;
                        rxns = 5;
                    end else begin
                    rxns = 1;
                    d <= rx_data_out;
                    p <= rx_data_out;
                    end
                    
                end
            end
            1: begin
                if (d == dprev) begin
                    count = count + 8'd1;
                    rxns = 0;
                end else begin
                    rxns = 2;
                end
            end
            2: begin
                mem[waddr] <= count;
                
                b_wr = b_wr + 8'd2;
                rxns = 3;
            end
            3: begin
                mem[waddr + 8'd1] <= dprev;
                rxns = 4;
            end
            4: begin
                count = 49;
                dprev <= d;
                written <= b_wr;
                waddr = waddr + 8'd2;
                rxns = 0;
            end
            5: begin
                dprev <= rx_data_out;
                isfirstbit = 0;
                rxns = 1;
            end
            default: rxns = 0; 
        endcase
        
        case (tx_st)
            0: begin
                if (t) begin
                    if (tfirstbit) begin
                        txns = 4;
                    end else begin
                        txns = 1;
                        dout = mem[raddr];
                    end
                end else begin
                    txns = 0;
                end 
            end
            1: begin
                if (tx_done_tick) begin 
                    if (b_tr >= b_wr) begin
                        txns = 1;
                        tx_en = 1;
                    end else begin
                        txns = 2;
                    end
                end
            end
            2: begin
                dout = mem[raddr];
                txns = 3;
            end
            3: begin
                raddr = raddr + 8'd1;
                b_tr = b_tr + 8'd1;
                
                txns = 0;
            end
            4: begin
                mem[waddr] <= count;
                b_wr = b_wr + 2;
                txns = 5;
            end
            5: begin
                mem[waddr + 1] <= dprev;
                tfirstbit = 0;
                txns = 6;
            end
            6: begin
                waddr = waddr + 2;
                txns = 0;
            end
            
            default: txns = 0;
        endcase
    end
    
endmodule
