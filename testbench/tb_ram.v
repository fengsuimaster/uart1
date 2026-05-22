`timescale 1ns/1ps
`include "../design/ram.v"

module tb_ram();

parameter ADDRESS_WIDTH = 'd8;
parameter DATA_WIDTH = 'd8;

reg                        sys_clk      ;
reg                        sys_rst_n    ;
reg  [ADDRESS_WIDTH - 1:0] write_address;
reg  [ADDRESS_WIDTH - 1:0] read_address ;
reg  [DATA_WIDTH - 1:0]    data_in      ;
reg                        write        ;
wire [DATA_WIDTH - 1:0]    data_out     ;


localparam BAUD = 'd9600;
localparam CLK_FREQUENCY = 'd50_000_000;

// 初始化
initial begin
sys_clk = 1'b1;
sys_rst_n <= 1'b0;
write_address <= 0;
read_address <= 0;
data_in <= 0;
write <= 0;
#20;
sys_rst_n <= 1'b1;
end

always #10 sys_clk = ~sys_clk;


integer i;
initial begin
    #200;
    for (i = 0; i < 100; i = i + 1) begin
        wr(i,i);
    end
    $stop;
end

task wr(
    input [7:0] data,
    input [7:0] addr
);
begin
    data_in <= data;
    write_address <= addr;
    read_address <= addr;
    write <= 1'b1;
    #20;
    write <= 0;
    #(200);
end
endtask


ram #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) ram_inst1(
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .write_address(write_address),
    .read_address (read_address ),
    .data_in      (data_in      ),
    .write        (write        ),
    .data_out     (data_out     )
);


endmodule