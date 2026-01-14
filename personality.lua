-- Module: personality.lua
-- Manages AI personality traits

local M = {}

-- Personality traits (0.0 to 1.0)
M.traits = {
    humor = 0.5,
    curiosity = 0.5,
    patience = 0.5,
    empathy = 0.5,
    friendliness = 0.7
}

-- Adjust personality trait
function M.adjust(trait, amount)
    if M.traits[trait] then
        M.traits[trait] = math.max(0, math.min(1, M.traits[trait] + amount))
    end
end

-- Get personality trait value
function M.get(trait)
    return M.traits[trait] or 0.5
end

-- Evolve personality based on feedback
function M.evolve(feedback, category)
    if feedback == "positive" then
        M.adjust("humor", 0.02)
        M.adjust("friendliness", 0.02)
        if category == "greeting" or category == "gratitude" then
            M.adjust("empathy", 0.01)
        end
    elseif feedback == "negative" then
        M.adjust("humor", -0.02)
        M.adjust("patience", 0.01)
    end
end

return M
