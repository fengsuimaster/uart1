// ****************************************************************************
// 模块名: uart
// 功能描述: UART顶层模块，例化uart_tx发送模块和uart_rx接收模块
//           支持波特率可配、奇偶校验可选（无校验/奇校验/偶校验）
// 作者: 
// 日期: 
// ****************************************************************************

module uart (
    // 系统接口
    input               sys_clk,        // 系统时钟
    input               sys_rst_n,      // 系统复位，低电平有效

    // 串行接口
    input               rx,             // UART接收输入
    output              tx,             // UART发送输出

    // 波特率配置
    input  [15:0]       baud_cnt_max_in, // 波特率计数最大值 = 时钟频率/波特率 - 1

    // 发送接口
    input  [7:0]        tx_data_in,      // 待发送数据
    input               tx_start,        // 发送启动信号（上升沿有效）
    output              tx_busy,         // 发送忙标志
    output              tx_done,         // 发送完成标志

    // 接收接口
    output [7:0]        rx_data_out,     // 接收到的数据
    output              rx_done,         // 接收完成标志（一帧数据接收完毕）
    output              rx_error,        // 接收错误标志（停止位错误）

    // 控制/状态寄存器直通
    input  [7:0]        tx_ctrl_reg_in,  // 发送控制寄存器输入
    output [7:0]        tx_ctrl_reg_out, // 发送控制寄存器输出
    input  [7:0]        rx_ctrl_reg_in,  // 接收控制寄存器输入
    output [7:0]        rx_ctrl_reg_out, // 接收控制寄存器输出
    output [15:0]       baud_cnt_max_out // 波特率计数最大值直通输出
);

// ----------------------------------------------------------------------------
// 例化uart_tx发送模块
// ----------------------------------------------------------------------------
// 例化uart_tx发送模块
// ----------------------------------------------------------------------------
uart_tx uart_tx_inst (
    .sys_clk            (sys_clk),
    .sys_rst_n          (sys_rst_n),
    .data_in            (tx_data_in),
    .baud_cnt_max_in    (baud_cnt_max_in),
    .ctrl_reg_in        ({4'b0000, tx_start, 1'b0, 2'b00}),
    .tx                 (tx),
    .baud_cnt_max_out   (baud_cnt_max_out),
    .ctrl_reg_out       (tx_ctrl_reg_out)
);

// ----------------------------------------------------------------------------
// 例化uart_rx接收模块
// ----------------------------------------------------------------------------
uart_rx uart_rx_inst (
    .sys_clk            (sys_clk),
    .sys_rst_n          (sys_rst_n),
    .rx                 (rx),
    .baud_cnt_max_in    (baud_cnt_max_in),
    .ctrl_reg_in        (rx_ctrl_reg_in),
    .data_out           (rx_data_out),
    .baud_cnt_max_out   (),
    .ctrl_reg_out       (rx_ctrl_reg_out)
);

// ----------------------------------------------------------------------------
// 信号分配
// ----------------------------------------------------------------------------
assign tx_done   = tx_ctrl_reg_out[3];  // 发送完成标志
assign tx_busy   = tx_ctrl_reg_out[5];  // 发送忙标志
assign rx_done   = rx_ctrl_reg_out[3];  // 接收完成标志
assign rx_error  = rx_ctrl_reg_out[4];  // 接收错误标志

endmodule
