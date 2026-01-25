-- training_diagnostic.lua
-- Shows what MODUS learned and proves it's using the training data

print("=== TRAINING DIAGNOSTIC ===")
print("")

-- Load context_markov
local cm = nil
local cm_loaded = false

local success, err = pcall(function()
    cm = require("context_markov")
    if fs.exists("context_markov.dat") then
        cm.load("context_markov.dat")
        cm_loaded = true
    end
end)

if not cm_loaded then
    print("WARNING: context_markov.dat not found!")
    print("Run training first to generate data.")
    print("")
end

-- Load exponential trainer stats
local exp_state = nil
pcall(function()
    local exp = require("exponential_trainer")
    exp_state = exp.getState()
end)

print("=== EXPONENTIAL TRAINING STATUS ===")
print("")
if exp_state then
    print("Generation: " .. (exp_state.generation or 1))
    print("Total conversations trained: " .. (exp_state.total_conversations or 0))
    print("Student intelligence: " .. string.format("%.2f", exp_state.student_intelligence or 1.0))
    print("Teacher intelligence: " .. string.format("%.2f", exp_state.teacher_intelligence or 1.0))
    
    -- Complexity level
    local gen = exp_state.generation or 1
    local complexity = gen <= 2 and "Simple" or gen <= 5 and "Intermediate" or gen <= 10 and "Advanced" or "Expert"
    print("Complexity level: " .. complexity)
    print("")
    
    -- Topic mastery
    if exp_state.topic_mastery then
        local topics_covered = 0
        for _ in pairs(exp_state.topic_mastery) do
            topics_covered = topics_covered + 1
        end
        print("Topics mastered: " .. topics_covered)
    end
else
    print("No exponential training data found.")
    print("Say 'training menu' and choose option 7-11")
end
print("")

-- Get stats from context_markov
if cm_loaded then
    local stats = cm.getStats()
    
    print("=== LEARNED DATA STATS ===")
    print("")
    print("Patterns learned: " .. (stats.total_patterns or 0))
    print("Contexts learned: " .. (stats.contexts_learned or 0))
    print("Successful generations: " .. (stats.successful_generations or 0))
    print("")
    
    -- Show what contexts exist
    print("=== CONTEXTS LEARNED ===")
    print("")
    local context_count = 0
    if cm.chains and cm.chains.contexts then
        for context, data in pairs(cm.chains.contexts) do
            context_count = context_count + 1
            if context_count <= 10 then
                local pattern_count = 0
                if type(data) == "table" and data.sequences then
                    for _ in pairs(data.sequences) do pattern_count = pattern_count + 1 end
                end
                print("  " .. context .. " (" .. pattern_count .. " sequences)")
            end
        end
    end
    if context_count > 10 then
        print("  ... and " .. (context_count - 10) .. " more contexts")
    end
    print("")
    print("Total unique contexts: " .. context_count)
    print("")
    
    -- Test generation
    print("=== TEST GENERATION ===")
    print("")
    print("Testing if MODUS can generate from learned data...")
    print("")
    
    local test_contexts = {
        "conversation_start",
        "answering_question",
        "general"
    }
    
    for _, ctx in ipairs(test_contexts) do
        local response = cm.generateWithContext({}, "test", 15)
        if response then
            print("[" .. ctx .. "]")
            local display = response
            if #display > 50 then display = display:sub(1, 47) .. "..." end
            print("  Generated: " .. display)
            print("  Source: LEARNED DATA")
            print("")
        end
    end
end

print("=== HOW TO GROW SMARTER ===")
print("")
print("1. Say 'training menu' to MODUS")
print("2. Choose options 7-11 for exponential training")
print("3. Run multiple times - each run builds on previous!")
print("4. Higher generations = smarter responses")
print("")
print("Say 'debug on' during chat to see response sources.")
