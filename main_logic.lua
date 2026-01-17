-- Module: main_logic.lua
-- Natural conversational AI with personality and useful features

local M = {}

-- Load dependencies
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- NEW: Advanced systems (with safe loading)
local codeGen, dictionary, learning

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

-- Database is now in memory module (memory_RAID_partA.lua)
-- Graph algorithms are now in utils.math

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DEFAULT_BOT_NAME = "SuperAI"
local BOT_NAME = DEFAULT_BOT_NAME
local isTurtle = (type(turtle) == "table")

-- Context window for conversation memory (like LSTM/Transformers)
local CONTEXT_WINDOW = 15
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

local DISK_PATH = "/disk/superai_memory"
local MEM_FILE = DISK_PATH .. "/memory.dat"

local function loadMemory()
    if not fs.exists(MEM_FILE) then return end
    
    local file = fs.open(MEM_FILE, "r")
    local content = file.readAll()
    file.close()
    
    if content and content ~= "" then
        local loaded = textutils.unserialize(content)
        if loaded then
            -- Deep merge loaded memory into the table
            for k, v in pairs(loaded) do
                memory[k] = v
            end
            
            -- Sync the global name
            if memory.botName then
                BOT_NAME = memory.botName
            end
        end
    end
end

local function saveMemory()
    if not fs.exists("/disk") then return end
    if not fs.exists(DISK_PATH) then fs.makeDir(DISK_PATH) end
    
    local file = fs.open(MEM_FILE, "w")
    file.write(textutils.serialize(memory))
    file.close()
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
-- IMPROVED MATH EVALUATION (UPDATED WITH COMPLEX MATH SUPPORT)
-- ============================================================================

local function evaluateMath(message)
    local expr = message:lower()
    
    -- Handle written operators
    expr = expr:gsub("plus", "+")
    expr = expr:gsub("minus", "-")
    expr = expr:gsub("times", "*")
    expr = expr:gsub("multiplied by", "*")
    expr = expr:gsub("divided by", "/")
    expr = expr:gsub("to the power of", "^")
    expr = expr:gsub("squared", "^2")
    
    -- COMPLEX MATH: Handle percentage calculations (e.g., "50% of 200")
    expr = expr:gsub("([%d%.]+)%% of ([%d%.]+)", "(%1/100)*%2")
    expr = expr:gsub("([%d%.]+)%%", "(%1/100)")

    local functions = {"sqrt", "sin", "cos", "tan", "abs", "log", "exp", "floor", "ceil"}
    for _, f in ipairs(functions) do
        -- Wrap functions for Lua math library compatibility
        if f == "sin" or f == "cos" or f == "tan" then
            expr = expr:gsub(f .. " ?%(([^%)]+)%)", "math." .. f .. "(math.rad(%1))")
            expr = expr:gsub(f .. " +([%d%.]+)", "math." .. f .. "(math.rad(%1))")
        else
            expr = expr:gsub(f .. " ?%(([^%)]+)%)", "math." .. f .. "(%1)")
            expr = expr:gsub(f .. " +([%d%.]+)", "math." .. f .. "(%1)")
        end
    end

    local cleanExpr = ""
    -- FIX: Expanded character whitelist to allow 'q', 'r', and 'l' for sqrt and log
    -- Whitelist: numbers, basic ops, math keywords, and letters for functions
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
]]
    end
    
    safeCall(mood, "update", nil, user, message)
    local userMood = safeCall(mood, "get", "neutral", user) or "neutral"
    
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
            
            -- Factorial
            local n = lower:match("factorial%s+of%s+(%d+)") or lower:match("factorial%((%d+)%)")
            if n then
                n = tonumber(n)
                local result = utils.math.factorial(n)
                return "Factorial of " .. n .. " = " .. result
            end
            
            -- Fibonacci
            n = lower:match("fibonacci%s+of%s+(%d+)") or lower:match("fibonacci%((%d+)%)") or lower:match("fib%((%d+)%)")
            if n then
                n = tonumber(n)
                local result = utils.math.fibonacci(n)
                return "Fibonacci(" .. n .. ") = " .. result
            end
            
            -- GCD
            local a, b = lower:match("gcd%s+of%s+(%d+)%s+and%s+(%d+)")
            if not a then
                a, b = lower:match("gcd%((%d+),%s*(%d+)%)")
            end
            if a and b then
                a, b = tonumber(a), tonumber(b)
                local result = utils.math.gcd(a, b)
                return "GCD of " .. a .. " and " .. b .. " = " .. result
            end
            
            -- LCM
            a, b = lower:match("lcm%s+of%s+(%d+)%s+and%s+(%d+)")
            if not a then
                a, b = lower:match("lcm%((%d+),%s*(%d+)%)")
            end
            if a and b then
                a, b = tonumber(a), tonumber(b)
                local result = utils.math.lcm(a, b)
                return "LCM of " .. a .. " and " .. b .. " = " .. result
            end
            
            -- Prime check
            n = lower:match("is%s+(%d+)%s+prime")
            if not n then
                n = lower:match("prime%?%s*%((%d+)%)")
            end
            if n then
                n = tonumber(n)
                local isPrime = utils.math.isPrime(n)
                return n .. (isPrime and " is prime!" or " is not prime.")
            end
            
            -- Prime factors
            n = lower:match("prime%s+factors?%s+of%s+(%d+)")
            if not n then
                n = lower:match("factor%((%d+)%)")
            end
            if n then
                n = tonumber(n)
                local factors = utils.math.primeFactors(n)
                return "Prime factors of " .. n .. ": " .. table.concat(factors, ", ")
            end
            
            -- Power
            a, b = lower:match("(%d+)%s*%^%s*(%d+)")
            if not a then
                a, b = lower:match("(%d+)%s+to%s+the%s+power%s+of%s+(%d+)")
            end
            if a and b then
                a, b = tonumber(a), tonumber(b)
                local result = utils.math.power(a, b)
                return a .. "^" .. b .. " = " .. result
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
        response = handleGreeting(user, message)
        
    elseif intent == "gratitude" then
        response = handleGratitude(user, message)
        safeCall(personality, "evolve", nil, "positive", {messageType = "general"})
        safeCall(personality, "recordJokeReaction", nil, true)
        
    elseif intent == "question" then
        response = handleQuestion(user, message, userMood)
        safeCall(personality, "resetQuestionCount", nil)
        
    else
        response = handleStatement(user, message, userMood)
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
    
    updateContext(user, message, category, response)
    
    if memory.conversationCount % 5 == 0 then
        saveMemory()
    end
    
    return response
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
