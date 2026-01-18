-- auto_trainer.lua
-- Autonomous AI trainer - generates conversations to train your AI

print("=== AI Auto-Trainer ===")
print("This will generate thousands of training conversations")
print("")

-- Load the AI's main logic
local mainLogic = require("main_logic")
local markov = require("markov")

-- Training conversation templates
local conversation_templates = {
    -- Greetings
    {
        user = {"hello", "hi", "hey", "good morning", "what's up", "howdy"},
        expected_type = "greeting"
    },
    
    -- Questions
    {
        user = {"what is {topic}?", "how does {topic} work?", "tell me about {topic}", "explain {topic}"},
        topics = {"programming", "math", "science", "computers", "minecraft", "redstone", "coding"}
    },
    
    -- Math problems
    {
        user = {"what is {a} plus {b}?", "calculate {a} times {b}", "{a} divided by {b}"},
        numbers = {2, 5, 10, 15, 20, 50, 100}
    },
    
    -- Personal questions
    {
        user = {"how are you?", "how are you doing?", "how's it going?", "what's up?"},
        expected_type = "status"
    },
    
    -- Capabilities
    {
        user = {"what can you do?", "help me", "what are your features?", "commands"},
        expected_type = "help"
    },
    
    -- Time/date
    {
        user = {"what time is it?", "what's the time?", "current time?"},
        expected_type = "time"
    },
    
    -- Gratitude
    {
        user = {"thanks", "thank you", "appreciate it", "that's helpful"},
        expected_type = "gratitude"
    },
    
    -- Casual conversation
    {
        user = {
            "that's interesting",
            "cool",
            "nice",
            "tell me more",
            "I see",
            "gotcha",
            "makes sense",
            "that's awesome",
            "good to know"
        }
    },
    
    -- Opinions
    {
        user = {
            "what do you think about {topic}?",
            "do you like {topic}?",
            "what's your opinion on {topic}?"
        },
        topics = {"coding", "games", "learning", "AI", "technology", "music"}
    },
    
    -- Activities
    {
        user = {
            "I'm working on {activity}",
            "I just finished {activity}",
            "I'm going to {activity}"
        },
        activities = {"a project", "homework", "coding", "building", "studying"}
    }
}

-- Generate a random conversation turn
local function generateUserMessage()
    local template = conversation_templates[math.random(#conversation_templates)]
    local message_template = template.user[math.random(#template.user)]
    
    -- Replace placeholders
    if template.topics then
        local topic = template.topics[math.random(#template.topics)]
        message_template = message_template:gsub("{topic}", topic)
    end
    
    if template.numbers then
        local a = template.numbers[math.random(#template.numbers)]
        local b = template.numbers[math.random(#template.numbers)]
        message_template = message_template:gsub("{a}", a)
        message_template = message_template:gsub("{b}", b)
    end
    
    if template.activities then
        local activity = template.activities[math.random(#template.activities)]
        message_template = message_template:gsub("{activity}", activity)
    end
    
    return message_template
end

-- Run training sessions
local function runTrainingSession(num_conversations, turns_per_conversation)
    print(string.format("Starting training: %d conversations, %d turns each", 
        num_conversations, turns_per_conversation))
    print("")
    
    local total_turns = 0
    
    for conv = 1, num_conversations do
        print(string.format("Conversation %d/%d", conv, num_conversations))
        
        -- Start conversation
        local conversation_log = {}
        
        for turn = 1, turns_per_conversation do
            -- Generate user message
            local user_message = generateUserMessage()
            
            -- Get AI response (simulate calling the AI)
            -- In real use, this would call your main AI
            -- For training, we'll generate synthetic responses
            local ai_response = "I understand. " .. user_message:gsub("?", ".")
            
            -- Train Markov chains with this exchange
            if markov then
                markov.train(user_message, 1)
                markov.train(user_message, 2)
                markov.train(ai_response, 1)
                markov.train(ai_response, 2)
            end
            
            table.insert(conversation_log, {
                user = user_message,
                ai = ai_response
            })
            
            total_turns = total_turns + 1
            
            -- Small delay to prevent overwhelming
            os.sleep(0.05)
        end
        
        -- Save progress every 10 conversations
        if conv % 10 == 0 then
            if markov then
                markov.save()
            end
            print("  Progress saved!")
        end
    end
    
    print("")
    print(string.format("Training complete! Generated %d conversation turns", total_turns))
    
    -- Final save
    if markov then
        markov.save()
        local stats = markov.getStats()
        print(string.format("Markov chains now have %d sequences", stats.total_sequences))
    end
end

-- Add diverse training data
local function addDiverseData()
    print("Adding diverse training conversations...")
    
    local diverse_conversations = {
        -- Tech conversations
        {
            "What's the best programming language?",
            "It depends on what you're building! Python is great for beginners, JavaScript for web development, and Lua is perfect for ComputerCraft!",
            "I want to learn Python",
            "Python is an excellent choice! It has clean syntax and tons of libraries. Want to start with the basics?",
            "Yes please",
            "Let's begin with variables and data types. In Python, you can create a variable like: x = 5"
        },
        
        -- Math conversations
        {
            "Can you help with math?",
            "Absolutely! I can solve equations, calculate statistics, work with geometry, and more. What do you need help with?",
            "What's 15% of 200?",
            "15% of 200 is 30. Here's how: 200 × 0.15 = 30",
            "Thanks!",
            "You're welcome! Need help with anything else?"
        },
        
        -- Personal conversations
        {
            "I'm feeling stressed",
            "I'm sorry to hear that. Stress can be tough. Want to talk about what's on your mind?",
            "Just too much homework",
            "That's really common. Breaking it into smaller chunks can help. What subject are you working on?",
            "Math problems",
            "I can help with those! Want to work through them together?"
        },
        
        -- Learning conversations
        {
            "How do I get better at coding?",
            "Practice is key! Start with small projects, read other people's code, and don't be afraid to make mistakes. What are you interested in building?",
            "Maybe a game",
            "Games are fantastic for learning! They involve logic, graphics, user input - you learn so much. What kind of game?",
            "A simple platformer",
            "Perfect! Start with basic movement, then add jumping, collisions, and level design. Want some starter code?"
        }
    }
    
    for _, conv in ipairs(diverse_conversations) do
        for i = 1, #conv do
            if markov then
                markov.train(conv[i], 1)
                markov.train(conv[i], 2)
            end
        end
    end
    
    print("Diverse data added!")
end

-- Main menu
while true do
    print("")
    print("=== Training Options ===")
    print("1. Quick training (100 conversations)")
    print("2. Medium training (500 conversations)")
    print("3. Intensive training (2000 conversations)")
    print("4. Add diverse data")
    print("5. Custom training")
    print("6. View stats")
    print("7. Exit")
    print("")
    write("Choice: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        runTrainingSession(100, 5)
        
    elseif choice == "2" then
        runTrainingSession(500, 5)
        
    elseif choice == "3" then
        print("This will take a few minutes...")
        runTrainingSession(2000, 5)
        
    elseif choice == "4" then
        addDiverseData()
        markov.save()
        
    elseif choice == "5" then
        write("Number of conversations: ")
        local num_conv = tonumber(read())
        write("Turns per conversation: ")
        local turns = tonumber(read())
        
        if num_conv and turns then
            runTrainingSession(num_conv, turns)
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
            print("Chains by order:")
            for order, count in pairs(stats.chains_by_order) do
                print(string.format("  Order %d: %d states", order, count))
            end
        end
        
    elseif choice == "7" then
        print("Saving and exiting...")
        if markov then
            markov.save()
        end
        break
    end
end

print("Training session ended!")
