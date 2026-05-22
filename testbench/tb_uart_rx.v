`timescale 1ns/1ps
`include "../design/uart_rx.v"

module tb_uart_rx();

reg         sys_clk        ;
reg         sys_rst_n      ;
reg         rx             ;
reg  [15:0] baud_cnt_max_in;
reg  [1:0]  parity_mode    ;
wire [7:0]  data_out       ;
wire        parity_result  ;
wire        done           ;
wire        error          ;

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
    rx <= 1'b1;
    parity_mode <= NO_PARITY;
    baud_cnt_max_in <= (CLK_FREQUENCY / BAUD - 1);
    #20;
    sys_rst_n <= 1'b1;
end

// 发送数据
initial begin
    #200;
    rx_bit(8'd0 , 2'b00);
    rx_bit(8'd1 , 2'b00);
    rx_bit(8'hFE, 2'b00);
    rx_bit(8'hEF, 2'b00);
    rx_bit(8'hFF, 2'b00);
    #200;
    parity_mode <= ODD_PARITY; 
    rx_bit(8'd0 , 2'b01);
    rx_bit(8'd1 , 2'b01);
    rx_bit(8'hFE, 2'b01);
    rx_bit(8'hEF, 2'b01);
    rx_bit(8'hFF, 2'b01);
    #200;
    parity_mode <= EVEN_PARITY; 
    rx_bit(8'd0 , 2'b10);
    rx_bit(8'd1 , 2'b10);
    rx_bit(8'hFE, 2'b10);
    rx_bit(8'hEF, 2'b10);
    rx_bit(8'hFF, 2'b10);
end

// 时钟生成
always #10 sys_clk = ~sys_clk;


// 发送一帧
task rx_bit(
    input [7:0] data,
    input [1:0] parity_mode
);
integer i;

if (parity_mode == 0) begin
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
                if (parity_mode == 2'b01) 
                    rx <= ^data;
                else if (parity_mode == 2'b10)
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
.sys_clk        (sys_clk        ),
.sys_rst_n      (sys_rst_n      ),
.rx             (rx             ),
.baud_cnt_max_in(baud_cnt_max_in),
.parity_mode    (parity_mode    ),
.data_out       (data_out       ),
.parity_result  (parity_result  ),
.done           (done           ),
.error          (error          )
);


endmodule