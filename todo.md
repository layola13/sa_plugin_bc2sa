# bc2sa TODO

> 基线：全仓 `0.17` 分支，Zig `0.17.0`。`sci/` 只读（编译器），主改本仓库。

## P0 — 已完成（已推 `origin/0.17`）

- [x] float：`fadd/fsub/fmul/fdiv` + `fcmp` 全谓词（`ord/uno` 保守拒绝）—— `src/llvm2sa.zig`
- [x] float/hex 立即数透传归一（对齐 sci 做法）—— `saValue` / `llvmTypedValueToValue`
- [x] `select` → 栈槽 `br/store/load`；`switch` → `eq+br` 链（多行）；`phi` → 入口分槽 + 前驱存 + 使用点取（函数体缓冲重构 `appendFunctionBody`）
- [x] `llvm-dis-14~17` + `llvm-as-*` 绝对路径候选链，`clang -S` 兜底
- [x] `sap.json` exec 白名单绝对路径化（宿主拒相对路径，见 `sci/src/plugins.zig:3870`）
- [x] 顶层模块元数据行（`source_filename/target/attributes`）忽略
- [x] 单测 10/10（含 2 个真 `.bc` 回环：整数 / float+select+立即数），`zig build` 产出 `libbc2sa.so`

## P1 — 待办：CLI 路由被内建遮蔽（2026-10-16 实测确认）

### 现象

插件已正确安装（`sa plugin list` 可见，`sa skills` 含 `bc2sa`），但：

```sh
$ sa bc2sa fmin.bc   # 仅含 %s = fadd double %x, %y
error[SA-CLI-018]: unsupported LLVM instruction
```

错误码前缀是 **`SA-CLI-018`**（内建格式）。插件自己的错误格式是
`SA-BC2SA-CLI`（`src/plugin.zig:144`）或裸 `error: {Name}`（`src/plugin.zig:101`）——
**一次都没出现过**，证明请求没进过插件。而直调插件 `translateBitcodeFile`
（独立 runner，与 `runLlvm2SaCommand` 同一函数）翻译同一形状成功：

```
@export float_math(x: f64, y: f64) -> f64:
L_entry:
  s = fadd x, y
  c = fcmp_lt s, 100
```

### 根因调用链（sci 只读引用，不改）

1. `sci/src/cli.zig:8509` —— `commandFromName(args[1])` 命中已知命令就直接走，
   插件分发（`plugins.Runtime.dispatchCommand`，`sci/src/plugins.zig:1427`）只在
   `else`（未知命令）分支执行。`bc2sa` 是 `Command` 已知成员（`cli.zig:726`），
   所以插件分发一次都不执行。
2. `sci/src/cli.zig:8911` —— `.bc2sa` 分支写死调 sci 内建
   `bc2sa.translateBitcodeFile`（即 `sci/src/llvm2sa.zig`，无 float 映射），
   报错走 `printCliError` → `SA-CLI-018`。
3. 插件侧接线本身是通的：`src/plugin.zig:79 runLlvm2SaCommand` 对 `argv[1]=="bc2sa"`
   接单并调插件自带翻译器，经由 ABI `handle_command` 导出。只是 CLI 主分发在它
   之前就把 `bc2sa` 截胡，本函数经由 CLI 是死代码。
4. 参照：`.pkg`（`cli.zig:8540-8548`）有“内建 fallback → 再问插件”的双通道写法，
   `.bc2sa` 没有。

### 选项（需改 sci，已超出本仓只读范围，待决策）

- [ ] (a) `.bc2sa` 分支仿 `.pkg` 先问插件，插件返回 `unknown_command` 再回落内建
- [ ] (b) 删内建翻译器 / 降级为缺插件时的提示，CLI 默认走插件
- [ ] (c) 维持现状：CLI 走内建（整数子集），float 等新能力只经插件单测 + 独立调用验证

### 复现步骤

```sh
# 1. 建 0.17 版 sa（sci 只构建不改源码）+ 装 llvm-14
# 2. 本仓 zig build；sa plugin install --dev .
cat > fmin.ll <<'EOF'
define double @fmin(double %x, double %y) {
entry:
  %s = fadd double %x, %y
  ret double %s
}
EOF
llvm-as-14 fmin.ll -o fmin.bc
sa bc2sa fmin.bc   # 期望（现状）：SA-CLI-018；插件接管后应输出 fadd
```

## P2 — 后续候选（未排期）

- [ ] `ownership.toml`（`malloc/free` 标 `^`，解 `call` 后 Referee Trap）
- [ ] `extractvalue/insertvalue` 聚合、`SA-CLI-020~024` 细分错误码 + `rebuild_command` hint
- [ ] `docs/supported_subset.md`（能翻/不能翻一页纸）
- [ ] `C O0/O1/O2 × hello/loop/struct/array/float` round-trip corpus
