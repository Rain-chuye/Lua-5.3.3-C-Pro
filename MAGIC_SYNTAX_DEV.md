# 开发者指南：如何为 Lua 添加魔改语法

如果你想基于本项目继续扩展 Lua 的语法，请遵循以下步骤：

## 第一步：定义 Token (llex.h)
在 `RESERVED` 枚举中添加你的新关键字或操作符。
```c
enum RESERVED {
  /* ... 现有 ... */
  TK_MY_OP,
  /* ... */
}
```

## 第二步：在词法分析器中捕获字符 (llex.c)
在 `llex` 函数中，编写字符检测逻辑。
- 使用 `next(ls)` 步进到下一个字符。
- 使用 `check_next1(ls, 'x')` 检测并消耗下一个字符。
- 返回你定义的 `TK_*` 标记。

## 第三步：在解析器中处理语法 (lparser.c)
这是最关键的一步。

### 1. 处理语句级语法 (Statement)
在 `statement` 函数的 `switch (ls->t.token)` 块中添加你的逻辑。
**示例：添加 `unless` 语法**
```c
case TK_UNLESS: {
  luaX_next(ls); // 跳过 unless
  // 解析表达式 ...
  // 生成 JMP 指令 ...
  break;
}
```

### 2. 处理表达式级语法 (Expression)
在 `primaryexp` 或 `subexpr` 中添加操作符的处理。

## 第四步：虚拟机支持 (lvm.c / lopcodes.h)
如果你的语法引入了新的底层操作，需要在 `lopcodes.h` 定义新 OpCode，并在 `lvm.c` 的 `luaV_execute` 中编写执行逻辑。

---

## 本项目已实现的魔改技巧
- **符号重映射**: 将 `!` 直接映射为 `TK_NOT`，无需修改解析逻辑。
- **单字符别名**: 将 `$` 映射为 `TK_LOCAL`，解析器会将其视作传统的 `local`。
- **指令融合**: 编译器扫描生成的代码，将特定序列替换为新的融合指令，以绕过标准反编译工具并提速。
