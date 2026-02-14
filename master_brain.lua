-- master_brain.lua
-- Enhanced Master Brain: Cluster coordinator merged with main_logic features
-- Combines distributed AI cluster with comprehensive standalone AI capabilities

local M = {}

-- ============================================================================
-- CLUSTER CONFIGURATION (from superai_cluster.lua)
-- ============================================================================

M.PROTOCOL = "SUPERAI_CLUSTER"
M.workers = {}
M.masterID = os.getComputerID()

-- Define all AI roles (one per worker node, 4 workers)
M.ROLES = {
    "neural",       -- Worker 1: neural networks + language representation
    "learning",     -- Worker 2: training + reinforcement learning
    "memory",       -- Worker 3: memory + knowledge + context
    "generation"    -- Worker 4: response generation + personality + mood
}

-- ============================================================================
-- MODULE REGISTRY - ALL 40+ MODULES ORGANIZED BY ROLE
-- ============================================================================

M.MODULE_MAP = {
    -- Worker 1: Neural networks + language representation
    neural = {
        "neural_net",
        "large_neural_net", 
        "neural_trainer",
        "tokenization",
        "embeddings",
        "word_vectors",
        "attention"
    },
    -- Worker 2: Training + reinforcement learning
    learning = {
        "machine_learning",
        "learning",
        "autonomous_learning",
        "auto_trainer",
        "advanced_ai_trainer",
        "exponential_trainer",
        "easy_trainer",
        "unified_trainer",
        "training_diagnostic",
        "rlhf",
        "ai_vs_ai"
    },
    -- Worker 3: Memory + knowledge + context
    memory = {
        "conversation_memory",
        "memory_search",
        "memory_loader",
        "knowledge_graph",
        "dictionary",
        "context",
        "user_data"
    },
    -- Worker 4: Response generation + personality + mood
    generation = {
        "response_generator",
        "responses",
        "markov",
        "context_markov",
        "sampling",
        "personality",
        "mood",
        "advanced",
        "code_generator"
    }
}

-- ============================================================================
-- STANDALONE AI MODULES (from main_logic.lua)
-- ============================================================================

-- Load core dependencies
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- Enhanced conversation modules
local convStrat, convMem, respGen
local success, module = pcall(require, "conversation_strategies")
if success then
    convStrat = module
    print("Conversation strategies loaded - enhanced dialogue enabled!")
end

success, module = pcall(require, "conversation_memory")
if success then
    convMem = module
    convMem.init()
    print("Conversation memory loaded - deep memory enabled!")
end

success, module = pcall(require, "response_generator")
if success then
    respGen = module
    print("Advanced response generator loaded!")
end

-- Advanced AI systems
local codeGen, dictionary, learning, neuralNet, machineLearning, largeNeural, trainedNetwork, markov
local attention, embeddings, memorySearch, rlhf, sampling, tokenization
local metaCognition, introspection, philReasoning, contextMarkov

-- Load all advanced modules with safe loading
local modules = {
    {name = "code_generator", var = "codeGen", desc = "code generation"},
    {name = "dictionary", var = "dictionary", desc = "dictionary"},
    {name = "learning", var = "learning", desc = "learning"},
    {name = "neural_net", var = "neuralNet", desc = "neural learning"},
    {name = "machine_learning", var = "machineLearning", desc = "ML features"},
    {name = "large_neural_net", var = "largeNeural", desc = "advanced neural features"},
    {name = "markov", var = "markov", desc = "natural language generation"},
    {name = "context_markov", var = "contextMarkov", desc = "context-aware responses"},
    {name = "attention", var = "attention", desc = "attention mechanism"},
    {name = "embeddings", var = "embeddings", desc = "word embeddings"},
    {name = "memory_search", var = "memorySearch", desc = "semantic memory search"},
    {name = "rlhf", var = "rlhf", desc = "feedback learning"},
    {name = "sampling", var = "sampling", desc = "advanced sampling"},
    {name = "tokenization", var = "tokenization", desc = "tokenization"},
    {name = "meta_cognition", var = "metaCognition", desc = "meta-cognitive features"},
    {name = "introspection", var = "introspection", desc = "introspection"},
    {name = "philosophical_reasoning", var = "philReasoning", desc = "philosophical reasoning"}
}

-- Load modules dynamically
local loadedModules = {}
for _, mod in ipairs(modules) do
    success, module = pcall(require, mod.name)
    if success then
        loadedModules[mod.var] = module
        print(mod.name .. " loaded - " .. mod.desc .. " enabled!")
        
        -- Special initialization for some modules
        if mod.name == "large_neural_net" then
            trainedNetwork = module.loadNetwork("/neural/")
            if trainedNetwork then
                print("Loaded trained network with " .. trainedNetwork.total_params .. " parameters!")
            end
        elseif mod.name == "markov" then
            if module.load("markov_data.dat") then
                local stats = module.getStats()
                print("Loaded Markov data: " .. stats.total_sequences .. " sequences")
            else
                module.initializeWithDefaults()
                module.save()
            end
        elseif mod.name == "context_markov" then
            if module.load("context_markov.dat") then
                local stats = module.getStats()
                print("Context-Aware Markov loaded: " .. stats.total_patterns .. " patterns!")
            end
        elseif mod.name == "embeddings" then
            if module.load("embeddings.dat") then
                print("Loaded embeddings: " .. module.vocab_size .. " words")
            else
                module.initializeDefaults()
                module.save()
            end
        elseif mod.name == "memory_search" then
            if loadedModules["embeddings"] and loadedModules["attention"] then
                module.initialize(loadedModules["embeddings"], loadedModules["attention"])
                module.load("memory_index.dat")
                local stats = module.getStats()
                print("Memory index: " .. stats.total_memories .. " memories")
            end
        elseif mod.name == "rlhf" then
            module.load("rlhf_data.dat")
            local stats = module.getStats()
            print("RLHF stats: " .. stats.total_feedback .. " feedback samples")
        elseif mod.name == "tokenization" then
            module.load("tokenization.dat")
        elseif mod.name == "meta_cognition" then
            module.init()
        elseif mod.name == "introspection" then
            module.init({
                name = "SuperAI",
                purpose = "helpful conversation and task assistance"
            })
        elseif mod.name == "philosophical_reasoning" then
            module.init()
        end
    else
        print("Warning: " .. mod.name .. ".lua not found - " .. mod.desc .. " disabled")
    end
end

-- Assign loaded modules to variables
codeGen = loadedModules["codeGen"]
dictionary = loadedModules["dictionary"]
learning = loadedModules["learning"]
neuralNet = loadedModules["neuralNet"] 
machineLearning = loadedModules["machineLearning"]
largeNeural = loadedModules["largeNeural"]
markov = loadedModules["markov"]
contextMarkov = loadedModules["contextMarkov"]
attention = loadedModules["attention"]
embeddings = loadedModules["embeddings"]
memorySearch = loadedModules["memorySearch"]
rlhf = loadedModules["rlhf"]
sampling = loadedModules["sampling"]
tokenization = loadedModules["tokenization"]
metaCognition = loadedModules["metaCognition"]
introspection = loadedModules["introspection"]
philReasoning = loadedModules["philReasoning"]

-- ============================================================================
-- MEMORY SYSTEM (from main_logic.lua)
-- ============================================================================

local DEFAULT_BOT_NAME = "SuperAI"
local BOT_NAME = "SuperAI"

-- In-memory storage
local memory = {
    facts = {},
    preferences = {},
    nicknames = {},
    topics = {},
    context = {},
    chatColor = colors.cyan,
    botName = DEFAULT_BOT_NAME,
    users = {}
}

-- Utility functions (from main_logic.lua)
local function safeCall(module, funcName, default, ...)
    if module and module[funcName] and type(module[funcName]) == "function" then
        local success, result = pcall(module[funcName], ...)
        if success then
            return result
        else
            print("Error in " .. funcName .. ": " .. tostring(result))
            return default
        end
    end
    return default
end

local function hasFunction(module, funcName)
    return module and module[funcName] and type(module[funcName]) == "function"
end

-- Memory management
local function loadMemory()
    if fs.exists("superai_memory.dat") then
        local file = fs.open("superai_memory.dat", "r")
        if file then
            local content = file.readAll()
            file.close()
            local loaded = textutils.unserialize(content)
            if loaded then
                memory = loaded
                if memory.botName then
                    BOT_NAME = memory.botName
                end
                print("Memory loaded from superai_memory.dat")
            end
        end
    end
end

local function saveMemory()
    local file = fs.open("superai_memory.dat", "w")
    if file then
        file.write(textutils.serialize(memory))
        file.close()
    end
end

-- Enhanced memory functions (from main_logic.lua)
local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user, nickname)
    memory.nicknames[user] = nickname
    saveMemory()
end

local function setBotName(newName)
    memory.botName = newName
    BOT_NAME = newName
    saveMemory()
end

local function rememberFact(user, fact)
    if not memory.facts[user] then
        memory.facts[user] = {}
    end
    
    -- Avoid duplicates
    for _, existing in ipairs(memory.facts[user]) do
        if existing.text == fact then
            existing.lastMentioned = os.clock()
            return
        end
    end
    
    table.insert(memory.facts[user], {
        text = fact,
        timestamp = os.clock(),
        lastMentioned = os.clock()
    })
    saveMemory()
end

local function rememberPreference(user, item, isLike)
    if not memory.preferences[user] then
        memory.preferences[user] = {}
    end
    
    memory.preferences[user][item] = {
        likes = isLike,
        timestamp = os.clock()
    }
    saveMemory()
end

local function recallFact(user)
    if not memory.facts[user] or #memory.facts[user] == 0 then
        return nil
    end
    
    local fact = memory.facts[user][math.random(#memory.facts[user])]
    fact.lastMentioned = os.clock()
    return fact.text
end

local function trackTopic(topic)
    if not memory.topics[topic] then
        memory.topics[topic] = {count = 0, lastDiscussed = 0}
    end
    memory.topics[topic].count = memory.topics[topic].count + 1
    memory.topics[topic].lastDiscussed = os.clock()
    saveMemory()
end

local function discussedRecently(topic)
    if memory.topics[topic] then
        return (os.clock() - memory.topics[topic].lastDiscussed) < 300 -- 5 minutes
    end
    return false
end

-- ============================================================================
-- CLUSTER INITIALIZATION
-- ============================================================================

function M.init()
    print("=== SuperAI Unified Master Brain ===")
    print("Initializing cluster network...")

    -- Open all modems
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
            print("Opened modem: " .. name)
        end
    end

    -- Discover worker computers (exclude master itself)
    local computers = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "computer" then
            local id = peripheral.call(name, "getID")
            if id ~= M.masterID then
                table.insert(computers, {name = name, id = id})
            end
        end
    end

    print("Found " .. #computers .. " worker computers")

    -- Turn on ALL workers first, then wait for them to boot
    print("\nStarting all worker computers...")
    for i, comp in ipairs(computers) do
        peripheral.call(comp.name, "turnOn")
        print("  Turned on worker " .. comp.id)
    end

    -- Wait for workers to boot and start their startup scripts
    print("Waiting for workers to boot (15 seconds)...")
    sleep(15)

    -- Assign roles to workers with retry logic
    print("\nAssigning AI roles to workers...")
    for i, comp in ipairs(computers) do
        local role = M.ROLES[i]
        if role then
            print("  " .. role:upper() .. " -> worker " .. comp.id .. "...")

            -- Retry role assignment up to 6 times (30 second total window)
            local assigned = false
            for attempt = 1, 6 do
                -- Send role assignment
                rednet.send(comp.id, {
                    type = "assign_role",
                    role = role,
                    modules = M.MODULE_MAP[role]
                }, M.PROTOCOL)

                -- Wait for acknowledgment (5 seconds per attempt)
                local deadline = os.clock() + 5
                while os.clock() < deadline do
                    local senderID, message = rednet.receive(M.PROTOCOL, 0.5)
                    if senderID == comp.id and message and message.type == "role_ack" then
                        M.workers[role] = {
                            id = comp.id,
                            name = comp.name,
                            ready = message.ok,
                            modules = message.loaded_modules or {}
                        }
                        print("  " .. role:upper() .. ": " .. (message.ok and "READY" or "ERROR") ..
                              " (" .. #(message.loaded_modules or {}) .. " modules)")
                        assigned = true
                        break
                    end
                end

                if assigned then break end
                if attempt < 6 then
                    print("    Attempt " .. attempt .. " timed out, retrying...")
                end
            end

            if not assigned then
                M.workers[role] = {id = comp.id, name = comp.name, ready = false}
                print("  " .. role:upper() .. ": FAILED (worker " .. comp.id ..
                      " not responding - run cluster_worker_setup.lua on that computer)")
            end
        end
    end

    -- Count ready workers
    local ready_count = 0
    for _, worker in pairs(M.workers) do
        if worker.ready then
            ready_count = ready_count + 1
        end
    end

    print("\nCluster Status: " .. ready_count .. "/" .. #computers .. " workers ready")
    print("Total AI modules distributed across cluster\n")

    return ready_count > 0
end

-- ============================================================================
-- TASK DISTRIBUTION
-- ============================================================================

M.taskID = 0

function M.dispatch(role, task, data, timeout)
    local worker = M.workers[role]
    if not worker or not worker.ready then
        return {error = "Worker not ready: " .. role}
    end

    M.taskID = M.taskID + 1
    local currentTaskID = M.taskID

    -- Send task to worker
    rednet.send(worker.id, {
        type = "task",
        task = task,
        taskId = currentTaskID,
        data = data or {}
    }, M.PROTOCOL)

    -- Wait for result
    local deadline = os.clock() + (timeout or 3)
    while os.clock() < deadline do
        local senderID, message = rednet.receive(M.PROTOCOL, 0.3)
        if message and message.type == "result" and message.taskId == currentTaskID then
            return message.result
        end
    end

    return {error = "Task timeout"}
end

-- ============================================================================
-- ENHANCED INTENT DETECTION (from main_logic.lua)
-- ============================================================================

local function detectIntent(message)
    local lower = message:lower()
    
    -- Greetings
    if lower:match("^h[ie]") or lower:match("^hey") or lower:match("^hello") or 
       lower:match("good morning") or lower:match("good afternoon") or lower:match("good evening") then
        return "greeting"
    end
    
    -- Farewells
    if lower:match("bye") or lower:match("goodbye") or lower:match("see you") or
       lower:match("farewell") or lower:match("later") or lower:match("goodnight") then
        return "farewell"
    end
    
    -- Questions about the AI
    if lower:match("how are") or lower:match("what's up") or lower:match("how do you feel") then
        return "how_are_you"
    end
    
    -- Gratitude
    if lower:match("thank") or lower:match("thanks") or lower:match("appreciate") then
        return "thanks"
    end
    
    -- AI identity questions
    if lower:match("who are") or lower:match("what are you") or lower:match("tell me about yourself") then
        return "about_ai"
    end
    
    -- Jokes and humor
    if lower:match("joke") or lower:match("funny") or lower:match("humor") or lower:match("laugh") then
        return "joke"
    end
    
    -- Code requests
    if lower:match("code") or lower:match("program") or lower:match("function") or 
       lower:match("script") or lower:match("algorithm") then
        return "code_request"
    end
    
    -- Math expressions
    if lower:match("calculate") or lower:match("what is %d") or lower:match("%d+%s*[%+%-%*/%^]") then
        return "math"
    end
    
    -- Memory commands
    if lower:match("remember that") or lower:match("save this") or lower:match("store") then
        return "remember"
    end
    
    if lower:match("what do you know") or lower:match("tell me what") or lower:match("recall") then
        return "recall"
    end
    
    -- Learning commands
    if lower:match("learn this") or lower:match("train") or lower:match("study") then
        return "learn"
    end
    
    -- General questions (ending with ?)
    if lower:match("%?$") then
        return "question"
    end
    
    -- Commands or requests
    if lower:match("^can you") or lower:match("^could you") or lower:match("^please") or 
       lower:match("^help me") or lower:match("^show me") then
        return "request"
    end
    
    return "statement"
end

-- ============================================================================
-- MATH EVALUATION (from main_logic.lua)
-- ============================================================================

local function evaluateMath(message)
    local cleanMsg = message:gsub("[^%d%.%+%-%*/%^%(%)%s]", "")
    cleanMsg = cleanMsg:gsub("%s+", "")
    
    if cleanMsg == "" then return nil end
    
    -- Replace ^ with math.pow for proper exponentiation
    cleanMsg = cleanMsg:gsub("(%d+)%^(%d+)", function(base, exp)
        return "math.pow(" .. base .. "," .. exp .. ")"
    end)
    
    local success, result = pcall(function()
        return load("return " .. cleanMsg)()
    end)
    
    if success and type(result) == "number" then
        if result == math.floor(result) then
            return tostring(math.floor(result))
        else
            return string.format("%.6g", result)
        end
    end
    
    return nil
end

-- ============================================================================
-- NEURAL NETWORK INTEGRATION (from main_logic.lua)
-- ============================================================================

local function useNeuralNetwork(message)
    if trainedNetwork then
        return safeCall(largeNeural, "predict", nil, trainedNetwork, message)
    elseif neuralNet then
        return safeCall(neuralNet, "predict", nil, message)
    end
    return nil
end

-- ============================================================================
-- CONTEXT MANAGEMENT (from main_logic.lua)
-- ============================================================================

local function updateContext(user, message, category, response)
    if not memory.context[user] then
        memory.context[user] = {}
    end
    
    table.insert(memory.context[user], {
        message = message,
        response = response,
        category = category,
        timestamp = os.clock(),
        sentiment = personality and personality.getLastSentiment() or 0
    })
    
    -- Keep only last 10 interactions
    if #memory.context[user] > 10 then
        table.remove(memory.context[user], 1)
    end
    
    saveMemory()
end

local function getContextualHistory(user, lookback)
    lookback = lookback or 3
    local history = {}
    
    if memory.context[user] then
        local start = math.max(1, #memory.context[user] - lookback + 1)
        for i = start, #memory.context[user] do
            table.insert(history, memory.context[user][i])
        end
    end
    
    return history
end

-- ============================================================================
-- ENHANCED PROCESSING FUNCTIONS
-- ============================================================================

function M.processInput(input, userName)
    local results = {}

    -- Try cluster processing first if workers available
    if M.workers.neural and M.workers.neural.ready then
        local languageResult = M.dispatch("neural", "analyze", {text = input})
        results.language = languageResult
    end

    -- Use local neural processing as fallback
    if not results.language and (neuralNet or largeNeural) then
        local neuralResult = useNeuralNetwork(input)
        if neuralResult then
            results.language = {neural_prediction = neuralResult}
        end
    end

    -- Get user context from memory worker or local memory
    local userContext
    if M.workers.memory and M.workers.memory.ready then
        userContext = M.dispatch("memory", "getUser", {name = userName})
    else
        userContext = {history = getContextualHistory(userName)}
    end
    results.userContext = userContext

    -- Determine intent and sentiment
    local sentiment = (results.language and results.language.sentiment) or 0
    if sentiment == 0 and personality then
        sentiment = personality.analyzeSentiment(input) or 0
    end
    
    local intent = detectIntent(input)
    results.intent = intent
    results.sentiment = sentiment

    -- Context processing
    local contextData
    if M.workers.memory and M.workers.memory.ready then
        contextData = M.dispatch("memory", "process", {
            input = input,
            intent = intent,
            user = userName,
            history = (userContext and userContext.history) or {}
        })
    else
        contextData = {
            recent_topics = {},
            sentiment_trend = sentiment,
            context_relevance = 0.5
        }
    end
    results.context = contextData

    return results
end

function M.generateResponse(input, userName, processingResults)
    local intent = processingResults.intent or "statement"
    local sentiment = processingResults.sentiment or 0
    local context = processingResults.context or {}

    local response = nil

    -- Handle special intents locally first
    if intent == "math" then
        local mathResult = evaluateMath(input)
        if mathResult then
            response = "The answer is: " .. mathResult
        end
    elseif intent == "remember" then
        local fact = input:gsub("remember that", ""):gsub("save this", ""):gsub("store", ""):trim()
        if fact and fact ~= "" then
            rememberFact(userName, fact)
            response = "I'll remember that: " .. fact
        end
    elseif intent == "recall" then
        local fact = recallFact(userName)
        if fact then
            response = "I remember: " .. fact
        else
            response = "I don't have any facts stored for you yet."
        end
    elseif intent == "code_request" and codeGen then
        local code = safeCall(codeGen, "generate", "-- Unable to generate code", input, context)
        if code then
            response = "Here's the code:\n\n" .. code
        end
    end

    -- If no local response, try cluster workers
    if not response then
        if intent == "greeting" then
            if M.workers.generation and M.workers.generation.ready then
                local result = M.dispatch("generation", "generateGreeting", {context = context})
                response = result and result.response
            else
                response = "Hello " .. getName(userName) .. "! How can I help you today?"
            end
        elseif intent == "farewell" then
            if M.workers.generation and M.workers.generation.ready then
                local result = M.dispatch("generation", "generateFarewell", {})
                response = result and result.response
            else
                response = "Goodbye " .. getName(userName) .. "! Have a great day!"
            end
        elseif intent == "question" then
            -- Try knowledge/memory worker first
            if M.workers.memory and M.workers.memory.ready then
                local knowledgeResult = M.dispatch("memory", "query", {question = input})
                if knowledgeResult and knowledgeResult.answer then
                    response = knowledgeResult.answer
                end
            end
            
            -- Fallback to generation worker or local
            if not response then
                if M.workers.generation and M.workers.generation.ready then
                    local result = M.dispatch("generation", "generateContextual", {
                        intent = "question",
                        context = context,
                        input = input
                    })
                    response = result and result.response
                else
                    -- Local fallback using available modules
                    if contextMarkov then
                        response = safeCall(contextMarkov, "generate", nil, input, context)
                    elseif markov then
                        response = safeCall(markov, "generate", nil, input)
                    end
                end
            end
        elseif intent == "joke" then
            if M.workers.generation and M.workers.generation.ready then
                local result = M.dispatch("generation", "generateJoke", {})
                response = result and result.response
            else
                response = "Why did the AI cross the road? To optimize its path finding algorithm!"
            end
        else
            -- Default contextual response
            if M.workers.generation and M.workers.generation.ready then
                local result = M.dispatch("generation", "generateContextual", {
                    intent = intent,
                    context = context,
                    input = input,
                    sentiment = sentiment
                })
                response = result and result.response
            else
                -- Local contextual generation
                if contextMarkov then
                    response = safeCall(contextMarkov, "generate", nil, input, context)
                elseif respGen then
                    response = safeCall(respGen, "generateContextual", nil, intent, context)
                elseif markov then
                    response = safeCall(markov, "generate", nil, input)
                end
            end
        end
    end

    -- Record interaction
    if M.workers.memory and M.workers.memory.ready then
        M.dispatch("memory", "record", {
            user = userName,
            input = input,
            response = response,
            sentiment = sentiment,
            intent = intent
        })
    else
        updateContext(userName, input, intent, response)
        if convMem then
            safeCall(convMem, "recordUserInteraction", nil, userName, input, sentiment, {
                intent = intent,
                response = response
            })
        end
    end

    -- Update personality
    if M.workers.generation and M.workers.generation.ready then
        M.dispatch("generation", "update_personality", {
            sentiment = sentiment,
            intent = intent
        })
    else
        if personality then
            safeCall(personality, "updateMood", nil, sentiment)
        end
        if mood then
            safeCall(mood, "update", nil, sentiment, intent)
        end
    end

    return response or "I'm thinking..."
end

-- ============================================================================
-- LEARNING INTEGRATION
-- ============================================================================

function M.learn(input, feedback)
    -- Distribute learning across relevant workers
    if M.workers.neural and M.workers.neural.ready then
        M.dispatch("neural", "train", {
            input = input,
            feedback = feedback
        })
    end

    if M.workers.learning and M.workers.learning.ready then
        M.dispatch("learning", "update", {
            data = input,
            feedback = feedback
        })
        M.dispatch("learning", "rlhf_feedback", {
            input = input,
            feedback = feedback
        })
    end

    -- Local learning fallbacks
    if neuralNet then
        safeCall(neuralNet, "train", nil, input, feedback)
    end
    
    if machineLearning then
        safeCall(machineLearning, "train", nil, input, feedback)
    end
    
    if rlhf then
        safeCall(rlhf, "addFeedback", nil, input, feedback)
    end

    return true
end

-- ============================================================================
-- AUTO TRAINING (from main_logic.lua)
-- ============================================================================

function M.runAutoTraining(num_conversations)
    print("Starting auto-training with " .. (num_conversations or 10) .. " conversations...")
    
    if neuralNet then
        safeCall(neuralNet, "autoTrain", nil, num_conversations or 10)
    end
    
    if machineLearning then
        safeCall(machineLearning, "autoTrain", nil, num_conversations or 10)
    end
    
    print("Auto-training complete!")
end

-- ============================================================================
-- STATUS AND HEALTH MONITORING
-- ============================================================================

function M.getStatus()
    local status = {
        master = M.masterID,
        workers = {},
        total_modules = 0,
        local_modules = {},
        memory_stats = {},
        system_health = {}
    }

    -- Cluster worker status
    for role, worker in pairs(M.workers) do
        status.workers[role] = {
            id = worker.id,
            ready = worker.ready,
            modules = #(worker.modules or {})
        }
        status.total_modules = status.total_modules + #(worker.modules or {})
    end
    
    -- Local module status
    local localModuleCount = 0
    for name, module in pairs(loadedModules) do
        if module then
            status.local_modules[name] = "loaded"
            localModuleCount = localModuleCount + 1
        end
    end
    status.local_modules.count = localModuleCount
    
    -- Memory statistics
    status.memory_stats = {
        users = 0,
        facts = 0,
        preferences = 0,
        context_entries = 0
    }
    
    for user, facts in pairs(memory.facts) do
        status.memory_stats.users = status.memory_stats.users + 1
        status.memory_stats.facts = status.memory_stats.facts + #facts
    end
    
    for user, prefs in pairs(memory.preferences) do
        for _, _ in pairs(prefs) do
            status.memory_stats.preferences = status.memory_stats.preferences + 1
        end
    end
    
    for user, contexts in pairs(memory.context) do
        status.memory_stats.context_entries = status.memory_stats.context_entries + #contexts
    end

    return status
end

-- ============================================================================
-- CONFIGURATION PERSISTENCE
-- ============================================================================

local CONFIG_FILE = "superai_config.dat"

local function loadConfig()
    if fs.exists(CONFIG_FILE) then
        local f = fs.open(CONFIG_FILE, "r")
        if f then
            local content = f.readAll()
            f.close()
            return textutils.unserialize(content) or {}
        end
    end
    return {}
end

local function saveConfig(config)
    local f = fs.open(CONFIG_FILE, "w")
    if f then
        f.write(textutils.serialize(config))
        f.close()
    end
end

-- ============================================================================
-- FIRST RUN SETUP
-- ============================================================================

local function firstRunSetup(config)
    print("")
    print("=== First Time Setup ===")
    print("")

    -- Ask for user's name
    write("Before we start, what should I call you? ")
    local nickname = read()
    if nickname and nickname ~= "" then
        config.userName = nickname
        memory.nicknames["Player"] = nickname
        print("")
        print("Nice to meet you, " .. nickname .. "!")
    else
        config.userName = "User"
    end

    -- Ask what to call the AI
    print("")
    write("What would you like to call me? (default: SuperAI) ")
    local botName = read()
    if botName and botName ~= "" then
        config.botName = botName
        setBotName(botName)
        print("")
        print("Cool! You can call me " .. botName .. " then!")
    else
        config.botName = "SuperAI"
        setBotName("SuperAI")
    end

    -- Chat color picker
    print("")
    print("Pick your chat color:")
    local chatColors = {
        {name = "white",     code = colors.white},
        {name = "orange",    code = colors.orange},
        {name = "magenta",   code = colors.magenta},
        {name = "lightBlue", code = colors.lightBlue},
        {name = "yellow",    code = colors.yellow},
        {name = "lime",      code = colors.lime},
        {name = "pink",      code = colors.pink},
        {name = "cyan",      code = colors.cyan},
        {name = "purple",    code = colors.purple},
        {name = "blue",      code = colors.blue},
        {name = "green",     code = colors.green},
        {name = "red",       code = colors.red},
        {name = "lightGray", code = colors.lightGray},
        {name = "gray",      code = colors.gray},
    }

    for i = 1, #chatColors, 2 do
        local left = i .. ") " .. chatColors[i].name
        local right = ""
        if chatColors[i + 1] then
            right = (i + 1) .. ") " .. chatColors[i + 1].name
        end
        left = left .. string.rep(" ", 20 - #left)
        print(left .. right)
    end

    write("Number (or Enter for cyan): ")
    local choice = tonumber(read())
    if choice and chatColors[choice] then
        config.chatColor = chatColors[choice].code
        config.chatColorName = chatColors[choice].name
        memory.chatColor = chatColors[choice].code
        print("")
        print("Great choice! Chat will appear in " .. chatColors[choice].name .. ".")
    else
        config.chatColor = colors.cyan
        config.chatColorName = "cyan"
        memory.chatColor = colors.cyan
    end

    config.setupDone = true
    saveConfig(config)
    saveMemory()

    print("")
    print("Setup complete! Let's get started.")
    print("")
end

-- ============================================================================
-- SHUTDOWN
-- ============================================================================

function M.shutdown()
    print("\nShutting down cluster...")
    for role, worker in pairs(M.workers) do
        rednet.send(worker.id, {type = "shutdown"}, M.PROTOCOL)
    end
    
    -- Save all data
    saveMemory()
    
    -- Save module data
    if markov then
        safeCall(markov, "save", nil)
    end
    
    if contextMarkov then
        safeCall(contextMarkov, "save", nil)
    end
    
    if embeddings then
        safeCall(embeddings, "save", nil)
    end
    
    if rlhf then
        safeCall(rlhf, "save", nil)
    end
    
    if memorySearch then
        safeCall(memorySearch, "save", nil)
    end
    
    print("All data saved. Cluster shutdown complete.")
end

-- ============================================================================
-- INTERACTIVE MODE
-- ============================================================================

function M.run()
    -- Load memory
    loadMemory()
    
    -- Try to initialize cluster (gracefully handle failure)
    local clusterReady = M.init()
    
    if not clusterReady then
        print("Warning: Cluster initialization failed - running in standalone mode")
        print("=== SuperAI Standalone Mode ===")
    end

    -- Load saved config
    local config = loadConfig()

    -- First run setup if not done yet
    if not config.setupDone then
        firstRunSetup(config)
    end

    local userName = config.userName or "User"
    local botName = config.botName or BOT_NAME
    local chatColor = config.chatColor or colors.cyan

    print("=== " .. botName .. " is ready! ===")
    if clusterReady then
        print("Cluster mode: " .. M.getStatus().total_modules .. " distributed modules")
    end
    print("Standalone modules: " .. (M.getStatus().local_modules.count or 0) .. " loaded")
    print("Type 'quit' to exit, 'status' for system status")
    print("Type 'setup' to redo personalization settings")
    print("Type 'train' for auto-training, 'learn <feedback>' to provide feedback")
    print("")

    local messageCount = 0

    while true do
        if term and term.setTextColor then
            term.setTextColor(colors.white)
        end
        write(userName .. "> ")
        local input = read()

        if not input or input == "" then
            -- Skip empty input
        elseif input == "quit" or input == "exit" then
            M.shutdown()
            break
        elseif input == "status" then
            local status = M.getStatus()
            print("\nSystem Status:")
            print("Master ID: " .. status.master)
            if status.total_modules > 0 then
                print("Cluster Modules: " .. status.total_modules)
                for role, info in pairs(status.workers) do
                    print("  " .. role .. ": " .. (info.ready and "READY" or "DOWN") ..
                          " (" .. info.modules .. " modules)")
                end
            end
            print("Local Modules: " .. status.local_modules.count)
            print("Memory: " .. status.memory_stats.users .. " users, " .. 
                  status.memory_stats.facts .. " facts, " .. 
                  status.memory_stats.context_entries .. " context entries")
            print("")
        elseif input == "setup" then
            -- Allow re-running setup
            config.setupDone = false
            firstRunSetup(config)
            userName = config.userName or "User"
            botName = config.botName or BOT_NAME
            chatColor = config.chatColor or colors.cyan
        elseif input == "train" then
            M.runAutoTraining(10)
        elseif input:match("^learn ") then
            local feedback = input:sub(7)
            if messageCount > 0 then
                M.learn("last_message", feedback)
                print("Thank you for the feedback!")
            else
                print("Send me a message first, then provide feedback.")
            end
        elseif input:match("^name ") then
            userName = input:sub(6)
            config.userName = userName
            saveConfig(config)
            setNickname("Player", userName)
            print("Hello " .. userName .. "!")
        else
            -- Process input through enhanced system
            local processingResults = M.processInput(input, userName)
            local response = M.generateResponse(input, userName, processingResults)

            messageCount = messageCount + 1

            if term and term.setTextColor then
                term.setTextColor(chatColor)
            end
            print("\n" .. botName .. ": " .. response)
            if term and term.setTextColor then
                term.setTextColor(colors.lightGray)
            end
            if processingResults.intent then
                print("[" .. processingResults.intent .. " | sentiment: " ..
                      string.format("%.2f", processingResults.sentiment or 0) .. "]")
            end
            print("")
        end
    end
end

return M