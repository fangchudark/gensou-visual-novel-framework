## 变量命令解释器 [br]
## Variable command interpreter
##
## 提供变量声明赋值，数学表达式处理以及变量释放功能。[br]
## Provides variable declaration and assignment, mathematical expression processing and variable release functions
class_name VariableInterpreter extends BaseInterpreter

## int最大值[br]
## int Max value
const INT_MAX = 9223372036854775807

## int最小值[br]
## int Min value 
const INT_MIN = -9223372036854775808

## 不可用作变量名的保留关键字列表[br]
## List of reserved keywords that cannot be used as variable names. 
static var key_words: PackedStringArray = [
	"when",
	"release"
]

## 变量字典，键为变量名，值为变量值[br]
## Variable dictionary, where the key is the variable name and the value is the variable value.  
static var variable_list: Dictionary = {}


## 处理变量字符串赋值[br]
## Handles variable string assignment.[br]
## 该方法解析赋值语句中的变量名和值表达式，并根据赋值类型（字符串或表达式）进行适当处理。 [br]
## This method parses the variable name and value expression in an assignment statement and processes it according to whether the value is a string or an expression. [br]
## [br]
## [param code] : [br]
## 命令标识符后的代码，其中包括变量名和赋值表达式。 [br]
## The code following the command identifier, which includes the variable name and assignment expression. 
static func handle_variable_assignment(code: String) -> void:
	# 获取变量名和赋值表达式
	var var_name = code.substr(0, code.find("=")).strip_edges()  # 获取变量名
	var value_expression = code.substr(code.find("=") + 1).strip_edges()  # 获取赋值表达式
	
	# 检查变量名是否有效
	if not check_variable_name(var_name):
		push_error("Variable name invalid (变量名不合法)")  # 如果变量名无效，报错并返回
		return
	
	# 处理字符串赋值
	if value_expression.begins_with("\"") and value_expression.ends_with("\""):
		value_expression = value_expression.substr(1, value_expression.length() - 2).strip_edges()  # 去除字符串的引号
		variable_list[var_name] = value_expression  # 将值赋给变量
		return
	
	# 如果赋值表达式不是字符串，则检查并处理表达式
	if not check_expression(value_expression):
		_assign_value(var_name, value_expression)  # 如果是有效的赋值表达式，进行赋值
		return
		
	# 处理复杂表达式赋值
	_process_expression_assignment(var_name, value_expression)  # 处理更复杂的表达式赋值


# 变量赋值
static func _assign_value(var_name: String, value: String) -> void:
	# 初始化要赋值的变量
	var value_to_assign = value

	# 检查值是否引用已有变量
	if variable_list.has(value):
		value_to_assign = variable_list[value]
	# 检查值是否为有效的整数
	elif value.is_valid_int():
		if check_int_overflow(value):
			# 如果整数溢出，警告用户，并将其存储为浮点数
			push_warning("Long integer variable: %s data size overflow (attempted to assign: %s), stored as floating-point. (长整型变量: %s 数据大小溢出 (尝试赋值: %s), 已将其储存为浮点数型)" % [var_name, value, var_name, value])
			value_to_assign = value.to_float()
		else:
			value_to_assign = value.to_int()
	# 检查值是否为有效的浮点数
	elif value.is_valid_float():
		value_to_assign = value.to_float()
	# 检查值是否为布尔型字符串
	elif try_parse_str_to_bool(value)["success"]:
		value_to_assign = try_parse_str_to_bool(value)["result"]

	# 将最终处理后的值存储到变量列表中
	variable_list[var_name] = value_to_assign


# 有表达式的变量赋值
static func _process_expression_assignment(var_name: String, value_expression: String) -> void:
	# 将中缀表达式转换为后缀表达式
	var postfix_expression = intfix_to_postfix(value_expression)
	# 评估后缀表达式获取结果
	var result = evaluate_postfix(postfix_expression)
	
	# 初始化存储值
	var value_to_store = null
	
	# 检查结果是否为有效的整数
	if result.is_valid_int():
		if check_int_overflow(result):
			# 如果整数溢出，将其转换为浮点数并发出警告
			push_warning("Long integer variable: %s data size overflow (attempted to assign: %s), stored as floating-point. (长整型变量: %s 数据大小溢出 (尝试赋值: %s), 已将其储存为浮点数型)" % [var_name, value_expression, var_name, value_expression])
			value_to_store = result.to_float()
		else:
			value_to_store = result.to_int()
	# 检查结果是否为有效的浮点数
	elif result.is_valid_float():
		value_to_store = result.to_float()
	else:
		# 如果结果无效，报告错误并返回
		push_error("Variable: %s cannot be assigned, unexpected target value: %s (变量: %s 无法赋值,意外的目标值: %s)" % [var_name, result, var_name, result])
		return
		
	# 如果值有效，将其存储到变量列表中
	if value_to_store != null:
		variable_list[var_name] = value_to_store
	else:
		# 如果值仍无效，再次报告错误
		push_error("Variable: %s cannot be assigned, unexpected target value: %s (变量: %s 无法赋值,意外的目标值: %s)" % [var_name, result, var_name, result])


## 处理变量声明 [br]
## Handles variable declaration. [br]
## 该方法用于声明一个新变量。如果变量名不合法或变量已存在，会进行错误提示。 [br]
## This method declares a new variable. If the variable name is invalid or the variable already exists, an error is raised. [br]
## [br]
## [param code] : [br]
## 变量声明的代码部分，通常是变量名。 [br]
## The code representing the variable declaration, typically the variable name.
static func handle_variable_declaration(code: String) -> void:
	# 检查变量名是否合法
	if not check_variable_name(code):
		# 如果变量名不合法，记录错误并返回
		push_error("Variable name: %s invalid (变量名: %s 不合法)" % [code, code])
		return

	# 检查变量是否已经存在
	if variable_list.has(code):
		# 如果变量已存在，记录错误
		push_error("Variable: %s already exists (变量: %s 已存在)" % [code, code])
	else:
		# 如果变量不存在，初始化为空字符串
		variable_list[code] = ""


## 从变量字典释放一个变量 [br]
## Releases a variable from the variable dictionary. [br]
## 该方法用于从变量列表中移除指定变量，如果变量存在于列表中，则将其删除。 [br]
## This method removes the specified variable from the variable dictionary if it exists. [br]
## [br]
## [param variable] : [br]
## 要释放的变量名 [br]
## The name of the variable to release.
static func release_variable(variable: String) -> void:
	# 检查变量字典中是否存在指定变量
	if variable_list.has(variable):
		# 如果变量存在，从字典中删除
		variable_list.erase(variable)
	return


## Shunting Yard 算法，转换中缀表达式为后缀表达式[br]
## Shunting Yard algorithm, converts infix expressions to postfix expressions. [br]
## 请直接将返回的值传入[method evaluate_postfix]方法 [br]
## Please directly pass the returned value to the [method evaluate_postfix] method.[br]
## [br]
## [param input] : [br]
## 中缀表达式 [br]
## Infix expression [br]
## [br]
## 返回转换后的后缀表达式，或错误标识：[br]
## Returns the converted postfix expression, or error indicators: [br][b]
## - "InvalidExpression" : [br]
## ·        表示输入的表达式无效。/ Indicates that the input expression is invalid.[br]
## - "UnknownOperator" : [br] 
## ·        表示表达式中包含未知运算符。/ Indicates that the expression contains an unknown operator.[br]
## - "UndefinedVariable" : [br]
## ·        表示表达式中使用了未定义的变量。/ Indicates that the expression uses an undefined variable.[br]
## - "InvalidVariableType" : [br]
## ·        表示表达式中使用了不合法的变量类型。/ Indicates that an invalid variable type is used in the expression.[/b]
static func intfix_to_postfix(input: String) -> Array[String]:
	input = input.replace(" ", "")  # 去除输入中的所有空格
	var output: Array[String]  # 存储后缀表达式的结果
	var operators: Array[String]  # 存储操作符的栈
	var precedence: Dictionary = {  # 定义运算符的优先级
		"+": 1,
		"-": 1,
		"%": 2,
		"*": 2,
		"/": 2
	}

	var regex = RegEx.new()  # 正则表达式匹配
	regex.compile(r"(?<=^|[(]|[+\-*/%])-\d+(\.\d+)?|(?<=^|[(]|[+\-*/%])-\p{L}[\p{L}\p{N}_]*|\d+(\.\d+)?|[+\-*/%()]|[\p{L}][\p{L}\p{N}_]*")
	for reuslt in regex.search_all(input):  # 遍历匹配的每个标记
		var token = reuslt.get_string() # 提取匹配的字符串
		if token.is_valid_float():  # 如果是数字，直接加入输出
			output.append(token)
		elif token == "-":  # 处理负号的情况
			if output.size() == 0 or output.back() == "(" or precedence.has(output.back()): # 检查前一个 token
				output.append("0")  # 将负号变为 0 减去数值
				operators.push_front(token) # 将负号入栈
			else:
				if output.size() < 1:  # 操作符之前无操作数
					push_error("Invalid expression: unexpected operator. (意外的操作符)")
					return ["InvalidExpression"]
				while operators.size() > 0 and precedence.has(operators.front()) and precedence[operators.front()] >= precedence[token]:
					output.append(operators.pop_front()) # 将栈中优先级不低于当前运算符的运算符弹出并添加到输出
				operators.push_front(token) # 当前运算符入栈
		elif token.begins_with("-") and variable_list.has(token.substr(1).strip_edges()):  # 处理负变量
			var value = variable_list[token.substr(1).strip_edges()]
			if value is float or value is int:
				output.append(str(-value)) # 将变量值取出并转为负数
			else:
				push_error("Invalid variable type for: %s (变量类型无效: %s)" % [token.substr(1), token.substr(1)])
				return ["InvalidVariableType"]
		elif precedence.has(token):  # 操作符处理
			if output.size() < 1:  # 操作符之前无操作数
				push_error("Invalid expression: unexpected operator. (意外的操作符)")
				return ["InvalidExpression"]
			while operators.size() > 0 and precedence.has(operators.front()) and precedence[operators.front()] >= precedence[token]:
				output.append(operators.pop_front()) # 将栈中优先级不低于当前运算符的运算符弹出并添加到输出
			operators.push_front(token) # 当前运算符入栈
		elif token == "(":  # 左括号直接入栈
			operators.push_front(token)
		elif token == ")":  # 右括号处理
			while operators.size() > 0 and operators.front() != "(":
				output.append(operators.pop_front()) # 弹出所有运算符直到遇到左括号
			if operators.size() == 0:  # 括号不匹配
				push_error("Invalid expression: mismatched parentheses. (括号不匹配)")
				return ["InvalidExpression"]
			operators.pop_front() # 弹出左括号
		else:  # 变量处理
			if variable_list.has(token):
				var value = variable_list[token]
				if value is float or value is int: # 检查是否为数值类型
					output.append(str(value)) # 将变量值加入输出
				else:
					push_error("Invalid variable type for: %s (变量类型无效: %s)" % [token, token])
					return ["InvalidVariableType"]
			else:
				push_error("Undefined variable: %s (未定义的变量: %s)" % [token, token])
				return ["UndefinedVariable"]
	while operators.size() > 0:  # 将剩余的操作符加入输出
		var op = operators.pop_front()
		if precedence.has(op): # 只添加有效的运算符
			output.append(op)
		else:  # 未知操作符
			push_error("Unknown operator: %s (未知运算符: %s )" % [op, op])
			return ["UnknownOperator"]
	if output.size() == 0 or operators.size() > 0:  # 检查表达式是否完整
		push_error("Invalid expression: incomplete or malformed. (不完整的表达式)")
		return ["InvalidExpression"]
	return output  # 返回后缀表达式
	

## 计算后缀表达式的值[br]
## Calculate the value of the postfix expression. [br]
## [br]
## [param postfix] : [br]
## 将中缀表达式由 [method intfix_to_postfix] 方法转换后得到的后缀表达式。 [br]
## The postfix expression obtained by converting the infix expression using the [method intfix_to_postfix] method. [br]
## 该表达式应包含有效的运算符和操作数。[br]
## This expression should contain valid operators and operands.[br]
## [br]
## 返回计算得到的结果字符串，或者返回错误标识：[br]
## Returns the calculated result string, or an error indicator: [br][b]
## - "InvalidExpression" : [br]
## ·        表示输入的表达式无效。/ Indicates that the input expression is invalid.[br]
## - "UnknownOperator" : [br] 
## ·        表示表达式中包含未知运算符。/ Indicates that the expression contains an unknown operator.[br]
## - "UndefinedVariable" : [br]
## ·        表示表达式中使用了未定义的变量。/ Indicates that the expression uses an undefined variable.[br]
## - "InvalidVariableType" : [br]
## ·        表示表达式中使用了不合法的变量类型。/ Indicates that an invalid variable type is used in the expression.[br]
## - "DivisionInvalid" : [br]
## ·        表示尝试进行非法的除法运算（如除以零）。 / Indicates an attempt to perform an illegal division operation (e.g., division by zero).[/b]
static func evaluate_postfix(postfix: Array[String]) -> String:
	# 检查后缀表达式是否包含已知的错误标识
	if postfix.size() ==  1 and postfix[0] == "InvalidExpression":
		return "InvalidExpression"
	if postfix.size() ==  1 and postfix[0] == "UnknownOperator":
		return "UnknownOperator"
	if postfix.size() ==  1 and postfix[0] == "UndefinedVariable":
		return "UndefinedVariable"
	if postfix.size() ==  1 and postfix[0] == "InvalidVariableType":
		return "InvalidVariableType"
	
	var stack: Array[float] # 用于操作数的栈
	
	for token in postfix:  # 遍历后缀表达式的每个标记
		if token.is_valid_float(): # 如果是数值，将其压入栈中
			stack.push_front(token.to_float())
		else:
			if stack.size() < 2: # 如果操作数不足，则表达式无效
				push_error("Invalid expression: not enough operands. (操作数不足)")
				return "InvalidExpression"
			var right_operand = stack.pop_front()  # 弹出右操作数
			var left_operand = stack.pop_front()  # 弹出左操作数
			
			match token:
				"+": # 加法
					stack.push_front(left_operand + right_operand)
				"-": # 减法
					stack.push_front(left_operand - right_operand)
				"*": # 乘法
					stack.push_front(left_operand * right_operand)
				"/": # 除法
					if right_operand == 0:  # 检查除零错误
						push_error("Division by zero is not allowed. (除数不能为0)")
						return "DivisionInvalid"
					stack.push_front(left_operand / right_operand)
				"%": # 求余
					stack.push_front(fposmod(left_operand, right_operand))
				_: # 未知操作符
					push_error("Unknown operator: %s (未知运算符: %s)" % [token,token])
					return "UnknownOperator"
	return str(stack.pop_front()) # 返回计算结果


## 检查整数溢出 [br]
## Check for integer overflow. [br]
## [br]
## [param value] : [br]
## 要检查的值，作为字符串传入。 [br]
## The value to check, passed as a string. [br]
## [br]
## 如果值会导致整数溢出，返回 true；否则返回 false。 [br]
## Returns true if the value causes integer overflow, otherwise false. [br]
static func check_int_overflow(value: String) -> bool:
	# 获取最大和最小整数的字符串表示
	var int_max_str = str(INT_MAX)
	var int_min_str = str(INT_MIN)
	
	# 检查值的长度是否超过了最大或最小整数的长度
	if value.length() > int_max_str.length() or value.length() > int_min_str.length():
		return true
	
	# 如果值的长度与最大或最小整数相等，进行进一步比较
	if value.length() == int_max_str.length() or value.length() == int_min_str.length():
		 # 去除符号并进行比较
		var value_without_sign = value.strip_edges().substr(1, value.length() - 1) if value.begins_with("-") else value.strip_edges()
		var max_check_str = int_max_str if not value.begins_with("-") else int_min_str
		var max_compare = int_max_str if not value.begins_with("-") else int_min_str
		
		# 比较数字的高位部分
		if value_without_sign.substr(0, value_without_sign.length() - 1).to_int() > max_check_str.substr(0, value_without_sign.length() - 1).to_int():
			return true # 如果高位部分大于最大值或最小值，表示溢出

		# 如果高位部分相同，比较低位部分
		elif value_without_sign.substr(0, value_without_sign.length() - 1).to_int() == max_check_str.substr(0, value_without_sign.length() - 1).to_int():
			if value[-1].to_int() > max_compare[-1].to_int(): # 如果低位部分大于最大值的低位
				return true # 表示溢出

	return false # 如果没有发生溢出，返回 false


## 检查变量名是否合法[br]
## Check if the variable name is valid [br]
## 该方法用于检查输入的变量名是否符合命名规则： [br]
## This method checks if the input variable name conforms to the naming rules: [br][b]
## - 变量名必须以字母（包括 Unicode 字符）或下划线开头，后续字符可以是字母、数字或下划线。 [br]
## - The variable name must start with a letter (including Unicode characters) or an underscore, and subsequent characters can be letters, numbers, or underscores. [br]
## - 变量名不能是保留字（如 "false" 或 "true"）。 [br]
## - The variable name cannot be a reserved word (such as "false" or "true"). [br]
## - 变量名不能是已知的关键字（存储在 [member key_words] 集合中）。 [br]
## - The variable name cannot be one of the known keywords (stored in the [member key_words] set). [br][/b]
## [br]
## [param name] : [br]
## 输入的变量名，作为字符串表示。 [br]
## The input variable name, represented as a string. [br]
## [br]
## 返回布尔值，指示输入的变量名是否合法。[br]
## Returns a boolean value indicating whether the input variable name is valid. [br]
## 如果变量名符合这些规则，返回 true；否则返回 false。 [br]
## If the variable name follows these rules, it returns true; otherwise, it returns false. [br]
## [br]
static func check_variable_name(name: String) -> bool:
	var regex = RegEx.new() # 创建正则表达式对象，用于检查变量名的格式
	regex.compile(r"^[\p{L}_][\p{L}\p{N}_]*")
	 # 如果变量名符合正则规则且不等于 "false" 或 "true" 且不在保留关键字中
	if (regex.search(name) # 检查是否匹配正则表达式
	and name.nocasecmp_to("false") # 确保不等于 "false"
	and name.nocasecmp_to("true") # 确保不等于 "true"
	and not key_words.has(name)): # 确保不在关键字集合中
		return true # 如果满足所有条件，返回 true
	return false # 如果不满足条件，则返回 false


## 检查表达式的有效性[br]
## Check if the given expression is valid [br]
## 该方法用于检查给定的表达式是否符合有效的格式。 [br]
## This method checks if the given expression conforms to a valid format: [br][b]
## - 如果表达式以非法的操作符（如 "+"、"*"、"/" 或 "%"）开头，表达式无效。 [br]
## - If the expression starts with an invalid operator (such as "+", "*", "/", or "%"), the expression is invalid. [br]
## - 表达式中的每个部分必须是有效的数字（浮点或整数）或已定义的变量名。 [br]
## - Each part of the expression must be a valid number (floating point or integer) or a defined variable name. [br]
## - 表达式必须包含至少一个有效的运算符（如 "+"、"-"、"*" 或 "%"）。 [br]
## - The expression must contain at least one valid operator (such as "+", "-", "*", or "%"). [br][/b]
## [br]
## [param expression] : [br]
## 输入的表达式，作为字符串表示。 [br]
## The input expression, represented as a string. [br]
## [br]
## 返回布尔值，指示表达式是否有效。[br]
## Returns a boolean value indicating whether the expression is valid. [br]
## 如果表达式符合上述规则，返回 true；否则返回 false。 [br]
## If the expression follows the above rules, it returns true; otherwise, it returns false. [br]
## [br]
static func check_expression(expression: String) -> bool:
	 # 如果表达式以非法操作符开始，直接返回 false
	if (expression.begins_with("+")
	or expression.begins_with("*")
	or expression.begins_with("/")
	or expression.begins_with("%")):
		return false
	
	var regex = RegEx.new() # 创建正则表达式对象，用于匹配表达式中的数字或变量名
	regex.compile(r"[^\+\-\*/%\s]+")
	for part in regex.search_all(expression): # 遍历表达式中的每一部分，如果它不是有效的数字且也不是已定义的变量名，则返回 false
		var op = part.get_string()
		if not op.is_valid_float() and not check_variable_name(op):
			return false
	
	var regex_op = RegEx.new() # 创建正则表达式对象，用于检查表达式是否包含有效的运算符
	regex_op.compile(r"(?<!\\)([+\-*/%])")
	if not regex_op.search_all(expression): # 如果表达式不包含运算符，返回 false
		return false
	return true  # 如果表达式符合所有条件，返回 true
	

## 尝试获取指定变量的值[br]
## Try to get the value of the specified variable [br]
## [br]
## [param variable] : [br]
## 需要查找的变量名。 [br]
## The name of the variable to look for. [br]
## [br]
## 返回一个字典，包含查询结果和成功标记。[br]
## Returns a dictionary containing the query result and a success flag. [br]
## 如果变量列表中存在指定的变量，返回一个字典，包含变量值以及 [code]success: true[/code]，表示查询成功。 [br]
## If the variable is present in the list of variables, a dictionary is returned with the value and [code]success: true[/code] to indicate success.[br]
## 如果变量列表中不存在指定的变量，返回一个字典，包含 [code]result: null[/code] 和 [code]success: false[/code]，表示查询失败。 [br]
## If the specified variable doesn't exist in the variable list, return a dictionary with [code]result: null[/code] and [code]success: false[/code] to indicate that the query failed. [br]
## [br]
## 示例： [br]
## Example: [br]
## 变量存在:[code]{"result": 42, "success": true}[/code][br]
## Variable exist:[code]{"result": 42, "success": true}[/code] [br]
## 变量不存在:[code]{"result": null, "success": false}[/code][br]
## Variable does not exist:[code]{"result": null, "success": false}[/code]
static func try_get_variable_value(variable: String) -> Dictionary:
	# 检查变量列表中是否包含指定的变量
	if variable_list.has(variable):
		# 如果变量存在，获取其值
		var value = variable_list[variable]
		# 返回包含结果和值的字典，表示查询成功
		return {
			"result": value,
			"success": true
		}
	# 如果变量不存在，返回 null 和失败标记
	return {
		"result": null,
		"success": false
	}
