# UART 子系统接口文档

---

## 1. uart_tx — UART 发送器

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| `sys_clk` | input | 1 | 系统时钟（50MHz） |
| `sys_rst_n` | input | 1 | 异步复位，低有效 |
| `data_in` | input | 8 | 待发送的并行数据，在 `start` 脉冲时锁存 |
| `baud_cnt_max_in` | input | 16 | 波特率分频计数最大值，计算方式：`CLK_FREQ / BAUD_RATE - 1`（如 9600bps → 5208） |
| `parity_mode` | input | 2 | 校验模式：`00`=无校验（发送 START + 8bit DATA + STOP），`01`=奇校验，`10`=偶校验（发送 START + 8bit DATA + PARITY + STOP） |
| `start` | input | 1 | 发送启动信号，内部通过边沿检测转为单周期脉冲，高有效 |
| `tx` | output | 1 | 串行数据输出线，空闲为高 |
| `done` | output | 1 | 发送完成脉冲，一帧数据发送结束后拉高一周期 |
| `busy` | output | 1 | 忙标志，发送过程中为高，空闲为低 |

### 状态机（5 状态）
`IDLE` → `START_BIT` → `DATA_BITS` → `PARITY`（可选）→ `STOP_BIT` → `IDLE`

### 发送时序
```
 IDLE: tx=1, busy=0
   ↓ start_pulse 上升沿
 START_BIT: 锁存 data_in / parity_mode，计算校验位，tx=0
   ↓ baud_cnt == baud_cnt_max
 DATA_BITS: 每个波特周期发送 1bit，从 LSB 到 MSB（共 8bit）
   ↓ bit_cnt == 8
 PARITY（如使能）: 发送校验位
   ↓
 STOP_BIT: tx=1，发送完成后拉高 done 一个周期
   ↓
 IDLE
```

---

## 2. uart_rx — UART 接收器

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| `sys_clk` | input | 1 | 系统时钟（50MHz） |
| `sys_rst_n` | input | 1 | 异步复位，低有效 |
| `rx` | input | 1 | 串行数据输入线，空闲为高，内部经三级同步处理 |
| `baud_cnt_max_in` | input | 16 | 波特率分频计数最大值，计算方式同 `uart_tx` |
| `parity_mode` | input | 2 | 校验模式：`00`=无校验，`01`=奇校验，`10`=偶校验 |
| `data_out` | output | 8 | 接收到的并行数据，在 `done` 拉高时有效 |
| `parity_result` | output | 1 | 校验结果：`0`=校验通过或无关，`1`=校验错误 |
| `done` | output | 1 | 接收完成脉冲，一帧数据接收成功（STOP 位为高）后拉高一周期 |
| `error` | output | 1 | 帧错误标志，STOP 位为低时拉高一周期 |

### 状态机（5 状态）
`IDLE` → `START_BIT` → `DATA_BITS` → `PARITY`（可选）→ `STOP_BIT` → `IDLE`

### 接收时序
```
 IDLE: 等待 rx 下降沿（rx_reg2==0 && rx_reg3==1）
   ↓ 检测到起始位
 START_BIT: 等待 bit_flag（baud_cnt 到达中点）确认起始位有效
   ↓ bit_flag 拉高
 DATA_BITS: 在每个 bit_flag 时刻采样 rx_reg3，从 LSB 到 MSB（共 8bit）
   ↓ bit_cnt == 7
 PARITY（如使能）: 采样校验位，与本地计算结果比对 → parity_result
   ↓
 STOP_BIT: 采样停止位
   · rx_reg3==1 → data_out 写入有效数据，done=1
   · rx_reg3==0 → error=1（帧错误）
   ↓
 IDLE
```

### 跨时钟域处理
`rx` 端口经过三级寄存器（`rx_reg1` → `rx_reg2` → `rx_reg3`）同步，消除亚稳态。

### 位中间采样
`bit_flag` 在 `baud_cnt == baud_cnt_max[15:1]`（即计数到一半）时拉高，确保在每位的中心位置采样，提高抗干扰能力。

---

## 3. FIFO — 同步 FIFO（256×8bit）

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| `sys_clk` | input | 1 | 系统时钟（50MHz） |
| `sys_rst_n` | input | 1 | 异步复位，低有效 |
| `data_in` | input | 8 | 写入数据 |
| `write` | input | 1 | 写使能，单周期脉冲。满（`full=1`）时内部自动屏蔽 |
| `read` | input | 1 | 读使能，单周期脉冲。空（`empty=1`）时内部自动屏蔽 |
| `data_out` | output | 8 | 读出数据，组合逻辑输出（下一周期有效） |
| `empty` | output | 1 | FIFO 空标志，`fifo_cnt == 0` 时为高 |
| `full` | output | 1 | FIFO 满标志，`fifo_cnt == RAM_LENGTH(256)` 时为高 |

### 参数

| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| `ADDRESS_WIDTH` | 8 | 地址位宽，决定 FIFO 深度 = 2^ADDRESS_WIDTH（默认 256） |
| `DATA_WIDTH` | 8 | 数据位宽 |

### 读写保护机制

| 场景 | 行为 |
|------|------|
| `full=1` 时写入 | 写使能被内部屏蔽（`write & ~full`），`fifo_cnt` 不增加，数据不写入 |
| `empty=1` 时读取 | 读使能被内部屏蔽（`read & ~empty`），`fifo_cnt` 不减少，输出保持 |
| 同时读写 | `fifo_cnt` 不变 |
| 只写不读 | `fifo_cnt` + 1 |
| 只读不写 | `fifo_cnt` - 1 |

### 内部结构
```
FIFO
├── ram #(.ADDRESS_WIDTH, .DATA_WIDTH)
│   ├── .write_address → write_address（写指针）
│   ├── .read_address  → read_address （读指针）
│   ├── .write         → write & ~full  （满保护）
│   └── .data_out      → data_out
├── write_address  → 写指针 +1（每次写操作）
├── read_address   → 读指针 +1（每次读操作）
├── fifo_cnt       → 当前 FIFO 中有效数据数量（0 ~ 256）
├── empty          → (fifo_cnt == 0)
└── full           → (fifo_cnt == 256)

---

## 模块功能简述

| 模块 | 功能简述 |
|------|----------|
| **uart_tx** | 将用户写入的 8bit 并行数据按 UART 帧格式（1 起始位 + 8 数据位 + 可选校验位 + 1 停止位）串行输出。内部通过 5 状态状态机控制发送时序，支持无校验/奇校验/偶校验三种模式，并输出 `done` 和 `busy` 状态供上层调度。 |
| **uart_rx** | 从串行输入 `rx` 上检测起始位，按 UART 帧格式采样恢复 8bit 并行数据。输入经过三级同步消除亚稳态，并在每位中心点采样以提高可靠性。支持奇偶校验验证和帧错误（STOP 位异常）检测，接收完成后通过 `done` 通知上层读取。 |
| **FIFO** | 基于同步双口 RAM 构建的 256×8bit 先进先出缓冲器，提供 `write`/`read` 单周期脉冲接口和 `empty`/`full` 状态标志。内置满写保护和空读保护，自动维护读写指针和计数器，适用于跨模块数据缓冲（如 UART TX/RX 数据流缓冲）。 |
