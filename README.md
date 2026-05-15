# lua-async-await

此库是根据 [walterCui/lua-async](https://github.com/walterCui/lua-async) 修改而来，因原作者的库分散在了多个文件且命名部分跟随 C#, 部分跟随lua，所以统一修改并合并到一个文件中

This library is modified from [walterCui/lua-async](https://github.com/walterCui/lua-async). Since the original author's library was split across multiple files and its naming convention partially followed C# and partially followed Lua, it has been unified and merged into a single file.

测试代码(Test code)：

```lua
local task = require("task")
local async = task.async
local await = task.await
t = task.create()
t.result = 100
local tempAsync = async(function()
    print(123)
    local temp = await(t)
    print(temp)
    print(2)
end)
tempAsync()
print("xxx")
t:done()
```

输出(Output)：

```
123
xxx
100
2
```
