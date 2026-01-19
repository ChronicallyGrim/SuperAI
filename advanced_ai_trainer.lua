-- advanced_ai_trainer.lua (CSV Format - No Serialize!)
-- Uses simple CSV format instead of textutils.serialize to avoid memory buildup

local M = {}

local SWAP_DISK = "disk4"

-- Simple responses (no large tables)
local STUDENT_GREETINGS = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?"}
local STUDENT_QUESTIONS = {"How does that work?", "Can you explain more?", "What do you mean?", "Why is that important?"}
local STUDENT_ACKS = {"Got it!", "I understand!", "Makes sense!", "Awesome!"}
local STUDENT_REACTIONS = {"That's interesting!", "Oh I see!", "That makes sense!", "Cool!"}

local TEACHER_EXPLANATIONS = {"Great question! Let me explain.", "Think of it like organizing information.", "The key is how parts work together.", "It's simpler than it sounds."}
local TEACHER_ENCOURAGEMENTS = {"You're getting it!", "Exactly!", "Good thinking!", "Perfect!"}
local TEACHER_FOLLOWUPS = {"Make sense?", "Want more?", "Questions?", "Got it?"}

local function choose(list)
    return list[math.random(#list)]
end

-- Context on disk
local function createContext(id)
    local f = fs.open(SWAP_DISK .. "/ctx_" .. id, "w")
    f.writeLine("general")  -- topic
    f.writeLine("0")        -- depth
    f.writeLine("")         -- last message
    f.close()
    return id
end

local function readContext(id)
    if not fs.exists(SWAP_DISK .. "/ctx_" .. id) then
        return {topic = "general", depth = 0, last = ""}
    end
    local f = fs.open(SWAP_DISK .. "/ctx_" .. id, "r")
    local topic = f.readLine() or "general"
    local depth = tonumber(f.readLine()) or 0
    local last = f.readLine() or ""
    f.close()
    return {topic = topic, depth = depth, last = last}
end

local function updateContext(id, message)
    local ctx = readContext(id)
    ctx.last = message
    ctx.depth = ctx.depth + 1
    
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") then
        ctx.topic = "programming"
    elseif msg_lower:find("learn") then
        ctx.topic = "learning"
    end
    
    local f = fs.open(SWAP_DISK .. "/ctx_" .. id, "w")
    f.writeLine(ctx.topic)
    f.writeLine(tostring(ctx.depth))
    f.writeLine(ctx.last)
    f.close()
    
    return ctx
end

local function deleteContext(id)
    if fs.exists(SWAP_DISK .. "/ctx_" .. id) then
        fs.delete(SWAP_DISK .. "/ctx_" .. id)
    end
end

-- Generate response
local function generateResponse(role, ctx)
    local is_q = ctx.last:find("?") ~= nil
    
    if role == "student" then
        if ctx.depth == 0 then
            return choose(STUDENT_GREETINGS)
        elseif is_q then
            local resp = choose(STUDENT_ACKS)
            if math.random() < 0.7 then
                resp = resp .. " " .. choose(STUDENT_QUESTIONS)
            end
            return resp
        elseif ctx.depth > 5 and math.random() < 0.4 then
            return choose(STUDENT_REACTIONS)
        else
            return choose(STUDENT_QUESTIONS)
        end
    else
        if is_q then
            local resp = choose(TEACHER_EXPLANATIONS)
            if math.random() < 0.3 then
                resp = resp .. " " .. choose(TEACHER_FOLLOWUPS)
            end
            return resp
        else
            return choose(TEACHER_ENCOURAGEMENTS)
        end
    end
end

-- CSV escape
local function csvEscape(str)
    return '"' .. str:gsub('"', '""') .. '"'
end

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local num = options.conversations or 1000
    local turns = options.turns or 8
    
    print("=== ADVANCED AI TRAINING (CSV Format) ===")
    print("")
    
    if not fs.exists(SWAP_DISK) then
        print("ERROR: Swap disk not found!")
        return {exchanges = 0}
    end
    
    -- Clear swap
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    fs.makeDir(SWAP_DISK .. "/swap")
    
    print("Virtual memory ready! (Using " .. SWAP_DISK .. ")")
    print(string.format("Training: %d conversations", num))
    print("")
    
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    local start = os.clock()
    local total = 0
    local s_conf = 0.5
    local t_conf = 0.7
    
    -- Open log in APPEND mode, write incrementally
    local log = fs.open("/training/conversation_log.csv", "w")
    log.writeLine("speaker_a,message_a,speaker_b,message_b,topic,turn")  -- CSV header
    
    for conv = 1, num do
        local ctx_id = "c" .. conv
        createContext(ctx_id)
        
        local ctx = readContext(ctx_id)
        local s_msg = generateResponse("student", ctx)
        ctx = updateContext(ctx_id, s_msg)
        
        for turn = 1, turns - 1 do
            local t_msg = generateResponse("teacher", ctx)
            ctx = updateContext(ctx_id, t_msg)
            
            -- Write as CSV (MUCH smaller than serialize!)
            log.writeLine(csvEscape("Student") .. "," .. csvEscape(s_msg) .. "," .. 
                         csvEscape("Teacher") .. "," .. csvEscape(t_msg) .. "," .. 
                         csvEscape(ctx.topic) .. "," .. turn)
            
            s_msg = generateResponse("student", ctx)
            ctx = updateContext(ctx_id, s_msg)
            total = total + 1
        end
        
        deleteContext(ctx_id)
        
        s_conf = math.min(1.0, s_conf + 0.002)
        t_conf = math.min(1.0, t_conf + 0.002)
        
        if conv % 100 == 0 then
            local elapsed = os.clock() - start
            local eta = (num - conv) / (conv / elapsed)
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num, (conv/num)*100, eta))
            print(string.format("  Student: %.3f | Teacher: %.3f", s_conf, t_conf))
        end
        
        if conv % 50 == 0 then
            os.sleep(0.05)
        end
    end
    
    log.close()
    
    -- Clean up
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    
    -- Save states (simple format)
    local sf = fs.open("/training/student_ai.dat", "w")
    sf.writeLine("confidence=" .. s_conf)
    sf.writeLine("conversations=" .. num)
    sf.close()
    
    local tf = fs.open("/training/teacher_ai.dat", "w")
    tf.writeLine("confidence=" .. t_conf)
    tf.writeLine("conversations=" .. num)
    tf.close()
    
    print("")
    print("=== COMPLETE ===")
    print(string.format("Exchanges: %d | Time: %.1f sec", total, os.clock() - start))
    
    return {exchanges = total, student_confidence = s_conf, teacher_confidence = t_conf}
end

function M.run()
    print("=== AI TRAINER ===")
    print("1. Quick (500)")
    print("2. Standard (2,000)")
    print("3. Deep (10,000)")
    print("4. ULTIMATE (50,000)")
    write("Choice: ")
    local c = read()
    if c == "1" then
        M.createAdvancedTrainingSession({conversations = 500, turns = 6})
    elseif c == "2" then
        M.createAdvancedTrainingSession({conversations = 2000, turns = 8})
    elseif c == "3" then
        M.createAdvancedTrainingSession({conversations = 10000, turns = 10})
    elseif c == "4" then
        write("Type YES: ")
        if read():upper() == "YES" then
            M.createAdvancedTrainingSession({conversations = 50000, turns = 12})
        end
    end
end

return M
