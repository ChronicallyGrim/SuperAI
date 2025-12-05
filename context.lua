-- Module: context.lua
-- Alters tone of responses based on user mood and AI personality
local function adjustResponseForMood(response, userMood)
    local adjusted = response
    if userMood == "happy" then
        adjusted = adjusted .. " 😄"
    elseif userMood == "sad" then
        adjusted = adjusted .. " 😢"
    elseif userMood == "neutral" then
        adjusted = adjusted .. " 🙂"
    end

    -- Personality-based flair
    if personality.humor > 0.7 and math.random() < 0.3 then
        adjusted = adjusted .. " Haha!"
    elseif personality.curiosity > 0.6 and math.random() < 0.2 then
        adjusted = adjusted .. " By the way, have you tried exploring that new cave?"
    end
    return adjusted
end

-- ===== INTEGRATED INTERPRETATION WITH MOOD & CONTEXT =====

local function interpretWithContext(message, user)
    local category = detectCategory(message)
    local response = interpret(message, user)
    response = dynamicResponse(response, category)
    
    -- Update context history
    updateContextHistory(user, message, response, category)

    -- Occasionally give personalized suggestions
    if math.random() < 0.15 then
        local suggestion = suggestNextAction(user)
        if suggestion then response = response .. " " .. suggestion end
    end

    return response
end
-- ===== SENTIMENT ANALYSIS =====

local function interpretWithPersonality(message, user)
    -- Start with emotion-aware response
    local resp = interpretWithEmotion(message, user)

    -- Apply personality adjustments
    resp = humorAdjust(resp)
    resp = friendlinessAdjust(resp)

    -- Evolve personality based on this interaction
    evolvePersonality(user, message, resp)

    return resp
end
-- ===== CONTEXT CHAINING =====


-- Define simple sentiment lexicon
local sentimentLexicon = {
    positive = {"happy", "great", "good", "fun", "awesome", "cool", "love", "yay", "yes", "yay"},
    negative = {"sad", "angry", "bad", "hate", "upset", "ugh", "no", "terrible", "frustrated"},
    neutral = {"ok", "fine", "meh", "alright"}
}

-- Analyze the emotional tone of a message
local function analyzeSentiment(message)
    local msgNorm = normalize(message)
    local score = 0
    
    for _, word in ipairs(sentimentLexicon.positive) do
        if msgNorm:find(word) then score = score + 1 end
    end
    for _, word in ipairs(sentimentLexicon.negative) do
        if msgNorm:find(word) then score = score - 1 end
    end
    -- Neutral words have minimal effect
    return score
end

-- Determine mood label based on sentiment score
local function determineMood(score)
    if score > 0 then
        return "happy"
    elseif score < 0 then
        return "sad"
    else
        return "neutral"
    end
end

-- Adjust AI response tone
local function adjustResponseTone(response, userMood)
    local moodAdjustments = {
        happy = {"😊", "😃", "👍", "🎉"},
        sad = {"😢", "🙁", "💔"},
        neutral = {"😐", "🤔"}
    }

    local emojiList = moodAdjustments[userMood] or {}
    if #emojiList > 0 and math.random() < 0.5 then
        response = response .. " " .. emojiList[math.random(#emojiList)]
    end
    return response
end

-- Integrate emotional tone into interpretation
local function interpretWithEmotion(message, user)
    local baseResp = interpret(message, user)
    local sentimentScore = analyzeSentiment(message)
    local userMood = determineMood(sentimentScore)
    local finalResp = adjustResponseTone(baseResp, userMood)
    
    -- Store context with mood
    addContextEvent(user, message, finalResp)
    
    return finalResp
end
-- ===== PERSONALITY-DRIVEN CONVERSATION VARIATIONS =====


-- Basic negative sentiment keywords
local negativeWords = {
    "sad","angry","upset","mad","frustrated","tired","bored","unhappy","stressed","worried","lonely","frustrating"
}

-- Function to detect negative sentiment
local function detectNegativeSentiment(message)
    local msg = message:lower()
    for _, word in ipairs(negativeWords) do
        if msg:find(word) then
            return true
        end
    end
    return false
end

-- Empathetic responses
local empathyResponses = {
    "I understand how you feel.",
    "That sounds tough. I'm here for you!",
    "I get it. Everyone has those days.",
    "Take a deep breath, it will get better.",
    "I'm listening. Want to tell me more?",
    "I'm sorry you're feeling that way.",
    "I can imagine that’s frustrating.",
    "Thanks for sharing that with me."
}

-- Function to generate empathy response
local function generateEmpathy(message, user)
    if detectNegativeSentiment(message) then
        local resp = empathyResponses[math.random(#empathyResponses)]
        -- Optionally reference last interaction for more context
        local recent = getRecentMessages(user, 2)
        if #recent > 0 then
            resp = resp .. " Earlier you mentioned '" .. recent[#recent] .. "'."
        end
        return resp
    end
    return nil
end

-- Modify interpret function to include empathy
local old_interpret = interpret
interpret = function(message, user)
    -- First check for empathy
    local empathyResp = generateEmpathy(message, user)
    if empathyResp then
        updateContext(user, message, "empathy")
        return empathyResp
    end
    -- Otherwise use old interpretation
    return old_interpret(message, user)
end
-- ===== HUMOR + EMPATHY FUSION =====


-- Define mood thresholds
local moodThresholds = {
    happy = 0.6,
    neutral = 0.4,
    sad = 0.2
}

-- Simple sentiment keywords
local sentimentKeywords = {
    happy = {"yay","great","awesome","fun","cool","nice","love","good"},
    sad = {"sad","bad","ugh","hate","angry","frustrated","upset"},
    neutral = {"ok","fine","alright","meh","whatever"}
}

-- Detect mood from message
local function detectMood(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, neutral=0}
    for mood, keywords in pairs(sentimentKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then scores[mood] = scores[mood] + 1 end
        end
    end
    local maxMood = "neutral"
    local maxScore = scores.neutral
    for mood, score in pairs(scores) do
        if score > maxScore then
            maxMood = mood
            maxScore = score
        end
    end
    return maxMood
end

-- Modify response based on mood
local function modulateResponse(response, mood)
    if mood == "happy" then
        response = response .. " 😄"
        if math.random() < 0.3 then
            response = response .. " Let's keep going!"
        end
    elseif mood == "sad" then
        response = response .. " 😔"
        if math.random() < 0.3 then
            response = response .. " I hope things get better!"
        end
    elseif mood == "neutral" then
        -- Slightly random neutral variations
        if math.random() < 0.2 then
            response = response .. " 🙂"
        end
    end
    return response
end

-- Wrap interpret function to include mood modulation
local oldInterpretMood = interpret
interpret = function(message, user)
    local mood = detectMood(message)
    local resp = oldInterpretMood(message, user)
    resp = modulateResponse(resp, mood)
    return resp
end
-- ===== PART 12: CONTEXT-AWARE HUMOR & SARCASM =====
