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
