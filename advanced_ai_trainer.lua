-- advanced_ai_trainer.lua (Batch System - Works around ComputerCraft limits!)
-- Trains in batches of 450 conversations, can be resumed

local M = {}

local SWAP_DISK = "disk4"
local BATCH_SIZE = 450  -- Safe limit per execution

-- Progress tracking
local function saveProgress(completed, total, s_conf, t_conf)
    local f = fs.open("/training/progress.txt", "w")
    f.writeLine(tostring(completed))
    f.writeLine(tostring(total))
    f.writeLine(tostring(s_conf))
    f.writeLine(tostring(t_conf))
    f.close()
end

local function loadProgress()
    if not fs.exists("/training/progress.txt") then
        return 0, 0, 0.5, 0.7
    end
    local f = fs.open("/training/progress.txt", "r")
    local completed = tonumber(f.readLine()) or 0
    local total = tonumber(f.readLine()) or 0
    local s_conf = tonumber(f.readLine()) or 0.5
    local t_conf = tonumber(f.readLine()) or 0.7
    f.close()
    return completed, total, s_conf, t_conf
end

-- [ALL THE PREVIOUS FUNCTIONS - writePersonality, readPersonality, writeContext, readContext, etc.]
-- [Copy from previous version - keeping this file size down for readability]

-- Manual encoding functions
local function writePersonality(id, role, traits, metrics)
    local f = fs.open(SWAP_DISK .. "/p_" .. id, "w")
    f.writeLine(role)
    if role == "student" then
        f.writeLine(tostring(traits.curiosity))
        f.writeLine(tostring(traits.enthusiasm))
        f.writeLine(tostring(traits.depth))
        f.writeLine(tostring(traits.humor))
        f.writeLine(tostring(traits.creativity))
    else
        f.writeLine(tostring(traits.helpfulness))
        f.writeLine(tostring(traits.patience))
        f.writeLine(tostring(traits.depth))
        f.writeLine(tostring(traits.clarity))
        f.writeLine(tostring(traits.encouragement))
    end
    f.writeLine(tostring(metrics.conversations))
    f.writeLine(tostring(metrics.successful_exchanges))
    f.writeLine(tostring(metrics.confidence))
    f.writeLine(tostring(metrics.learning_rate))
    f.close()
end

local function readPersonality(id)
    local path = SWAP_DISK .. "/p_" .. id
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local role = f.readLine()
    local traits = {}
    if role == "student" then
        traits.curiosity = tonumber(f.readLine())
        traits.enthusiasm = tonumber(f.readLine())
        traits.depth = tonumber(f.readLine())
        traits.humor = tonumber(f.readLine())
        traits.creativity = tonumber(f.readLine())
    else
        traits.helpfulness = tonumber(f.readLine())
        traits.patience = tonumber(f.readLine())
        traits.depth = tonumber(f.readLine())
        traits.clarity = tonumber(f.readLine())
        traits.encouragement = tonumber(f.readLine())
    end
    local metrics = {
        conversations = tonumber(f.readLine()),
        successful_exchanges = tonumber(f.readLine()),
        confidence = tonumber(f.readLine()),
        learning_rate = tonumber(f.readLine())
    }
    f.close()
    return {id = id, role = role, traits = traits, metrics = metrics}
end

local function writeContext(id, topic, emotional_state, depth, question_streak, exchanges)
    local f = fs.open(SWAP_DISK .. "/c_" .. id, "w")
    f.writeLine(topic)
    f.writeLine(emotional_state)
    f.writeLine(tostring(depth))
    f.writeLine(tostring(question_streak))
    f.writeLine(tostring(#exchanges))
    for _, ex in ipairs(exchanges) do
        f.writeLine(ex.speaker)
        f.writeLine(ex.message:gsub("\n", "\\n"))
    end
    f.close()
end

local function readContext(id)
    local path = SWAP_DISK .. "/c_" .. id
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local topic = f.readLine()
    local emotional_state = f.readLine()
    local depth = tonumber(f.readLine())
    local question_streak = tonumber(f.readLine())
    local count = tonumber(f.readLine())
    local exchanges = {}
    for i = 1, count do
        local speaker = f.readLine()
        local message = f.readLine():gsub("\\n", "\n")
        table.insert(exchanges, {speaker = speaker, message = message})
    end
    f.close()
    return {id = id, current_topic = topic, emotional_state = emotional_state, depth = depth, question_streak = question_streak, recent_exchanges = exchanges}
end

local function createPersonality(id, role, initial_conf)
    local traits = {}
    local metrics = {conversations = 0, successful_exchanges = 0, confidence = initial_conf or (role == "student" and 0.5 or 0.7), learning_rate = 1.0}
    if role == "student" then
        traits = {curiosity = 0.8, enthusiasm = 0.7, depth = 0.5, humor = 0.4, creativity = 0.6}
    else
        traits = {helpfulness = 0.9, patience = 0.8, depth = 0.7, clarity = 0.8, encouragement = 0.9}
    end
    writePersonality(id, role, traits, metrics)
    return {id = id}
end

local function evolvePersonality(id, role, success, engagement)
    local p = readPersonality(id)
    if success then
        p.metrics.confidence = math.min(1.0, p.metrics.confidence + 0.002)
        p.metrics.successful_exchanges = p.metrics.successful_exchanges + 1
    end
    if engagement > 0.7 then
        if p.traits.curiosity then
            p.traits.curiosity = math.min(1.0, p.traits.curiosity + 0.005)
        end
        if p.traits.helpfulness then
            p.traits.helpfulness = math.min(1.0, p.traits.helpfulness + 0.003)
        end
    end
    p.metrics.conversations = p.metrics.conversations + 1
    writePersonality(id, p.role, p.traits, p.metrics)
    return p
end

local function createContext(id)
    writeContext(id, "general", "neutral", 0, 0, {})
    return {id = id}
end

local function addExchange(ctx_id, speaker, message)
    local ctx = readContext(ctx_id)
    table.insert(ctx.recent_exchanges, {speaker = speaker, message = message})
    if #ctx.recent_exchanges > 5 then
        table.remove(ctx.recent_exchanges, 1)
    end
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") then ctx.current_topic = "programming"
    elseif msg_lower:find("learn") or msg_lower:find("study") then ctx.current_topic = "learning"
    elseif msg_lower:find("think") or msg_lower:find("feel") then ctx.current_topic = "personal"
    elseif msg_lower:find("ai") or msg_lower:find("intelligence") then ctx.current_topic = "ai"
    elseif msg_lower:find("game") or msg_lower:find("play") then ctx.current_topic = "gaming"
    end
    if msg_lower:find("awesome") or msg_lower:find("great") then ctx.emotional_state = "positive"
    elseif msg_lower:find("confus") or msg_lower:find("hard") then ctx.emotional_state = "confused"
    elseif msg_lower:find("interest") or msg_lower:find("curious") then ctx.emotional_state = "curious"
    elseif msg_lower:find("frustrat") then ctx.emotional_state = "frustrated"
    else ctx.emotional_state = "neutral"
    end
    ctx.depth = ctx.depth + 1
    ctx.question_streak = message:find("?") and (ctx.question_streak + 1) or 0
    writeContext(ctx.id, ctx.current_topic, ctx.emotional_state, ctx.depth, ctx.question_streak, ctx.recent_exchanges)
    return ctx
end

-- Templates
local ST = {
    g = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?", "Yo! Ready to learn?"},
    q = {"How does that work?", "Can you explain more?", "What do you mean?", "Why is that important?", "What's the best way?", "Is there more to it?", "What are the key concepts?", "How would I use that?"},
    r = {"That's interesting!", "Oh I see!", "That makes sense!", "I never thought of that!", "Cool, thanks!", "Wow, fascinating!", "This helps!", "Ah, now I get it!"},
    a = {"Got it!", "I understand!", "That helps!", "Makes sense!", "Awesome!", "Oh I see!", "Clear!", "Perfect!"},
    d = {"What's the underlying principle?", "How does this connect?", "What are real-world uses?", "Why designed that way?"}
}

local TT = {
    g = {"Hey! Ready to learn?", "Hi! What would you like to know?", "Hello! Let's dive in!"},
    e = {"Great question! Let me explain.", "Think of it like organizing information.", "The key is how parts work together.", "Simpler than it sounds.", "Let me break it down.", "Here's how to think about it.", "The important thing is this.", "Imagine it like this."},
    c = {"You're getting it!", "Exactly!", "Good thinking!", "Perfect!", "That's it!", "You've got it!", "Well done!", "Spot on!"},
    f = {"Make sense?", "Want more?", "Questions?", "Ready to move on?", "Got it?", "Clear?"},
    b = {"To add,", "Another way:", "Building on that:", "Interesting detail:"}
}

local function choose(list)
    return list[math.random(#list)]
end

local function generateResponse(personality_id, context_id, role, traits)
    local ctx = readContext(context_id)
    local last_msg = #ctx.recent_exchanges > 0 and ctx.recent_exchanges[#ctx.recent_exchanges].message or nil
    local is_question = last_msg and last_msg:find("?") ~= nil
    if role == "student" then
        if not last_msg then return choose(ST.g)
        elseif is_question then
            local r = choose(ST.a)
            if math.random() < traits.curiosity then
                r = r .. " " .. (ctx.depth > 7 and math.random() < 0.3 and choose(ST.d) or choose(ST.q))
            end
            return r
        elseif ctx.depth > 5 and math.random() < 0.4 then return choose(ST.r)
        else return choose(ST.q)
        end
    else
        if is_question then
            local r = choose(TT.e)
            if ctx.depth > 6 and math.random() < 0.2 then r = choose(TT.b) .. " " .. r:lower() end
            if math.random() < 0.3 and ctx.question_streak < 2 then r = r .. " " .. choose(TT.f) end
            return r
        else return choose(TT.c)
        end
    end
end

local function csvEscape(str)
    return '"' .. str:gsub('"', '""') .. '"'
end

-- Main batch training
function M.runBatch(start_conv, end_conv, turns, s_conf, t_conf)
    if not fs.exists(SWAP_DISK) then
        print("ERROR: Swap disk not found!")
        return 0, s_conf, t_conf
    end
    
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    fs.makeDir(SWAP_DISK .. "/swap")
    
    -- Create/load personalities with current confidence
    createPersonality("student", "student", s_conf)
    createPersonality("teacher", "teacher", t_conf)
    
    local log_mode = start_conv == 1 and "w" or "a"
    if start_conv == 1 then
        local log = fs.open("/training/conversation_log.csv", "w")
        log.writeLine("speaker_a,message_a,speaker_b,message_b,topic,emotion,turn,depth")
        log.close()
    end
    
    local start_time = os.clock()
    local total = 0
    
    for conv = start_conv, end_conv do
        local ctx_id = "c" .. conv
        createContext(ctx_id)
        local s_p = readPersonality("student")
        local t_p = readPersonality("teacher")
        local s_msg = generateResponse("student", ctx_id, "student", s_p.traits)
        local ctx = addExchange(ctx_id, "Student", s_msg)
        
        local log = fs.open("/training/conversation_log.csv", "a")
        for turn = 1, turns - 1 do
            local t_msg = generateResponse("teacher", ctx_id, "teacher", t_p.traits)
            ctx = addExchange(ctx_id, "Teacher", t_msg)
            log.write(csvEscape("Student")) log.write(",") log.write(csvEscape(s_msg)) log.write(",")
            log.write(csvEscape("Teacher")) log.write(",") log.write(csvEscape(t_msg)) log.write(",")
            log.write(csvEscape(ctx.current_topic)) log.write(",") log.write(csvEscape(ctx.emotional_state)) log.write(",")
            log.write(tostring(turn)) log.write(",") log.write(tostring(ctx.depth)) log.write("\n")
            s_msg = generateResponse("student", ctx_id, "student", s_p.traits)
            ctx = addExchange(ctx_id, "Student", s_msg)
            total = total + 1
        end
        log.close()
        
        s_p = evolvePersonality("student", "student", true, 0.8)
        t_p = evolvePersonality("teacher", "teacher", true, 0.9)
        if fs.exists(SWAP_DISK .. "/c_c" .. conv) then
            fs.delete(SWAP_DISK .. "/c_c" .. conv)
        end
        
        if (conv - start_conv + 1) % 50 == 0 then
            print(string.format("Batch progress: %d/%d", conv - start_conv + 1, end_conv - start_conv + 1))
        end
        
        -- CRITICAL: Yield to prevent "too long without yielding" error
        if (conv - start_conv + 1) % 10 == 0 then
            os.sleep(0)
        end
    end
    
    local final_s = readPersonality("student")
    local final_t = readPersonality("teacher")
    
    print(string.format("Batch complete: %d conversations, %.1f sec", end_conv - start_conv + 1, os.clock() - start_time))
    
    return total, final_s.metrics.confidence, final_t.metrics.confidence
end

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local total_conversations = options.conversations or 1000
    local turns = options.turns or 8
    
    print("=== BATCH TRAINING SYSTEM ===")
    print(string.format("Total: %d conversations", total_conversations))
    print(string.format("Batch size: %d (safe limit)", BATCH_SIZE))
    print("")
    
    local completed, _, s_conf, t_conf = loadProgress()
    if completed > 0 then
        print(string.format("Resuming from conversation %d", completed + 1))
    end
    
    local total_batches = math.ceil((total_conversations - completed) / BATCH_SIZE)
    
    for batch = 1, total_batches do
        local start_conv = completed + 1
        local end_conv = math.min(completed + BATCH_SIZE, total_conversations)
        
        print(string.format("=== BATCH %d/%d: Conversations %d-%d ===", batch, total_batches, start_conv, end_conv))
        
        local exchanges, new_s_conf, new_t_conf = M.runBatch(start_conv, end_conv, turns, s_conf, t_conf)
        
        completed = end_conv
        s_conf = new_s_conf
        t_conf = new_t_conf
        
        saveProgress(completed, total_conversations, s_conf, t_conf)
        
        print(string.format("Progress: %d/%d (%.1f%%)", completed, total_conversations, (completed/total_conversations)*100))
        print(string.format("Student: %.3f | Teacher: %.3f", s_conf, t_conf))
        print("")
        
        if completed < total_conversations then
            print("Starting next batch in 3 seconds...")
            os.sleep(3)
        end
    end
    
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total: %d conversations", completed))
    fs.delete("/training/progress.txt")
    
    return {exchanges = completed * (turns - 1), student_confidence = s_conf, teacher_confidence = t_conf}
end

function M.run()
    print("=== AI TRAINER (BATCH SYSTEM) ===")
    print("1. Quick (500)")
    print("2. Standard (2,000)")
    print("3. Deep (10,000)")
    print("4. ULTIMATE (50,000)")
    write("Choice: ")
    local c = read()
    if c == "1" then M.createAdvancedTrainingSession({conversations = 500, turns = 6})
    elseif c == "2" then M.createAdvancedTrainingSession({conversations = 2000, turns = 8})
    elseif c == "3" then M.createAdvancedTrainingSession({conversations = 10000, turns = 10})
    elseif c == "4" then
        write("Type YES: ")
        if read():upper() == "YES" then
            M.createAdvancedTrainingSession({conversations = 50000, turns = 12})
        end
    end
end

return M
