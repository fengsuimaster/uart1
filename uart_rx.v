module uart_rx(
    input sys_clk,
    input sys_rst_n,
    input rx,
    input [15:0] baud_cnt_max_in,
    input [7:0] ctrl_reg_in,
    output reg [7:0] data_out,
    output wire [15:0] baud_cnt_max_out,
    output wire [7:0] ctrl_reg_out
);

reg rx_reg1, rx_reg2, rx_reg3;
reg [15:0] baud_cnt;
reg bit_flag;
reg [3:0] bit_cnt;
reg [7:0] rx_reg;

// 接收状态
localparam [2:0]
    IDLE      = 3'b000,
    START_BIT = 3'b001,
    DATA_BITS = 3'b010,
    STOP_BIT  = 3'b011,
    PARITY    = 3'b100;
reg [2:0] state, next_state;


// 控制寄存器
reg [7:0] ctrl_reg;
wire [1:0] parity_mode_bit;
wire parity_result_bit;
wire done_bit;
wire error_bit;
localparam [1:0]
    NO_PARITY   = 2'b00,
    ODD_PARITY  = 2'b01,
    EVEN_PARITY = 2'b10;
    
assign ctrl_reg_out = ctrl_reg;
assign parity_mode_bit = ctrl_reg[1:0];
assign parity_result_bit = ctrl_reg[2];  // 0是校验通过
assign done_bit = ctrl_reg[3];
assign error_bit = ctrl_reg[4];

// 波特率设置寄存器
reg [15:0] baud_cnt_max;
assign baud_cnt_max_out = baud_cnt_max;

// 跨时钟域处理
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        rx_reg1 <= 1;
    else
        rx_reg1 <= rx;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        rx_reg2 <= 1;
    else
        rx_reg2 <= rx_reg1;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        rx_reg3 <= 1;
    else
        rx_reg3 <= rx_reg2;
end

// 波特率发生器
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        baud_cnt <= 0;
    else if ((baud_cnt == baud_cnt_max) || (state == IDLE))
        baud_cnt <= 0;
    else
        baud_cnt <= baud_cnt + 1'b1;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        bit_flag <= 0;
    else if (baud_cnt == baud_cnt_max_in[15:1])
        bit_flag <= 1'b1;
    else 
        bit_flag <= 0;
end

// 接收状态机
always @(*) begin
    case (state)
        IDLE: next_state = ((rx_reg2 == 0) && (rx_reg3 == 1'b1)) ? START_BIT : IDLE;
        START_BIT: begin
            if (rx_reg3 == 0)
                next_state = DATA_BITS;
            else if (rx_reg3 == 1'b1)
                next_state = IDLE;
            else
                next_state = START_BIT;
        end
        DATA_BITS: begin
            if ((parity_mode_bit == NO_PARITY) && (bit_cnt == 4'd7))
                next_state = STOP_BIT;
            else if (bit_cnt == 4'd7)
                next_state = PARITY;
            else
                next_state = DATA_BITS;
        end
        PARITY:    next_state = STOP_BIT;
        STOP_BIT:  next_state = IDLE;
        default :  next_state = IDLE;
    endcase
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0)
        state <= IDLE;
    else if ((state == IDLE) || (bit_flag == 1'b1))
        state <= next_state;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        bit_cnt <= 0;
        rx_reg <= 0;
        data_out <= 0;
        ctrl_reg <= 0;
        baud_cnt_max <= 0;
    end else begin
        case (state)
            IDLE:begin
                ctrl_reg <= {ctrl_reg_in[7:4],1'b0,ctrl_reg_in[2:0]};
                baud_cnt_max <= baud_cnt_max_in;
            end
            START_BIT: begin
                if (bit_flag == 1'b1) begin
                    bit_cnt <= 0;
                    rx_reg <= 0;
                end
            end
            DATA_BITS: begin
                if (bit_flag == 1'b1) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    rx_reg <= {rx_reg3, rx_reg[7:1]};
                end
            end
            PARITY: begin
                if (bit_flag == 1'b1) begin
                    if ((parity_mode_bit == ODD_PARITY) && (rx_reg3 == ~^rx_reg))
                        ctrl_reg[2] <= 0;
                    else if ((parity_mode_bit == EVEN_PARITY) && (rx_reg3 == ^rx_reg))
                        ctrl_reg[2] <= 0;
                    else
                        ctrl_reg[2] <= 1'b1;
                end
            end
            STOP_BIT: begin
                if ((bit_flag == 1'b1) && (rx_reg3 == 1'b1)) begin
                    data_out <= rx_reg;
                    ctrl_reg[3] <= 1'b1;
                    ctrl_reg[4] <= 0;
                end else if ((bit_flag == 1'b1) && (rx_reg3 == 1'b0)) begin
                    ctrl_reg[4] <= 1'b1;
                end else begin
                    ctrl_reg[3] <= 0;
                end
            end
        endcase
    end
end



endmodule