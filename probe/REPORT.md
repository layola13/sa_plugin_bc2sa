# bc2sa 弯道超车探针报告（Agent AM，2026-10-27）

路线假设：`rustc --emit=llvm-bc`（语法/宏/借用检查/单态化全归 rustc）→ bc2sa → SA，
难题只剩 referee 合法性、extern 表面、bc2sa 覆盖三处。本线只做探针实测，
不做 bc2sa 功能扩展；结论全部来自下方实测，未测的明确标注。

## 环境与基点

- 仓库基点：sa_plugin_bc2sa master `6b97b5a`（开工直查；本线仅新增 `probe/`，未动其他文件）
- Colab 运行时 `410dd20b5a78`；zig 0.17（/opt/zig17）；sa/sla 为盒上已装版
- **rustc 在本运行时上原本不存在**（旧运行时的安装未跟随轮换）：本线装回
  rustup stable minimal profile，实测 **rustc 1.99.1（LLVM 23.1.1）**
- 驱动：`probe/driver.zig` 直调插件 `translateBitcodeFile` / `translateIrSource`
  （绕开被 sci 内建遮蔽的 `sa bc2sa` CLI——已知 P1，本线不修）
- 统一编译参数：`rustc --emit=llvm-ir,llvm-bc -C panic=abort -C opt-level=2 --crate-type rlib`；
  原生真值 = 同一源码编 bin 运行（`work/tier_*_truth.txt`）

## 第 0 步：bitcode 版本兼容性 —— 传输层被阻断（头条结论）

rustc 1.99.1（LLVM 23.1.1）产出的 `.bc`，summary version = 14：

| 读取方 | 结果 |
|---|---|
| llvm-dis-14（插件白名单内、盒上实存） | `Invalid summary version 14. Version should be in the range [1-9]`；bin 形态另报 opaque pointers |
| llvm-dis-20（盒上为 sax 装，白名单外） | `Invalid summary version 14. Version should be in the range [1-12]` |
| 插件 `translateBitcodeFile(tier_a.bc)` | `error.LlvmDisFailed` |

rlib/bin × embed-bitcode 开关四种组合全败——稳定版 rustc 没有任何 flag 能产出
盒上可读的 bitcode。插件侧机制（`src/llvm2sa.zig` 源码级 + 实测）：
`disassembleBitcode` 候选链 17→16→15→14 中，不存在的版本跳过、**存在的版本
报错即短路**返回 `LlvmDisFailed`，`/usr/bin/clang` 兜底永不达（且盒上只有
clang-14、无 `/usr/bin/clang`）。候选链上限 17 对 LLVM 23 同样无望。

**路线前置项（登记，本线未动）**，二选一：
(a) 盒上装 llvm-dis ≥ 23，并扩 `llvm_dis_candidates` 与 sap.json 白名单；
(b) rustc 钉到 LLVM ≤ 20 的工具链，且候选链/白名单加入 llvm-dis-20
（仍需改一行候选 + sap.json）。

本线其余探针经 `translateIrSource` 喂 `rustc --emit=llvm-ir` 文本（与未来
llvm-dis-23 的输出同源），裁定对象为翻译器 + referee + extern 面；
传输层以上述结论单独为准。

## 逐档结果

记法：翻译 = `translateIrSource` 是否产出 SA；归一 = `probe/normalize_ll.py`
的文本修复（类目见裁定 3）；referee/运行 = 经 SLA harness（`.sai` 声明视图 +
`.sa` 导入，与 sa_std 的 .sai/.sa 消费模式相同）`sa build-exe` 并运行对拍。

### (a) 纯函数 + struct/enum/match（samples/tier_a.rs，5 个 `#[no_mangle]` 函数）

- 原始 O2：**1/5 翻译**（dist2）。逐函数二分 + 最小复现定性：
  - `icmp samesign` 修饰符（LLVM 18+ 打印）：classify、sign_chain
  - `br` 尾随 `, !llvm.loop !N` 元数据后缀：fib
  - `f0x…` 十六进制浮点常量作 binop 操作数：area_code
    （注：todo.md 记 P0 有「hex 立即数透传」，实测 hex 在 phi/ret 位置可过、
    **binop 操作数位置失败**，最小复现 min_hex.ll）
- 归一后：**5/5 翻译**；referee **4/5 过、运行值全对**（harness_a_nofib 输出
  `tier_a fails=0`，与原生真值 14 项逐项一致）；**fib 被 referee 拒**：
  `UnknownRegister t_6`（形态 M1，见裁定 1）
- O0 变体（同一源码 -C opt-level=0）：新拦路类——`extractvalue`/`insertvalue`
  （溢出检查的 `{值, i1}` 聚合返回，dist2 有 10 处 extractvalue）、
  `unreachable`（panic 块终结符）、sret 聚合返回（本身可解析）；
  6 个函数（含内部 shape_of）中 3 个可译

### (b) Vec/String core+alloc（samples/tier_b.rs，5 入口 + 3 个 alloc 内部函数）

- 原生真值：vec_sum(10)=285、vec_filter_sum(10)=25、string_build()=7754、
  string_fmt()=4208、string_split_count()=519
- 原始 O2（自动向量化开）：**0/8 翻译**——求和循环被向量化为 `<2 x i64>`
  向量 phi/宽载荷；向量类型经最小复现证实不支持（min_vec.ll）
- 去向量化（`-C llvm-args=-vectorize-loops=false -C llvm-args=-vectorize-slp=false`）
  + 归一后：**1/8 翻译**——string_fmt 被 rustc 常量折叠为
  `call @__rust_no_alloc_shim…; return 4208`，构建 + 运行 = **4208 与原生一致**
  （shim 桩须以原始 SA 同名 `@export` 提供；SLA 同名 fn 的符号发射对不上，
  链接报 `undefined symbol: __rustc::__rust_no_alloc_shim_is_unstable_v2`）
- 其余 7 个函数逐个二分/类计数，失败点全部落在已证类目（去向量化+归一版统计）：

  | 函数 | 命中类 |
  |---|---|
  | vec_sum | `inttoptr` 常量表达式 ×3（空 Vec 悬垂指针 `inttoptr (i64 8 to ptr)`，store 与 phi 入边各一，二分坐实） |
  | vec_filter_sum | `unreachable` ×1（+ 展开迭代器循环，referee 风险未达） |
  | string_build | `unreachable` ×1（alloc 失败路径） |
  | string_split_count | `extractvalue` ×4（二分坐实首拦：memchr_aligned 的 `{i64, i64}` 返回）+ `unreachable` ×1 |
  | RawVec::grow_one | `unreachable` ×1（二分坐实：handle_error 尾调用后） |
  | RawVecInner::finish_grow | `extractvalue` ×2 |
  | RawVecInner::do_reserve_and_handle | `unreachable` ×1 |

### (c) 真实 crate 函数：fnv 1.0.7 的 FnvHasher（tier_c/）

出处：crates.io `fnv` 1.0.7，.crate sha256
`3f9eec918d3f24069decb9af1554cad7c880e2da24a9afd88aca000531ab82c1`；
源码 vendored 于 `tier_c/src/fnv.rs`（仅删 40 行 crate 级 doc cfg_attr 文档块，
代码逐字一致；以 fnv 自家支持的 no_std 配置编译）。包装函数在本线
`tier_c/src/lib.rs`，原生真值见 `work/tier_c_truth.txt`。

- fnv1a_fixed（write + write_u32 + write_usize + finish，全内联）：
  归一后翻译 → referee 过 → 运行 **`fnv1a_fixed() = 3500526725341250453`，
  与原生逐字一致** —— 真实 crate 纯逻辑函数的端到端存在性证明
- fnv1a_stream（64B 缓冲填充 + 流式 write）：向量化版被
  `<16 x i32>/<16 x i8>` + `shufflevector` + `poison` 挡；去向量化后翻译过
  （3693 B SA），**referee 拒**：`UnknownRegister i_sroa_0_010`（形态 M2）；
  referee 是整模块检查，未被调用的它同时挡住同模块其他函数的构建

## 裁定 1：referee 合法性 —— 一道真墙，根源单一

槽位降低对「phi 值只在汇合块内使用」的形态（菱形分支、单块自环）**合法且
语义正确**（classify 的 5 入边 phi、area_code 的 switch+phi、dist2、
sign_chain 全部运行对拍通过；select/switch 降低同样过）。

翻车点是 **phi 值的寄存器跨块复用**，两种形态同根：

- **M1（边存储引用非直接前驱的值）**：fib（O2 展开 + LCSSA）——phi 边存储被
  发射进直接前驱块 loopexit，但入边值 `%t.6` 定义在更早的 bb2
- **M2（装载值在汇合块外使用）**：fnv1a_stream——循环头 phi 的装载寄存器
  `i_sroa_0_010` 被 latch 块的自增 `r7 = add i_sroa_0_010, 1` 使用

根源：翻译器对每个 phi 只在汇合块**装载一次**寄存器并在所有使用点复用；
SA referee 要求计算寄存器块内声明（函数参数与 `stack_alloc` 槽指针是
函数级，可跨块——这正是槽机制本身能成立的原因）。rustc 的循环旋转/展开/
LCSSA 是默认 O2 形态，故**几乎所有真实循环**都会触发 M1/M2 之一。

修复形态（登记，不在本线）：phi 值在使用块按槽重新装载，或全部 SSA 值槽化
——翻译器一处策略，非逐案补丁。本线未验证该修复，仅界定其形状。

## 裁定 2：extern 表面 —— panic=abort 甜点区成立，集合小且可枚举

- **panic=abort 实证有效**：(b) 全模块 `invoke`/`landingpad` 均为 0；
  (a) O2 模块 panic 引用为 0。panic 落点只在「真会失败的路径」出现：
  alloc 失败 → `alloc::raw_vec::handle_error` 调用 + `unreachable`；
  O0 的算术溢出 → `core::panicking::panic_const_*` 调用 + `unreachable`
- 实测 extern 全集（(b) 15 个 declare、(c) 3 个，归纳为四组）：
  - **alloc 家族**：`__rust_alloc` / `__rust_dealloc` / `__rust_realloc`
    （符号为 `___rustc*` 修饰名）、`alloc::raw_vec::handle_error`、
    `___rust_no_alloc_shim_is_unstable_v2`（标记调用，SA 桩已验证可链接）
  - **编译器内建（伪装成 extern）**：`llvm.assume`（空桩）、
    `llvm.lifetime.start/end`（空桩）、`llvm.memset.p0.i64`（真实现——
    本线以 SA 字节循环桩提供并验证 fnv1a_stream 的翻译产物调用形状）、
    `llvm.umax.i64`、`llvm.umul.with.overflow.i64`
  - **EH**：`rust_eh_personality` 仅被 declare 与 personality 子句引用，
    panic=abort 下从未被调用
  - **libc/core  extern**：`bcmp`；`core::slice::memchr::memchr_aligned`
    在部分模块里是 extern（未内联时）
- 未见任何 panic lang item 的直接引用；String/Vec 的方法体均为单态化后
  在模块内定义（不是 extern），extern 的只是上述分配与内建面
- **隐患（登记）**：聚合返回的 declare 被压成单字段类型——
  `llvm.umul.with.overflow.i64` 在 SA 里声明为 `-> i1`（真身 `{i64, i1}`）。
  当前所有真实用法都经 `extractvalue`（本身不支持）而不可达，
  但属静默误声明，将来补 extractvalue 时须一并处理

## 裁定 3：覆盖增长 —— 高度集中，不是长尾

「78 处 unsupported/TODO 标记」的实况：同一批错误返回点
（`error.UnsupportedInstruction` 63 点、`error.UnsupportedPhi` 9 点，
余为 InvalidIr/IO 类）。按**构造类**统计才有意义。三档实测共撞上 **9 类**，
每类均有最小复现（work/min_*.ll）：

| # | 类 | 性质 | 回收方式 |
|---|---|---|---|
| 1 | `icmp samesign` 修饰符 | 打印方言漂移（LLVM 18+） | 文本归一 |
| 2 | 指令尾随元数据后缀（`!llvm.loop`/`!range`/`!noalias`，含叠加双后缀） | 打印方言漂移 | 文本归一（須叠剥至不动点） |
| 3 | `f0x…` 十六进制浮点作 binop 操作数 | 打印方言漂移（位置敏感：phi/ret 可过） | 文本归一（位型转十进制） |
| 4 | `llvm.experimental.noalias.scope.decl` 的 `metadata` 型 declare/调用 | 打印方言漂移（注释性内建） | 文本归一（整行删除，24 处/(b)） |
| 5 | 向量类型 `<N x T>`、`shufflevector`、`poison` | 真特性缺口 | rustc 关向量化可绕（本线采用）；或翻译器补向量槽化 |
| 6 | `inttoptr` 常量表达式（空 Vec 悬垂指针） | 真特性缺口 | 翻译器补常量表达式求值 |
| 7 | `extractvalue` / `insertvalue`（聚合返回：溢出检查、memchr、sret 内容） | 真特性缺口 | 翻译器补聚合槽化 |
| 8 | `unreachable` 终结符（panic/alloc 失败路径） | 真特性缺口 | 翻译器映射为 trap/不可达 |
| 9 | phi 跨块寄存器复用（M1/M2） | referee 层（裁定 1） | phi 装载策略一处改动 |

归一器四条规则即回收 (a) 档全部翻译失败 + (b) 的 string_fmt + (c) 的
fnv1a_fixed；工作量形态：1–4 是**一层 IR 文本归一**（本线 normalize_ll.py
可作雏形）、5 是**一个 rustc flag 约定**、6–8 是三个边界清晰的小特性、
9 是一处策略改动。三档的全部失败点被 9 类覆盖，无类外长尾出现。

## 路线总评

按顺序三道墙：(1) bitcode 传输版本墙——工具链问题（装 llvm-dis ≥23 或钉
rustc），非翻译器问题，但**不解决则路线无入口**；(2) referee 的 phi 跨块
墙——翻译器一处策略，是三者中唯一的真设计题；(3) 三个小特性缺口
（extractvalue / inttoptr 常量表达式 / unreachable）。extern 面比预想
干净：panic=abort + 去向量化 + 文本归一的约定下，core+alloc 无 IO 的
甜点区 extern 是个位数可枚举集合，且已实证可由 SA 桩满足——string_fmt
与 fnv1a_fixed 两个端到端真值即存在性证明。补齐 (1)(2)(3) 后，此路线可
承载真实 crate 的纯逻辑函数；与 slars 互补（机器转换 vs 人写）的定位不变。

## 复现

`probe/run_probe.sh` 串起全流程（装/查 rustc → 编驱动 → 三档编译/翻译/
归一/构建/运行）。中间产物全在 `probe/work/`（.ll/.bc/.sa/harness/真值/
最小复现集 min_*.ll 与变体 *.ll）；逐函数二分脚本 `probe/bisect_fn.py`、
拆分脚本 `probe/split_ll.py`。
