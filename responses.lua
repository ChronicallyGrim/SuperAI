-- Module: responses.lua
local function suggestNextAction(user)
    local recent = getRecentContext(user)
    local suggestions = {}

    for _,entry in ipairs(recent) do
        if entry.category == "turtle" then
            table.insert(suggestions, "Do you want to continue mining or building?")
        elseif entry.category == "math" then
            table.insert(suggestions, "Want to try another calculation?")
        elseif entry.category == "greeting" or entry.category == "gratitude" then
            table.insert(suggestions, "Shall we continue chatting or do some tasks?")
        elseif entry.category == "color" then
            table.insert(suggestions, "Would you like to change your chat color again?")
        end
    end

    if #suggestions > 0 then
        return choose(suggestions)
    else
        return nil
    end
end

-- ===== INTEGRATION WITH RESPONSE SYSTEM =====
