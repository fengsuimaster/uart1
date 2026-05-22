`timescale 1ns/1ps
`include "uart_tx.v"
`include "uart_rx.v"
`include "FIFO.v"

module uart (
    // 系统接口
    input               sys_clk        ,
    input               sys_rst_n      ,
    // 波特率和校验，公用
    input  [15:0]       baud_cnt_max_in,
    input  [1:0]        parity_mode    ,
    // Tx
    input  [7:0]        tx_data_in     ,
    input               tx_write       ,  // 单周期脉冲
    output              tx_done        ,
    output              tx_fifo_full   ,
    output              tx_fifo_empty  ,
    output              tx             ,
    // Rx
    input               rx             ,
    input               rx_read        ,  // 单周期脉冲
    output [7:0]        rx_data_out    ,
    output              rx_done        ,
    output              rx_fifo_full   ,
    output              rx_fifo_empty  
);

// Tx FIFO
wire [7:0]  tx_fifo_data_out;
wire tx_fifo_write = tx_write & ~tx_fifo_full;
wire tx_start;
FIFO #(
    .ADDRESS_WIDTH(8),
    .DATA_WIDTH   (8)
) tx_fifo_inst (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_in  (tx_data_in),
    .write    (tx_fifo_write),
    .read     (tx_start),  // FIFO当前指针指向的输出，有read信号后指针加一
    .data_out (tx_fifo_data_out),
    .empty    (tx_fifo_empty),
    .full     (tx_fifo_full)
);

// 上升沿检测，用于控制自动发送FIFO里面的数据
wire tx_busy;
wire tx_ready = ~tx_busy & ~tx_fifo_empty;
edge_detect #(
    .EDGE_TYPE(0)
) edge_tx_start (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .signal_in(tx_ready),
    .pulse_out(tx_start)  // 单周期脉冲，作为tx_start和FIFO读使能
);

// Tx 模块
uart_tx uart_tx_inst (
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    .data_in        (tx_fifo_data_out),
    .baud_cnt_max_in(baud_cnt_max_in),
    .parity_mode    (parity_mode),
    .start          (tx_start),
    .tx             (tx),
    .done           (tx_done),
    .busy           (tx_busy)
);


// Rx 模块
wire [7:0]  rx_fifo_data_in;
wire rx_parity_result;
wire rx_error;

uart_rx uart_rx_inst (
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    .rx             (rx),
    .baud_cnt_max_in(baud_cnt_max_in),
    .parity_mode    (parity_mode),
    .data_out       (rx_fifo_data_in),
    .parity_result  (rx_parity_result),
    .done           (rx_done),
    .error          (rx_error)
);

// 上升沿检测，用于检测接收完成信号，输出写入FIFO信号
wire rx_ready = rx_done & ~rx_fifo_full & ~rx_error & ~rx_parity_result;
wire rx_fifo_write;
edge_detect #(
    .EDGE_TYPE(0)
) edge_rx (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .signal_in(rx_ready),
    .pulse_out(rx_fifo_write)  // 单周期脉冲
);

// Rx FIFO
FIFO #(
    .ADDRESS_WIDTH(8),
    .DATA_WIDTH   (8)
) rx_fifo_inst (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_in  (rx_fifo_data_in),
    .write    (rx_fifo_write),
    .read     (rx_read),
    .data_out (rx_data_out),
    .empty    (rx_fifo_empty),
    .full     (rx_fifo_full)
);


endmodule