// ****************************************************************************
// 模块名: uart
// 功能描述: UART顶层模块，集成TX/RX子模块 + TX FIFO + RX FIFO
//           TX: 用户写入FIFO，自动从FIFO取数发送
//           RX: 接收数据自动存入FIFO，用户按需读取
// 作者: 
// 日期: 
// ****************************************************************************

`include "uart_tx.v"
`include "uart_rx.v"
`include "FIFO.v"

module uart (
    // 系统接口
    input               sys_clk,
    input               sys_rst_n,

    // 串行接口
    input               rx,
    output              tx,

    // 波特率 & 校验配置（TX/RX共享）
    input  [15:0]       baud_cnt_max_in,
    input  [1:0]        parity_mode,

    // TX 用户接口（写 FIFO）
    input  [7:0]        tx_data_in,
    input               tx_wr_en,
    output              tx_busy,
    output              tx_fifo_full,

    // RX 用户接口（读 FIFO）
    output [7:0]        rx_data_out,
    input               rx_rd_en,
    output              rx_done,
    output              rx_error,
    output              rx_fifo_empty
);

// ----------------------------------------------------------------------------
// TX FIFO 信号
// ----------------------------------------------------------------------------
wire [7:0]  tx_fifo_data_out;
wire        tx_fifo_empty;

// 写入 TX FIFO（满时禁止写入）
wire tx_fifo_wr = tx_wr_en & ~tx_fifo_full;

FIFO #(
    .ADDRESS_WIDTH(8),
    .DATA_WIDTH   (8)
) tx_fifo_inst (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_in  (tx_data_in),
    .write    (tx_fifo_wr),
    .read     (tx_start),
    .data_out (tx_fifo_data_out),
    .empty    (tx_fifo_empty),
    .full     (tx_fifo_full)
);

// ----------------------------------------------------------------------------
// TX 自动发送逻辑
// ----------------------------------------------------------------------------
// ready = TX空闲 且 FIFO非空
wire tx_ready = ~tx_busy & ~tx_fifo_empty;

// 上升沿检测 → 单周期脉冲，同时作为 tx_start 和 FIFO 读使能
wire tx_start;
edge_detect #(
    .EDGE_TYPE(0)
) edge_tx_start (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .signal_in(tx_ready),
    .pulse_out(tx_start)
);

// ----------------------------------------------------------------------------
// uart_tx 实例化
// ----------------------------------------------------------------------------
wire tx_done;  // TX 完成脉冲（内部使用）

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

// ----------------------------------------------------------------------------
// uart_rx 实例化
// ----------------------------------------------------------------------------
wire [7:0]  rx_data_raw;
wire        rx_done_raw;
wire        rx_parity_result;  // 未使用，可扩展

uart_rx uart_rx_inst (
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    .rx             (rx),
    .baud_cnt_max_in(baud_cnt_max_in),
    .parity_mode    (parity_mode),
    .data_out       (rx_data_raw),
    .parity_result  (rx_parity_result),
    .done           (rx_done_raw),
    .error          (rx_error)
);

// ----------------------------------------------------------------------------
// RX FIFO 信号
// ----------------------------------------------------------------------------
wire rx_fifo_full;   // 内部使用，注意溢出

// 收到一帧 → 写入 RX FIFO
wire rx_fifo_wr = rx_done_raw & ~rx_fifo_full;

FIFO #(
    .ADDRESS_WIDTH(8),
    .DATA_WIDTH   (8)
) rx_fifo_inst (
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_in  (rx_data_raw),
    .write    (rx_fifo_wr),
    .read     (rx_rd_en),
    .data_out (rx_data_out),
    .empty    (rx_fifo_empty),
    .full     (rx_fifo_full)
);

// ----------------------------------------------------------------------------
// 输出分配
// ----------------------------------------------------------------------------
assign rx_done = rx_done_raw;

endmodule