`timescale 1ns/1ps
`include "../design/uart_tx.v"

module tb_uart_tx();

reg        sys_clk         ;
reg        sys_rst_n       ;
reg [7:0]  data_in         ;
reg [15:0] baud_cnt_max_in ;
reg [1:0]  parity_mode     ;
reg        start           ;
wire       tx              ;
wire       done            ;
wire       busy            ;

localparam BAUD = 'd9600;
localparam CLK_FREQUENCY = 'd50_000_000;
localparam [1:0]
    NO_PARITY   = 2'b00,
    ODD_PARITY  = 2'b01,
    EVEN_PARITY = 2'b10;

// 初始化
initial begin
    sys_clk = 1'b1;
    sys_rst_n <= 1'b0;
    data_in <= 0;
    parity_mode <= NO_PARITY;
    baud_cnt_max_in <= (CLK_FREQUENCY / BAUD - 1);
    #20;
    sys_rst_n <= 1'b1;
end

initial begin
    #200;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
    #200;
    parity_mode <= ODD_PARITY;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
    parity_mode <= EVEN_PARITY;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
end

always #10 sys_clk = ~sys_clk;

task tx_bit(
    input [7:0] data
);
begin
    data_in <= data;
    start <= 1'b1;
    @(posedge sys_clk);
    #20;
    start <= 0;
    #(5208*20 *11);
end
endtask


// 实例化
uart_tx uart_tx_inst(
.sys_clk        (sys_clk         ),
.sys_rst_n      (sys_rst_n       ),
.data_in        (data_in         ),
.baud_cnt_max_in(baud_cnt_max_in ),
.parity_mode    (parity_mode     ),
.start          (start           ),
.tx             (tx              ),
.done           (done            ),
.busy           (busy            )
);


endmodule