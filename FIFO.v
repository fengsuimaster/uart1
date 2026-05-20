`include "ram.v"

module FIFO #(
    parameter ADDRESS_WIDTH = 'd8,
    parameter DATA_WIDTH = 'd8
)(
    input sys_clk,
    input sys_rst_n,
    input [DATA_WIDTH - 1:0] data_in,
    input [7:0] ctrl_reg_in,
    output reg [DATA_WIDTH - 1:0] data_out,
    output wire [7:0] ctrl_reg_out
);


// 读写指针
reg [ADDRESS_WIDTH - 1:0]   write_address;
reg [ADDRESS_WIDTH - 1:0]   read_address ;

// 控制寄存器
reg [7:0] ctrl_reg;
wire write_flag_bit;
wire read_flag_bit;
wire full_bit;
wire empty_bit;
wire write_done_bit;
wire read_done_bit;
    
assign ctrl_reg_out = ctrl_reg;
assign write_flag_bit = ctrl_reg[1];  // 输入单周期脉冲
assign read_flag_bit = ctrl_reg[2];  // 输入单周期脉冲
assign full_bit = ctrl_reg[3];
assign empty_bit = ctrl_reg[4];
assign write_done_bit = ctrl_reg[5];
assign read_done_bit = ctrl_reg[6];


// 读写逻辑
ram #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH   )
)ram_inst1(
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .write_address(write_address),
    .read_address (read_address ),
    .data_in      (data_in      ),
    .write_flag   (write_flag_bit),
    .data_out     (data_out     )
);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        write_address <= 0;
        read_address <= 0;
        ctrl_reg[1:0] <= ctrl_reg_in[1:0];
    end else if ((write_flag_bit == 1'b1) && (full_bit == 0)) begin
        write_address <= write_address + 1'b1; 
    end else begin
    end
end





