-- unified_trainer.lua
-- Complete training pipeline: Advanced AI → Context Markov → SuperAI

print("Loading advanced training system...")

local advanced_trainer = require("advanced_ai_trainer")
local context_markov = require("context_markov")

print("=== UNIFIED AI TRAINING SYSTEM ===")
print("")
print("This system:")
print("1. Trains TWO self-learning AIs")
print("2. They have conversations and learn from each other")
print("3. Extracts context-aware patterns")
print("4. Trains your SuperAI with the results!")
print("")
print("Choose training intensity:")
print("")
print("1. Quick (500 conversations) - 2 minutes")
print("2. Standard (2,000 conversations) - 5 minutes")
print("3. Deep (10,000 conversations) - 20 minutes")
print("4. ULTIMATE (50,000 conversations) - 2 HOURS")
print("5. View training data")
print("6. Import existing training to SuperAI")
print("7. Exit")
print("")
write("Choice: ")

local choice = read()
print("")

local function runTrainingPipeline(num_conversations)
    print("=== PHASE 1: ADVANCED AI TRAINING ===")
    print("")
    
    -- Run advanced AI training
    local result = advanced_trainer.createAdvancedTrainingSession({
        conversations = num_conversations,
        turns = 10,
        save_interval = 100
    })
    
    print("")
    print("=== PHASE 2: IMPORTING TO CONTEXT MARKOV ===")
    print("")
    
    -- Import training data into context-aware Markov
    local imported = context_markov.importFromTrainingLog("/training/conversation_log.csv")
    
    -- Save context Markov
    context_markov.save("context_markov.dat")
    
    print("")
    print("=== PHASE 3: TRAINING SUPERAI ===")
    print("")
    
    -- Check if markov module is available (search all drives)
    local markov_exists = false
    for _, side in ipairs({"top", "right", "bottom", "left", "back"}) do
        for i = 0, 50 do
            local name = side .. "_" .. i
            if fs.exists(name .. "/markov.lua") then
                markov_exists = true
                break
            end
        end
        if markov_exists then break end
    end
    markov_exists = markov_exists or fs.exists("markov.lua")
    
    if not markov_exists then
        print("WARNING: markov.lua not found!")
        print("The context-aware patterns are saved, but")
        print("your SuperAI needs the markov module to use them.")
        print("")
        print("Make sure markov.lua is installed on disk2")
    else
        print("Context-aware patterns saved!")
        print("SuperAI can now use these patterns for natural responses.")
        print("")
        print("To enable in SuperAI, add this to main_logic.lua:")
        print("")
        print([[  local contextMarkov = require("context_markov")
  contextMarkov.load("context_markov.dat")
  
  -- In interpret():
  local history = getContextualHistory(user, 5)
  local smartResponse = contextMarkov.generateWithContext(
      history, message, 15
  )
  if smartResponse then
      response = smartResponse
  end]])
    end
    
    print("")
    print("=== TRAINING COMPLETE ===")
    print("")
    print("Results:")
    print(string.format("  AI Conversations: %d", result.exchanges))
    print(string.format("  Patterns Imported: %d", imported))
    
    local stats = context_markov.getStats()
    print(string.format("  Unique Contexts: %d", stats.contexts))
    print(string.format("  Total Patterns: %d", stats.total_patterns))
    print("")
    print("Data saved to:")
    print("  /training/student_ai.dat")
    print("  /training/teacher_ai.dat")
    print("  /training/conversation_log.csv")
    print("  context_markov.dat")
    print("")
end

if choice == "1" then
    runTrainingPipeline(500)
    
elseif choice == "2" then
    runTrainingPipeline(2000)
    
elseif choice == "3" then
    print("Deep training will take about 20 minutes...")
    write("Continue? (y/n): ")
    if read():lower() == "y" then
        runTrainingPipeline(10000)
    end
    
elseif choice == "4" then
    print("ULTIMATE training will take 1-2 HOURS!")
    write("Type YES to confirm: ")
    if read():upper() == "YES" then
        runTrainingPipeline(50000)
    else
        print("Cancelled.")
    end
    
elseif choice == "5" then
    print("=== TRAINING DATA OVERVIEW ===")
    print("")
    
    -- Check what exists
    if fs.exists("/training/conversation_log.csv") then
        local file = fs.open("/training/conversation_log.csv", "r")
        local lines = 0
        while file.readLine() do
            lines = lines + 1
        end
        file.close()
        print(string.format("Conversation Log: %d exchanges", lines))
    else
        print("Conversation Log: Not found")
    end
    
    if fs.exists("context_markov.dat") then
        context_markov.load("context_markov.dat")
        local stats = context_markov.getStats()
        print(string.format("Context Markov: %d patterns in %d contexts", 
            stats.total_patterns, stats.contexts))
    else
        print("Context Markov: Not found")
    end
    
    print("")
    advanced_trainer.viewStats()
    
elseif choice == "6" then
    print("=== IMPORT EXISTING TRAINING ===")
    print("")
    
    if not fs.exists("/training/conversation_log.csv") then
        print("ERROR: No training data found!")
        print("Run training first (options 1-4)")
    else
        print("Importing training data to context Markov...")
        local imported = context_markov.importFromTrainingLog("/training/conversation_log.csv")
        context_markov.save("context_markov.dat")
        
        local stats = context_markov.getStats()
        print("")
        print("Import complete!")
        print(string.format("  Patterns: %d", stats.total_patterns))
        print(string.format("  Contexts: %d", stats.contexts))
    end
    
else
    print("Exiting...")
end

print("")
print("Done!")
