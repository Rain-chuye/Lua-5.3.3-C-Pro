-- Lua-5.3.3-C-Pro 语法示例

-- 1. 局部变量与复合赋值
$ count = 0
count += 10
count *= 2
print("Count is:", count) -- 20

-- 2. Lambda 表达式
$ list = {1, 2, 3, 4, 5}
$ map = \t, f ->
  $ res = {}
  for i,v in ipairs(t) do
    res[i] = f(v)
  end
  return res
end

$ squares = map(list, \x -> x * x)
print("Squares:", table.concat(squares, ", "))

-- 3. Defer 资源管理
function open_and_read(name)
  print("Opening file...")
  defer print("File closed (deferred).") end
  print("Reading from "..name)
  if name == "error" then return error("failed") end
  return "data"
end

open_and_read("test.txt")

-- 4. Switch-Case
$ op = "+"
$ x, y = 10, 5
$ result = 0

switch op do
  case "+" then result = x + y
  case "-" then result = x - y
  case "*", "x" then result = x * y
  default print("Unknown op")
end
print("Result:", result)

-- 5. When 表达式
$ score = 85
when score >= 90 then
  print("Excellent")
case score >= 60 then
  print("Pass")
else
  print("Fail")
end

-- 6. 新操作符
if !false && (1 != 2 || true) then
  print("Logical operators work!")
end

-- 7. 标签与 Goto
@loop_start
print("In loop")
-- goto loop_start -- 注意死循环
