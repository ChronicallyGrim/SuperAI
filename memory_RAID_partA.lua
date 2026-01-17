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
    if #memory.moodHistory > 1000 then table.remove(memory.moodHistory, 1) end
end

-- ===== CONTEXT TRACKING =====

local function rememberContext(user, message, category)
    table.insert(memory.context, {user=user, message=message, category=category, mood=memory.mood})
    if #memory.context > 10000 then table.remove(memory.context, 1) end
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
local MAX_CONTEXT = 10000000
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
local MAX_CONTEXT = 10000
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
local MAX_LEARNED = 100000
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

local CONTEXT_LIMIT = 10000 -- number of messages to remember

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
    local MAX_CONTEXT_EVENTS = 10000
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
local MAX_CONTEXT_LENGTH = 10000 -- store last 20 interactions for richer context

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
local MAX_CONTEXT = 10000

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
local CONTEXT_LIMIT = 10000

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

-- ============================================================================
-- INTEGRATED DATABASE SYSTEM
-- ============================================================================

-- Database storage within memory
memory.databases = {}
memory.currentDB = nil

-- Create a new database
function createDatabase(name)
    if memory.databases[name] then
        return false, "Database already exists"
    end
    
    memory.databases[name] = {
        tables = {},
        indices = {},
        metadata = {
            created = os.time(),
            modified = os.time(),
        }
    }
    
    memory.currentDB = name
    return true, "Database created: " .. name
end

-- Use a database
function useDatabase(name)
    if not memory.databases[name] then
        return false, "Database does not exist"
    end
    memory.currentDB = name
    return true, "Using database: " .. name
end

-- Create a table
function createTable(tableName, schema)
    if not memory.currentDB then
        return false, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    if db.tables[tableName] then
        return false, "Table already exists"
    end
    
    db.tables[tableName] = {
        schema = schema,
        rows = {},
        autoIncrement = 1,
    }
    
    return true, "Table created: " .. tableName
end

-- Insert data
function insertData(tableName, data)
    if not memory.currentDB then
        return false, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local tbl = db.tables[tableName]
    
    if not tbl then
        return false, "Table does not exist"
    end
    
    if not data.id then
        data.id = tbl.autoIncrement
        tbl.autoIncrement = tbl.autoIncrement + 1
    end
    
    table.insert(tbl.rows, data)
    return true, "Inserted with ID: " .. data.id
end

-- Select data
function selectData(tableName, conditions)
    if not memory.currentDB then
        return nil, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local tbl = db.tables[tableName]
    
    if not tbl then
        return nil, "Table does not exist"
    end
    
    local results = {}
    
    for _, row in ipairs(tbl.rows) do
        local match = true
        if conditions then
            for field, value in pairs(conditions) do
                if row[field] ~= value then
                    match = false
                    break
                end
            end
        end
        if match then
            table.insert(results, row)
        end
    end
    
    return results, "Found " .. #results .. " rows"
end

-- Update data
function updateData(tableName, conditions, updates)
    if not memory.currentDB then
        return false, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local tbl = db.tables[tableName]
    
    if not tbl then
        return false, "Table does not exist"
    end
    
    local count = 0
    for _, row in ipairs(tbl.rows) do
        local match = true
        if conditions then
            for field, value in pairs(conditions) do
                if row[field] ~= value then
                    match = false
                    break
                end
            end
        end
        if match then
            for field, value in pairs(updates) do
                row[field] = value
            end
            count = count + 1
        end
    end
    
    return true, "Updated " .. count .. " rows"
end

-- Delete data
function deleteData(tableName, conditions)
    if not memory.currentDB then
        return false, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local tbl = db.tables[tableName]
    
    if not tbl then
        return false, "Table does not exist"
    end
    
    local count = 0
    local i = 1
    while i <= #tbl.rows do
        local row = tbl.rows[i]
        local match = true
        if conditions then
            for field, value in pairs(conditions) do
                if row[field] ~= value then
                    match = false
                    break
                end
            end
        end
        if match then
            table.remove(tbl.rows, i)
            count = count + 1
        else
            i = i + 1
        end
    end
    
    return true, "Deleted " .. count .. " rows"
end

-- List all databases
function listDatabases()
    local names = {}
    for name, _ in pairs(memory.databases) do
        table.insert(names, name)
    end
    return names
end

-- List tables in current database
function listTables()
    if not memory.currentDB then
        return nil, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local names = {}
    for name, _ in pairs(db.tables) do
        table.insert(names, name)
    end
    return names
end

-- Get table row count
function getTableStats(tableName)
    if not memory.currentDB then
        return nil, "No database selected"
    end
    
    local db = memory.databases[memory.currentDB]
    local tbl = db.tables[tableName]
    
    if not tbl then
        return nil, "Table does not exist"
    end
    
    return {
        rowCount = #tbl.rows,
        schema = tbl.schema,
    }
end
