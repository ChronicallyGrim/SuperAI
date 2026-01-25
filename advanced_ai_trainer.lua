-- advanced_ai_trainer.lua (Multi-Drive RAM System)
-- Uses 6 RAM drives (BACK + BOTTOM) for massive virtual memory capacity

local M = {}

-- ============================================================================
-- CRITICAL FIX: Convert peripheral names to mount paths
-- ============================================================================
local function getMountPath(peripheral_name)
    if not peripheral_name then return nil end
    if not peripheral.isPresent(peripheral_name) then return nil end
    return disk.getMountPath(peripheral_name)
end

-- Detect drives by side (using drive_config.lua) - returns MOUNT PATHS
local function getDrivesBySide()
    local config = require("drive_config")
    
    local result = {
        left = {},
        back = {},
        right = {},
        bottom = {},
        top = {}
    }
    
    -- Convert all peripheral names to mount paths
    for _, name in ipairs(config.left or {}) do
        local path = getMountPath(name)
        if path then table.insert(result.left, path) end
    end
    for _, name in ipairs(config.back or {}) do
        local path = getMountPath(name)
        if path then table.insert(result.back, path) end
    end
    for _, name in ipairs(config.right or {}) do
        local path = getMountPath(name)
        if path then table.insert(result.right, path) end
    end
    for _, name in ipairs(config.bottom or {}) do
        local path = getMountPath(name)
        if path then table.insert(result.bottom, path) end
    end
    if config.top then
        local path = getMountPath(config.top)
        if path then table.insert(result.top, path) end
    end
    
    return result
end

-- Initialize drive system
local RAM_DRIVES = {}  -- LEFT + BACK (6 drives for swap)
local RAID_DRIVES = {} -- RIGHT + BOTTOM (4 drives for storage)
local current_ram_drive = 1

local function initDrives()
    local drives = getDrivesBySide()
    
    -- RAM A (BACK) + RAM B (BOTTOM) = 6 drives for virtual memory
    for _, drive in ipairs(drives.back) do
        table.insert(RAM_DRIVES, drive)
    end
    for _, drive in ipairs(drives.bottom) do
        table.insert(RAM_DRIVES, drive)
    end
    
    -- RAID A (LEFT) + RAID B (RIGHT) = 4 drives for persistent storage  
    for _, drive in ipairs(drives.left) do
        table.insert(RAID_DRIVES, drive)
    end
    for _, drive in ipairs(drives.right) do
        table.insert(RAID_DRIVES, drive)
    end
    
    print(string.format("Found %d RAM drives, %d RAID drives", #RAM_DRIVES, #RAID_DRIVES))
    
    -- Show actual mount paths for debugging
    print("RAM drives (mount paths):")
    for i, drive in ipairs(RAM_DRIVES) do
        print("  [" .. i .. "] " .. drive)
    end
    
    if #RAM_DRIVES == 0 then
        error("No RAM drives found! Need BACK or BOTTOM drives.")
    end
    
    -- Clear all RAM drives and create swap directories
    for _, drive in ipairs(RAM_DRIVES) do
        if fs.exists(drive .. "/swap") then
            fs.delete(drive .. "/swap")
        end
        local ok = fs.makeDir(drive .. "/swap")
        if not fs.exists(drive .. "/swap") then
            print("WARNING: Could not create " .. drive .. "/swap")
        end
    end
end

-- Get next RAM drive (rotate through all 6)
local function getNextRAMDrive()
    local drive = RAM_DRIVES[current_ram_drive]
    current_ram_drive = (current_ram_drive % #RAM_DRIVES) + 1
    return drive
end

-- Write to rotating RAM drive
local function swapWrite(key, data, drive)
    local path = drive .. "/swap/" .. key
    local f = fs.open(path, "w")
    if not f then return false end
    for k, v in pairs(data) do
        f.writeLine(k .. "=" .. tostring(v))
    end
    f.close()
    return true
end

-- Read from RAM drive
local function swapRead(key, drive)
    local path = drive .. "/swap/" .. key
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    if not f then return nil end
    local data = {}
    while true do
        local line = f.readLine()
        if not line then break end
        local k, v = line:match("([^=]+)=(.*)")
        if k then
            data[k] = tonumber(v) or v
        end
    end
    f.close()
    return data
end

-- Personality functions (simple key=value format, no serialize!)
local function writePersonality(id, role, traits, metrics, drive)
    local f = fs.open(drive .. "/swap/p_" .. id, "w")
    if not f then return false end
    f.writeLine("role=" .. role)
    for k, v in pairs(traits) do
        f.writeLine("trait_" .. k .. "=" .. tostring(v))
    end
    for k, v in pairs(metrics) do
        f.writeLine("metric_" .. k .. "=" .. tostring(v))
    end
    f.close()
    return true
end

local function readPersonality(id, drive)
    local path = drive .. "/swap/p_" .. id
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    if not f then return nil end
    local role, traits, metrics = nil, {}, {}
    while true do
        local line = f.readLine()
        if not line then break end
        local k, v = line:match("([^=]+)=(.*)")
        if k == "role" then
            role = v
        elseif k:match("^trait_") then
            traits[k:sub(7)] = tonumber(v) or v
        elseif k:match("^metric_") then
            metrics[k:sub(8)] = tonumber(v) or v
        end
    end
    f.close()
    return {id = id, role = role, traits = traits, metrics = metrics}
end

-- Context functions (spread across drives)
local conv_to_drive = {}  -- Track which drive has which conversation

local function writeContext(conv_id, topic, emotion, depth, qstreak, exchanges)
    local drive = getNextRAMDrive()  -- Rotate!
    conv_to_drive[conv_id] = drive
    
    -- Ensure swap directory exists
    if not fs.exists(drive .. "/swap") then
        fs.makeDir(drive .. "/swap")
    end
    
    local f = fs.open(drive .. "/swap/c_" .. conv_id, "w")
    if not f then
        -- Fallback: try computer root
        f = fs.open("swap_c_" .. conv_id, "w")
        if not f then
            return false  -- Can't write anywhere
        end
    end
    f.writeLine(topic)
    f.writeLine(emotion)
    f.writeLine(tostring(depth))
    f.writeLine(tostring(qstreak))
    f.writeLine(tostring(#exchanges))
    for _, ex in ipairs(exchanges) do
        f.writeLine(ex.speaker)
        f.writeLine(ex.message:gsub("\n", "\\n"))
    end
    f.close()
    return true
end

local function readContext(conv_id)
    local drive = conv_to_drive[conv_id]
    if not drive then return nil end
    
    local path = drive .. "/swap/c_" .. conv_id
    if not fs.exists(path) then return nil end
    
    local f = fs.open(path, "r")
    if not f then return nil end
    
    local topic = f.readLine()
    local emotion = f.readLine()
    local depth = tonumber(f.readLine() or "0")
    local qstreak = tonumber(f.readLine() or "0")
    local count = tonumber(f.readLine() or "0")
    local exchanges = {}
    for i = 1, count do
        local speaker = f.readLine()
        local msg_line = f.readLine()
        if speaker and msg_line then
            local message = msg_line:gsub("\\n", "\n")
            table.insert(exchanges, {speaker = speaker, message = message})
        end
    end
    f.close()
    
    return {id = conv_id, current_topic = topic, emotional_state = emotion, 
            depth = depth, question_streak = qstreak, recent_exchanges = exchanges}
end

local function deleteContext(conv_id)
    local drive = conv_to_drive[conv_id]
    if drive and fs.exists(drive .. "/swap/c_" .. conv_id) then
        fs.delete(drive .. "/swap/c_" .. conv_id)
    end
    conv_to_drive[conv_id] = nil
end

-- Progress tracking (on RAID drives)
local raid = nil

local function initRAID()
    if not raid then
        local success, module = pcall(require, "raid_system")
        if success then
            raid = module
            raid.init()
        end
    end
end

local function saveProgress(completed, total, s_conf, t_conf)
    initRAID()
    local content = table.concat({
        tostring(completed),
        tostring(total),
        tostring(s_conf),
        tostring(t_conf)
    }, "\n")
    
    if raid then
        pcall(function() raid.write("training/progress.txt", content) end)
    else
        if not fs.exists("/training") then fs.makeDir("/training") end
        local f = fs.open("/training/progress.txt", "w")
        if f then
            f.write(content)
            f.close()
        end
    end
end

local function loadProgress()
    initRAID()
    local content = nil
    
    if raid and raid.exists("training/progress.txt") then
        local ok, result = pcall(function() return raid.read("training/progress.txt") end)
        if ok then content = result end
    elseif fs.exists("/training/progress.txt") then
        local f = fs.open("/training/progress.txt", "r")
        if f then
            content = f.readAll()
            f.close()
        end
    end
    
    if not content then
        return 0, 0, 0.5, 0.7
    end
    
    local lines = {}
    for line in content:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    return tonumber(lines[1]) or 0, 
           tonumber(lines[2]) or 0,
           tonumber(lines[3]) or 0.5,
           tonumber(lines[4]) or 0.7
end

-- AI functions (simplified)
local function createPersonality(id, role, conf, drive)
    local traits = {}
    if role == "student" then
        traits = {curiosity=0.8, enthusiasm=0.7, depth=0.5, humor=0.4, creativity=0.6}
    else
        traits = {helpfulness=0.9, patience=0.8, depth=0.7, clarity=0.8, encouragement=0.9}
    end
    local metrics = {conversations=0, successful_exchanges=0, confidence=conf, learning_rate=1.0}
    writePersonality(id, role, traits, metrics, drive)
    return {id = id, drive = drive}
end

local function evolvePersonality(handle, success, engagement)
    local p = readPersonality(handle.id, handle.drive)
    
    -- If personality couldn't be read, create default
    if not p then
        p = {
            role = handle.id,
            traits = {curiosity = 0.5, helpfulness = 0.5, patience = 0.5, creativity = 0.5, formality = 0.5},
            metrics = {conversations = 0, successful_exchanges = 0, confidence = 0.5, learning_rate = 1.0}
        }
    end
    
    if success then
        p.metrics.confidence = math.min(1.0, (p.metrics.confidence or 0.5) + 0.002)
        p.metrics.successful_exchanges = (p.metrics.successful_exchanges or 0) + 1
    end
    if engagement > 0.7 then
        if p.traits.curiosity then
            p.traits.curiosity = math.min(1.0, p.traits.curiosity + 0.005)
        end
        if p.traits.helpfulness then
            p.traits.helpfulness = math.min(1.0, p.traits.helpfulness + 0.003)
        end
    end
    p.metrics.conversations = (p.metrics.conversations or 0) + 1
    writePersonality(handle.id, p.role, p.traits, p.metrics, handle.drive)
    return p
end

local function createContext(conv_id)
    writeContext(conv_id, "general", "neutral", 0, 0, {})
    return {id = conv_id}
end

local function addExchange(conv_id, speaker, message)
    local ctx = readContext(conv_id)
    
    -- If context couldn't be read, create a fresh one
    if not ctx then
        ctx = {
            id = conv_id,
            current_topic = "general",
            emotional_state = "neutral",
            depth = 0,
            question_streak = 0,
            recent_exchanges = {}
        }
    end
    
    table.insert(ctx.recent_exchanges, {speaker=speaker, message=message})
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

-- Templates (loaded once)
local ST = {
    g = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?", "Yo! Ready to learn?"},
    q = {"How does that work?", "Can you explain more?", "What do you mean?", "Why is that important?", "What's the best way?"},
    r = {"That's interesting!", "Oh I see!", "That makes sense!", "Cool, thanks!"},
    a = {"Got it!", "I understand!", "Makes sense!", "Awesome!"},
    d = {"What's the underlying principle?", "How does this connect?"}
}

local TT = {
    g = {"Hey! Ready to learn?", "Hi! What would you like to know?"},
    e = {"Great question! Let me explain.", "Think of it like organizing information.", "The key is how parts work together."},
    c = {"You're getting it!", "Exactly!", "Perfect!"},
    f = {"Make sense?", "Questions?", "Got it?"}
}

local function choose(list)
    return list[math.random(#list)]
end

local function generateResponse(role, ctx, traits)
    -- Ensure ctx has required fields
    ctx = ctx or {}
    ctx.recent_exchanges = ctx.recent_exchanges or {}
    ctx.depth = ctx.depth or 0
    traits = traits or {curiosity = 0.5}
    
    local last_msg = #ctx.recent_exchanges > 0 and ctx.recent_exchanges[#ctx.recent_exchanges].message or nil
    local is_q = last_msg and last_msg:find("?") ~= nil
    
    if role == "student" then
        if not last_msg then return choose(ST.g)
        elseif is_q then
            local r = choose(ST.a)
            if math.random() < traits.curiosity then
                r = r .. " " .. choose(ST.q)
            end
            return r
        elseif ctx.depth > 5 and math.random() < 0.4 then return choose(ST.r)
        else return choose(ST.q)
        end
    else
        if is_q then
            local r = choose(TT.e)
            if math.random() < 0.3 then r = r .. " " .. choose(TT.f) end
            return r
        else return choose(TT.c)
        end
    end
end

-- Main batch training (now with 6-drive rotation!)
function M.runBatch(start_conv, end_conv, turns, s_conf, t_conf)
    initRAID()
    
    -- Use first RAM drive for personalities (they're small)
    local student = createPersonality("student", "student", s_conf, RAM_DRIVES[1])
    local teacher = createPersonality("teacher", "teacher", t_conf, RAM_DRIVES[1])
    
    -- Initialize CSV log
    local csv_data = ""
    if start_conv == 1 then
        csv_data = "speaker_a|message_a|speaker_b|message_b|topic|emotion|turn|depth\n"
    else
        -- Load existing data if appending
        if raid and raid.exists("training/conversation_log.csv") then
            local ok, result = pcall(function() return raid.read("training/conversation_log.csv") end)
            if ok and result then csv_data = result end
        elseif fs.exists("/training/conversation_log.csv") then
            local f = fs.open("/training/conversation_log.csv", "r")
            if f then
                csv_data = f.readAll()
                f.close()
            end
        end
    end
    
    local start_time = os.clock()
    local total = 0
    local log_buffer = {}  -- Buffer lines before writing to RAID
    
    for conv = start_conv, end_conv do
        local ctx_id = "c" .. conv
        createContext(ctx_id)  -- Auto-rotates to next RAM drive!
        
        local s_p = readPersonality("student", student.drive)
        local t_p = readPersonality("teacher", teacher.drive)
        
        -- Default traits if personality read failed
        local s_traits = s_p and s_p.traits or {curiosity=0.7, helpfulness=0.6, patience=0.6, creativity=0.8, formality=0.3}
        local t_traits = t_p and t_p.traits or {curiosity=0.5, helpfulness=0.9, patience=0.8, creativity=0.6, formality=0.6}
        
        local init_ctx = readContext(ctx_id) or {
            id = ctx_id, current_topic = "general", emotional_state = "neutral",
            depth = 0, question_streak = 0, recent_exchanges = {}
        }
        local s_msg = generateResponse("student", init_ctx, s_traits)
        local ctx = addExchange(ctx_id, "Student", s_msg)
        
        for turn = 1, turns - 1 do
            local t_msg = generateResponse("teacher", ctx, t_traits)
            ctx = addExchange(ctx_id, "Teacher", t_msg)
            
            -- Build CSV line in buffer (pipe-delimited)
            local line = "Student|" .. s_msg .. "|Teacher|" .. t_msg .. "|" ..
                        (ctx.current_topic or "general") .. "|" .. (ctx.emotional_state or "neutral") .. "|" ..
                        tostring(turn) .. "|" .. tostring(ctx.depth or 0) .. "\n"
            table.insert(log_buffer, line)
            
            s_msg = generateResponse("student", ctx, s_traits)
            ctx = addExchange(ctx_id, "Student", s_msg)
            total = total + 1
        end
        
        s_p = evolvePersonality(student, true, 0.8)
        t_p = evolvePersonality(teacher, true, 0.9)
        
        deleteContext(ctx_id)
        
        -- Write buffer to RAID every 50 conversations to avoid memory buildup
        if (conv - start_conv + 1) % 50 == 0 then
            csv_data = csv_data .. table.concat(log_buffer)
            if raid then
                pcall(function() raid.write("training/conversation_log.csv", csv_data) end)
            else
                if not fs.exists("/training") then fs.makeDir("/training") end
                local f = fs.open("/training/conversation_log.csv", "w")
                if f then
                    f.write(csv_data)
                    f.close()
                end
            end
            log_buffer = {}  -- Clear buffer
        end
        
        if (conv - start_conv + 1) % 100 == 0 then
            print(string.format("Batch: %d/%d", conv - start_conv + 1, end_conv - start_conv + 1))
        end
        
        if (conv - start_conv + 1) % 25 == 0 then
            os.sleep(0)
        end
    end
    
    -- Final write of remaining buffer
    if #log_buffer > 0 then
        csv_data = csv_data .. table.concat(log_buffer)
        if raid then
            pcall(function() raid.write("training/conversation_log.csv", csv_data) end)
        else
            if not fs.exists("/training") then fs.makeDir("/training") end
            local f = fs.open("/training/conversation_log.csv", "w")
            if f then
                f.write(csv_data)
                f.close()
            end
        end
    end
    
    local final_s = readPersonality("student", student.drive)
    local final_t = readPersonality("teacher", teacher.drive)
    
    local s_conf = final_s and final_s.metrics and final_s.metrics.confidence or 0.5
    local t_conf = final_t and final_t.metrics and final_t.metrics.confidence or 0.5
    
    print(string.format("Batch complete: %d conversations, %.1f sec", end_conv - start_conv + 1, os.clock() - start_time))
    
    return total, s_conf, t_conf
end

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local total_conversations = options.conversations or 1000
    local turns = options.turns or 8
    local BATCH_SIZE = 600  -- Increased from 300! We have 6 drives now!
    
    print("=== MULTI-DRIVE TRAINING SYSTEM ===")
    initDrives()
    print(string.format("Total: %d conversations", total_conversations))
    print(string.format("Batch size: %d (6-drive rotation)", BATCH_SIZE))
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
            print("Next batch starting...")
            os.sleep(0.5)
        end
    end
    
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total: %d conversations", completed))
    fs.delete("/training/progress.txt")
    
    -- Cleanup all RAM drives
    for _, drive in ipairs(RAM_DRIVES) do
        if fs.exists(drive .. "/swap") then
            fs.delete(drive .. "/swap")
        end
    end
    
    return {exchanges = completed * (turns - 1), student_confidence = s_conf, teacher_confidence = t_conf}
end

function M.run()
    print("=== AI TRAINER (MULTI-DRIVE) ===")
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
