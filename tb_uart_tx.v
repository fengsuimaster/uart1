module tb_uart_tx();

reg sys_clk;
reg sys_rst_n;
reg [7:0] data_in;
wire tx;
reg [7:0] ctrl_reg_in;
wire [7:0] ctrl_reg_out;
reg [15:0] baud_cnt_max_in;


localparam BAUD = 'd9600;
localparam CLK_FREQUENCY = 'd50_000_000;

assign done_flag = ctrl_reg_out[3];

// 初始化
initial begin
sys_clk = 1'b1;
sys_rst_n <= 1'b0;
ctrl_reg_in <= 0; 
baud_cnt_max_in <= (CLK_FREQUENCY / BAUD - 1);
#20;
sys_rst_n <= 1'b1;
end

initial begin
#200
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
    ctrl_reg_in[5] <= 1'b1;
    @(posedge sys_clk);
    #20;
    ctrl_reg_in[5] <= 0;
    #(5208*20 *11);
end
endtask

// 实例化
uart_tx uart_tx_inst(
.sys_clk  (sys_clk),
.sys_rst_n(sys_rst_n),
.data_in(data_in),
.tx(tx),


.ctrl_reg_in(ctrl_reg_in),
.ctrl_reg_out(ctrl_reg_out),
.baud_cnt_max_in(baud_cnt_max_in)
);


endmodule