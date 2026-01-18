-- advanced_ai_trainer.lua
-- Self-learning AI training system with context awareness and personality evolution

local M = {}

-- ============================================================================
-- CORE AI PERSONALITY SYSTEM
-- ============================================================================

local AIPersonality = {
    -- Personality traits that evolve over time
    traits = {
        curiosity = 0.7,      -- How likely to ask questions
        enthusiasm = 0.6,     -- Energy level in responses
        depth = 0.5,          -- How deep conversations go
        humor = 0.4,          -- Likelihood of jokes/casual talk
        empathy = 0.8,        -- Understanding emotional context
        creativity = 0.6,     -- Novel responses vs patterns
    },
    
    -- Learned preferences from conversations
    preferences = {
        topics = {},          -- Topics AI has learned about
        response_styles = {}, -- Successful response patterns
        conversation_flow = {},-- How conversations naturally progress
    },
    
    -- Evolving knowledge base
    knowledge = {
        facts = {},           -- Facts learned from conversations
        concepts = {},        -- Abstract concepts understood
        relationships = {},   -- How concepts relate
        experiences = {},     -- Past conversation experiences
    },
    
    -- Performance metrics
    metrics = {
        conversations = 0,
        successful_exchanges = 0,
        learning_rate = 1.0,
        confidence = 0.5,
    }
}

function AIPersonality:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    
    -- Deep copy traits
    obj.traits = {}
    for k, v in pairs(self.traits) do
        obj.traits[k] = v
    end
    
    obj.preferences = {topics = {}, response_styles = {}, conversation_flow = {}}
    obj.knowledge = {facts = {}, concepts = {}, relationships = {}, experiences = {}}
    obj.metrics = {
        conversations = 0,
        successful_exchanges = 0,
        learning_rate = 1.0,
        confidence = 0.5
    }
    
    return obj
end

function AIPersonality:evolve(feedback)
    -- Traits evolve based on conversation success
    if feedback.engagement > 0.7 then
        self.traits.curiosity = math.min(1.0, self.traits.curiosity + 0.01)
        self.traits.enthusiasm = math.min(1.0, self.traits.enthusiasm + 0.01)
    end
    
    if feedback.depth > 0.6 then
        self.traits.depth = math.min(1.0, self.traits.depth + 0.02)
    end
    
    -- Adjust learning rate based on success
    if feedback.success then
        self.metrics.successful_exchanges = self.metrics.successful_exchanges + 1
        self.metrics.confidence = math.min(1.0, self.metrics.confidence + 0.005)
    else
        self.metrics.confidence = math.max(0.1, self.metrics.confidence - 0.003)
    end
    
    self.metrics.conversations = self.metrics.conversations + 1
end

function AIPersonality:save(filepath)
    local data = textutils.serialize({
        traits = self.traits,
        preferences = self.preferences,
        knowledge = self.knowledge,
        metrics = self.metrics
    })
    
    local file = fs.open(filepath, "w")
    file.write(data)
    file.close()
end

function AIPersonality:load(filepath)
    if not fs.exists(filepath) then return false end
    
    local file = fs.open(filepath, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    
    if data then
        self.traits = data.traits or self.traits
        self.preferences = data.preferences or self.preferences
        self.knowledge = data.knowledge or self.knowledge
        self.metrics = data.metrics or self.metrics
        return true
    end
    
    return false
end

-- ============================================================================
-- CONTEXT-AWARE CONVERSATION MANAGER
-- ============================================================================

local ConversationContext = {
    history = {},           -- Full conversation history
    current_topic = nil,    -- Active topic
    topic_depth = 0,        -- How deep in current topic
    emotional_state = "neutral",
    last_question = nil,    -- Track questions asked
    answered_questions = {},
    conversation_goals = {},
}

function ConversationContext:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    
    obj.history = {}
    obj.current_topic = nil
    obj.topic_depth = 0
    obj.emotional_state = "neutral"
    obj.last_question = nil
    obj.answered_questions = {}
    obj.conversation_goals = {}
    
    return obj
end

function ConversationContext:addExchange(speaker, message, context_tags)
    table.insert(self.history, {
        speaker = speaker,
        message = message,
        context_tags = context_tags or {},
        timestamp = os.clock(),
        topic = self.current_topic,
        emotional_state = self.emotional_state
    })
    
    -- Keep last 100 exchanges in memory
    if #self.history > 100 then
        table.remove(self.history, 1)
    end
end

function ConversationContext:detectTopic(message)
    local msg_lower = message:lower()
    
    -- Topic keywords
    local topics = {
        programming = {"code", "program", "function", "variable", "lua", "python"},
        science = {"experiment", "theory", "research", "data", "hypothesis"},
        personal = {"feel", "think", "like", "want", "enjoy", "prefer"},
        gaming = {"game", "play", "level", "minecraft", "player"},
        learning = {"learn", "understand", "teach", "study", "practice"},
        philosophy = {"why", "meaning", "purpose", "exist", "think about"},
        casual = {"hey", "sup", "lol", "yeah", "cool", "nice"}
    }
    
    local scores = {}
    for topic, keywords in pairs(topics) do
        scores[topic] = 0
        for _, keyword in ipairs(keywords) do
            if msg_lower:find(keyword) then
                scores[topic] = scores[topic] + 1
            end
        end
    end
    
    -- Find highest scoring topic
    local best_topic = "general"
    local best_score = 0
    for topic, score in pairs(scores) do
        if score > best_score then
            best_topic = topic
            best_score = score
        end
    end
    
    if best_score > 0 then
        if self.current_topic ~= best_topic then
            self.current_topic = best_topic
            self.topic_depth = 0
        else
            self.topic_depth = self.topic_depth + 1
        end
    end
    
    return best_topic
end

function ConversationContext:analyzeEmotionalTone(message)
    local msg_lower = message:lower()
    
    -- Positive indicators
    local positive = {"happy", "great", "awesome", "love", "excited", "amazing", "good", "nice"}
    local negative = {"sad", "angry", "frustrated", "hate", "annoyed", "bad", "terrible"}
    local curious = {"how", "why", "what", "interesting", "wonder", "curious"}
    
    local pos_score = 0
    local neg_score = 0
    local cur_score = 0
    
    for _, word in ipairs(positive) do
        if msg_lower:find(word) then pos_score = pos_score + 1 end
    end
    for _, word in ipairs(negative) do
        if msg_lower:find(word) then neg_score = neg_score + 1 end
    end
    for _, word in ipairs(curious) do
        if msg_lower:find(word) then cur_score = cur_score + 1 end
    end
    
    if pos_score > neg_score and pos_score > 0 then
        self.emotional_state = "positive"
    elseif neg_score > pos_score and neg_score > 0 then
        self.emotional_state = "negative"
    elseif cur_score > 1 then
        self.emotional_state = "curious"
    else
        self.emotional_state = "neutral"
    end
    
    return self.emotional_state
end

function ConversationContext:shouldChangeSubject()
    -- Change subject if topic has been discussed for too long
    return self.topic_depth > 10 and math.random() < 0.3
end

function ConversationContext:getRecentContext(n)
    n = n or 5
    local recent = {}
    local start = math.max(1, #self.history - n + 1)
    
    for i = start, #self.history do
        table.insert(recent, self.history[i])
    end
    
    return recent
end

-- ============================================================================
-- INTELLIGENT RESPONSE GENERATOR
-- ============================================================================

local ResponseGenerator = {}

function ResponseGenerator:new(personality, context)
    local obj = {
        personality = personality,
        context = context,
        response_templates = {},
        learned_patterns = {}
    }
    setmetatable(obj, self)
    self.__index = self
    
    obj:initializeTemplates()
    
    return obj
end

function ResponseGenerator:initializeTemplates()
    self.response_templates = {
        greetings = {
            "Hey! How's it going?",
            "Hi there! What's on your mind?",
            "Yo! What's up?",
            "Hello! Ready to chat?",
        },
        
        follow_up_questions = {
            programming = {
                "What programming languages do you work with?",
                "Are you working on any projects?",
                "How did you get into coding?",
                "What's the most interesting thing you've built?",
            },
            learning = {
                "What are you trying to learn?",
                "How's that going for you?",
                "Have you tried any tutorials?",
                "What's been the hardest part?",
            },
            personal = {
                "What do you enjoy doing?",
                "What's something you're passionate about?",
                "What makes you happy?",
                "What's on your mind today?",
            }
        },
        
        acknowledgments = {
            enthusiastic = {"That's awesome!", "Amazing!", "Love it!", "So cool!"},
            understanding = {"I get that.", "Makes sense.", "Yeah, I understand.", "I feel you."},
            curious = {"Tell me more!", "Interesting!", "Really? How so?", "That's fascinating!"},
            supportive = {"You've got this!", "That's great progress!", "Keep it up!", "Nice work!"}
        },
        
        deep_thoughts = {
            "That's an interesting perspective. What made you think of that?",
            "I never thought about it that way before.",
            "There's a lot to unpack there. Let's dive deeper.",
            "That raises some interesting questions...",
        }
    }
end

function ResponseGenerator:generate(message, role)
    -- role: "student" (asking questions), "teacher" (explaining), "friend" (casual)
    
    local msg_lower = message:lower()
    local response = ""
    
    -- Detect what kind of response is needed
    local is_question = msg_lower:find("?") ~= nil
    local is_greeting = msg_lower:find("^h[ei]") or msg_lower:find("^yo") or msg_lower:find("^sup")
    local is_short = #message < 20
    
    -- Context-aware response generation
    local recent = self.context:getRecentContext(3)
    local just_asked_question = false
    
    if #recent > 0 then
        local last = recent[#recent]
        if last.speaker ~= "self" and last.message:find("?") then
            just_asked_question = true
        end
    end
    
    -- Generate based on context
    if is_greeting then
        response = self:chooseRandom(self.response_templates.greetings)
        
    elseif just_asked_question and not is_question then
        -- User answered our question - acknowledge
        local emotion = self.context.emotional_state
        if emotion == "positive" then
            response = self:chooseRandom(self.response_templates.acknowledgments.enthusiastic)
        elseif emotion == "curious" then
            response = self:chooseRandom(self.response_templates.acknowledgments.curious)
        else
            response = self:chooseRandom(self.response_templates.acknowledgments.understanding)
        end
        
        -- Sometimes add follow-up based on topic
        if self.context.current_topic and math.random() < self.personality.traits.curiosity then
            local follow_ups = self.response_templates.follow_up_questions[self.context.current_topic]
            if follow_ups then
                response = response .. " " .. self:chooseRandom(follow_ups)
            end
        end
        
    elseif is_question then
        -- User asked a question - provide thoughtful answer
        response = self:generateThoughtfulAnswer(message, role)
        
    elseif is_short then
        -- Short message - brief but engaging response
        if msg_lower:find("yeah") or msg_lower:find("cool") or msg_lower:find("nice") then
            response = self:chooseRandom({"Right?", "For sure!", "I know!", "Totally!"})
        else
            response = self:chooseRandom(self.response_templates.acknowledgments.understanding)
        end
        
    else
        -- Longer statement - engage deeply
        if math.random() < self.personality.traits.depth then
            response = self:chooseRandom(self.response_templates.deep_thoughts)
        else
            response = self:generateContextualResponse(message, role)
        end
    end
    
    return response
end

function ResponseGenerator:generateThoughtfulAnswer(question, role)
    local msg_lower = question:lower()
    
    -- Topic-specific responses
    if msg_lower:find("how") and msg_lower:find("work") then
        return "Great question! Let me break that down. " .. self:explainConcept(question)
    end
    
    if msg_lower:find("what.*think") or msg_lower:find("what.*opinion") then
        return "Honestly, I think " .. self:generateOpinion(question)
    end
    
    if msg_lower:find("why") then
        return "Good question. I'd say it's because " .. self:generateExplanation(question)
    end
    
    if role == "student" then
        return "I'm curious about that too! What do you think?"
    elseif role == "teacher" then
        return "Let me explain. " .. self:explainConcept(question)
    else
        return "Hmm, interesting question. I'm not totally sure, but here's what I think..."
    end
end

function ResponseGenerator:explainConcept(topic)
    local explanations = {
        "It's basically a way to organize and structure information.",
        "Think of it like building blocks - each piece has a specific purpose.",
        "The key is understanding how all the parts work together.",
        "It's simpler than it sounds once you break it down.",
    }
    return self:chooseRandom(explanations)
end

function ResponseGenerator:generateOpinion(topic)
    local opinions = {
        "it's really fascinating when you dig into it.",
        "there's a lot of potential there that people don't realize.",
        "it's more complex than most people think.",
        "the real challenge is understanding all the nuances.",
    }
    return self:chooseRandom(opinions)
end

function ResponseGenerator:generateExplanation(topic)
    local explanations = {
        "it helps solve a fundamental problem in an elegant way.",
        "it's the result of years of development and iteration.",
        "the underlying principles are actually quite logical.",
        "once you understand the basics, everything else follows.",
    }
    return self:chooseRandom(explanations)
end

function ResponseGenerator:generateContextualResponse(message, role)
    local topic = self.context.current_topic or "general"
    
    local responses = {
        programming = "That's a cool approach! Have you run into any challenges with it?",
        learning = "Nice progress! What's been the most helpful thing you've learned?",
        personal = "I can relate to that. What else has been on your mind?",
        gaming = "Sounds fun! What do you like most about it?",
        general = "That's interesting! Tell me more about that.",
    }
    
    return responses[topic] or responses.general
end

function ResponseGenerator:chooseRandom(list)
    if not list or #list == 0 then return "I see." end
    return list[math.random(#list)]
end

function ResponseGenerator:learnFromSuccess(message, response, feedback)
    -- Store successful patterns
    if feedback and feedback.success then
        table.insert(self.learned_patterns, {
            input = message,
            output = response,
            context = self.context.current_topic,
            success_score = feedback.engagement or 0.5
        })
        
        -- Keep top 1000 patterns
        if #self.learned_patterns > 1000 then
            table.remove(self.learned_patterns, 1)
        end
    end
end

-- ============================================================================
-- CONVERSATION LOGGER WITH CONTEXT TAGS
-- ============================================================================

local ConversationLogger = {}

function ConversationLogger:new(filepath)
    local obj = {
        filepath = filepath,
        conversations = {},
        current_session = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function ConversationLogger:logExchange(speaker_a, message_a, speaker_b, message_b, context_tags)
    local exchange = {
        speaker_a = speaker_a,
        message_a = message_a,
        speaker_b = speaker_b,
        message_b = message_b,
        context = context_tags,
        timestamp = os.time()
    }
    
    table.insert(self.current_session, exchange)
    table.insert(self.conversations, exchange)
end

function ConversationLogger:save()
    if not fs.exists("/training") then
        fs.makeDir("/training")
    end
    
    local file = fs.open(self.filepath, #self.conversations == 0 and "w" or "a")
    for _, exchange in ipairs(self.current_session) do
        file.writeLine(textutils.serialize(exchange))
    end
    file.close()
    
    self.current_session = {}
end

function ConversationLogger:getStats()
    return {
        total_exchanges = #self.conversations,
        session_exchanges = #self.current_session
    }
end

-- ============================================================================
-- MAIN ADVANCED TRAINING SYSTEM
-- ============================================================================

function M.createAdvancedTrainingSession(options)
    options = options or {}
    
    local num_conversations = options.conversations or 1000
    local turns_per_conversation = options.turns or 8
    local save_interval = options.save_interval or 100
    
    -- Initialize components
    local student_ai = AIPersonality:new()
    local teacher_ai = AIPersonality:new()
    
    -- Make them slightly different
    teacher_ai.traits.depth = 0.8
    teacher_ai.traits.empathy = 0.9
    student_ai.traits.curiosity = 0.9
    student_ai.traits.enthusiasm = 0.8
    
    -- Load existing personalities if they exist
    student_ai:load("/training/student_ai.dat")
    teacher_ai:load("/training/teacher_ai.dat")
    
    local context = ConversationContext:new()
    local student_generator = ResponseGenerator:new(student_ai, context)
    local teacher_generator = ResponseGenerator:new(teacher_ai, context)
    local logger = ConversationLogger:new("/training/conversation_log.dat")
    
    print("=== ADVANCED AI TRAINING SESSION ===")
    print("")
    print(string.format("Conversations: %d", num_conversations))
    print(string.format("Turns each: %d", turns_per_conversation))
    print(string.format("Total exchanges: %d", num_conversations * turns_per_conversation))
    print("")
    print("Student AI Traits:")
    print(string.format("  Curiosity: %.2f | Enthusiasm: %.2f", student_ai.traits.curiosity, student_ai.traits.enthusiasm))
    print(string.format("  Conversations: %d | Confidence: %.2f", student_ai.metrics.conversations, student_ai.metrics.confidence))
    print("")
    print("Teacher AI Traits:")
    print(string.format("  Depth: %.2f | Empathy: %.2f", teacher_ai.traits.depth, teacher_ai.traits.empathy))
    print(string.format("  Conversations: %d | Confidence: %.2f", teacher_ai.metrics.conversations, teacher_ai.metrics.confidence))
    print("")
    print("Starting training...")
    print("")
    
    local start_time = os.clock()
    local total_exchanges = 0
    
    for conv = 1, num_conversations do
        -- Reset context for new conversation
        context = ConversationContext:new()
        student_generator.context = context
        teacher_generator.context = context
        
        -- Student starts conversation
        local student_msg = student_generator:generate("", "student")
        context:addExchange("Student", student_msg, {"greeting", "conversation_start"})
        
        for turn = 1, turns_per_conversation - 1 do
            -- Teacher responds
            context:detectTopic(student_msg)
            context:analyzeEmotionalTone(student_msg)
            
            local teacher_msg = teacher_generator:generate(student_msg, "teacher")
            context:addExchange("Teacher", teacher_msg, {
                context.current_topic,
                context.emotional_state,
                "response_to_" .. (student_msg:find("?") and "question" or "statement")
            })
            
            -- Log for training
            logger:logExchange("Student", student_msg, "Teacher", teacher_msg, {
                topic = context.current_topic,
                emotional_state = context.emotional_state,
                turn = turn
            })
            
            -- Student responds
            context:detectTopic(teacher_msg)
            context:analyzeEmotionalTone(teacher_msg)
            
            student_msg = student_generator:generate(teacher_msg, "student")
            context:addExchange("Student", student_msg, {
                context.current_topic,
                context.emotional_state
            })
            
            total_exchanges = total_exchanges + 1
            
            -- Learn from exchange
            local feedback = {
                success = true,
                engagement = 0.7 + math.random() * 0.3,
                depth = context.topic_depth / 10
            }
            
            student_ai:evolve(feedback)
            teacher_ai:evolve(feedback)
        end
        
        -- Progress updates
        if conv % save_interval == 0 then
            local elapsed = os.clock() - start_time
            local rate = conv / elapsed
            local remaining = num_conversations - conv
            local eta = remaining / rate
            
            print(string.format("Progress: %d/%d (%.1f%%) - ETA: %.0f sec", 
                conv, num_conversations, (conv/num_conversations)*100, eta))
            print(string.format("  Student confidence: %.3f | Teacher confidence: %.3f",
                student_ai.metrics.confidence, teacher_ai.metrics.confidence))
            
            -- Save progress
            logger:save()
            student_ai:save("/training/student_ai.dat")
            teacher_ai:save("/training/teacher_ai.dat")
        end
        
        -- Small delay to prevent lag
        if conv % 50 == 0 then
            os.sleep(0.05)
        end
    end
    
    -- Final save
    logger:save()
    student_ai:save("/training/student_ai.dat")
    teacher_ai:save("/training/teacher_ai.dat")
    
    local total_time = os.clock() - start_time
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print(string.format("Total exchanges: %d", total_exchanges))
    print(string.format("Time: %.1f seconds", total_time))
    print(string.format("Rate: %.0f exchanges/sec", total_exchanges / total_time))
    print("")
    print("Final AI States:")
    print(string.format("Student - Confidence: %.3f | Conversations: %d",
        student_ai.metrics.confidence, student_ai.metrics.conversations))
    print(string.format("Teacher - Confidence: %.3f | Conversations: %d",
        teacher_ai.metrics.confidence, teacher_ai.metrics.conversations))
    print("")
    print("Data saved to /training/ directory")
    
    return {
        exchanges = total_exchanges,
        student_ai = student_ai,
        teacher_ai = teacher_ai,
        logger = logger
    }
end

-- ============================================================================
-- TRAINING MENU
-- ============================================================================

function M.run()
    print("=== ADVANCED AI TRAINER ===")
    print("")
    print("This system trains TWO AIs that learn from each other!")
    print("")
    print("1. Quick Training (500 conversations)")
    print("2. Standard Training (2,000 conversations)")
    print("3. Deep Training (10,000 conversations)")
    print("4. ULTIMATE Training (50,000 conversations)")
    print("5. Custom Training")
    print("6. View Training Stats")
    print("7. Exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        M.createAdvancedTrainingSession({conversations = 500, turns = 6})
    elseif choice == "2" then
        M.createAdvancedTrainingSession({conversations = 2000, turns = 8})
    elseif choice == "3" then
        print("Deep training will take 15-20 minutes...")
        M.createAdvancedTrainingSession({conversations = 10000, turns = 10})
    elseif choice == "4" then
        print("ULTIMATE training will take 1-2 HOURS!")
        write("Are you sure? (YES to confirm): ")
        if read():upper() == "YES" then
            M.createAdvancedTrainingSession({conversations = 50000, turns = 12})
        else
            print("Cancelled.")
        end
    elseif choice == "5" then
        write("Number of conversations: ")
        local convs = tonumber(read())
        write("Turns per conversation: ")
        local turns = tonumber(read())
        if convs and turns then
            M.createAdvancedTrainingSession({conversations = convs, turns = turns})
        else
            print("Invalid input.")
        end
    elseif choice == "6" then
        M.viewStats()
    else
        print("Exiting...")
    end
end

function M.viewStats()
    print("=== TRAINING STATISTICS ===")
    print("")
    
    -- Load AI personalities
    local student = AIPersonality:new()
    local teacher = AIPersonality:new()
    
    if student:load("/training/student_ai.dat") then
        print("Student AI:")
        print(string.format("  Conversations: %d", student.metrics.conversations))
        print(string.format("  Confidence: %.3f", student.metrics.confidence))
        print(string.format("  Curiosity: %.2f | Enthusiasm: %.2f", 
            student.traits.curiosity, student.traits.enthusiasm))
        print("")
    else
        print("Student AI: No data (not trained yet)")
        print("")
    end
    
    if teacher:load("/training/teacher_ai.dat") then
        print("Teacher AI:")
        print(string.format("  Conversations: %d", teacher.metrics.conversations))
        print(string.format("  Confidence: %.3f", teacher.metrics.confidence))
        print(string.format("  Depth: %.2f | Empathy: %.2f", 
            teacher.traits.depth, teacher.traits.empathy))
        print("")
    else
        print("Teacher AI: No data (not trained yet)")
        print("")
    end
    
    -- Check for conversation log
    if fs.exists("/training/conversation_log.dat") then
        local file = fs.open("/training/conversation_log.dat", "r")
        local lines = 0
        while file.readLine() do
            lines = lines + 1
        end
        file.close()
        print(string.format("Logged conversations: %d exchanges", lines))
    else
        print("No conversation logs found")
    end
    
    print("")
    write("Press Enter to continue...")
    read()
end

return M
