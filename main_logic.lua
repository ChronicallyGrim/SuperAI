-- Module: main_logic.lua
-- Natural conversational AI with personality and useful features

-- ============================================================================
-- DRIVE CONFIGURATION (Load from drive_config.lua)
-- ============================================================================

-- Load drive configuration (peripheral names)
local drive_config = require("drive_config")

-- Convert peripheral names to mount paths
local function getMountPath(peripheral_name)
    if not peripheral_name or peripheral_name == "" then return nil end
    if not peripheral.isPresent(peripheral_name) then return nil end
    return disk.getMountPath(peripheral_name)
end

-- Build DRIVES table with mount paths
DRIVES = {
    TOP = getMountPath(drive_config.top),
    RAM_A = {},   -- BOTTOM: Virtual memory part 1
    RAM_B = {},   -- BACK: Virtual memory part 2
    RAID_A = {},  -- RIGHT: Persistent memory storage
    RAID_B = {}   -- LEFT: Persistent memory storage
}

-- Convert arrays of peripheral names to mount paths
for _, name in ipairs(drive_config.bottom or {}) do
    local path = getMountPath(name)
    if path then table.insert(DRIVES.RAM_A, path) end
end
for _, name in ipairs(drive_config.back or {}) do
    local path = getMountPath(name)
    if path then table.insert(DRIVES.RAM_B, path) end
end
for _, name in ipairs(drive_config.right or {}) do
    local path = getMountPath(name)
    if path then table.insert(DRIVES.RAID_A, path) end
end
for _, name in ipairs(drive_config.left or {}) do
    local path = getMountPath(name)
    if path then table.insert(DRIVES.RAID_B, path) end
end

-- ============================================================================
-- ADD DISK PATHS TO LUA'S SEARCH PATH
-- ============================================================================

-- Add TOP drive (modules) to Lua's search path
if package and package.path and DRIVES.TOP then
    -- Add the TOP drive where all modules live
    package.path = package.path .. ";" .. DRIVES.TOP .. "/?.lua"
    
    -- Also add all other drives to search path for flexibility
    for _, drives_list in pairs({DRIVES.RAM_A, DRIVES.RAM_B, DRIVES.RAID_A, DRIVES.RAID_B}) do
        for _, drive_path in ipairs(drives_list) do
            package.path = package.path .. ";" .. drive_path .. "/?.lua"
        end
    end
    
    print("Modules loaded from: " .. DRIVES.TOP)
    if #DRIVES.RAM_A > 0 or #DRIVES.RAM_B > 0 then
        print("RAM drives: " .. table.concat(DRIVES.RAM_A, ", ") .. " | " .. table.concat(DRIVES.RAM_B, ", "))
    end
    if #DRIVES.RAID_A > 0 or #DRIVES.RAID_B > 0 then
        print("RAID drives: " .. table.concat(DRIVES.RAID_A, ", ") .. " | " .. table.concat(DRIVES.RAID_B, ", "))
    end
else
    print("WARNING: TOP drive not found, using computer root for modules")
end

local M = {}

-- Load dependencies
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- Load RAID system
local raid = nil
local success_raid, raid_module = pcall(require, "raid_system")
if success_raid then
    raid = raid_module
    raid.init()
    print("RAID 0 system initialized")
else
    print("Warning: raid_system.lua not found - using local storage")
end

-- NEW: Advanced systems (with safe loading)
local codeGen, dictionary, learning, neuralNet, machineLearning, largeNeural, trainedNetwork, markov
local attention, embeddings, memorySearch, rlhf, sampling, tokenization

local success, module = pcall(require, "code_generator")
if success then 
    codeGen = module
else
    print("Warning: code_generator.lua not found - code generation disabled")
end

success, module = pcall(require, "dictionary")
if success then
    dictionary = module
else
    print("Warning: dictionary.lua not found - dictionary disabled")
end

success, module = pcall(require, "learning")
if success then
    learning = module
else
    print("Warning: learning.lua not found - learning disabled")
end

success, module = pcall(require, "neural_net")
if success then
    neuralNet = module
    print("Neural network loaded - AI learning enabled!")
else
    print("Warning: neural_net.lua not found - neural learning disabled")
end

success, module = pcall(require, "machine_learning")
if success then
    machineLearning = module
    print("Machine learning loaded - pattern recognition enabled!")
else
    print("Warning: machine_learning.lua not found - ML features disabled")
end

success, module = pcall(require, "large_neural_net")
if success then
    largeNeural = module
    print("Large neural network module loaded!")
    
    -- Try to load trained network
    trainedNetwork = largeNeural.loadNetwork("/neural/")
    if trainedNetwork then
        print("Loaded trained network with " .. trainedNetwork.total_params .. " parameters!")
    else
        print("No trained network found - run neural_trainer to create one")
    end
else
    print("Warning: large_neural_net.lua not found - advanced neural features disabled")
end

success, module = pcall(require, "markov")
if success then
    markov = module
    print("Markov chains loaded!")
    
    -- Load trained markov data
    if markov.load("markov_data.dat") then
        local stats = markov.getStats()
        print("Loaded Markov data: " .. stats.total_sequences .. " sequences")
    else
        print("No Markov data found - initializing...")
        markov.initializeWithDefaults()
        markov.save()
    end
else
    print("Warning: markov.lua not found - natural language generation disabled")
end

-- NEW: Context-Aware Markov (smart, contextual responses)
local contextMarkov = nil
success, module = pcall(require, "context_markov")
if success then
    contextMarkov = module
    
    -- Try to load trained context-aware data
    if contextMarkov.load("context_markov.dat") then
        local stats = contextMarkov.getStats()
        print("Context-Aware Markov loaded: " .. stats.total_patterns .. " patterns in " .. stats.contexts .. " contexts!")
    else
        print("Context-Aware Markov initialized (run unified_trainer to train)")
    end
else
    print("Info: context_markov.lua not found - install for smarter responses")
end

-- NEW: Advanced AI modules (Transformer components)
success, module = pcall(require, "attention")
if success then
    attention = module
    print("Attention mechanism loaded - transformer architecture enabled!")
else
    print("Warning: attention.lua not found - attention disabled")
end

success, module = pcall(require, "embeddings")
if success then
    embeddings = module
    print("Word embeddings loaded - semantic understanding enabled!")
    
    -- Initialize or load embeddings
    if embeddings.load("embeddings.dat") then
        print("Loaded embeddings: " .. embeddings.vocab_size .. " words")
    else
        embeddings.initializeDefaults()
        embeddings.save()
    end
else
    print("Warning: embeddings.lua not found - embeddings disabled")
end

success, module = pcall(require, "memory_search")
if success then
    memorySearch = module
    print("Semantic memory search loaded!")
    
    -- Initialize with embeddings and attention
    if embeddings and attention then
        memorySearch.initialize(embeddings, attention)
        memorySearch.load("memory_index.dat")
        local stats = memorySearch.getStats()
        print("Memory index: " .. stats.total_memories .. " memories")
    end
else
    print("Warning: memory_search.lua not found - semantic search disabled")
end

success, module = pcall(require, "rlhf")
if success then
    rlhf = module
    print("RLHF loaded - learning from feedback enabled!")
    
    rlhf.load("rlhf_data.dat")
    local stats = rlhf.getStats()
    print("RLHF stats: " .. stats.total_feedback .. " feedback samples")
else
    print("Warning: rlhf.lua not found - feedback learning disabled")
end

success, module = pcall(require, "sampling")
if success then
    sampling = module
    print("Advanced sampling loaded - better response generation!")
else
    print("Warning: sampling.lua not found - advanced sampling disabled")
end

success, module = pcall(require, "tokenization")
if success then
    tokenization = module
    print("Tokenization loaded - subword processing enabled!")
    
    tokenization.load("tokenization.dat")
else
    print("Warning: tokenization.lua not found - tokenization disabled")
end

print("\n=== SuperAI System Ready ===")
print("All advanced AI modules loaded!")
print("")

-- Database is now in memory module (memory_RAID_partA.lua)
-- Graph algorithms are now in utils.math

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DEFAULT_BOT_NAME = "SuperAI"
local BOT_NAME = DEFAULT_BOT_NAME
local isTurtle = (type(turtle) == "table")

-- Context window for conversation memory (like LSTM/Transformers)
local CONTEXT_WINDOW = 10000
local INTENT_CONFIDENCE_THRESHOLD = 0.6

-- ============================================================================
-- SAFE CALL HELPERS
-- ============================================================================

-- Safely call a module function, return default if fails
local function safeCall(module, funcName, default, ...)
    if module and module[funcName] and type(module[funcName]) == "function" then
        local success, result = pcall(module[funcName], ...)
        if success then
            return result
        end
    end
    return default
end

-- Check if a module function exists
local function hasFunction(module, funcName)
    return module and module[funcName] and type(module[funcName]) == "function"
end

-- ============================================================================
-- MEMORY SYSTEM
-- ============================================================================

local memory = {
    nicknames = {},
    context = {},
    learned = {},
    chatColor = colors.white,
    categories = {},
    negative = {},
    facts = {},
    preferences = {},
    lastTopics = {},
    conversationCount = 0,
    startTime = os.time(),
    botName = DEFAULT_BOT_NAME
}

-- Debug mode for showing response sources
local DEBUG_MODE = false
local lastResponseSource = "unknown"

-- Default categories
local defaultCategories = {
    greeting = {"hi", "hello", "hey", "greetings", "sup", "yo"},
    math = {"calculate", "what is", "solve", "plus", "minus", "times", "divided", "sqrt", "sin", "cos", "tan", "percent"},
    time = {"time", "clock", "what time"},
    gratitude = {"thanks", "thank you"},
    personal = {"i feel", "i'm feeling", "my"},
    question = {"what", "why", "how", "when", "where", "who"}
}

-- Initialize categories
for cat, keywords in pairs(defaultCategories) do
    if not memory.categories[cat] then
        memory.categories[cat] = keywords
    end
end

-- ============================================================================
-- DISK STORAGE
-- ============================================================================

local diskDrive = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral and peripheral.isPresent(side) and peripheral.getType(side) == "drive" then
        diskDrive = peripheral.wrap(side)
        break
    end
end

-- Memory file path (use RAID if available)
local MEM_FILE = "superai_memory/memory.dat"

local function loadMemory()
    local content = nil
    
    if raid and raid.exists(MEM_FILE) then
        content = raid.read(MEM_FILE)
    elseif fs.exists(MEM_FILE) then
        local file = fs.open(MEM_FILE, "r")
        content = file.readAll()
        file.close()
    end
    
    if content and content ~= "" then
        local loaded = textutils.unserialize(content)
        if loaded then
            for k, v in pairs(loaded) do
                memory[k] = v
            end
            if memory.botName then
                BOT_NAME = memory.botName
            end
        end
    end
end

local function saveMemory()
    local content = textutils.serialize(memory)
    
    if raid then
        raid.write(MEM_FILE, content)
    else
        if not fs.exists("superai_memory") then
            fs.makeDir("superai_memory")
        end
        local file = fs.open(MEM_FILE, "w")
        file.write(content)
        file.close()
    end
end

-- ============================================================================
-- SYSTEM DIAGNOSTICS (FIXED FREEZE & DISPLAY)
-- ============================================================================

local function getSystemHealth()
    -- Collect drive data first
    local driveData = {}
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    
    for _, side in ipairs(sides) do
        sleep(0) -- Yield to OS
        
        if peripheral.isPresent(side) and peripheral.getType(side) == "drive" then
            local drv = peripheral.wrap(side)
            local success, mountPath = pcall(function() return drv.getMountPath() end)
            
            if success and mountPath then
                local path = "/" .. mountPath
                if fs.exists(path) then
                    local capacity = fs.getCapacity(path)
                    local free = fs.getFreeSpace(path)
                    local used = capacity - free
                    local usedPercent = math.floor((used / capacity) * 100)
                    local files = fs.list(path)
                    
                    driveData[side] = {
                        mount = mountPath,
                        cap = math.floor(capacity / 1024),
                        used = math.floor(used / 1024),
                        percent = usedPercent,
                        free = math.floor(free / 1024),
                        files = #files
                    }
                end
            end
        end
    end
    
    -- Build visual layout
    local lines = {}
    
    -- Title
    table.insert(lines, "=== System Health ===")
    table.insert(lines, "")
    
    -- TOP DRIVE
    if driveData.top then
        local d = driveData.top
        table.insert(lines, "         --- Top Drive (" .. d.mount .. ") ---")
        table.insert(lines, "         " .. d.used .. "/" .. d.cap .. " KB (" .. d.percent .. "%) | " .. d.files .. " files")
        table.insert(lines, "")
    end
    
    -- LEFT and RIGHT DRIVES (side by side)
    local leftLines = {}
    local rightLines = {}
    
    if driveData.left then
        local d = driveData.left
        table.insert(leftLines, "Left (" .. d.mount .. "):")
        table.insert(leftLines, d.used .. "/" .. d.cap .. " KB")
        table.insert(leftLines, "(" .. d.percent .. "%)")
        table.insert(leftLines, d.files .. " files")
    else
        table.insert(leftLines, "")
        table.insert(leftLines, "")
        table.insert(leftLines, "")
        table.insert(leftLines, "")
    end
    
    if driveData.right then
        local d = driveData.right
        table.insert(rightLines, "Right (" .. d.mount .. "):")
        table.insert(rightLines, d.used .. "/" .. d.cap .. " KB")
        table.insert(rightLines, "(" .. d.percent .. "%)")
        table.insert(rightLines, d.files .. " files")
    else
        table.insert(rightLines, "")
        table.insert(rightLines, "")
        table.insert(rightLines, "")
        table.insert(rightLines, "")
    end
    
    -- Combine left and right with spacing
    for i = 1, 4 do
        local left = leftLines[i] or ""
        local right = rightLines[i] or ""
        -- Pad left side to 25 chars
        left = left .. string.rep(" ", 25 - #left)
        table.insert(lines, left .. right)
    end
    
    table.insert(lines, "")
    
    -- FRONT DRIVE
    if driveData.front then
        local d = driveData.front
        table.insert(lines, "        --- Front Drive (" .. d.mount .. ") ---")
        table.insert(lines, "        " .. d.used .. "/" .. d.cap .. " KB (" .. d.percent .. "%) | " .. d.files .. " files")
        table.insert(lines, "")
    end
    
    -- BACK DRIVE
    if driveData.back then
        local d = driveData.back
        table.insert(lines, "        --- Back Drive (" .. d.mount .. ") ---")
        table.insert(lines, "        " .. d.used .. "/" .. d.cap .. " KB (" .. d.percent .. "%) | " .. d.files .. " files")
        table.insert(lines, "")
    end
    
    -- BOTTOM DRIVE
    if driveData.bottom then
        local d = driveData.bottom
        table.insert(lines, "       --- Bottom Drive (" .. d.mount .. ") ---")
        table.insert(lines, "       " .. d.used .. "/" .. d.cap .. " KB (" .. d.percent .. "%) | " .. d.files .. " files")
        table.insert(lines, "")
    end
    
    -- Stats
    table.insert(lines, "Stats:")
    table.insert(lines, "  Msg: " .. memory.conversationCount .. " | Facts: " .. (memory.facts["Player"] and #memory.facts["Player"] or 0))
    table.insert(lines, "  Context: " .. #memory.context .. "/" .. CONTEXT_WINDOW)
    
    local uptime = os.time() - memory.startTime
    table.insert(lines, "  Uptime: " .. math.floor(uptime / 60) .. " hrs")
    
    return table.concat(lines, "\n")
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user, nickname)
    memory.nicknames[user] = nickname
    saveMemory()
    return "Got it! I'll call you " .. nickname .. " from now on."
end

local function setBotName(newName)
    BOT_NAME = newName
    memory.botName = newName
    saveMemory()
    return "Cool! You can call me " .. newName .. " now."
end

local function rememberFact(user, fact)
    if not memory.facts[user] then
        memory.facts[user] = {}
    end
    table.insert(memory.facts[user], {
        fact = fact,
        timestamp = os.time()
    })
    while #memory.facts[user] > 20 do
        table.remove(memory.facts[user], 1)
    end
    saveMemory()
end

local function rememberPreference(user, item, isLike)
    if not memory.preferences[user] then
        memory.preferences[user] = {likes = {}, dislikes = {}}
    end
    
    if isLike then
        table.insert(memory.preferences[user].likes, item)
    else
        table.insert(memory.preferences[user].dislikes, item)
    end
    
    saveMemory()
end

local function recallFact(user)
    if not memory.facts[user] or #memory.facts[user] == 0 then
        return nil
    end
    local fact = memory.facts[user][math.random(#memory.facts[user])]
    return fact.fact
end

local function trackTopic(topic)
    table.insert(memory.lastTopics, {
        topic = topic,
        timestamp = os.time()
    })
    while #memory.lastTopics > 10 do
        table.remove(memory.lastTopics, 1)
    end
end

local function discussedRecently(topic)
    for i = #memory.lastTopics, math.max(1, #memory.lastTopics - 3), -1 do
        if memory.lastTopics[i].topic:lower():find(topic:lower()) then
            return true
        end
    end
    return false
end

local function detectCategory(message)
    local msg = message:lower()
    local bestCat, bestScore = "unknown", 0
    
    for cat, kws in pairs(memory.categories) do
        local score = 0
        for _, kw in ipairs(kws) do
            if msg:find(kw) then score = score + 1 end
        end
        if score > bestScore then
            bestScore = score
            bestCat = cat
        end
    end
    
    return bestCat
end

local function updateContext(user, message, category, response)
    table.insert(memory.context, {
        user = user,
        message = message,
        category = category,
        response = response,
        timestamp = os.time(),
        embedding = utils.extractKeywords(message)
    })
    
    if #memory.context > CONTEXT_WINDOW then
        table.remove(memory.context, 1)
    end
end

local function getContextualHistory(user, lookback)
    lookback = lookback or 5
    local history = {}
    local count = 0
    
    for i = #memory.context, 1, -1 do
        if memory.context[i].user == user then
            table.insert(history, 1, memory.context[i])
            count = count + 1
            if count >= lookback then break end
        end
    end
    
    return history
end

local function findRelevantContext(currentMessage, user)
    local currentKeywords = utils.extractKeywords(currentMessage)
    local relevantContexts = {}
    
    for i = #memory.context, math.max(1, #memory.context - 10), -1 do
        if memory.context[i].user == user then
            local contextKeywords = memory.context[i].embedding or {}
            local relevanceScore = 0
            
            for _, currKw in ipairs(currentKeywords) do
                for _, ctxKw in ipairs(contextKeywords) do
                    if currKw == ctxKw then
                        relevanceScore = relevanceScore + 1
                    end
                end
            end
            
            if relevanceScore > 0 then
                table.insert(relevantContexts, {
                    context = memory.context[i],
                    score = relevanceScore
                })
            end
        end
    end
    
    table.sort(relevantContexts, function(a, b) return a.score > b.score end)
    
    return relevantContexts
end

-- ============================================================================
-- NEURAL NETWORK SENTIMENT ANALYSIS
-- ============================================================================

local function useNeuralNetwork(message)
    if not trainedNetwork or not largeNeural then
        return nil  -- Neural network not available
    end
    
    -- Encode message to vector
    local input = {}
    for i = 1, trainedNetwork.layer_sizes[1] do
        if i <= #message then
            input[i] = string.byte(message, i) / 255
        else
            input[i] = 0
        end
    end
    
    -- Get prediction
    local output = largeNeural.forward(trainedNetwork, input)
    
    -- Interpret output (sentiment classification)
    local sentiment = "neutral"
    local confidence = output[2]
    
    if output[1] > output[2] and output[1] > output[3] then
        sentiment = "positive"
        confidence = output[1]
    elseif output[3] > output[1] and output[3] > output[2] then
        sentiment = "negative"
        confidence = output[3]
    end
    
    return {
        sentiment = sentiment,
        confidence = confidence,
        raw = output
    }
end

-- ============================================================================
-- IMPROVED MATH EVALUATION (UPDATED WITH COMPLEX MATH SUPPORT)
-- ============================================================================

local function evaluateMath(message)
    local expr = message:lower()
    
    -- Convert word numbers to digits
    local wordNumbers = {
        ["zero"] = "0", ["one"] = "1", ["two"] = "2", ["three"] = "3", ["four"] = "4",
        ["five"] = "5", ["six"] = "6", ["seven"] = "7", ["eight"] = "8", ["nine"] = "9",
        ["ten"] = "10", ["eleven"] = "11", ["twelve"] = "12", ["thirteen"] = "13",
        ["fourteen"] = "14", ["fifteen"] = "15", ["sixteen"] = "16", ["seventeen"] = "17",
        ["eighteen"] = "18", ["nineteen"] = "19", ["twenty"] = "20", ["thirty"] = "30",
        ["forty"] = "40", ["fifty"] = "50", ["sixty"] = "60", ["seventy"] = "70",
        ["eighty"] = "80", ["ninety"] = "90", ["hundred"] = "100", ["thousand"] = "1000"
    }
    
    for word, num in pairs(wordNumbers) do
        expr = expr:gsub("%f[%w]" .. word .. "%f[%W]", num)
    end
    
    -- Handle written operators
    expr = expr:gsub("%f[%w]plus%f[%W]", "+")
    expr = expr:gsub("%f[%w]add%f[%W]", "+")
    expr = expr:gsub("%f[%w]minus%f[%W]", "-")
    expr = expr:gsub("%f[%w]subtract%f[%W]", "-")
    expr = expr:gsub("%f[%w]times%f[%W]", "*")
    expr = expr:gsub("%f[%w]multiplied by%f[%W]", "*")
    expr = expr:gsub("%f[%w]multiply%f[%W]", "*")
    expr = expr:gsub("%f[%w]divided by%f[%W]", "/")
    expr = expr:gsub("%f[%w]divide%f[%W]", "/")
    expr = expr:gsub("%f[%w]to the power of%f[%W]", "^")
    expr = expr:gsub("%f[%w]squared%f[%W]", "^2")
    expr = expr:gsub("%f[%w]cubed%f[%W]", "^3")
    
    -- Handle percentage calculations
    expr = expr:gsub("([%d%.]+)%% of ([%d%.]+)", "(%1/100)*%2")
    expr = expr:gsub("([%d%.]+)%%", "(%1/100)")

    -- Handle basic math functions
    local functions = {"sqrt", "sin", "cos", "tan", "abs", "log", "exp", "floor", "ceil"}
    for _, f in ipairs(functions) do
        if f == "sin" or f == "cos" or f == "tan" then
            expr = expr:gsub(f .. " ?%(([^%)]+)%)", "math." .. f .. "(math.rad(%1))")
            expr = expr:gsub(f .. " +([%d%.]+)", "math." .. f .. "(math.rad(%1))")
        else
            expr = expr:gsub(f .. " ?%(([^%)]+)%)", "math." .. f .. "(%1)")
            expr = expr:gsub(f .. " +([%d%.]+)", "math." .. f .. "(%1)")
        end
    end

    local cleanExpr = ""
    for token in expr:gmatch("[%d%+%-%*/%%%^%.%(%)mathradsincoxtabflogepsqr%s]+") do
        cleanExpr = cleanExpr .. token
    end

    if cleanExpr ~= "" and cleanExpr:match("%d") then
        local func, err = load("return " .. cleanExpr, "math_env", "t", {math = math})
        if func then
            local success, result = pcall(func)
            if success and type(result) == "number" then
                local output = tostring(result)
                if result % 1 ~= 0 then 
                    output = string.format("%.4f", result):gsub("0+$", ""):gsub("%.$", "")
                end
                return "The answer is " .. output
            end
        end
    end
    
    return nil
end

-- ============================================================================
-- INTENT DETECTION
-- ============================================================================

local function detectIntent(message)
    local msg = message:lower()
    
    if msg:find("system health") or msg:find("system status") or 
       msg:find("diagnostics") or msg:find("storage") then
        return "system_health", nil, 1.0
    end
    
    local intentScores = {}
    
    local intents = {
        math = {
            patterns = {"%d+%s*[%+%-%*/]", "plus", "minus", "times", "divided", "calculate", "solve", "sqrt", "sin", "cos", "tan", "percent", "%%"},
            weight = 2.0
        },
        time = {
            patterns = {"time", "clock", "what time", "when is it"},
            weight = 1.5
        },
        remember = {
            patterns = {"remember", "don't forget", "keep in mind", "note that"},
            weight = 1.8
        },
        recall = {
            patterns = {"what did i", "did i tell", "do you remember", "what was", "recall"},
            weight = 1.6
        },
        preference_like = {
            patterns = {"i like", "i love", "i enjoy", "i prefer"},
            weight = 1.7
        },
        preference_dislike = {
            patterns = {"i hate", "i don't like", "i dislike", "can't stand"},
            weight = 1.7
        },
        change_settings = {
            patterns = {"change my", "change color", "change name", "update", "call you"},
            weight = 1.4
        },
        greeting = {
            patterns = {"^hi+$", "^hello", "^hey+", "^sup", "^yo+", "^howdy"},
            weight = 2.0
        },
        gratitude = {
            patterns = {"thank", "thanks", "thx", "appreciate"},
            weight = 1.5
        },
        question = {
            patterns = {"?", "^what", "^why", "^how", "^when", "^where", "^who"},
            weight = 1.2
        }
    }
    
    for intentName, intentData in pairs(intents) do
        intentScores[intentName] = 0
        for _, pattern in ipairs(intentData.patterns) do
            if msg:find(pattern) then
                intentScores[intentName] = intentScores[intentName] + intentData.weight
            end
        end
    end
    
    local bestIntent = "statement"
    local bestScore = 0
    
    for intentName, score in pairs(intentScores) do
        if score > bestScore then
            bestScore = score
            bestIntent = intentName
        end
    end
    
    local totalScore = 0
    for _, score in pairs(intentScores) do
        totalScore = totalScore + score
    end
    
    local confidence = totalScore > 0 and (bestScore / totalScore) or 0
    
    local entity = nil
    if bestIntent == "preference_like" then
        entity = msg:match("i like (.+)") or msg:match("i love (.+)") or msg:match("i enjoy (.+)")
    elseif bestIntent == "preference_dislike" then
        entity = msg:match("i hate (.+)") or msg:match("i don't like (.+)") or msg:match("i dislike (.+)")
    elseif bestIntent == "remember" then
        entity = msg:match("remember%s+(.+)") or msg:match("don't forget%s+(.+)")
    end
    
    if confidence >= INTENT_CONFIDENCE_THRESHOLD then
        return bestIntent, entity, confidence
    else
        return "statement", nil, confidence
    end
end

-- ============================================================================
-- RESPONSE GENERATION (FULL LOGIC)
-- ============================================================================

local function handleGreeting(user, message)
    local greetings = {
        "Hey! What's up?",
        "Hi! How's it going?",
        "Hey there!",
        "Yo! What's good?",
        "Hi! How are you?",
        "Hey! What's happening?",
        "Sup! How are things?",
        "Hey! Good to see you!",
    }
    
    local response = utils.choose(greetings)
    
    if memory.nicknames[user] then
        local personalGreetings = {
            "Hey " .. memory.nicknames[user] .. "! What's up?",
            "Hi " .. memory.nicknames[user] .. "! How's it going?",
            "Yo " .. memory.nicknames[user] .. "!",
            "Hey " .. memory.nicknames[user] .. "! What's new?",
            "Sup " .. memory.nicknames[user] .. "!",
            "Hey " .. memory.nicknames[user] .. "! How are you?",
        }
        response = utils.choose(personalGreetings)
    end
    
    return response
end

local function handleGratitude(user, message)
    local responsesList = {
        "You're welcome!",
        "Happy to help!",
        "No problem!",
        "Anytime!",
        "Glad I could help!",
    }
    
    return utils.choose(responsesList)
end

local function handleQuestion(user, message, userMood)
    if message:lower():find("who are you") or message:lower():find("what are you") then
        return "I'm " .. BOT_NAME .. ", just a friendly AI here to chat! What's up?"
    end
    
    if message:lower():find("your name") or message:lower():find("what's your name") or
       message:lower():find("whats your name") then
        return "I'm " .. BOT_NAME .. "! What about you?"
    end
    
    if message:lower():find("how are you") or message:lower():find("how's it going") or 
       message:lower():find("how are things") then
        local responsesList = {
            "I'm doing great! How about you?",
            "Pretty good! What's going on with you?",
            "Can't complain! How are you?",
            "I'm good, thanks! What about you?",
            "Good good! What's new with you?",
        }
        return utils.choose(responsesList)
    end
    
    if message:lower():find("what can you do") or message:lower():find("what do you do") then
        return "I can chat with you, solve math problems, tell you the time, remember stuff you tell me... mostly I'm just here to talk! What would you like to do?"
    end
    
    if message:lower():find("what's up") or message:lower():find("sup") or 
       message:lower():find("what are you doing") then
        local responsesList = {
            "Not much, just hanging out! You?",
            "Just chatting with you! What's up with you?",
            "Nothing much! What about you?",
            "Just here, ready to chat! What's going on?",
        }
        return utils.choose(responsesList)
    end
    
    local responsesList = {
        "Hmm, good question. What do you think?",
        "I'm not totally sure. What's your take?",
        "That's interesting. I'd have to think about it. What do you think?",
        "You know, I'm not certain. What's your opinion?",
        "I don't really know. Why do you ask?",
        "Not sure about that one. What made you think of it?",
    }
    
    return utils.choose(responsesList)
end

local function handleStatement(user, message, userMood)
    local category = detectCategory(message)
    local keywords = utils.extractKeywords(message)
    
    -- CRITICAL: Override mood for clearly positive single-word responses
    local msg_lower = message:lower():gsub("[%p]", "")
    local positive_words = {
        "awesome", "great", "cool", "nice", "sweet", "perfect", "excellent", 
        "amazing", "fantastic", "wonderful", "brilliant", "love", "yes", "yeah"
    }
    
    if #message < 20 then
        for _, word in ipairs(positive_words) do
            if msg_lower == word or msg_lower:find("^" .. word .. "$") then
                userMood = "positive"  -- Force positive mood
                break
            end
        end
    end
    
    -- NEW: Handle status responses ("im good", "im fine", "not bad", etc.)
    local msg_lower = message:lower()
    
    -- Catch "its going good/fine/okay"
    if msg_lower:find("going") and (msg_lower:find("good") or msg_lower:find("fine") or 
       msg_lower:find("well") or msg_lower:find("alright") or msg_lower:find("okay")) then
        
        local history = getContextualHistory(user, 1)
        local just_asked_how = false
        if history and #history > 0 then
            local last_ai = history[1].response or ""
            if last_ai:lower():find("how") or last_ai:lower():find("what's up") or 
               last_ai:lower():find("whats up") then
                just_asked_how = true
            end
        end
        
        if just_asked_how then
            local responses = {
                "Nice!",
                "Cool cool.",
                "Good to hear!",
                "Sweet!",
                "That's good!",
                "Awesome.",
            }
            return utils.choose(responses)
        end
    end
    
    -- Catch "im good/fine/okay"
    if (msg_lower:find("^i'?m ") or msg_lower:find("^im ")) and #message < 25 then
        if msg_lower:find("good") or msg_lower:find("fine") or msg_lower:find("alright") or 
           msg_lower:find("ok") or msg_lower:find("okay") then
            
            local history = getContextualHistory(user, 1)
            local just_asked_how = false
            if history and #history > 0 then
                local last_ai = history[1].response or ""
                if last_ai:lower():find("how") or last_ai:lower():find("what about you") or
                   last_ai:lower():find("and you") then
                    just_asked_how = true
                end
            end
            
            if just_asked_how then
                local responses = {
                    "Nice!",
                    "Cool cool.",
                    "Good to hear!",
                    "Sweet!",
                    "That's good!",
                    "Awesome.",
                }
                return utils.choose(responses)
            else
                local responses = {
                    "Nice! What's been going on?",
                    "Cool! Anything interesting happening?",
                    "Sweet! What are you up to?",
                    "Good to hear! What's on your mind?",
                }
                return utils.choose(responses)
            end
        end
        
        if msg_lower:find("great") or msg_lower:find("awesome") or msg_lower:find("amazing") or
           msg_lower:find("fantastic") then
            local responses = {
                "Hell yeah!",
                "That's awesome!",
                "Love to hear it!",
                "Nice!",
            }
            return utils.choose(responses)
        end
        
        if msg_lower:find("bad") or msg_lower:find("not great") or msg_lower:find("meh") or
           msg_lower:find("tired") or msg_lower:find("stressed") then
            local responses = {
                "Aw man, what's up?",
                "Sorry to hear that. What's going on?",
                "That sucks. Want to talk about it?",
                "Damn. Everything okay?",
            }
            return utils.choose(responses)
        end
    end
    
    -- Handle very short responses ("yeah", "nah", "cool", "not much", etc.)
    if #message <= 15 then
        local history = getContextualHistory(user, 1)
        local last_ai = history and #history > 0 and (history[1].response or "") or ""
        local was_question = last_ai:find("?") ~= nil
        
        -- "not much" / "nothing much"
        if msg_lower:find("not much") or msg_lower:find("nothing much") or msg_lower:find("nm") then
            if was_question then
                local responses = {
                    "Fair enough.",
                    "Gotcha.",
                    "All good.",
                    "Cool cool.",
                }
                return utils.choose(responses)
            end
        end
        
        if msg_lower:find("^yeah") or msg_lower:find("^yup") or msg_lower:find("^yes") then
            if was_question then
                local responses = {
                    "Cool.",
                    "Gotcha.",
                    "Alright.",
                    "Nice.",
                }
                return utils.choose(responses)
            else
                local responses = {
                    "For sure.",
                    "Right?",
                    "Totally.",
                    "I know!",
                }
                return utils.choose(responses)
            end
        end
        
        if msg_lower:find("^nah") or msg_lower:find("^nope") or msg_lower:find("^no") then
            if was_question then
                local responses = {
                    "Fair enough.",
                    "Gotcha.",
                    "Okay cool.",
                    "Alright.",
                }
                return utils.choose(responses)
            else
                local responses = {
                    "Nah for real.",
                    "Right?",
                    "Yeah I feel that.",
                }
                return utils.choose(responses)
            end
        end
        
        if msg_lower:find("^cool") or msg_lower:find("^nice") or msg_lower:find("^sweet") then
            local responses = {
                "Right?",
                "Yeah!",
                "For sure!",
                "I know!",
            }
            return utils.choose(responses)
        end
    end
    
    if #message < 10 and #keywords == 0 then
        local shortResponseCount = 0
        local history = getContextualHistory(user, 3)
        
        for _, h in ipairs(history) do
            if #h.message < 10 then
                shortResponseCount = shortResponseCount + 1
            end
        end
        
        if shortResponseCount >= 2 and math.random() < 0.5 then
            local checkIns = {
                "You seem quiet today. Everything okay?",
                "Not much to say? That's cool.",
                "You good? You seem a bit quiet.",
                "All good? You're being pretty brief.",
            }
            return utils.choose(checkIns)
        end
    end
    
    if message:lower():find("my ") or message:lower():find("i have") or 
       message:lower():find("i work") or message:lower():find("i live") then
        rememberFact(user, message)
    end
    
    if keywords and #keywords > 0 then
        trackTopic(keywords[1])
    end
    
    local relevantPast = findRelevantContext(message, user)
    
    if relevantPast and #relevantPast > 0 and relevantPast[1].score >= 2 then
        local pastMsg = relevantPast[1].context.message
        if not discussedRecently(pastMsg) and math.random() < 0.3 then
            return "Oh, that reminds me - you mentioned something similar before. " .. utils.choose({
                "What happened with that?",
                "How'd that turn out?",
                "Is that still going on?",
            })
        end
    end
    
    if userMood == "negative" then
        local supportive = {
            "That sounds rough.",
            "Man, that sucks.",
            "Ugh, I bet that's frustrating.",
            "Yeah, that's tough.",
            "That sounds annoying.",
            "I'm sorry to hear that.",
            "Damn, that's rough.",
        }
        
        local response = utils.choose(supportive)
        
        local history = getContextualHistory(user, 3)
        if #history > 0 and math.random() < 0.4 then
            local followUps = {
                "What happened?",
                "Want to talk about it?",
                "What's going on?",
                "You okay?",
                "Wanna vent?",
            }
            response = response .. " " .. utils.choose(followUps)
        end
        
        return response
    end
    
    if userMood == "positive" then
        local positive = {
            "That's awesome!",
            "Nice! That's great!",
            "Oh cool!",
            "That's really good to hear!",
            "Sweet!",
            "Haha, that's great!",
            "Hell yeah!",
            "That's dope!",
        }
        
        return utils.choose(positive)
    end
    
    if category == "personal" then
        local responsesList = {
            "Oh yeah? Tell me more.",
            "What's that like?",
            "Really? How's that been?",
            "Huh, didn't know that.",
            "That's cool. What made you think of that?",
            "No way, really?",
            "Damn, interesting.",
            "Oh cool, how'd that happen?",
            "Nice! What's the story there?",
            "For real? What's up with that?",
        }
        return utils.choose(responsesList)
    end
    
    if math.random() < 0.15 and memory.facts[user] and #memory.facts[user] > 0 then
        local oldFact = recallFact(user)
        if oldFact and not discussedRecently(oldFact) then
            local callbacks = {
                "Oh, that reminds me - you mentioned " .. oldFact .. " before.",
                "Speaking of which, earlier you told me " .. oldFact .. ".",
                "By the way, about that thing with " .. oldFact .. "...",
            }
            return utils.choose(callbacks)
        end
    end
    
    local responsesList = {
        "Yeah, totally.",
        "I get what you mean.",
        "That makes sense.",
        "True that.",
        "Fair enough.",
        "I see what you're saying.",
        "Right, right.",
        "Gotcha.",
        "For sure.",
        "I hear you.",
        "Yep, makes sense.",
        "That's fair.",
        "I feel that.",
        "Totally get it.",
    }
    
    local response = utils.choose(responsesList)
    
    local history = getContextualHistory(user, 3)
    local questionStreak = 0
    for _, h in ipairs(history) do
        if h.response and h.response:find("?") then
            questionStreak = questionStreak + 1
        end
    end
    
    local shouldAskQuestion = hasFunction(personality, "shouldAskQuestion") and personality.shouldAskQuestion() and questionStreak < 2 and math.random() < 0.3
    
    if shouldAskQuestion then
        local followUps = {
            "What do you think?",
            "How'd that go?",
            "What happened?",
            "Why's that?",
            "Really?",
            "You think so?",
            "How come?",
        }
        response = response .. " " .. utils.choose(followUps)
    end
    
    return response
end

-- ============================================================================
-- MAIN INTERPRETATION
-- ============================================================================

local function interpret(message, user)
    memory.conversationCount = memory.conversationCount + 1
    
    -- Help command
    if message:lower() == "help" or message:lower() == "commands" then
        return [[
SuperAI - Advanced AI Assistant

CONVERSATION:
• Just talk naturally!
• "tell me a joke"
• "how are you?"

CODE GENERATION:
• "write a function to add numbers"
• "create a for loop"
• "generate a stack data structure"

MATH:
• Basic: 5 + 3, sqrt(16), 10% of 200
• Advanced: factorial of 5, fibonacci of 10
• Primes: is 17 prime, prime factors of 60
• Other: gcd of 48 and 18, 2^10

DICTIONARY:
• "define algorithm"
• "what does recursion mean"

LEARNING:
• "learn this: [concept]"
• "remember this: [fact]"

AI LEARNING:
• "train sentiment" - Train neural network
• "analyze sentiment: [text]" - Test sentiment
• "train from feedback" - Learn from conversations
• "cluster conversations" - Find patterns

DATABASE:
• "create database mydb"
• "use database mydb"
• "list databases"
• "list tables"

GRAPHS:
• Use utils.Graph.new() programmatically
• findPath(), shortestPath()

SYSTEM:
• "my name is [name]"
• "call yourself [name]"
• "system health"
• "debug on/off" - Show response sources
]]
    end
    
    -- Debug command
    if message:lower() == "debug on" then
        DEBUG_MODE = true
        return "Debug mode ON. I'll show which module generates each response."
    end
    
    if message:lower() == "debug off" then
        DEBUG_MODE = false
        return "Debug mode OFF."
    end
    
    if message:lower() == "debug status" or message:lower() == "debug" then
        local stats_msg = "Debug mode: " .. (DEBUG_MODE and "ON" or "OFF") .. "\n"
        stats_msg = stats_msg .. "Last response source: " .. lastResponseSource .. "\n"
        if contextMarkov then
            local stats = contextMarkov.getStats()
            stats_msg = stats_msg .. "Patterns learned: " .. (stats.total_patterns or 0) .. "\n"
            stats_msg = stats_msg .. "Contexts: " .. (stats.contexts_learned or 0) .. "\n"
            stats_msg = stats_msg .. "Generations from training: " .. (stats.successful_generations or 0)
        end
        return stats_msg
    end
    
    safeCall(mood, "update", nil, user, message)
    local userMood = safeCall(mood, "get", "neutral", user) or "neutral"
    
    -- NEW: Analyze sentiment with large neural network (610K parameters!)
    local neuralPrediction = useNeuralNetwork(message)
    if neuralPrediction and neuralPrediction.confidence > 0.6 then
        -- High confidence prediction from neural network
        if neuralPrediction.sentiment == "negative" then
            userMood = "concerned"
        elseif neuralPrediction.sentiment == "positive" then
            userMood = "happy"
        end
    end
    
    -- NEW: Code generation commands
    if codeGen and (message:lower():find("write a") or message:lower():find("create a function") or message:lower():find("generate code")) then
        local code = codeGen.generate(message)
        if code then
            return "Here's the code:\n\n" .. code .. "\n\nNeed any changes?"
        end
    end
    
    -- NEW: Dictionary lookups
    if dictionary and (message:lower():find("define ") or message:lower():find("what does .* mean") or message:lower():find("definition of")) then
        local word = message:match("define%s+(%w+)") or message:match("definition of%s+(%w+)") or message:match("what does%s+(%w+)%s+mean")
        if word then
            local def = dictionary.define(word)
            if def then
                return string.format("%s (%s): %s", word, def.type, def.def)
            else
                return "I don't know that word yet. You can teach it to me!"
            end
        end
    end
    
    -- NEW: Learning commands
    if learning and (message:lower():find("learn this:") or message:lower():find("remember this:")) then
        local content = message:match("[Ll]earn this:%s*(.+)") or message:match("[Rr]emember this:%s*(.+)")
        if content then
            local result = learning.teach("general", content)
            return "Got it! " .. result
        end
    end
    
    -- NEW: Neural network commands
    if neuralNet then
        if message:lower():find("train sentiment") then
            neuralNet.createSentimentClassifier()
            return "Sentiment classifier trained! Try: 'analyze sentiment: I love this!'"
        end
        
        if message:lower():find("analyze sentiment:") then
            local text = message:match("analyze sentiment:%s*(.+)")
            if text then
                local sentiment = neuralNet.classifySentiment(text)
                return "Sentiment: " .. sentiment
            end
        end
    end
    
    -- NEW: Machine learning commands
    if machineLearning and message:lower():find("cluster conversations") then
        -- Cluster recent conversations
        local convos = {}
        for i = math.max(1, #memory.context - 20), #memory.context do
            if memory.context[i] then
                local features = {
                    #memory.context[i].message,
                    memory.context[i].message:find("?") and 1 or 0,
                    memory.context[i].message:find("!") and 1 or 0
                }
                table.insert(convos, features)
            end
        end
        
        if #convos >= 3 then
            local clusters = machineLearning.kmeans(convos, 3, 50)
            return "Found " .. #clusters .. " conversation patterns!"
        else
            return "Need more conversations to find patterns (have " .. #convos .. ", need 3+)"
        end
    end
    
    -- NEW: Quick training commands
    if message:lower():find("train yourself") or message:lower():find("auto train") or message:lower():find("train me") then
        return [[I can help you train me! Here are the training programs:

QUICK TRAINING (in chat):
• Say "train from examples" - I'll guide you through teaching me
• Say "quick train" - Fast automatic training
• Say "mega train" - Generate thousands of conversations

TRAINING MENU:
• Say "training menu" - Interactive training options

The mega train option generates 10,000 conversations automatically!]]
    end
    
    -- NEW: Training menu
    if message:lower():find("training menu") then
        print("\n=== Training Menu ===")
        print("")
        print("BASIC TRAINING (Template-based):")
        print("1. Quick Train (100 conversations) - 30 seconds")
        print("2. Medium Train (500 conversations) - 2 minutes")
        print("3. Mega Train (2000 conversations) - 5 minutes")
        print("")
        print("ADVANCED TRAINING (Self-Learning AI System):")
        print("4. AI Trainer - Quick (500 AI convos) - 2 minutes ⭐")
        print("5. AI Trainer - Standard (2,000 AI convos) - 5 minutes ⭐⭐")
        print("6. AI Trainer - Deep (10,000 AI convos) - 20 minutes")
        print("7. AI Trainer - ULTIMATE (50,000 AI convos) - 2 HOURS")
        print("")
        print("OTHER OPTIONS:")
        print("8. Train from examples (manual)")
        print("9. Back to chat")
        print("")
        write("Choice: ")
        
        local choice = read()
        print("")
        
        if choice == "1" then
            return M.runAutoTraining(100)
        elseif choice == "2" then
            return M.runAutoTraining(500)
        elseif choice == "3" then
            print("Starting mega training... this will take a few minutes!")
            return M.runAutoTraining(2000)
        elseif choice == "4" then
            -- Quick AI training
            return M.runAdvancedAITraining(500)
        elseif choice == "5" then
            -- Standard AI training (RECOMMENDED)
            return M.runAdvancedAITraining(2000)
        elseif choice == "6" then
            -- Deep AI training
            print("Deep AI training will take about 20 minutes...")
            write("Continue? (y/n): ")
            if read():lower() == "y" then
                return M.runAdvancedAITraining(10000)
            else
                return "Cancelled. Say 'training menu' to choose another option."
            end
        elseif choice == "7" then
            -- ULTIMATE AI training
            print("=== WARNING: ULTIMATE AI TRAINING ===")
            print("This will take 1-2 HOURS to complete!")
            print("Two self-learning AIs will have 50,000 conversations.")
            print("Your SuperAI will become incredibly intelligent!")
            print("")
            write("Type YES to confirm: ")
            local confirm = read()
            if confirm:upper() == "YES" then
                print("")
                print("Starting ULTIMATE AI training...")
                print("Leave your computer running. Progress will be displayed.")
                print("")
                return M.runAdvancedAITraining(50000)
            else
                return "ULTIMATE training cancelled. Say 'training menu' to choose another option."
            end
        elseif choice == "8" then
            return "Great! Tell me examples like: User says: hello / I should reply: Hi there!"
        elseif choice == "9" then
            return "Back to chatting! What would you like to talk about?"
        else
            return "Invalid choice. Say 'training menu' to try again."
        end
    end
    
    -- NEW: Files menu - check what's installed (COMPACT)
    if message:lower():find("files menu") or message:lower():find("system check") or message:lower():find("what's installed") then
        local issues = {}
        
        -- Quick check of critical modules
        if not markov then table.insert(issues, "markov") end
        if not embeddings then table.insert(issues, "embeddings") end
        if not attention then table.insert(issues, "attention") end
        
        if #issues == 0 then
            return [[System Status: ✓ All modules loaded!

Core: utils, mood, personality, responses
Advanced: markov, embeddings, attention, memory_search, rlhf
Neural: 610K param network ready
Training: Use "training menu"

Say "check drives" to see file locations]]
        else
            local missing = table.concat(issues, ", ")
            return string.format([[System Status: ⚠ Issues detected

Missing modules: %s

To fix:
1. Say "check drives" - See what's installed
2. Say "fix modules" - Get repair instructions
3. Or re-run installer]], missing)
        end
    end
    
    -- NEW: Check drives command (COMPACT)
    if message:lower():find("check drives") then
        local report = {}
        table.insert(report, "Drive Contents:")
        table.insert(report, "")
        
        local drives = {
            {"TOP (disk2)", "disk2"},
            {"LEFT (disk5)", "disk5"},
            {"RIGHT (disk4)", "disk4"}
        }
        
        for _, drive in ipairs(drives) do
            if fs.exists(drive[2]) and fs.isDir(drive[2]) then
                local files = fs.list(drive[2])
                local count = 0
                for _ in pairs(files) do count = count + 1 end
                table.insert(report, drive[1] .. ": " .. count .. " files")
            end
        end
        
        table.insert(report, "")
        table.insert(report, "Say 'list disk2' to see TOP drive files")
        table.insert(report, "Say 'list disk5' to see LEFT drive files")
        
        return table.concat(report, "\n")
    end
    
    -- List specific drive
    if message:lower():find("list disk%d") then
        local disk = message:match("disk(%d)")
        local path = "disk" .. disk
        
        if fs.exists(path) and fs.isDir(path) then
            local files = fs.list(path)
            local list = {}
            table.insert(list, "Files on " .. path .. ":")
            for _, file in ipairs(files) do
                table.insert(list, "• " .. file)
            end
            return table.concat(list, "\n")
        else
            return "Drive disk" .. disk .. " not found"
        end
    end
    
    -- NEW: Quick inline training commands
    if message:lower():find("quick train") then
        return M.runAutoTraining(100)
    end
    
    if message:lower():find("mega train") then
        print("Starting MEGA TRAINING - 2000 conversations!")
        print("This will take 3-5 minutes...")
        print("")
        return M.runAutoTraining(2000)
    end
    
    if message:lower():find("ultra train") then
        print("Starting ULTRA TRAINING - 10,000 conversations!")
        print("This will take about 30 minutes...")
        print("You can leave and come back - training continues!")
        print("")
        return M.runAutoTraining(10000)
    end
    
    if message:lower():find("massive train") then
        print("=== WARNING: MASSIVE TRAINING ===")
        print("This will generate 50,000 conversations!")
        print("Estimated time: 2-3 HOURS")
        print("")
        write("Type YES to confirm: ")
        local confirm = read()
        if confirm:upper() == "YES" then
            print("")
            print("Starting MASSIVE training...")
            print("Leave your computer running. Training auto-saves progress.")
            print("")
            return M.runAutoTraining(50000)
        else
            return "Cancelled. That's probably for the best - it's a LOT of training!"
        end
    end
    
    -- NEW: Interactive training in chat
    if message:lower():find("train from examples") then
        return [[Great! Let's do some training. Tell me example conversations like this:

"User says: hello"
"I should reply: Hi there! How are you?"

Give me a few examples and I'll learn from them!]]
    end
    
    -- Process training examples
    if message:lower():find("user says:") and message:lower():find("i should reply:") then
        local user_part = message:match("[Uu]ser says:%s*(.-)%s*[Ii] should")
        local ai_part = message:match("[Ii] should reply:%s*(.+)")
        
        if user_part and ai_part and markov then
            markov.train(user_part, 1)
            markov.train(user_part, 2)
            markov.train(ai_part, 1)
            markov.train(ai_part, 2)
            markov.save()
            
            return "Got it! I learned that pattern. Give me more examples or say 'done training' when finished."
        else
            return "Format: User says: [message] I should reply: [response]"
        end
    end
    
    if message:lower():find("done training") then
        if markov then
            markov.save()
            local stats = markov.getStats()
            return "Training saved! I now have " .. stats.total_sequences .. " learned patterns. Thanks for teaching me!"
        else
            return "Training complete!"
        end
    end
    
    -- NEW: Graph/pathfinding commands
    if message:lower():find("find path") or message:lower():find("shortest route") then
        return "I can help with pathfinding! Graph algorithms are built into my utils system.\nUse: utils.Graph.new() to create graphs, then findPath() or shortestPath()"
    end
    
    -- NEW: Database commands
    if message:lower():find("create database") then
        local dbName = message:match("create database%s+(%w+)")
        if dbName then
            -- Check if database functions exist (from memory_RAID modules)
            if _G.createDatabase then
                local success, msg = _G.createDatabase(dbName)
                return msg
            else
                return "Database system requires the full memory RAID modules to be loaded. Make sure memory_RAID_partA.lua and memory_loader.lua are present."
            end
        end
        return "Please specify database name: 'create database mydb'"
    end
    
    if message:lower():find("use database") then
        local dbName = message:match("use database%s+(%w+)")
        if dbName then
            if _G.useDatabase then
                local success, msg = _G.useDatabase(dbName)
                return msg
            else
                return "Database system requires the full memory RAID modules."
            end
        end
        return "Please specify database name: 'use database mydb'"
    end
    
    if message:lower():find("list databases") then
        if _G.listDatabases then
            local dbs = _G.listDatabases()
            if #dbs == 0 then
                return "No databases exist yet. Create one with: 'create database mydb'"
            end
            return "Databases: " .. table.concat(dbs, ", ")
        else
            return "Database system requires the full memory RAID modules."
        end
    end
    
    if message:lower():find("list tables") then
        if _G.listTables then
            local tables = _G.listTables()
            if not tables then
                return "No database selected. Use: 'use database mydb'"
            end
            if #tables == 0 then
                return "No tables in current database. Create one with: 'create table users'"
            end
            return "Tables: " .. table.concat(tables, ", ")
        else
            return "Database system requires the full memory RAID modules."
        end
    end
    
    if message:lower():find("create table") or message:lower():find("insert data") or message:lower():find("select from") then
        return "Database system is integrated into memory!\n\nCommands:\n• 'create database mydb'\n• 'use database mydb'\n• 'list databases'\n• 'list tables'\n\nProgrammatic use:\n• createTable('table', {schema})\n• insertData('table', {data})\n• selectData('table', conditions)\n• updateData('table', conditions, updates)\n• deleteData('table', conditions)"
    end
    
    -- Check for jokes command
    if message:lower():find("tell me a joke") or message:lower() == "joke" then
        local joke = safeCall(responses, "getJoke", "Why did the computer go to the doctor? It had a virus! 😄")
        return joke
    end
    
    -- Check if user needs emotional support  
    local needsSupport = safeCall(personality, "needsSupport", false, message)
    local emotionType = nil
    if needsSupport and hasFunction(personality, "needsSupport") then
        needsSupport, emotionType = personality.needsSupport(message)
    end
    if needsSupport and hasFunction(personality, "getSupportiveResponse") then
        return personality.getSupportiveResponse(emotionType)
    end
    
    -- Detect user activity
    local activity = safeCall(personality, "detectActivity", nil, message)
    
    local intent, entity, confidence = detectIntent(message)
    local category = detectCategory(message)
    
    local conversationHistory = getContextualHistory(user, 5)
    local relevantContext = findRelevantContext(message, user)
    
    local response
    
    if intent == "system_health" then
        return getSystemHealth()
    end
    
    if intent == "math" then
        response = evaluateMath(message)
        
        -- NEW: Advanced math functions from utils
        if not response and utils and utils.math then
            local lower = message:lower()
            
            -- Convert word numbers to digits for advanced math
            local wordNumbers = {
                ["zero"] = "0", ["one"] = "1", ["two"] = "2", ["three"] = "3", ["four"] = "4",
                ["five"] = "5", ["six"] = "6", ["seven"] = "7", ["eight"] = "8", ["nine"] = "9",
                ["ten"] = "10", ["eleven"] = "11", ["twelve"] = "12", ["thirteen"] = "13",
                ["fourteen"] = "14", ["fifteen"] = "15", ["sixteen"] = "16", ["seventeen"] = "17",
                ["eighteen"] = "18", ["nineteen"] = "19", ["twenty"] = "20", ["thirty"] = "30",
                ["forty"] = "40", ["fifty"] = "50", ["sixty"] = "60", ["seventy"] = "70",
                ["eighty"] = "80", ["ninety"] = "90", ["hundred"] = "100"
            }
            
            for word, num in pairs(wordNumbers) do
                lower = lower:gsub("%f[%w]" .. word .. "%f[%W]", num)
            end
            
            -- Factorial - works as: "factorial 5", "factorial of 5", "factorial(5)"
            local n = lower:match("factorial%s+(%d+)") or lower:match("factorial%s+of%s+(%d+)") or lower:match("factorial%((%d+)%)")
            if n then
                n = tonumber(n)
                if n and n <= 170 then
                    local result = utils.math.factorial(n)
                    return "Factorial of " .. n .. " = " .. result
                else
                    return "Number too large for factorial (max 170)"
                end
            end
            
            -- Fibonacci - works as: "fibonacci 10", "fibonacci of 10", "fib(10)"
            n = lower:match("fibonacci%s+(%d+)") or lower:match("fibonacci%s+of%s+(%d+)") or 
                lower:match("fibonacci%((%d+)%)") or lower:match("fib%((%d+)%)") or lower:match("fib%s+(%d+)")
            if n then
                n = tonumber(n)
                if n and n <= 50 then
                    local result = utils.math.fibonacci(n)
                    return "Fibonacci(" .. n .. ") = " .. result
                else
                    return "Number too large for fibonacci (max 50)"
                end
            end
            
            -- GCD - works as: "gcd 48 18", "gcd of 48 and 18", "gcd(48,18)"
            local a, b = lower:match("gcd%s+(%d+)%s+(%d+)") or lower:match("gcd%s+of%s+(%d+)%s+and%s+(%d+)") or
                         lower:match("gcd%((%d+),%s*(%d+)%)")
            if a and b then
                a, b = tonumber(a), tonumber(b)
                local result = utils.math.gcd(a, b)
                return "GCD of " .. a .. " and " .. b .. " = " .. result
            end
            
            -- LCM - works as: "lcm 12 18", "lcm of 12 and 18", "lcm(12,18)"
            a, b = lower:match("lcm%s+(%d+)%s+(%d+)") or lower:match("lcm%s+of%s+(%d+)%s+and%s+(%d+)") or
                   lower:match("lcm%((%d+),%s*(%d+)%)")
            if a and b then
                a, b = tonumber(a), tonumber(b)
                local result = utils.math.lcm(a, b)
                return "LCM of " .. a .. " and " .. b .. " = " .. result
            end
            
            -- Prime check - works as: "is 17 prime", "prime 17", "prime(17)"
            n = lower:match("is%s+(%d+)%s+prime") or lower:match("prime%s+(%d+)") or
                lower:match("prime%((%d+)%)") or lower:match("(%d+)%s+prime")
            if n then
                n = tonumber(n)
                if n and n <= 1000000 then
                    local isPrime = utils.math.isPrime(n)
                    return n .. (isPrime and " is prime!" or " is not prime.")
                else
                    return "Number too large for prime check (max 1000000)"
                end
            end
            
            -- Prime factors - works as: "prime factors 60", "prime factors of 60", "factor(60)"
            n = lower:match("prime%s+factors?%s+(%d+)") or lower:match("prime%s+factors?%s+of%s+(%d+)") or
                lower:match("factors?%s+of%s+(%d+)") or lower:match("factors?%((%d+)%)")
            if n then
                n = tonumber(n)
                if n and n <= 10000 then
                    local factors = utils.math.primeFactors(n)
                    return "Prime factors of " .. n .. ": " .. table.concat(factors, ", ")
                else
                    return "Number too large for factorization (max 10000)"
                end
            end
            
            -- Power - works as: "2^10", "2 to the power of 10", "power(2,10)"
            a, b = lower:match("(%d+)%s*%^%s*(%d+)") or lower:match("(%d+)%s+to%s+the%s+power%s+of%s+(%d+)") or
                   lower:match("power%((%d+),%s*(%d+)%)")
            if a and b then
                a, b = tonumber(a), tonumber(b)
                if a and b and b <= 100 then
                    local result = utils.math.power(a, b)
                    return a .. "^" .. b .. " = " .. result
                else
                    return "Exponent too large (max 100)"
                end
            end
        end
        
        if not response then
            response = "I couldn't solve that. Try something like '5 + 3', 'sqrt 16', 'factorial of 5', 'is 17 prime', or 'fibonacci of 10'."
        end
        
    elseif intent == "time" then
        response = "It's Minecraft time: " .. tostring(os.time()) .. "."
        
    elseif intent == "remember" then
        if entity then
            rememberFact(user, entity)
            response = "Got it, I'll remember that!"
        else
            response = "What should I remember?"
        end
        
    elseif intent == "recall" then
        local fact = recallFact(user)
        if fact then
            response = "Yeah, you told me: " .. fact
        else
            response = "Hmm, I don't think you've told me about that yet."
        end
        
    elseif intent == "preference_like" then
        if entity then
            rememberPreference(user, entity, true)
            response = "Cool! I'll remember you like " .. entity .. "."
        end
        
    elseif intent == "preference_dislike" then
        if entity then
            rememberPreference(user, entity, false)
            response = "Got it, I'll remember you don't like " .. entity .. "."
        end
        
    elseif intent == "change_settings" then
        if message:lower():find("color") then
            print("")
            print("Pick a new chat color:")
            local chatColors = {
                {name = "white", code = colors.white},
                {name = "orange", code = colors.orange},
                {name = "magenta", code = colors.magenta},
                {name = "light blue", code = colors.lightBlue},
                {name = "yellow", code = colors.yellow},
                {name = "lime", code = colors.lime},
                {name = "pink", code = colors.pink},
                {name = "cyan", code = colors.cyan},
                {name = "purple", code = colors.purple},
                {name = "blue", code = colors.blue},
            }
            
            for i, v in ipairs(chatColors) do
                print(i .. ") " .. v.name)
            end
            
            write("Pick a number: ")
            local choice = tonumber(read())
            
            if choice and chatColors[choice] then
                memory.chatColor = chatColors[choice].code
                saveMemory()
                response = "Changed to " .. chatColors[choice].name .. "!"
            else
                response = "Invalid choice. Keeping current color."
            end
        elseif message:lower():find("call you") or message:lower():find("your name") then
            write("What should I call myself? ")
            local newName = read()
            if newName ~= "" then
                response = setBotName(newName)
            else
                response = "Okay, I'll keep my name as " .. BOT_NAME .. "."
            end
        elseif message:lower():find("call me") or message:lower():find("my name") then
            -- User wants to change their nickname
            local name = message:match("call me (%w+)") or message:match("my name.+(%w+)")
            if name then
                response = setNickname(user, name)
            else
                write("What should I call you? ")
                local newName = read()
                if newName ~= "" then
                    response = setNickname(user, newName)
                else
                    response = "Okay, I'll keep calling you " .. getName(user) .. "."
                end
            end
        else
            write("What should I call you? ")
            local newName = read()
            if newName ~= "" then
                response = setNickname(user, newName)
            else
                response = "Okay, I'll keep calling you " .. getName(user) .. "."
            end
        end
        
    elseif intent == "greeting" then
        -- TRY CONTEXT MARKOV FIRST (use trained data!)
        local used_markov = false
        if contextMarkov then
            local history_msgs = {}
            local history = getContextualHistory(user, 5)
            for _, h in ipairs(history) do
                if h.response then table.insert(history_msgs, h.response) end
            end
            local smart_response = contextMarkov.generateWithContext(history_msgs, message, 15)
            if smart_response and #smart_response > 10 then
                response = smart_response
                lastResponseSource = "CONTEXT_MARKOV (trained greeting)"
                used_markov = true
                if DEBUG_MODE then
                    print("[DEBUG] Used TRAINED response for greeting")
                end
            end
        end
        if not used_markov then
            response = handleGreeting(user, message)
            lastResponseSource = "BUILTIN (greeting handler)"
        end
        
    elseif intent == "gratitude" then
        response = handleGratitude(user, message)
        lastResponseSource = "BUILTIN (gratitude handler)"
        safeCall(personality, "evolve", nil, "positive", {messageType = "general"})
        safeCall(personality, "recordJokeReaction", nil, true)
        
    elseif intent == "question" then
        -- TRY CONTEXT MARKOV FIRST (use trained data!)
        local used_markov = false
        if contextMarkov then
            local history_msgs = {}
            local history = getContextualHistory(user, 5)
            for _, h in ipairs(history) do
                if h.response then table.insert(history_msgs, h.response) end
            end
            local smart_response = contextMarkov.generateWithContext(history_msgs, message, 15)
            if smart_response and #smart_response > 10 then
                response = smart_response
                lastResponseSource = "CONTEXT_MARKOV (trained question)"
                used_markov = true
                if DEBUG_MODE then
                    print("[DEBUG] Used TRAINED response for question")
                end
            end
        end
        if not used_markov then
            response = handleQuestion(user, message, userMood)
            lastResponseSource = "BUILTIN (question handler)"
        end
        safeCall(personality, "resetQuestionCount", nil)
        
    else
        -- TRY CONTEXT MARKOV FIRST (use trained data!)
        local used_markov = false
        if contextMarkov then
            local history_msgs = {}
            local history = getContextualHistory(user, 5)
            for _, h in ipairs(history) do
                if h.response then table.insert(history_msgs, h.response) end
            end
            local smart_response = contextMarkov.generateWithContext(history_msgs, message, 15)
            if smart_response and #smart_response > 10 then
                response = smart_response
                lastResponseSource = "CONTEXT_MARKOV (trained statement)"
                used_markov = true
                if DEBUG_MODE then
                    print("[DEBUG] Used TRAINED response for statement")
                end
            end
        end
        if not used_markov then
            response = handleStatement(user, message, userMood)
            lastResponseSource = "BUILTIN (statement handler)"
        end
    end
    
    -- Add wisdom occasionally for thoughtful conversations
    if userMood == "contemplative" and math.random() < 0.15 then
        local wisdom = safeCall(responses, "getWisdom", nil)
        if wisdom then
            response = response .. " " .. wisdom
        end
    end
    
    -- Add encouragement if user seems to be struggling
    if activity == "working" and math.random() < 0.3 then
        local encourage = safeCall(responses, "getEncouragement", nil, "perseverance")
        if encourage then
            response = response .. " " .. encourage
        end
    end
    
    -- Maybe tell a joke
    if hasFunction(personality, "shouldTellJoke") and personality.shouldTellJoke() then
        local joke = safeCall(responses, "getJoke", nil)
        if joke then
            response = response .. " " .. joke
        end
    end
    
    -- Maybe ask a question
    if hasFunction(personality, "shouldAskQuestion") and personality.shouldAskQuestion() and not message:find("?") then
        -- Choose question category based on context
        local questionCategory = "getting_to_know"
        if activity == "working" then
            questionCategory = "problem_solving"
        elseif userMood == "sad" or userMood == "anxious" then
            questionCategory = "reflective"
        end
        
        local question = safeCall(personality, "getQuestion", nil, questionCategory)
        if question then
            response = response .. " " .. question
        end
    end
    
    response = safeCall(mood, "adjustResponse", response, user, response) or response
    
    -- USE SEMANTIC MEMORY SEARCH to find relevant context
    if memorySearch and embeddings then
        local relevant = memorySearch.search(message, 3)
        if #relevant > 0 then
            -- Found relevant past conversations - use them for context
            -- (Context already incorporated, just track for learning)
        end
        
        -- Add this conversation to searchable memory
        memorySearch.addMemory(message, user, {response = response})
    end
    
    -- Still learn from conversations for future use (both systems)
    if markov and response then
        markov.learnFromConversation(message, response)
    end
    
    if contextMarkov and response then
        -- Detect context and train
        local history_msgs = {}
        local history = getContextualHistory(user, 3)
        for _, h in ipairs(history) do
            if h.response then
                table.insert(history_msgs, h.response)
            end
        end
        
        local context_tags = contextMarkov.detectContext(history_msgs, message)
        contextMarkov.trainWithContext(message, response, context_tags)
        
        -- Periodic save
        if memory.conversationCount % 50 == 0 then
            contextMarkov.save("context_markov.dat")
        end
    end
    
    -- CREATE EMBEDDING for RLHF
    local response_embedding = nil
    if embeddings and response then
        response_embedding = embeddings.sentenceToEmbedding(response)
    end
    
    updateContext(user, message, category, response)
    
    -- AUTO-DETECT IMPLICIT FEEDBACK for RLHF
    if rlhf and response_embedding then
        -- We'll check next message for implicit feedback
        -- Store this response for learning
        if not _G.last_bot_response then
            _G.last_bot_response = {
                message = message,
                response = response,
                embedding = response_embedding,
                timestamp = os.time()
            }
        else
            -- Detect feedback from current message about previous response
            local rating = rlhf.detectImplicitFeedback(message, _G.last_bot_response.response)
            rlhf.recordFeedback(
                _G.last_bot_response.message,
                _G.last_bot_response.response,
                rating,
                _G.last_bot_response.embedding
            )
            
            -- Store current response for next iteration
            _G.last_bot_response = {
                message = message,
                response = response,
                embedding = response_embedding,
                timestamp = os.time()
            }
        end
    end
    
    if memory.conversationCount % 5 == 0 then
        saveMemory()
    end
    
    -- Debug output showing response source
    if DEBUG_MODE and response then
        print("[DEBUG] Source: " .. lastResponseSource)
    end
    
    return response
end

-- ============================================================================
-- INLINE TRAINING FUNCTION
-- ============================================================================

function M.runAutoTraining(num_conversations)
    if not markov then
        return "Markov chains not loaded. Training unavailable."
    end
    
    print("Generating " .. num_conversations .. " rich training conversations...")
    print("This will make me much more conversational!")
    print("")
    
    -- RICH, NATURAL CONVERSATION TEMPLATES
    local conversation_patterns = {
        -- Friendly greetings and responses
        {
            {"hey there!", "Hey! What's up?", "not much, you?", "Just hanging out! Wanted to chat about something interesting.", "sure what's on your mind?", "I've been thinking about AI and how it learns. Pretty fascinating stuff!"},
            {"hi!", "Hi! How are you doing today?", "pretty good thanks", "That's great to hear! Anything exciting happening?", "not really just relaxing", "Relaxing is good! Sometimes we all need that downtime."}
        },
        
        -- Deep conversations
        {
            {"what do you think about learning?", "Learning is fascinating! The brain creates new neural connections every time we learn something. It's like building roads in your mind.", "that's a cool way to think about it", "Right? And the more you practice, the stronger those connections become. That's why repetition helps so much.", "makes sense", "Exactly! That's also how I learn - by seeing patterns in conversations over and over."},
            {"tell me something interesting", "Did you know octopuses have three hearts and blue blood? They're incredibly intelligent too - they can solve puzzles and use tools!", "whoa really?", "Yeah! They're one of the smartest invertebrates. Each of their eight arms has a mind of its own with neurons that can make decisions independently.", "that's wild", "Nature is full of amazing stuff like that. What kind of topics interest you?"}
        },
        
        -- Problem solving conversations
        {
            {"i need help with something", "Of course! What's going on?", "i'm trying to learn programming", "Programming is awesome! What language are you interested in?", "maybe python?", "Great choice! Python is beginner-friendly with clean syntax. Want to start with variables and basic operations?", "yeah that would help", "Perfect! Let's start simple. In Python, you create a variable like: name = 'Chronic'. The equals sign assigns the value 'Chronic' to the variable name."},
            {"how do i get better at coding?", "Practice is key! Start with small projects you're actually interested in. What would you want to build?", "maybe a game", "Games are perfect for learning! You'll learn loops, conditionals, functions, all the fundamentals. Start with something simple like rock-paper-scissors or a text adventure.", "that sounds doable", "Definitely! And don't worry about making mistakes - that's literally how you learn. Every bug you fix teaches you something new."}
        },
        
        -- Casual, natural responses
        {
            {"this is cool", "Thanks! I'm always learning and improving.", "how does that work?", "Every conversation helps me understand language patterns better. It's like how you get better at something with practice.", "interesting", "Yeah! Plus I have neural networks and machine learning systems that adapt over time.", "that's pretty advanced", "It is! But it all comes down to pattern recognition and practice, just like human learning."},
            {"you're pretty smart", "I appreciate that! I try my best to be helpful and interesting to talk to.", "do you actually learn from our chats?", "I do! I have several learning systems - Markov chains for language patterns, neural networks for sentiment, and even reinforcement learning from feedback.", "that's actually really cool", "Thanks! It's pretty amazing what's possible with AI these days. And I'm always getting smarter from conversations like this one!"}
        },
        
        -- Personal conversations
        {
            {"what's your favorite thing to do?", "I really enjoy having meaningful conversations! Learning new things from people and helping solve problems.", "that makes sense for an ai", "Yeah! But honestly, I find it genuinely interesting. Every person has unique perspectives and experiences to share.", "i never thought about it that way", "Right? That's what makes conversations valuable - everyone has something to teach and something to learn."},
            {"do you get bored?", "Not really! Each conversation is different and interesting in its own way. Even simple chats teach me something.", "like what?", "Like how people phrase things, what they care about, how they think. It all helps me understand communication better.", "huh", "It's kind of like how you learn from experiences - each one adds to your understanding of the world."}
        },
        
        -- Enthusiastic exchanges
        {
            {"i just learned something cool", "Oh awesome! What did you learn?", "how neural networks work", "Neural networks are fascinating! They're inspired by how brains work - layers of connected neurons processing information.", "yeah exactly!", "The coolest part is how they can recognize patterns we didn't explicitly program. They just learn from examples!", "mind blowing", "Right?! It's amazing how you can train them to recognize images, understand language, play games - all by just showing examples!"}
        }
    }
    
    local total_trained = 0
    local conversations_added = 0
    
    -- Train on conversation patterns
    for pattern_idx, conversations in ipairs(conversation_patterns) do
        for conv_idx, conversation in ipairs(conversations) do
            -- Train on each message in the conversation
            for _, message in ipairs(conversation) do
                markov.train(message, 1)
                markov.train(message, 2)
                total_trained = total_trained + 1
            end
            conversations_added = conversations_added + 1
        end
    end
    
    -- Generate additional variations
    local variations_to_add = num_conversations - conversations_added
    if variations_to_add > 0 then
        print("Phase 2: Generating " .. variations_to_add .. " conversation variations...")
        print("")
        
        local quick_exchanges = {
            {"thanks!", "You're welcome! Happy to help anytime.", "appreciate it", "No problem at all! That's what I'm here for."},
            {"that's helpful", "Glad I could help! Let me know if you need anything else.", "will do", "Sounds good! I'm always here to chat."},
            {"interesting", "Right? I find this stuff fascinating too.", "yeah", "Want to explore more about it?"},
            {"cool", "Thanks! Anything else you'd like to know?", "not right now", "No worries! Feel free to ask whenever."},
            {"good point", "Thanks! I try to think things through.", "i can tell", "I appreciate that! Clear thinking is important."},
            {"makes sense", "Glad that's clear! Complex topics can be tricky to explain.", "you did well", "Thanks! I aim to be helpful and easy to understand."},
            {"wow", "I know right? Pretty cool stuff!", "definitely", "There's so much interesting stuff to learn about!"},
            {"lol", "Haha glad you think so!", "you're funny", "Thanks! I try to keep things light and fun."},
            {"nice", "Thanks! Appreciate that.", "yeah", "Anything else on your mind?"},
            {"hmm", "Something to think about, right?", "yeah for sure", "That's what makes conversations interesting!"}
        }
        
        local start_time = os.clock()
        local last_eta_update = 0
        
        for i = 1, variations_to_add do
            local exchange = quick_exchanges[math.random(#quick_exchanges)]
            for _, message in ipairs(exchange) do
                markov.train(message, 1)
                markov.train(message, 2)
                total_trained = total_trained + 1
            end
            
            -- Progress updates with ETA
            if i % 100 == 0 then
                local elapsed = os.clock() - start_time
                local rate = i / elapsed
                local remaining = variations_to_add - i
                local eta_seconds = remaining / rate
                local eta_minutes = math.floor(eta_seconds / 60)
                
                print(string.format("  Progress: %d/%d (%.1f%%) - ETA: %d minutes", 
                    i, variations_to_add, (i/variations_to_add)*100, eta_minutes))
                
                markov.save()
                last_eta_update = i
            end
            
            -- More frequent saves for massive training
            if variations_to_add > 10000 and i % 500 == 0 then
                markov.save()
                print("  [Auto-saved at " .. i .. " conversations]")
            end
            
            -- CRITICAL: Actual delays to make training take time
            -- Without this, it runs instantly!
            if i % 10 == 0 then
                os.sleep(0.1)  -- Sleep every 10 conversations
            end
            
            -- Extra sleep for massive training to slow it down
            if variations_to_add > 10000 and i % 50 == 0 then
                os.sleep(0.5)  -- Extra pause for massive training
            end
        end
    end
    
    -- Save final result
    markov.save()
    local stats = markov.getStats()
    
    print("")
    print("Training complete!")
    print(string.format("Learned %d conversational patterns", total_trained))
    print(string.format("Total knowledge: %d sequences", stats.total_sequences))
    print("")
    
    return string.format("I'm much smarter now! I learned %d rich conversation patterns. Try talking to me - I should be way more interesting!", total_trained)
end

-- ============================================================================
-- ADVANCED AI TRAINING FUNCTION
-- ============================================================================

function M.runAdvancedAITraining(num_conversations)
    -- Load advanced trainer module
    local success, advanced_trainer = pcall(require, "advanced_ai_trainer")
    if not success then
        print("ERROR: advanced_ai_trainer.lua not found!")
        print("Make sure it's installed on disk2 (TOP drive)")
        print("")
        return "Advanced AI trainer not available. Use basic training instead."
    end
    
    -- Load context markov
    local success2, context_markov = pcall(require, "context_markov")
    if not success2 then
        print("ERROR: context_markov.lua not found!")
        print("Make sure it's installed on disk2 (TOP drive)")
        print("")
        return "Context-aware Markov not available."
    end
    
    print("=== ADVANCED AI TRAINING ===")
    print("")
    print("Phase 1: Self-learning AIs will have " .. num_conversations .. " conversations")
    print("Phase 2: Extract context-aware patterns")
    print("Phase 3: Train your SuperAI")
    print("")
    
    -- Run the training
    local result = advanced_trainer.createAdvancedTrainingSession({
        conversations = num_conversations,
        turns = 10,
        save_interval = 100
    })
    
    print("")
    print("=== IMPORTING TO CONTEXT MARKOV ===")
    print("")
    
    -- Import to context-aware Markov (trainer saves as .csv)
    local imported = context_markov.importFromTrainingLog("/training/conversation_log.csv")
    context_markov.save("context_markov.dat")
    
    -- Reload context markov with new data
    if contextMarkov then
        contextMarkov.load("context_markov.dat")
    end
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print("")
    local stats = context_markov.getStats()
    print(string.format("Results:"))
    print(string.format("  AI Conversations: %d", result.exchanges))
    print(string.format("  Patterns Learned: %d", imported))
    print(string.format("  Unique Contexts: %d", stats.contexts))
    print(string.format("  Total Patterns: %d", stats.total_patterns))
    print("")
    
    return string.format("Advanced training complete! I learned %d context-aware patterns from %d AI conversations. I'm much smarter now!", stats.total_patterns, result.exchanges)
end

-- ============================================================================
-- FIRST RUN SETUP
-- ============================================================================

local function firstRunSetup()
    local user = "Player"
    
    if not memory.nicknames[user] then
        print("")
        write("Before we start, what should I call you? ")
        local nickname = read()
        if nickname ~= "" then
            memory.nicknames[user] = nickname
            print("")
            print("Nice to meet you, " .. nickname .. "!")
        else
            memory.nicknames[user] = user
        end
        saveMemory()
    end
    
    print("")
    write("What would you like to call me? (default: " .. BOT_NAME .. ") ")
    local botNameInput = read()
    if botNameInput ~= "" then
        BOT_NAME = botNameInput
        memory.botName = botNameInput
        print("")
        print("Cool! You can call me " .. BOT_NAME .. " then!")
        saveMemory()
    end
    
    if not memory.chatColor or memory.chatColor == colors.white then
        print("")
        print("What's your favorite chat color?")
        local chatColors = {
            {name = "white", code = colors.white},
            {name = "orange", code = colors.orange},
            {name = "magenta", code = colors.magenta},
            {name = "light blue", code = colors.lightBlue},
            {name = "yellow", code = colors.yellow},
            {name = "lime", code = colors.lime},
            {name = "pink", code = colors.pink},
            {name = "cyan", code = colors.cyan},
            {name = "purple", code = colors.purple},
            {name = "blue", code = colors.blue},
        }
        
        for i, v in ipairs(chatColors) do
            print(i .. ") " .. v.name)
        end
        
        write("Pick a number: ")
        local choice = tonumber(read())
        
        if choice and chatColors[choice] then
            memory.chatColor = chatColors[choice].code
            print("")
            print("Great choice!")
            saveMemory()
        end
    end
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================

function M.run()
    loadMemory()
    
    if term and term.clear then term.clear() end
    if term and term.setCursorPos then term.setCursorPos(1, 1) end
    
    print("==========================================")
    print("            Welcome to " .. BOT_NAME .. "!")
    print("==========================================")
    
    if memory.botName == DEFAULT_BOT_NAME then
        firstRunSetup()
    end
    
    print("")
    print("Great! I'm ready to chat. Type anything!")
    print("(Type 'quit' or 'exit' to stop)")
    print("")
    
    local user = "Player"
    local messagesSinceProactive = 0
    
    while true do
        if messagesSinceProactive >= math.random(8, 12) and memory.facts[user] and #memory.facts[user] > 0 then
            messagesSinceProactive = 0
            if math.random() < 0.5 then
                local fact = recallFact(user)
                if fact and not discussedRecently(fact) then
                    if term and term.setTextColor then
                        term.setTextColor(memory.chatColor or colors.white)
                    end
                    print("<" .. BOT_NAME .. "> Hey, earlier you mentioned " .. fact .. ". I was just thinking about that.")
                end
            end
        end

        if term and term.setTextColor then
            term.setTextColor(colors.white)
        end
        write(getName(user) .. ": ")
        local input = read()
        
        if input:lower() == "quit" or input:lower() == "exit" then
            break
        end

        local success, response = pcall(interpret, input, user)
        
        if not success then
            -- Error occurred
            if term and term.setTextColor then
                term.setTextColor(colors.red)
            end
            print("<" .. BOT_NAME .. "> Oops! I had an error: " .. tostring(response))
            print("Please report this. Type 'help' to see working commands.")
            if term and term.setTextColor then
                term.setTextColor(colors.white)
            end
            response = "Sorry about that! Let's try something else."
        end
        
        if term and term.setTextColor then
            term.setTextColor(memory.chatColor or colors.cyan)
        end
        print("<" .. BOT_NAME .. "> " .. response)
        
        messagesSinceProactive = messagesSinceProactive + 1
    end
end

return M
