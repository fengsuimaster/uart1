module tb_uart_rx();

reg sys_clk;
reg sys_rst_n;
reg rx;
wire [7:0] data_out;
wire done_flag;
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
rx <= 1'b1;
ctrl_reg_in <= 0; 
baud_cnt_max_in <= (CLK_FREQUENCY / BAUD - 1);
#20;
sys_rst_n <= 1'b1;
end

initial begin
#200
rx_bit(8'd0 , 2'b00);
rx_bit(8'd1 , 2'b00);
rx_bit(8'hFE, 2'b00);
rx_bit(8'hEF, 2'b00);
rx_bit(8'hFF, 2'b00);
#200
ctrl_reg_in <= 8'b0000_0001; 
rx_bit(8'd0 , 2'b01);
rx_bit(8'd1 , 2'b01);
rx_bit(8'hFE, 2'b01);
rx_bit(8'hEF, 2'b01);
rx_bit(8'hFF, 2'b01);

#200
ctrl_reg_in <= 8'b0000_0010; 
rx_bit(8'd0 , 2'b10);
rx_bit(8'd1 , 2'b10);
rx_bit(8'hFE, 2'b10);
rx_bit(8'hEF, 2'b10);
rx_bit(8'hFF, 2'b10);
end

always #10 sys_clk = ~sys_clk;

task rx_bit(
    input [7:0] data,
    input [1:0] parity_mode_bit
);
integer i;

if (parity_mode_bit == 0) begin
    for (i=0; i<10; i=i+1) begin
        case(i)
            0: rx <= 1'b0;
            1: rx <= data[0];
            2: rx <= data[1];
            3: rx <= data[2];
            4: rx <= data[3];
            5: rx <= data[4];
            6: rx <= data[5];
            7: rx <= data[6];
            8: rx <= data[7];
            9: rx <= 1'b1;
        endcase
        #(5208*20);
    end
end else begin
    for (i=0; i<11; i=i+1) begin
        case(i)
            0: rx <= 1'b0;
            1: rx <= data[0];
            2: rx <= data[1];
            3: rx <= data[2];
            4: rx <= data[3];
            5: rx <= data[4];
            6: rx <= data[5];
            7: rx <= data[6];
            8: rx <= data[7];
            9: begin
                if (parity_mode_bit == 2'b01) 
                    rx <= ^data;
                else if (parity_mode_bit == 2'b10)
                    rx <= ~^data;
            end
            10: rx <= 1'b1;
        endcase
        #(5208*20);
    end
end
endtask

// 实例化
uart_rx uart_rx_inst(
.sys_clk  (sys_clk),
.sys_rst_n(sys_rst_n),
.rx       (rx),
.ctrl_reg_in(ctrl_reg_in),
.data_out     (data_out),
.ctrl_reg_out(ctrl_reg_out),
.baud_cnt_max_in(baud_cnt_max_in)
);


endmodule