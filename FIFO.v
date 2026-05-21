`include "ram.v"

module FIFO #(
    parameter ADDRESS_WIDTH = 'd8,
    parameter DATA_WIDTH    = 'd8
)(
    input                         sys_clk  ,
    input                         sys_rst_n,
    input      [DATA_WIDTH - 1:0] data_in  ,
    input                         write    ,  // 单周期脉冲
    input                         read     ,  // 单周期脉冲
    output reg [DATA_WIDTH - 1:0] data_out ,
    output reg                    empty    ,
    output reg                    full     
);

localparam RAM_LENGTH = 1 << ADDRESS_WIDTH;

// 读写指针
reg [ADDRESS_WIDTH - 1:0] write_address;
reg [ADDRESS_WIDTH - 1:0] read_address ;
reg [ADDRESS_WIDTH : 0]   fifo_cnt;      // 计数范围 0 ~ RAM_LENGTH

// RAM 实例化
ram #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH   )
) ram_inst1 (
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .write_address(write_address),
    .read_address (read_address ),
    .data_in      (data_in      ),
    .write        (write & ~full ),
    .data_out     (data_out     )
);

// 写指针 & FIFO计数器
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        write_address <= 0;
        fifo_cnt      <= 0;
    end else begin
        case ({(write & ~full), (read & ~empty)})
            2'b10: begin  // 只写不读
                write_address <= write_address + 1'b1;
                fifo_cnt      <= fifo_cnt + 1'b1;
            end
            2'b01: begin  // 只读不写
                fifo_cnt <= fifo_cnt - 1'b1;
            end
            2'b11: begin  // 同时读写
                write_address <= write_address + 1'b1;
                // fifo_cnt 不变
            end
            default: ;  // 无操作
        endcase
    end
end

// 读指针
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        read_address <= 0;
    end else if (read & ~empty) begin
        read_address <= read_address + 1'b1;
    end
end

// 空满标志
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        empty <= 1'b1;
        full  <= 1'b0;
    end else begin
        empty <= (fifo_cnt == 0);
        full  <= (fifo_cnt == RAM_LENGTH);
    end
end

endmodule