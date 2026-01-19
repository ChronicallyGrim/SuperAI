-- advanced_ai_trainer.lua (Optimized Medium Version - Fixed)
-- Smart AI training with balanced memory usage and quality

local M = {}

-- ============================================================================
-- PERSONALITY SYSTEM (Lightweight but Smart)
-- ============================================================================

local function createPersonality(role)
    if role == "student" then
        return {
            curiosity = 0.8,
            enthusiasm = 0.7,
            confidence = 0.5,
            conversations = 0,
            recent_topics = {}
        }
    else
        return {
            helpfulness = 0.9,
            patience = 0.8,
            confidence = 0.7,
            conversations = 0,
            recent_topics = {}
        }
    end
end

local function evolvePersonality(personality, success)
    if success then
        personality.confidence = math.min(1.0, personality.confidence + 0.002)
    end
    personality.conversations = personality.conversations + 1
end

-- ============================================================================
-- SMART CONTEXT TRACKING (Last 3 exchanges only)
-- ============================================================================

local function createContext()
    return {
        recent_exchanges = {},
        current_topic = "general",
        depth = 0
    }
end

local function addExchange(context, speaker, message)
    table.insert(context.recent_exchanges, {speaker = speaker, message = message})
    
    -- Keep only last 3 exchanges
    if #context.recent_exchanges > 3 then
        table.remove(context.recent_exchanges, 1)
    end
    
    -- Detect topic from keywords
    local msg_lower = message:lower()
    if msg_lower:find("code") or msg_lower:find("program") then
        context.current_topic = "programming"
    elseif msg_lower:find("learn") or msg_lower:find("understand") then
        context.current_topic = "learning"
    elseif msg_lower:find("think") or msg_lower:find("feel") then
        context.current_topic = "personal"
    end
    
    context.depth = context.depth + 1
end

local function getLastMessage(context)
    if #context.recent_exchanges > 0 then
        return context.recent_exchanges[#context.recent_exchanges].message
    end
    return nil
end

local function wasQuestionAsked(context)
    local last = getLastMessage(context)
    return last and last:find("?") ~= nil
end

-- ============================================================================
-- INTELLIGENT RESPONSE GENERATOR
-- ============================================================================

local function loadTemplates(role)
    if role == "student" then
        return {
            greetings = {"Hey! How's it going?", "Hi! What's up?", "Hello! What's new?"},
            questions = {
                "How does that work exactly?",
                "Can you explain that more?",
                "What do you mean by that?",
                "Why is that important?",
                "What's the best way to learn that?"
            },
            reactions = {
                "That's really interesting!",
                "Oh, I see what you mean!",
                "That makes a lot of sense!",
                "I never thought about it that way!",
                "Cool, thanks for explaining!"
            },
            acknowledgments = {
                "Got it!", "I understand!", "That helps!", "Makes sense!", "Awesome!"
            }
        }
    else
        return {
            greetings = {"Hey! Ready to learn?", "Hi there! What would you like to know?"},
            explanations = {
                "Great question! Let me break that down for you.",
                "Think of it this way: it's like organizing information efficiently.",
                "The key concept here is understanding how the parts work together.",
                "It's simpler than it sounds once you see the pattern.",
                "Let me explain it step by step."
            },
            encouragements = {
                "You're getting it!", "Exactly right!", "Good thinking!", "Perfect!", "That's the idea!"
            },
            follow_ups = {
                "Does that make sense?",
                "Want me to explain more?",
                "Any questions about that?",
                "Ready to move on?",
                "Got it?"
            }
        }
    end
end

local function chooseRandom(list)
    return list[math.random(#list)]
end

local function generateResponse(role, context, personality, templates)
    local last_msg = getLastMessage(context)
    local is_question = wasQuestionAsked(context)
    
    if role == "student" then
        if not last_msg then
            return chooseRandom(templates.greetings)
        elseif is_question then
            -- Answer, then sometimes ask follow-up
            local response = chooseRandom(templates.acknowledgments)
            if math.random() < personality.curiosity then
                response = response .. " " .. chooseRandom(templates.questions)
            end
            return response
        elseif context.depth > 5 and math.random() < 0.4 then
            return chooseRandom(templates.reactions)
        else
            return chooseRandom(templates.questions)
        end
    else -- teacher
        if is_question then
            local response = chooseRandom(templates.explanations)
            if math.random() < 0.3 then
                response = response .. " " .. chooseRandom(templates.follow_ups)
            end
            return response
        else
            return chooseRandom(templates.encouragements)
        end
    end
end

-- ============================================================================
-- MAIN TRAINING SESSION
-- ============================================================================

function M.createAdvancedTrainingSession(options)
    options = options or {}
    local num_conversations = options.conversations or 1000
    local turns_per_conversation = options.turns or 8
    
    -- Create training directory
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    -- Open log file for streaming
    local log_file = fs.open("/training/conversation_log.dat", "w")
    
    print("=== ADVANCED AI TRAINING (Optimized) ===")
    print(string.format("Conversations: %d", num_conversations))
    print(string.format("Turns each: %d", turns_per_conversation))
    print("")
    
    -- Create AI personalities
    local student_personality = createPersonality("student")
    local teacher_personality = createPersonality("teacher")
    
    -- Load templates
    local student_templates = loadTemplates("student")
    local teacher_templates = loadTemplates("teacher")
    
    local start_time = os.clock()
    local total_exchanges = 0
    
    for conv = 1, num_conversations do
        -- Create fresh context for each conversation
        local context = createContext()
        
        -- Student starts
        local student_msg = generateResponse("student", context, student_personality, student_templates)
        addExchange(context, "Student", student_msg)
        
        for turn = 1, turns_per_conversation - 1 do
            -- Teacher responds
            local teacher_msg = generateResponse("teacher", context, teacher_personality, teacher_templates)
            addExchange(context, "Teacher", teacher_msg)
            
            -- Write to file immediately
            log_file.writeLine(textutils.serialize({
                speaker_a = "Student",
                message_a = student_msg,
                speaker_b = "Teacher",
                message_b = teacher_msg,
                context = {
                    topic = context.current_topic,
                    emotional_state = "neutral",
                    turn = turn
                }
            }))
            
            -- Student responds
            student_msg = generateResponse("student", context, student_personality, student_templates)
            addExchange(context, "Student", student_msg)
            
            total_exchanges = total_exchanges + 1
        end
        
        -- Learn from conversation
        evolvePersonality(student_personality, true)
        evolvePersonality(teacher_personality, true)
        
        -- Progress updates
        if conv % 100 == 0 then
            local elapsed = os.clock() - start_time
            local rate = conv / elapsed
            local eta = (num_conversations - conv) / rate
            
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num_conversations, (conv/num_conversations)*100, eta))
            print(string.format("  Student: %.3f | Teacher: %.3f",
                student_personality.confidence, teacher_personality.confidence))
            
            -- Clear context to free memory
            context = nil
            -- Note: ComputerCraft handles memory automatically
        end
        
        -- Small delay
        if conv % 50 == 0 then
            os.sleep(0.05)
        end
    end
    
    log_file.close()
    
    -- Save AI states
    local student_file = fs.open("/training/student_ai.dat", "w")
    student_file.write(textutils.serialize(student_personality))
    student_file.close()
    
    local teacher_file = fs.open("/training/teacher_ai.dat", "w")
    teacher_file.write(textutils.serialize(teacher_personality))
    teacher_file.close()
    
    local total_time = os.clock() - start_time
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total exchanges: %d", total_exchanges))
    print(string.format("Time: %.1f seconds (%.0f exchanges/sec)", 
        total_time, total_exchanges / total_time))
    print(string.format("Student confidence: %.3f | Teacher confidence: %.3f",
        student_personality.confidence, teacher_personality.confidence))
    print("Data saved to /training/")
    
    return {
        exchanges = total_exchanges,
        student_confidence = student_personality.confidence,
        teacher_confidence = teacher_personality.confidence
    }
end

-- ============================================================================
-- MENU
-- ============================================================================

function M.run()
    print("=== ADVANCED AI TRAINER ===")
    print("")
    print("1. Quick (500 conversations)")
    print("2. Standard (2,000 conversations)")
    print("3. Deep (10,000 conversations)")
    print("4. Exit")
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
    else
        print("Exiting...")
    end
end

return M
