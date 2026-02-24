# LuaJIT-Pro: 高性能魔改版虚拟机文档

## 1. 简介
LuaJIT-Pro 是将 Lua-5.3.3-C-Pro 的核心特性移植到 LuaJIT 2.1 后的产物。它结合了 Pro 版本的安全性、语法便捷性以及 LuaJIT 的极致性能。

## 2. 核心特性移植进度

### 2.1 语法支持 (Lexer & Parser)
- [x] **Lambda 表达式**: 使用 `\` 启动，兼容 `->` 和 `=>`。
- [x] **Switch-Case**: 原生支持多分支选择。
- [x] **Defer 语句**: 作用域结束自动执行。
- [x] **复合赋值**: `+=`, `-=`, `*=`, `/=`, 等。
- [x] **符号别名**: `!` (not), `&&` (and), `||` (or), `$` (local), `@` (::)。
- [x] **Lua 5.3 位操作符**: `&`, `|`, `~`, `<<`, `>>`。
- [x] **Lua 5.3 整除**: `//`。

### 2.2 安全特性
- [x] **SHA-256 完整性校验**: 字节码内置魔改版 SHA-256 哈希，防止非法篡改。
- [ ] **指令加密**: 由于 LuaJIT 的汇编解释器架构，动态指令加密目前仅在解释模式下部分实现。

## 3. 魔改版词法示例 (llex.c 分析)

在 `lj_lex.c` 中，我们修改了字符扫描逻辑以支持这些符号：

```c
// 识别 != 和 !
case '!':
  lex_next(ls);
  if (ls->c == '=') { lex_next(ls); return TK_ne; }
  return TK_not;

// 识别 &&
case '&':
  lex_next(ls);
  if (ls->c == '&') { lex_next(ls); return TK_and; }
  return '&';
```

## 4. 完美转换：代码事例

### 4.1 逻辑运算与局部变量
```lua
$ a = 10
$ b = 20
if ! (a == b) && (a < b) then
  print("Pro logic works in JIT!")
end
```

### 4.2 复合赋值与位运算
```lua
$ x = 1
x <<= 3  -- 8
x |= 1   -- 9
x += 1   -- 10
print(x) -- 10
```

### 4.3 Lambda 与 Defer
```lua
$ process = \data ->
  defer print("Cleanup done") end
  return data * 2
end

print(process(21)) -- 42, then prints Cleanup
```

## 5. 构建说明
使用根目录的 Makefile 进行构建：
- `make jit`: 编译高性能 LuaJIT-Pro 后端。
- `make pro`: 编译高度加密的 Lua-5.3.3-Pro 后端。

## 6. 技术文档：词法部分
魔改版词法分析器支持以下非标准转换：
1. **标识符自动映射**: `$` 在词法阶段即被替换为 `local`，因此编译器无需修改原有局部变量处理逻辑。
2. **操作符多级检测**: 对于 `//=`，词法器会连续消耗三个字符并返回 `TK_idiveq`。
3. **Lambda 起始符**: `\\` 被定义为 `TK_lambda`，在解析器中触发匿名函数解析。
