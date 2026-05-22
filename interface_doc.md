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

```
---

## 4. uart — UART 全双工顶层模块

### 接口列表

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| `sys_clk` | input | 1 | 系统时钟（50MHz） |
| `sys_rst_n` | input | 1 | 异步复位，低有效 |
| `baud_cnt_max_in` | input | 16 | 波特率分频计数最大值，内部同时送给 TX 和 RX |
| `parity_mode` | input | 2 | 校验模式：`00`=无校验，`01`=奇校验，`10`=偶校验，内部同时送给 TX 和 RX |
| **TX 通道** | | | |
| `tx_data_in` | input | 8 | 待发送的并行数据 |
| `tx_write` | input | 1 | TX 写使能，单周期脉冲。满（`tx_fifo_full=1`）时由内部满保护自动屏蔽 |
| `tx_done` | output | 1 | 发送完成脉冲，一帧数据发送结束后拉高一周期 |
| `tx_fifo_full` | output | 1 | TX FIFO 满标志，满时不能再写入 |
| `tx_fifo_empty` | output | 1 | TX FIFO 空标志，无待发送数据时为高 |
| `tx` | output | 1 | 串行数据输出线，空闲为高 |
| **RX 通道** | | | |
| `rx` | input | 1 | 串行数据输入线，空闲为高，内部经 `uart_rx` 三级同步处理 |
| `rx_read` | input | 1 | RX 读使能，单周期脉冲。空（`rx_fifo_empty=1`）时由内部空保护自动屏蔽 |
| `rx_data_out` | output | 8 | 接收到的并行数据，在 `rx_read` 后的下一周期有效 |
| `rx_done` | output | 1 | 接收完成脉冲，一帧数据接收成功且校验通过后拉高一周期 |
| `rx_fifo_full` | output | 1 | RX FIFO 满标志，满时新数据不会被写入 |
| `rx_fifo_empty` | output | 1 | RX FIFO 空标志，无已接收数据时为高 |

### 内部架构


uart
├── TX 路径
│   ├── tx_fifo_inst (FIFO 256×8)     ← 用户写入 tx_data_in
│   │   └── ram (双口同步 RAM)
│   ├── edge_tx_start (edge_detect)    ← 检测 ~tx_busy & ~tx_fifo_empty 上升沿
│   │   └── 输出 tx_start 脉冲，同时作为 FIFO 读使能
│   └── uart_tx                       ← 从 TX FIFO 取数据，串行输出
│
├── RX 路径
│   ├── uart_rx                       ← 串行输入 rx，解析为并行数据
│   ├── edge_rx (edge_detect)         ← 检测 rx_done & ~rx_fifo_full & ~rx_error & ~rx_parity_result 上升沿
│   │   └── 输出 rx_fifo_write 脉冲
│   └── rx_fifo_inst (FIFO 256×8)     ← 校验通过的数据写入 FIFO
│       └── ram (双口同步 RAM)
│
└── 公用
    ├── baud_cnt_max_in → TX / RX 共用
    └── parity_mode     → TX / RX 共用
```

### TX 发送流程
```
用户写入 tx_data_in → tx_write 脉冲
  ↓
TX FIFO 锁存数据，empty 变低
  ↓
边沿检测检测到 ~tx_busy & ~tx_fifo_empty 上升沿 → tx_start 脉冲
  ↓ tx_start 同时作为 FIFO 读使能，弹出队首数据 → tx_fifo_data_out
  ↓
uart_tx 接收 start 脉冲，锁存 data_in，启动状态机 → 串行输出 tx
  ↓ 发送完成
tx_done 拉高一周期，tx_busy 变低
  ↓
边沿检测再次触发（若 FIFO 非空），自动弹出下一个数据继续发送
```

### RX 接收流程
```
uart_rx 检测 rx 下降沿（起始位）
  ↓
按位采样接收 8bit 数据 + 可选校验位 + 停止位
  ↓
STOP 位正确：data_out 锁存数据，done 拉高一周期
  ↓
rx_ready = rx_done & ~rx_fifo_full & ~rx_error & ~rx_parity_result
  ↓ 校验通过且 RX FIFO 未满
edge_rx 产生 rx_fifo_write 脉冲 → 数据写入 RX FIFO
  ↓
用户检测 ~rx_fifo_empty，发起 rx_read 脉冲 → 读取 rx_data_out
```

### RX 数据过滤规则
只有同时满足以下 **全部条件** 的数据才会被写入 RX FIFO：
| 条件 | 说明 |
|------|------|
| `rx_done = 1` | 接收完成 |
| `rx_error = 0` | 停止位正确（帧无误） |
| `rx_parity_result = 0` | 校验通过（无校验模式下恒为 0） |
| `rx_fifo_full = 0` | RX FIFO 未满 |

---

## 模块功能简述

| 模块 | 功能简述 |
|------|----------|
| **uart** | 全双工 UART 顶层模块，集成 TX 发送器、RX 接收器及两组 256×8 FIFO 缓冲。用户通过 `tx_write` 脉冲写入 TX FIFO，内部自动弹出并串行发送；接收端自动解析串行数据，校验通过后存入 RX FIFO，用户通过 `rx_read` 脉冲读取。支持无/奇/偶三种校验模式，波特率和校验模式 TX/RX 共用。 |
| **uart_tx** | 将用户写入的 8bit 并行数据按 UART 帧格式（1 起始位 + 8 数据位 + 可选校验位 + 1 停止位）串行输出。内部通过 5 状态状态机控制发送时序，支持无校验/奇校验/偶校验三种模式，并输出 `done` 和 `busy` 状态供上层调度。 |
| **uart_rx** | 从串行输入 `rx` 上检测起始位，按 UART 帧格式采样恢复 8bit 并行数据。输入经过三级同步消除亚稳态，并在每位中心点采样以提高可靠性。支持奇偶校验验证和帧错误（STOP 位异常）检测，接收完成后通过 `done` 通知上层读取。 |
| **FIFO** | 基于同步双口 RAM 构建的 256×8bit 先进先出缓冲器，提供 `write`/`read` 单周期脉冲接口和 `empty`/`full` 状态标志。内置满写保护和空读保护，自动维护读写指针和计数器，适用于跨模块数据缓冲（如 UART TX/RX 数据流缓冲）。 |
