-- Module: main_logic.lua
-- Main SuperAI logic and chat loop

local M = {}

-- Load other modules
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- Bot configuration
local BOT_NAME = "SuperAI"
local isTurtle = (type(turtle) == "table")

-- Memory structure
local memory = {
    nicknames = {},
    context = {},
    learned = {},
    chatColor = colors.white,
    categories = {},
    negative = {}
}

-- ===== DISK STORAGE =====

local diskDrive = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "drive" then
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

-- ===== CATEGORY DETECTION =====

local defaultCategories = {
    greeting = {"hi", "hello", "hey", "greetings"},
    math = {"calculate", "what", "%d+%s*[%+%-%*/%%%^]%s*%d+"},
    turtle = {"forward", "back", "up", "down", "dig", "place", "mine"},
    time = {"time", "date", "clock"},
    gratitude = {"thanks", "thank you"},
    color = {"color", "chat"}
}

-- Initialize categories
for cat, keywords in pairs(defaultCategories) do
    if not memory.categories[cat] then
        memory.categories[cat] = keywords
    end
end

local function detectCategory(message)
    local msg = message:lower()
    local bestCat, bestScore = "unknown", 0
    
    for cat, keywords in pairs(memory.categories) do
        local score = 0
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then score = score + 1 end
        end
        if score > bestScore then
            bestScore = score
            bestCat = cat
        end
    end
    
    return bestCat
end

-- ===== INTENT DETECTION =====

local intents = {
    greeting = {"hi", "hello", "hey", "greetings"},
    math = {"%d+%s*[%+%-%*/%%%^]%s*%d+", "calculate", "what is"},
    turtle = {"forward", "back", "up", "down", "dig", "place", "mine"},
    time = {"time", "what time"},
    gratitude = {"thank you", "thanks"},
    color_change = {"change my color", "set chat color"},
    nickname = {"please call me%s+(.+)", "call me%s+(.+)"},
    remember = {"remember"}
}

local function detectIntent(message)
    local msg = message:lower()
    for intent, patterns in pairs(intents) do
        for _, pattern in ipairs(patterns) do
            local match = msg:match(pattern)
            if match then
                if intent == "nickname" then
                    return intent, match
                end
                return intent
            end
        end
    end
    return "unknown"
end

-- ===== USER MANAGEMENT =====

local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user, nickname)
    memory.nicknames[user] = nickname
    saveMemory()
    return "Got it! I'll call you " .. nickname .. " from now on."
end

-- ===== MATH EVALUATION =====

local function evaluateMath(message)
    local expr = message:match("(%d+%s*[%+%-%*/%%%^]%s*%d+)")
    if expr then
        local func, err = load("return " .. expr)
        if func then
            local success, result = pcall(func)
            if success then
                return "The result is: " .. tostring(result)
            end
        end
    end
    return nil
end

-- ===== TURTLE CONTROL =====

local function turtleAction(action, successMsg)
    if not isTurtle then return "Error: I'm not a turtle!" end
    local success, msg = pcall(action)
    if success then
        return successMsg
    else
        return "Error: " .. (msg or "Something blocked me.")
    end
end

-- ===== COMMANDS =====

local commands = {
    hello = function(user)
        return utils.choose(utils.library.greetings) .. " How can I help, " .. getName(user) .. "?"
    end,
    time = function()
        return "It's Minecraft time: " .. tostring(os.time()) .. "."
    end,
    forward = function()
        return turtleAction(turtle.forward, "Moved forward!")
    end,
    back = function()
        return turtleAction(turtle.back, "Moved back!")
    end,
    up = function()
        return turtleAction(turtle.up, "Moved up!")
    end,
    down = function()
        return turtleAction(turtle.down, "Moved down!")
    end,
    dig = function()
        return turtleAction(turtle.dig, "Dug a block!")
    end,
    place = function()
        return turtleAction(turtle.place, "Placed a block!")
    end,
    set_color = function()
        local chatColors = {
            {name = "white", code = colors.white},
            {name = "yellow", code = colors.yellow},
            {name = "green", code = colors.green},
            {name = "cyan", code = colors.cyan},
            {name = "red", code = colors.red},
            {name = "purple", code = colors.purple},
            {name = "blue", code = colors.blue}
        }
        
        print("Choose your chat color:")
        for i, v in ipairs(chatColors) do
            print(i .. ") " .. v.name)
        end
        
        write("Enter color number: ")
        local choice = tonumber(read())
        
        if choice and chatColors[choice] then
            memory.chatColor = chatColors[choice].code
            saveMemory()
            return "Chat color set to " .. chatColors[choice].name .. "!"
        else
            return "Invalid choice."
        end
    end
}

-- ===== LEARNING SYSTEM =====

local function recordLearning(message, response, category)
    local msg = utils.normalize(message)
    local keywords = utils.extractKeywords(msg)
    
    if memory.negative[msg] == response then return end
    
    if not memory.learned[msg] then
        memory.learned[msg] = {
            responses = {{text = response, category = category, keywords = keywords}},
            count = {1}
        }
    else
        local entry = memory.learned[msg]
        local found = false
        
        for i, r in ipairs(entry.responses) do
            if r.text == response then
                entry.count[i] = entry.count[i] + 1
                found = true
                break
            end
        end
        
        if not found then
            table.insert(entry.responses, {text = response, category = category, keywords = keywords})
            table.insert(entry.count, 1)
        end
    end
    
    saveMemory()
end

-- ===== AUTONOMOUS RESPONSE =====

local function chooseAutonomous(message)
    local msg = utils.normalize(message)
    local keywords = utils.extractKeywords(msg)
    local category = detectCategory(message)
    local bestResp, bestScore = nil, 0
    
    -- Check learned responses
    for learnedMsg, entry in pairs(memory.learned) do
        for i, response in ipairs(entry.responses) do
            local score = 0
            
            -- Keyword matching
            for _, kw in ipairs(keywords) do
                for _, rkw in ipairs(response.keywords) do
                    if kw == rkw then score = score + 1 end
                end
            end
            
            -- Category bonus
            if response.category == category then score = score + 2 end
            
            -- Frequency bonus
            score = score * entry.count[i]
            
            if score > bestScore then
                bestScore = score
                bestResp = response.text
            end
        end
    end
    
    -- Fallback to library responses
    if not bestResp or bestScore < 2 then
        if math.random() < personality.get("humor") then
            bestResp = utils.choose(utils.library.jokes)
        else
            local options = {}
            for _, tbl in ipairs({utils.library.greetings, utils.library.replies, utils.library.interjections}) do
                for _, txt in ipairs(tbl) do
                    table.insert(options, txt)
                end
            end
            bestResp = utils.choose(options)
        end
    end
    
    return bestResp or "Hmm… not sure what to say."
end

-- ===== CONTEXT MANAGEMENT =====

local function updateContext(user, message, category, response)
    table.insert(memory.context, {
        user = user,
        message = message,
        category = category,
        response = response,
        timestamp = os.time()
    })
    
    if #memory.context > 20 then
        table.remove(memory.context, 1)
    end
end

-- ===== MAIN INTERPRET FUNCTION =====

local function interpret(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)
    
    -- Update mood
    mood.update(user, message)
    
    -- Handle specific intents
    if intent == "gratitude" then
        return utils.choose(utils.library.replies)
    elseif intent == "math" then
        local mathResult = evaluateMath(message)
        if mathResult then return mathResult end
    elseif intent == "nickname" then
        return setNickname(user, extra)
    elseif intent == "time" then
        return commands.time()
    elseif intent == "turtle" then
        for cmd, _ in pairs(commands) do
            if message:lower():find(cmd) then
                return commands[cmd](user)
            end
        end
    elseif intent == "greeting" then
        return commands.hello(user)
    elseif intent == "color_change" then
        return commands.set_color()
    end
    
    -- Autonomous response
    local response = chooseAutonomous(message)
    
    -- Adjust for mood
    response = mood.adjustResponse(user, response)
    
    -- Add follow-up occasionally
    local followUp = responses.generateFollowUp(category)
    if followUp then
        response = response .. " " .. followUp
    end
    
    -- Update context and learning
    updateContext(user, message, category, response)
    recordLearning(message, response, category)
    
    -- Evolve personality based on interaction
    local sentiment = mood.detectSentiment(message)
    personality.evolve(sentiment == "positive" and "positive" or "neutral", category)
    
    return response
end

-- ===== FEEDBACK HANDLER =====

local function handleFeedback(user, message)
    if message:lower():find("no") and #memory.context > 0 then
        local lastEntry = memory.context[#memory.context]
        memory.negative[utils.normalize(lastEntry.message)] = lastEntry.response
        saveMemory()
        personality.evolve("negative", lastEntry.category)
        return "Got it! I'll adjust my responses."
    end
    return nil
end

-- ===== FIRST RUN SETUP =====

local function firstRunSetup()
    local user = "Player"
    
    if not memory.nicknames[user] then
        write("Hi! What should I call you? ")
        local nickname = read()
        if nickname ~= "" then
            memory.nicknames[user] = nickname
            print("Great! I'll call you " .. nickname .. ".")
        else
            memory.nicknames[user] = user
        end
        saveMemory()
    end
    
    if not memory.chatColor or memory.chatColor == colors.white then
        commands.set_color()
    end
end

-- ===== MODULE ENTRY POINT =====

function M.run()
    loadMemory()
    firstRunSetup()
    print("[" .. BOT_NAME .. "] Ready to chat! Type 'help' for commands.")
    
    while true do
        -- Show prompt in chat color
        if memory.chatColor then
            term.setTextColor(memory.chatColor)
        end
        write("> ")
        term.setTextColor(colors.white)
        
        local input = read()
        local user = "Player"
        
        if input ~= "" then
            -- Check for feedback first
            local feedbackResp = handleFeedback(user, input)
            if feedbackResp then
                print(feedbackResp)
            else
                -- Generate response
                local response = interpret(input, user)
                
                -- Display response in chat color
                if memory.chatColor then
                    term.setTextColor(memory.chatColor)
                end
                print("<" .. BOT_NAME .. "> " .. response)
                term.setTextColor(colors.white)
            end
        end
    end
end

return M
