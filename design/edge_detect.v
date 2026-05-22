`timescale 1ns/1ps
module edge_detect #(
    parameter  EDGE_TYPE = 0      // 0: 上升沿, 1: 下降沿, 2: 双边沿
) (
    input      sys_clk  ,
    input      sys_rst_n,
    input      signal_in,        // 待检测信号需要已同步到本时钟域
    output reg pulse_out         // 单周期正脉冲
);

reg signal_in_reg;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        signal_in_reg <= 0;
    else
        signal_in_reg <= signal_in;
end

// 边沿检测
always @(*) begin
    case (EDGE_TYPE)
        0: pulse_out = signal_in & ~signal_in_reg;   // 上升沿
        1: pulse_out = ~signal_in & signal_in_reg;   // 下降沿
        2: pulse_out = signal_in ^ signal_in_reg;    // 任意边沿
        default: pulse_out = 0;
    endcase
end


endmodule