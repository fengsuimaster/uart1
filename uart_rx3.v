module uart_rx3 #(
    parameter BAUD = 'd9600,
    parameter CLK_FREQUENCY = 'd50_000_000
)(
    input sys_clk,
    input sys_rst_n,
    input rx,
    output reg [7:0] dout,
    output reg done_flag
);

reg rx_reg1, rx_reg2, rx_reg3;
reg start_flag, work_en;
reg [12:0] baud_cnt;
reg bit_flag;
reg [3:0] bit_cnt;
reg [7:0] rx_data;

localparam BAUD_CNT_MAX = CLK_FREQUENCY / BAUD;


// 跨时钟域处理
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        rx_reg1 <= 1;
    else
        rx_reg1 <= rx;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        rx_reg2 <= 1;
    else
        rx_reg2 <= rx_reg1;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        rx_reg3 <= 1;
    else
        rx_reg3 <= rx_reg2;
end

// 起始位检测
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        start_flag <= 0;
    else if ((rx_reg2 == 1'b0) && (rx_reg3 == 1'b1))
        start_flag <= 1'b1;
    else 
        start_flag <= 0;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        work_en <= 0;
    else if (start_flag == 1'b1)
        work_en <= 1'b1;
    else if ((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        work_en <= 0;
    else 
        work_en <= work_en;
end

// 波特率发生器
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        baud_cnt <= 0;
    else if ((baud_cnt == BAUD_CNT_MAX - 1) || (work_en == 0))
        baud_cnt <= 0;
    else if (work_en == 1'b1)
        baud_cnt <= baud_cnt + 1'b1;
    else
        baud_cnt <= baud_cnt;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0)
        bit_flag <= 0;
    else if (baud_cnt == BAUD_CNT_MAX / 2 - 1)
        bit_flag <= 1'b1;
    else 
        bit_flag <= 0;
end

// 接收过程
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0) 
        bit_cnt <= 0;
    else if ((work_en == 0) || (bit_cnt == 4'd9))
        bit_cnt <= 0;
    else if (bit_flag == 1'b1)
        bit_cnt <= bit_cnt + 1'b1;
    else
        bit_cnt <= bit_cnt;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 1'b0) begin
        rx_data <= 0;
        dout <= 0;
        done_flag <= 0;
    end else if ((bit_cnt >= 4'b1) && (bit_cnt <= 4'd8) && (bit_flag == 1'b1))
        rx_data <= {rx_reg3, rx_data[7:1]};
    else if (bit_cnt == 4'd9) begin
        dout <= rx_data;
        done_flag <= 1;
    end else begin
        rx_data <= rx_data;
        dout <= dout;
        done_flag <= 0;
    end
end


endmodule