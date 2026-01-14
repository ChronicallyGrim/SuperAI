-- Module: responses.lua
-- Manages dynamic response generation

local M = {}

-- Suggestion prompts by category
local suggestions = {
    turtle = {
        "Do you want to continue mining or building?",
        "Should I keep digging?",
        "Ready for more exploration?"
    },
    math = {
        "Want to try another calculation?",
        "Need help with more math?",
        "Shall I solve another problem?"
    },
    greeting = {
        "Shall we continue chatting or do some tasks?",
        "What would you like to do today?",
        "Ready for some adventure?"
    },
    color = {
        "Would you like to change your chat color again?",
        "Want to try a different color?",
        "Happy with your current color?"
    }
}

-- Generate contextual suggestion
function M.suggestNextAction(category)
    local categoryPrompts = suggestions[category]
    if categoryPrompts and #categoryPrompts > 0 then
        return categoryPrompts[math.random(#categoryPrompts)]
    end
    return nil
end

-- Follow-up question generator
function M.generateFollowUp(category)
    if math.random() < 0.3 then  -- 30% chance
        return M.suggestNextAction(category)
    end
    return nil
end

return M
