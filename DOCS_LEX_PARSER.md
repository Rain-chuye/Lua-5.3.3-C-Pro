# Lua-5.3.3-C-Pro 词法与语法深度解析文档

## 1. 词法分析器 (llex.c) 深度魔改

词法分析器（Lexer）负责将源代码字符流转换为标记（Token）。在本魔改版中，我们通过修改 `llex.c` 和 `llex.h`，引入了大量非标准的操作符和语法糖。

### 1.1 Token 枚举扩展 (llex.h)
我们新增了以下关键标记：
- `TK_LUAVMP`: 虚拟机占位符标记。
- `TK_LAMBDA`: 反斜杠 `\` 启动的 Lambda 表达式。
- `TK_LET`: `->` 操作符。
- `TK_MEAN`: `=>` 操作符。
- 复合赋值标记：`TK_PLUSEQ`, `TK_MINUSEQ`, `TK_MULTEQ`, 等。

### 1.2 核心词法识别逻辑 (llex.c)
在 `llex` 函数的大循环中，通过对特定字符的拦截实现新语法：

#### A. 复合赋值识别
```c
case '-': {
  next(ls);
  if (check_next1(ls, '>')) return TK_LET;   // 识别 ->
  if (check_next1(ls, '=')) return TK_MINUSEQ; // 识别 -=
  if (ls->current != '-') return '-';
  // ... 注释处理
}
```

#### B. 符号别名识别
为了兼容 C/Java 习惯，魔改版直接在词法层面替换了逻辑运算符：
```c
case '!': {
  next(ls);
  if (check_next1(ls, '=')) return TK_NE; // != 映射为 TK_NE (~=)
  else return TK_NOT;                     // ! 映射为 TK_NOT (not)
}
case '&': {
  next(ls);
  if (check_next1(ls, '&')) return TK_AND; // && 映射为 TK_AND (and)
  return '&'; // 位与保持不变
}
```

#### C. 快捷声明与标签
- `$`: 直接映射为 `TK_LOCAL`。
- `@`: 直接映射为 `TK_DBCOLON` (用于 Label)。

---

## 2. 语法特性代码事例 (Magic Syntax Examples)

### 2.1 极简 Lambda (匿名函数)
**语法**: `\参数 -> 表达式` 或 `\参数 => 语句`

```lua
-- 带返回值的 Lambda
$ sum = \x, y -> x + y
print(sum(1, 2)) -- 3

-- 执行单条语句的 Lambda
$ log = \msg => print("[LOG]: " .. msg)
log("System Init") -- [LOG]: System Init

-- 嵌套使用
$ factory = \base -> \val -> base + val end
$ add5 = factory(5)
print(add5(10)) -- 15
```

### 2.2 Switch-Case 增强版
**语法**: `switch 变量 do case ... then ... end`

```lua
$ mode = "fast"

switch mode do
  case "slow" then
    print("Processing slowly...")
  case "fast", "turbo" then
    -- 支持多值匹配
    print("High speed enabled")
  default
    print("Default speed")
end
```

### 2.3 Defer 延迟执行
**用途**: 确保资源在函数退出前被释放。

```lua
function process_data()
  $ db = connect_database()
  -- 无论函数因何种原因结束，都会执行 defer 块
  defer db:close(); print("DB connection released") end

  if !db:is_alive() then return end
  db:insert("data")
end
```

### 2.4 快捷变量与复合运算
```lua
$ i = 1          -- 等同于 local i = 1
i += 1           -- 等同于 i = i + 1
$ flag = !false  -- 等同于 local flag = not false

if flag && i != 0 then
  print("Condition met")
end
```

---

## 3. 虚拟机指令融合 (VM Fusions)

为了使魔改版性能更佳，`lvm.c` 中实现了一系列指令融合。当编译器发现特定的连续操作时，会将其压缩为单条高性能指令。

| 指令 | 原始模式 | 优化效果 |
| :--- | :--- | :--- |
| `OP_FAST_DIST` | `(x*x + y*y)^0.5` | 减少 3 次分发开销 |
| `OP_FUSE_GETSUB` | `v = t.k; v = v - x` | 合并表查找与减法 |
| `OP_VIRTUAL` | 任意加密代码块 | 隐藏逻辑，执行 VMP 指令集 |

---

## 4. 后端选择：Pro VM vs LuaJIT

本工程现在支持双后端构建：

1. **Pro VM (默认)**:
   - 支持上述所有魔改语法。
   - 支持指令加密、VMP 混淆。
   - 字节码 SHA-256 校验。

2. **LuaJIT Backend**:
   - **极高性能**: 利用 LuaJIT 的跟踪编译技术。
   - **语法限制**: 暂不支持 Pro VM 的专用语法（如 `\`, `switch`）。
   - **建议**: 在需要高性能计算且不依赖加密/特殊语法的情况下使用。

构建命令：
- `make pro`: 构建 Pro 5.3 环境。
- `make jit`: 构建 LuaJIT 环境。
