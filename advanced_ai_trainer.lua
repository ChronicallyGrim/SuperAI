-- advanced_ai_trainer.lua (ULTIMATE - Full Intelligence + No Memory Limits)
-- Virtual memory for ALL data structures + CSV logging to avoid serialize()

local M = {}

local SWAP_DISK = "disk4"  -- RIGHT drive used as virtual RAM

-- ============================================================================
-- DISK-BACKED VIRTUAL MEMORY - NO RAM USAGE!
-- ============================================================================

local function swapWrite(key, data)
    local file = fs.open(SWAP_DISK .. "/swap/" .. key, "w")
    file.write(textutils.serialize(data))
    file.close()
end

local function swapRead(key)
    local path = SWAP_DISK .. "/swap/" .. key
    if not fs.exists(path) then return nil end
    local file = fs.open(path, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
end

local function swapDelete(key)
    if fs.exists(SWAP_DISK .. "/swap/" .. key) then
        fs.delete(SWAP_DISK .. "/swap/" .. key)
    end
end

-- ============================================================================
-- FULL PERSONALITY SYSTEM (100% disk-backed)
-- ============================================================================

local function createPersonality(id, role)
    local personality = {
        id = id,
        role = role,
        traits = {},
        recent_topics = {},
        metrics = {
            conversations = 0,
            successful_exchanges = 0,
            confidence = role == "student" and 0.5 or 0.7,
            learning_rate = 1.0
        }
    }
    
    if role == "student" then
        personality.traits = {
            curiosity = 0.8,
            enthusiasm = 0.7,
            depth = 0.5,
            humor = 0.4,
            creativity = 0.6
        }
    else
        personality.traits = {
            helpfulness = 0.9,
            patience = 0.8,
            depth = 0.7,
            clarity = 0.8,
            encouragement = 0.9
        }
    end
    
    swapWrite("personality_" .. id, personality)
    return {id = id}  -- Only ID in RAM!
end

local function getPersonality(handle)
    return swapRead("personality_" .. handle.id)
end

local function updatePersonality(handle, personality)
    swapWrite("personality_" .. handle.id, personality)
end

local function evolvePersonality(handle, success, engagement)
    local p = getPersonality(handle)
    if success then
        p.metrics.confidence = math.min(1.0, p.metrics.confidence + 0.002)
        p.metrics.successful_exchanges = p.metrics.successful_exchanges + 1
    end
    if engagement > 0.7 then
        p.traits.curiosity = math.min(1.0, p.traits.curiosity + 0.005)
    end
    p.metrics.conversations = p.metrics.conversations + 1
    updatePersonality(handle, p)
end

-- ============================================================================
-- CONVERSATION CONTEXT (Full 5-exchange history on disk)
-- ============================================================================

local function createContext(id)
    local context = {
        id = id,
        recent_exchanges = {},  -- Last 5 exchanges
        current_topic = "general",
        emotional_state = "neutral",
        depth = 0,
        question_streak = 0
    }
    swapWrite("context_" .. id, context)
    return {id = id}
end

local function getContext(handle)
    return swapRead("context_" .. handle.id)
end

local function updateContext(handle, context)
    swapWrite("context_" .. handle.id, context)
end

local function addExchange(context_handle, speaker, message)
    local ctx = getContext(context_handle)
    
    table.insert(ctx.recent_exchanges, {
        speaker = speaker,
        message = message,
        timestamp = os.clock()
    })
    
    -- Keep last 5 exchanges
    if #ctx.recent_exchanges > 5 then
        table.remove(ctx.recent_exchanges, 1)
    end
    
    -- Advanced topic detection
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") or msg_lower:find("function") or msg_lower:find("variable") then
        ctx.current_topic = "programming"
    elseif msg_lower:find("learn") or msg_lower:find("study") or msg_lower:find("understand") or msg_lower:find("teach") then
        ctx.current_topic = "learning"
    elseif msg_lower:find("think") or msg_lower:find("feel") or msg_lower:find("like") or msg_lower:find("prefer") then
        ctx.current_topic = "personal"
    elseif msg_lower:find("ai") or msg_lower:find("intelligence") or msg_lower:find("neural") or msg_lower:find("machine") then
        ctx.current_topic = "ai"
    elseif msg_lower:find("game") or msg_lower:find("play") or msg_lower:find("minecraft") then
        ctx.current_topic = "gaming"
    end
    
    -- Emotional state detection
    if msg_lower:find("awesome") or msg_lower:find("great") or msg_lower:find("amazing") or msg_lower:find("love") then
        ctx.emotional_state = "positive"
    elseif msg_lower:find("confus") or msg_lower:find("hard") or msg_lower:find("difficult") or msg_lower:find("stuck") then
        ctx.emotional_state = "confused"
    elseif msg_lower:find("interest") or msg_lower:find("curious") or msg_lower:find("wonder") or msg_lower:find("how") then
        ctx.emotional_state = "curious"
    elseif msg_lower:find("frustrat") or msg_lower:find("annoying") or msg_lower:find("tired") then
        ctx.emotional_state = "frustrated"
    else
        ctx.emotional_state = "neutral"
    end
    
    ctx.depth = ctx.depth + 1
    
    if message:find("?") then
        ctx.question_streak = ctx.question_streak + 1
    else
        ctx.question_streak = 0
    end
    
    updateContext(context_handle, ctx)
end

-- ============================================================================
-- INTELLIGENT RESPONSE GENERATOR (Full templates, all on disk!)
-- ============================================================================

local function loadTemplates(role)
    if role == "student" then
        return {
            greetings = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?", "Yo! Ready to learn?", "Hey there! What are we learning today?"},
            questions = {
                "How does that work exactly?",
                "Can you explain that more?",
                "What do you mean by that?",
                "Why is that important?",
                "What's the best way to learn that?",
                "Is there more to it?",
                "What are the key concepts?",
                "How would I use that?",
                "Can you give an example?",
                "What makes that different?"
            },
            reactions = {
                "That's really interesting!",
                "Oh, I see what you mean!",
                "That makes a lot of sense!",
                "I never thought about it that way!",
                "Cool, thanks for explaining!",
                "Wow, that's fascinating!",
                "This is really helpful!",
                "Ah, now I get it!",
                "That's actually pretty cool!",
                "Interesting perspective!"
            },
            acknowledgments = {
                "Got it!",
                "I understand!",
                "That helps!",
                "Makes sense!",
                "Awesome!",
                "Oh I see!",
                "That's clear!",
                "Perfect!",
                "Okay!",
                "Right!"
            },
            deep_questions = {
                "What's the underlying principle?",
                "How does this connect to other concepts?",
                "What are the real-world applications?",
                "Why did they design it that way?",
                "What problems does this solve?"
            }
        }
    else
        return {
            greetings = {"Hey! Ready to learn?", "Hi there! What would you like to know?", "Hello! Let's dive in!", "Great to see you! What should we explore?"},
            explanations = {
                "Great question! Let me break that down for you.",
                "Think of it this way: it's like organizing information efficiently.",
                "The key concept here is understanding how the parts work together.",
                "It's simpler than it sounds once you see the pattern.",
                "Let me explain it step by step.",
                "Here's a good way to think about it.",
                "The important thing to understand is this.",
                "Imagine it like this.",
                "The core idea is actually quite elegant.",
                "Let me give you a clearer picture."
            },
            encouragements = {
                "You're getting it!",
                "Exactly right!",
                "Good thinking!",
                "Perfect!",
                "That's the idea!",
                "You've got it!",
                "Well done!",
                "Spot on!",
                "Nice!",
                "Great insight!"
            },
            follow_ups = {
                "Does that make sense?",
                "Want me to explain more?",
                "Any questions about that?",
                "Ready to move on?",
                "Got it?",
                "Is that clear?",
                "Need another example?",
                "Want to dive deeper?",
                "Make sense so far?",
                "Following along?"
            },
            elaborations = {
                "To add to that,",
                "Another way to think about it:",
                "Building on that idea,",
                "Here's an interesting detail:",
                "What's also cool is"
            }
        }
    end
end

local function chooseRandom(list)
    return list[math.random(#list)]
end

local function generateResponse(personality_handle, context_handle)
    local personality = getPersonality(personality_handle)
    local context = getContext(context_handle)
    local templates = loadTemplates(personality.role)
    
    local last_msg = #context.recent_exchanges > 0 and 
        context.recent_exchanges[#context.recent_exchanges].message or nil
    local is_question = last_msg and last_msg:find("?") ~= nil
    
    local response = ""
    
    if personality.role == "student" then
        -- Greeting
        if not last_msg then
            response = chooseRandom(templates.greetings)
        
        -- Answering question
        elseif is_question then
            response = chooseRandom(templates.acknowledgments)
            
            if math.random() < personality.traits.curiosity then
                if context.depth > 7 and math.random() < 0.3 then
                    response = response .. " " .. chooseRandom(templates.deep_questions)
                else
                    response = response .. " " .. chooseRandom(templates.questions)
                end
            end
        
        -- Deep conversation reaction
        elseif context.depth > 5 and math.random() < 0.4 then
            response = chooseRandom(templates.reactions)
        
        -- Regular questions
        else
            if context.depth > 8 and math.random() < 0.25 then
                response = chooseRandom(templates.deep_questions)
            else
                response = chooseRandom(templates.questions)
            end
        end
        
    else -- teacher
        if is_question then
            response = chooseRandom(templates.explanations)
            
            if context.depth > 6 and math.random() < 0.2 then
                response = chooseRandom(templates.elaborations) .. " " .. response:lower()
            end
            
            if math.random() < 0.3 and context.question_streak < 2 then
                response = response .. " " .. chooseRandom(templates.follow_ups)
            end
        else
            response = chooseRandom(templates.encouragements)
        end
    end
    
    templates = nil  -- Clear templates from RAM
    return response
end

-- ============================================================================
-- CSV LOGGING (NO serialize() - the memory killer!)
-- ============================================================================

local function csvEscape(str)
    return '"' .. str:gsub('"', '""') .. '"'
end

-- ============================================================================
-- MAIN TRAINING SESSION
-- ============================================================================

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local num_conversations = options.conversations or 1000
    local turns_per_conversation = options.turns or 8
    
    print("=== ADVANCED AI TRAINING (ULTIMATE) ===")
    print("")
    print("Initializing virtual memory system...")
    
    if not fs.exists(SWAP_DISK) then
        print("ERROR: Swap disk (" .. SWAP_DISK .. ") not found!")
        print("Please insert a disk in the RIGHT drive.")
        return {exchanges = 0, error = "No swap disk"}
    end
    
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    fs.makeDir(SWAP_DISK .. "/swap")
    
    print("Virtual memory ready! (Using " .. SWAP_DISK .. " as swap)")
    print("")
    
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    print(string.format("Training: %d conversations x %d turns", num_conversations, turns_per_conversation))
    print("Full intelligence: 5-exchange context, emotional states, 50+ templates")
    print("")
    
    local start_time = os.clock()
    local total_exchanges = 0
    
    -- Create AI personalities (tiny handles in RAM, full data on disk!)
    local student = createPersonality("student", "student")
    local teacher = createPersonality("teacher", "teacher")
    
    -- CSV log (no serialize!)
    local log_file = fs.open("/training/conversation_log.csv", "w")
    log_file.writeLine("speaker_a,message_a,speaker_b,message_b,topic,emotional_state,turn,depth")
    
    for conv = 1, num_conversations do
        -- Create context (on disk!)
        local context = createContext("conv_" .. conv)
        
        -- Student starts
        local student_msg = generateResponse(student, context)
        addExchange(context, "Student", student_msg)
        
        for turn = 1, turns_per_conversation - 1 do
            -- Teacher responds
            local teacher_msg = generateResponse(teacher, context)
            addExchange(context, "Teacher", teacher_msg)
            
            -- Get context for logging
            local ctx = getContext(context)
            
            -- Write CSV (tiny memory footprint!)
            log_file.writeLine(
                csvEscape("Student") .. "," .. csvEscape(student_msg) .. "," ..
                csvEscape("Teacher") .. "," .. csvEscape(teacher_msg) .. "," ..
                csvEscape(ctx.current_topic) .. "," .. csvEscape(ctx.emotional_state) .. "," ..
                turn .. "," .. ctx.depth
            )
            
            -- Student responds
            student_msg = generateResponse(student, context)
            addExchange(context, "Student", student_msg)
            
            total_exchanges = total_exchanges + 1
        end
        
        -- Evolve personalities
        evolvePersonality(student, true, 0.8)
        evolvePersonality(teacher, true, 0.9)
        
        -- Clean up context
        swapDelete("context_conv_" .. conv)
        
        -- Progress
        if conv % 100 == 0 then
            local elapsed = os.clock() - start_time
            local eta = (num_conversations - conv) / (conv / elapsed)
            
            local s = getPersonality(student)
            local t = getPersonality(teacher)
            
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num_conversations, (conv/num_conversations)*100, eta))
            print(string.format("  Student: %.3f | Teacher: %.3f", s.metrics.confidence, t.metrics.confidence))
        end
        
        if conv % 50 == 0 then
            os.sleep(0.05)
        end
    end
    
    log_file.close()
    
    -- Save final states
    local final_student = getPersonality(student)
    local final_teacher = getPersonality(teacher)
    
    local sf = fs.open("/training/student_ai.dat", "w")
    sf.write(textutils.serialize(final_student))
    sf.close()
    
    local tf = fs.open("/training/teacher_ai.dat", "w")
    tf.write(textutils.serialize(final_teacher))
    tf.close()
    
    -- Clean up swap
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
    end
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total exchanges: %d", total_exchanges))
    print(string.format("Time: %.1f seconds (%.0f exchanges/sec)", 
        os.clock() - start_time, total_exchanges / (os.clock() - start_time)))
    print(string.format("Student confidence: %.3f | Teacher confidence: %.3f",
        final_student.metrics.confidence, final_teacher.metrics.confidence))
    print("Data quality: MAXIMUM (5-exchange context, emotional states, 50+ templates)")
    
    return {
        exchanges = total_exchanges,
        student_confidence = final_student.metrics.confidence,
        teacher_confidence = final_teacher.metrics.confidence
    }
end

function M.run()
    print("=== ADVANCED AI TRAINER (ULTIMATE) ===")
    print("")
    print("Uses " .. SWAP_DISK .. " (RIGHT drive) as virtual memory.")
    print("FULL intelligence - NO compromises!")
    print("")
    print("1. Quick (500 conversations)")
    print("2. Standard (2,000 conversations)")
    print("3. Deep (10,000 conversations)")
    print("4. ULTIMATE (50,000 conversations)")
    print("5. Exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        M.createAdvancedTrainingSession({conversations = 500, turns = 6})
    elseif choice == "2" then
        M.createAdvancedTrainingSession({conversations = 2000, turns = 8})
    elseif choice == "3" then
        M.createAdvancedTrainingSession({conversations = 10000, turns = 10})
    elseif choice == "4" then
        print("ULTIMATE training will take 1-2 hours!")
        write("Type YES to confirm: ")
        if read():upper() == "YES" then
            M.createAdvancedTrainingSession({conversations = 50000, turns = 12})
        end
    else
        print("Exiting...")
    end
end

return M
