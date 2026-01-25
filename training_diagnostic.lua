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
    print("ERROR: context_markov.dat not found!")
    print("Run training first.")
    return
end

-- Get stats
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
            if type(data) == "table" then
                for _ in pairs(data) do pattern_count = pattern_count + 1 end
            end
            print("  " .. context .. " (" .. pattern_count .. " patterns)")
        end
    end
end
if context_count > 10 then
    print("  ... and " .. (context_count - 10) .. " more contexts")
end
print("")
print("Total unique contexts: " .. context_count)
print("")

-- Show sample patterns from each context
print("=== SAMPLE PATTERNS ===")
print("")
if cm.chains and cm.chains.responses then
    local shown = 0
    for context, responses in pairs(cm.chains.responses) do
        if shown < 5 then
            print("[" .. context .. "]")
            local resp_count = 0
            for resp, _ in pairs(responses) do
                resp_count = resp_count + 1
                if resp_count <= 3 then
                    -- Truncate long responses
                    local display = resp
                    if #display > 50 then
                        display = display:sub(1, 47) .. "..."
                    end
                    print("  -> " .. display)
                end
            end
            print("")
            shown = shown + 1
        end
    end
end

-- Test generation
print("=== TEST GENERATION ===")
print("")
print("Testing if MODUS can generate from learned data...")
print("")

local test_contexts = {
    "conversation_start",
    "answering_question",
    "status_question",
    "greeting"
}

for _, ctx in ipairs(test_contexts) do
    local response = cm.generateResponse({ctx}, {})
    if response then
        print("[" .. ctx .. "]")
        print("  Generated: " .. response)
        print("  Source: LEARNED DATA")
        print("")
    else
        print("[" .. ctx .. "]")
        print("  Generated: (none)")
        print("  Source: Would use FALLBACK")
        print("")
    end
end

-- Compare with/without training
print("=== PROOF OF LEARNING ===")
print("")
print("If 'Source: LEARNED DATA' appears above,")
print("MODUS is actively using the training!")
print("")
print("To see this in action during chat,")
print("type 'debug on' to MODUS to enable")
print("response source logging.")
