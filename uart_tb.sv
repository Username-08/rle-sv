`timescale 1ns/1ps
module uart_tb;
    logic clk, rx, tx, t, reset;
    logic [7:0] written, p;
    top uut (rx, clk, reset, t, tx, p, written);
    
    task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
       
      // Send Start Bit
      rx <= 1'b0;
      #(10417 * 2);
       
       
      // Send Data Byte
      for (ii=0; ii<8; ii=ii+1)
        begin
          rx <= i_Data[ii];
          #(10417 * 2);
        end
       
      // Send Stop Bit
      rx <= 1'b1;
      #(10417);
     end
  endtask 
    
    initial begin
        clk = 1;
        forever #1 clk = ~clk;
    end
    initial begin
        rx = 1;
        reset = 1;
        t = 0;
        #1 reset = 0;
        #100000
        UART_WRITE_BYTE(8'b01010101);
        #100000
        UART_WRITE_BYTE(8'b01010101);
        #100000
        UART_WRITE_BYTE(8'b01100110);
        #100000
        UART_WRITE_BYTE(8'b01100110);
        #100000
        UART_WRITE_BYTE(8'b01100001);
        #100000
        UART_WRITE_BYTE(8'b01100110);
        #100000;
        t = 1;
        #3000000;
    end
endmodule