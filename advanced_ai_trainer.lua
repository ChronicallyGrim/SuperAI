-- advanced_ai_trainer.lua (ZERO COMPROMISE - Manual encoding, no serialize!)
-- Writes raw data structures manually to avoid ALL serialize() calls during training

local M = {}

local SWAP_DISK = "disk4"

-- ============================================================================
-- MANUAL DATA ENCODING - NO SERIALIZE!
-- ============================================================================

-- Write personality manually (NO serialize!)
local function writePersonality(id, role, traits, metrics)
    local f = fs.open(SWAP_DISK .. "/p_" .. id, "w")
    f.writeLine(role)
    -- Traits (5 values for student, 5 for teacher)
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
    -- Metrics
    f.writeLine(tostring(metrics.conversations))
    f.writeLine(tostring(metrics.successful_exchanges))
    f.writeLine(tostring(metrics.confidence))
    f.writeLine(tostring(metrics.learning_rate))
    f.close()
end

-- Read personality manually
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

-- Write context manually (NO serialize!)
local function writeContext(id, topic, emotional_state, depth, question_streak, exchanges)
    local f = fs.open(SWAP_DISK .. "/c_" .. id, "w")
    f.writeLine(topic)
    f.writeLine(emotional_state)
    f.writeLine(tostring(depth))
    f.writeLine(tostring(question_streak))
    f.writeLine(tostring(#exchanges))
    for _, ex in ipairs(exchanges) do
        f.writeLine(ex.speaker)
        f.writeLine(ex.message:gsub("\n", "\\n"))  -- Escape newlines
    end
    f.close()
end

-- Read context manually
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
    
    return {
        id = id,
        current_topic = topic,
        emotional_state = emotional_state,
        depth = depth,
        question_streak = question_streak,
        recent_exchanges = exchanges
    }
end

-- ============================================================================
-- PERSONALITY SYSTEM
-- ============================================================================

local function createPersonality(id, role)
    local traits = {}
    local metrics = {
        conversations = 0,
        successful_exchanges = 0,
        confidence = role == "student" and 0.5 or 0.7,
        learning_rate = 1.0
    }
    
    if role == "student" then
        traits = {
            curiosity = 0.8,
            enthusiasm = 0.7,
            depth = 0.5,
            humor = 0.4,
            creativity = 0.6
        }
    else
        traits = {
            helpfulness = 0.9,
            patience = 0.8,
            depth = 0.7,
            clarity = 0.8,
            encouragement = 0.9
        }
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

-- ============================================================================
-- CONTEXT SYSTEM
-- ============================================================================

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
    
    -- Topic detection
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") or msg_lower:find("function") then
        ctx.current_topic = "programming"
    elseif msg_lower:find("learn") or msg_lower:find("study") or msg_lower:find("understand") then
        ctx.current_topic = "learning"
    elseif msg_lower:find("think") or msg_lower:find("feel") or msg_lower:find("like") then
        ctx.current_topic = "personal"
    elseif msg_lower:find("ai") or msg_lower:find("intelligence") or msg_lower:find("neural") then
        ctx.current_topic = "ai"
    elseif msg_lower:find("game") or msg_lower:find("play") then
        ctx.current_topic = "gaming"
    end
    
    -- Emotional state
    if msg_lower:find("awesome") or msg_lower:find("great") or msg_lower:find("amazing") then
        ctx.emotional_state = "positive"
    elseif msg_lower:find("confus") or msg_lower:find("hard") or msg_lower:find("difficult") then
        ctx.emotional_state = "confused"
    elseif msg_lower:find("interest") or msg_lower:find("curious") or msg_lower:find("wonder") then
        ctx.emotional_state = "curious"
    elseif msg_lower:find("frustrat") or msg_lower:find("annoying") then
        ctx.emotional_state = "frustrated"
    else
        ctx.emotional_state = "neutral"
    end
    
    ctx.depth = ctx.depth + 1
    ctx.question_streak = message:find("?") and (ctx.question_streak + 1) or 0
    
    writeContext(ctx.id, ctx.current_topic, ctx.emotional_state, ctx.depth, ctx.question_streak, ctx.recent_exchanges)
    return ctx
end

-- ============================================================================
-- RESPONSE TEMPLATES (Loaded once, reused)
-- ============================================================================

local STUDENT_TEMPLATES = {
    greetings = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?", "Yo! Ready to learn?"},
    questions = {"How does that work exactly?", "Can you explain that more?", "What do you mean by that?", "Why is that important?", "What's the best way to learn that?", "Is there more to it?", "What are the key concepts?", "How would I use that?", "Can you give an example?"},
    reactions = {"That's really interesting!", "Oh, I see what you mean!", "That makes a lot of sense!", "I never thought about it that way!", "Cool, thanks for explaining!", "Wow, that's fascinating!", "This is really helpful!", "Ah, now I get it!"},
    acknowledgments = {"Got it!", "I understand!", "That helps!", "Makes sense!", "Awesome!", "Oh I see!", "That's clear!", "Perfect!"},
    deep_questions = {"What's the underlying principle?", "How does this connect to other concepts?", "What are the real-world applications?", "Why did they design it that way?"}
}

local TEACHER_TEMPLATES = {
    greetings = {"Hey! Ready to learn?", "Hi there! What would you like to know?", "Hello! Let's dive in!"},
    explanations = {"Great question! Let me break that down for you.", "Think of it this way: it's like organizing information efficiently.", "The key concept here is understanding how the parts work together.", "It's simpler than it sounds once you see the pattern.", "Let me explain it step by step.", "Here's a good way to think about it.", "The important thing to understand is this.", "Imagine it like this."},
    encouragements = {"You're getting it!", "Exactly right!", "Good thinking!", "Perfect!", "That's the idea!", "You've got it!", "Well done!", "Spot on!"},
    follow_ups = {"Does that make sense?", "Want me to explain more?", "Any questions about that?", "Ready to move on?", "Got it?", "Is that clear?"},
    elaborations = {"To add to that,", "Another way to think about it:", "Building on that idea:", "Here's an interesting detail:"}
}

local function choose(list)
    return list[math.random(#list)]
end

-- ============================================================================
-- RESPONSE GENERATOR
-- ============================================================================

local function generateResponse(personality_id, context_id, role, traits)
    local ctx = readContext(context_id)
    local last_msg = #ctx.recent_exchanges > 0 and ctx.recent_exchanges[#ctx.recent_exchanges].message or nil
    local is_question = last_msg and last_msg:find("?") ~= nil
    
    local response = ""
    
    if role == "student" then
        if not last_msg then
            response = choose(STUDENT_TEMPLATES.greetings)
        elseif is_question then
            response = choose(STUDENT_TEMPLATES.acknowledgments)
            if math.random() < traits.curiosity then
                if ctx.depth > 7 and math.random() < 0.3 then
                    response = response .. " " .. choose(STUDENT_TEMPLATES.deep_questions)
                else
                    response = response .. " " .. choose(STUDENT_TEMPLATES.questions)
                end
            end
        elseif ctx.depth > 5 and math.random() < 0.4 then
            response = choose(STUDENT_TEMPLATES.reactions)
        else
            response = choose(STUDENT_TEMPLATES.questions)
        end
    else
        if is_question then
            response = choose(TEACHER_TEMPLATES.explanations)
            if ctx.depth > 6 and math.random() < 0.2 then
                response = choose(TEACHER_TEMPLATES.elaborations) .. " " .. response:lower()
            end
            if math.random() < 0.3 and ctx.question_streak < 2 then
                response = response .. " " .. choose(TEACHER_TEMPLATES.follow_ups)
            end
        else
            response = choose(TEACHER_TEMPLATES.encouragements)
        end
    end
    
    return response
end

-- ============================================================================
-- CSV LOGGING
-- ============================================================================

local function csvEscape(str)
    return '"' .. str:gsub('"', '""') .. '"'
end

-- ============================================================================
-- MAIN TRAINING
-- ============================================================================

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local num = options.conversations or 1000
    local turns = options.turns or 8
    
    print("=== ADVANCED AI TRAINING (ZERO COMPROMISE) ===")
    print("")
    
    if not fs.exists(SWAP_DISK) then
        print("ERROR: Swap disk not found!")
        return {exchanges = 0}
    end
    
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    fs.makeDir(SWAP_DISK .. "/swap")
    
    print("Virtual memory ready! (Manual encoding, NO serialize!)")
    print(string.format("Training: %d conversations", num))
    print("Full intelligence: 5-exchange context, 5 emotions, 5 topics, 40+ templates")
    print("")
    
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    local start = os.clock()
    local total = 0
    
    -- Create personalities
    local student = createPersonality("student", "student")
    local teacher = createPersonality("teacher", "teacher")
    
    local log = fs.open("/training/conversation_log.csv", "w")
    log.writeLine("speaker_a,message_a,speaker_b,message_b,topic,emotion,turn,depth")
    log.close()
    
    for conv = 1, num do
        local ctx_id = "conv" .. conv
        createContext(ctx_id)
        
        -- Get initial traits
        local s_p = readPersonality("student")
        local t_p = readPersonality("teacher")
        
        local s_msg = generateResponse("student", ctx_id, "student", s_p.traits)
        local ctx = addExchange(ctx_id, "Student", s_msg)
        
        -- Open log in append mode for THIS conversation
        log = fs.open("/training/conversation_log.csv", "a")
        
        for turn = 1, turns - 1 do
            local t_msg = generateResponse("teacher", ctx_id, "teacher", t_p.traits)
            ctx = addExchange(ctx_id, "Teacher", t_msg)
            
            -- Write each field separately to avoid string concatenation in memory
            log.write(csvEscape("Student"))
            log.write(",")
            log.write(csvEscape(s_msg))
            log.write(",")
            log.write(csvEscape("Teacher"))
            log.write(",")
            log.write(csvEscape(t_msg))
            log.write(",")
            log.write(csvEscape(ctx.current_topic))
            log.write(",")
            log.write(csvEscape(ctx.emotional_state))
            log.write(",")
            log.write(tostring(turn))
            log.write(",")
            log.write(tostring(ctx.depth))
            log.write("\n")
            
            s_msg = generateResponse("student", ctx_id, "student", s_p.traits)
            ctx = addExchange(ctx_id, "Student", s_msg)
            total = total + 1
        end
        
        -- Close after each conversation to flush buffer
        log.close()
        log = nil
        
        -- Evolve
        s_p = evolvePersonality("student", "student", true, 0.8)
        t_p = evolvePersonality("teacher", "teacher", true, 0.9)
        
        -- Delete context
        if fs.exists(SWAP_DISK .. "/c_conv" .. conv) then
            fs.delete(SWAP_DISK .. "/c_conv" .. conv)
        end
        
        if conv % 100 == 0 then
            local elapsed = os.clock() - start
            local eta = (num - conv) / (conv / elapsed)
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num, (conv/num)*100, eta))
            print(string.format("  Student: %.3f | Teacher: %.3f", s_p.metrics.confidence, t_p.metrics.confidence))
        end
        
        if conv % 50 == 0 then
            os.sleep(0.05)
        end
    end
    
    -- No need to close log - already closed after each conversation
    
    -- Final save (NOW we can use serialize safely)
    local final_s = readPersonality("student")
    local final_t = readPersonality("teacher")
    
    local sf = fs.open("/training/student_ai.dat", "w")
    sf.write(textutils.serialize(final_s))
    sf.close()
    
    local tf = fs.open("/training/teacher_ai.dat", "w")
    tf.write(textutils.serialize(final_t))
    tf.close()
    
    -- Cleanup
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    
    print("")
    print("=== COMPLETE ===")
    print(string.format("Exchanges: %d | Time: %.1f sec", total, os.clock() - start))
    print("Quality: MAXIMUM (zero compromises)")
    
    return {exchanges = total, student_confidence = final_s.metrics.confidence, teacher_confidence = final_t.metrics.confidence}
end

function M.run()
    print("=== AI TRAINER (ZERO COMPROMISE) ===")
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
