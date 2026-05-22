module tb_uart();
reg           sys_clk        ;
reg           sys_rst_n      ;
reg   [15:0]  baud_cnt_max_in;
reg   [1:0]   parity_mode    ;
reg   [7:0]   tx_data_in     ;
reg           tx_write       ;
wire          tx_done        ;
wire          tx_fifo_empty  ;
wire          tx_fifo_full   ;
wire          tx             ;
reg           rx_read        ;
wire   [7:0]  rx_data_out    ;
wire          rx_done        ;
wire          rx_fifo_empty  ;
wire          rx_fifo_full   ;

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
    baud_cnt_max_in <= (CLK_FREQUENCY / BAUD - 1);
    parity_mode <= NO_PARITY;
    
    tx_data_in <= 0;
    tx_write <= 0;
    rx_read <= 0;

    #20;
    sys_rst_n <= 1'b1;
end

integer i;

// 发送数据
initial begin
    #200;
    parity_mode <= NO_PARITY;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
    wait(tx_fifo_empty);
    #(5208*20 *11);
    rx_bit(8'd0 );
    rx_bit(8'd1 );
    rx_bit(8'hFE);
    rx_bit(8'hEF);
    rx_bit(8'hFF);

    #200;
    parity_mode <= ODD_PARITY;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
    wait(tx_fifo_empty);
    #(5208*20 *11);
    rx_bit(8'd0 );
    rx_bit(8'd1 );
    rx_bit(8'hFE);
    rx_bit(8'hEF);
    rx_bit(8'hFF);

    parity_mode <= EVEN_PARITY;
    tx_bit(8'd0 );
    tx_bit(8'd1 );
    tx_bit(8'hFE);
    tx_bit(8'hEF);
    tx_bit(8'hFF);
    wait(tx_fifo_empty);
    #(5208*20 *11);
    rx_bit(8'd0 );
    rx_bit(8'd1 );
    rx_bit(8'hFE);
    rx_bit(8'hEF);
    rx_bit(8'hFF);
    $stop;
end


always #10 sys_clk = ~sys_clk;


// 发送一帧
task tx_bit(
    input [7:0] data
);
begin
    tx_data_in <= data;
    tx_write <= 1'b1;
    @(posedge sys_clk);
    #20;
    tx_write <= 0;
    #20;
end
endtask

// 检查一帧
task rx_bit(
    input [7:0] data
);
begin
    rx_read <= 0;
    @(posedge sys_clk);
    #20;
    rx_read <= 1;
    #20;
    if (data != rx_data_out) begin
        $display("%b,error",data);
    end
end
endtask


// 实例化
uart uart_inst(
.sys_clk        (sys_clk        ),
.sys_rst_n      (sys_rst_n      ),
.baud_cnt_max_in(baud_cnt_max_in),
.parity_mode    (parity_mode    ),
.tx_data_in     (tx_data_in     ),
.tx_write       (tx_write       ),
.tx_done        (tx_done        ),
.tx_fifo_empty  (tx_fifo_empty  ),
.tx_fifo_full   (tx_fifo_full   ),
.tx             (tx             ),
.rx             (tx             ),
.rx_read        (rx_read        ),
.rx_data_out    (rx_data_out    ),
.rx_done        (rx_done        ),
.rx_fifo_empty  (rx_fifo_empty  ),
.rx_fifo_full   (rx_fifo_full   )
);


endmodule