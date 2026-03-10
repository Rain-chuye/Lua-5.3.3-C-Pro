# Lua-5.3.3-C-Pro 虚拟机底层分析

## 1. 核心指令集扩展 (lopcodes.h)
本项目引入了多个非标准指令：

- **OP_TERNARY**: 处理三元运算符。它会预先计算条件，并根据结果跳过后续的加载指令。
- **OP_VIRTUAL**: 虚拟化入口指令。
  - 参数 `Ax` 指向 `vcode` 中的索引。
  - VM 会从 `vcode` 中读取指令流，这些指令经过了额外的位旋转和异或加密。
- **指令融合系列**:
  - **OP_FAST_DIST**: 融合计算 `(x^2 + y^2)^0.5` 的过程。在图形处理或物理模拟中极大地减少了指令分发开销。
  - **OP_FUSE_GETSUB / OP_FUSE_GETADD**: 将表查找 (`GETTABLE`) 与算术运算 (`SUB`/`ADD`) 融合成单条指令。
  - **OP_FUSE_GETGETSUB**: 融合两次表查找和一次减法。
  - **OP_FUSE_PARTICLE_DIST**: 专为粒子引擎优化的距离计算指令。

## 2. 词法分析器深度定制 (llex.c)
词法解析器不仅仅增加了关键字，还修改了字符识别逻辑：

### 2.1 快捷操作符识别
在 `llex` 函数中，通过检测字符并利用 `check_next1` 实现多字符组合。
例如：
```c
case '!': {
  next(ls);
  if (check_next1(ls, '=')) return TK_NE; // 识别 != 为不等于
  else return TK_NOT;                     // 识别 ! 为 not
}
```

### 2.2 LuaVMP 占位符
`TK_LUAVMP` 是一个特殊的 Token，用于标识经过混淆的代码入口或库函数。它在编译器中会被处理成一个稳定的内部标识符 `\1LuaVMP`。

## 3. 编译器优化逻辑 (lparser.c)

### 3.1 Lambda 实现
Lambda 并不是简单的语法糖，`lambda_body` 函数中实现了参数列表到表达式的快速映射。
它会新开一个 `FuncState`，解析参数，然后直接解析 `retstat`。

### 3.2 复合赋值的解析
在 `exprstat` 中处理赋值语句时，解析器会检测 `TK_PLUSEQ` 等。
它会将 `a += b` 内部展开为 `a = a + b`，但由于解析器直接操作 `expdesc`，它可以重用左值的解析结果，避免了多次冗余的表键查找。

## 4. 安全机制：指令动态解密
在 `lvm.c` 的主分发循环中：
```c
Instruction i = *ci->u.l.savedpc++;
if (cl->p->obfuscated) {
    i = DECRYPT_INST(i, (int)(ci->u.l.savedpc - 1 - cl->p->code), cl->p->inst_seed);
}
```
每条指令在执行前都会根据其在代码段中的位置 (`idx`) 和函数唯一的种子 (`seed`) 进行异或与位移还原。
这意味着内存中的字节码始终是加密态的，dump 到磁盘后更是无法直接阅读。

## 5. 指令融合匹配器 (lobfuscator.c)
混淆器 (Obfuscator) 在编译完成后，会扫描字节码模式并进行融合。
例如，如果它发现连续的指令符合特定的数学模式（如坐标计算），它会将它们替换为 `OP_FAST_DIST` 并填补 `OP_FUSE_NOP`。这种后期优化既提高了性能，又进一步干扰了反编译。
