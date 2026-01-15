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

local BOT_NAME = "SuperAI"
local isTurtle = (type(turtle) == "table")

-- ============================================================================
-- MEMORY SYSTEM
-- ============================================================================

local memory = {
    nicknames = {},
    context = {},
    learned = {},
    chatColor = colors.white,
    categories = {},
    negative = {}
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
        negative = memory.negative
    }))
    file.close()
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
        timestamp = os.time()
    })
    
    if #memory.context > 10 then
        table.remove(memory.context, 1)
    end
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
-- INTENT DETECTION
-- ============================================================================

local function detectIntent(message)
    local msg = message:lower()
    
    -- Math
    if msg:find("%d") and (msg:find("[%+%-%*/]") or msg:find("plus") or msg:find("minus") or 
       msg:find("times") or msg:find("divided") or msg:find("calculate")) then
        return "math"
    end
    
    -- Time
    if msg:find("time") or msg:find("clock") then
        return "time"
    end
    
    -- Greeting
    if msg:match("^hi+$") or msg:match("^hello") or msg:match("^hey+") or 
       msg:match("^sup") or msg:match("^yo+") then
        return "greeting"
    end
    
    -- Gratitude
    if msg:find("thank") or msg:find("thanks") then
        return "gratitude"
    end
    
    -- Nickname request
    if msg:match("call me%s+(.+)") then
        return "nickname", msg:match("call me%s+(.+)")
    end
    
    -- Question
    if msg:find("?") or msg:match("^what") or msg:match("^why") or 
       msg:match("^how") or msg:match("^when") or msg:match("^where") then
        return "question"
    end
    
    return "statement"
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
    }
    
    local response = utils.choose(greetings)
    
    -- Personalize if we know their name
    if memory.nicknames[user] then
        local personalGreetings = {
            "Hey " .. memory.nicknames[user] .. "! What's up?",
            "Hi " .. memory.nicknames[user] .. "! How's it going?",
            "Yo " .. memory.nicknames[user] .. "!",
            "Hey " .. memory.nicknames[user] .. "! What's new?",
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
    -- Check for specific answerable questions
    if message:lower():find("who are you") or message:lower():find("what are you") then
        return "I'm " .. BOT_NAME .. ", just a friendly AI here to chat! What's up?"
    end
    
    if message:lower():find("how are you") then
        local responses = {
            "I'm doing great! How about you?",
            "Pretty good! What's going on with you?",
            "Can't complain! How are you?",
            "I'm good, thanks! What about you?",
        }
        return utils.choose(responses)
    end
    
    if message:lower():find("what can you do") or message:lower():find("what do you do") then
        return "I can chat with you, solve math problems, tell you the time... mostly I'm just here to talk! What would you like to do?"
    end
    
    -- General question handling - be honest but casual
    local responses = {
        "Hmm, good question. What do you think?",
        "I'm not totally sure. What's your take?",
        "That's interesting. I'd have to think about it. What do you think?",
        "You know, I'm not certain. What's your opinion?",
        "I don't really know. Why do you ask?",
    }
    
    return utils.choose(responses)
end

local function handleStatement(user, message, userMood)
    local category = detectCategory(message)
    local keywords = utils.extractKeywords(message)
    
    -- For negative moods, be supportive but natural
    if userMood == "negative" then
        local supportive = {
            "That sounds rough.",
            "Man, that sucks.",
            "Ugh, I bet that's frustrating.",
            "Yeah, that's tough.",
            "That sounds annoying.",
            "I'm sorry to hear that.",
        }
        
        local response = utils.choose(supportive)
        
        -- Maybe ask what's up
        if math.random() < 0.4 then
            local followUps = {
                "What happened?",
                "Want to talk about it?",
                "What's going on?",
                "You okay?",
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
        }
        
        return utils.choose(positive)
    end
    
    -- Personal stuff - be interested but casual
    if category == "personal" then
        local responses = {
            "Oh yeah? Tell me more.",
            "Interesting. What's that like?",
            "Really? How's that been going?",
            "Huh, I didn't know that.",
            "That's cool. What made you think of that?",
        }
        return utils.choose(responses)
    end
    
    -- General conversation - be natural
    local responses = {
        "Yeah, totally.",
        "I get what you mean.",
        "That makes sense.",
        "True that.",
        "Fair enough.",
        "I see what you're saying.",
        "Right, right.",
        "Gotcha.",
    }
    
    local response = utils.choose(responses)
    
    -- Sometimes add a follow-up question (not too often)
    if personality.shouldAskQuestion() and math.random() < 0.3 then
        local followUps = {
            "What do you think?",
            "How'd that go?",
            "What happened?",
            "Why's that?",
            "Really?",
        }
        response = response .. " " .. utils.choose(followUps)
    end
    
    return response
end

-- ============================================================================
-- MAIN INTERPRETATION
-- ============================================================================

local function interpret(message, user)
    -- Update mood
    mood.update(user, message)
    local userMood = mood.get(user)
    
    -- Detect intent
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)
    
    local response
    
    -- Handle specific intents
    if intent == "math" then
        response = evaluateMath(message)
        if not response then
            response = "I couldn't solve that. Try something like '5 + 3' or 'what is 10 times 4'."
        end
        
    elseif intent == "time" then
        response = "It's Minecraft time: " .. tostring(os.time()) .. "."
        
    elseif intent == "greeting" then
        response = handleGreeting(user, message)
        
    elseif intent == "gratitude" then
        response = handleGratitude(user, message)
        personality.evolve("positive", {messageType = "general"})
        
    elseif intent == "nickname" then
        response = setNickname(user, extra)
        
    elseif intent == "question" then
        response = handleQuestion(user, message, userMood)
        
    else
        response = handleStatement(user, message, userMood)
    end
    
    -- Adjust for mood
    response = mood.adjustResponse(user, response)
    
    -- Store in context
    updateContext(user, message, category, response)
    
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
    
    -- Main conversation loop
    while true do
        -- Show prompt with chat color
        if term and term.setTextColor then
            term.setTextColor(colors.yellow)
        end
        write("> ")
        if term and term.setTextColor then
            term.setTextColor(colors.white)
        end
        
        local input = read()
        
        -- Check for exit
        if input:lower() == "quit" or input:lower() == "exit" then
            if term and term.setTextColor then
                term.setTextColor(memory.chatColor)
            end
            print("<" .. BOT_NAME .. "> Bye! It was great talking with you!")
            if term and term.setTextColor then
                term.setTextColor(colors.white)
            end
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
