-- advanced_ai_trainer.lua (Virtual Memory System)
-- Uses disk drive as RAM - FULL intelligence with NO memory limits!

local M = {}

-- ============================================================================
-- DISK-BACKED VIRTUAL MEMORY SYSTEM
-- ============================================================================

-- Which disk to use for virtual memory (swap)
local SWAP_DISK = "disk4"  -- RIGHT drive (or choose another)

local function initVirtualMemory()
    if not fs.exists(SWAP_DISK) then
        print("ERROR: Swap disk (" .. SWAP_DISK .. ") not found!")
        print("Please insert a disk in the RIGHT drive.")
        return false
    end
    
    -- Create swap directory
    if not fs.exists(SWAP_DISK .. "/swap") then
        fs.makeDir(SWAP_DISK .. "/swap")
    end
    
    return true
end

-- Store data to disk instead of RAM
local function swapWrite(key, data)
    local file = fs.open(SWAP_DISK .. "/swap/" .. key .. ".dat", "w")
    file.write(textutils.serialize(data))
    file.close()
end

-- Load data from disk
local function swapRead(key)
    local path = SWAP_DISK .. "/swap/" .. key .. ".dat"
    if not fs.exists(path) then
        return nil
    end
    
    local file = fs.open(path, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
end

-- Delete swap data
local function swapDelete(key)
    local path = SWAP_DISK .. "/swap/" .. key .. ".dat"
    if fs.exists(path) then
        fs.delete(path)
    end
end

-- Clear all swap
local function swapClear()
    if fs.exists(SWAP_DISK .. "/swap") then
        fs.delete(SWAP_DISK .. "/swap")
        fs.makeDir(SWAP_DISK .. "/swap")
    end
end

-- ============================================================================
-- FULL AI PERSONALITY SYSTEM (Now stored on disk!)
-- ============================================================================

local function createPersonality(id, role)
    local personality = {
        id = id,
        role = role,
        traits = {},
        knowledge = {},
        conversation_history = {},  -- Stored on disk, not RAM!
        metrics = {
            conversations = 0,
            successful_exchanges = 0,
            confidence = role == "student" and 0.5 or 0.7
        }
    }
    
    if role == "student" then
        personality.traits = {
            curiosity = 0.8,
            enthusiasm = 0.7,
            depth = 0.5
        }
    else
        personality.traits = {
            helpfulness = 0.9,
            patience = 0.8,
            depth = 0.7
        }
    end
    
    -- Store to disk immediately
    swapWrite("personality_" .. id, personality)
    
    return {id = id}  -- Only keep ID in memory!
end

local function getPersonality(handle)
    return swapRead("personality_" .. handle.id)
end

local function updatePersonality(handle, updates)
    local personality = getPersonality(handle)
    for key, value in pairs(updates) do
        personality[key] = value
    end
    swapWrite("personality_" .. handle.id, personality)
end

-- ============================================================================
-- CONVERSATION CONTEXT (Disk-backed)
-- ============================================================================

local function createContext(id)
    local context = {
        id = id,
        recent_exchanges = {},
        current_topic = "general",
        emotional_state = "neutral",
        depth = 0
    }
    
    swapWrite("context_" .. id, context)
    return {id = id}
end

local function getContext(handle)
    return swapRead("context_" .. handle.id)
end

local function addExchange(context_handle, speaker, message)
    local context = getContext(context_handle)
    
    table.insert(context.recent_exchanges, {
        speaker = speaker,
        message = message
    })
    
    -- Keep only last 5 (more than before!)
    if #context.recent_exchanges > 5 then
        table.remove(context.recent_exchanges, 1)
    end
    
    -- Advanced topic detection
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") or msg_lower:find("function") then
        context.current_topic = "programming"
    elseif msg_lower:find("learn") or msg_lower:find("study") or msg_lower:find("understand") then
        context.current_topic = "learning"
    elseif msg_lower:find("think") or msg_lower:find("feel") or msg_lower:find("like") then
        context.current_topic = "personal"
    elseif msg_lower:find("ai") or msg_lower:find("intelligence") or msg_lower:find("neural") then
        context.current_topic = "ai"
    end
    
    -- Emotional state detection
    if msg_lower:find("awesome") or msg_lower:find("great") or msg_lower:find("amazing") then
        context.emotional_state = "positive"
    elseif msg_lower:find("confus") or msg_lower:find("hard") or msg_lower:find("difficult") then
        context.emotional_state = "confused"
    elseif msg_lower:find("interest") or msg_lower:find("curious") or msg_lower:find("wonder") then
        context.emotional_state = "curious"
    end
    
    context.depth = context.depth + 1
    
    swapWrite("context_" .. context_handle.id, context)
end

-- ============================================================================
-- INTELLIGENT RESPONSE GENERATOR (Full templates!)
-- ============================================================================

local function generateResponse(personality_handle, context_handle)
    local personality = getPersonality(personality_handle)
    local context = getContext(context_handle)
    
    local last_msg = #context.recent_exchanges > 0 and 
        context.recent_exchanges[#context.recent_exchanges].message or nil
    local is_question = last_msg and last_msg:find("?") ~= nil
    
    local response = ""
    
    if personality.role == "student" then
        -- Greeting
        if not last_msg then
            local greetings = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?", "Yo! Ready to learn?"}
            response = greetings[math.random(#greetings)]
        
        -- Answering question
        elseif is_question then
            local acks = {"Got it!", "I understand!", "That helps!", "Makes sense!", "Awesome!", "Oh I see!", "That's clear!"}
            response = acks[math.random(#acks)]
            
            if math.random() < personality.traits.curiosity then
                local questions = {
                    "How does that work exactly?",
                    "Can you explain that more?",
                    "What do you mean by that?",
                    "Why is that important?",
                    "What's the best way to learn that?",
                    "Is there more to it?",
                    "What are the key concepts?"
                }
                response = response .. " " .. questions[math.random(#questions)]
            end
        
        -- Deep conversation
        elseif context.depth > 5 and math.random() < 0.4 then
            local reactions = {
                "That's really interesting!",
                "Oh, I see what you mean!",
                "That makes a lot of sense!",
                "I never thought about it that way!",
                "Cool, thanks for explaining!",
                "Wow, that's fascinating!",
                "This is really helpful!"
            }
            response = reactions[math.random(#reactions)]
        
        -- Regular questions
        else
            local questions = {
                "How does that work?",
                "Can you explain that?",
                "What do you think about that?",
                "Why is that?",
                "How would I learn that?",
                "What's important here?",
                "Can you teach me more?"
            }
            response = questions[math.random(#questions)]
        end
        
    else -- teacher
        if is_question then
            local explanations = {
                "Great question! Let me break that down for you.",
                "Think of it this way: it's like organizing information efficiently.",
                "The key concept here is understanding how the parts work together.",
                "It's simpler than it sounds once you see the pattern.",
                "Let me explain it step by step.",
                "Here's a good way to think about it.",
                "The important thing to understand is this."
            }
            response = explanations[math.random(#explanations)]
            
            if math.random() < 0.3 then
                local follow_ups = {
                    "Does that make sense?",
                    "Want me to explain more?",
                    "Any questions about that?",
                    "Ready to move on?",
                    "Got it?",
                    "Is that clear?"
                }
                response = response .. " " .. follow_ups[math.random(#follow_ups)]
            end
        else
            local encouragements = {
                "You're getting it!",
                "Exactly right!",
                "Good thinking!",
                "Perfect!",
                "That's the idea!",
                "You've got it!",
                "Well done!"
            }
            response = encouragements[math.random(#encouragements)]
        end
    end
    
    return response
end

-- ============================================================================
-- MAIN TRAINING SESSION
-- ============================================================================

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local num_conversations = options.conversations or 1000
    local turns_per_conversation = options.turns or 8
    
    print("=== ADVANCED AI TRAINING (Virtual Memory) ===")
    print("")
    print("Initializing virtual memory system...")
    
    if not initVirtualMemory() then
        return {exchanges = 0, error = "Virtual memory initialization failed"}
    end
    
    swapClear()
    print("Virtual memory ready! (Using " .. SWAP_DISK .. " as swap)")
    print("")
    
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    print(string.format("Training: %d conversations x %d turns", num_conversations, turns_per_conversation))
    print("")
    
    local start_time = os.clock()
    local total_exchanges = 0
    
    -- Create AI personalities (stored on disk!)
    local student = createPersonality("student", "student")
    local teacher = createPersonality("teacher", "teacher")
    
    local log_file = fs.open("/training/conversation_log.dat", "w")
    
    for conv = 1, num_conversations do
        -- Create conversation context (stored on disk!)
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
            
            -- Write to training log
            log_file.writeLine(textutils.serialize({
                speaker_a = "Student",
                message_a = student_msg,
                speaker_b = "Teacher",
                message_b = teacher_msg,
                context = {
                    topic = ctx.current_topic,
                    emotional_state = ctx.emotional_state,
                    turn = turn
                }
            }))
            
            -- Student responds
            student_msg = generateResponse(student, context)
            addExchange(context, "Student", student_msg)
            
            total_exchanges = total_exchanges + 1
        end
        
        -- Update personalities (on disk)
        local student_p = getPersonality(student)
        student_p.metrics.confidence = math.min(1.0, student_p.metrics.confidence + 0.002)
        student_p.metrics.conversations = student_p.metrics.conversations + 1
        swapWrite("personality_" .. student.id, student_p)
        
        local teacher_p = getPersonality(teacher)
        teacher_p.metrics.confidence = math.min(1.0, teacher_p.metrics.confidence + 0.002)
        teacher_p.metrics.conversations = teacher_p.metrics.conversations + 1
        swapWrite("personality_" .. teacher.id, teacher_p)
        
        -- Clean up context
        swapDelete("context_conv_" .. conv)
        
        -- Progress
        if conv % 100 == 0 then
            local elapsed = os.clock() - start_time
            local eta = (num_conversations - conv) / (conv / elapsed)
            
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num_conversations, (conv/num_conversations)*100, eta))
            print(string.format("  Student: %.3f | Teacher: %.3f",
                student_p.metrics.confidence, teacher_p.metrics.confidence))
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
    swapClear()
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total exchanges: %d", total_exchanges))
    print(string.format("Time: %.1f seconds", os.clock() - start_time))
    print(string.format("Student: %.3f | Teacher: %.3f",
        final_student.metrics.confidence, final_teacher.metrics.confidence))
    
    return {
        exchanges = total_exchanges,
        student_confidence = final_student.metrics.confidence,
        teacher_confidence = final_teacher.metrics.confidence
    }
end

function M.run()
    print("=== ADVANCED AI TRAINER ===")
    print("")
    print("This uses " .. SWAP_DISK .. " (RIGHT drive) as virtual memory.")
    print("Make sure the drive is empty or backed up!")
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
