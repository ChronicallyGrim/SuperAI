-- Module: code_generator.lua
-- Advanced Lua code generation and programming assistance

local M = {}

-- ============================================================================
-- CODE TEMPLATES
-- ============================================================================

M.templates = {
    -- Basic structures
    basic = {
        ["for loop"] = [[
for i = 1, %d do
    %s
end]],
        ["while loop"] = [[
while %s do
    %s
end]],
        ["if statement"] = [[
if %s then
    %s
end]],
        ["function"] = [[
function %s(%s)
    %s
end]],
        ["table"] = [[
local %s = {
    %s
}]],
    },
    
    -- ComputerCraft specific
    computercraft = {
        ["turtle move"] = [[
function move%s(distance)
    for i = 1, distance do
        if not turtle.%s() then
            return false
        end
    end
    return true
end]],
        ["turtle dig pattern"] = [[
function digPattern(width, length)
    for row = 1, length do
        for col = 1, width do
            turtle.dig()
            turtle.forward()
        end
        if row < length then
            if row % 2 == 1 then
                turtle.turnRight()
                turtle.dig()
                turtle.forward()
                turtle.turnRight()
            else
                turtle.turnLeft()
                turtle.dig()
                turtle.forward()
                turtle.turnLeft()
            end
        end
    end
end]],
        ["inventory manager"] = [[
function manageInventory()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            print("Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
        end
    end
end]],
    },
    
    -- File operations
    file_operations = {
        ["read file"] = [[
function readFile(filename)
    local file = fs.open(filename, "r")
    if not file then return nil end
    local content = file.readAll()
    file.close()
    return content
end]],
        ["write file"] = [[
function writeFile(filename, content)
    local file = fs.open(filename, "w")
    if not file then return false end
    file.write(content)
    file.close()
    return true
end]],
        ["append file"] = [[
function appendFile(filename, content)
    local file = fs.open(filename, "a")
    if not file then return false end
    file.writeLine(content)
    file.close()
    return true
end]],
    },
    
    -- Data structures
    data_structures = {
        ["queue"] = [[
local Queue = {}
Queue.__index = Queue

function Queue.new()
    return setmetatable({items = {}}, Queue)
end

function Queue:enqueue(item)
    table.insert(self.items, item)
end

function Queue:dequeue()
    return table.remove(self.items, 1)
end

function Queue:isEmpty()
    return #self.items == 0
end]],
        ["stack"] = [[
local Stack = {}
Stack.__index = Stack

function Stack.new()
    return setmetatable({items = {}}, Stack)
end

function Stack:push(item)
    table.insert(self.items, item)
end

function Stack:pop()
    return table.remove(self.items)
end

function Stack:isEmpty()
    return #self.items == 0
end]],
        ["linked list"] = [[
local Node = {}
function Node.new(value)
    return {value = value, next = nil}
end

local LinkedList = {}
LinkedList.__index = LinkedList

function LinkedList.new()
    return setmetatable({head = nil, size = 0}, LinkedList)
end

function LinkedList:append(value)
    local newNode = Node.new(value)
    if not self.head then
        self.head = newNode
    else
        local current = self.head
        while current.next do
            current = current.next
        end
        current.next = newNode
    end
    self.size = self.size + 1
end

function LinkedList:toArray()
    local array = {}
    local current = self.head
    while current do
        table.insert(array, current.value)
        current = current.next
    end
    return array
end]],
    },
    
    -- Algorithms
    algorithms = {
        ["bubble sort"] = [[
function bubbleSort(arr)
    local n = #arr
    for i = 1, n do
        for j = 1, n - i do
            if arr[j] > arr[j + 1] then
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
            end
        end
    end
    return arr
end]],
        ["binary search"] = [[
function binarySearch(arr, target)
    local left, right = 1, #arr
    while left <= right do
        local mid = math.floor((left + right) / 2)
        if arr[mid] == target then
            return mid
        elseif arr[mid] < target then
            left = mid + 1
        else
            right = mid - 1
        end
    end
    return nil
end]],
        ["fibonacci"] = [[
function fibonacci(n)
    if n <= 1 then return n end
    return fibonacci(n - 1) + fibonacci(n - 2)
end

-- Optimized version with memoization
local memo = {}
function fibonacciMemo(n)
    if n <= 1 then return n end
    if memo[n] then return memo[n] end
    memo[n] = fibonacciMemo(n - 1) + fibonacciMemo(n - 2)
    return memo[n]
end]],
    },
}

-- ============================================================================
-- CODE GENERATION FUNCTIONS
-- ============================================================================

-- Generate function from description
function M.generateFunction(name, params, description)
    local paramStr = table.concat(params, ", ")
    local body = "    -- " .. description .. "\n    -- TODO: Implement logic here\n    return nil"
    
    return string.format([[
function %s(%s)
%s
end]], name, paramStr, body)
end

-- Generate class/module
function M.generateModule(moduleName, functions)
    local code = string.format("-- Module: %s.lua\n\nlocal M = {}\n\n", moduleName)
    
    for _, func in ipairs(functions) do
        code = code .. string.format([[
function M.%s(%s)
    -- TODO: Implement %s
    return nil
end

]], func.name, table.concat(func.params, ", "), func.description or func.name)
    end
    
    code = code .. "return M\n"
    return code
end

-- Generate loop
function M.generateLoop(loopType, iterations, body)
    if loopType == "for" then
        return string.format([[
for i = 1, %d do
    %s
end]], iterations, body or "-- code here")
    elseif loopType == "while" then
        return string.format([[
local i = 0
while i < %d do
    %s
    i = i + 1
end]], iterations, body or "-- code here")
    end
end

-- Generate conditional
function M.generateConditional(condition, thenBody, elseBody)
    local code = string.format("if %s then\n    %s\n", condition, thenBody)
    if elseBody then
        code = code .. string.format("else\n    %s\n", elseBody)
    end
    code = code .. "end"
    return code
end

-- ============================================================================
-- CODE ANALYSIS
-- ============================================================================

-- Detect what the user wants to code
function M.detectIntent(message)
    local lower = message:lower()
    
    -- Function creation
    if lower:find("function") or lower:find("create a function") or lower:find("write a function") then
        return "create_function"
    end
    
    -- Loop
    if lower:find("for loop") or lower:find("iterate") or lower:find("repeat") then
        return "create_loop"
    end
    
    -- Data structure
    if lower:find("queue") or lower:find("stack") or lower:find("list") or lower:find("tree") then
        return "create_data_structure"
    end
    
    -- Algorithm
    if lower:find("sort") or lower:find("search") or lower:find("algorithm") then
        return "create_algorithm"
    end
    
    -- File operations
    if lower:find("read file") or lower:find("write file") or lower:find("save") or lower:find("load") then
        return "file_operation"
    end
    
    -- Turtle operations
    if lower:find("turtle") or lower:find("mine") or lower:find("dig") or lower:find("move") then
        return "turtle_operation"
    end
    
    return "general"
end

-- Extract code requirements
function M.extractRequirements(message)
    local requirements = {
        functionName = nil,
        parameters = {},
        description = message,
        loopCount = nil,
        dataStructure = nil,
    }
    
    -- Extract function name
    local funcName = message:match("function%s+(%w+)")
    if funcName then
        requirements.functionName = funcName
    end
    
    -- Extract parameters
    local params = message:match("%(([^)]*)%)")
    if params then
        for param in params:gmatch("%w+") do
            table.insert(requirements.parameters, param)
        end
    end
    
    -- Extract loop count
    local count = message:match("%d+")
    if count then
        requirements.loopCount = tonumber(count)
    end
    
    return requirements
end

-- ============================================================================
-- CODE HELPERS
-- ============================================================================

-- Generate boilerplate for common tasks
function M.getBoilerplate(category)
    if M.templates[category] then
        local templates = M.templates[category]
        local names = {}
        for name, _ in pairs(templates) do
            table.insert(names, name)
        end
        return templates, names
    end
    return nil, nil
end

-- Get template by name
function M.getTemplate(category, name)
    if M.templates[category] and M.templates[category][name] then
        return M.templates[category][name]
    end
    return nil
end

-- List all available templates
function M.listTemplates()
    local list = {}
    for category, templates in pairs(M.templates) do
        list[category] = {}
        for name, _ in pairs(templates) do
            table.insert(list[category], name)
        end
    end
    return list
end

-- ============================================================================
-- CODE EXPLANATION
-- ============================================================================

M.explanations = {
    ["for"] = "A for loop repeats code a specific number of times. Syntax: for i = start, end do ... end",
    ["while"] = "A while loop repeats code while a condition is true. Syntax: while condition do ... end",
    ["if"] = "An if statement executes code only if a condition is true. Syntax: if condition then ... end",
    ["function"] = "A function is a reusable block of code. Syntax: function name(params) ... end",
    ["table"] = "A table is Lua's main data structure, can be array or dictionary. Syntax: local t = {}",
    ["pairs"] = "pairs() iterates over all key-value pairs in a table.",
    ["ipairs"] = "ipairs() iterates over array elements in order (1, 2, 3...).",
    ["return"] = "return sends a value back from a function.",
    ["local"] = "local creates a variable that only exists in the current scope.",
    ["require"] = "require loads and runs another Lua file as a module.",
}

-- Explain Lua concept
function M.explain(concept)
    local lower = concept:lower()
    for key, explanation in pairs(M.explanations) do
        if lower:find(key) then
            return explanation
        end
    end
    return "I'm not sure about that concept. Can you be more specific?"
end

-- ============================================================================
-- CODE GENERATION MAIN FUNCTION
-- ============================================================================

-- Generate code based on user request
function M.generate(message)
    local intent = M.detectIntent(message)
    local requirements = M.extractRequirements(message)
    
    if intent == "create_function" then
        local name = requirements.functionName or "myFunction"
        local params = requirements.parameters
        return M.generateFunction(name, params, requirements.description)
        
    elseif intent == "create_loop" then
        local count = requirements.loopCount or 10
        return M.generateLoop("for", count, "print(i)")
        
    elseif intent == "create_data_structure" then
        local lower = message:lower()
        if lower:find("queue") then
            return M.templates.data_structures["queue"]
        elseif lower:find("stack") then
            return M.templates.data_structures["stack"]
        elseif lower:find("list") then
            return M.templates.data_structures["linked list"]
        end
        
    elseif intent == "create_algorithm" then
        local lower = message:lower()
        if lower:find("sort") then
            return M.templates.algorithms["bubble sort"]
        elseif lower:find("search") then
            return M.templates.algorithms["binary search"]
        end
        
    elseif intent == "file_operation" then
        local lower = message:lower()
        if lower:find("read") then
            return M.templates.file_operations["read file"]
        elseif lower:find("write") then
            return M.templates.file_operations["write file"]
        elseif lower:find("append") then
            return M.templates.file_operations["append file"]
        end
        
    elseif intent == "turtle_operation" then
        return M.templates.computercraft["turtle move"]
    end
    
    return nil
end

return M
