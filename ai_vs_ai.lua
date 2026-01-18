-- ai_vs_ai.lua
-- Two AI instances have conversations to generate training data

print("=== AI vs AI Training ===")
print("Two AIs will talk to each other to generate training data")
print("")

local markov = require("markov")

-- Simple AI personality A (Curious Student)
local AI_A = {
    name = "Student",
    personality = "curious",
    
    topics_of_interest = {
        "programming", "math", "science", "games", "learning",
        "computers", "AI", "technology", "coding", "minecraft"
    },
    
    question_starters = {
        "How does {topic} work?",
        "What is {topic}?",
        "Can you explain {topic}?",
        "Tell me about {topic}",
        "I'm curious about {topic}",
        "Why is {topic} important?",
        "What's the best way to learn {topic}?"
    },
    
    reactions = {
        positive = {"That's interesting!", "Cool!", "I didn't know that!", "Awesome!", "That makes sense!"},
        curious = {"Tell me more", "How so?", "Can you elaborate?", "What do you mean?"},
        understanding = {"I see", "Got it", "That helps", "Makes sense"}
    }
}

-- Simple AI personality B (Helpful Teacher)
local AI_B = {
    name = "Teacher",
    personality = "helpful",
    
    explanations = {
        programming = "Programming is writing instructions for computers to follow. It's like writing a recipe, but for machines!",
        math = "Math is the language of patterns and logic. It helps us solve problems and understand the world.",
        science = "Science is about asking questions and finding answers through experiments and observation.",
        AI = "AI is software that can learn and make decisions, kind of like teaching a computer to think!",
        learning = "Learning is about building connections in your brain. The more you practice, the stronger those connections get!",
        coding = "Coding is the process of creating programs. You break down problems into small steps a computer can follow."
    },
    
    encouragements = {
        "Great question!",
        "I'm happy to help!",
        "Let me explain that",
        "That's a smart thing to ask!",
        "You're thinking about this the right way!"
    }
}

-- Generate AI_A message (student asks question)
local function generateStudentMessage(conversation_context)
    -- Pick a random topic
    local topic = AI_A.topics_of_interest[math.random(#AI_A.topics_of_interest)]
    
    -- Choose question type
    local question_template = AI_A.question_starters[math.random(#AI_A.question_starters)]
    local message = question_template:gsub("{topic}", topic)
    
    return message, topic
end

-- Generate AI_B response (teacher answers)
local function generateTeacherResponse(topic)
    -- Start with encouragement
    local encouragement = AI_B.encouragements[math.random(#AI_B.encouragements)]
    
    -- Get explanation
    local explanation = AI_B.explanations[topic] or 
        string.format("%s is a fascinating subject with many applications!", topic)
    
    return encouragement .. " " .. explanation
end

-- Generate follow-up from student
local function generateStudentReaction()
    local reaction_type = math.random(3)
    
    if reaction_type == 1 then
        return AI_A.reactions.positive[math.random(#AI_A.reactions.positive)]
    elseif reaction_type == 2 then
        return AI_A.reactions.curious[math.random(#AI_A.reactions.curious)]
    else
        return AI_A.reactions.understanding[math.random(#AI_A.reactions.understanding)]
    end
end

-- Run a conversation between two AIs
local function runAIConversation(num_turns)
    local conversation = {}
    local current_topic = nil
    
    for turn = 1, num_turns do
        if turn % 2 == 1 then
            -- Student asks
            local message, topic = generateStudentMessage()
            current_topic = topic
            table.insert(conversation, {speaker = "Student", message = message})
            
            -- Train on this
            if markov then
                markov.train(message, 1)
                markov.train(message, 2)
            end
        else
            if turn == num_turns then
                -- Last turn - student reacts
                local reaction = generateStudentReaction()
                table.insert(conversation, {speaker = "Student", message = reaction})
                
                if markov then
                    markov.train(reaction, 1)
                    markov.train(reaction, 2)
                end
            else
                -- Teacher responds
                local response = generateTeacherResponse(current_topic)
                table.insert(conversation, {speaker = "Teacher", message = response})
                
                if markov then
                    markov.train(response, 1)
                    markov.train(response, 2)
                end
            end
        end
    end
    
    return conversation
end

-- Generate multiple conversations
local function generateTrainingData(num_conversations, turns_per_conv, show_conversations)
    print(string.format("Generating %d conversations (%d turns each)...", 
        num_conversations, turns_per_conv))
    print("")
    
    local total_turns = 0
    
    for i = 1, num_conversations do
        local conversation = runAIConversation(turns_per_conv)
        total_turns = total_turns + #conversation
        
        -- Show sample conversations
        if show_conversations and i <= 3 then
            print("--- Sample Conversation " .. i .. " ---")
            for _, turn in ipairs(conversation) do
                print(turn.speaker .. ": " .. turn.message)
            end
            print("")
        end
        
        -- Progress indicator
        if i % 100 == 0 then
            print(string.format("  Generated %d/%d conversations...", i, num_conversations))
            
            -- Save progress
            if markov then
                markov.save()
            end
        end
        
        -- Small delay
        os.sleep(0.01)
    end
    
    print("")
    print(string.format("Complete! Generated %d conversation turns", total_turns))
    
    -- Final save
    if markov then
        markov.save()
        local stats = markov.getStats()
        print(string.format("Markov data now has %d sequences!", stats.total_sequences))
    end
end

-- Add realistic conversation patterns
local function addRealisticPatterns()
    print("Adding realistic conversation patterns...")
    
    local realistic_exchanges = {
        -- Greetings
        {"Hey!", "Hi there! How's it going?", "Pretty good, you?", "Doing great! What's up?"},
        {"Hello", "Hey! Good to see you!", "Good to see you too!", "So what brings you here?"},
        
        -- Problem solving
        {"I'm stuck on this problem", "What kind of problem?", "A math one", "Let me help! What's the problem?"},
        {"Can you help me?", "Of course! What do you need?", "I need to understand loops", "Loops are super useful! Which part?"},
        
        -- Learning progression
        {"I want to learn coding", "That's awesome! What interests you?", "Making games", "Games are perfect for learning! Let's start simple."},
        {"How do I start?", "Start with the basics!", "Like what?", "Variables, if statements, loops - the fundamentals!"},
        
        -- Encouragement
        {"This is hard", "I know it can be tough, but you're doing great!", "Really?", "Absolutely! Keep practicing and it'll click!"},
        {"I don't get it", "That's okay! Learning takes time. Let me explain differently.", "Okay", "Think of it this way..."}
    }
    
    for _, exchange in ipairs(realistic_exchanges) do
        for _, message in ipairs(exchange) do
            if markov then
                markov.train(message, 1)
                markov.train(message, 2)
            end
        end
    end
    
    markov.save()
    print("Realistic patterns added!")
end

-- Main menu
while true do
    print("")
    print("=== AI vs AI Training ===")
    print("1. Quick generation (500 conversations)")
    print("2. Medium generation (2,000 conversations)")
    print("3. Massive generation (10,000 conversations)")
    print("4. Add realistic patterns")
    print("5. Custom generation")
    print("6. View training stats")
    print("7. Exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        generateTrainingData(500, 6, true)
        
    elseif choice == "2" then
        generateTrainingData(2000, 6, false)
        
    elseif choice == "3" then
        print("This will take several minutes...")
        print("The AI will learn THOUSANDS of conversation patterns!")
        print("")
        generateTrainingData(10000, 6, false)
        
    elseif choice == "4" then
        addRealisticPatterns()
        
    elseif choice == "5" then
        write("Number of conversations: ")
        local num = tonumber(read())
        write("Turns per conversation: ")
        local turns = tonumber(read())
        write("Show sample conversations? (y/n): ")
        local show = read():lower() == "y"
        
        if num and turns then
            generateTrainingData(num, turns, show)
        else
            print("Invalid input")
        end
        
    elseif choice == "6" then
        if markov then
            local stats = markov.getStats()
            print("=== Training Statistics ===")
            print(string.format("Total sequences: %d", stats.total_sequences))
            print(string.format("Unique starters: %d", stats.unique_starters))
            print("")
            
            -- Calculate approximate conversations
            local approx_convs = math.floor(stats.total_sequences / 12)
            print(string.format("Approximately %d conversations learned", approx_convs))
        end
        
    elseif choice == "7" then
        print("Saving and exiting...")
        if markov then
            markov.save()
        end
        break
    end
end

print("")
print("Training complete! Your AI now has tons of conversation experience!")
