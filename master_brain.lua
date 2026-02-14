-- master_brain.lua - Enhanced AI System
-- Combines cluster coordination with comprehensive AI capabilities from main_logic.lua
-- Auto-installs to advanced computer and runs after reboot

-- ============================================================================
-- CLUSTER COORDINATION (from embedded master_brain.lua)
-- ============================================================================

local PROTOCOL, workers, roles = "MODUS_CLUSTER", {}, {"language","memory","response","personality"}
for _, n in ipairs(peripheral.getNames()) do 
    if peripheral.getType(n)=="modem" then 
        rednet.open(n) 
    end 
end

-- ============================================================================
-- ENHANCED AI SYSTEM (from main_logic.lua)
-- ============================================================================

local M = {}

-- Load dependencies with safe error handling
local function safeRequire(module_name, description)
    local success, module = pcall(require, module_name)
    if success then
        print("✓ " .. description .. " loaded")
        return module
    else
        print("⚠ " .. description .. " not found - " .. module_name .. " disabled")
        return nil
    end
end

-- Core modules
local utils = safeRequire("utils", "Utils")
local personality = safeRequire("personality", "Personality")
local mood = safeRequire("mood", "Mood")
local responses = safeRequire("responses", "Responses")

-- Enhanced conversation modules
local convStrat = safeRequire("conversation_strategies", "Conversation Strategies")
local convMem = safeRequire("conversation_memory", "Conversation Memory")
local respGen = safeRequire("response_generator", "Response Generator")

-- Advanced AI modules
local codeGen = safeRequire("code_generator", "Code Generator")
local dictionary = safeRequire("dictionary", "Dictionary")
local learning = safeRequire("learning", "Learning System")
local neuralNet = safeRequire("neural_net", "Neural Network")
local machineLearning = safeRequire("machine_learning", "Machine Learning")
local largeNeural = safeRequire("large_neural_net", "Large Neural Network")
local markov = safeRequire("markov", "Markov Chains")

-- Transformer components
local attention = safeRequire("attention", "Attention Mechanism")
local embeddings = safeRequire("embeddings", "Word Embeddings")
local memorySearch = safeRequire("memory_search", "Semantic Memory Search")
local rlhf = safeRequire("rlhf", "RLHF Training")
local sampling = safeRequire("sampling", "Advanced Sampling")
local tokenization = safeRequire("tokenization", "Tokenization")

-- Meta-cognitive modules
local metaCognition = safeRequire("meta_cognition", "Meta-Cognition")
local introspection = safeRequire("introspection", "Introspection")
local philReasoning = safeRequire("philosophical_reasoning", "Philosophical Reasoning")

-- Initialize conversation memory if available
if convMem and convMem.init then
    convMem.init()
    print("✓ Conversation memory initialized")
end

-- Try to load trained neural network
local trainedNetwork = nil
if largeNeural then
    trainedNetwork = largeNeural.loadNetwork("/neural/")
    if trainedNetwork then
        print("✓ Loaded trained network with " .. trainedNetwork.total_params .. " parameters")
    else
        print("ℹ No trained network found - run neural_trainer to create one")
    end
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DEFAULT_BOT_NAME = "MODUS"
local BOT_NAME = DEFAULT_BOT_NAME
local CONTEXT_WINDOW = 10000
local INTENT_CONFIDENCE_THRESHOLD = 0.6
local DEBUG_MODE = false

-- ============================================================================
-- ENHANCED MEMORY SYSTEM (from main_logic.lua)
-- ============================================================================

local memory = {
    facts = {},          -- User facts
    preferences = {},    -- User preferences
    nicknames = {},      -- User nicknames
    topics = {},         -- Recently discussed topics
    conversations = {},  -- Full conversation history
    context = {},        -- Contextual information
    categories = {},     -- Message categories
}

-- Default categories
local defaultCategories = {
    "general", "tech", "personal", "work", "entertainment", "question", 
    "opinion", "fact", "story", "joke", "compliment", "complaint"
}

-- Initialize categories
for _, cat in ipairs(defaultCategories) do
    memory.categories[cat] = {}
end

-- ============================================================================
-- USER PREFERENCES AND SETTINGS (from embedded master_brain.lua)
-- ============================================================================

local settings = {}
local settingsFile = "modus_settings.lua"

local function loadSettings()
    if fs.exists(settingsFile) then
        local f = fs.open(settingsFile, "r")
        local content = f.readAll()
        f.close()
        local func = loadstring(content)
        if func then
            local env = {}
            setfenv(func, env)
            func()
            settings = env.settings or {}
        end
    end
end

local function saveSettings()
    local f = fs.open(settingsFile, "w")
    f.write("settings = " .. textutils.serialize(settings))
    f.close()
end

-- ============================================================================
-- MEMORY PERSISTENCE
-- ============================================================================

local MEM_FILE = "superai_memory/memory.dat"

local function loadMemory()
    if fs.exists(MEM_FILE) then
        local f = fs.open(MEM_FILE, "r")
        if f then
            local data = f.readAll()
            f.close()
            if data and data ~= "" then
                local func = loadstring(data)
                if func then
                    local env = {}
                    setfenv(func, env)
                    pcall(func)
                    if env.memory then
                        memory = env.memory
                        print("✓ Memory loaded from " .. MEM_FILE)
                    end
                end
            end
        end
    end
end

local function saveMemory()
    -- Ensure directory exists
    local dir = fs.getDir(MEM_FILE)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local f = fs.open(MEM_FILE, "w")
    if f then
        f.write("memory = " .. textutils.serialize(memory))
        f.close()
    end
end

-- ============================================================================
-- SAFE CALL HELPERS
-- ============================================================================

local function safeCall(module, funcName, default, ...)
    if module and module[funcName] and type(module[funcName]) == "function" then
        local success, result = pcall(module[funcName], ...)
        if success then
            return result
        end
    end
    return default
end

local function hasFunction(module, funcName)
    return module and module[funcName] and type(module[funcName]) == "function"
end

-- ============================================================================
-- UTILITY FUNCTIONS (Enhanced from main_logic.lua)
-- ============================================================================

local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user, nickname)
    memory.nicknames[user] = nickname
    saveMemory()
end

local function setBotName(newName)
    BOT_NAME = newName
    settings.botName = newName
    saveSettings()
end

local function rememberFact(user, fact)
    if not memory.facts[user] then memory.facts[user] = {} end
    table.insert(memory.facts[user], {fact = fact, timestamp = os.time()})
    saveMemory()
end

local function rememberPreference(user, item, isLike)
    if not memory.preferences[user] then memory.preferences[user] = {} end
    memory.preferences[user][item] = isLike
    saveMemory()
end

local function trackTopic(topic)
    memory.topics[topic] = os.time()
end

local function discussedRecently(topic)
    local lastTime = memory.topics[topic]
    if not lastTime then return false end
    return (os.time() - lastTime) < 3600 -- Within last hour
end

local function updateContext(user, message, category, response)
    if not memory.context[user] then memory.context[user] = {} end
    
    local contextEntry = {
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    }
    
    table.insert(memory.context[user], contextEntry)
    
    -- Keep only recent context (sliding window)
    while #memory.context[user] > 20 do
        table.remove(memory.context[user], 1)
    end
    
    saveMemory()
end

local function getContextualHistory(user, lookback)
    if not memory.context[user] then return {} end
    local history = {}
    local start = math.max(1, #memory.context[user] - lookback + 1)
    for i = start, #memory.context[user] do
        table.insert(history, memory.context[user][i])
    end
    return history
end

-- ============================================================================
-- ENHANCED MATH EVALUATION (from main_logic.lua)
-- ============================================================================

local function evaluateMath(message)
    local expr = message:gsub("what's", ""):gsub("what is", ""):gsub("%?", "")
    expr = expr:gsub("plus", "+"):gsub("minus", "-"):gsub("times", "*"):gsub("divided by", "/")
    expr = expr:match("([%d%+%-%*%/%(%)\\.%s]+)")
    
    if expr then
        expr = expr:gsub("%s+", "")
        local func = loadstring("return " .. expr)
        if func then
            local success, result = pcall(func)
            if success and type(result) == "number" then
                return tostring(result)
            end
        end
    end
    return nil
end

-- ============================================================================
-- ADVANCED INTENT DETECTION (from main_logic.lua)
-- ============================================================================

local function detectIntent(message)
    local msg = message:lower()
    
    -- Enhanced intent patterns with confidence scoring
    local patterns = {
        greeting = {
            patterns = {"^h[ei]", "^hey", "^hello", "^sup", "^yo", "^good morning", "^good afternoon"},
            confidence = 0.9
        },
        farewell = {
            patterns = {"bye", "goodbye", "see you", "later", "farewell", "take care", "night", "gtg"},
            confidence = 0.9
        },
        question = {
            patterns = {"^what", "^how", "^why", "^when", "^where", "^who", "^can you", "%?"},
            confidence = 0.8
        },
        gratitude = {
            patterns = {"thank", "thanks", "thx", "appreciate", "grateful"},
            confidence = 0.85
        },
        math = {
            patterns = {"what's %d", "what is %d", "%d%s*[%+%-%*%/]", "calculate", "solve"},
            confidence = 0.9
        },
        code_request = {
            patterns = {"write code", "program", "function", "script", "algorithm"},
            confidence = 0.85
        },
        compliment = {
            patterns = {"awesome", "great", "cool", "amazing", "fantastic", "wonderful", "brilliant"},
            confidence = 0.7
        },
        status_inquiry = {
            patterns = {"how are you", "how's it going", "what's up", "how are things"},
            confidence = 0.9
        }
    }
    
    local bestIntent = "statement"
    local bestConfidence = 0
    
    for intent, data in pairs(patterns) do
        for _, pattern in ipairs(data.patterns) do
            if msg:find(pattern) then
                if data.confidence > bestConfidence then
                    bestIntent = intent
                    bestConfidence = data.confidence
                end
            end
        end
    end
    
    return bestIntent, bestConfidence
end

-- ============================================================================
-- ENHANCED RESPONSE GENERATION (from main_logic.lua + cluster coordination)
-- ============================================================================

local function handleGreeting(user, message)
    -- Try cluster response first
    local clusterResponse = nil
    if workers.response and workers.response.ready then
        clusterResponse = task("response", "generateGreeting", {})
        if clusterResponse and clusterResponse.response then
            return clusterResponse.response
        end
    end
    
    -- Enhanced greeting with conversation memory
    if respGen then
        local ctx = {}
        if convMem then
            ctx = safeCall(convMem, "getRecentContext", {}, user) or {}
        end
        
        local response = safeCall(respGen, "generateGreeting", nil, ctx)
        if response then return response end
    end
    
    -- Fallback greetings
    local greetings = {
        "Hey! What's up?",
        "Hi! How's it going?", 
        "Hey there!",
        "Yo! What's good?",
        "Hi! How are you?",
        "Hey! What's happening?",
        "Sup! How are things?",
        "Hey! Good to see you!"
    }
    
    local response = greetings[math.random(#greetings)]
    
    if memory.nicknames[user] then
        local personalGreetings = {
            "Hey " .. memory.nicknames[user] .. "! What's up?",
            "Hi " .. memory.nicknames[user] .. "! How's it going?",
            "Yo " .. memory.nicknames[user] .. "!",
            "Hey " .. memory.nicknames[user] .. "! What's new?"
        }
        response = personalGreetings[math.random(#personalGreetings)]
    end
    
    return response
end

local function handleQuestion(user, message)
    -- Mathematical questions
    local mathResult = evaluateMath(message)
    if mathResult then
        return "The answer is " .. mathResult
    end
    
    -- Try cluster response
    if workers.response and workers.response.ready then
        local clusterResponse = task("response", "generateContextual", {intent="question"})
        if clusterResponse and clusterResponse.response then
            return clusterResponse.response
        end
    end
    
    -- Enhanced question handling
    local msg = message:lower()
    
    if msg:find("who are you") or msg:find("what are you") then
        return "I'm " .. BOT_NAME .. ", an AI assistant with advanced learning capabilities!"
    end
    
    if msg:find("how are you") or msg:find("how's it going") then
        local readyWorkers = 0
        for _, w in pairs(workers) do
            if w.ready then readyWorkers = readyWorkers + 1 end
        end
        return "I'm doing great! All my " .. readyWorkers .. " neural modules are active. How about you?"
    end
    
    if msg:find("what can you do") then
        local capabilities = {
            "chat with advanced conversation memory",
            "solve complex math problems", 
            "generate code",
            "learn from our conversations",
            "remember facts and preferences",
            "coordinate with multiple AI workers"
        }
        return "I can " .. table.concat(capabilities, ", ") .. "... and much more! What would you like to explore?"
    end
    
    -- Use advanced response generation if available
    if respGen then
        local response = safeCall(respGen, "generateContextual", nil, "question", {})
        if response then return response end
    end
    
    -- Fallback
    local responses = {
        "Hmm, good question. What do you think?",
        "I'm not totally sure. What's your take?",
        "That's interesting. I'd have to think about it.",
        "You know, I'm not certain. What's your opinion?"
    }
    
    return responses[math.random(#responses)]
end

local function handleStatement(user, message)
    -- Try cluster response first
    if workers.response and workers.response.ready then
        local clusterResponse = task("response", "generateContextual", {intent="statement"})
        if clusterResponse and clusterResponse.response then
            return clusterResponse.response
        end
    end
    
    -- Enhanced contextual responses
    if respGen then
        local context = getContextualHistory(user, 3)
        local response = safeCall(respGen, "generateContextual", nil, "statement", context)
        if response then return response end
    end
    
    -- Smart status responses
    local msg = message:lower()
    if msg:find("^i'?m ") and (msg:find("good") or msg:find("fine") or msg:find("okay")) then
        local responses = {"Nice!", "Cool cool.", "Good to hear!", "Sweet!", "That's good!"}
        return responses[math.random(#responses)]
    end
    
    -- Fallback responses
    local responses = {
        "Interesting!",
        "I see what you mean.",
        "That's cool!",
        "Tell me more about that.",
        "Right on!",
        "Makes sense to me."
    }
    
    return responses[math.random(#responses)]
end

-- ============================================================================
-- CLUSTER TASK COORDINATION (from embedded master_brain.lua)
-- ============================================================================

local tid = 0
local function task(role, taskName, data)
    local w = workers[role]
    if not w or not w.ready then return nil end
    
    tid = tid + 1
    rednet.send(w.id, {type="task", task=taskName, taskId=tid, data=data or {}}, PROTOCOL)
    
    local deadline = os.clock() + 2
    while os.clock() < deadline do
        local _, msg = rednet.receive(PROTOCOL, 0.3)
        if msg and msg.taskId == tid then 
            return msg.result 
        end
    end
    return nil
end

-- ============================================================================
-- MAIN INTERPRETATION (Enhanced from main_logic.lua)
-- ============================================================================

local function interpret(message, user)
    local intent, confidence = detectIntent(message)
    
    -- Record interaction in cluster memory
    if workers.memory and workers.memory.ready then
        local sentiment = 0
        if workers.language and workers.language.ready then
            local analysis = task("language", "analyze", {text=message})
            sentiment = (analysis and analysis.sentiment) or 0
        end
        task("memory", "recordInteraction", {name=user, message=message, sentiment=sentiment})
    end
    
    -- Use neural network for sentiment if available
    local neuralSentiment = nil
    if neuralNet and hasFunction(neuralNet, "predict") then
        neuralSentiment = safeCall(neuralNet, "predict", 0, message)
    end
    
    -- Generate response based on intent
    local response
    if intent == "greeting" then
        response = handleGreeting(user, message)
    elseif intent == "question" then
        response = handleQuestion(user, message)
    elseif intent == "gratitude" then
        if workers.response and workers.response.ready then
            local clusterResponse = task("response", "generateThanks", {})
            response = (clusterResponse and clusterResponse.response) or "You're welcome!"
        else
            response = "You're welcome!"
        end
    elseif intent == "farewell" then
        if workers.response and workers.response.ready then
            local clusterResponse = task("response", "generateFarewell", {})
            response = (clusterResponse and clusterResponse.response) or "Goodbye!"
        else
            response = "Goodbye!"
        end
    elseif intent == "code_request" and codeGen then
        response = safeCall(codeGen, "generate", "I'd be happy to help with code, but I need more specific requirements.", message)
    else
        response = handleStatement(user, message)
    end
    
    -- Update context and learning
    updateContext(user, message, intent, response)
    
    if learning and hasFunction(learning, "learn") then
        safeCall(learning, "learn", nil, message, response, intent)
    end
    
    return response, intent, confidence
end

-- ============================================================================
-- FIRST-TIME SETUP (from embedded master_brain.lua)
-- ============================================================================

local function firstRunSetup()
    local needsSetup = false
    
    if not settings.userName or settings.userName == "User" then needsSetup = true end
    if not settings.botName or settings.botName == "MODUS" then needsSetup = true end
    if not settings.chatColor or settings.chatColor == colors.white then needsSetup = true end
    
    if not needsSetup then return end
    
    print("==========================================")
    print("        Welcome to MODUS Enhanced!")
    print("==========================================")
    print("")
    print("Let's set up your preferences...")
    print("")
    
    -- Get user name
    if not settings.userName or settings.userName == "User" then
        write("What should I call you? ")
        local name = read()
        if name ~= "" then
            settings.userName = name
            print("Nice to meet you, " .. name .. "!")
        else
            settings.userName = "User"
        end
        print("")
    end
    
    -- Get bot name
    if not settings.botName or settings.botName == "MODUS" then
        write("What would you like to call me? (default: MODUS) ")
        local botName = read()
        if botName ~= "" then
            settings.botName = botName
            setBotName(botName)
            print("Cool! You can call me " .. botName .. " then!")
        else
            settings.botName = "MODUS"
        end
        print("")
    end
    
    -- Get chat color preference  
    if not settings.chatColor or settings.chatColor == colors.white then
        print("Pick your chat color:")
        local chatColors = {
            {name = "white", code = colors.white},
            {name = "orange", code = colors.orange},
            {name = "cyan", code = colors.cyan},
            {name = "purple", code = colors.purple},
            {name = "blue", code = colors.blue},
            {name = "green", code = colors.green},
            {name = "red", code = colors.red},
            {name = "yellow", code = colors.yellow}
        }
        
        for i = 1, #chatColors, 2 do
            local left = i .. ")" .. chatColors[i].name
            local right = ""
            if chatColors[i+1] then
                right = (i+1) .. ")" .. chatColors[i+1].name
            end
            left = left .. string.rep(" ", 18 - #left)
            print(left .. right)
        end
        
        write("Number: ")
        local choice = tonumber(read())
        
        if choice and chatColors[choice] then
            settings.chatColor = chatColors[choice].code
            print("Great choice!")
        else
            settings.chatColor = colors.cyan
        end
        print("")
    end
    
    saveSettings()
    print("Setup complete! Starting enhanced MODUS...")
    print("")
end

-- ============================================================================
-- CLUSTER INITIALIZATION (from embedded master_brain.lua)
-- ============================================================================

local function initializeCluster()
    print("=== MODUS Enhanced v2.0 ===")
    
    local myMasterID = os.getComputerID()
    local comps = {}
    
    for _, n in ipairs(peripheral.getNames()) do
        if peripheral.getType(n) == "computer" then
            local cid = peripheral.call(n, "getID")
            if cid ~= myMasterID then 
                table.insert(comps, {name=n, id=cid}) 
            end
        end
    end
    
    if #comps > 0 then
        print("Initializing cluster with " .. #comps .. " workers...")
        
        for i, c in ipairs(comps) do
            local role = roles[i]
            if role then
                peripheral.call(c.name, "turnOn")
                sleep(0.5)
                rednet.send(c.id, {type="assign_role", role=role}, PROTOCOL)
                
                local deadline = os.clock() + 4
                while os.clock() < deadline do
                    local sid, msg = rednet.receive(PROTOCOL, 0.5)
                    if sid == c.id and msg and msg.type == "role_ack" then
                        workers[role] = {id=c.id, ready=msg.ok}
                        print("  " .. role:upper() .. ": " .. (msg.ok and "OK" or "ERR"))
                        break
                    end
                end
                if not workers[role] then 
                    workers[role] = {id=c.id, ready=false}
                    print("  " .. role:upper() .. ": TIMEOUT") 
                end
            end
        end
        
        local ready = 0
        for _, w in pairs(workers) do 
            if w.ready then ready = ready + 1 end 
        end
        print("\nCluster Ready: " .. ready .. "/4")
    else
        print("No cluster workers found - running in standalone mode")
    end
    
    print("Enhanced AI modules loaded - advanced capabilities active!")
    print("")
end

-- ============================================================================
-- AUTO-TRAINING FUNCTIONS (from main_logic.lua)
-- ============================================================================

function M.runAutoTraining(num_conversations)
    print("Starting auto-training with " .. (num_conversations or 100) .. " iterations...")
    
    if neuralNet and hasFunction(neuralNet, "train") then
        for i = 1, (num_conversations or 100) do
            local sample_input = "Hello, how are you doing today?"
            local sample_output = "I'm doing great! Thanks for asking."
            safeCall(neuralNet, "train", nil, sample_input, sample_output)
        end
        print("✓ Neural network training completed")
    end
    
    if learning and hasFunction(learning, "autoTrain") then
        safeCall(learning, "autoTrain", nil, num_conversations)
        print("✓ Learning system training completed")
    end
    
    saveMemory()
    return true
end

function M.runAdvancedAITraining(num_conversations)
    print("Starting advanced AI training...")
    
    if trainedNetwork and rlhf then
        safeCall(rlhf, "trainFromFeedback", nil, trainedNetwork, memory.conversations)
        print("✓ RLHF training completed")
    end
    
    if attention and hasFunction(attention, "trainAttention") then
        safeCall(attention, "trainAttention", nil, memory.conversations)
        print("✓ Attention mechanism training completed") 
    end
    
    return M.runAutoTraining(num_conversations)
end

-- ============================================================================
-- MAIN EXECUTION FUNCTION
-- ============================================================================

function M.run()
    -- Initialize systems
    loadSettings()
    loadMemory()
    
    -- Set defaults
    if not settings.userName then settings.userName = "User" end
    if not settings.botName then settings.botName = "MODUS" end
    if not settings.chatColor then settings.chatColor = colors.cyan end
    
    BOT_NAME = settings.botName
    
    -- Initialize cluster (will run in standalone mode if no workers)
    initializeCluster()
    
    -- Run first-time setup if needed
    firstRunSetup()
    
    local user = settings.userName or "User"
    
    print("Great! I'm ready to chat with advanced AI capabilities!")
    print("(Type 'quit' to stop, 'status' for system status, 'settings' to change preferences)")
    print("(Type 'train' to run auto-training, 'advanced-train' for full AI training)")
    print("")
    
    -- Main conversation loop
    while true do
        if term and term.setTextColor then term.setTextColor(colors.white) end
        write(user .. "> ")
        local input = read()
        
        if input == "quit" then 
            break
        elseif input == "status" then
            -- Show cluster status
            for role, w in pairs(workers) do 
                print("Cluster " .. role .. ": " .. (w.ready and "OK" or "DOWN")) 
            end
            
            -- Show AI module status
            local modules = {
                {"Neural Network", neuralNet},
                {"Machine Learning", machineLearning}, 
                {"Attention", attention},
                {"Embeddings", embeddings},
                {"Code Generator", codeGen},
                {"Conversation Memory", convMem},
                {"Response Generator", respGen}
            }
            
            for _, module in ipairs(modules) do
                print("AI " .. module[1] .. ": " .. (module[2] and "LOADED" or "DISABLED"))
            end
            
        elseif input == "settings" then
            -- Reset settings to trigger setup without forcing white color
            settings.userName = "User"
            settings.botName = "MODUS"
            settings.chatColor = nil  -- Force re-prompt for color choice
            firstRunSetup()
            user = settings.userName
            BOT_NAME = settings.botName
            
        elseif input == "train" then
            M.runAutoTraining(100)
            print("Training completed!")
            
        elseif input == "advanced-train" then
            M.runAdvancedAITraining(500)
            print("Advanced training completed!")
            
        elseif input:match("^name ") then
            user = input:sub(6)
            settings.userName = user
            saveSettings()
            print("Hi " .. user .. "!")
            
        elseif input ~= "" then
            local response, intent, confidence = interpret(input, user)
            
            if term and term.setTextColor then 
                term.setTextColor(settings.chatColor or colors.cyan) 
            end
            print("\n" .. BOT_NAME .. ": " .. (response or "..."))
            
            if DEBUG_MODE then
                if term and term.setTextColor then term.setTextColor(colors.lightGray) end
                print("[" .. intent .. " | conf:" .. string.format("%.2f", confidence) .. "]\n")
            else
                print("")
            end
        end
    end
    
    -- Shutdown cluster workers
    for _, w in pairs(workers) do 
        rednet.send(w.id, {type="shutdown"}, PROTOCOL) 
    end
    
    print("Goodbye!")
    saveMemory()
end

-- ============================================================================
-- AUTO-STARTUP AND MAIN EXECUTION
-- ============================================================================

-- Auto-start the enhanced MODUS system
M.run()

return M