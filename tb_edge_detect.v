module tb_edge_detect();

reg  sys_clk  ;
reg  sys_rst_n;
reg  signal_in;
wire pulse_out;

localparam CLK_PERIOD = 20;  // 50MHz

// 初始化
initial begin
    sys_clk   = 1'b1;
    sys_rst_n = 1'b0;
    signal_in = 1'b0;
    #(CLK_PERIOD);
    sys_rst_n = 1'b1;
end

// 测试激励
initial begin
    #(CLK_PERIOD * 5);
    // 测试上升沿
    signal_in <= 1'b0;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;   // 上升沿
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;   // 上升沿
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;

    // 测试下降沿
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;   // 下降沿
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b1;
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;   // 下降沿
    #(CLK_PERIOD * 5);
    signal_in <= 1'b0;

    #(CLK_PERIOD * 10);
    $stop;
end

// 时钟生成
always #(CLK_PERIOD / 2) sys_clk = ~sys_clk;

// 实例化
edge_detect #(
    .EDGE_TYPE(2)     // 0: 上升沿, 1: 下降沿, 2: 双边沿
) edge_detect_inst (
    .sys_clk  (sys_clk  ),
    .sys_rst_n(sys_rst_n),
    .signal_in(signal_in),
    .pulse_out(pulse_out)
);

endmodule