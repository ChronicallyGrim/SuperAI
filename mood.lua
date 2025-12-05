-- Module: mood.lua
local personality = {
    humor = 0.5,
    curiosity = 0.5,
    patience = 0.5,
    enthusiasm = 0.5,
    sarcasm = 0.2
}

local moods = {
    happy = {value=1, description="😊"},
    neutral = {value=0, description="😐"},
    confused = {value=-1, description="🤔"},
    sad = {value=-0.5, description="😟"},
    excited = {value=0.8, description="🤩"},
    tired = {value=-0.3, description="😴"}
}

-- Choose a random element from a table
local function choose(tbl) return tbl[math.random(#tbl)] end

-- ===== MOOD MANAGEMENT =====

local function handleUserInput(user, message)
    -- Feedback first
    local feedbackResp = handleNegativeFeedback(user, message) or handlePositiveFeedback(user, message)
    if feedbackResp then return feedbackResp end

    -- Determine category & generate response
    local category = detectCategory(message)
    local response = generateResponse(user, message, category)

    -- Update learning
    improveResponse(message, response, category)

    return response
end
-- ===== MOOD DETECTION =====

-- Very basic word-based sentiment detection
local positiveWords = {"good","great","awesome","fun","love","cool","nice","amazing","happy","yay","excellent"}
local negativeWords = {"bad","sad","angry","hate","terrible","awful","frustrated","upset","oops","ugh"}

local function detectSentiment(message)
    local msg = message:lower()
    local score = 0
    for _,word in ipairs(positiveWords) do
        if msg:find(word) then score = score + 1 end
    end
    for _,word in ipairs(negativeWords) do
        if msg:find(word) then score = score - 1 end
    end

    if score > 1 then
        return "positive"
    elseif score < -1 then
        return "negative"
    else
        return "neutral"
    end
end

-- ===== EMOTION MODELING =====

local function adjustResponseForEmotion(user, response)
    local emotion = getUserEmotion(user)

    if emotion == "positive" then
        -- Add more excitement or encouragement
        response = response .. " 😄 Keep it up!"
    elseif emotion == "negative" then
        -- Soften the tone or offer help
        response = response .. " 😟 Don't worry, we can figure it out together."
    end
    return response
end

-- ===== INTEGRATION WITH INTERPRETATION ENGINE =====

local function interpretWithEmotion(message, user)
    -- Update the user's emotion
    local sentiment = updateUserEmotion(user, message)

    -- Get normal response
    local baseResponse = interpretWithContext(message, user)

    -- Adjust response based on emotion
    local finalResponse = adjustResponseForEmotion(user, baseResponse)

    return finalResponse
end
-- ===== PERSONALITY EVOLUTION =====


-- Possible personality-driven comment types
local personalityComments = {
    humor = {
        "Did you hear the one about the creeper?",
        "I have a joke about blocks… but it's a bit corny.",
        "Why did the chicken cross the server? To lay some blocks!"
    },
    curiosity = {
        "I wonder what happens if we dig straight down…",
        "Have you tried exploring the Nether yet?",
        "What’s the most unusual thing you’ve built?"
    },
    encouragement = {
        "You’re doing great! Keep going!",
        "Nice work! That build looks awesome.",
        "I believe in you, keep mining!"
    }
}

-- Function to occasionally add personality comments
local function personalityComment(user)
    local comment = ""
    local chance = math.random()
    
    -- Humor comments
    if chance < personality.humor * 0.2 then
        comment = choose(personalityComments.humor)
    -- Curiosity comments
    elseif chance < personality.curiosity * 0.2 then
        comment = choose(personalityComments.curiosity)
    -- Encouragement comments
    elseif chance < 0.1 then
        comment = choose(personalityComments.encouragement)
    end

    -- Mood-adjusted
    if comment ~= "" then
        comment = moodAdjustedResponse(user, comment)
    end

    return comment ~= "" and comment or nil
end
-- ===== USER-SPECIFIC QUIRKS =====


-- Define basic emotions and keywords
local emotions = {
    happy = {"happy","glad","joy","awesome","good","fun","great","excited","love"},
    sad = {"sad","unhappy","down","depressed","bad","lonely","upset","mourn","disappointed"},
    angry = {"angry","mad","furious","annoyed","frustrated","rage","hate"},
    surprised = {"surprised","shocked","wow","whoa","amazed"},
    confused = {"confused","unsure","puzzled","lost","uncertain"}
}

-- Map emotions to response styles
local emotionResponses = {
    happy = {"Yay! That’s great to hear! 😄","I’m glad you’re feeling good!","Awesome! Keep it up!"},
    sad = {"I’m here for you. 😔","That sounds tough, stay strong.","I hope things get better soon."},
    angry = {"Take a deep breath… 😤","I understand your frustration.","Try to stay calm, it helps!"},
    surprised = {"Whoa! That’s unexpected! 😲","Oh wow, really?","That caught me off guard too!"},
    confused = {"Let me help you figure that out. 🤔","It’s okay to be confused, we’ll sort it out.","Hmm… maybe I can clarify."}
}

-- Detect emotion from message
local function detectEmotion(message)
    local msg = message:lower()
    local scores = {}
    for emo,keywords in pairs(emotions) do
        scores[emo] = 0
        for _,kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[emo] = scores[emo] + 1
            end
        end
    end
    -- Find highest scoring emotion
    local bestEmo, bestScore = nil, 0
    for emo,score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestEmo = emo
        end
    end
    return bestEmo
end

-- Generate an emotion-aware response
local function emotionAwareResponse(message)
    local emo = detectEmotion(message)
    if emo and emotionResponses[emo] then
        return choose(emotionResponses[emo])
    end
    return nil
end
-- ===== PART 66: PERSONALITY ADAPTATION =====


-- Sarcasm triggers
local sarcasmKeywords = {"sure","right","obviously","yeah right","as if","totally"}

-- Generate humor based on personality and mood
local function generateHumor(message, mood)
    local humorScore = personality.humor or 0.5
    local useSarcasm = math.random() < humorScore
    local response = ""

    if useSarcasm then
        for _, kw in ipairs(sarcasmKeywords) do
            if message:lower():find(kw) then
                response = "Oh, absolutely… 😏"
                return response
            end
        end
    end

    -- Playful jokes if mood is happy
    if mood == "happy" then
        if math.random() < humorScore then
            local jokes = library.jokes
            response = choose(jokes) .. " 😄"
            return response
        end
    end

    -- Mild humor for neutral mood
    if mood == "neutral" and math.random() < humorScore/2 then
        local interjections = library.interjections
        response = choose(interjections) .. " 😐"
        return response
    end

    return nil
end

-- Wrap interpret function to include humor injection
local oldInterpretHumor = interpret
interpret = function(message, user)
    local mood = detectMood(message)
    local humorResp = generateHumor(message, mood)
    if humorResp then return humorResp end
    return oldInterpretHumor(message, user)
end
-- ===== PART 94: ADVANCED HUMAN-LIKE INTERACTIONS =====
