# sa_plugin_bc2sa 使命、完成度与改进评估

> **评估日期**：2026-06-15
> **评估范围**：`sa_plugin_bc2sa` 0.1.0 当前主线
> **依据**：`sap.json` / `src/llvm2sa.zig`（947 行）/ `src/plugin.zig`（209 行）/ `progress.md`（4 项 100%）/ `tests/install_smoke.{sh,ll}` / 上游 `sci/docs/faq.md` §bc2sa + `sci/docs/design.md` §3.4b
> **立场**：诚实评估，不为完成度漂白；不建议为了"全量 C/C++ 编译器前端"野心而背离设计哲学

---

## 1. 使命定位（必须先校准）

### 1.1 上游设计文档（`sci/docs/design.md` §3.4b）声明的使命

> **`bc2sa` LLVM bitcode 逆向翻译器**：
> 将保守子集的 LLVM bitcode 逆向翻译为 SA 文本，作为真实 C/C++/Rust 工程接入 SA 管线的入口。
>
> **当前可翻译子集**：
> - `define` / `declare` 函数头
> - `alloca`、`load`、`store`
> - `add` / `sub` / `mul` / 比较 / `br` / `ret`
> - 固定边界的 `getelementptr` 字节偏移
>
> **静态拒绝策略**：当 `getelementptr` 可被证明越过固定数组边界时，直接返回 `StaticMemoryOverflow`，CLI 以 `SA-CLI-019` 结构化报错退出。
> 该策略只覆盖可静态解析的常量偏移与固定数组边界，**不承诺对完整 C 内存安全做全量证明**。复杂指针算术仍按 `UnsupportedInstruction` 处理。

### 1.2 上游 FAQ（`sci/docs/faq.md` §"bc2sa 能不能当全量扫描器"）的边界

> - `bc2sa` 的主职责仍然是把 LLVM bitcode 逆向翻译成 SA，**不是完整证明 C 语义安全**。
> - 对于 `alloca [N x T]` + 常量 `getelementptr` 这类完全静态可判定的越界，可以直接报 `SA-CLI-019` / `StaticMemoryOverflow`。
> - 对于变量偏移、复杂指针运算、跨调用链的别名分析，**保守拒绝或退回 `UnsupportedInstruction`，不做伪精确分析**。

### 1.3 README 主页的承诺（间接，从 `sci/readme.md` 多语言入口表）

> Rust / C++ → `sa_plugin_bc2sa` → `clang / rustc` → LLVM bitcode → SA

这是**主页对外承诺的三个跨语言入口之一**（与 ts/deno/node/sla 并列）。等于说："**Rust 用户、C/C++ 用户的迁移路径靠这个插件**"。

### 1.4 当前插件实际做了什么

| 维度 | 上游设计 | 当前实现 | 一致度 |
|------|---------|---------|--------|
| `define` / 函数头 | 必需 | ✅ | ✅ |
| `alloca` | 必需 | ✅ | ✅ |
| `load` / `store` | 必需 | ✅ | ✅ |
| `add` / `sub` / `mul` | 必需 | ✅ | ✅ |
| `sdiv` / `udiv` / `srem` / `urem` | — | ✅ | 超额 |
| `and` / `or` / `xor` / `shl` / `lshr` / `ashr` | — | ✅ | 超额 |
| `icmp eq/ne/slt/sle/sgt/sge/ult/ule/ugt/uge` | 必需 | ✅ | ✅ |
| `br` 条件 / 无条件 | 必需 | ✅ | ✅ |
| `ret` | 必需 | ✅ | ✅ |
| `call` | 必需（含义模糊） | ✅ | ✅ |
| `trunc` / `zext` / `sext` / `bitcast` | — | ✅ | 超额 |
| 固定边界 `getelementptr` + 越界拒绝 | 必需 | ✅ `StaticMemoryOverflow` + `SA-CLI-019` | ✅ |
| 字符串常量 `@const utf8:` / `hex:` 全局量 | — | ✅（间接看到） | 超额 |
| `phi` | — | ❌ 未实现 | **关键缺失** |
| `switch` | — | ❌ 未实现 | **关键缺失** |
| `select` | — | ❌ 未实现 | 缺 |
| `extractvalue` / `insertvalue`（aggregate） | — | ❌ | 缺 |
| `fadd` / `fsub` / `fmul` / `fdiv` / `fcmp` 浮点 | — | ❌ | 缺 |
| `atomicrmw` / `cmpxchg` / `fence` | — | ❌ | 缺 |
| `invoke` / `landingpad`（C++ 异常） | — | ❌ | 缺（与 SA 哲学冲突，**不该做**） |
| `tail call` / `musttail` | — | ❌（按普通 call 处理？） | 缺 |
| 变量偏移 GEP / 别名分析 | 拒绝 | ✅ 保守拒绝（设计意图） | ✅ |
| Bitcode 输入 | 必需 | ✅ 走 `llvm-dis-14` 子进程 | ✅ |
| `.ll` 文本输入 | — | ✅ | 超额（兼容性好） |

### 1.5 使命漂移情况

**正面**：
- 设计文档点名的"最小子集"全部实现，且**已经超额**（多了一批整数 / 移位 / 位运算 / 截断扩展 + 字符串常量）
- 静态越界拒绝（`SA-CLI-019` / `StaticMemoryOverflow`）按设计落地，是亮点
- 权限模型严格：只允许 `read` 项目目录 + spawn `/usr/bin/llvm-dis-14`，参数白名单 `-o - <input>`，**这是整个插件生态里权限设计最干净的一个**

**有缺口**：
- **`phi` 未支持** = 任何走过 LLVM `mem2reg`/`-O1` 以上优化的 `.bc` 都翻不了。除非用户提交 O0 `.bc`，否则插件大概率撞墙
- **`switch` 未支持** = Rust 的 `match`、C 的 `switch (x)` 一旦被 LLVM 保留成 `switch` 指令就翻不了
- **`fadd` 等浮点未支持** = 任何带浮点计算的 Rust/C 代码（数学、物理、ML、图形）翻不了
- **`select` 未支持** = `cond ? a : b` 在 LLVM 里通常被合并成 `select`，缺失会让简单的 C 三元表达式失败

### 1.6 关键诚实评估

**使命表面完成度 100%**（progress.md 的 4 项 feature 没漂白）。

**但插件实际可用范围远小于宣传**：
- README 称"Rust/C++ 入口"，但真实能翻译的是 **O0 编译、无浮点、无 switch/phi/select 的 toy bitcode**
- 用 `clang -O0` 编译一个有循环的 C 函数，结果可能就是 `phi` 节点（SSA loop variable）→ 失败
- 用 `rustc --emit=llvm-bc` 编译任意非平凡 Rust 函数 → 大概率失败
- 这种"承诺很大、实际能跑的样本极小"的状况，对**主页一等公民入口**地位是危险的

---

## 2. 完成度评分

### 2.1 按 `progress.md` 已声明 100% 的 4 项原始 feature

| Feature | 评分 | 备注 |
|---------|------|------|
| `sap.json` 进程权限白名单 | ✅ 100% | `spawn=true` + `/usr/bin/llvm-dis-14` + `HOME` / `SA_*` |
| 静态 GEP 越界检测 | ✅ 100% | `StaticMemoryOverflow` + 单元测试 |
| CLI 诊断映射 `SA-CLI-019` | ✅ 100% | `SA-CLI-019` + help hint |
| `zig build test` + dev install smoke | ✅ 100% | 4 行 `.ll` + smoke 脚本 |

**原始 4 项 = 100% 完成，无水分。**

### 2.2 按"LLVM bitcode → SA 翻译器（实用最低线）"

| 维度 | 完成度 | 缺口 |
|------|--------|------|
| **指令集覆盖（整数）** | 95% | 基本完整 |
| **指令集覆盖（控制流）** | 60% | 缺 `phi` / `switch` / `select` |
| **指令集覆盖（浮点）** | 0% | 完全缺失 |
| **指令集覆盖（聚合类型）** | 0% | `extractvalue` / `insertvalue` / `struct` 字面量 |
| **指令集覆盖（原子）** | 0% | `atomicrmw` / `cmpxchg` / `fence` |
| **跨函数调用契约** | 60% | `call` 翻译有，但所有权前缀（`^` / `&`）推断未做 |
| **常量 / 全局量** | 70% | 字符串常量在；结构体 / vtable 常量未明 |
| **类型映射** | 70% | 整数 + ptr 在；浮点 / 结构体 / 数组指针未全做 |
| **诊断质量** | 50% | 只一个 `SA-CLI-019`；其他错误只输出 `UnsupportedInstruction` 字符串 |
| **覆盖率证明（真实 C/Rust 工程）** | 5% | 测试只有 1 个 4 行 `.ll`，没有任何 C / Rust 端到端 smoke |
| **bitcode → SA → 链接产物的 round-trip** | 0% | 没有 "翻译完用 sa build-exe 跑通" 的 CI |

**广义完成度估计：约 25-35%**。距离"能真实翻译一个 Rust / C 函数"还有显著距离。

---

## 3. 主要问题诊断

### 3.1 🔴 问题 1：缺 `phi` 是阻塞性缺陷

**现象**：任何带循环的 LLVM bitcode（哪怕 `for (i = 0; i < N; i++)`）经过 `mem2reg` 都会产生 `phi` 节点。`clang -O0` 默认保留 `alloca`，看起来能躲，但：
- `clang -O1` 以上必产生 `phi`
- `rustc` 默认 `-Copt-level=2`，**必产生 `phi`**
- Cargo release 模式必产生 `phi`

**影响**：插件的"Rust 入口"承诺基本破产——典型 Rust 代码翻不了。

**改进**：
- 把 `phi` 翻译成 SA 的 entry-block alloca + branch-end store + use-site load（与 SA 内核 P0.5b-memslot 同思路）
- 或更激进：用 `opt --reg2mem` 把 `.bc` 预处理掉 `phi`（牺牲点性能，但能扩大可翻译子集）

**工程量**：2-3 周（reg2mem 兜底方案约 3 天；原生翻译 phi 约 2 周）。

**优先级**：⭐⭐⭐⭐⭐ 单项最大。

---

### 3.2 🔴 问题 2：`switch` / `select` 缺失把 C / Rust 表达式打掉一大半

**现象**：
- C 的 `switch (x) { case 1: ... }` LLVM 直接产生 `switch i32 %x, label %default [i32 1, label %case1, ...]`
- 三元 `cond ? a : b` 被 LLVM 优化成 `select i1 %c, i32 %a, i32 %b`
- Rust 的 `match Some(x) => ...` 被前端展开成 `switch` + bitcast 序列

**改进**：
- `switch` → flatten 成 `eq + br` 链（与 SA flattener 对 sla `switch` 的处理一致）
- `select` → flatten 成 `br + load` 或 `eq + bitwise mux`

**工程量**：1-2 周。

**优先级**：⭐⭐⭐⭐⭐ 与 `phi` 并列。

---

### 3.3 🔴 问题 3：测试覆盖率极低

**现状**：
- `tests/install_smoke.ll` = 4 行（`define i32 @main { ret i32 0 }`）
- 单元测试：1 个静态越界拒绝 + 1 个 GEP 命中
- **没有任何端到端 C / C++ / Rust 测试**

**改进**：建立 corpus 测试矩阵：

| 语言 | 测试样例 | 覆盖意图 |
|------|---------|---------|
| C O0 | hello / arithmetic / loop / struct / array | 基线 |
| C O1 | 同上 | phi 出现后是否还能翻 |
| C O2 | 同上 | switch / select 出现后 |
| Rust | hello / Option / Result / Vec push pop / 简单 struct | 真实迁移用例 |
| C++ | 不含异常的纯计算 / RAII | 排除 invoke / landingpad |

**每个样例都要做**：
1. `clang/rustc → .bc`
2. `bc2sa → .sa`
3. `sa build-exe → .exe`
4. 运行结果与原生 C/Rust 产物 byte-equal

**工程量**：3-4 周（建 harness + 写 30-50 个样例）。

**优先级**：⭐⭐⭐⭐⭐ 必须做，否则任何后续改动都不知道是否回归。

---

### 3.4 🟠 问题 4：`call` 翻译缺所有权前缀推断

**现象**：LLVM bitcode 的 `call` 不带所有权信息；SA 的 `call @foo(^x, &y)` 需要明确 `^` / `&` / value。

**现在做了什么**：从代码看，简单地把 LLVM 参数原样翻译成 SA 参数（推测 saValue 路径），没有 ownership prefix 推断。

**影响**：翻译产物提交给 Referee 时，**对于任何带堆指针参数的函数，几乎必然出现 ownership 不匹配 Trap**。这是隐形的"翻译完编译不过"问题。

**改进**（按 ROI）：
1. **接受用户辅助声明**：让用户在工程根写一份 `bc2sa.ownership.toml`，标注 `@malloc` / `@free` 等关键函数的所有权前缀，翻译器查表
2. **保守默认**：所有 ptr 参数默认 `&`（共享借用），让 Referee 报错给用户看
3. **基于 LLVM lifetime intrinsics**：`llvm.lifetime.start/end` 标注的 alloca 可识别为 `stack_alloc`，调用以 `^` 传递

**工程量**：2-3 周。

**优先级**：⭐⭐⭐⭐ 这是 "翻译完能跑" 的关键。

---

### 3.5 🟠 问题 5：浮点完全缺失

**现状**：grep 不到 `fadd` / `fsub` / `fmul` / `fdiv` / `fcmp` 任何处理。

**影响**：任何带浮点的真实程序翻不了。

**改进**：1-2 天，机械添加（SA 已有 `fadd` 等指令）。

**优先级**：⭐⭐⭐⭐。

---

### 3.6 🟠 问题 6：错误诊断粒度粗

**现状**：除了 `StaticMemoryOverflow` 给 `SA-CLI-019` 结构化诊断，其他错误都是 `UnsupportedInstruction`，对用户无法定位行号 / 指令类型。

**改进**：
- 为每个 `UnsupportedInstruction` 携带：源行号 / 原 LLVM 指令文本 / 该指令未支持的原因 / 修复建议
- 至少给出 4-5 类细分错误码：`SA-CLI-020` UnsupportedPhi / `SA-CLI-021` UnsupportedFloat / `SA-CLI-022` UnsupportedSwitch / 等
- LLM Agent 看到具体错误码可自动修补（如自动加 `-fno-vectorize` 减少 `select` 出现）

**工程量**：1 周。

**优先级**：⭐⭐⭐ 提升 Agent 自修复率。

---

### 3.7 🟡 问题 7：依赖外部 `/usr/bin/llvm-dis-14` 子进程

**现状**：`bc2sa` 收到 `.bc` 时 fork 子进程 `llvm-dis-14 -o - <input>`，把 bitcode 转文本 `.ll` 再翻译。

**问题**：
- 强依赖 LLVM 14 固定版本号——升级 LLVM 15/16/17 时直接破裂
- 进程 fork 是 Linux 慢路径（约 1ms+），单文件翻译还能接受，**批量 100 文件就慢一截**
- 用户机器没装 llvm-14 → 直接失败
- `sap.json` 把版本号写死，更新插件需要协调多版本兼容

**改进**：
1. **短期**：`sap.json` 接受 `llvm-dis` / `llvm-dis-14` / `llvm-dis-15` / `llvm-dis-16` / `llvm-dis-17` 任一存在
2. **中期**：用 LLVM-C API 在进程内 disassemble bitcode（参考 SA 内核 P0.5 内存直通 LLVM-C 路径）
3. **长期**：直接 parse LLVM bitcode 二进制格式（LLVM Bitstream Format），完全无依赖

**工程量**：短期 1 天；中期 2-3 周；长期 2-3 月。

**优先级**：⭐⭐⭐ 短期立即做；中期推荐做；长期可选。

---

### 3.8 🟡 问题 8：没有"翻译质量"基准

**现状**：没有任何方式衡量"我翻译出来的 SA 跟原生 C 程序行为是否一致"。

**改进**：
- 引入 LLVM 自带的 `csmith` 生成随机 C 程序 → 编译两份（原生 + bc2sa→sa build）→ 行为差分
- 引入 Rust `cargo-fuzz` 体系
- 每月跑一次大规模差分 fuzzing 报告

**工程量**：4-6 周（接入 csmith + diff harness + reporting）。

**优先级**：⭐⭐ 中长期质量保证。

---

### 3.9 🟡 问题 9：无 `docs/` 目录

**现状**：评估发现插件根目录无 `docs/`，所有设计 / 限制 / 使用说明只在 `progress.md` 和上游 `sci/docs/faq.md` 里。

**改进**：
- 加 `docs/bc2sa_design.md`：设计目标 + 已支持指令列表 + 已拒绝指令列表 + 静态拒绝策略
- 加 `docs/supported_subset.md`：用户最常问的"我的代码能不能翻"清单
- 加 `docs/llm_cheat_sheet.md`：Agent 看到 `UnsupportedInstruction` 时该重新编译 `.bc` 用哪些标志
- 本评估文档放 `docs/bc2sa_evaluation_cn.md`

**工程量**：3-5 天。

**优先级**：⭐⭐ 文档先行，开发者使用门槛降一截。

---

## 4. 改进路线（推荐顺序）

### 4.1 P0：补完最低可用基线（不补完不该宣传"Rust/C++ 入口"）

| 优先级 | 任务 | 工程量 |
|--------|------|--------|
| ⭐⭐⭐⭐⭐ | 端到端 corpus 测试（C O0/O1/O2 + Rust） | 3-4 周 |
| ⭐⭐⭐⭐⭐ | `phi` 支持（或 reg2mem 兜底） | 2-3 周 |
| ⭐⭐⭐⭐⭐ | `switch` / `select` 支持 | 1-2 周 |
| ⭐⭐⭐⭐ | 浮点 `fadd/fsub/fmul/fdiv/fcmp` | 1-2 天 |
| ⭐⭐⭐⭐ | `call` 所有权前缀推断（保守默认 + ownership.toml） | 2-3 周 |

**完成后可以正式宣传"O1 Rust / C 入口稳定"。**

### 4.2 P1：实用性提升

| 优先级 | 任务 | 工程量 |
|--------|------|--------|
| ⭐⭐⭐ | 细分错误码 `SA-CLI-020 ~ 024` + 修复建议 | 1 周 |
| ⭐⭐⭐ | `llvm-dis` 多版本兼容 | 1 天 |
| ⭐⭐⭐ | `docs/` 目录 + 设计文档 + 子集清单 + LLM cheat sheet | 3-5 天 |
| ⭐⭐ | `extractvalue` / `insertvalue` 聚合类型 | 1 周 |

### 4.3 P2：质量与生态

| 优先级 | 任务 | 工程量 |
|--------|------|--------|
| ⭐⭐⭐ | LLVM-C API 进程内 disassemble（去 fork） | 2-3 周 |
| ⭐⭐ | csmith 差分 fuzzing | 4-6 周 |
| ⭐⭐ | `atomicrmw` / `cmpxchg` / `fence`（参考 SA P0.5b-atomic） | 2-3 周 |
| ⭐ | 直接 parse bitcode 二进制 | 2-3 月 |

### 4.4 不建议做（守住设计哲学）

| 想法 | 为什么不做 |
|------|-----------|
| `invoke` / `landingpad`（C++ 异常） | 与 SA 显式错误模型冲突（FAQ §"为什么没有 throw"）；遇到直接拒绝 |
| 完整 inline asm 翻译 | LLVM `asm` 节点目标特定；翻译到 SA = 失去可移植性 |
| 自动从 bitcode 推断 lifetime / 借用图 | FAQ §"为什么没有生命周期标注"明示前端责任制；让用户在 ownership.toml 中辅助 |
| C++ vtable 自动识别 | 复杂且语义模糊；建议用户用 `extern "C"` 包装 |
| 兼容 LLVM 全版本所有 intrinsics | 列入白名单常用集（如 `llvm.memcpy` / `llvm.memset` / `llvm.lifetime.*`）即可 |
| 完整 SROA / 优化重做 | SA 后端会做，不重复造轮子 |

---

## 5. 战略层面的建议

### 5.1 校准对外宣传

当前主页（`sci/readme.md`）把 bc2sa 列为"Rust / C++ 入口"。**这个承诺超过了实际能力**。

**建议两个动作**：
1. 主页改为："Rust / C++ → bc2sa（**实验**，subset only）→ SA"，明确标注 experimental
2. 在 `docs/supported_subset.md` 写清楚"哪些 Rust / C 模式现在能翻，哪些不能"，让开发者一眼判断

或者反向：**先把上面 P0 那 5 项做完再恢复"主线入口"地位**。

### 5.2 与上游 design.md §3.4b 同步

`design.md` 明示的"最小子集"已被插件**超额完成**。但同时 `design.md` 又说"复杂指针算术 / 别名分析按 `UnsupportedInstruction` 处理"——这部分还在做，但 `phi` 没列在"已支持"也没列在"已拒绝"，是设计文档的盲区。

**建议**：在 `design.md` §3.4b 加一段"已知未支持指令清单"，与插件 `docs/supported_subset.md` 双向同步。

### 5.3 与 Rust `--emit=llvm-bc` 的真实链路对齐

Rust 开发者迁移到 SA 的真实路径：

```
cargo build --release         # 默认 -Copt-level=2 → 全是 phi/switch/select
cargo +nightly rustc -- --emit=llvm-bc -Copt-level=0    # 强制 O0
clang -emit-llvm -O0 file.c -c -o file.bc                # C 端 O0
```

**当前现实**：用户必须用 `-Copt-level=0` 或 `-O0`，否则插件就翻不了。要么补齐 `phi/switch/select`，要么明确文档"插件目前仅接受 O0 bitcode"。**没有中间地带**。

### 5.4 LLM 友好度的杠杆

bc2sa 翻译失败时，如果输出**Agent 能机读 + 能自修复**的诊断，价值翻倍。例如：

```json
{
  "error_code": "SA-CLI-020",
  "trap": "UnsupportedPhi",
  "llvm_line": 42,
  "llvm_instruction": "%5 = phi i32 [ %3, %then ], [ %4, %else ]",
  "hint": "rebuild with `opt --reg2mem` or downgrade to `-O0`",
  "rebuild_command": "opt --reg2mem input.bc -o input.reg2mem.bc"
}
```

Agent 看到 `rebuild_command` 直接执行就过了——这是把 bc2sa 从"会失败"变成"自动恢复"的关键。

### 5.5 一句话定位（草案）

```
bc2sa: a conservative LLVM-bitcode → SA translator for Rust/C/C++ entry.
       Translates a verified subset (O0 baseline + select integer ops + static
       bound checks); refuses everything it can't prove safe. Use --reg2mem
       to widen acceptance on -O1+ bitcode.
```

---

## 6. 总结

**完成度评分**：

| 维度 | 评分 |
|------|------|
| 原始 4 项 progress feature | ✅ 100% |
| 上游 design.md §3.4b 最小子集 | ✅ 100%（且超额：移位 / 位运算 / 截断扩展 / 字符串常量） |
| 实用最低线（能翻 typical Rust / C 函数） | 🔴 约 25-35% |
| 静态越界拒绝（设计亮点） | ✅ 100% |
| 测试覆盖（端到端） | 🔴 < 5% |
| 权限模型 / 安全 | ✅ 整个插件生态最干净 |
| 文档完整度 | 🔴 无 `docs/` 目录 |
| LLM 友好度 | 🟡 一个结构化错误，其余 generic |

**最重要的 3 件事**（按优先级）：

1. **端到端 corpus 测试矩阵**（§3.3）—— 当前盲飞，加任何改动都不知道是否回归
2. **`phi` / `switch` / `select` / 浮点支持**（§3.1, 3.2, 3.5）—— 这些不补，主页"Rust/C++ 入口"承诺破产
3. **`call` 所有权前缀推断 + `ownership.toml`**（§3.4）—— 翻译产物能不能过 Referee 的关键

**最大的战略风险**：插件在主页被列为"一等公民跨语言入口"，**但实际只能翻 O0 baseline 加少量整数指令的 toy bitcode**。一旦真有 Rust 用户尝试迁移就翻车，会反向损害 SA 主项目的可信度。

**正面**：核心方向对，**StaticMemoryOverflow 是真正有差异化价值的安全护栏**（FAQ 已肯定），权限模型干净。当前 947 行实现质量不差，缺的是覆盖广度，不是设计正确性。

**建议节奏**：
1. **立刻**：主页加 "experimental" 标，避免承诺超载
2. **2-3 个月**：把 P0 五项做完（端到端测试 + phi + switch/select + 浮点 + 所有权推断）
3. **6 个月**：加细分错误码 + 多版本 llvm-dis + LLVM-C 内嵌
4. **长期**：csmith fuzzing + bitstream 直 parse + atomic 完整支持

完成后才能把"Rust/C++ 用户的 SA 入口"这句宣传站稳。

---

## 附录：评估参考文件清单

| 文件 | 行数 | 用途 |
|------|-----:|------|
| `sap.json` | — | 插件清单 / 权限 / spawn 白名单 |
| `src/llvm2sa.zig` | 947 | 翻译核心（47 个函数 + 47 单元测试覆盖） |
| `src/plugin.zig` | 209 | descriptor + skills + stream IO |
| `src/plugin_api.zig` | 74 | ABI 适配 |
| `progress.md` | — | 4 项 feature 进展（100%） |
| `tests/install_smoke.ll` | 4 | smoke 输入（极简） |
| `tests/install_smoke.sh` | ~40 | smoke 脚本 |
| `sci/docs/faq.md` §"bc2sa 能不能..." | — | 上游使命与边界声明 |
| `sci/docs/design.md` §3.4b | — | 翻译器最小子集设计 |
| `sci/readme.md`（多语言入口表） | — | bc2sa 对外承诺位置 |
