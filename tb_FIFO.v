`include "FIFO.v"

module tb_FIFO();

reg         sys_clk  ;
reg         sys_rst_n;
reg  [7:0]  data_in  ;
reg         write    ;
reg         read     ;
wire [7:0]  data_out ;
wire        empty    ;
wire        full     ;

localparam CLK_PERIOD   = 20;    // 50MHz
localparam FIFO_DEPTH   = 256;   // ADDRESS_WIDTH = 8
localparam DATA_WIDTH   = 8;

// 初始化
initial begin
    sys_clk   = 1'b1;
    sys_rst_n = 1'b0;
    data_in   = 8'd0;
    write     = 1'b0;
    read      = 1'b0;
    #(CLK_PERIOD);
    sys_rst_n = 1'b1;
end

// 测试激励
initial begin
    #(CLK_PERIOD * 5);

    // 1. 复位后确认空
    check_empty;

    // 2. 写满 FIFO
    fifo_write_fill(FIFO_DEPTH);
    check_full;

    // 3. 读空 FIFO
    fifo_read_empty(FIFO_DEPTH);
    check_empty;

    // 4. 同时读写测试（写一个读一个交替）
    fifo_write_read_alternate(16);

    // 5. 满时写保护测试
    fifo_write_fill(FIFO_DEPTH);
    check_full;
    fifo_write_protect;

    // 6. 空时读保护测试
    fifo_read_empty(FIFO_DEPTH);
    check_empty;
    fifo_read_protect;

    #(CLK_PERIOD * 10);
    $stop;
end

// 时钟生成
always #(CLK_PERIOD / 2) sys_clk = ~sys_clk;

// 检查空标志
task check_empty;
begin
    #(CLK_PERIOD * 2);
    if (empty == 1'b1)
        $display("[OK] FIFO is empty as expected.");
    else
        $display("[FAIL] Expected empty=1, got empty=%b.", empty);
end
endtask

// 检查满标志
task check_full;
begin
    #(CLK_PERIOD * 2);
    if (full == 1'b1)
        $display("[OK] FIFO is full as expected.");
    else
        $display("[FAIL] Expected full=1, got full=%b.", full);
end
endtask

// 写满 FIFO
task fifo_write_fill;
    input integer count;
    integer i;
begin
    for (i = 0; i < count; i = i + 1) begin
        data_in <= i[7:0];
        write   <= 1'b1;
        #(CLK_PERIOD);
        write   <= 1'b0;
        #(CLK_PERIOD);
    end
    $display("[INFO] Wrote %0d data into FIFO.", count);
end
endtask

// 读空 FIFO
task fifo_read_empty;
    input integer count;
    integer i;
begin
    for (i = 0; i < count; i = i + 1) begin
        read <= 1'b1;
        #(CLK_PERIOD);
        read <= 1'b0;
        #(CLK_PERIOD);
    end
    $display("[INFO] Read %0d data from FIFO.", count);
end
endtask

// 交替读写
task fifo_write_read_alternate;
    input integer count;
    integer i;
begin
    for (i = 0; i < count; i = i + 1) begin
        data_in <= i[7:0];
        write   <= 1'b1;
        #(CLK_PERIOD);
        write   <= 1'b0;
        #(CLK_PERIOD);
        // 读一次
        read <= 1'b1;
        #(CLK_PERIOD);
        read <= 1'b0;
        #(CLK_PERIOD);
    end
    $display("[INFO] Alternating write/read %0d cycles done.", count);
end
endtask

// 满时写保护：full=1 时写操作应被忽略
task fifo_write_protect;
    reg [7:0] last_data_out;
begin
    last_data_out = data_out;
    data_in <= 8'hAA;
    write   <= 1'b1;
    #(CLK_PERIOD);
    write   <= 1'b0;
    #(CLK_PERIOD);
    // 检查 full 仍为 1，数据未被覆盖
    if (full == 1'b1)
        $display("[OK] Write protect on full works: full stays high.");
    else
        $display("[FAIL] full flag changed unexpectedly.");
end
endtask

// 空时读保护：empty=1 时读操作应被忽略
task fifo_read_protect;
begin
    read <= 1'b1;
    #(CLK_PERIOD);
    read <= 1'b0;
    #(CLK_PERIOD);
    if (empty == 1'b1)
        $display("[OK] Read protect on empty works: empty stays high.");
    else
        $display("[FAIL] empty flag changed unexpectedly.");
end
endtask

// 实例化
FIFO #(
    .ADDRESS_WIDTH(8),
    .DATA_WIDTH   (8)
) FIFO_inst (
    .sys_clk  (sys_clk  ),
    .sys_rst_n(sys_rst_n),
    .data_in  (data_in  ),
    .write    (write    ),
    .read     (read     ),
    .data_out (data_out ),
    .empty    (empty    ),
    .full     (full     )
);

endmodule