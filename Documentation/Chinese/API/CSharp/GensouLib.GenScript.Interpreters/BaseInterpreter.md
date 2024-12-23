# BaseInterpreter

派生：[ConditionInterpreter](ConditionInterpreter.md), [VariableInterpreter](VariableInterpreter.md)

## 描述

`BaseInterpreter` 是 `Genscript` 的基础解释器类，主要负责将脚本内容拆分成命令行，并移除注释。它还提供了对[控制台命令](../../../Genscript/Category/Console.md)的处理，并包含一些常用的字符串处理工具方法。

## 静态方法

|[ParseScript](#baseinterpreterparsescript)|分割整个脚本文件为命令行，并排除其中的注释内容。|
|:--|:--|
|[HandleDebugOutput](#baseinterpreterhandledebugoutput)|处理控制台输出的命令。|
|[ReplacePlaceholders](#baseinterpreterreplaceplaceholders)|替换文本中的转义字符和变量。|
|[TryParseNumeric](#baseinterpretertryparsenumeric)|尝试将字符串解析为数字。|

---

# BaseInterpreter.ParseScript

`public static void ParseScript(string scriptContent)`  
`public static void ParseScript(string scriptContent, Node node)`

## 参数

|`scriptContent`|脚本读取器获取到的脚本文本内容。|
|:--|:--|
|`node`|（Godot平台）挂载到自动加载的脚本初始化器节点。|

## 描述

将传入的脚本文本内容拆分为命令行，并逐行处理命令。在处理每一行时，注释会被移除，之后每一行命令会传递给 [命令执行器](ScriptExecutor.md) 进行进一步执行。特别地，方法会处理[多行日志命令](../../../Genscript/Category/Console.md/#-n)，直到退出多行日志模式时，才会继续处理每行命令。

如果在 **Godot** 平台上使用，`node` 参数需要传入一个挂载到自动加载脚本初始化器节点的 `Node` 对象，支持后续脚本执行的上下文。一般来说，应该传入挂载到自动加载的脚本初始化器节点，或者其他任意被挂载为自动加载的节点。

---

# BaseInterpreter.HandleDebugOutput

`public static void HandleDebugOutput(string code)`

## 参数

|`code`|经由[命令执行器](ScriptExecutor.md)进一步解析后的命令行。|
|---|---|

## 描述

`Genscript`的控制台命令解释器，负责解析并执行控制台命令，支持多行日志输出、转义符替换、数学表达式计算（仅限单行控制台输出）、变量插值。

---

# BaseInterpreter.ReplacePlaceholders

`public static string ReplacePlaceholders(string input)`

## 参数

|`input`|需要替换占位符的字符串。|
|---|--|

## 描述

替换输入字符串中的占位符。它会处理所有定义的转义符，并且支持将 `Genscript` 中定义的有效变量替换为其对应的值。 

方法内部定义的转义符：

|转义符|替换内容|  
|---|---|  
|`\}`|替换为 `}`|  
|`\{`|替换为 `{`|  
|`\/`|替换为 `/`|  
|`\+`|替换为 `+`|  
|`\-`|替换为 `-`|  
|`\*`|替换为 `*`|  
|`\%`|替换为 `%`|  
|`\\`|替换为 `\`|  
|`\"`|替换为 `"`|  

---

# BaseInterpreter.TryParseNumeric

`public static bool TryParseNumeric(string input, out object result)`

## 参数

|`inpt`|需要解析为数字的字符串。|
|---|---|
|`result`|字符串解析为数字后的数值。解析失败时，值为`null`。|

## 描述

尝试将输入的字符串解析为整数或浮点数，然后返回解析结果。

## 返回

如果字符串是有效的整数或浮点数格式，则返回`true`和对应的数值；否则，返回`false`和`null`。