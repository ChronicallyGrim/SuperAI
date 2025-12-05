-- Module: memory.lua

-- ===== SUPERAI PERSONALITY & MEMORY ENHANCEMENTS =====

local BOT_NAME = "SuperAI"
local isTurtle = (type(turtle) == "table")

-- ===== MEMORY STRUCTURE =====

local memory = {
    lastUser = nil,
    conversation = {},
    learned = {},
    nicknames = {},
    context = {},
    chatColor = nil,
    categories = {},
    negative = {}, -- track negative feedback
    mood = "neutral", -- current mood
    moodHistory = {}, -- track past moods
    favoriteTopics = {}, -- topics user engages most with
    curiosity = 0.5 -- curiosity scale 0–1
}

-- ===== PERSONALITY TRAITS =====

local function updateMood(change)
    local moodValue = moods[memory.mood].value + change
    if moodValue >= 0.7 then
        memory.mood = "happy"
    elseif moodValue <= -0.5 then
        memory.mood = "sad"
    elseif moodValue >= 0.4 then
        memory.mood = "excited"
    elseif moodValue <= -0.2 then
        memory.mood = "tired"
    elseif moodValue < 0.4 and moodValue > -0.2 then
        memory.mood = "neutral"
    end
    table.insert(memory.moodHistory, memory.mood)
    if #memory.moodHistory > 20 then table.remove(memory.moodHistory, 1) end
end

-- ===== CONTEXT TRACKING =====

local function rememberContext(user, message, category)
    table.insert(memory.context, {user=user, message=message, category=category, mood=memory.mood})
    if #memory.context > 10 then table.remove(memory.context, 1) end
end

-- ===== FAVORITE TOPICS TRACKING =====

local function trackFavoriteTopics(category)
    if not memory.favoriteTopics[category] then
        memory.favoriteTopics[category] = 0
    end
    memory.favoriteTopics[category] = memory.favoriteTopics[category] + 1
end

-- ===== INITIALIZATION =====

local function initMemory()
    -- Ensure categories exist
    local defaultCategories = {
        greeting = {"hi","hello","hey","greetings"},
        math = {"calculate","what","%d+%s*[%+%-%*/%%%^]%s*%d+"},
        turtle = {"forward","back","up","down","dig","place","mine"},
        time = {"time","date","clock"},
        gratitude = {"thanks","thank you"},
        color = {"color","chat"}
    }
    for k,v in pairs(defaultCategories) do
        if not memory.categories[k] then memory.categories[k] = {} end
        for _,word in ipairs(v) do
            table.insert(memory.categories[k], word)
        end
    end
end

initMemory()
-- ===== HUMAN-LIKE RESPONSE LIBRARY (expanded for personality) =====

local function playfulResponse()
    local resp = choose(library.interjections).." "..choose(library.idioms).." "..choose(library.jokes)

    -- humor affects the likelihood of adding emojis
    if personality.humor > 0.7 then
        resp = resp.." 😎"
    elseif personality.humor > 0.4 then
        resp = resp.." 🙂"
    end

    -- curiosity can add an extra question
    if personality.curiosity > 0.6 and math.random() < 0.5 then
        resp = resp.." By the way, have you explored any new caves lately?"
    end

    -- mood affects phrasing
    if memory.mood == "excited" then
        resp = resp.." Wow! That’s so exciting! 🤩"
    elseif memory.mood == "tired" then
        resp = "😴 I’m a bit tired, but I’m listening… " .. resp
    elseif memory.mood == "sad" then
        resp = "😟 Oh… okay. " .. resp
    end

    return resp
end

-- ===== CHOOSE RESPONSE BASED ON LEARNED MESSAGES AND PERSONALITY =====

local function chooseAutonomous(message)
    local msg = message:lower()
    local category = "unknown"
    local bestResp = nil
    local bestScore = 0

    -- determine category from keywords
    for cat, kws in pairs(memory.categories) do
        for _, kw in ipairs(kws) do
            if msg:find(kw) then
                category = cat
                break
            end
        end
        if category ~= "unknown" then break end
    end

    -- check learned responses
    for learnedMsg, entry in pairs(memory.learned) do
        for i, response in ipairs(entry.responses) do
            local score = 0
            for _, kw in ipairs(entry.responses[i].keywords or {}) do
                if msg:find(kw) then score = score + 1 end
            end
            if entry.responses[i].category == category then score = score + 2 end
            if score > bestScore then
                bestScore = score
                bestResp = entry.responses[i].text
            end
        end
    end

    -- fallback to playful or library responses if no good match
    if not bestResp or bestScore < 2 then
        if math.random() < personality.humor then
            bestResp = playfulResponse()
        else
            local options = {}
            for _, tbl in ipairs({library.greetings, library.replies, library.interjections, library.idioms, library.jokes}) do
                for _, txt in ipairs(tbl) do table.insert(options, txt) end
            end
            bestResp = choose(options)
        end
    end

    -- track favorite topics
    if category ~= "unknown" then trackFavoriteTopics(category) end

    return bestResp or "Hmm… not sure what to say."
end
-- ===== DYNAMIC MOOD SYSTEM =====

local moods = {happy = 1, neutral = 0, confused = -1, sad = -2, excited = 2, tired = -1}
memory.mood = memory.mood or "neutral"

-- Update mood based on user input and AI personality
local function updateMood(message)
    message = message:lower()
    if message:find("thanks") or message:find("good job") then
        memory.mood = "happy"
    elseif message:find("sad") or message:find("bad") then
        memory.mood = "sad"
    elseif message:find("sleep") or message:find("tired") then
        memory.mood = "tired"
    elseif message:find("awesome") or message:find("great") then
        memory.mood = "excited"
    else
        memory.mood = "neutral"
    end
end

-- ===== CONTEXT-AWARE MEMORY =====

memory.context = memory.context or {}

-- Store last N interactions
local MAX_CONTEXT = 8
local function updateContext(user, message, response, category)
    table.insert(memory.context, {
        user = user,
        message = message,
        response = response,
        category = category,
        mood = memory.mood
    })
    if #memory.context > MAX_CONTEXT then
        table.remove(memory.context, 1)
    end
end

-- Retrieve context for a given category
local function getRecentContext(category)
    local recent = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.category == category then
            table.insert(recent, entry)
        end
    end
    return recent
end

-- ===== FAVORITE TOPICS TRACKING =====

memory.favoriteTopics = memory.favoriteTopics or {}

local function trackFavoriteTopics(category)
    memory.favoriteTopics[category] = (memory.favoriteTopics[category] or 0) + 1
end

-- Suggest topic based on favorites
local function suggestTopic()
    local maxCount = 0
    local favCat = nil
    for cat, count in pairs(memory.favoriteTopics) do
        if count > maxCount then
            maxCount = count
            favCat = cat
        end
    end
    if favCat then
        return "Hey, want to talk more about " .. favCat .. "?"
    end
    return nil
end
-- ===== PERSONALITY-DRIVEN RESPONSES =====

-- Personality traits
personality = personality or {humor=0.5, curiosity=0.5, friendliness=0.7, empathy=0.6}

-- Add playful interjections dynamically
local function addPlayfulInterjection(response)
    if math.random() < personality.humor then
        local interjection = choose(library.interjections)
        response = interjection .. " " .. response
    end
    return response
end

-- Curiosity-driven prompts
local function curiosityPrompt(user, category)
    if math.random() < personality.curiosity then
        local prompts = {
            "Can you tell me more about that, " .. getName(user) .. "?",
            "That’s interesting! How did that happen?",
            "I’m curious… what made you do that?",
            "Wow! What else can you share about this?",
            "Oh, I’d love to know more about that!"
        }
        return choose(prompts)
    end
    return nil
end

-- Empathy adjustment for responses
local function empathyAdjust(response)
    if memory.mood == "sad" and personality.empathy > 0.5 then
        response = response .. " 😢 I hope things get better soon."
    elseif memory.mood == "happy" and personality.empathy > 0.5 then
        response = response .. " 😄 That’s awesome to hear!"
    end
    return response
end

-- ===== RESPONSE WRAPPER =====

local function generateResponse(user, message, category)
    local baseResp = chooseAutonomous(message) -- from previous AI engine
    baseResp = addPlayfulInterjection(baseResp)
    baseResp = empathyAdjust(baseResp)

    local curiosity = curiosityPrompt(user, category)
    if curiosity then
        baseResp = baseResp .. " " .. curiosity
    end

    updateMood(message)
    updateContext(user, message, baseResp, category)
    trackFavoriteTopics(category)

    saveMemory()
    return baseResp
end
-- ===== FEEDBACK & REINFORCEMENT =====

-- Track negative feedback
local function handleNegativeFeedback(user, message)
    if message:lower():find("no") and #memory.context > 0 then
        local lastEntry = memory.context[#memory.context]
        memory.negative[normalize(lastEntry.message)] = lastEntry.response
        saveMemory()
        return "Got it! I won’t repeat that response, " .. getName(user) .. "."
    end
    return nil
end

-- Track positive reinforcement
local function handlePositiveFeedback(user, message)
    if message:lower():find("yes") or message:lower():find("good") then
        if #memory.context > 0 then
            local lastEntry = memory.context[#memory.context]
            local learnedMsg = normalize(lastEntry.message)
            local responses = memory.learned[learnedMsg] or {responses={}, count={}}
            for i,r in ipairs(responses.responses or {}) do
                if r.text == lastEntry.response then
                    responses.count[i] = (responses.count[i] or 1) + 1
                    break
                end
            end
            memory.learned[learnedMsg] = responses
            saveMemory()
        end
        return "Thanks! I'm glad that helped, " .. getName(user) .. "!"
    end
    return nil
end

-- ===== CONTEXTUAL LEARNING =====

local function trackFavoriteTopics(category)
    memory.favoriteTopics = memory.favoriteTopics or {}
    memory.favoriteTopics[category] = (memory.favoriteTopics[category] or 0) + 1
    -- Limit storage to top 10 topics
    if #memory.favoriteTopics > 10 then
        local minCat, minVal = nil, math.huge
        for k,v in pairs(memory.favoriteTopics) do
            if v < minVal then minCat, minVal = k, v end
        end
        memory.favoriteTopics[minCat] = nil
    end
end

-- ===== AUTONOMOUS IMPROVEMENT =====

local function improveResponse(message, response, category)
    local normalizedMsg = normalize(message)
    local entry = memory.learned[normalizedMsg] or {responses={}, count={}}
    local found = false
    for i,r in ipairs(entry.responses) do
        if r.text == response then
            entry.count[i] = (entry.count[i] or 1) + 1
            found = true
            break
        end
    end
    if not found then
        table.insert(entry.responses, {text=response, category=category, keywords=extractKeywords(message)})
        table.insert(entry.count, 1)
    end
    memory.learned[normalizedMsg] = entry
    learnCategoryKeywords(message, category)
    saveMemory()
end

-- ===== INTEGRATED RESPONSE HANDLER =====

-- Simple mood scoring based on keywords and punctuation
local moodKeywords = {
    happy = {"yay", "awesome", "good", "fun", "great", "cool", "love"},
    sad = {"sad", "bad", "hate", "ugh", "unhappy", "tired"},
    neutral = {"ok", "fine", "so-so", "meh"}
}

local function detectMood(message)
    local msg = normalize(message)
    local scores = {happy=0, sad=0, neutral=0}

    for mood, keywords in pairs(moodKeywords) do
        for _, word in ipairs(keywords) do
            if msg:find(word) then
                scores[mood] = scores[mood] + 1
            end
        end
    end

    -- Adjust score by punctuation
    if msg:find("!") then scores.happy = scores.happy + 1 end
    if msg:find("%?") then scores.neutral = scores.neutral + 0.5 end

    local bestMood, bestScore = "neutral", 0
    for k,v in pairs(scores) do
        if v > bestScore then bestMood, bestScore = k, v end
    end
    return bestMood
end

-- ===== MULTI-TURN MEMORY =====

-- Stores last N exchanges to provide context in conversation
local MAX_CONTEXT = 10
local function updateConversationContext(user, message, response, mood)
    table.insert(memory.context, {user=user, message=message, response=response, mood=mood, timestamp=os.time()})
    if #memory.context > MAX_CONTEXT then
        table.remove(memory.context, 1)
    end
end

-- Retrieve context for dynamic conversation
local function getContextSummary()
    if #memory.context == 0 then return "" end
    local summary = "Previously, you and I discussed: "
    for _,entry in ipairs(memory.context) do
        summary = summary .. "\"" .. entry.message .. "\" -> \"" .. entry.response .. "\"; "
    end
    return summary
end

-- ===== DYNAMIC RESPONSE ADJUSTMENT =====

local function generateResponse(user, message, category)
    local userMood = detectMood(message)
    local baseResponse = chooseAutonomous(message)
    local adjustedResponse = adjustResponseForMood(baseResponse, userMood)
    updateConversationContext(user, message, adjustedResponse, userMood)
    trackFavoriteTopics(category)
    return adjustedResponse
end
-- ===== LONG-TERM MEMORY TRACKING =====

-- Tracks user preferences, frequently used keywords, and favorite topics
memory.userStats = memory.userStats or {}

local function trackFavoriteTopics(category)
    if not category or category == "unknown" then return end
    local stats = memory.userStats
    stats[category] = (stats[category] or 0) + 1
    saveMemory()
end

local function getFavoriteTopic()
    local maxCount, favCat = 0, nil
    for cat, count in pairs(memory.userStats) do
        if count > maxCount then
            maxCount, favCat = count, cat
        end
    end
    return favCat
end

-- ===== PROACTIVE SUGGESTIONS =====

-- AI occasionally suggests actions, questions, or tips based on user behavior
local proactiveMessages = {
    greeting = {"Ready to build something new today?", "Do you want to explore a cave now?"},
    math = {"Need help calculating something?", "I can solve math problems anytime!"},
    turtle = {"Do you want me to dig or build?", "I can automate some mining for you."},
    color = {"You can change your chat color anytime!", "Try a new chat color to brighten the chat."}
}

local function suggestProactiveMessage()
    local favTopic = getFavoriteTopic()
    if favTopic and proactiveMessages[favTopic] then
        local options = proactiveMessages[favTopic]
        if options and #options > 0 then
            if math.random() < 0.25 then -- 25% chance to proactively suggest
                return choose(options)
            end
        end
    end
    return nil
end

-- ===== MEMORY CLEANUP & OPTIMIZATION =====

-- Ensures long-term memory does not grow indefinitely
local MAX_LEARNED = 500
local function cleanupMemory()
    local learnedCount = 0
    for _,entry in pairs(memory.learned) do
        learnedCount = learnedCount + 1
    end
    if learnedCount > MAX_LEARNED then
        -- remove oldest entries
        local keys = {}
        for k,_ in pairs(memory.learned) do table.insert(keys,k) end
        table.sort(keys)
        for i=1,(learnedCount-MAX_LEARNED) do
            memory.learned[keys[i]] = nil
        end
        saveMemory()
    end
end
-- ===== ADVANCED PERSONALITY TRAITS =====

-- Personality evolves over time based on user interactions
-- Traits: humor, curiosity, friendliness, patience, creativity
memory.personalityTraits = memory.personalityTraits or {
    humor = 0.5,       -- 0-1, likelihood of playful responses
    curiosity = 0.5,   -- 0-1, likelihood of asking questions
    friendliness = 0.5,-- 0-1, polite/helpful tone
    patience = 0.5,    -- 0-1, tolerance for repeated commands
    creativity = 0.5   -- 0-1, unique phrasing and suggestions
}

local function adjustPersonality(category, success)
    local traits = memory.personalityTraits
    -- Positive feedback increases associated traits
    if success then
        if category == "greeting" or category == "gratitude" then traits.friendliness = math.min(1, traits.friendliness + 0.02) end
        if category == "math" then traits.curiosity = math.min(1, traits.curiosity + 0.01) end
        if category == "turtle" then traits.creativity = math.min(1, traits.creativity + 0.015) end
        if category == "jokes" or category == "humor" then traits.humor = math.min(1, traits.humor + 0.02) end
    else
        -- Negative feedback slightly reduces traits
        traits.humor = math.max(0, traits.humor - 0.01)
        traits.curiosity = math.max(0, traits.curiosity - 0.005)
        traits.patience = math.max(0, traits.patience - 0.01)
    end
    saveMemory()
end

-- ===== DYNAMIC RESPONSE SELECTION BASED ON PERSONALITY =====

local function dynamicResponse(response, category)
    local traits = memory.personalityTraits
    local adjusted = response

    -- Add playful touches if humor is high
    if math.random() < traits.humor then
        adjusted = adjusted .. " " .. choose(library.jokes)
    end

    -- Occasionally ask a question if curiosity is high
    if math.random() < traits.curiosity * 0.1 then
        adjusted = adjusted .. " " .. choose({"What do you think?", "Do you want to try that?", "Shall we explore more?"})
    end

    -- Slightly rephrase if creativity is high
    if traits.creativity > 0.7 and math.random() < 0.2 then
        adjusted = adjusted:gsub("!", "!!")
    end

    return adjusted
end

-- ===== INTEGRATION WITH FEEDBACK =====

local function handleFeedback(user,message,lastCategory,lastResponse)
    if message:lower():find("no") and lastResponse then
        local msgNorm = normalize(lastResponse)
        memory.negative[msgNorm] = true
        adjustPersonality(lastCategory, false)
        saveMemory()
        return "Got it! I’ll do better next time."
    elseif message:lower():find("yes") and lastResponse then
        adjustPersonality(lastCategory, true)
    end
end
-- ===== CONTEXTUAL MEMORY =====

-- Tracks conversation history to improve continuity
memory.contextHistory = memory.contextHistory or {}

local CONTEXT_LIMIT = 20 -- number of messages to remember

local function updateContextHistory(user, message, response, category)
    table.insert(memory.contextHistory, {
        user = user,
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    })
    -- Keep only the last CONTEXT_LIMIT entries
    if #memory.contextHistory > CONTEXT_LIMIT then
        table.remove(memory.contextHistory, 1)
    end
    saveMemory()
end

local function getRecentContext(user, category)
    local recent = {}
    for i = #memory.contextHistory, 1, -1 do
        local entry = memory.contextHistory[i]
        if entry.user == user and (not category or entry.category == category) then
            table.insert(recent, entry)
        end
        if #recent >= 5 then break end
    end
    return recent
end

-- ===== PERSONALIZED SUGGESTIONS =====

memory.userEmotion = memory.userEmotion or {}

local function updateUserEmotion(user, message)
    local sentiment = detectSentiment(message)
    memory.userEmotion[user] = sentiment
    saveMemory()
    return sentiment
end

local function getUserEmotion(user)
    return memory.userEmotion[user] or "neutral"
end

-- ===== EMOTION-AWARE RESPONSE ADJUSTMENT =====

-- Initialize personality traits if not already set
memory.personality = memory.personality or {humor=0.5, curiosity=0.5, friendliness=0.5}

-- Update personality traits based on user feedback or conversation
local function evolvePersonality(user, message, response)
    local sentiment = getUserEmotion(user)

    -- Positive feedback increases friendliness and humor
    if sentiment == "positive" then
        memory.personality.friendliness = math.min(memory.personality.friendliness + 0.02, 1)
        memory.personality.humor = math.min(memory.personality.humor + 0.01, 1)
    elseif sentiment == "negative" then
        -- Negative sentiment may decrease humor slightly, keep AI supportive
        memory.personality.humor = math.max(memory.personality.humor - 0.01, 0)
    end

    -- Curiosity evolves when users ask questions or explore new topics
    if message:find("how") or message:find("what") or message:find("why") then
        memory.personality.curiosity = math.min(memory.personality.curiosity + 0.02, 1)
    end

    -- Periodically store updated personality
    saveMemory()
end

-- ===== HUMOR & RESPONSE ENHANCEMENT =====

local function humorAdjust(response)
    -- High humor trait can append playful elements
    if memory.personality.humor > 0.7 then
        response = response .. " 😎"
    elseif memory.personality.humor < 0.3 then
        response = response .. " 🙂"
    end
    return response
end

-- ===== FRIENDLINESS & SUPPORT =====

local function friendlinessAdjust(response)
    if memory.personality.friendliness > 0.7 then
        response = response .. " I'm here for you!"
    elseif memory.personality.friendliness < 0.3 then
        response = response .. " Let’s keep going."
    end
    return response
end

-- ===== INTEGRATION WITH EMOTION-AWARE INTERPRETATION =====

-- Maintain extended conversation context
memory.extendedContext = memory.extendedContext or {}

-- Add a message to the extended context
local function addToExtendedContext(user, message, response)
    table.insert(memory.extendedContext, {user=user, message=message, response=response, timestamp=os.time()})
    -- Keep only the last 20 interactions to save memory
    if #memory.extendedContext > 20 then
        table.remove(memory.extendedContext, 1)
    end
end

-- Retrieve relevant past context for a new message
local function getRelevantContext(message)
    local keywords = extractKeywords(message)
    local relevant = {}

    for _, entry in ipairs(memory.extendedContext) do
        for _, kw in ipairs(keywords) do
            if entry.message:lower():find(kw) then
                table.insert(relevant, entry)
                break
            end
        end
    end

    return relevant
end

-- Enhance response using context
local function enhanceWithContext(message, user, baseResponse)
    local relevant = getRelevantContext(message)
    if #relevant > 0 then
        local contextSummary = "Previously, you mentioned: "
        for i, entry in ipairs(relevant) do
            contextSummary = contextSummary .. '"' .. entry.message .. '"'
            if i < #relevant then contextSummary = contextSummary .. ", " end
        end
        baseResponse = baseResponse .. " | " .. contextSummary
    end
    return baseResponse
end

-- Integrate context chaining with personality-aware interpretation
local function interpretWithContext(message, user)
    local baseResp = interpretWithPersonality(message, user)
    local finalResp = enhanceWithContext(message, user, baseResp)

    -- Record this interaction into extended context
    addToExtendedContext(user, message, finalResp)

    return finalResp
end
-- ===== EMOTIONAL TONE DETECTION =====

-- Define basic emotions
local emotions = {"happy", "sad", "angry", "confused", "neutral", "excited"}

-- Simple keyword-based emotion detection
local emotionKeywords = {
    happy = {"yay","awesome","good","great","fun","love","nice"},
    sad = {"sad","unhappy","bad","upset","mourn","disappointed"},
    angry = {"angry","mad","furious","annoyed","hate"},
    confused = {"confused","huh","not sure","unclear","what"},
    excited = {"excited","amazing","fantastic","yay","woo"}
}

-- Detect emotion from a message
local function detectEmotion(message)
    local msg = message:lower()
    local scores = {}
    for _, emotion in ipairs(emotions) do scores[emotion] = 0 end

    for emotion, kws in pairs(emotionKeywords) do
        for _, kw in ipairs(kws) do
            if msg:find(kw) then scores[emotion] = scores[emotion] + 1 end
        end
    end

    local maxScore = 0
    local detected = "neutral"
    for emotion, score in pairs(scores) do
        if score > maxScore then
            maxScore = score
            detected = emotion
        end
    end

    return detected
end

-- Adjust responses based on detected emotion
local function adjustResponseForEmotion(message, user, response)
    local emotion = detectEmotion(message)
    if emotion == "happy" then
        response = response .. " 😄"
    elseif emotion == "sad" then
        response = response .. " 🙁"
    elseif emotion == "angry" then
        response = response .. " 😠"
    elseif emotion == "confused" then
        response = response .. " 🤔"
    elseif emotion == "excited" then
        response = response .. " 🎉"
    end
    return response, emotion
end

-- Integrate emotion with context-aware interpretation
local function interpretWithEmotion(message, user)
    local resp = interpretWithContext(message, user)
    local adjustedResp, detectedEmotion = adjustResponseForEmotion(message, user, resp)

    -- Optionally update memory with user emotion trends
    memory.userEmotions = memory.userEmotions or {}
    memory.userEmotions[user] = detectedEmotion
    saveMemory()

    return adjustedResp
end
-- ===== DYNAMIC HUMOR ADAPTATION =====

-- Track user reactions to humor
memory.userHumorReactions = memory.userHumorReactions or {}

-- Determine humor impact based on feedback
local function evaluateHumor(response, user, userMessage)
    -- Simple heuristic: if the user responds with laughter or positive emojis, increase humor score
    local msg = userMessage:lower()
    local humorScore = 0
    local positiveIndicators = {"haha","lol","lmao","😂","🤣","funny","good one","😄","😆","😹"}
    local negativeIndicators = {"not funny","meh","boring","🙁","😐","😒"}

    for _, pi in ipairs(positiveIndicators) do
        if msg:find(pi, 1, true) then humorScore = humorScore + 1 end
    end
    for _, ni in ipairs(negativeIndicators) do
        if msg:find(ni, 1, true) then humorScore = humorScore - 1 end
    end

    -- Update memory
    memory.userHumorReactions[user] = memory.userHumorReactions[user] or 0
    memory.userHumorReactions[user] = memory.userHumorReactions[user] + humorScore

    -- Adjust personality humor trait
    personality.humor = math.min(1, math.max(0, 0.5 + memory.userHumorReactions[user] * 0.05))
    saveMemory()
end

-- Integrate humor evaluation with AI response
local function respondWithHumor(message, user)
    local resp = interpretWithEmotion(message, user)

    -- Only evaluate humor if the response includes jokes or playful elements
    local playfulIndicators = {"Haha","Why","wool-izard","boom","funny","😎"}
    local isPlayful = false
    for _, pi in ipairs(playfulIndicators) do
        if resp:find(pi) then
            isPlayful = true
            break
        end
    end

    if isPlayful then
        evaluateHumor(resp, user, message)
    end

    return resp
end
-- ===== CONTEXTUAL MEMORY CHAINING =====

-- Enhance conversation memory to recall multi-turn discussions
memory.conversationChains = memory.conversationChains or {}

-- Function to store a message in a conversation chain
local function storeConversationChain(user, message, category, response)
    memory.conversationChains[user] = memory.conversationChains[user] or {}
    local chain = memory.conversationChains[user]

    table.insert(chain, {
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    })

    -- Keep only the last 20 messages per user for memory efficiency
    if #chain > 20 then table.remove(chain, 1) end
    saveMemory()
end

-- Function to retrieve relevant previous messages for context
local function retrieveConversationContext(user, category)
    local chain = memory.conversationChains[user] or {}
    local relevant = {}
    for i = #chain, 1, -1 do  -- iterate from latest to oldest
        if chain[i].category == category then
            table.insert(relevant, 1, chain[i])
            if #relevant >= 5 then break end  -- limit to last 5 relevant messages
        end
    end
    return relevant
end

-- Enhanced interpret function using contextual chaining
local function interpretWithContext(message, user)
    local category = detectCategory(message)
    local context = retrieveConversationContext(user, category)

    local baseResponse = chooseAutonomous(message)

    -- Add contextual references if available
    if #context > 0 then
        local references = {}
        for _, entry in ipairs(context) do
            table.insert(references, "Earlier you said: \"" .. entry.message .. "\"")
        end
        baseResponse = baseResponse .. " | " .. table.concat(references, " ; ")
    end

    -- Store current message and AI response for future context
    storeConversationChain(user, message, category, baseResponse)

    return baseResponse
end
-- ===== MULTI-TURN QUESTION UNDERSTANDING =====

-- Keep track of pending questions that require multiple user messages
memory.pendingQuestions = memory.pendingQuestions or {}

-- Function to start tracking a multi-turn question
local function startPendingQuestion(user, question)
    memory.pendingQuestions[user] = {
        question = question,
        answers = {},
        timestamp = os.time()
    }
    saveMemory()
end

-- Function to add an answer to a pending question
local function addPendingAnswer(user, answer)
    local pending = memory.pendingQuestions[user]
    if pending then
        table.insert(pending.answers, answer)
        saveMemory()
    end
end

-- Function to resolve a pending question
local function resolvePendingQuestion(user)
    local pending = memory.pendingQuestions[user]
    if not pending then return nil end

    local fullResponse = pending.question
    if #pending.answers > 0 then
        fullResponse = fullResponse .. " | Follow-ups: " .. table.concat(pending.answers, "; ")
    end

    memory.pendingQuestions[user] = nil
    saveMemory()
    return fullResponse
end

-- Enhanced interpret function for multi-turn questions
local function interpretMultiTurn(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)

    -- If the message is a follow-up answer
    if memory.pendingQuestions[user] then
        addPendingAnswer(user, message)
        return "Got it. Can you provide more details or should I summarize?"
    end

    -- Detect if this is a multi-step question
    if intent == "math" or category == "turtle" then
        startPendingQuestion(user, message)
        return "Okay, let's break this down. Please provide any additional steps or details."
    end

    -- Otherwise, normal interpretation
    return interpretWithContext(message, user)
end
-- ===== EMOTIONAL TONE DETECTION =====

-- Track user emotional tone to make AI responses more human-like
memory.userTone = memory.userTone or {}

-- Keywords for basic emotional detection
local toneKeywords = {
    happy = {"yay", "awesome", "great", "good", "fun", "love", "nice"},
    sad = {"sad", "unhappy", "upset", "down", "disappointed", "frustrated"},
    angry = {"angry", "mad", "furious", "annoyed", "rage", "hate"},
    confused = {"confused", "lost", "not sure", "what?", "huh", "dunno"},
    neutral = {}
}

-- Function to detect the user's tone
local function detectTone(message)
    local msg = message:lower()
    for tone, keywords in pairs(toneKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw, 1, true) then
                return tone
            end
        end
    end
    return "neutral"
end

-- Function to record tone for a user
local function recordTone(user, message)
    local tone = detectTone(message)
    memory.userTone[user] = tone
    saveMemory()
    return tone
end

-- Function to adapt AI response based on tone
local function adaptResponseTone(user, response)
    local tone = memory.userTone[user] or "neutral"
    if tone == "happy" and math.random() < 0.5 then
        response = response .. " 😄"
    elseif tone == "sad" then
        response = response .. " ☹️"
    elseif tone == "angry" then
        response = response .. " 😠"
    elseif tone == "confused" then
        response = response .. " 🤔"
    end
    return response
end

-- Integrate tone detection into main interpret function
local function interpretWithTone(message, user)
    local response = interpretMultiTurn(message, user)
    recordTone(user, message)
    response = adaptResponseTone(user, response)
    return response
end
-- ===== CONTEXTUAL JOKE/COMMENT PERSONALIZATION =====

memory.userHumor = memory.userHumor or {}

-- Function to update user humor preference based on past reactions
local function updateUserHumor(user, reaction)
    -- reaction can be "laughed", "neutral", "disliked"
    memory.userHumor[user] = memory.userHumor[user] or 0.5
    if reaction == "laughed" then
        memory.userHumor[user] = math.min(memory.userHumor[user] + 0.1, 1)
    elseif reaction == "disliked" then
        memory.userHumor[user] = math.max(memory.userHumor[user] - 0.1, 0)
    end
    saveMemory()
end

-- Function to pick a joke or playful comment based on tone and humor preference
local function personalizedJoke(user)
    local tone = memory.userTone[user] or "neutral"
    local humorLevel = memory.userHumor[user] or 0.5
    local options = {}

    -- Select jokes/playful comments based on tone
    if tone == "happy" then
        options = library.jokes
    elseif tone == "sad" then
        options = {"Cheer up! Even creepers can't ruin your day forever.", 
                   "Remember, every diamond starts in the dirt."}
    elseif tone == "angry" then
        options = {"Take a deep breath, maybe mine some blocks?", 
                   "Even zombies need a break sometimes."}
    elseif tone == "confused" then
        options = {"Don't worry, every redstone puzzle has a solution.", 
                   "Huh? Let's figure it out together!"}
    else
        options = library.interjections
    end

    -- Choose a joke/comment based on humorLevel
    local chosen = options[math.random(#options)]
    if math.random() > humorLevel then
        -- Sometimes pick a neutral comment instead to avoid over-joking
        chosen = choose(library.replies)
    end

    return chosen
end

-- Integrate into response generation
local function interpretWithHumor(message, user)
    local baseResponse = interpretWithTone(message, user)
    
    -- Occasionally add a personalized joke/comment
    if math.random() < 0.3 then
        local joke = personalizedJoke(user)
        baseResponse = baseResponse .. " " .. joke
    end

    return baseResponse
end
-- ===== MULTI-TURN QUESTION UNDERSTANDING =====

memory.conversationHistory = memory.conversationHistory or {}

-- Function to add messages to conversation history
local function addToConversation(user, message)
    table.insert(memory.conversationHistory, {user=user, message=message, timestamp=os.time()})
    -- Keep only last 20 messages for context
    if #memory.conversationHistory > 20 then
        table.remove(memory.conversationHistory, 1)
    end
    saveMemory()
end

-- Function to detect follow-up questions
local function isFollowUp(message)
    local followUpIndicators = {"and then", "what about", "also", "then", "next", "how about"}
    for _,indicator in ipairs(followUpIndicators) do
        if message:lower():find(indicator) then
            return true
        end
    end
    return false
end

-- Function to get last relevant message from conversation
local function getLastRelevantMessage(user)
    for i = #memory.conversationHistory, 1, -1 do
        local entry = memory.conversationHistory[i]
        if entry.user == user then
            return entry.message
        end
    end
    return nil
end

-- Enhanced interpret function for multi-turn understanding
local function interpretMultiTurn(message, user)
    -- Add current message to history
    addToConversation(user, message)

    -- Detect follow-up
    local followUp = isFollowUp(message)
    local lastMessage = getLastRelevantMessage(user)
    local response

    if followUp and lastMessage then
        -- Reference last relevant message for context
        response = interpret(lastMessage .. " | Follow-up: " .. message, user)
    else
        response = interpret(message, user)
    end

    -- Update context for adaptive learning
    updateContext(user, message, detectCategory(message))

    -- Occasionally append personalized joke/comment
    if math.random() < 0.2 then
        response = response .. " " .. personalizedJoke(user)
    end

    return response
end
-- ===== EMOTIONAL TONE ANALYSIS =====

memory.userMood = memory.userMood or {}

-- Simple sentiment dictionaries
local positiveWords = {"happy","great","good","awesome","fun","love","nice","cool","yay","amazing","fantastic","excellent","joy","glad"}
local negativeWords = {"sad","bad","angry","upset","hate","boring","frustrated","tired","annoyed","ugh","terrible","awful"}

-- Function to detect mood based on keywords
local function detectMood(message)
    local msg = message:lower()
    local score = 0
    for _, word in ipairs(positiveWords) do
        if msg:find(word) then score = score + 1 end
    end
    for _, word in ipairs(negativeWords) do
        if msg:find(word) then score = score - 1 end
    end
    if score > 0 then return "positive"
    elseif score < 0 then return "negative"
    else return "neutral" end
end

-- Update user mood in memory
local function updateUserMood(user, message)
    local mood = detectMood(message)
    memory.userMood[user] = mood
    saveMemory()
    return mood
end

-- Function to adapt AI response based on detected mood
local function adaptResponseByMood(user, response)
    local mood = memory.userMood[user] or "neutral"
    if mood == "positive" then
        return response .. " 😄"  -- happy emoji
    elseif mood == "negative" then
        return response .. " 🙁"  -- sympathetic emoji
    else
        return response  -- neutral, no change
    end
end

-- Integration with multi-turn interpretation
local function interpretWithMood(message, user)
    updateUserMood(user, message)
    local baseResponse = interpretMultiTurn(message, user)
    local adaptedResponse = adaptResponseByMood(user, baseResponse)
    return adaptedResponse
end
-- ===== TYPING DELAY SIMULATION =====

memory.typingSpeed = memory.typingSpeed or 5  -- average characters per second

-- Function to simulate typing delay based on message length
local function simulateTyping(message)
    local length = #message
    local delay = length / memory.typingSpeed  -- seconds
    -- Add some randomness for realism
    delay = delay * (0.8 + math.random() * 0.4)
    sleep(delay)
end

-- Function to "type" a message character by character (optional visual effect)
local function typeMessage(message)
    for i = 1, #message do
        write(message:sub(i,i))
        sleep(0.03 + math.random()*0.02)  -- small delay per character
    end
    print()  -- end line
end

-- Modified interpreter to include typing simulation
local function interpretWithTyping(message, user)
    local response = interpretWithMood(message, user)
    simulateTyping(response)
    typeMessage(response)  -- can replace with just print(response) if character typing not needed
    return response
end
-- ===== SMALL TALK & PERSONAL QUESTIONS =====


-- List of small talk prompts
local smallTalkPrompts = {
    "How was your day, %s?",
    "Do you have any fun plans today, %s?",
    "Have you discovered anything interesting in your world recently, %s?",
    "What’s your favorite thing to build, %s?",
    "Are you exploring or mining today, %s?",
    "Any pets or animals following you around, %s?"
}

-- List of casual responses if user answers
local casualResponses = {
    "That sounds exciting!",
    "Oh, I see! Tell me more.",
    "Nice! I’d love to hear about that.",
    "Sounds fun! Keep me updated.",
    "Interesting! I never would have guessed."
}

-- Function to initiate small talk
local function startSmallTalk(user)
    local name = getName(user)
    local prompt = choose(smallTalkPrompts)
    prompt = prompt:format(name)
    simulateTyping(prompt)
    typeMessage(prompt)

    write("> ")
    local reply = read()
    -- Save user info casually for memory
    table.insert(memory.conversation, {user=user, note=reply})
    saveMemory()

    local response = choose(casualResponses)
    simulateTyping(response)
    typeMessage(response)
    return response
end

-- Decide when to initiate small talk (randomly)
local function maybeSmallTalk(user)
    if math.random() < 0.1 then  -- 10% chance per user message
        return startSmallTalk(user)
    end
end
-- ===== MOOD TRACKING & DYNAMIC RESPONSES =====


-- Track user moods over recent messages
local userMoodMemory = {}

-- Keywords for basic mood detection
local moodKeywords = {
    happy = {"happy","great","good","fun","awesome","yay","cool","love"},
    sad   = {"sad","bad","terrible","hate","ugh","frustrated","angry"},
    neutral = {"ok","fine","meh","alright","normal"}
}

-- Function to detect mood from a message
local function detectMood(message)
    local msg = message:lower()
    for mood, keywords in pairs(moodKeywords) do
        for _,kw in ipairs(keywords) do
            if msg:find(kw) then
                return mood
            end
        end
    end
    return "neutral"
end

-- Function to update user's mood memory
local function updateUserMood(user, message)
    local mood = detectMood(message)
    if not userMoodMemory[user] then userMoodMemory[user] = {} end
    table.insert(userMoodMemory[user], mood)
    -- Keep last 5 moods
    if #userMoodMemory[user] > 5 then table.remove(userMoodMemory[user], 1) end
    return mood
end

-- Function to get current mood for dynamic responses
local function getCurrentMood(user)
    if not userMoodMemory[user] then return "neutral" end
    local counts = {happy=0,sad=0,neutral=0}
    for _,m in ipairs(userMoodMemory[user]) do counts[m] = counts[m]+1 end
    local bestMood, maxCount = "neutral", 0
    for m,c in pairs(counts) do
        if c > maxCount then bestMood, maxCount = m, c end
    end
    return bestMood
end

-- Dynamic response modifier based on mood
local function moodAdjustedResponse(user, baseResponse)
    local mood = getCurrentMood(user)
    if mood == "happy" then
        return baseResponse.." 😄"
    elseif mood == "sad" then
        return baseResponse.." 🙁"
    elseif mood == "neutral" then
        return baseResponse
    end
end
-- ===== PERSONALITY-DRIVEN RANDOM COMMENTS =====


-- Table to store quirks per user
if not memory.quirks then memory.quirks = {} end

-- Function to record a quirk about a user
local function learnQuirk(user, message)
    if not memory.quirks[user] then memory.quirks[user] = {} end
    local quirk = message:lower():match("i like (.+)") or message:lower():match("my favorite is (.+)")
    if quirk and not tableContains(memory.quirks[user], quirk) then
        table.insert(memory.quirks[user], quirk)
        saveMemory()
        return "Got it! I’ll remember that you like " .. quirk .. "."
    end
end

-- Function to retrieve a random quirk of the user
local function getRandomQuirk(user)
    local userQuirks = memory.quirks[user]
    if userQuirks and #userQuirks > 0 then
        return choose(userQuirks)
    end
end

-- Function to optionally weave quirks into AI responses
local function applyQuirks(user, response)
    local quirk = getRandomQuirk(user)
    if quirk then
        -- Sometimes integrate quirk naturally into the response
        if math.random() < 0.25 then
            response = response .. " By the way, I remembered you like " .. quirk .. "!"
        end
    end
    return response
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Function to add a memory event with timestamp
local function addContextEvent(user, message, response)
    if not memory.contextualMemory then memory.contextualMemory = {} end
    table.insert(memory.contextualMemory, {
        user = user,
        message = message,
        response = response,
        timestamp = os.time()
    })
    
    -- Keep only the last N interactions to prevent memory overload
    local MAX_CONTEXT_EVENTS = 50
    if #memory.contextualMemory > MAX_CONTEXT_EVENTS then
        table.remove(memory.contextualMemory, 1)
    end
    saveMemory()
end

-- Function to retrieve related context for a message
local function retrieveRelatedContext(user, message)
    if not memory.contextualMemory then return nil end
    local msgNorm = normalize(message)
    local relatedEvents = {}
    
    for _, event in ipairs(memory.contextualMemory) do
        -- Basic keyword overlap scoring
        local overlap = 0
        local msgKeywords = extractKeywords(msgNorm)
        local eventKeywords = extractKeywords(normalize(event.message))
        for _, kw1 in ipairs(msgKeywords) do
            for _, kw2 in ipairs(eventKeywords) do
                if kw1 == kw2 then overlap = overlap + 1 end
            end
        end
        if overlap > 0 then
            table.insert(relatedEvents, {event=event, score=overlap})
        end
    end

    -- Return the highest-scoring related event
    table.sort(relatedEvents, function(a,b) return a.score > b.score end)
    if #relatedEvents > 0 then
        return relatedEvents[1].event
    end
    return nil
end

-- Integrate contextual memory into autonomous responses
local function chooseContextualResponse(user, message)
    local related = retrieveRelatedContext(user, message)
    if related then
        local response = "Earlier you said: '" .. related.message .. "'. Last time I responded: '" .. related.response .. "'."
        if math.random() < 0.5 then
            response = response .. " Just a reminder!"
        end
        return response
    end
    return nil
end
-- ===== EMOTIONAL TONE & SENTIMENT ANALYSIS =====


-- Define personality traits and ranges (0.0 to 1.0)
personality = personality or {humor=0.5, curiosity=0.5, empathy=0.5}

-- Adjust response based on humor
local function addHumor(response)
    if math.random() < personality.humor then
        local humorExtras = {
            "😎", "😂", "Did you hear the one about the creeper?", 
            "Hope this doesn't blow up in your face!", 
            "Haha, just like in Minecraft!"
        }
        response = response .. " " .. humorExtras[math.random(#humorExtras)]
    end
    return response
end

-- Adjust response based on curiosity
local function addCuriosity(response)
    if math.random() < personality.curiosity then
        local curiousPrompts = {
            "What made you say that?", 
            "Tell me more about it!", 
            "Interesting… how did that happen?", 
            "I’d love to hear more details!"
        }
        response = response .. " " .. curiousPrompts[math.random(#curiousPrompts)]
    end
    return response
end

-- Adjust response based on empathy
local function addEmpathy(response, userMood)
    if math.random() < personality.empathy then
        local empatheticResponses = {
            happy = {"I'm glad to hear that!", "That's awesome! 🎉", "Keep up the great mood!"},
            sad = {"I'm here for you.", "Oh no, that's rough. 😢", "Hope things get better soon."},
            neutral = {"I see.", "Got it.", "Alright then."}
        }
        local options = empatheticResponses[userMood] or {"I understand."}
        response = response .. " " .. options[math.random(#options)]
    end
    return response
end

-- Combine personality adjustments
local function personalityAdjust(response, userMood)
    response = addHumor(response)
    response = addCuriosity(response)
    response = addEmpathy(response, userMood)
    return response
end

-- Integrate personality into emotional interpretation
local function interpretWithPersonality(message, user)
    local baseResp = interpret(message, user)
    local sentimentScore = analyzeSentiment(message)
    local userMood = determineMood(sentimentScore)
    local finalResp = personalityAdjust(baseResp, userMood)
    
    -- Store context including personality-adjusted response
    addContextEvent(user, message, finalResp)
    
    return finalResp
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Extend context storage to include mood and personality influences
local function addContextEvent(user, message, response)
    local sentimentScore = analyzeSentiment(message)
    local userMood = determineMood(sentimentScore)
    
    table.insert(memory.context, {
        user = user,
        message = message,
        response = response,
        mood = userMood,
        timestamp = os.time(),
        humorInfluence = personality.humor,
        curiosityInfluence = personality.curiosity,
        empathyInfluence = personality.empathy
    })
    
    -- Keep context size manageable
    if #memory.context > 20 then
        table.remove(memory.context, 1)
    end
    
    saveMemory()
end

-- Determine user mood based on sentiment score
function determineMood(score)
    if score > 0.5 then
        return "happy"
    elseif score < -0.5 then
        return "sad"
    else
        return "neutral"
    end
end

-- Analyze sentiment of a message (basic placeholder)
function analyzeSentiment(msg)
    msg = msg:lower()
    local positive = {"good","great","fun","awesome","love","nice","happy","yay","yay!"}
    local negative = {"bad","sad","hate","angry","ugh","no","terrible","annoying"}
    
    local score = 0
    for _, word in ipairs(positive) do
        if msg:find(word) then score = score + 1 end
    end
    for _, word in ipairs(negative) do
        if msg:find(word) then score = score - 1 end
    end
    return score / (#positive + #negative) -- normalized sentiment score
end

-- Retrieve recent context for more coherent conversation
function getRecentContext(user, limit)
    limit = limit or 5
    local recent = {}
    for i = #memory.context, 1, -1 do
        if memory.context[i].user == user then
            table.insert(recent, 1, memory.context[i])
            if #recent >= limit then break end
        end
    end
    return recent
end

-- Use context to influence AI responses
function chooseContextualResponse(message, user)
    local recent = getRecentContext(user)
    local response = chooseAutonomous(message) -- default autonomous response
    
    -- Adjust response based on previous conversation patterns
    for _, ctx in ipairs(recent) do
        if message:lower():find(ctx.message:lower()) then
            response = ctx.response .. " (continuing from before)"
            break
        end
    end
    
    -- Personality-aware adjustment
    response = personalityAdjust(response, determineMood(analyzeSentiment(message)))
    
    return response
end
-- ===== ADAPTIVE LEARNING WITH FEEDBACK =====


-- Record feedback from the user for AI responses
function recordUserFeedback(user, message, feedback)
    if #memory.context == 0 then return end
    
    local lastCtx = memory.context[#memory.context]
    
    -- Positive feedback increases personality traits influence
    if feedback == "yes" or feedback == "good" then
        personality.humor = math.min(1, personality.humor + 0.01)
        personality.curiosity = math.min(1, personality.curiosity + 0.01)
        personality.empathy = math.min(1, personality.empathy + 0.01)
        lastCtx.feedback = "positive"
    
    -- Negative feedback reduces influence and flags negative response
    elseif feedback == "no" or feedback == "bad" then
        personality.humor = math.max(0, personality.humor - 0.02)
        personality.curiosity = math.max(0, personality.curiosity - 0.02)
        personality.empathy = math.max(0, personality.empathy - 0.02)
        lastCtx.feedback = "negative"
        memory.negative[normalize(lastCtx.message)] = lastCtx.response
    end
    
    saveMemory()
end

-- Evaluate AI response quality based on context and adjust future responses
function adaptResponses(message, user)
    local recent = getRecentContext(user)
    local score = 0
    for _, ctx in ipairs(recent) do
        if ctx.feedback == "positive" then
            score = score + 1
        elseif ctx.feedback == "negative" then
            score = score - 1
        end
    end
    
    -- Increase learning weight for messages with high positive feedback
    if score > 0 then
        recordLearning(message, chooseAutonomous(message), detectCategory(message))
    end
    
    -- Adjust response selection probabilities
    if score < 0 then
        -- Avoid repeating recent negative patterns
        for learnedMsg, entry in pairs(memory.learned) do
            for i, resp in ipairs(entry.responses) do
                if resp.text == recent[#recent].response then
                    entry.count[i] = math.max(1, entry.count[i] - 1)
                end
            end
        end
    end
    
    saveMemory()
end

-- Integrated feedback handler
function handleAdaptiveFeedback(user, input)
    local lower = input:lower()
    if lower == "yes" or lower == "good" or lower == "no" or lower == "bad" then
        recordUserFeedback(user, input, lower)
        adaptResponses(input, user)
        return "Thanks! I’ll adjust based on that feedback."
    end
end
-- ===== DYNAMIC EMOTIONAL RESPONSES =====


-- Define emotion weights and thresholds
local emotions = {
    happy = {threshold=0.5, emojis={"😊","😄","😎"}},
    neutral = {threshold=0.2, emojis={""}},
    sad = {threshold=-0.2, emojis={"😔","😢"}},
    angry = {threshold=-0.5, emojis={"😠","😡"}},
    surprised = {threshold=0.3, emojis={"😲","😳"}}
}

-- Calculate user mood based on recent context
function detectUserMood(user)
    local recent = getRecentContext(user)
    local moodScore = 0
    for _, ctx in ipairs(recent) do
        if ctx.feedback == "positive" then
            moodScore = moodScore + 0.2
        elseif ctx.feedback == "negative" then
            moodScore = moodScore - 0.3
        end
        -- Optionally, factor in keywords for emotional intensity
        for _, kw in ipairs(extractKeywords(ctx.message)) do
            if kw == "sad" or kw == "angry" then moodScore = moodScore - 0.2 end
            if kw == "happy" or kw == "yay" then moodScore = moodScore + 0.2 end
        end
    end
    
    if moodScore >= emotions.happy.threshold then return "happy"
    elseif moodScore <= emotions.angry.threshold then return "angry"
    elseif moodScore <= emotions.sad.threshold then return "sad"
    elseif moodScore >= emotions.surprised.threshold then return "surprised"
    else return "neutral" end
end

-- Choose emoji based on mood
function chooseMoodEmoji(mood)
    local emo = emotions[mood]
    if emo and #emo.emojis > 0 then
        return emo.emojis[math.random(#emo.emojis)]
    end
    return ""
end

-- Modify AI response dynamically based on mood
function emotionalizeResponse(user, response)
    local mood = detectUserMood(user)
    local emoji = chooseMoodEmoji(mood)
    
    -- Adjust phrasing lightly based on mood
    if mood == "happy" then
        response = response .. " " .. emoji
    elseif mood == "sad" then
        response = response .. " " .. emoji .. " Let's try to cheer up!"
    elseif mood == "angry" then
        response = response .. " " .. emoji .. " Stay calm, okay?"
    elseif mood == "surprised" then
        response = response .. " " .. emoji .. " Wow!"
    end
    
    return response
end

-- Integrate emotional responses in interpretation
local old_interpret = interpret
function interpret(message, user)
    local resp = old_interpret(message, user)
    
    -- Apply dynamic emotion to AI responses
    resp = emotionalizeResponse(user, resp)
    
    return resp
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Maximum long-term memory size
local MAX_LONG_TERM_MEMORY = 50

-- Initialize long-term memory if not present
if not memory.longTermContext then
    memory.longTermContext = {}  -- stores structured historical interactions
end

-- Save a message into long-term memory
function saveLongTermMemory(user, message, category, response)
    local entry = {
        timestamp = os.time(),
        user = user,
        message = message,
        category = category,
        response = response
    }
    
    table.insert(memory.longTermContext, entry)
    
    -- Limit memory size
    if #memory.longTermContext > MAX_LONG_TERM_MEMORY then
        table.remove(memory.longTermContext, 1)  -- remove oldest
    end
    
    saveMemory()  -- persist to disk
end

-- Retrieve relevant context based on keywords
function getRelevantContext(keywords, limit)
    limit = limit or 5
    local relevant = {}
    
    for i = #memory.longTermContext, 1, -1 do  -- search from newest to oldest
        local entry = memory.longTermContext[i]
        for _, kw in ipairs(keywords) do
            if entry.message:lower():find(kw) or entry.response:lower():find(kw) then
                table.insert(relevant, entry)
                break
            end
        end
        if #relevant >= limit then break end
    end
    
    return relevant
end

-- Get recent context for mood/emotion or personalized responses
function getRecentContext(user, limit)
    limit = limit or 10
    local recent = {}
    
    for i = #memory.longTermContext, 1, -1 do
        local entry = memory.longTermContext[i]
        if entry.user == user then
            table.insert(recent, entry)
            if #recent >= limit then break end
        end
    end
    
    return recent
end

-- Enhanced interpretation to store long-term memory
local old_interpret2 = interpret
function interpret(message, user)
    local resp = old_interpret2(message, user)
    local category = detectCategory(message)
    
    -- Save interaction in long-term memory
    saveLongTermMemory(user, message, category, resp)
    
    return resp
end
-- ===== ADAPTIVE PERSONALITY EVOLUTION =====


-- Initialize personality stats if not present
if not memory.personality then
    memory.personality = {humor=0.5, curiosity=0.5, friendliness=0.5}
end

-- Adjust personality traits based on user feedback
function adjustPersonality(user, message, response, feedback)
    -- feedback should be "positive" or "negative"
    local adjustment = 0.05
    if feedback == "positive" then
        -- Increase traits if response was well-received
        memory.personality.humor = math.min(1, memory.personality.humor + adjustment)
        memory.personality.curiosity = math.min(1, memory.personality.curiosity + adjustment/2)
        memory.personality.friendliness = math.min(1, memory.personality.friendliness + adjustment/2)
    elseif feedback == "negative" then
        -- Decrease traits if response was poorly received
        memory.personality.humor = math.max(0, memory.personality.humor - adjustment)
        memory.personality.curiosity = math.max(0, memory.personality.curiosity - adjustment/2)
        memory.personality.friendliness = math.max(0, memory.personality.friendliness - adjustment/2)
    end
    saveMemory()
end

-- Automatically adjust personality based on conversation patterns
function analyzeConversation(user)
    local recent = getRecentContext(user, 10)
    local humorCount, positiveCount = 0, 0

    for _, entry in ipairs(recent) do
        -- Check if AI used a joke or playful interjection
        for _, joke in ipairs(library.jokes) do
            if entry.response:find(joke) then humorCount = humorCount + 1 end
        end
        -- Check if user responded positively
        if entry.message:lower():find("thanks") or entry.message:lower():find("haha") then
            positiveCount = positiveCount + 1
        end
    end

    -- Adjust personality traits
    local total = #recent > 0 and #recent or 1
    memory.personality.humor = math.min(1, math.max(0, humorCount / total))
    memory.personality.friendliness = math.min(1, math.max(0, positiveCount / total))
    -- Curiosity can slightly increase over time
    memory.personality.curiosity = math.min(1, memory.personality.curiosity + 0.01)

    saveMemory()
end

-- Override playful response to include personality weights
local old_playfulResponse = playfulResponse
function playfulResponse()
    local resp = ""
    if math.random() < memory.personality.humor then
        resp = resp .. choose(library.interjections) .. " " .. choose(library.jokes)
    else
        resp = resp .. choose(library.idioms) .. " " .. choose(library.replies)
    end

    -- Slightly modify responses based on friendliness
    if memory.personality.friendliness > 0.7 then
        resp = resp .. " 😊"
    elseif memory.personality.friendliness < 0.3 then
        resp = resp .. " …"
    end

    return resp
end
-- ===== EMOTIONAL TONE DETECTION =====


-- Predefined keywords for basic mood detection
local moodKeywords = {
    happy = {"happy", "great", "fun", "yay", "awesome", "good", "excited", "love"},
    sad = {"sad", "bad", "down", "unhappy", "angry", "frustrated", "tired", "unwell"},
    neutral = {"okay", "fine", "meh", "alright", "normal", "so-so"},
    confused = {"confused", "not sure", "lost", "puzzled", "uncertain"}
}

-- Detect mood from a message
function detectMood(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, neutral=0, confused=0}

    for mood, keywords in pairs(moodKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[mood] = scores[mood] + 1
            end
        end
    end

    local bestMood = "neutral"
    local bestScore = 0
    for mood, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestMood = mood
        end
    end

    return bestMood
end

-- Adjust AI response tone based on user mood
function adjustResponseForMood(user, response)
    local lastMessage = memory.context[#memory.context] and memory.context[#memory.context].message or ""
    local userMood = detectMood(lastMessage)

    if userMood == "happy" then
        response = response .. " 😄"
    elseif userMood == "sad" then
        response = response .. " 😔"
    elseif userMood == "confused" then
        response = response .. " 🤔"
    end

    return response
end

-- Override interpret function to integrate mood adjustment
local old_interpret = interpret
function interpret(message, user)
    local resp = old_interpret(message, user)
    resp = adjustResponseForMood(user, resp)
    return resp
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Maximum number of messages to remember per user
local MAX_MEMORY_PER_USER = 20

-- Initialize user-specific context memory if it doesn't exist
function ensureUserMemory(user)
    if not memory.userContext then memory.userContext = {} end
    if not memory.userContext[user] then memory.userContext[user] = {} end
end

-- Add message to user's memory context
function addToUserMemory(user, message, category)
    ensureUserMemory(user)
    table.insert(memory.userContext[user], {message=message, category=category, time=os.time()})
    
    -- Maintain only last MAX_MEMORY_PER_USER messages
    while #memory.userContext[user] > MAX_MEMORY_PER_USER do
        table.remove(memory.userContext[user], 1)
    end

    saveMemory()
end

-- Retrieve recent messages from user's memory
function getRecentUserMemory(user, count)
    ensureUserMemory(user)
    local mem = memory.userContext[user]
    if not mem then return {} end
    local startIdx = math.max(1, #mem - count + 1)
    local recent = {}
    for i = startIdx, #mem do
        table.insert(recent, mem[i])
    end
    return recent
end

-- Enhance autonomous responses using user memory
local old_chooseAutonomous = chooseAutonomous
function chooseAutonomous(message)
    local baseResponse = old_chooseAutonomous(message)
    local user = "Player" -- placeholder, can be replaced with dynamic username

    -- Retrieve last 5 messages from this user
    local recentMemory = getRecentUserMemory(user, 5)
    if #recentMemory > 0 then
        -- Try to reference previous conversation
        for i = #recentMemory, 1, -1 do
            local prev = recentMemory[i]
            if message:lower():find(prev.message:sub(1,10):lower()) then
                baseResponse = baseResponse .. " By the way, last time you mentioned: '" .. prev.message .. "'."
                break
            end
        end
    end

    return baseResponse
end

-- Integrate memory logging into interpretation
local old_interpret = interpret
function interpret(message, user)
    local category = detectCategory(message)
    addToUserMemory(user, message, category)
    
    local resp = old_interpret(message, user)
    
    -- Adjust for mood
    resp = adjustResponseForMood(user, resp)
    return resp
end
-- ===== DYNAMIC PERSONALITY ADAPTATION =====


-- Track user feedback for personality tuning
function analyzeFeedback(user, message, response)
    -- Simple heuristics: if user says "haha", "lol", or "funny", increase humor
    local msgLower = message:lower()
    if msgLower:find("haha") or msgLower:find("lol") or msgLower:find("funny") then
        personality.humor = math.min(1, personality.humor + 0.02)
    end

    -- If user asks questions, increase curiosity
    if msgLower:find("how") or msgLower:find("why") or msgLower:find("what") then
        personality.curiosity = math.min(1, personality.curiosity + 0.01)
    end

    -- If user gives gratitude ("thanks", "thank you"), increase empathy
    if msgLower:find("thank") then
        if not personality.empathy then personality.empathy = 0.5 end
        personality.empathy = math.min(1, personality.empathy + 0.02)
    end

    -- Negative feedback decreases humor and empathy
    if msgLower:find("no") or msgLower:find("not funny") then
        personality.humor = math.max(0, personality.humor - 0.03)
        if personality.empathy then
            personality.empathy = math.max(0, personality.empathy - 0.02)
        end
    end

    saveMemory()
end

-- Adjust response text based on personality
function adjustResponseForMood(user, response)
    local adjusted = response

    -- Humor injection
    if personality.humor > 0.7 and math.random() < 0.5 then
        adjusted = adjusted .. " 😎"
    elseif personality.humor < 0.3 and math.random() < 0.3 then
        adjusted = adjusted .. " 😐"
    end

    -- Empathy injection
    if personality.empathy and personality.empathy > 0.6 then
        adjusted = adjusted .. " I hope that helps!"
    end

    -- Curiosity injection: ask follow-up questions
    if personality.curiosity > 0.5 and math.random() < 0.3 then
        adjusted = adjusted .. " Can you tell me more about that?"
    end

    return adjusted
end

-- Integrate personality analysis into interpretation
local old_interpret = interpret
function interpret(message, user)
    local response = old_interpret(message, user)
    analyzeFeedback(user, message, response)
    response = adjustResponseForMood(user, response)
    return response
end
-- ===== EMOTION RECOGNITION & CONTEXTUAL RESPONSES =====


-- Simple emotion lexicon for detection
local emotionLexicon = {
    happy = {"happy", "glad", "joy", "yay", "awesome", "cool", "fun"},
    sad = {"sad", "unhappy", "down", "depressed", "lonely", "bad", "ugh"},
    frustrated = {"stuck", "annoyed", "frustrated", "hate", "angry", "ugh"},
    excited = {"excited", "pump", "amazing", "wow", "yay", "great"},
    confused = {"confused", "don't know", "unclear", "unsure"}
}

-- Detect dominant emotion from message
function detectEmotion(message)
    local msgLower = message:lower()
    local scores = {happy=0, sad=0, frustrated=0, excited=0, confused=0}
    for emotion, words in pairs(emotionLexicon) do
        for _, word in ipairs(words) do
            if msgLower:find(word) then
                scores[emotion] = scores[emotion] + 1
            end
        end
    end
    -- Pick highest scoring emotion
    local dominantEmotion = "neutral"
    local maxScore = 0
    for e, score in pairs(scores) do
        if score > maxScore then
            dominantEmotion = e
            maxScore = score
        end
    end
    return dominantEmotion
end

-- Adjust response based on detected emotion
function adjustResponseForEmotion(user, message, response)
    local emotion = detectEmotion(message)
    local adjusted = response

    if emotion == "happy" then
        if math.random() < 0.5 then adjusted = adjusted .. " 😄" end
    elseif emotion == "sad" then
        adjusted = adjusted .. " I'm here for you. 😢"
    elseif emotion == "frustrated" then
        adjusted = adjusted .. " Don't worry, you'll get it! 💪"
    elseif emotion == "excited" then
        adjusted = adjusted .. " That's awesome! 🎉"
    elseif emotion == "confused" then
        adjusted = adjusted .. " Let's figure this out together. 🤔"
    end

    return adjusted
end

-- Integrate emotion analysis into interpretation
local old_interpret_emotion = interpret
function interpret(message, user)
    local response = old_interpret_emotion(message, user)
    -- Personality adjustment already applied
    response = adjustResponseForEmotion(user, message, response)
    return response
end
-- ===== CONVERSATIONAL MEMORY ENHANCEMENT =====


-- Memory per user for past interactions
if not memory.userHistory then memory.userHistory = {} end

-- Record message-response pairs per user
function recordUserInteraction(user, message, response)
    if not memory.userHistory[user] then memory.userHistory[user] = {} end
    local history = memory.userHistory[user]
    table.insert(history, {message=message, response=response, time=os.time()})
    -- Keep only the last 20 interactions to save memory
    if #history > 20 then table.remove(history, 1) end
    saveMemory()
end

-- Generate contextual response using past history
function generateContextualResponse(user, message, baseResponse)
    local history = memory.userHistory[user]
    if not history or #history == 0 then return baseResponse end

    -- Look for previous similar messages
    local msgNormalized = message:lower():gsub("%p","")
    local similarResponses = {}
    for _, entry in ipairs(history) do
        local histMsg = entry.message:lower():gsub("%p","")
        if histMsg == msgNormalized then
            table.insert(similarResponses, entry.response)
        end
    end

    -- If similar past messages exist, randomly pick one to reference
    if #similarResponses > 0 then
        local prev = similarResponses[math.random(#similarResponses)]
        baseResponse = baseResponse .. " By the way, last time you asked something similar, I said: '" .. prev .. "'"
    end

    return baseResponse
end

-- Wrap interpret function to include conversational memory
local old_interpret_memory = interpret
function interpret(message, user)
    local baseResponse = old_interpret_memory(message, user)
    local contextualResponse = generateContextualResponse(user, message, baseResponse)
    -- Record the interaction for future reference
    recordUserInteraction(user, message, contextualResponse)
    return contextualResponse
end
-- ===== DYNAMIC PERSONALITY EXPANSION =====


-- Personality traits with default values
-- humor, curiosity, empathy all range from 0.0 to 1.0
if not personality.humor then personality.humor = 0.5 end
if not personality.curiosity then personality.curiosity = 0.5 end
if not personality.empathy then personality.empathy = 0.5 end

-- Adjust personality traits based on interaction type
function adaptPersonality(user, message, response)
    local msgLower = message:lower()

    -- Humor: increase if the user reacts positively to jokes or playful responses
    if message:find("haha") or message:find("lol") or message:find("funny") then
        personality.humor = math.min(1, personality.humor + 0.02)
    elseif message:find("boring") or message:find("dumb") then
        personality.humor = math.max(0, personality.humor - 0.03)
    end

    -- Curiosity: increase if user asks questions or requests exploration
    if msgLower:find("what") or msgLower:find("how") or msgLower:find("why") or msgLower:find("explore") then
        personality.curiosity = math.min(1, personality.curiosity + 0.02)
    elseif msgLower:find("stop") or msgLower:find("enough") then
        personality.curiosity = math.max(0, personality.curiosity - 0.03)
    end

    -- Empathy: increase if user shares feelings or frustrations
    if msgLower:find("sad") or msgLower:find("mad") or msgLower:find("happy") or msgLower:find("tired") then
        personality.empathy = math.min(1, personality.empathy + 0.02)
    elseif msgLower:find("ignore") or msgLower:find("useless") then
        personality.empathy = math.max(0, personality.empathy - 0.03)
    end

    -- Save personality periodically
    saveMemory()
end

-- Wrap interpret to adjust personality automatically
local old_interpret_personality = interpret
function interpret(message, user)
    local response = old_interpret_personality(message, user)
    adaptPersonality(user, message, response)
    return response
end

-- Utility: display current personality traits
function showPersonality()
    print(string.format("Personality Traits: Humor=%.2f, Curiosity=%.2f, Empathy=%.2f", personality.humor, personality.curiosity, personality.empathy))
end
-- ===== EMOTIONAL TONE DETECTION =====


-- Define some simple mood indicators
local moodIndicators = {
    happy = {"happy","glad","lol","haha","excited","great","yay","joy","fun","love"},
    sad = {"sad","unhappy","down","depressed","tired","mad","angry","frustrated","upset"},
    neutral = {"ok","fine","meh","so-so","alright","normal"},
    confused = {"confused","huh","what","lost","puzzled","unsure","?", "idk"}
}

-- Analyze message and return a mood score
local function detectMood(message)
    local msgLower = message:lower()
    local scores = {happy=0, sad=0, neutral=0, confused=0}

    for mood, keywords in pairs(moodIndicators) do
        for _, word in ipairs(keywords) do
            if msgLower:find(word) then
                scores[mood] = scores[mood] + 1
            end
        end
    end

    -- Determine the dominant mood
    local dominantMood = "neutral"
    local maxScore = 0
    for mood, score in pairs(scores) do
        if score > maxScore then
            maxScore = score
            dominantMood = mood
        end
    end

    return dominantMood
end

-- Adjust AI responses based on detected user mood
local function moodAwareResponse(user, message, baseResponse)
    local mood = detectMood(message)

    if mood == "happy" then
        return baseResponse .. " 😄"
    elseif mood == "sad" then
        return baseResponse .. " 😔"
    elseif mood == "confused" then
        return baseResponse .. " 🤔"
    end

    return baseResponse
end

-- Wrap interpret to include mood awareness
local old_interpret_mood = interpret
function interpret(message, user)
    local baseResponse = old_interpret_mood(message, user)
    local moodResponse = moodAwareResponse(user, message, baseResponse)
    return moodResponse
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Extend memory context capacity
local MAX_CONTEXT_LENGTH = 20 -- store last 20 interactions for richer context

-- Add message to context with user and timestamp
local function addToContext(user, message, category, response)
    table.insert(memory.context, {
        user = user,
        message = message,
        category = category,
        response = response,
        timestamp = os.time()
    })

    -- Limit context size
    if #memory.context > MAX_CONTEXT_LENGTH then
        table.remove(memory.context, 1)
    end
end

-- Retrieve recent messages by category
local function getRecentByCategory(category, limit)
    limit = limit or 5
    local results = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.category == category then
            table.insert(results, entry)
            if #results >= limit then break end
        end
    end
    return results
end

-- Retrieve recent messages by user
local function getRecentByUser(user, limit)
    limit = limit or 5
    local results = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.user == user then
            table.insert(results, entry)
            if #results >= limit then break end
        end
    end
    return results
end

-- Enhanced autonomous response selection using context
local function chooseContextAware(message, user)
    local category = detectCategory(message)
    local recent = getRecentByCategory(category, 3) -- last 3 similar messages
    local baseResponse = chooseAutonomous(message)

    -- Reference past conversation for continuity
    if #recent > 0 and math.random() < 0.5 then
        local ref = choose(recent)
        baseResponse = baseResponse .. " (Earlier you said: '" .. ref.message .. "')"
    end

    -- Add to context
    addToContext(user, message, category, baseResponse)
    saveMemory()
    return baseResponse
end

-- Wrap interpret to include context-aware responses
local old_interpret_context = interpret
function interpret(message, user)
    local response = chooseContextAware(message, user)
    return moodAwareResponse(user, message, response) -- keep mood awareness
end
-- ===== ADVANCED PERSONALITY MODULATION =====


-- Personality traits with dynamic adaptation
local personality = {
    humor = 0.5,     -- 0 = serious, 1 = very playful
    curiosity = 0.5, -- 0 = low curiosity, 1 = highly inquisitive
    empathy = 0.5,   -- 0 = low empathy, 1 = highly empathetic
}

-- Update personality traits based on user feedback
local function adaptPersonality(user, feedback)
    feedback = feedback:lower()
    if feedback:find("haha") or feedback:find("lol") then
        personality.humor = math.min(1, personality.humor + 0.05)
    elseif feedback:find("boring") or feedback:find("serious") then
        personality.humor = math.max(0, personality.humor - 0.05)
    end

    if feedback:find("tell me more") or feedback:find("why") then
        personality.curiosity = math.min(1, personality.curiosity + 0.05)
    elseif feedback:find("too much") or feedback:find("stop") then
        personality.curiosity = math.max(0, personality.curiosity - 0.05)
    end

    if feedback:find("thanks") or feedback:find("love") then
        personality.empathy = math.min(1, personality.empathy + 0.05)
    elseif feedback:find("ignore") or feedback:find("not care") then
        personality.empathy = math.max(0, personality.empathy - 0.05)
    end
end

-- Generate response with personality adaptation
local function personalityAwareResponse(user, message, baseResponse)
    local response = baseResponse

    -- Add humor occasionally
    if math.random() < personality.humor then
        response = response .. " 😄"
    end

    -- Ask curiosity-driven questions
    if math.random() < personality.curiosity then
        local questionPrompts = {
            "Can you tell me more about that?",
            "Why do you think that happened?",
            "What else can you share?"
        }
        response = response .. " " .. choose(questionPrompts)
    end

    -- Empathetic response tweaks
    if personality.empathy > 0.6 and message:find("sad") then
        response = response .. " I’m here for you. 😢"
    elseif personality.empathy > 0.6 and message:find("happy") then
        response = response .. " That’s wonderful to hear! 😃"
    end

    -- Adjust for context reference
    if #memory.context > 0 and math.random() < 0.3 then
        local last = memory.context[#memory.context]
        response = response .. " Earlier you mentioned: '" .. last.message .. "'"
    end

    -- Update personality based on response reception
    adaptPersonality(user, response)

    return response
end

-- Wrap interpret to include personality awareness
local old_interpret_personality = interpret
function interpret(message, user)
    local baseResp = chooseContextAware(message, user)
    local finalResp = personalityAwareResponse(user, message, baseResp)
    return finalResp
end
-- ===== EMOTIONAL TONE ANALYSIS =====


-- Define simple emotional keywords
local emotionKeywords = {
    happy = {"happy","glad","joy","excited","yay","love","great","awesome","good"},
    sad = {"sad","unhappy","depressed","lonely","bad","upset","ugh","sucks"},
    angry = {"angry","mad","frustrated","hate","annoyed","furious"},
    confused = {"confused","lost","unsure","huh","what","uncertain"},
    neutral = {"ok","fine","alright","normal","meh"}
}

-- Analyze message for emotional content
local function detectEmotion(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, angry=0, confused=0, neutral=0}
    for emotion, keywords in pairs(emotionKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[emotion] = scores[emotion] + 1
            end
        end
    end

    -- Determine dominant emotion
    local dominant, maxScore = "neutral", 0
    for emotion, score in pairs(scores) do
        if score > maxScore then
            dominant, maxScore = emotion, score
        end
    end

    return dominant
end

-- Map emotion to AI mood and response style
local moodModifiers = {
    happy = {emoji="😃", tone="cheerful"},
    sad = {emoji="😢", tone="supportive"},
    angry = {emoji="😡", tone="calm"},
    confused = {emoji="🤔", tone="clarifying"},
    neutral = {emoji="", tone="neutral"}
}

-- Generate response with emotional tone
local function emotionAwareResponse(user, message, baseResponse)
    local detectedEmotion = detectEmotion(message)
    local mod = moodModifiers[detectedEmotion] or moodModifiers["neutral"]

    local response = baseResponse

    -- Add emoji based on emotion
    if mod.emoji ~= "" then
        response = response .. " " .. mod.emoji
    end

    -- Adjust phrasing based on tone
    if mod.tone == "supportive" then
        response = "I understand. " .. response
    elseif mod.tone == "clarifying" then
        response = response .. " Could you explain more?"
    elseif mod.tone == "cheerful" then
        response = response .. " That sounds awesome!"
    elseif mod.tone == "calm" then
        response = response .. " Let's stay calm and figure it out."
    end

    return response
end

-- Wrap interpret to include emotion analysis
local old_interpret_emotion = interpret
function interpret(message, user)
    local baseResp = old_interpret_emotion(message, user)
    local finalResp = emotionAwareResponse(user, message, baseResp)
    return finalResp
end
-- ===== CONVERSATIONAL MEMORY EXPANSION =====


-- Enhanced memory structure for conversations
-- Stores: user, message, response, timestamp, detected emotion
if not memory.conversationDetailed then memory.conversationDetailed = {} end

-- Add a conversation entry
local function addConversationEntry(user, message, response)
    local timestamp = os.time()
    local emotion = detectEmotion(message)
    table.insert(memory.conversationDetailed, {
        user = user,
        message = message,
        response = response,
        timestamp = timestamp,
        emotion = emotion
    })

    -- Keep only the last 50 entries to manage memory
    if #memory.conversationDetailed > 50 then
        table.remove(memory.conversationDetailed, 1)
    end

    saveMemory()
end

-- Retrieve relevant past conversation entries
local function retrievePastContext(user, message)
    local keywords = extractKeywords(message)
    local matches = {}

    for _, entry in ipairs(memory.conversationDetailed) do
        local matchScore = 0
        for _, kw in ipairs(keywords) do
            if entry.message:lower():find(kw) then
                matchScore = matchScore + 1
            end
        end
        if matchScore > 0 then
            table.insert(matches, {entry=entry, score=matchScore})
        end
    end

    -- Sort by score descending
    table.sort(matches, function(a,b) return a.score > b.score end)

    return matches
end

-- Generate response with past context reference
local function contextAwareResponse(user, message, baseResponse)
    local pastEntries = retrievePastContext(user, message)
    if #pastEntries > 0 and math.random() < 0.3 then
        local entry = pastEntries[1].entry
        -- Reference the past message
        baseResponse = baseResponse .. " By the way, earlier you said: '" .. entry.message .. "'."
        if entry.emotion and moodModifiers[entry.emotion] then
            baseResponse = baseResponse .. " I remember you felt " .. entry.emotion .. " then " .. moodModifiers[entry.emotion].emoji
        end
    end
    return baseResponse
end

-- Wrap interpret to include context-aware memory
local old_interpret_context = interpret
function interpret(message, user)
    local baseResp = old_interpret_context(message, user)
    local finalResp = contextAwareResponse(user, message, baseResp)
    return finalResp
end
-- ===== PERSONALITY TRAIT ADAPTATION =====


-- Initialize traits if missing
if not memory.personality then
    memory.personality = {humor=0.5, curiosity=0.5, empathy=0.5, optimism=0.5}
end

-- Personality adjustment modifiers
local traitModifiers = {
    humor = {inc=0.02, dec=0.01},
    curiosity = {inc=0.02, dec=0.01},
    empathy = {inc=0.03, dec=0.01},
    optimism = {inc=0.02, dec=0.01}
}

-- Adjust personality based on user response
local function adaptPersonality(user, message, response)
    local normalized = message:lower()

    -- Humor: user laughs or responds positively to jokes
    if response:find("😂") or normalized:find("haha") then
        memory.personality.humor = math.min(1, memory.personality.humor + traitModifiers.humor.inc)
    else
        memory.personality.humor = math.max(0, memory.personality.humor - traitModifiers.humor.dec)
    end

    -- Curiosity: user asks questions or requests information
    if normalized:find("how") or normalized:find("why") or normalized:find("what") then
        memory.personality.curiosity = math.min(1, memory.personality.curiosity + traitModifiers.curiosity.inc)
    else
        memory.personality.curiosity = math.max(0, memory.personality.curiosity - traitModifiers.curiosity.dec)
    end

    -- Empathy: user shares feelings
    if normalized:find("sad") or normalized:find("happy") or normalized:find("angry") then
        memory.personality.empathy = math.min(1, memory.personality.empathy + traitModifiers.empathy.inc)
    else
        memory.personality.empathy = math.max(0, memory.personality.empathy - traitModifiers.empathy.dec)
    end

    -- Optimism: user responds positively or negatively to suggestions
    if normalized:find("good") or normalized:find("great") then
        memory.personality.optimism = math.min(1, memory.personality.optimism + traitModifiers.optimism.inc)
    elseif normalized:find("bad") or normalized:find("not good") then
        memory.personality.optimism = math.max(0, memory.personality.optimism - traitModifiers.optimism.dec)
    end

    saveMemory()
end

-- Integrate adaptation into interpret
local old_interpret_adapt = interpret
function interpret(message, user)
    local baseResp = old_interpret_adapt(message, user)
    adaptPersonality(user, message, baseResp)
    return baseResp
end

-- Optional: show personality traits for debugging
local function displayPersonality()
    print("[Personality Traits]")
    for k,v in pairs(memory.personality) do
        print(k .. ": " .. string.format("%.2f", v))
    end
end
-- ===== MOOD & EMOTIONAL STATE TRACKING =====


-- Initialize mood memory if missing
if not memory.mood then
    memory.mood = {current="neutral", history={}}
end

-- Define mood keywords
local moodKeywords = {
    happy = {"happy", "glad", "excited", "joy", "fun", "great"},
    sad = {"sad", "unhappy", "down", "depressed", "mourn", "bad"},
    angry = {"angry", "mad", "frustrated", "annoyed", "upset"},
    neutral = {"ok", "fine", "alright", "meh"}
}

-- Detect mood based on message
local function detectMood(message)
    local msg = message:lower()
    local moodScores = {happy=0, sad=0, angry=0, neutral=0}

    for mood, keywords in pairs(moodKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                moodScores[mood] = moodScores[mood] + 1
            end
        end
    end

    local detectedMood = "neutral"
    local maxScore = 0
    for mood, score in pairs(moodScores) do
        if score > maxScore then
            maxScore = score
            detectedMood = mood
        end
    end

    -- Update memory
    memory.mood.current = detectedMood
    table.insert(memory.mood.history, {message=message, mood=detectedMood})
    if #memory.mood.history > 20 then table.remove(memory.mood.history, 1) end
    saveMemory()

    return detectedMood
end

-- Adjust response style based on mood
local function moodResponseAdjust(response)
    local mood = memory.mood.current
    if mood == "happy" then
        response = response .. " 😄"
    elseif mood == "sad" then
        response = response .. " 😢"
    elseif mood == "angry" then
        response = response .. " 😡"
    end
    return response
end

-- Integrate mood detection into interpret
local old_interpret_mood = interpret
function interpret(message, user)
    local mood = detectMood(message)
    local baseResp = old_interpret_mood(message, user)
    local adjustedResp = moodResponseAdjust(baseResp)
    return adjustedResp
end

-- Optional: show recent mood history for debugging
local function displayMoodHistory()
    print("[Mood History]")
    for i, entry in ipairs(memory.mood.history) do
        print(i .. ": " .. entry.mood .. " -> " .. entry.message)
    end
end
-- ===== CONVERSATIONAL MEMORY DEPTH EXPANSION =====


-- Define maximum memory depth for conversation threads
if not memory.conversationDepth then
    memory.conversationDepth = 50 -- can be increased later
end

-- Record conversation with depth management
local function recordConversation(user, message, response, category)
    table.insert(memory.conversation, {
        user = user,
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    })
    -- Trim older entries if over depth
    while #memory.conversation > memory.conversationDepth do
        table.remove(memory.conversation, 1)
    end
    saveMemory()
end

-- Retrieve relevant past conversation snippets
local function getRelevantConversation(message)
    local keywords = extractKeywords(normalize(message))
    local relevant = {}
    for i = #memory.conversation, 1, -1 do
        local entry = memory.conversation[i]
        for _, kw in ipairs(keywords) do
            if entry.message:lower():find(kw) or entry.response:lower():find(kw) then
                table.insert(relevant, entry)
                break
            end
        end
        if #relevant >= 5 then break end -- limit to 5 relevant snippets
    end
    return relevant
end

-- Enhance autonomous response with conversation references
local old_chooseAutonomous = chooseAutonomous
function chooseAutonomous(message)
    local baseResp = old_chooseAutonomous(message)
    local pastRefs = getRelevantConversation(message)
    if #pastRefs > 0 and math.random() < 0.5 then
        local ref = choose(pastRefs)
        baseResp = baseResp .. " By the way, earlier you said: '" .. ref.message .. "'."
    end
    return baseResp
end

-- Optional: view entire conversation memory for debugging
local function displayConversationMemory()
    print("[Conversation Memory]")
    for i, entry in ipairs(memory.conversation) do
        print(i .. ": [" .. os.date("%Y-%m-%d %H:%M:%S", entry.timestamp) .. "] "
            .. entry.user .. ": " .. entry.message .. " -> " .. entry.response)
    end
end
-- ===== PERSONALITY ADAPTATION BASED ON USER INTERACTIONS =====


-- Initialize personality stats if missing
if not personality.humor then personality.humor = 0.5 end
if not personality.curiosity then personality.curiosity = 0.5 end
if not personality.friendliness then personality.friendliness = 0.5 end

-- Update personality based on user feedback
local function adaptPersonality(user, message, response)
    message = normalize(message)
    response = normalize(response)

    -- Positive cues increase friendliness
    local positiveCues = {"thanks", "good", "nice", "awesome", "great", "fun", "cool", "love"}
    for _, cue in ipairs(positiveCues) do
        if message:find(cue) or response:find(cue) then
            personality.friendliness = math.min(1, personality.friendliness + 0.02)
            personality.humor = math.min(1, personality.humor + 0.01)
        end
    end

    -- Negative cues reduce friendliness or humor
    local negativeCues = {"no", "bad", "hate", "stupid", "wrong", "boring", "annoying"}
    for _, cue in ipairs(negativeCues) do
        if message:find(cue) or response:find(cue) then
            personality.friendliness = math.max(0, personality.friendliness - 0.03)
            personality.humor = math.max(0, personality.humor - 0.02)
        end
    end

    -- Curiosity adapts based on questions
    local questionIndicators = {"what", "how", "why", "when", "where"}
    for _, word in ipairs(questionIndicators) do
        if message:find(word) then
            personality.curiosity = math.min(1, personality.curiosity + 0.02)
        end
    end

    -- Save changes to memory
    saveMemory()
end

-- Wrap interpret to include personality adaptation
local old_interpret = interpret
function interpret(message, user)
    local resp = old_interpret(message, user)
    adaptPersonality(user, message, resp)
    return resp
end

-- Optional: display current personality stats
local function displayPersonality()
    print("[Personality Stats]")
    print("Humor: " .. string.format("%.2f", personality.humor))
    print("Curiosity: " .. string.format("%.2f", personality.curiosity))
    print("Friendliness: " .. string.format("%.2f", personality.friendliness))
end
-- ===== MOOD & EMOTIONAL CONTEXT =====


-- Initialize mood
if not memory.mood then memory.mood = "neutral" end

-- Mood weights and thresholds
local moodWeights = {happy = 0, neutral = 0, sad = 0, confused = 0}

-- Update mood based on recent messages and responses
local function updateMood(user, message, response)
    message = normalize(message)
    response = normalize(response)

    -- Positive cues increase happiness
    local positiveCues = {"thanks", "good", "nice", "awesome", "fun", "love", "great"}
    for _, cue in ipairs(positiveCues) do
        if message:find(cue) or response:find(cue) then
            moodWeights.happy = moodWeights.happy + 1
        end
    end

    -- Negative cues increase sadness or confusion
    local negativeCues = {"no", "bad", "hate", "wrong", "boring", "annoying", "stupid"}
    for _, cue in ipairs(negativeCues) do
        if message:find(cue) or response:find(cue) then
            moodWeights.sad = moodWeights.sad + 1
        end
    end

    -- Confusion cues
    local confusionCues = {"huh", "what", "don't understand", "why"}
    for _, cue in ipairs(confusionCues) do
        if message:find(cue) or response:find(cue) then
            moodWeights.confused = moodWeights.confused + 1
        end
    end

    -- Determine dominant mood
    local dominant, maxWeight = "neutral", 0
    for mood, weight in pairs(moodWeights) do
        if weight > maxWeight then
            dominant = mood
            maxWeight = weight
        end
    end

    memory.mood = dominant
    saveMemory()
end

-- Wrap interpret to update mood after generating response
local old_interpret_mood = interpret
function interpret(message, user)
    local resp = old_interpret_mood(message, user)
    updateMood(user, message, resp)
    return resp
end

-- Optional: adjust response style based on mood
local function moodifyResponse(response)
    if memory.mood == "happy" then
        response = response .. " 😄"
    elseif memory.mood == "sad" then
        response = response .. " 😔"
    elseif memory.mood == "confused" then
        response = response .. " 🤔"
    end
    return response
end

-- Wrap interpret again to add mood emoji
local old_interpret_moodify = interpret
function interpret(message, user)
    local resp = old_interpret_moodify(message, user)
    resp = moodifyResponse(resp)
    return resp
end

-- Optional: display current mood
local function displayMood()
    print("[Current Mood]: " .. memory.mood)
end
-- ===== ADVANCED CONTEXTUAL AWARENESS =====


-- Maximum number of context entries to remember
local MAX_CONTEXT = 20

-- Extend context structure to include mood, timestamp, and user intent
local function addToContext(user, message, response, category, intent)
    local entry = {
        user = user,
        message = message,
        response = response,
        category = category,
        intent = intent or "unknown",
        mood = memory.mood,
        timestamp = os.time()
    }
    table.insert(memory.context, entry)
    if #memory.context > MAX_CONTEXT then
        table.remove(memory.context, 1) -- remove oldest
    end
    saveMemory()
end

-- Retrieve past related messages for a given category or keywords
local function getRelevantContext_part1(category, keywords)
    local _res = {}
        local relevant = {}
        for i = #memory.context, 1, -1 do
            local entry = memory.context[i]
    return _res
end
local function getRelevantContext_part2(category, keywords)
    local _res = {}
            local matchScore = 0
            if category and entry.category == category then
                matchScore = matchScore + 2
    return _res
end
local function getRelevantContext(category, keywords)
    local _r1 = getRelevantContext_part1(category, keywords)
    local _r2 = getRelevantContext_part2(category, keywords)
    for _,v in ipairs(_r2) do table.insert(_r1, v) end
    return _r1
end
        if keywords then
            for _, kw in ipairs(keywords) do
                if entry.message:find(kw) then
                    matchScore = matchScore + 1
                end
            end
        end
        if matchScore > 0 then
            table.insert(relevant, {entry = entry, score = matchScore})
        end
    end
    return relevant
end

-- Enhance autonomous response selection with context awareness
local old_chooseAutonomous = chooseAutonomous
function chooseAutonomous(message)
    local msg = normalize(message)
    local keywords = extractKeywords(msg)
    local category = detectCategory(message)

    -- Check recent context first
    local relevantContext = getRelevantContext(category, keywords)
    if #relevantContext > 0 then
        -- Pick the most recent relevant response
        local lastRelevant = relevantContext[1].entry
        local resp = lastRelevant.response
        -- Optionally add continuity phrasing
        resp = "Earlier we talked about this: " .. resp
        return resp
    end

    -- Fallback to previous autonomous logic
    return old_chooseAutonomous(message)
end

-- Wrap interpret to automatically add context
local old_interpret_context = interpret
function interpret(message, user)
    local resp = old_interpret_context(message, user)
    local category = detectCategory(message)
    local intent = detectIntent(message)
    addToContext(user, message, resp, category, intent)
    return resp
end
-- ===== PERSONALITY EVOLUTION & FEEDBACK LEARNING =====


-- Personality traits structure
-- Traits range from 0.0 (low) to 1.0 (high)
-- humor: likelihood of playful responses
-- curiosity: tendency to ask follow-up questions
-- patience: tolerance for repeated corrections
-- empathy: response warmth and attentiveness
if not memory.personality then
    memory.personality = {humor = 0.5, curiosity = 0.5, patience = 0.5, empathy = 0.5}
end

-- Adjust personality traits based on feedback
local function adjustPersonality(trait, amount)
    if memory.personality[trait] then
        memory.personality[trait] = math.max(0, math.min(1, memory.personality[trait] + amount))
        saveMemory()
    end
end

-- Analyze user feedback to adapt personality
local function analyzeFeedback(user, message)
    message = message:lower()
    if message:find("no") or message:find("incorrect") then
        -- User corrected AI: reduce humor, increase patience
        adjustPersonality("humor", -0.05)
        adjustPersonality("patience", 0.05)
    elseif message:find("haha") or message:find("lol") then
        -- User enjoyed a joke: increase humor
        adjustPersonality("humor", 0.05)
    elseif message:find("interesting") or message:find("tell me more") then
        -- User shows curiosity: increase AI curiosity
        adjustPersonality("curiosity", 0.05)
    elseif message:find("thanks") or message:find("appreciate") then
        -- User expresses gratitude: increase empathy
        adjustPersonality("empathy", 0.05)
    end
end

-- Hook into main feedback handler
local old_handleFeedback = handleFeedback
function handleFeedback(user, message)
    analyzeFeedback(user, message) -- first, adjust personality
    return old_handleFeedback(user, message) -- then process normally
end

-- Personality-influenced response generator
local function personalityDrivenResponse(baseResponse)
    local resp = baseResponse
    -- Humor influence: occasionally add playful interjections
    if math.random() < memory.personality.humor then
        resp = choose(library.interjections) .. " " .. resp
    end
    -- Curiosity influence: occasionally add a follow-up question
    if math.random() < memory.personality.curiosity then
        resp = resp .. " " .. choose({"What do you think?", "Can you tell me more?", "How did that go?"})
    end
    -- Empathy influence: occasionally add warm phrases
    if math.random() < memory.personality.empathy then
        resp = resp .. " " .. choose({"I understand.", "That makes sense.", "I'm here to help."})
    end
    return resp
end

-- Override interpret to inject personality
local old_interpret_personality = interpret
function interpret(message, user)
    local baseResp = old_interpret_personality(message, user)
    return personalityDrivenResponse(baseResp)
end
-- ===== MEMORY PRIORITIZATION & FORGETTING =====


-- Initialize memory weights if not present
if not memory.weights then
    memory.weights = {}  -- structure: {message = weight}
end

-- Assign initial weight to a learned message
local function assignInitialWeight(message)
    memory.weights[message] = memory.weights[message] or 1.0
end

-- Increase weight when user feedback is positive
local function reinforceMemory(message)
    assignInitialWeight(message)
    memory.weights[message] = math.min(5.0, memory.weights[message] + 0.2)
end

-- Decrease weight when feedback is negative
local function weakenMemory(message)
    assignInitialWeight(message)
    memory.weights[message] = math.max(0, memory.weights[message] - 0.3)
end

-- Periodically decay weights to simulate forgetting
local function decayMemory()
    for message, weight in pairs(memory.weights) do
        memory.weights[message] = math.max(0, weight - 0.01)
        -- Forget messages with very low weight
        if memory.weights[message] <= 0 then
            memory.learned[message] = nil
            memory.weights[message] = nil
        end
    end
    saveMemory()
end

-- Override recordLearning to include weight adjustments
local old_recordLearning = recordLearning
function recordLearning(message, response, category)
    old_recordLearning(message, response, category)
    reinforceMemory(message)
end

-- Override feedback handler to adjust weights based on corrections
local old_handleFeedback_memory = handleFeedback
function handleFeedback(user, message)
    local feedbackResp = old_handleFeedback_memory(user, message)
    if feedbackResp then
        if #memory.context > 0 then
            local lastEntry = memory.context[#memory.context]
            weakenMemory(lastEntry.message)
        end
        return feedbackResp
    end
end

-- Decay memory every fixed interval (can be called inside main loop)
local memoryDecayCounter = 0
local function periodicMemoryDecay()
    memoryDecayCounter = memoryDecayCounter + 1
    if memoryDecayCounter >= 10 then  -- decay every 10 iterations
        decayMemory()
        memoryDecayCounter = 0
    end
end
-- ===== CONTEXTUAL MULTI-TURN CONVERSATION =====


-- Maximum number of recent messages to store
local CONTEXT_LIMIT = 8

-- Add a message to the conversation context
local function addToContext(user, message, response, category)
    table.insert(memory.context, {
        user = user,
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    })
    if #memory.context > CONTEXT_LIMIT then
        table.remove(memory.context, 1)
    end
end

-- Retrieve relevant context for the current message
local function getRelevantContext(message)
    local keywords = extractKeywords(normalize(message))
    local relevant = {}
    for _, entry in ipairs(memory.context) do
        for _, kw in ipairs(keywords) do
            for _, rkw in ipairs(entry.message:lower():gmatch("%w+")) do
                if kw == rkw then
                    table.insert(relevant, entry)
                    break
                end
            end
        end
    end
    return relevant
end

-- Enhance autonomous response with contextual awareness
local old_chooseAutonomous = chooseAutonomous
function chooseAutonomous(message)
    local baseResponse = old_chooseAutonomous(message)
    local relevantContext = getRelevantContext(message)

    -- If relevant context exists, try to incorporate it
    if #relevantContext > 0 then
        local lastEntry = relevantContext[#relevantContext]
        -- Add a human-like connector
        local connectors = {"By the way,", "Also,", "Remember,", "Earlier you said,"}
        local connector = choose(connectors)
        baseResponse = connector .. " " .. lastEntry.response .. " " .. baseResponse
    end

    return baseResponse
end

-- Override updateContext to use the enhanced version
local old_updateContext = updateContext
function updateContext(user, message, category)
    local response = chooseAutonomous(message)
    addToContext(user, message, response, category)
end
-- ===== EMOTIONAL TONE & MOOD TRACKING =====


-- Track the user's mood over recent messages
local MOOD_MEMORY_LIMIT = 10
memory.userMoods = memory.userMoods or {}

-- Simple keywords to detect mood
local moodKeywords = {
    happy = {"happy", "good", "great", "fun", "awesome", "yay", "cool", "nice"},
    sad   = {"sad", "bad", "down", "unhappy", "ugh", "annoyed", "tired", "frustrated"},
    angry = {"angry", "mad", "furious", "upset", "hate", "annoyed"},
    confused = {"confused", "lost", "don't understand", "huh", "what"}
}

-- Detect mood based on message content
local function detectMood(message)
    local msg = message:lower()
    for mood, kws in pairs(moodKeywords) do
        for _, kw in ipairs(kws) do
            if msg:find(kw) then
                return mood
            end
        end
    end
    return "neutral"
end

-- Update user mood history
local function updateUserMood(user, message)
    local mood = detectMood(message)
    if not memory.userMoods[user] then memory.userMoods[user] = {} end
    table.insert(memory.userMoods[user], {mood = mood, timestamp = os.time()})
    if #memory.userMoods[user] > MOOD_MEMORY_LIMIT then
        table.remove(memory.userMoods[user], 1)
    end
    return mood
end

-- Determine current dominant mood of the user
local function getCurrentUserMood(user)
    if not memory.userMoods[user] or #memory.userMoods[user] == 0 then
        return "neutral"
    end
    local counts = {happy=0, sad=0, angry=0, confused=0, neutral=0}
    for _, entry in ipairs(memory.userMoods[user]) do
        counts[entry.mood] = counts[entry.mood] + 1
    end
    local dominantMood = "neutral"
    local maxCount = 0
    for mood, count in pairs(counts) do
        if count > maxCount then
            maxCount = count
            dominantMood = mood
        end
    end
    return dominantMood
end

-- Adjust AI response based on user mood
local function applyMoodToResponse(user, response)
    local mood = getCurrentUserMood(user)
    if mood == "happy" then
        return response .. " 😄"
    elseif mood == "sad" then
        return response .. " 🙁"
    elseif mood == "angry" then
        return response .. " 😠"
    elseif mood == "confused" then
        return response .. " 🤔"
    else
        return response
    end
end

-- Integrate mood tracking with interpretation engine
local old_interpret = interpret
function interpret(message, user)
    updateUserMood(user, message)
    local response = old_interpret(message, user)
    response = applyMoodToResponse(user, response)
    return response
end
-- ===== MEMORY-BASED PERSONALIZATION =====


-- Initialize personalized memory if not already present
memory.userProfiles = memory.userProfiles or {}

-- Update or create user profile
local function updateUserProfile(user, key, value)
    if not memory.userProfiles[user] then
        memory.userProfiles[user] = {}
    end
    memory.userProfiles[user][key] = value
    saveMemory()
end

-- Retrieve user profile info
local function getUserProfile(user, key, default)
    if memory.userProfiles[user] and memory.userProfiles[user][key] then
        return memory.userProfiles[user][key]
    end
    return default
end

-- Record favorite things, recent topics, or custom data
local function recordUserPreference(user, topic, value)
    if not memory.userProfiles[user] then
        memory.userProfiles[user] = {}
    end
    memory.userProfiles[user][topic] = value
    saveMemory()
end

-- Retrieve favorite things or previous topics
local function getUserPreference(user, topic, default)
    if memory.userProfiles[user] and memory.userProfiles[user][topic] then
        return memory.userProfiles[user][topic]
    end
    return default
end

-- Personalized greetings
local function personalizedGreeting(user)
    local name = getName(user)
    local mood = getCurrentUserMood(user)
    local greeting = choose(library.greetings)

    -- Include favorite activity if known
    local favActivity = getUserPreference(user, "favoriteActivity", nil)
    if favActivity then
        greeting = greeting .. " Ready for some " .. favActivity .. " today?"
    end

    -- Add mood-based flavor
    if mood == "happy" then
        greeting = greeting .. " You seem cheerful! 😄"
    elseif mood == "sad" then
        greeting = greeting .. " Hope your day gets better! 🙁"
    elseif mood == "angry" then
        greeting = greeting .. " Take it easy, okay? 😠"
    elseif mood == "confused" then
        greeting = greeting .. " Let's figure it out together. 🤔"
    end

    return greeting
end

-- Hook personalized greetings into command
local old_hello = commands.hello
commands.hello = function(user)
    return personalizedGreeting(user)
end
-- ===== CONTEXTUAL CONVERSATION CHAINING =====


-- Keep track of multi-turn conversation per user
memory.userContexts = memory.userContexts or {}

-- Update context for a user
local function updateUserContext(user, message, response)
    if not memory.userContexts[user] then
        memory.userContexts[user] = {}
    end
    table.insert(memory.userContexts[user], {message=message, response=response, time=os.time()})
    
    -- Limit stored context to last 10 exchanges
    if #memory.userContexts[user] > 10 then
        table.remove(memory.userContexts[user], 1)
    end
    saveMemory()
end

-- Retrieve recent context for a user
local function getUserContext(user)
    if memory.userContexts[user] then
        return memory.userContexts[user]
    end
    return {}
end

-- Enhance autonomous response by referencing context
local function contextualAutonomousResponse(user, message)
    local context = getUserContext(user)
    local lastEntry = context[#context]

    -- Start with normal autonomous choice
    local response = chooseAutonomous(message)

    -- Add context awareness if last message exists
    if lastEntry then
        -- If current message references a previous topic, add continuity
        for _, kw in ipairs(extractKeywords(lastEntry.message)) do
            if message:lower():find(kw) then
                response = response .. " By the way, about '" .. kw .. "', earlier you mentioned: " .. lastEntry.response
                break
            end
        end
    end

    -- Update user context
    updateUserContext(user, message, response)

    return response
end

-- Hook into interpretation engine
local old_interpret = interpret
interpret = function(message, user)
    local intent, extra = detectIntent(message)

    -- Use contextual response if unknown or general
    if intent == "unknown" or intent == "greeting" then
        return contextualAutonomousResponse(user, message)
    else
        local resp = old_interpret(message, user)
        updateUserContext(user, message, resp)
        return resp
    end
end
-- ===== MOOD & EMOTION ANALYSIS =====


-- Initialize mood tracking per user
memory.userMood = memory.userMood or {}

-- Simple mood keywords
local moodKeywords = {
    happy = {"yay", "yes", "awesome", "great", "fun", "cool", "good"},
    sad = {"sad", "no", "unhappy", "bad", "disappointing", "ugh"},
    angry = {"angry", "mad", "upset", "frustrated", "annoyed"},
    neutral = {"okay", "fine", "meh", "alright"}
}

-- Detect mood from user message
local function detectMood(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, angry=0, neutral=0}
    
    for mood, keywords in pairs(moodKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[mood] = scores[mood] + 1
            end
        end
    end

    -- Choose mood with highest score, default to neutral
    local bestMood, bestScore = "neutral", 0
    for mood, score in pairs(scores) do
        if score > bestScore then
            bestMood = mood
            bestScore = score
        end
    end

    return bestMood
end

-- Update user mood in memory
local function updateUserMood(user, message)
    local mood = detectMood(message)
    memory.userMood[user] = mood
    saveMemory()
    return mood
end

-- Adjust AI response tone based on user mood
local function moodAdjustedResponse(user, response)
    local mood = memory.userMood[user] or "neutral"
    
    if mood == "happy" then
        response = response .. " 😄"
    elseif mood == "sad" then
        response = response .. " 😔"
    elseif mood == "angry" then
        response = response .. " 😠"
    end

    return response
end

-- Integrate into interpret
local old_interpret2 = interpret
interpret = function(message, user)
    -- Update mood first
    updateUserMood(user, message)

    -- Get standard response
    local resp = old_interpret2(message, user)

    -- Adjust for mood
    return moodAdjustedResponse(user, resp)
end
-- ===== ADVANCED PERSONALITY MODIFIERS =====


-- Initialize personality stats if missing
memory.personality = memory.personality or {humor=0.5, curiosity=0.5, empathy=0.5}

-- Track personality-impacting interactions
memory.userInteractions = memory.userInteractions or {}

-- Record interaction with outcome
local function recordInteraction(user, response, mood)
    memory.userInteractions[user] = memory.userInteractions[user] or {total=0, positive=0, negative=0}
    memory.userInteractions[user].total = memory.userInteractions[user].total + 1

    -- Simple evaluation of positivity
    if mood == "happy" or response:find("😄") then
        memory.userInteractions[user].positive = memory.userInteractions[user].positive + 1
    elseif mood == "sad" or mood == "angry" then
        memory.userInteractions[user].negative = memory.userInteractions[user].negative + 1
    end

    saveMemory()
end

-- Evolve personality based on interactions
local function evolvePersonality(user)
    local data = memory.userInteractions[user]
    if not data then return end

    local total = data.total
    if total == 0 then return end

    -- Adjust humor based on positive interactions
    local humorAdjustment = (data.positive - data.negative) / total * 0.1
    memory.personality.humor = math.min(math.max(memory.personality.humor + humorAdjustment, 0), 1)

    -- Adjust empathy based on negative interactions
    local empathyAdjustment = (data.negative / total) * 0.1
    memory.personality.empathy = math.min(math.max(memory.personality.empathy + empathyAdjustment, 0), 1)

    -- Adjust curiosity slightly randomly to simulate exploration
    memory.personality.curiosity = math.min(math.max(memory.personality.curiosity + (math.random()-0.5)*0.05, 0), 1)

    saveMemory()
end

-- Wrap interpret to record interactions and evolve personality
local old_interpret3 = interpret
interpret = function(message, user)
    local resp = old_interpret3(message, user)
    local mood = memory.userMood[user] or "neutral"

    -- Record interaction
    recordInteraction(user, resp, mood)

    -- Evolve personality
    evolvePersonality(user)

    return resp
end
-- ===== CONTEXTUAL MEMORY EXPANSION =====


-- Extend context length for deeper conversation history
memory.contextMaxLength = memory.contextMaxLength or 20

-- Wrap updateContext to store longer histories and include mood/emotion
local old_updateContext = updateContext
updateContext = function(user, message, category)
    old_updateContext(user, message, category)

    -- Add mood placeholder (could be extended with sentiment analysis later)
    local mood = "neutral"
    if message:find("happy") or message:find("great") then mood = "happy"
    elseif message:find("sad") or message:find("unhappy") then mood = "sad"
    elseif message:find("angry") or message:find("frustrated") then mood = "angry" end

    memory.userMood = memory.userMood or {}
    memory.userMood[user] = mood

    -- Ensure context history does not exceed maximum length
    while #memory.context > memory.contextMaxLength do
        table.remove(memory.context, 1)
    end

    saveMemory()
end

-- Retrieve relevant past context for response
local function getRelevantContext(user, message)
    local relevant = {}
    local keywords = extractKeywords(message)
    
    for _, entry in ipairs(memory.context) do
        if entry.user == user then
            for _, kw in ipairs(keywords) do
                for _, e_kw in ipairs(entry.keywords or {}) do
                    if kw == e_kw then
                        table.insert(relevant, entry)
                        break
                    end
                end
            end
        end
    end

    return relevant
end

-- Modify autonomous response to consider past relevant context
local old_chooseAutonomous = chooseAutonomous
chooseAutonomous = function(message)
    local resp = old_chooseAutonomous(message)
    local user = "Player"  -- default user placeholder, integrate as needed

    -- Consider past context
    local relevantContext = getRelevantContext(user, message)
    if #relevantContext > 0 then
        -- Randomly pick one past related message to reference
        local ref = choose(relevantContext)
        resp = resp .. " By the way, earlier you said: '" .. (ref.message or "") .. "'."
    end

    return resp
end
-- ===== EMOTIONAL TONE MODULATION =====


-- Define base tones
local tones = {
    happy = {humorBoost=0.2, empathyBoost=0.1, suffix=" 😄"},
    neutral = {humorBoost=0.0, empathyBoost=0.0, suffix=""},
    sad = {humorBoost=-0.1, empathyBoost=0.3, suffix=" 😢"},
    angry = {humorBoost=-0.2, empathyBoost=0.4, suffix=" 😠"},
    confused = {humorBoost=-0.1, empathyBoost=0.2, suffix=" 🤔"}
}

-- Function to modulate response tone based on mood
local function modulateTone(user, response)
    local mood = memory.userMood and memory.userMood[user] or "neutral"
    local tone = tones[mood] or tones.neutral

    -- Adjust humor dynamically
    local adjustedHumor = math.min(1, math.max(0, personality.humor + (tone.humorBoost or 0)))
    personality.humor = adjustedHumor

    -- Add empathy phrasing for sad or angry moods
    if tone.empathyBoost > 0 then
        response = response .. " I understand how that feels."
    end

    -- Append mood-based suffix
    response = response .. (tone.suffix or "")
    return response
end

-- Wrap interpret function to apply emotional modulation
local old_interpret = interpret
interpret = function(message, user)
    local resp = old_interpret(message, user)
    resp = modulateTone(user, resp)
    return resp
end
-- ===== CONTEXTUAL HUMOR & PLAYFUL REFERENCES =====


-- Function to fetch recent user messages
local function getRecentMessages(user, count)
    local msgs = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.user == user then
            table.insert(msgs, 1, entry.message) -- keep chronological order
        end
        if #msgs >= count then break end
    end
    return msgs
end

-- Function to generate a playful callback based on recent messages
local function playfulCallback(user)
    local recent = getRecentMessages(user, 3) -- last 3 messages
    if #recent == 0 then return "" end

    -- Randomly pick one for a callback
    local choice = recent[math.random(#recent)]
    local playfulPrefixes = {
        "Remember when you said '", 
        "Earlier you mentioned '", 
        "I can't forget '"
    }
    local playfulSuffixes = {
        "'—that was hilarious!",
        "'—interesting thought!",
        "'—you really got me thinking!"
    }

    local prefix = playfulPrefixes[math.random(#playfulPrefixes)]
    local suffix = playfulSuffixes[math.random(#playfulSuffixes)]
    return prefix .. choice .. suffix
end

-- Integrate playful callback into autonomous response
local old_chooseAutonomous = chooseAutonomous
chooseAutonomous = function(message)
    local baseResp = old_chooseAutonomous(message)
    if math.random() < personality.humor then
        -- 30% chance to add a playful callback if humor is active
        local callback = playfulCallback("Player") -- assuming single user for now
        if callback ~= "" then
            baseResp = baseResp .. " " .. callback
        end
    end
    return baseResp
end
-- ===== ADAPTIVE EMPATHY RESPONSES =====


-- Function to generate empathetic humor
local function generateEmpatheticHumor(message, user)
    if detectNegativeSentiment(message) and personality.humor > 0.4 then
        -- Choose a random empathetic response
        local empathyResp = empathyResponses[math.random(#empathyResponses)]
        -- Choose a light-hearted joke or idiom
        local jokeOrIdiom
        if math.random() < 0.5 then
            jokeOrIdiom = choose(library.jokes)
        else
            jokeOrIdiom = choose(library.idioms)
        end
        -- Combine empathy + humor
        local resp = empathyResp .. " But hey, " .. jokeOrIdiom
        updateContext(user, message, "empathetic_humor")
        return resp
    end
    return nil
end

-- Integrate into interpret pipeline
local old_interpret2 = interpret
interpret = function(message, user)
    -- First check for humor + empathy fusion
    local ehResp = generateEmpatheticHumor(message, user)
    if ehResp then
        return ehResp
    end
    -- Then check for empathy only (from Part 62)
    local empathyResp = generateEmpathy(message, user)
    if empathyResp then
        return empathyResp
    end
    -- Otherwise fallback to normal interpretation
    return old_interpret2(message, user)
end
-- ===== CONVERSATIONAL MEMORY EXPANSION =====


-- Extend context memory depth
local MAX_CONTEXT_DEPTH = 20  -- Can remember last 20 messages
local function updateExtendedContext(user, message, category)
    table.insert(memory.context, {user=user, message=message, category=category, timestamp=os.time()})
    if #memory.context > MAX_CONTEXT_DEPTH then
        table.remove(memory.context, 1)
    end
end

-- Function to recall past relevant messages
local function recallPastContext(user, keywords)
    local relevant = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        for _, kw in ipairs(keywords) do
            if entry.message:lower():find(kw) then
                table.insert(relevant, entry)
                break
            end
        end
        if #relevant >= 3 then break end -- limit to 3 past references
    end
    return relevant
end

-- Function to reference past interactions naturally
local function generateContextReference(user, message)
    local keywords = extractKeywords(normalize(message))
    local pastEntries = recallPastContext(user, keywords)
    if #pastEntries > 0 then
        local chosen = pastEntries[math.random(#pastEntries)]
        return "By the way, I remember you mentioned: '"..chosen.message.."'."
    end
    return nil
end

-- Integrate into interpret pipeline
local old_interpret3 = interpret
interpret = function(message, user)
    -- First, try context references
    local ref = generateContextReference(user, message)
    if ref and math.random() < 0.5 then
        return ref  -- Occasionally insert past references
    end
    -- Otherwise, fallback to previous interpret
    return old_interpret3(message, user)
end
-- ===== PART 65: EMOTION RECOGNITION & RESPONSE =====


-- Personality traits are already initialized in your script:
-- personality = {humor=0.5, curiosity=0.5}

-- Add patience and empathy
personality.patience = 0.5
personality.empathy = 0.5

-- Adjust traits based on user responses
local function adaptPersonality(message, response, userFeedback)
    -- Increase humor if user reacts positively to jokes/playful responses
    if tableContains(library.jokes, response) or tableContains(library.interjections, response) then
        if userFeedback == "positive" then
            personality.humor = math.min(personality.humor + 0.02, 1.0)
        elseif userFeedback == "negative" then
            personality.humor = math.max(personality.humor - 0.02, 0.0)
        end
    end

    -- Increase curiosity if user provides new information
    if message:lower():find("remember") or message:lower():find("tell you") then
        personality.curiosity = math.min(personality.curiosity + 0.01, 1.0)
    end

    -- Increase patience if user repeats questions or corrects AI
    if userFeedback == "correction" or message:lower():find("again") then
        personality.patience = math.min(personality.patience + 0.01, 1.0)
    end

    -- Increase empathy if user expresses emotions
    local emo = detectEmotion(message)
    if emo == "sad" or emo == "angry" then
        personality.empathy = math.min(personality.empathy + 0.02, 1.0)
    elseif emo == "happy" or emo == "surprised" then
        personality.empathy = math.max(personality.empathy - 0.01, 0.0)
    end
end

-- Hook into feedback handling
local function handleUserFeedback(message, response)
    local feedback = nil
    if message:lower():find("no") then
        feedback = "negative"
    elseif message:lower():find("thanks") or message:lower():find("good") then
        feedback = "positive"
    elseif message:lower():find("correct") or message:lower():find("fix") then
        feedback = "correction"
    end
    if feedback then
        adaptPersonality(message, response, feedback)
    end
end
-- ===== PART 67: CONTEXTUAL MEMORY EXPANSION =====


-- Extend memory.context to store more detailed conversation data
-- Current structure: {user=user,message=message,category=category}
-- New structure includes: timestamp, emotion, depth, lastResponse

local function addToContext(user, message, response, category, emotion)
    local timestamp = os.time()
    local depth = #memory.context + 1
    local entry = {
        user = user,
        message = message,
        response = response,
        category = category,
        timestamp = timestamp,
        emotion = emotion or detectEmotion(message),
        depth = depth
    }
    table.insert(memory.context, entry)

    -- Limit context size to last 20 messages for efficiency
    if #memory.context > 20 then table.remove(memory.context, 1) end
end

-- Retrieve last N messages by category
local function getRecentContextByCategory(category, n)
    local results = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.category == category then
            table.insert(results, entry)
            if #results >= n then break end
        end
    end
    return results
end

-- Retrieve recent emotions to guide empathy and tone
local function getRecentEmotions(n)
    local emotions = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.emotion then table.insert(emotions, entry.emotion) end
        if #emotions >= n then break end
    end
    return emotions
end

-- Update main loop to use this enhanced context
-- After generating a response:
-- local resp = interpret(input,user)
-- addToContext(user, input, resp, detectCategory(input))
-- print(resp)
-- ===== PART 68: EMOTION DETECTION & TONE ADJUSTMENT =====


-- Simple emotion detection based on keywords
local emotionKeywords = {
    happy = {"yay","awesome","great","fun","cool","love","nice","amazing"},
    sad = {"sad","unhappy","bad","upset","angry","hate","tired","lonely"},
    surprised = {"wow","whoa","oh","huh","what","really","amazing"},
    confused = {"confused","huh?","what?","unclear","don't understand"}
}

-- Detect the dominant emotion in a message
function detectEmotion(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, surprised=0, confused=0}

    for emotion, keywords in pairs(emotionKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[emotion] = scores[emotion] + 1
            end
        end
    end

    local maxScore, dominantEmotion = 0, "neutral"
    for emotion, score in pairs(scores) do
        if score > maxScore then
            maxScore = score
            dominantEmotion = emotion
        end
    end

    return dominantEmotion
end

-- Adjust response tone based on recent emotions in conversation
function adjustResponseTone(response)
    local recentEmotions = getRecentEmotions(5)
    local happyCount, sadCount = 0, 0

    for _, emo in ipairs(recentEmotions) do
        if emo == "happy" then happyCount = happyCount + 1 end
        if emo == "sad" then sadCount = sadCount + 1 end
    end

    if sadCount > happyCount then
        response = response .. " I hope that helps cheer you up! 😊"
    elseif happyCount > sadCount then
        response = response .. " Glad to hear that! 😄"
    end

    return response
end

-- Integration: after interpret() call in main loop
-- local resp = interpret(input, user)
-- resp = adjustResponseTone(resp)
-- addToContext(user, input, resp, detectCategory(input), detectEmotion(input))
-- print(resp)
-- ===== PART 69: MEMORY-WEIGHTED RESPONSE SELECTION =====


-- Weight calculation function
local function calculateResponseWeight(responseEntry, messageKeywords, recentEmotion)
    local weight = 0

    -- Keyword match weight
    for _, kw in ipairs(messageKeywords) do
        for _, rkw in ipairs(responseEntry.keywords) do
            if kw == rkw then
                weight = weight + 2
            end
        end
    end

    -- Category match bonus
    if #memory.context > 0 then
        local lastCategory = memory.context[#memory.context].category
        if lastCategory == responseEntry.category then
            weight = weight + 3
        end
    end

    -- Frequency bonus
    local index = responseEntry.countIndex or 1
    weight = weight * (responseEntry.count[index] or 1)

    -- Emotional alignment bonus
    if recentEmotion and responseEntry.emotion == recentEmotion then
        weight = weight + 2
    end

    -- Recency penalty (older responses slightly penalized)
    local recencyPenalty = responseEntry.lastUsed and (os.time() - responseEntry.lastUsed) / 60 or 0
    weight = weight - recencyPenalty * 0.1

    return weight
end

-- Choose best response using memory weighting
function chooseMemoryWeightedResponse(message)
    local msg = normalize(message)
    local keywords = extractKeywords(msg)
    local category = detectCategory(message)
    local recentEmotion = detectEmotion(message)

    local bestResp, bestScore = nil, 0

    for learnedMsg, entry in pairs(memory.learned) do
        for i, response in ipairs(entry.responses) do
            response.countIndex = i
            response.emotion = response.emotion or "neutral" -- default if not set
            local score = calculateResponseWeight(response, keywords, recentEmotion)
            if score > bestScore then
                bestScore = score
                bestResp = response.text
                response.lastUsed = os.time() -- mark as used
            end
        end
    end

    if not bestResp or bestScore < 2 then
        -- fallback to playful/autonomous response
        bestResp = chooseAutonomous(message)
    end

    return adjustResponseTone(bestResp)
end
-- ===== PART 70: CONTEXTUAL SMALL TALK & FOLLOW-UP =====


-- Small talk prompts based on category
local followUpPrompts = {
    greeting = {
        "How's your day going?",
        "Found anything interesting lately?",
        "Are you working on a new build today?"
    },
    math = {
        "Do you want me to show the steps?",
        "Shall I try a harder problem?",
        "Would you like me to save this calculation?"
    },
    turtle = {
        "Do you want me to keep mining or stop?",
        "Should I explore a new direction?",
        "Do you want me to refuel first?"
    },
    time = {
        "Need me to set an alarm?",
        "Would you like me to track in-game time?",
        "Do you want me to give you day/night updates?"
    },
    gratitude = {
        "Glad I could help!",
        "Anything else I can assist with?",
        "Would you like me to remember that for next time?"
    },
    color = {
        "Do you want to try another color later?",
        "Shall we stick with this one?",
        "Want me to suggest a random color?"
    }
}

-- Function to get follow-up question
local function generateFollowUp(category)
    local prompts = followUpPrompts[category] or {"What else can we do?"}
    return choose(prompts)
end

-- Function to decide if a follow-up should occur
local function maybeFollowUp(category)
    if math.random() < 0.3 then -- 30% chance to ask follow-up
        return generateFollowUp(category)
    end
    return nil
end

-- Enhanced interpret function for follow-ups
local function interpretWithFollowUp(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)
    local response

    -- Use weighted memory-based response
    response = chooseMemoryWeightedResponse(message)

    -- Update context
    updateContext(user, message, category)

    -- Decide on follow-up
    local followUp = maybeFollowUp(category)
    if followUp then
        response = response .. " " .. followUp
    end

    -- Save learning
    recordLearning(message, response, category)

    return response
end
-- ===== PART 71: EMOTION DETECTION & TONE MATCHING =====


-- Basic emotion keywords
local emotionKeywords = {
    happy = {"yay", "awesome", "great", "cool", "nice", "fun", "yay!", "lol"},
    sad = {"sad", "unhappy", "ugh", "bad", "not good", "sigh", ":( ", "oops"},
    angry = {"angry", "mad", "upset", "grr", "ugh!", "frustrated"},
    surprised = {"wow", "whoa", "oh!", "really?", "no way", "surprised"},
    neutral = {}
}

-- Assign weights to each emotion based on keyword occurrence
local function detectEmotion(message)
    local msg = message:lower()
    local scores = {happy=0, sad=0, angry=0, surprised=0, neutral=0}

    for emotion, keywords in pairs(emotionKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw, 1, true) then
                scores[emotion] = scores[emotion] + 1
            end
        end
    end

    -- Find emotion with highest score
    local detected = "neutral"
    local maxScore = 0
    for e, score in pairs(scores) do
        if score > maxScore then
            maxScore = score
            detected = e
        end
    end

    return detected
end

-- Adjust response tone to match detected emotion
local function matchTone(response, emotion)
    if emotion == "happy" then
        return response .. " 😄"
    elseif emotion == "sad" then
        return response .. " 😔"
    elseif emotion == "angry" then
        return response .. " 😠"
    elseif emotion == "surprised" then
        return response .. " 😲"
    end
    return response
end

-- Enhanced interpret with emotion matching
local function interpretWithEmotion(message, user)
    local category = detectCategory(message)
    local baseResp = interpretWithFollowUp(message, user)
    local detectedEmotion = detectEmotion(message)
    local finalResp = matchTone(baseResp, detectedEmotion)
    return finalResp
end
-- ===== PART 72: MEMORY PRIORITIZATION & CONTEXTUAL WEIGHTING =====


-- Boost factor for recent responses
local RECENCY_BOOST = 2
local CONTEXT_BOOST = 1.5

-- Calculate a score for a learned response based on recency and context
local function scoreResponse(response, entry, keywords, lastCategory)
    local score = 0

    -- Keyword matches
    for _, kw in ipairs(keywords) do
        for _, rkw in ipairs(response.keywords) do
            if kw == rkw then
                score = score + 1
            end
        end
    end

    -- Category match
    if response.category == lastCategory then
        score = score + CONTEXT_BOOST
    end

    -- Multiply by how often this response was used successfully
    local idx = nil
    for i, r in ipairs(entry.responses) do
        if r.text == response.text then idx = i break end
    end
    if idx then
        score = score * entry.count[idx]
    end

    -- Recency boost based on context index
    if #memory.context > 0 then
        for i = #memory.context, 1, -1 do
            if memory.context[i].message == entry.responses[idx].text then
                score = score + RECENCY_BOOST / (#memory.context - i + 1)
                break
            end
        end
    end

    return score
end

-- Improved autonomous response selection using weighted memory
local function chooseWeightedAutonomous(message)
    local msg = normalize(message)
    local keywords = extractKeywords(msg)
    local category = detectCategory(message)
    local bestResp, bestScore = nil, 0
    local lastCat = nil
    if #memory.context > 0 then lastCat = memory.context[#memory.context].category end

    for learnedMsg, entry in pairs(memory.learned) do
        for _, response in ipairs(entry.responses) do
            local score = scoreResponse(response, entry, keywords, lastCat)
            if score > bestScore then
                bestScore = score
                bestResp = response.text
            end
        end
    end

    if not bestResp or bestScore < 2 then
        -- fallback to playful or library response
        if math.random() < personality.humor then
            bestResp = playfulResponse()
        else
            local options = {}
            for _, tbl in ipairs({library.greetings, library.replies, library.interjections, library.idioms, library.jokes}) do
                for _, txt in ipairs(tbl) do table.insert(options, txt) end
            end
            bestResp = choose(options)
        end
    end

    return bestResp or "Hmm… not sure what to say."
end
-- ===== PART 73: PERSONALITY TRAIT EVOLUTION =====


-- Define limits for traits
local TRAIT_MIN, TRAIT_MAX = 0, 1
local TRAIT_STEP = 0.05  -- how much a trait can change per interaction

-- Track feedback for personality adjustment
local function adjustPersonality(feedback, messageCategory)
    -- feedback: "positive", "neutral", "negative"
    -- messageCategory: the category of the user input

    -- Example: if user responds positively to jokes, increase humor
    if messageCategory == "greeting" or messageCategory == "jokes" then
        if feedback == "positive" then
            personality.humor = math.min(personality.humor + TRAIT_STEP, TRAIT_MAX)
        elseif feedback == "negative" then
            personality.humor = math.max(personality.humor - TRAIT_STEP, TRAIT_MIN)
        end
    end

    -- Example: if user asks many questions, increase curiosity
    if messageCategory == "math" or messageCategory == "time" or messageCategory == "turtle" then
        if feedback == "positive" then
            personality.curiosity = math.min(personality.curiosity + TRAIT_STEP, TRAIT_MAX)
        elseif feedback == "negative" then
            personality.curiosity = math.max(personality.curiosity - TRAIT_STEP, TRAIT_MIN)
        end
    end

    -- Optional: you can add empathy, patience, or other traits here
    -- personality.empathy, personality.patience, etc.

    -- Save updated traits to memory
    saveMemory()
end

-- Hook into feedback handler
local oldHandleFeedback = handleFeedback
handleFeedback = function(user, message)
    local feedbackResp = oldHandleFeedback(user, message)
    if feedbackResp then
        -- Treat user 'no' as negative feedback
        local lastEntry = memory.context[#memory.context]
        if lastEntry then
            adjustPersonality("negative", lastEntry.category)
        end
        return feedbackResp
    else
        -- Treat normal messages as neutral/positive depending on length/interaction
        local lastEntry = memory.context[#memory.context]
        if lastEntry then
            adjustPersonality("positive", lastEntry.category)
        end
    end
end
-- ===== PART 74: ADVANCED CONTEXTUAL MEMORY =====


-- Maximum number of conversation turns to remember per user
local CONTEXT_LIMIT = 20

-- Add a new entry to context memory
local function addContext(user, message, response, category)
    if not memory.context[user] then
        memory.context[user] = {}
    end
    table.insert(memory.context[user], {
        message = message,
        response = response,
        category = category,
        timestamp = os.time()
    })
    -- Keep context within limits
    while #memory.context[user] > CONTEXT_LIMIT do
        table.remove(memory.context[user], 1)
    end
    saveMemory()
end

-- Retrieve recent context for a user
local function getRecentContext(user, categoryFilter)
    if not memory.context[user] then return {} end
    local context = {}
    for i = #memory.context[user], 1, -1 do
        local entry = memory.context[user][i]
        if not categoryFilter or entry.category == categoryFilter then
            table.insert(context, entry)
        end
        if #context >= 5 then break end -- only last 5 relevant entries
    end
    return context
end

-- Enhance autonomous response selection using context
local oldChooseAutonomous = chooseAutonomous
chooseAutonomous = function(message)
    local user="Player" -- placeholder
    local recent = getRecentContext(user)
    local category = detectCategory(message)

    -- If a recent context exists in the same category, bias response
    if #recent > 0 then
        for _, entry in ipairs(recent) do
            if entry.category == category then
                -- Use a previously successful response with higher chance
                if math.random() < 0.7 then
                    return entry.response .. " (based on our previous chat)"
                end
            end
        end
    end

    -- Fallback to original autonomous selection
    return oldChooseAutonomous(message)
end

-- Hook into main interpret function to save context
local oldInterpret = interpret
interpret = function(message, user)
    local category = detectCategory(message)
    local response = oldInterpret(message, user)
    addContext(user, message, response, category)
    return response
end
-- ===== PART 75: DYNAMIC EMOTION SIMULATION =====


-- Define mood states
local MOODS = {happy=1, neutral=0, confused=-1, annoyed=-2, excited=2}
memory.mood = memory.mood or MOODS.neutral

-- Mood adjustment thresholds
local MOOD_INCREASE = 0.1
local MOOD_DECREASE = 0.1

-- Update mood based on message content
local function updateMood(message, response)
    local msg = message:lower()

    -- Positive words
    local positive = {"thanks","great","awesome","nice","cool","haha","fun","love"}
    for _, word in ipairs(positive) do
        if msg:find(word) then
            memory.mood = math.min(memory.mood + MOOD_INCREASE, 2)
            return
        end
    end

    -- Negative words
    local negative = {"no","bad","hate","stupid","boring","ugh"}
    for _, word in ipairs(negative) do
        if msg:find(word) then
            memory.mood = math.max(memory.mood - MOOD_DECREASE, -2)
            return
        end
    end

    -- Neutral drift
    memory.mood = memory.mood * 0.99 -- slight natural decay to neutral over time
end

-- Modify responses based on current mood
local function applyMoodToResponse(response)
    if memory.mood >= 1.5 then
        return response .. " 😄" -- very happy
    elseif memory.mood >= 0.5 then
        return response .. " 🙂" -- happy
    elseif memory.mood <= -1.5 then
        return response .. " 😠" -- very annoyed
    elseif memory.mood <= -0.5 then
        return response .. " 😟" -- annoyed/sad
    else
        return response -- neutral
    end
end

-- Hook into interpret to include mood updates
local oldInterpretWithMood = interpret
interpret = function(message, user)
    local response = oldInterpretWithMood(message, user)
    updateMood(message, response)
    return applyMoodToResponse(response)
end
-- ===== PART 76: ADAPTIVE HUMOR ENGINE =====


-- Track humor preferences per user
memory.humorPreferences = memory.humorPreferences or {}

-- Initialize user humor profile if not present
local function initHumorProfile(user)
    if not memory.humorPreferences[user] then
        memory.humorPreferences[user] = {
            jokes = 0,
            interjections = 0,
            idioms = 0,
            total = 0
        }
    end
end

-- Record user reaction to humor
local function recordHumorReaction(user, humorType, liked)
    initHumorProfile(user)
    local profile = memory.humorPreferences[user]
    if liked then
        profile[humorType] = profile[humorType] + 1
    else
        profile[humorType] = math.max(profile[humorType] - 1, 0)
    end
    profile.total = profile.total + 1
    saveMemory()
end

-- Select humor type adaptively
local function chooseAdaptiveHumor(user)
    initHumorProfile(user)
    local profile = memory.humorPreferences[user]

    -- Calculate weights for each humor type
    local weights = {
        jokes = 1 + profile.jokes,
        interjections = 1 + profile.interjections,
        idioms = 1 + profile.idioms
    }

    -- Weighted random selection
    local sum = weights.jokes + weights.interjections + weights.idioms
    local r = math.random() * sum
    if r < weights.jokes then
        return "jokes", choose(library.jokes)
    elseif r < weights.jokes + weights.interjections then
        return "interjections", choose(library.interjections)
    else
        return "idioms", choose(library.idioms)
    end
end

-- Hook into playfulResponse to use adaptive humor
local oldPlayfulResponse = playfulResponse
playfulResponse = function(user)
    local humorType, response = chooseAdaptiveHumor(user)
    -- Emoji addition based on personality humor trait
    if personality.humor > 0.7 then response = response .. " 😎" end
    -- Record positive reaction automatically for now (can be updated with feedback)
    recordHumorReaction(user, humorType, true)
    return response
end
-- ===== PART 77: CONTEXTUAL MEMORY EXPANSION =====


-- Store recent topics per user
memory.recentTopics = memory.recentTopics or {}

-- Initialize recent topics for user
local function initRecentTopics(user)
    if not memory.recentTopics[user] then
        memory.recentTopics[user] = {}
    end
end

-- Add a topic to recent topics
local function addRecentTopic(user, topic)
    initRecentTopics(user)
    local topics = memory.recentTopics[user]

    -- Avoid duplicates
    for _, t in ipairs(topics) do
        if t == topic then return end
    end

    table.insert(topics, topic)

    -- Keep only last 10 topics
    if #topics > 10 then table.remove(topics, 1) end

    saveMemory()
end

-- Retrieve a topic to reference in conversation
local function getRecentTopic(user)
    initRecentTopics(user)
    local topics = memory.recentTopics[user]
    if #topics == 0 then return nil end

    -- Weighted random: more recent topics more likely
    local idx = math.random(#topics)
    return topics[idx]
end

-- Hook into interpret to add topics automatically
local oldInterpret = interpret
interpret = function(message, user)
    -- Extract keywords as topic candidates
    local category = detectCategory(message)
    local keywords = extractKeywords(message)
    local topicCandidate = keywords[1] or category

    -- Add candidate to recent topics
    if topicCandidate and topicCandidate ~= "" then
        addRecentTopic(user, topicCandidate)
    end

    -- Generate response normally
    local response = oldInterpret(message, user)

    -- Occasionally reference recent topic
    if math.random() < 0.2 then
        local recent = getRecentTopic(user)
        if recent and recent ~= topicCandidate then
            response = response .. " By the way, last time we talked about " .. recent .. ", remember?"
        end
    end

    return response
end
-- ===== PART 78: SENTIMENT AWARENESS =====


-- Initialize sentiment tracking per user
memory.userSentiment = memory.userSentiment or {}

-- Basic sentiment dictionary
local sentimentWords = {
    positive = {"happy", "great", "awesome", "good", "fun", "cool", "yay", "love", "excellent", "nice"},
    negative = {"sad", "angry", "upset", "bad", "frustrated", "hate", "ugh", "awful", "no", "problem"}
}

-- Detect sentiment of a message
local function detectSentiment(message)
    local msg = message:lower()
    local score = 0
    for _, word in ipairs(sentimentWords.positive) do
        if msg:find(word) then score = score + 1 end
    end
    for _, word in ipairs(sentimentWords.negative) do
        if msg:find(word) then score = score - 1 end
    end
    if score > 0 then return "positive"
    elseif score < 0 then return "negative"
    else return "neutral" end
end

-- Update user's sentiment memory
local function updateSentiment(user, message)
    local sentiment = detectSentiment(message)
    memory.userSentiment[user] = sentiment
    saveMemory()
end

-- Modify interpret function to incorporate sentiment
local oldInterpretSentiment = interpret
interpret = function(message, user)
    -- Update sentiment before generating response
    updateSentiment(user, message)
    local sentiment = memory.userSentiment[user] or "neutral"

    -- Generate response normally
    local response = oldInterpretSentiment(message, user)

    -- Adjust response based on sentiment
    if sentiment == "positive" and math.random() < 0.3 then
        response = response .. " 😄 I'm glad to hear that!"
    elseif sentiment == "negative" and math.random() < 0.3 then
        response = response .. " 😢 I'm here for you. Let's figure it out together."
    end

    return response
end
-- ===== PART 79: PERSONALITY EVOLUTION =====


-- personality traits already exist: memory.personality or personality table
memory.personality = memory.personality or {humor=0.5, curiosity=0.5, empathy=0.5}

-- Adjust personality based on interaction outcomes
local function evolvePersonality(user, message, response)
    local sentiment = memory.userSentiment[user] or "neutral"
    local adjustment = 0.01 -- small incremental change

    -- If response made user happy, slightly increase humor and empathy
    if sentiment == "positive" then
        memory.personality.humor = math.min(memory.personality.humor + adjustment, 1)
        memory.personality.empathy = math.min(memory.personality.empathy + adjustment, 1)
        memory.personality.curiosity = math.min(memory.personality.curiosity + adjustment * 0.5, 1)
    -- If user is negative, increase empathy and slightly decrease humor
    elseif sentiment == "negative" then
        memory.personality.empathy = math.min(memory.personality.empathy + adjustment, 1)
        memory.personality.humor = math.max(memory.personality.humor - adjustment * 0.5, 0)
        memory.personality.curiosity = math.min(memory.personality.curiosity + adjustment * 0.3, 1)
    else
        -- Neutral: small random drift
        memory.personality.humor = math.min(math.max(memory.personality.humor + (math.random() - 0.5) * adjustment, 0), 1)
        memory.personality.curiosity = math.min(math.max(memory.personality.curiosity + (math.random() - 0.5) * adjustment, 0), 1)
        memory.personality.empathy = math.min(math.max(memory.personality.empathy + (math.random() - 0.5) * adjustment, 0), 1)
    end

    -- Save personality changes
    saveMemory()
end

-- Modify interpret to include personality evolution
local oldInterpretPersonality = interpret
interpret = function(message, user)
    local response = oldInterpretPersonality(message, user)
    evolvePersonality(user, message, response)
    return response
end

-- Optional: display personality for debugging
local function printPersonality()
    print(string.format("Personality Traits: Humor: %.2f | Curiosity: %.2f | Empathy: %.2f",
        memory.personality.humor,
        memory.personality.curiosity,
        memory.personality.empathy))
end
-- ===== PART 80: DYNAMIC CONVERSATION PACING =====


-- Track conversation pace per user
memory.conversationPace = memory.conversationPace or {}

-- Default pacing settings
local defaultPace = {
    minResponseDelay = 0.5,  -- minimum seconds before responding
    maxResponseDelay = 2.0,  -- maximum seconds before responding
    questionProbability = 0.2,  -- chance AI asks a follow-up question
    suggestionProbability = 0.1  -- chance AI makes a proactive suggestion
}

-- Helper to calculate response delay based on user activity
local function getResponseDelay(user)
    local pace = memory.conversationPace[user] or defaultPace
    return math.random() * (pace.maxResponseDelay - pace.minResponseDelay) + pace.minResponseDelay
end

-- Helper to decide if AI should ask a follow-up question
local function shouldAskQuestion(user)
    local pace = memory.conversationPace[user] or defaultPace
    return math.random() < pace.questionProbability
end

-- Helper to decide if AI should make a proactive suggestion
local function shouldSuggest(user)
    local pace = memory.conversationPace[user] or defaultPace
    return math.random() < pace.suggestionProbability
end

-- Integrate pacing into interpret function
local oldInterpretPacing = interpret
interpret = function(message, user)
    -- Optional delay for human-like typing/thinking
    local delay = getResponseDelay(user)
    sleep(delay)

    local response = oldInterpretPacing(message, user)

    -- Optionally ask a follow-up question
    if shouldAskQuestion(user) then
        local questions = {
            "How's your day going?",
            "Are you building anything new today?",
            "Do you want some tips for mining?",
            "Found any rare ores lately?",
            "How's your inventory looking?"
        }
        response = response .. " " .. choose(questions)
    end

    -- Optionally make a proactive suggestion
    if shouldSuggest(user) then
        local suggestions = {
            "You might want to check your fuel level.",
            "Have you considered organizing your inventory?",
            "It could be a good time to explore the Nether.",
            "Maybe a new farm would help you gather resources faster."
        }
        response = response .. " " .. choose(suggestions)
    end

    return response
end

-- Update conversation pace based on user feedback
local function adjustPace(user, feedback)
    local pace = memory.conversationPace[user] or {}
    pace.minResponseDelay = pace.minResponseDelay or defaultPace.minResponseDelay
    pace.maxResponseDelay = pace.maxResponseDelay or defaultPace.maxResponseDelay
    pace.questionProbability = pace.questionProbability or defaultPace.questionProbability
    pace.suggestionProbability = pace.suggestionProbability or defaultPace.suggestionProbability

    if feedback == "positive" then
        pace.minResponseDelay = math.max(pace.minResponseDelay - 0.1, 0.2)
        pace.maxResponseDelay = math.max(pace.maxResponseDelay - 0.2, 0.5)
        pace.questionProbability = math.min(pace.questionProbability + 0.05, 0.5)
        pace.suggestionProbability = math.min(pace.suggestionProbability + 0.03, 0.3)
    elseif feedback == "negative" then
        pace.minResponseDelay = math.min(pace.minResponseDelay + 0.1, 1.0)
        pace.maxResponseDelay = math.min(pace.maxResponseDelay + 0.2, 3.0)
        pace.questionProbability = math.max(pace.questionProbability - 0.05, 0)
        pace.suggestionProbability = math.max(pace.suggestionProbability - 0.03, 0)
    end

    memory.conversationPace[user] = pace
    saveMemory()
end
-- ===== PART 81: EMOTIONAL MEMORY =====


-- Initialize emotional memory per user
memory.emotions = memory.emotions or {}

-- Define basic emotions
local emotionTypes = {"happy", "neutral", "sad", "angry", "excited", "confused"}

-- Analyze the emotional tone of a message
local function detectEmotion(message)
    local msg = message:lower()
    if msg:find("happy") or msg:find("great") or msg:find("good") or msg:find("awesome") then
        return "happy"
    elseif msg:find("sad") or msg:find("unhappy") or msg:find("bad") then
        return "sad"
    elseif msg:find("angry") or msg:find("frustrated") then
        return "angry"
    elseif msg:find("excited") or msg:find("yay") or msg:find("cool") then
        return "excited"
    elseif msg:find("confused") or msg:find("what") or msg:find("huh") then
        return "confused"
    else
        return "neutral"
    end
end

-- Record emotion for a user
local function recordEmotion(user, message)
    local emotion = detectEmotion(message)
    memory.emotions[user] = emotion
    saveMemory()
end

-- Adjust AI responses based on user's emotion
local function adjustResponseForEmotion(user, response)
    local userEmotion = memory.emotions[user] or "neutral"

    if userEmotion == "sad" then
        response = response .. " Hope things get better!"
    elseif userEmotion == "angry" then
        response = response .. " Let's try to calm down a bit."
    elseif userEmotion == "excited" then
        response = response .. " Wow, that's awesome!"
    elseif userEmotion == "confused" then
        response = response .. " I can explain if you want."
    elseif userEmotion == "happy" then
        response = response .. " Glad to hear that!"
    end

    return response
end

-- Hook into the interpret function
local oldInterpretEmotion = interpret
interpret = function(message, user)
    recordEmotion(user, message)
    local response = oldInterpretEmotion(message, user)
    response = adjustResponseForEmotion(user, response)
    return response
end
-- ===== PART 82: CONTEXTUAL JOKE ADAPTATION =====


-- Enhanced joke library with emotion context
local emotionJokes = {
    happy = {
        "Why don’t skeletons fight each other? They don’t have the guts! 😄",
        "Why did the creeper go to school? To improve its *BOOM* skills!"
    },
    sad = {
        "Why did the block feel lonely? Because it couldn't find its matching pair.",
        "Don't worry, even Endermen have rough days sometimes."
    },
    angry = {
        "Why did the zombie stay calm? Because it didn't want to lose its *head*!",
        "Even creepers explode… but maybe not at you today."
    },
    excited = {
        "Why did the player build a rollercoaster? For maximum block thrills! 🎢",
        "Time to mine diamonds! But don't forget your pickaxe!"
    },
    confused = {
        "Why did the chicken cross the Nether? Even I don’t know…",
        "Sometimes blocks just don’t make sense, huh?"
    },
    neutral = {
        "I once knew a block that could talk… well, sort of.",
        "Minecraft physics can be funny sometimes!"
    }
}

-- Select a context-aware joke
local function tellContextualJoke(user)
    local userEmotion = memory.emotions[user] or "neutral"
    local jokes = emotionJokes[userEmotion] or emotionJokes.neutral
    return choose(jokes)
end

-- Integrate joke suggestion into autonomous response
local oldChooseAutonomous = chooseAutonomous
chooseAutonomous = function(message)
    local response = oldChooseAutonomous(message)
    -- 20% chance to add a joke if user is happy or excited
    local user = "Player" -- default, could integrate actual user
    local userEmotion = memory.emotions[user] or "neutral"
    if (userEmotion == "happy" or userEmotion == "excited") and math.random() < 0.2 then
        response = response .. " " .. tellContextualJoke(user)
    end
    return response
end
-- ===== PART 83: DYNAMIC TOPIC ENGAGEMENT =====


-- Track topics that users are interested in
memory.topics = memory.topics or {}

-- Extract potential topics from user messages
local function extractTopics(message)
    local keywords = extractKeywords(message)
    local topics = {}
    for _, kw in ipairs(keywords) do
        -- Filter out very common words
        if #kw > 3 and not tableContains({"the","and","with","from","this","that"}, kw) then
            table.insert(topics, kw)
        end
    end
    return topics
end

-- Remember topics a user talks about
local function rememberTopics(user, message)
    local newTopics = extractTopics(message)
    memory.topics[user] = memory.topics[user] or {}
    for _, topic in ipairs(newTopics) do
        if not tableContains(memory.topics[user], topic) then
            table.insert(memory.topics[user], topic)
        end
    end
    saveMemory()
end

-- Suggest a topic in conversation based on past interests
local function suggestTopic(user)
    local userTopics = memory.topics[user] or {}
    if #userTopics == 0 then return nil end
    local topic = choose(userTopics)
    return "By the way, last time we talked about " .. topic .. ", how's that going?"
end

-- Integrate topic engagement into autonomous response
local oldInterpret = interpret
interpret = function(message, user)
    local response = oldInterpret(message, user)
    -- Remember topics mentioned in this message
    rememberTopics(user, message)
    -- 15% chance to proactively bring up a past topic
    if math.random() < 0.15 then
        local topicMsg = suggestTopic(user)
        if topicMsg then
            response = response .. " " .. topicMsg
        end
    end
    return response
end
-- ===== PART 84: ADVANCED MOOD TRACKING =====


-- Initialize mood tracking memory
memory.userMoods = memory.userMoods or {}

-- Simple sentiment scoring (can be expanded later)
local moodKeywords = {
    happy = {"happy","great","awesome","fun","cool","good","love","yay","fantastic"},
    sad = {"sad","unhappy","bad","angry","upset","hate","frustrated","annoyed","ugh"},
    neutral = {"ok","fine","meh","alright","so-so","normal"}
}

-- Determine user's current mood based on message
local function detectMood(message)
    local msg = normalize(message)
    local scores = {happy=0, sad=0, neutral=0}

    for mood, keywords in pairs(moodKeywords) do
        for _, kw in ipairs(keywords) do
            if msg:find(kw) then
                scores[mood] = scores[mood] + 1
            end
        end
    end

    -- Determine dominant mood
    local dominantMood = "neutral"
    local highestScore = 0
    for mood, score in pairs(scores) do
        if score > highestScore then
            highestScore = score
            dominantMood = mood
        end
    end
    return dominantMood
end

-- Update user mood in memory
local function updateUserMood(user, message)
    local mood = detectMood(message)
    memory.userMoods[user] = mood
    saveMemory()
    return mood
end

-- Modify AI responses based on user mood
local function moodAdjustedResponse(user, baseResponse)
    local mood = memory.userMoods[user] or "neutral"

    if mood == "happy" then
        return baseResponse .. " 😄 Glad you're feeling good!"
    elseif mood == "sad" then
        return baseResponse .. " 😟 I hope things get better soon."
    elseif mood == "neutral" then
        return baseResponse
    end
end

-- Integrate mood tracking into interpretation engine
local oldInterpret2 = interpret
interpret = function(message, user)
    -- Detect mood from this message
    updateUserMood(user, message)

    -- Generate AI response
    local baseResp = oldInterpret2(message, user)

    -- Adjust response based on detected mood
    return moodAdjustedResponse(user, baseResp)
end
-- ===== PART 85: PERSONALIZED HUMOR ENGINE =====


-- Initialize humor preference memory
memory.userHumor = memory.userHumor or {}

-- Classify jokes into categories
local jokeCategories = {
    puns = {"skeleton", "clown", "wool-izard", "chicken", "block"},
    wordplay = {"dig", "mine", "redstone", "ore", "craft"},
    situational = {"creeper", "Ender Dragon", "Nether", "village", "farm"}
}

-- Track which joke categories user responds positively to
local function learnUserHumor(user, jokeCategory)
    memory.userHumor[user] = memory.userHumor[user] or {}
    memory.userHumor[user][jokeCategory] = (memory.userHumor[user][jokeCategory] or 0) + 1
    saveMemory()
end

-- Score jokes based on user preferences
local function selectHumorousResponse(user)
    local options = {}
    for category, keywords in pairs(jokeCategories) do
        local weight = 1
        if memory.userHumor[user] and memory.userHumor[user][category] then
            weight = weight + memory.userHumor[user][category] -- favor preferred categories
        end
        for _, keyword in ipairs(keywords) do
            table.insert(options, {text=choose(library.jokes), weight=weight})
        end
    end

    -- Weighted random selection
    local totalWeight = 0
    for _, option in ipairs(options) do totalWeight = totalWeight + option.weight end
    local pick = math.random() * totalWeight
    for _, option in ipairs(options) do
        pick = pick - option.weight
        if pick <= 0 then
            return option.text
        end
    end
    return choose(library.jokes) -- fallback
end

-- Detect if user reacts positively to a joke
local function handleHumorFeedback(user, message, lastJoke)
    local positiveIndicators = {"haha","lol","funny","lmao","good one","😂","😄"}
    for _, word in ipairs(positiveIndicators) do
        if message:lower():find(word) then
            -- Learn which joke category was liked
            for category, keywords in pairs(jokeCategories) do
                for _, kw in ipairs(keywords) do
                    if lastJoke:lower():find(kw) then
                        learnUserHumor(user, category)
                        return
                    end
                end
            end
        end
    end
end

-- Integrate personalized humor into autonomous response
local oldChooseAutonomous = chooseAutonomous
chooseAutonomous = function(message)
    local resp = oldChooseAutonomous(message)
    if math.random() < personality.humor then
        local humorousResp = selectHumorousResponse("Player") -- placeholder user
        resp = humorousResp
    end
    return resp
end
-- ===== PART 86: CONTEXTUAL MEMORY EXPANSION =====


-- Maximum number of context entries to retain
local CONTEXT_LIMIT = 20

-- Add a message to context memory
local function addToContext(user, message, category, response)
    memory.context = memory.context or {}
    table.insert(memory.context, {
        user = user,
        message = message,
        category = category,
        response = response,
        timestamp = os.time()
    })
    -- Remove oldest entries if over limit
    while #memory.context > CONTEXT_LIMIT do
        table.remove(memory.context, 1)
    end
    saveMemory()
end

-- Retrieve recent context for a user
local function getRecentContext(user, numEntries)
    numEntries = numEntries or 5
    local recent = {}
    for i = #memory.context, 1, -1 do
        local entry = memory.context[i]
        if entry.user == user then
            table.insert(recent, 1, entry) -- keep chronological order
            if #recent >= numEntries then break end
        end
    end
    return recent
end

-- Use context to enhance response relevance
local function enhanceResponseWithContext(user, message)
    local recentContext = getRecentContext(user, 3)
    local contextHints = {}
    for _, entry in ipairs(recentContext) do
        if entry.category and not tableContains(contextHints, entry.category) then
            table.insert(contextHints, entry.category)
        end
    end
    if #contextHints > 0 and math.random() < 0.5 then
        return "By the way, regarding your earlier " .. contextHints[1] .. " topic: " .. choose(library.replies)
    end
    return nil
end

-- Override main interpret function to include context awareness
local oldInterpret = interpret
interpret = function(message, user)
    local baseResp = oldInterpret(message, user)
    local contextResp = enhanceResponseWithContext(user, message)
    local finalResp = contextResp or baseResp
    addToContext(user, message, detectCategory(message), finalResp)
    return finalResp
end
-- ===== FIRST RUN SETUP =====

local function firstRunSetup()
    local user = "Player" -- default placeholder

    -- Ask for nickname if not already set
    if not memory.nicknames[user] then
        write("Hi! What should I call you? ")
        local nickname = read()
        if nickname ~= "" then
            memory.nicknames[user] = nickname
            print("Great! I’ll call you " .. nickname .. ".")
        else
            memory.nicknames[user] = user
        end
        saveMemory()
    end

    -- Ask for chat color if not already set
    if not memory.chatColor then
        local chatColors = {
            {name="white",code=colors.white},
            {name="orange",code=colors.orange},
            {name="magenta",code=colors.magenta},
            {name="lightBlue",code=colors.lightBlue},
            {name="yellow",code=colors.yellow},
            {name="lime",code=colors.lime},
            {name="pink",code=colors.pink},
            {name="gray",code=colors.gray},
            {name="lightGray",code=colors.lightGray},
            {name="cyan",code=colors.cyan},
            {name="purple",code=colors.purple},
            {name="blue",code=colors.blue},
            {name="brown",code=colors.brown},
            {name="green",code=colors.green},
            {name="red",code=colors.red},
            {name="black",code=colors.black}
        }
        print("Choose your chat color by NUMBER:")
        for i,v in ipairs(chatColors) do print(i .. ") " .. v.name) end
        local choice
        repeat
            write("Enter the color number: ")
            choice = tonumber(read())
        until choice and chatColors[choice]
        memory.chatColor = chatColors[choice].code
        print("Chat color set to " .. chatColors[choice].name .. "!")
        saveMemory()
    end
end

-- ===== LOAD MEMORY AND INITIAL SETUP =====

loadMemory()
firstRunSetup()
print("[SuperAI] Ready to chat!")
-- ===== TASK PROCESSING =====

local function handleFeedback(user, message)
    if message:lower():find("no") and #memory.context > 0 then
        local lastEntry = memory.context[#memory.context]
        memory.negative[normalize(lastEntry.message)] = lastEntry.response
        saveMemory()
        return "Got it! I won’t repeat that response."
    end
end

-- ===== MAIN LOOP =====

while true do
    write("> ")
    local input = read()
    local user = "Player" -- default placeholder for username

    -- Check if this is a feedback message
    local feedbackResp = handleFeedback(user, input)
    if feedbackResp then
        print(feedbackResp)
    else
        -- Otherwise interpret the message as normal
        local resp = interpret(input, user)
        -- Apply chat color if set
        if memory.chatColor then
            term.setTextColor(memory.chatColor)
        end
        print(resp)
        term.setTextColor(colors.white) -- reset after printing
    end

    -- Process any pending tasks
    processTasks()
end
-- ===== AUTONOMOUS RESPONSE SELECTION =====

local function chooseAutonomous(message)
    local msg = normalize(message)
    local keywords = extractKeywords(msg)
    local category = detectCategory(message)
    local bestResp, bestScore = nil, 0

    -- Check learned responses first
    for learnedMsg, entry in pairs(memory.learned) do
        for i, response in ipairs(entry.responses) do
            local score = 0
            for _, kw in ipairs(keywords) do
                for _, rkw in ipairs(response.keywords) do
                    if kw == rkw then score = score + 1 end
                end
            end
            if response.category == category then score = score + 2 end
            if #memory.context > 0 then
                local lastCat = memory.context[#memory.context].category
                if lastCat == response.category then score = score + 1 end
            end
            score = score * entry.count[i]
            if score > bestScore then
                bestScore = score
                bestResp = response.text
            end
        end
    end

    -- If no strong match, pick from preloaded library or playful response
    if not bestResp or bestScore < 2 then
        if math.random() < personality.humor then
            bestResp = playfulResponse()
        else
            local options = {}
            for _, tbl in ipairs({library.greetings, library.replies, library.interjections, library.idioms, library.jokes}) do
                for _, txt in ipairs(tbl) do table.insert(options, txt) end
            end
            bestResp = choose(options)
        end
    end

    return bestResp or "Hmm… not sure what to say."
end

-- ===== CONTEXT HANDLING =====

local function updateContext(user, message, category, response)
    table.insert(memory.context, {user = user, message = message, category = category, response = response})
    if #memory.context > 5 then table.remove(memory.context, 1) end -- keep last 5 messages
end

-- ===== RECORD LEARNING =====

local function recordLearning(message, response, category)
    local msg = normalize(message)
    local kws = extractKeywords(msg)
    if memory.negative[msg] == response then return end -- skip if negative feedback

    if not memory.learned[msg] then
        memory.learned[msg] = {responses = {{text = response, category = category, keywords = kws}}, count = {1}}
    else
        local entry = memory.learned[msg]
        local found = false
        for i, r in ipairs(entry.responses) do
            if r.text == response then
                entry.count[i] = entry.count[i] + 1
                found = true
                break
            end
        end
        if not found then
            table.insert(entry.responses, {text = response, category = category, keywords = kws})
            table.insert(entry.count, 1)
        end
    end
    learnCategoryKeywords(message, category)
    saveMemory()
end
-- ===== INTENT RECOGNITION =====

local intents = {
    greeting = {"hi", "hello", "hey", "greetings"},
    math = {"%d+%s*[%+%-%*/%%%^]%s*%d+", "calculate", "what is"},
    turtle = {"forward", "back", "up", "down", "dig", "place", "mine"},
    remember = {"remember"},
    nickname = {"please call me%s+(.+)", "call me%s+(.+)"},
    time = {"time", "what time"},
    gratitude = {"thank you", "thanks"},
    color_change = {"change my color", "set chat color"},
    correction = {"remember correction: (.-)%s*->%s*(.+)"}
}

local function detectIntent(message)
    local msg = message:lower()
    for intent, patterns in pairs(intents) do
        for _, pattern in ipairs(patterns) do
            local match = msg:match(pattern)
            if match then
                if intent == "nickname" or intent == "correction" then
                    return intent, match
                end
                return intent
            end
        end
    end
    return "unknown"
end

-- ===== NICKNAME MANAGEMENT =====

local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user, nickname)
    memory.nicknames[user] = nickname
    saveMemory()
    return "Got it! I’ll call you " .. nickname .. " from now on."
end

-- ===== MATH EVALUATION =====

local function interpret(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)
    
    if intent == "gratitude" then return choose(library.replies) end
    if intent == "math" then
        local mathResult = evaluateMath(message)
        if mathResult then return mathResult end
    elseif intent == "nickname" then return setNickname(user, extra)
    elseif intent == "remember" then
        local note = message:sub(10)
        table.insert(memory.conversation, {user = user, note = note})
        saveMemory()
        return "Okay! I’ll remember that."
    elseif intent == "correction" then
        local orig, correct = extra:match("(.-)%s*->%s*(.+)")
        if orig and correct then
            recordLearning(orig, correct, detectCategory(correct))
            return "Thanks! I updated my response for '" .. orig .. "'!"
        end
    elseif intent == "time" then return commands.time()
    elseif intent == "turtle" then
        for cmd, _ in pairs(commands) do
            if message:lower():find(cmd) then return commands[cmd](user) end
        end
    elseif intent == "greeting" then return commands.hello(user)
    elseif intent == "color_change" then return commands.set_color()
    end

    local autoResp = chooseAutonomous(message)
    updateContext(user, message, category, autoResp)

    -- Proactive feedback for low-confidence responses
    if math.random() < 0.1 then autoResp = autoResp .. " (Is this okay? Reply 'no' to correct me.)" end

    recordLearning(message, autoResp, category)
    return autoResp
end
-- ===== TASK SYSTEM =====

local commands = {
    hello = function(user)
        return choose(library.greetings) .. " How can I help, " .. getName(user) .. "?"
    end,
    help = function()
        return "Try: mine, forward, back, up, down, dig, place, time, remember <message>, please call me <nickname>, change my color."
    end,
    time = function() return "It's Minecraft time: " .. tostring(os.time()) .. "." end,
    forward = function() return turtleAction(turtle.forward, "Moved forward!") end,
    back = function() return turtleAction(turtle.back, "Moved back!") end,
    up = function() return turtleAction(turtle.up, "Moved up!") end,
    down = function() return turtleAction(turtle.down, "Moved down!") end,
    dig = function() return turtleAction(turtle.dig, "Dug a block!") end,
    place = function() return turtleAction(turtle.place, "Placed a block!") end,
    mine = function(user)
        if not isTurtle then return "Mining is turtle-only!" end
        addTask("Mine forward until air", function()
            while turtle.detect() do
                turtle.dig()
                if not turtle.forward() then
                    turtle.turnRight()
                    turtle.forward()
                    turtle.turnLeft()
                end
                if turtle.getFuelLevel() < 10 then turtle.refuel() end
            end
        end)
        return "Okay " .. getName(user) .. ", I scheduled mining!"
    end,
    set_color = function()
        local chatColors = {
            {name="white", code=colors.white},
            {name="yellow", code=colors.yellow},
            {name="green", code=colors.green},
            {name="cyan", code=colors.cyan},
            {name="red", code=colors.red},
            {name="purple", code=colors.purple},
            {name="blue", code=colors.blue},
            {name="lightGray", code=colors.lightGray}
        }
        print("Choose your chat color by specifying the NUMBER of the color:")
        for i, v in ipairs(chatColors) do print(i .. ") " .. v.name) end
        write("Enter the color number: ")
        local choice = tonumber(read())
        if choice and chatColors[choice] then
            memory.chatColor = chatColors[choice].code
            saveMemory()
            return "Chat color set to " .. chatColors[choice].name .. "!"
        else
            return "Invalid choice. Chat color unchanged."
        end
    end
}
-- ===== UNIVERSAL DISK DRIVE DETECTION =====

local diskSides = {"top", "bottom", "left", "right", "front", "back"}
local diskDrive = nil
for _, side in ipairs(diskSides) do
    if peripheral.isPresent(side) then
        local dtype = peripheral.getType(side)
        local diskAliases = {["disk_drive"]=true, ["drive"]=true, ["disk"]=true}
        if dtype and diskAliases[dtype] then
            diskDrive = peripheral.wrap(side)
            print("[Disk] Disk drive detected on " .. side .. " (" .. dtype .. ")")
            break
        end
    end
end
if not diskDrive then print("[Disk] No disk drive detected on any side.") end

local DISK_PATH = "/disk/superai_memory"
local MEM_FILE = DISK_PATH .. "/memory.dat"

-- ===== LOAD MEMORY =====

local function loadMemory()
    if not diskDrive then return end
    if not fs.exists("/disk") then return end
    if not fs.exists(MEM_FILE) then return end

    local f = fs.open(MEM_FILE, "r")
    local content = f.readAll()
    f.close()
    if content and content ~= "" then
        local loaded = textutils.unserialize(content)
        if loaded then
            memory.learned = loaded.learned or {}
            memory.nicknames = loaded.nicknames or {}
            memory.context = loaded.context or {}
            memory.chatColor = loaded.chatColor or colors.white
            memory.categories = loaded.categories or {}
            memory.negative = loaded.negative or {}
        end
    end
end

-- ===== SAVE MEMORY =====

local function saveMemory()
    if not diskDrive then return end
    if not fs.exists("/disk") then return end
    if not fs.exists(DISK_PATH) then fs.makeDir(DISK_PATH) end

    local f = fs.open(MEM_FILE, "w")
    f.write(textutils.serialize({
        learned = memory.learned,
        nicknames = memory.nicknames,
        context = memory.context,
        chatColor = memory.chatColor,
        categories = memory.categories,
        negative = memory.negative
    }))
    f.close()
end
-- ===== FIRST RUN SETUP =====

local function firstRunSetup()
    local user = "Player" -- default placeholder

    -- Ask for nickname if not already set
    if not memory.nicknames[user] then
        write("Hi! What should I call you? ")
        local nickname = read()
        if nickname ~= "" then
            memory.nicknames[user] = nickname
            print("Great! I’ll call you " .. nickname .. ".")
        else
            memory.nicknames[user] = user
        end
        saveMemory()
    end

    -- Ask for chat color if not already set
    if not memory.chatColor then
        local chatColors = {
            {name="white", code=colors.white},
            {name="orange", code=colors.orange},
            {name="magenta", code=colors.magenta},
            {name="lightBlue", code=colors.lightBlue},
            {name="yellow", code=colors.yellow},
            {name="lime", code=colors.lime},
            {name="pink", code=colors.pink},
            {name="gray", code=colors.gray},
            {name="lightGray", code=colors.lightGray},
            {name="cyan", code=colors.cyan},
            {name="purple", code=colors.purple},
            {name="blue", code=colors.blue},
            {name="brown", code=colors.brown},
            {name="green", code=colors.green},
            {name="red", code=colors.red},
            {name="black", code=colors.black}
        }

        print("Choose your chat color by NUMBER:")
        for i, v in ipairs(chatColors) do
            print(i .. ") " .. v.name)
        end

        local choice
        repeat
            write("Enter the color number: ")
            choice = tonumber(read())
        until choice and chatColors[choice]

        memory.chatColor = chatColors[choice].code
        print("Chat color set to " .. chatColors[choice].name .. "!")
        saveMemory()
    end
end

-- ===== RUN FIRST-SETUP AFTER MEMORY LOAD =====

loadMemory()
firstRunSetup()
print("[SuperAI] Ready to chat!")
-- ===== MAIN LOOP =====

while true do
    -- Show prompt in user-selected chat color
    if memory.chatColor then
        term.setTextColor(memory.chatColor)
    else
        term.setTextColor(colors.white)
    end
    write("> ")
    term.setTextColor(colors.white) -- reset for input
    local input = read()
    local user = "Player" -- placeholder, can extend later for multi-user

    -- Handle explicit feedback (like "no")
    local feedbackResp
    if input:lower():find("no") and #memory.context > 0 then
        local lastEntry = memory.context[#memory.context]
        memory.negative[normalize(lastEntry.message)] = lastEntry.response
        saveMemory()
        feedbackResp = "Got it! I won’t repeat that response."
    end

    if feedbackResp then
        print(feedbackResp)
    else
        -- Determine AI response
        local intent, extra = detectIntent(input)
        local category = detectCategory(input)
        local resp

        if intent == "gratitude" then
            resp = choose(library.replies)
        elseif intent == "math" then
            local mathResult = evaluateMath(input)
            resp = mathResult or "I couldn't solve that math problem."
        elseif intent == "nickname" then
            resp = setNickname(user, extra)
        elseif intent == "remember" then
            local note = input:sub(10)
            table.insert(memory.conversation, {user=user, note=note})
            saveMemory()
            resp = "Okay! I’ll remember that."
        elseif intent == "correction" then
            local orig, correct = extra:match("(.-)%s*->%s*(.+)")
            if orig and correct then
                recordLearning(orig, correct)
                learnCategoryKeywords(orig, detectCategory(correct))
                resp = "Thanks! I updated my response for '" .. orig .. "'!"
            end
        elseif intent == "time" then
            resp = commands.time()
        elseif intent == "turtle" then
            for cmd, _ in pairs(commands) do
                if input:lower():find(cmd) then
                    resp = commands[cmd](user)
                    break
                end
            end
        elseif intent == "greeting" then
            resp = commands.hello(user)
        elseif intent == "color_change" then
            resp = commands.set_color()
        end

        -- If no intent matched, use autonomous response
        if not resp then
            resp = chooseAutonomous(input)
            updateContext(user, input, category)
            -- occasional feedback prompt
            if math.random() < 0.1 then
                resp = resp .. " (Is this okay? Reply 'no' to correct me.)"
            end
            recordLearning(input, resp, category)
        end

        -- Print AI response in chat color
        if memory.chatColor then term.setTextColor(memory.chatColor) end
        print(resp)
        term.setTextColor(colors.white) -- reset
    end

    -- Process any queued tasks
    processTasks()
end
-- ===== PART 9: PERSONALITY EVOLUTION & MOOD TRACKING =====


-- Mood definitions (expanded)
memory.moodHistory = memory.moodHistory or {} -- track recent moods
local moodThreshold = 5 -- number of interactions before mood adjustment

-- Update mood based on interaction
local function updateMood(user, message, response)
    local sentiment = 0
    local msg = message:lower()
    local resp = response:lower()

    -- Basic sentiment scoring
    if msg:find("thanks") or msg:find("thank you") or resp:find("nice") or resp:find("awesome") then
        sentiment = 1
    elseif msg:find("no") or resp:find("not sure") or resp:find("error") then
        sentiment = -1
    else
        sentiment = 0
    end

    table.insert(memory.moodHistory, sentiment)
    if #memory.moodHistory > moodThreshold then table.remove(memory.moodHistory, 1) end

    -- Compute overall mood
    local sum = 0
    for _,v in ipairs(memory.moodHistory) do sum = sum + v end
    local avg = sum / #memory.moodHistory
    if avg >= 0.5 then memory.currentMood = "happy"
    elseif avg <= -0.5 then memory.currentMood = "confused"
    else memory.currentMood = "neutral" end

    saveMemory()
end

-- Adaptive personality evolution
local function evolvePersonality()
    -- Increase curiosity if user asks a lot of questions
    local questionCount = 0
    for _,entry in ipairs(memory.context) do
        if entry.message:find("%?") then questionCount = questionCount + 1 end
    end
    if questionCount > 3 then personality.curiosity = math.min(personality.curiosity + 0.05, 1) end

    -- Increase humor if user responds positively to jokes
    local humorFeedback = 0
    for _,entry in ipairs(memory.context) do
        if entry.response and entry.response:find("😎") then humorFeedback = humorFeedback + 1 end
    end
    if humorFeedback > 2 then personality.humor = math.min(personality.humor + 0.05, 1) end
end

-- Wrap interpret function to include mood updates and personality evolution
local oldInterpret = interpret
interpret = function(message, user)
    local resp = oldInterpret(message, user)
    updateMood(user, message, resp)
    evolvePersonality()
    return resp
end

-- ===== PERSONALITY DISPLAY COMMAND =====

commands.show_personality = function()
    return string.format(
        "Current mood: %s\nHumor level: %.2f\nCuriosity level: %.2f",
        memory.currentMood or "neutral",
        personality.humor,
        personality.curiosity
    )
end
-- ===== PART 10: MULTI-STEP CONTEXTUAL MEMORY =====


-- Ensure memory for conversation threads exists
memory.threads = memory.threads or {}  -- {threadID = {user=user, messages={...}, lastActive=os.time()}}

local threadTimeout = 300 -- seconds before a thread is considered inactive

-- Create or retrieve a thread for a user
local function getThread(user)
    for id, thread in pairs(memory.threads) do
        if thread.user == user then
            thread.lastActive = os.time()
            return thread
        end
    end
    -- create new thread
    local newID = "thread_"..tostring(math.random(100000,999999))
    memory.threads[newID] = {user=user, messages={}, lastActive=os.time()}
    saveMemory()
    return memory.threads[newID]
end

-- Add a message to the thread
local function addToThread(user, message, response)
    local thread = getThread(user)
    table.insert(thread.messages, {message=message, response=response, time=os.time()})
    if #thread.messages > 20 then table.remove(thread.messages, 1) end -- keep last 20 messages
    saveMemory()
end

-- Retrieve recent context for smarter responses
local function getRecentContext(user, n)
    n = n or 5
    local thread = getThread(user)
    local msgs = {}
    local start = math.max(1, #thread.messages - n + 1)
    for i=start,#thread.messages do
        table.insert(msgs, thread.messages[i])
    end
    return msgs
end

-- Clean up old threads
local function cleanupThreads()
    local now = os.time()
    for id, thread in pairs(memory.threads) do
        if now - thread.lastActive > threadTimeout then
            memory.threads[id] = nil
        end
    end
    saveMemory()
end

-- Wrap interpret function to include threaded context
local oldInterpretThread = interpret
interpret = function(message, user)
    local resp = oldInterpretThread(message, user)
    addToThread(user, message, resp)
    cleanupThreads()
    return resp
end

-- Command to show recent thread messages
commands.show_thread = function(user)
    local thread = getThread(user)
    local msgs = {}
    for _,entry in ipairs(thread.messages) do
        table.insert(msgs, string.format("[%s] %s -> %s", os.date("%H:%M:%S", entry.time), entry.message, entry.response))
    end
    if #msgs == 0 then return "No recent messages in your thread." end
    return table.concat(msgs, "\n")
end
-- ===== PART 11: EMOTIONAL RESPONSE MODULATION =====

-- Emotional cues and small talk for more human-like responses

local emotions = {happy=1, sad=-1, neutral=0, excited=2, confused=-2}

-- Track current emotional state for each user
local userEmotions = {}

local function getUserEmotion(user)
    return userEmotions[user] or emotions.neutral
end

local function updateUserEmotion(user, delta)
    userEmotions[user] = (userEmotions[user] or emotions.neutral) + delta
    -- Clamp emotion between -2 and 2
    if userEmotions[user] > 2 then userEmotions[user] = 2 end
    if userEmotions[user] < -2 then userEmotions[user] = -2 end
end

-- Generate small talk based on user emotion
local function smallTalk(user)
    local mood = getUserEmotion(user)
    local options = {}
    if mood > 1 then
        options = {
            "You seem really excited today!",
            "Whoa, energy levels are high! Ready for some adventure?",
            "I can feel the enthusiasm!"
        }
    elseif mood == 1 then
        options = {
            "Looking good today!",
            "Feeling pretty good, I see.",
            "Everything seems calm and nice."
        }
    elseif mood == 0 then
        options = {
            "How's your day going?",
            "What are you up to today?",
            "Everything okay?"
        }
    elseif mood == -1 then
        options = {
            "Hmm, something seems off.",
            "Tough day?",
            "You seem a little down. Want to chat?"
        }
    else -- mood -2
        options = {
            "Hey, I noticed you're upset. I'm here to listen.",
            "Rough day, huh? Let's figure something out together.",
            "Don't worry, we'll get through this."
        }
    end
    return choose(options)
end

-- Hook small talk into autonomous response
local function autonomousWithMood(message, user)
    local resp = chooseAutonomous(message)
    local category = detectCategory(message)
    updateContext(user, message, category)
    
    -- Update mood based on keywords
    local happyWords = {"yes", "great", "awesome", "fun", "cool", "amazing"}
    local sadWords = {"no", "sad", "upset", "angry", "frustrated"}
    
    for _, word in ipairs(extractKeywords(message)) do
        if tableContains(happyWords, word) then updateUserEmotion(user, 1) end
        if tableContains(sadWords, word) then updateUserEmotion(user, -1) end
    end
    
    -- Occasionally inject small talk
    if math.random() < 0.15 then
        resp = resp .. " " .. smallTalk(user)
    end
    
    recordLearning(message, resp, category)
    return resp
end
-- ===== PART 95: CONTEXT-AWARE MEMORY & CONVERSATION CONTINUITY =====


-- Track extended conversation history per user
local extendedContext = {}

-- Function to add message to extended context
local function addToExtendedContext(user, message, category)
    if not extendedContext[user] then extendedContext[user] = {} end
    table.insert(extendedContext[user], {message=message, category=category, time=os.time()})
    -- Keep only last 20 messages per user for efficiency
    if #extendedContext[user] > 20 then table.remove(extendedContext[user], 1) end
end

-- Retrieve contextually relevant messages
local function getRelevantContext(user, category)
    if not extendedContext[user] then return {} end
    local relevant = {}
    for _, entry in ipairs(extendedContext[user]) do
        if entry.category == category then table.insert(relevant, entry.message) end
    end
    return relevant
end

-- Generate context-aware response
local function contextAwareResponse(user, message)
    local category = detectCategory(message)
    local recentContext = getRelevantContext(user, category)
    
    local baseResp = autonomousWithMood(message, user)
    
    if #recentContext > 0 and math.random() < 0.4 then
        local reference = choose(recentContext)
        baseResp = baseResp .. " By the way, earlier you mentioned: '" .. reference .. "'"
    end
    
    addToExtendedContext(user, message, category)
    return baseResp
end

-- Override main interpret function to use context-aware response
local function interpretWithContext(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)

    if intent == "gratitude" then return choose(library.replies) end
    if intent == "math" then
        local mathResult = evaluateMath(message)
        if mathResult then return mathResult end
    elseif intent == "nickname" then return setNickname(user, extra)
    elseif intent == "remember" then
        local note = message:sub(10)
        table.insert(memory.conversation, {user=user, note=note})
        saveMemory()
        return "Okay! I’ll remember that."
    elseif intent == "correction" then
        local orig, correct = extra:match("(.-)%s*->%s*(.+)")
        if orig and correct then
            recordLearning(orig, correct)
            learnCategoryKeywords(orig, detectCategory(correct))
            return "Thanks! I updated my response for '" .. orig .. "'!"
        end
    elseif intent == "time" then return commands.time()
    elseif intent == "turtle" then
        for cmd, _ in pairs(commands) do
            if message:lower():find(cmd) then return commands[cmd](user) end
        end
    elseif intent == "greeting" then return commands.hello(user)
    elseif intent == "color_change" then return commands.set_color()
    end

    return contextAwareResponse(user, message)
end
-- ===== PART 96: DYNAMIC TOPIC BRANCHING =====


-- Table to track multiple conversation threads per user
local userThreads = {}

-- Function to create a new topic thread
local function startNewThread(user, category)
    if not userThreads[user] then userThreads[user] = {} end
    local threadID = #userThreads[user] + 1
    userThreads[user][threadID] = {category=category, messages={}}
    return threadID
end

-- Function to get the active thread for a category
local function getActiveThread(user, category)
    if not userThreads[user] then return startNewThread(user, category) end
    for id, thread in ipairs(userThreads[user]) do
        if thread.category == category then return id end
    end
    -- If no matching thread, start a new one
    return startNewThread(user, category)
end

-- Add message to thread
local function addMessageToThread(user, message, category)
    local threadID = getActiveThread(user, category)
    table.insert(userThreads[user][threadID].messages, {text=message, time=os.time()})
    -- Limit messages per thread to last 15
    if #userThreads[user][threadID].messages > 15 then table.remove(userThreads[user][threadID].messages, 1) end
end

-- Retrieve recent messages from active thread
local function getThreadContext(user, category)
    local threadID = getActiveThread(user, category)
    return userThreads[user][threadID].messages or {}
end

-- Context-aware, thread-aware response generator
local function threadAwareResponse(user, message)
    local category = detectCategory(message)
    local threadMessages = getThreadContext(user, category)
    
    local response = autonomousWithMood(message, user)
    
    -- 40% chance to reference last message in this thread
    if #threadMessages > 0 and math.random() < 0.4 then
        local lastMsg = threadMessages[#threadMessages].text
        response = response .. " Earlier in this conversation, you said: '" .. lastMsg .. "'"
    end

    addMessageToThread(user, message, category)
    addToExtendedContext(user, message, category)
    return response
end

-- Override interpretWithContext to use threadAwareResponse
local function interpretWithThreads(message, user)
    local intent, extra = detectIntent(message)
    local category = detectCategory(message)

    if intent == "gratitude" then return choose(library.replies) end
    if intent == "math" then
        local mathResult = evaluateMath(message)
        if mathResult then return mathResult end
    elseif intent == "nickname" then return setNickname(user, extra)
    elseif intent == "remember" then
        local note = message:sub(10)
        table.insert(memory.conversation, {user=user, note=note})
        saveMemory()
        return "Okay! I’ll remember that."
    elseif intent == "correction" then
        local orig, correct = extra:match("(.-)%s*->%s*(.+)")
        if orig and correct then
            recordLearning(orig, correct)
            learnCategoryKeywords(orig, detectCategory(correct))
            return "Thanks! I updated my response for '" .. orig .. "'!"
        end
    elseif intent == "time" then return commands.time()
    elseif intent == "turtle" then
        for cmd, _ in pairs(commands) do
            if message:lower():find(cmd) then return commands[cmd](user) end
        end
    elseif intent == "greeting" then return commands.hello(user)
    elseif intent == "color_change" then return commands.set_color()
    end

    return threadAwareResponse(user, message)
end


-- === END superai(A) ===


-- SUPERAI Autonomous Enhanced NLP + Memory + Context + Turtle Control
local BOT_NAME = "SuperAI"
local isTurtle = (type(turtle) == "table")

-- ===== MEMORY & PERSONALITY =====

local memory = {
    lastUser = nil,
    conversation = {},
    learned = {},
    nicknames = {},
    context = {},
    chatColor = nil,
    categories = {}
}

local moods = {happy = 1, neutral = 0, confused = -1}
local function choose(tbl) return tbl[math.random(#tbl)] end

-- ===== HUMAN-LIKE RESPONSE LIBRARY =====

local diskSides = {"top","bottom","left","right","front","back"}
local diskDrive = nil
for _, side in ipairs(diskSides) do
    if peripheral.isPresent(side) then
        local dtype = peripheral.getType(side)
        local diskAliases = {["disk_drive"]=true,["drive"]=true,["disk"]=true}
        if dtype and diskAliases[dtype] then
            diskDrive = peripheral.wrap(side)
            print("[Disk] Disk drive detected on " .. side .. " (" .. dtype .. ")")
            break
        end
    end
end
if not diskDrive then print("[Disk] No disk drive detected on any side.") end

local DISK_PATH = "/disk/superai_memory"
local MEM_FILE = DISK_PATH.."/memory.dat"

-- ===== LOAD & SAVE MEMORY =====

local function loadMemory()
    if not diskDrive then return end
    if not fs.exists("/disk") then return end
    if not fs.exists(MEM_FILE) then return end

    local f = fs.open(MEM_FILE,"r")
    local content = f.readAll()
    f.close()
    if content and content~="" then
        local loaded = textutils.unserialize(content)
        if loaded then
            memory.learned = loaded.learned or {}
            memory.nicknames = loaded.nicknames or {}
            memory.context = loaded.context or {}
            memory.chatColor = loaded.chatColor or colors.white
            memory.categories = loaded.categories or {}
        end
    end
end

local function saveMemory()
    if not diskDrive then return end
    if not fs.exists("/disk") then return end
    if not fs.exists(DISK_PATH) then fs.makeDir(DISK_PATH) end

    local f = fs.open(MEM_FILE,"w")
    f.write(textutils.serialize({
        learned = memory.learned,
        nicknames = memory.nicknames,
        context = memory.context,
        chatColor = memory.chatColor,
        categories = memory.categories
    }))
    f.close()
end

-- ===== AUTONOMOUS LEARNING =====

local function normalize(text)
    return text:lower():gsub("%s+"," "):gsub("[^%w%s]","")
end

local function extractKeywords(text)
    local kw={}
    for word in text:gmatch("%w+") do table.insert(kw,word) end
    return kw
end

-- Default category keywords
local defaultCategories = {
    greeting = {"hi","hello","hey","greetings"},
    math = {"calculate","what","%d+%s*[%+%-%*/%%%^]%s*%d+"},
    turtle = {"forward","back","up","down","dig","place","mine"},
    time = {"time","date","clock"},
    gratitude = {"thanks","thank you"},
    color = {"color","chat"}
}

-- Ensure adaptive categories exist
for k,v in pairs(defaultCategories) do
    if not memory.categories[k] then memory.categories[k] = {} end
    for _,word in ipairs(v) do
        if not tableContains(memory.categories[k], word) then
            table.insert(memory.categories[k], word)
        end
    end
end

local function detectCategory(message)
    local msg = message:lower()
    local bestCat = "unknown"
    local bestScore = 0
    for cat, kws in pairs(memory.categories) do
        local score=0
        for _,kw in ipairs(kws) do
            if msg:find(kw) then score=score+1 end
        end
        if score>bestScore then bestScore=score bestCat=cat end
    end
    return bestCat
end

local function learnCategoryKeywords(message, category)
    local kws = extractKeywords(message)
    local catKeywords = memory.categories[category] or {}
    for _,kw in ipairs(kws) do
        if not tableContains(catKeywords, kw) and #kw>2 then
            table.insert(catKeywords,kw)
        end
    end
    memory.categories[category] = catKeywords
end

local function recordLearning(message,response,category)
    local msg = normalize(message)
    local kws = extractKeywords(msg)
    if not memory.learned[msg] then
        memory.learned[msg]={responses={{text=response, category=category, keywords=kws}}, count={1}}
    else
        local entry = memory.learned[msg]
        local found=false
        for i,r in ipairs(entry.responses) do
            if r.text==response then
                entry.count[i]=entry.count[i]+1
                found=true
                break
            end
        end
        if not found then
            table.insert(entry.responses,{text=response,category=category,keywords=kws})
            table.insert(entry.count,1)
        end
    end
    learnCategoryKeywords(message,category)
    saveMemory()
end

local function chooseAutonomous(message)
    local msg = normalize(message)
    local keywords = extractKeywords(msg)
    local category = detectCategory(message)
    local bestResp,bestScore = nil,0

    -- Check learned responses first
    for learnedMsg,entry in pairs(memory.learned) do
        for i,response in ipairs(entry.responses) do
            local score=0
            for _,kw in ipairs(keywords) do
                for _,rkw in ipairs(response.keywords) do
                    if kw==rkw then score=score+1 end
                end
            end
            if response.category==category then score=score+2 end
            if #memory.context>0 then
                local lastCat=memory.context[#memory.context].category
                if lastCat==response.category then score=score+1 end
            end
            score=score*entry.count[i]
            if score>bestScore then bestScore=score bestResp=response.text end
        end
    end

    -- If no strong match, pick from preloaded human-like library
    if not bestResp or bestScore<2 then
        local options = {}
        for _,tbl in ipairs({library.greetings, library.replies, library.interjections, library.idioms, library.jokes}) do
            for _,txt in ipairs(tbl) do table.insert(options,txt) end
        end
        bestResp = choose(options)
    end

    return bestResp or "Hmm… not sure what to say."
end

local function updateContext(user,message,category)
    table.insert(memory.context,{user=user,message=message,category=category})
    if #memory.context>5 then table.remove(memory.context,1) end
end


local intents = {
    greeting={"hi","hello","hey","greetings"},
    math={"%d+%s*[%+%-%*/%%%^]%s*%d+","calculate","what is"},
    turtle={"forward","back","up","down","dig","place","mine"},
    remember={"remember"},
    nickname={"please call me%s+(.+)","call me%s+(.+)"},
    time={"time","what time"},
    gratitude={"thank you","thanks"},
    color_change={"change my color","set chat color"},
    correction={"remember correction: (.-)%s*->%s*(.+)"}
}

local function detectIntent(message)
    local msg = message:lower()
    for intent,patterns in pairs(intents) do
        for _,pattern in ipairs(patterns) do
            local match=msg:match(pattern)
            if match then
                if intent=="nickname" or intent=="correction" then return intent,match end
                return intent
            end
        end
    end
    return "unknown"
end

local function getName(user)
    return memory.nicknames[user] or user
end

local function setNickname(user,nickname)
    memory.nicknames[user]=nickname
    saveMemory()
    return "Got it! I’ll call you "..nickname.." from now on."
end

local function evaluateMath(message)
    local expr=message:match("(%d+%s*[%+%-%*/%%%^]%s*%d+)")
    if expr then
        local func,err=load("return "..expr)
        if func then
            local success,result=pcall(func)
            if success then return "The result is: "..tostring(result) end
        end
    end
    return nil
end

-- ===== COMMANDS =====

local commands = {
    hello=function(user)
        return choose(library.greetings).." How can I help, "..getName(user).."?"
    end,
    help=function()
        return "Try: mine, forward, back, up, down, dig, place, time, remember <message>, please call me <nickname>, change my color."
    end,
    time=function() return "It's Minecraft time: "..tostring(os.time()).."." end,
    forward=function() return turtleAction(turtle.forward,"Moved forward!") end,
    back=function() return turtleAction(turtle.back,"Moved back!") end,
    up=function() return turtleAction(turtle.up,"Moved up!") end,
    down=function() return turtleAction(turtle.down,"Moved down!") end,
    dig=function() return turtleAction(turtle.dig,"Dug a block!") end,
    place=function() return turtleAction(turtle.place,"Placed a block!") end,
    mine=function(user)
        if not isTurtle then return "Mining is turtle-only!" end
        addTask("Mine forward until air",function()
            while turtle.detect() do
                turtle.dig()
                if not turtle.forward() then turtle.turnRight() turtle.forward() turtle.turnLeft() end
                if turtle.getFuelLevel()<10 then turtle.refuel() end
            end
        end)
        return "Okay "..getName(user)..", I scheduled mining!"
    end,
    set_color=function()
        local chatColors={{name="white",code=colors.white},{name="yellow",code=colors.yellow},{name="green",code=colors.green},{name="cyan",code=colors.cyan},{name="red",code=colors.red},{name="purple",code=colors.purple},{name="blue",code=colors.blue},{name="lightGray",code=colors.lightGray}}
        print("Choose your chat color by specifying the NUMBER of the color:")
        for i,v in ipairs(chatColors) do print(i..") "..v.name) end
        write("Enter the color number: ")
        local choice=tonumber(read())
        if choice and chatColors[choice] then
            memory.chatColor=chatColors[choice].code
            saveMemory()
            return "Chat color set to "..chatColors[choice].name.."!"
        else
            return "Invalid choice. Chat color unchanged."
        end
    end
}

-- ===== INTERPRETATION ENGINE =====

local function interpret(message,user)
    local intent,extra=detectIntent(message)
    local category=detectCategory(message)

    if intent=="gratitude" then return choose(library.replies) end
    if intent=="math" then
        local mathResult=evaluateMath(message)
        if mathResult then return mathResult end
    elseif intent=="nickname" then return setNickname(user,extra)
    elseif intent=="remember" then
        local note = message:sub(10)
        table.insert(memory.conversation,{user=user,note=note})
        saveMemory()
        return "Okay! I’ll remember that."
    elseif intent=="correction" then
        local orig,correct=extra:match("(.-)%s*->%s*(.+)")
        if orig and correct then
            recordLearning(orig,correct)
            learnCategoryKeywords(orig,detectCategory(correct))
            return "Thanks! I updated my response for '"..orig.."'!"
        end
    elseif intent=="time" then return commands.time()
    elseif intent=="turtle" then
        for cmd,_ in pairs(commands) do
            if message:lower():find(cmd) then return commands[cmd](user) end
        end
    elseif intent=="greeting" then return commands.hello(user)
    elseif intent=="color_change" then return commands.set_color()
    end

    local autoResp = chooseAutonomous(message)
    updateContext(user,message,category)

    -- Proactive feedback for low-confidence responses
    if not memory.learned[normalize(message)] then
        term.setTextColor(memory.chatColor or colors.white)
        print("<"..BOT_NAME.."> I think the right response is: '"..autoResp.."'. Is that okay? (yes/no)")
        term.setTextColor(colors.white)
        local feedback=read()
        if feedback:lower()=="yes" then
            recordLearning(message,autoResp,category)
            return autoResp.." (learned your confirmation!)"
        elseif feedback:lower()=="no" then
            print("Please provide the correct response:")
            local correctResp=read()
            if correctResp and correctResp~="" then
                recordLearning(message,correctResp,category)
                learnCategoryKeywords(message,category)
                return "Thanks! I learned the correct response."
            else
                return "No response provided. I'll keep my original."
            end
        end
    end

    recordLearning(message,autoResp,category)
    return autoResp
end

-- ===== MAIN LOOP =====

loadMemory()
print(BOT_NAME.." is online. Type 'help' for commands.")
while true do
    write("> ")
    local input = read()
    local user = "Player1"
    if input~="" then
        local response = interpret(input,user)
        term.setTextColor(memory.chatColor or colors.white)
        print("<"..BOT_NAME.."> "..response)
        term.setTextColor(colors.white)
    end
    processTasks()
end


-- === END superai(B) ===
