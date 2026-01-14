-- Module: mood.lua
-- Tracks and manages user mood and emotional state

local M = {}

-- Mood definitions
M.moods = {
    happy = {value = 1, emoji = "😄"},
    neutral = {value = 0, emoji = "😐"},
    sad = {value = -0.5, emoji = "😢"},
    angry = {value = -1, emoji = "😠"},
    excited = {value = 0.8, emoji = "🤩"},
    confused = {value = -0.3, emoji = "🤔"}
}

-- Sentiment keywords
local sentimentKeywords = {
    positive = {"happy", "great", "awesome", "good", "fun", "cool", "love", "nice", "yay", "excellent"},
    negative = {"sad", "bad", "angry", "hate", "upset", "frustrated", "terrible", "awful", "ugh", "no"}
}

-- Current mood tracking per user
local userMoods = {}

-- Detect sentiment from message
function M.detectSentiment(message)
    local msg = message:lower()
    local score = 0
    
    for _, word in ipairs(sentimentKeywords.positive) do
        if msg:find(word) then score = score + 1 end
    end
    for _, word in ipairs(sentimentKeywords.negative) do
        if msg:find(word) then score = score - 1 end
    end
    
    if score > 0 then return "positive"
    elseif score < 0 then return "negative"
    else return "neutral" end
end

-- Update user mood
function M.update(user, message)
    local sentiment = M.detectSentiment(message)
    userMoods[user] = sentiment
    return sentiment
end

-- Get user mood
function M.get(user)
    return userMoods[user] or "neutral"
end

-- Adjust response based on mood
function M.adjustResponse(user, response)
    local mood = M.get(user)
    
    if mood == "positive" then
        return response .. " 😄"
    elseif mood == "negative" then
        return response .. " I'm here for you. 😢"
    else
        return response
    end
end

return M
