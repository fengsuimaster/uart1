module uart_tx(
    input sys_clk,
    input sys_rst_n,
    input [7:0] data_in,
    input [15:0] baud_cnt_max_in,
    input [7:0] ctrl_reg_in,
    output reg tx,
    output wire [15:0] baud_cnt_max_out,
    output wire [7:0] ctrl_reg_out
);

reg [15:0] baud_cnt;
reg [3:0] bit_cnt;
reg [7:0] tx_reg;

// 发送状态
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
wire done_bit;
wire busy_in_bit;
wire busy_bit;
localparam [1:0]
    NO_PARITY   = 2'b00,
    ODD_PARITY  = 2'b01,
    EVEN_PARITY = 2'b10;
    
assign ctrl_reg_out = ctrl_reg;
assign parity_mode_bit = ctrl_reg[1:0];
assign done_bit = ctrl_reg[3];
assign busy_in_bit = ctrl_reg[4];
assign busy_bit = ctrl_reg[5];


reg parity_out_reg;
// 开始信号检测
reg busy_in_reg;


// 波特率设置寄存器
reg [15:0] baud_cnt_max;
assign baud_cnt_max_out = baud_cnt_max;

// 波特率发生器
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        baud_cnt <= 0;
    end else if ((baud_cnt == baud_cnt_max) || (state == IDLE)) begin
        baud_cnt <= 0;
    end else begin
        baud_cnt <= baud_cnt + 1'b1;
    end
end

// 发送状态机
always @(*) begin
    case (state)
        IDLE: next_state = ((busy_in_reg == 1'b0) && (busy_in_bit == 1'b1)) ? START_BIT : IDLE;
        START_BIT: next_state = DATA_BITS;
        DATA_BITS: begin
            if ((parity_mode_bit == NO_PARITY) && (bit_cnt == 4'd8))
                next_state = STOP_BIT;
            else if (bit_cnt == 4'd8)
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
    else if ((state == IDLE) || (baud_cnt == baud_cnt_max))
        state <= next_state;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (sys_rst_n == 0) begin
        bit_cnt <= 0;
        baud_cnt_max <= 0;
        ctrl_reg <= 0;
        tx_reg <= 8'hFF;
        tx <= 1'b1;
        parity_out_reg <= 1'b1;
        busy_in_reg <= 1'b1;
    end else begin
        case (state)
            IDLE:begin
                ctrl_reg <= {ctrl_reg_in[7:6], 1'b0, ctrl_reg_in[4], 1'b0, ctrl_reg_in[2:0]};
                baud_cnt_max <= baud_cnt_max_in;
                tx_reg <= data_in;

                // 校验计算
                if (parity_mode_bit == ODD_PARITY)
                    parity_out_reg <= ~^data_in;
                else if (parity_mode_bit == EVEN_PARITY)
                    parity_out_reg <= ^data_in;

                // 开始信号检测
                busy_in_reg <= ctrl_reg[4];
            end
            START_BIT: begin
                if (baud_cnt == 0) begin
                    bit_cnt <= 0;
                    tx <= 0;
                    ctrl_reg[5] <= 1;
                end
            end
            DATA_BITS: begin
                if (baud_cnt == 0) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    tx <= tx_reg[0];
                    tx_reg <= {1'b1, tx_reg[7:1]};
                end
            end
            PARITY: begin
                if (baud_cnt == 0) begin
                    tx <= parity_out_reg;
                end
            end
            STOP_BIT: begin
                if (baud_cnt == 0) begin
                    tx <= 1'b1;
                end else if (baud_cnt == baud_cnt_max_in) begin
                    ctrl_reg[3] <= 1;
                end
            end
        endcase
    end
end





endmodule