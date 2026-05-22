`timescale 1ns/1ps
`include "edge_detect.v"

module ram #(
    parameter ADDRESS_WIDTH = 'd8,
    parameter DATA_WIDTH    = 'd8
)(
    input                            sys_clk      ,
    input                            sys_rst_n    ,
    input      [ADDRESS_WIDTH - 1:0] write_address,
    input      [ADDRESS_WIDTH - 1:0] read_address ,
    input      [DATA_WIDTH - 1:0]    data_in      ,
    input                            write        ,  // 单周期脉冲
    output reg [DATA_WIDTH - 1:0]    data_out     
);


parameter RAM_LENGTH =  1 << ADDRESS_WIDTH;
reg [DATA_WIDTH - 1:0] ram [0:RAM_LENGTH - 1];

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin

    end else if (write) begin
        ram[write_address] <= data_in;
    end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        data_out <= 0;
    end else begin
        data_out <= ram[read_address];
    end
end


endmodule