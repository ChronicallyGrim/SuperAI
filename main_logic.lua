-- Module: main_logic.lua
-- Natural conversational AI with personality and useful features

local M = {}

-- Load dependencies
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local BOT_NAME = "SuperAI"  -- Default, can be changed by user
local isTurtle = (type(turtle) == "table")

-- Context window for conversation memory (like LSTM/Transformers)
local CONTEXT_WINDOW = 15
local INTENT_CONFIDENCE_THRESHOLD = 0.6

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
    facts = {},           -- Remember facts user tells us
    preferences = {},     -- User preferences and likes/dislikes
    lastTopics = {},      -- Recent conversation topics
    conversationCount = 0,
    startTime = os.time(),
    botName = "SuperAI"   -- Customizable bot name
}

-- Default categories
local defaultCategories = {
    greeting = {"hi", "hello", "hey", "greetings", "sup", "yo"},
    math = {"calculate", "what is", "%d+%s*[%+%-%*/%%%^]%s*%d+"},
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
    if not diskDrive or not fs.exists("/disk") or not fs.exists(MEM_FILE) then return end
    
    local file = fs.open(MEM_FILE, "r")
    local content = file.readAll()
    file.close()
    
    if content and content ~= "" then
        local loaded = textutils.unserialize(content)
        if loaded then
            memory.learned = loaded.learned or {}
            memory.nicknames = loaded.nicknames or {}
            memory.context = loaded.context or {}
            memory.chatColor = loaded.chatColor or colors.white
            memory.categories = loaded.categories or {}
            memory.negative = loaded.negative or {}
            memory.facts = loaded.facts or {}
            memory.preferences = loaded.preferences or {}
            memory.lastTopics = loaded.lastTopics or {}
            memory.conversationCount = loaded.conversationCount or 0
            memory.startTime = loaded.startTime or os.time()
            memory.botName = loaded.botName or "SuperAI"
            
            -- Update global BOT_NAME
            if memory.botName then
                BOT_NAME = memory.botName
            end
        end
    end
end

local function saveMemory()
    if not diskDrive or not fs.exists("/disk") then return end
    if not fs.exists(DISK_PATH) then fs.makeDir(DISK_PATH) end
    
    local file = fs.open(MEM_FILE, "w")
    file.write(textutils.serialize({
        learned = memory.learned,
        nicknames = memory.nicknames,
        context = memory.context,
        chatColor = memory.chatColor,
        categories = memory.categories,
        negative = memory.negative,
        facts = memory.facts,
        preferences = memory.preferences,
        lastTopics = memory.lastTopics,
        conversationCount = memory.conversationCount,
        startTime = memory.startTime,
        botName = memory.botName
    }))
    file.close()
end

-- ============================================================================
-- SYSTEM DIAGNOSTICS
-- ============================================================================

local function getSystemHealth()
    if not diskDrive then
        return "No disk drive detected. Can't check system health."
    end
    
    local report = {}
    table.insert(report, "=== System Health Report ===")
    table.insert(report, "")
    
    -- Check each drive
    local drives = {
        {name = "Left", side = "left"},
        {name = "Right", side = "right"},
        {name = "Back", side = "back"},
        {name = "Bottom", side = "bottom"},
        {name = "Top", side = "top"}
    }
    
    for _, drive in ipairs(drives) do
        if peripheral.isPresent(drive.side) and peripheral.getType(drive.side) == "drive" then
            local drv = peripheral.wrap(drive.side)
            local mountPath = drv.getMountPath and drv.getMountPath()
            
            if mountPath then
                local path = "/" .. mountPath
                local capacity = fs.getCapacity(path)
                local free = fs.getFreeSpace(path)
                local used = capacity - free
                
                local usedPercent = math.floor((used / capacity) * 100)
                local freePercent = 100 - usedPercent
                
                -- Estimate fragmentation (simplified)
                local files = fs.list(path)
                local fragmentation = #files > 10 and math.min(#files * 2, 80) or 10
                
                table.insert(report, drive.name .. " Drive (" .. mountPath .. "):")
                table.insert(report, "  Capacity: " .. math.floor(capacity / 1024) .. " KB")
                table.insert(report, "  Used: " .. math.floor(used / 1024) .. " KB (" .. usedPercent .. "%)")
                table.insert(report, "  Free: " .. math.floor(free / 1024) .. " KB (" .. freePercent .. "%)")
                table.insert(report, "  Files: " .. #files)
                table.insert(report, "  Fragmentation: ~" .. fragmentation .. "%")
                table.insert(report, "")
            end
        else
            table.insert(report, drive.name .. " Drive: Not detected")
            table.insert(report, "")
        end
    end
    
    -- Memory stats
    table.insert(report, "Conversation Stats:")
    table.insert(report, "  Total messages: " .. memory.conversationCount)
    table.insert(report, "  Facts stored: " .. (#memory.facts[memory.nicknames["Player"] or "Player"] or 0))
    table.insert(report, "  Context window: " .. #memory.context .. "/" .. CONTEXT_WINDOW)
    
    local uptime = os.time() - memory.startTime
    table.insert(report, "  Uptime: " .. math.floor(uptime / 60) .. " hours")
    
    return table.concat(report, "\n")
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

-- Remember facts about the user
local function rememberFact(user, fact)
    if not memory.facts[user] then
        memory.facts[user] = {}
    end
    table.insert(memory.facts[user], {
        fact = fact,
        timestamp = os.time()
    })
    -- Keep last 20 facts
    while #memory.facts[user] > 20 do
        table.remove(memory.facts[user], 1)
    end
    saveMemory()
end

-- Remember user preferences (likes/dislikes)
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

-- Get a random fact about the user
local function recallFact(user)
    if not memory.facts[user] or #memory.facts[user] == 0 then
        return nil
    end
    local fact = memory.facts[user][math.random(#memory.facts[user])]
    return fact.fact
end

-- Track conversation topics
local function trackTopic(topic)
    table.insert(memory.lastTopics, {
        topic = topic,
        timestamp = os.time()
    })
    -- Keep last 10 topics
    while #memory.lastTopics > 10 do
        table.remove(memory.lastTopics, 1)
    end
end

-- Check if we discussed this recently
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
        embedding = utils.extractKeywords(message)  -- Simplified "embedding"
    })
    
    -- LSTM-like: Keep sliding window of context
    if #memory.context > CONTEXT_WINDOW then
        table.remove(memory.context, 1)
    end
end

-- Sequence-to-Sequence concept: Map input sequence to output
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

-- Transformer-like: Attention mechanism - find relevant past context
local function findRelevantContext(currentMessage, user)
    local currentKeywords = utils.extractKeywords(currentMessage)
    local relevantContexts = {}
    
    for i = #memory.context, math.max(1, #memory.context - 10), -1 do
        if memory.context[i].user == user then
            local contextKeywords = memory.context[i].embedding or {}
            local relevanceScore = 0
            
            -- Calculate relevance (attention score)
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
    
    -- Sort by relevance score
    table.sort(relevantContexts, function(a, b) return a.score > b.score end)
    
    return relevantContexts
end

-- ============================================================================
-- MATH EVALUATION
-- ============================================================================

local function evaluateMath(message)
    local expr = message:match("(%d+%s*[%+%-%*/%%%^]%s*%d+)")
    if expr then
        local func, err = load("return " .. expr)
        if func then
            local success, result = pcall(func)
            if success then
                return "The answer is " .. tostring(result)
            end
        end
    end
    
    -- Try "what is X plus/minus/times/divided by Y"
    local patterns = {
        {"(%d+)%s+plus%s+(%d+)", function(a,b) return a+b end},
        {"(%d+)%s+minus%s+(%d+)", function(a,b) return a-b end},
        {"(%d+)%s+times%s+(%d+)", function(a,b) return a*b end},
        {"(%d+)%s+divided%s+by%s+(%d+)", function(a,b) return a/b end},
    }
    
    for _, pattern in ipairs(patterns) do
        local a, b = message:lower():match(pattern[1])
        if a and b then
            local result = pattern[2](tonumber(a), tonumber(b))
            return "That's " .. tostring(result)
        end
    end
    
    return nil
end

-- ============================================================================
-- INTENT DETECTION (Naive Bayes inspired with confidence scores)
-- ============================================================================

local function detectIntent(message)
    local msg = message:lower()
    local intentScores = {}
    
    -- Score each intent (Naive Bayes concept)
    local intents = {
        math = {
            patterns = {"%d+%s*[%+%-%*/]", "plus", "minus", "times", "divided", "calculate", "solve"},
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
    
    -- Calculate scores for each intent
    for intentName, intentData in pairs(intents) do
        intentScores[intentName] = 0
        for _, pattern in ipairs(intentData.patterns) do
            if msg:find(pattern) then
                intentScores[intentName] = intentScores[intentName] + intentData.weight
            end
        end
    end
    
    -- Find highest scoring intent (with confidence)
    local bestIntent = "statement"
    local bestScore = 0
    
    for intentName, score in pairs(intentScores) do
        if score > bestScore then
            bestScore = score
            bestIntent = intentName
        end
    end
    
    -- Calculate confidence (normalized)
    local totalScore = 0
    for _, score in pairs(intentScores) do
        totalScore = totalScore + score
    end
    
    local confidence = totalScore > 0 and (bestScore / totalScore) or 0
    
    -- Extract entities for certain intents
    local entity = nil
    if bestIntent == "preference_like" then
        entity = msg:match("i like (.+)") or msg:match("i love (.+)") or msg:match("i enjoy (.+)")
    elseif bestIntent == "preference_dislike" then
        entity = msg:match("i hate (.+)") or msg:match("i don't like (.+)") or msg:match("i dislike (.+)")
    elseif bestIntent == "remember" then
        entity = msg:match("remember%s+(.+)") or msg:match("don't forget%s+(.+)")
    end
    
    -- Return best intent only if confidence is high enough
    if confidence >= INTENT_CONFIDENCE_THRESHOLD then
        return bestIntent, entity, confidence
    else
        return "statement", nil, confidence
    end
end

-- ============================================================================
-- RESPONSE GENERATION
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
    
    -- Personalize if we know their name
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
    local responses = {
        "You're welcome!",
        "Happy to help!",
        "No problem!",
        "Anytime!",
        "Glad I could help!",
    }
    
    return utils.choose(responses)
end

local function handleQuestion(user, message, userMood)
    -- System health check
    if message:lower():find("system health") or message:lower():find("system status") or
       message:lower():find("diagnostics") or message:lower():find("storage") then
        return getSystemHealth()
    end
    
    -- Check for specific answerable questions
    if message:lower():find("who are you") or message:lower():find("what are you") then
        return "I'm " .. BOT_NAME .. ", just a friendly AI here to chat! What's up?"
    end
    
    if message:lower():find("your name") or message:lower():find("what's your name") or
       message:lower():find("whats your name") then
        return "I'm " .. BOT_NAME .. "! What about you?"
    end
    
    if message:lower():find("how are you") or message:lower():find("how's it going") or 
       message:lower():find("how are things") then
        local responses = {
            "I'm doing great! How about you?",
            "Pretty good! What's going on with you?",
            "Can't complain! How are you?",
            "I'm good, thanks! What about you?",
            "Good good! What's new with you?",
        }
        return utils.choose(responses)
    end
    
    if message:lower():find("what can you do") or message:lower():find("what do you do") then
        return "I can chat with you, solve math problems, tell you the time, remember stuff you tell me... mostly I'm just here to talk! What would you like to do?"
    end
    
    if message:lower():find("what's up") or message:lower():find("sup") or 
       message:lower():find("what are you doing") then
        local responses = {
            "Not much, just hanging out! You?",
            "Just chatting with you! What's up with you?",
            "Nothing much! What about you?",
            "Just here, ready to chat! What's going on?",
        }
        return utils.choose(responses)
    end
    
    -- General question handling - be honest but casual
    local responses = {
        "Hmm, good question. What do you think?",
        "I'm not totally sure. What's your take?",
        "That's interesting. I'd have to think about it. What do you think?",
        "You know, I'm not certain. What's your opinion?",
        "I don't really know. Why do you ask?",
        "Not sure about that one. What made you think of it?",
    }
    
    return utils.choose(responses)
end

-- ============================================================================
-- RESPONSE GENERATION (Seq2Seq + Context-aware generation)
-- ============================================================================

local function handleStatement(user, message, userMood)
    local category = detectCategory(message)
    local keywords = utils.extractKeywords(message)
    
    -- Detect very short responses (user might be distracted/busy)
    if #message < 10 and #keywords == 0 then
        local shortResponseCount = 0
        local history = getContextualHistory(user, 3)
        
        for _, h in ipairs(history) do
            if #h.message < 10 then
                shortResponseCount = shortResponseCount + 1
            end
        end
        
        -- If user keeps giving short responses, check in
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
    
    -- Extract and remember facts mentioned
    if message:lower():find("my ") or message:lower():find("i have") or 
       message:lower():find("i work") or message:lower():find("i live") then
        rememberFact(user, message)
    end
    
    -- Track topics
    if keywords and #keywords > 0 then
        trackTopic(keywords[1])
    end
    
    -- Use attention mechanism to find relevant past context
    local relevantPast = findRelevantContext(message, user)
    
    -- If we have highly relevant past context, reference it
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
    
    -- For negative moods, be supportive but natural
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
        
        -- Use conversation history to provide better follow-up
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
    
    -- For positive moods, be enthusiastic
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
    
    -- Personal stuff - be interested but casual
    if category == "personal" then
        local responses = {
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
        return utils.choose(responses)
    end
    
    -- Sometimes reference something they told us before (Information Retrieval)
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
    
    -- General conversation - be natural (with context awareness)
    local responses = {
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
    
    local response = utils.choose(responses)
    
    -- Use RNN-like memory: Consider conversation flow
    local history = getContextualHistory(user, 3)
    local questionStreak = 0
    for _, h in ipairs(history) do
        if h.response and h.response:find("?") then
            questionStreak = questionStreak + 1
        end
    end
    
    -- Don't ask too many questions in a row (dialogue management)
    local shouldAskQuestion = personality.shouldAskQuestion() and questionStreak < 2 and math.random() < 0.3
    
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
-- MAIN INTERPRETATION (with NLP pipeline)
-- ============================================================================

local function interpret(message, user)
    memory.conversationCount = memory.conversationCount + 1
    
    -- STEP 1: Input Processing (NLP) - Understand words and extract intent
    mood.update(user, message)
    local userMood = mood.get(user)
    
    -- STEP 2: Intent Classification (Naive Bayes + SVM concepts)
    local intent, entity, confidence = detectIntent(message)
    local category = detectCategory(message)
    
    -- STEP 3: Context Management (LSTM/Transformer concept) - Recall previous turns
    local conversationHistory = getContextualHistory(user, 5)
    local relevantContext = findRelevantContext(message, user)
    
    local response
    
    -- STEP 4: Information Retrieval/Generation - Access memory or generate response
    if intent == "math" then
        response = evaluateMath(message)
        if not response then
            response = "I couldn't solve that. Try something like '5 + 3' or 'what is 10 times 4'."
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
        -- Information Retrieval from memory
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
            -- Show color picker
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
        personality.evolve("positive", {messageType = "general"})
        
    elseif intent == "question" then
        response = handleQuestion(user, message, userMood)
        
    else
        -- STEP 5: Response Generation (Seq2Seq) - Formulate natural answer
        response = handleStatement(user, message, userMood)
    end
    
    -- Apply mood adjustment (sentiment aware)
    response = mood.adjustResponse(user, response)
    
    -- Store in context (like RNN/LSTM memory)
    updateContext(user, message, category, response)
    
    -- Periodic save
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
    
    -- Ask for nickname
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
    
    -- Ask for chat color
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
    
    -- Clear screen
    if term and term.clear then term.clear() end
    if term and term.setCursorPos then term.setCursorPos(1, 1) end
    
    -- Welcome message
    print("==========================================")
    print("           Welcome to " .. BOT_NAME .. "!")
    print("==========================================")
    
    -- First run setup
    firstRunSetup()
    
    print("")
    print("Great! I'm ready to chat. Type anything!")
    print("(Type 'quit' or 'exit' to stop)")
    print("")
    
    local user = memory.nicknames["Player"] and "Player" or "User"
    local messagesSinceProactive = 0
    
    -- Main conversation loop
    while true do
        -- Occasionally be proactive (every 8-12 messages)
        if messagesSinceProactive >= math.random(8, 12) and memory.facts[user] and #memory.facts[user] > 0 then
            messagesSinceProactive = 0
            
            -- Bring up something they mentioned before
            if math.random() < 0.5 then
                local fact = recallFact(user)
                if fact and not discussedRecently(fact) then
                    if term and term.setTextColor then
                        term.setTextColor(memory.chatColor)
                    end
                    print("<" .. BOT_NAME .. "> Hey, earlier you mentioned " .. fact .. " - how's that going?")
                    if term and term.setTextColor then
                        term.setTextColor(colors.white)
                    end
                    print("")
                end
            else
                -- Ask about their preferences
                if memory.preferences[user] and #memory.preferences[user].likes > 0 then
                    local like = memory.preferences[user].likes[math.random(#memory.preferences[user].likes)]
                    if term and term.setTextColor then
                        term.setTextColor(memory.chatColor)
                    end
                    print("<" .. BOT_NAME .. "> So you like " .. like .. " - what got you into that?")
                    if term and term.setTextColor then
                        term.setTextColor(colors.white)
                    end
                    print("")
                end
            end
        end
        
        -- Show prompt with chat color
        if term and term.setTextColor then
            term.setTextColor(colors.yellow)
        end
        write("> ")
        if term and term.setTextColor then
            term.setTextColor(colors.white)
        end
        
        local input = read()
        messagesSinceProactive = messagesSinceProactive + 1
        
        -- Check for exit
        if input:lower() == "quit" or input:lower() == "exit" then
            if term and term.setTextColor then
                term.setTextColor(memory.chatColor)
            end
            
            -- Personalized goodbye
            local goodbyes = {
                "Bye! It was great talking with you!",
                "See you later! Take care!",
                "Later! This was fun!",
            }
            
            if memory.nicknames[user] then
                goodbyes = {
                    "Bye " .. memory.nicknames[user] .. "! Talk soon!",
                    "Later " .. memory.nicknames[user] .. "! Take care!",
                    "See you " .. memory.nicknames[user] .. "!",
                }
            end
            
            print("<" .. BOT_NAME .. "> " .. utils.choose(goodbyes))
            
            if term and term.setTextColor then
                term.setTextColor(colors.white)
            end
            saveMemory()
            break
        end
        
        -- Skip empty input
        if input == "" then
            if term and term.setTextColor then
                term.setTextColor(memory.chatColor)
            end
            print("<" .. BOT_NAME .. "> I'm listening...")
            if term and term.setTextColor then
                term.setTextColor(colors.white)
            end
        else
            -- Generate and display response
            local response = interpret(input, user)
            
            if term and term.setTextColor then
                term.setTextColor(memory.chatColor)
            end
            print("<" .. BOT_NAME .. "> " .. response)
            if term and term.setTextColor then
                term.setTextColor(colors.white)
            end
        end
        
        print("")  -- Add spacing
    end
end

return M
