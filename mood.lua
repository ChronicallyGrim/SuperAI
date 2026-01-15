-- Module: mood.lua
-- Advanced emotional intelligence with multi-dimensional affect analysis

local M = {}

-- ============================================================================
-- EMOTION TAXONOMY - Based on Plutchik's wheel of emotions
-- ============================================================================

local emotionDatabase = {
    -- Primary emotions
    joy = {
        words = {"happy", "joyful", "cheerful", "delighted", "pleased", "glad", "content", 
                "ecstatic", "elated", "thrilled", "overjoyed", "blissful", "gleeful"},
        expressions = {"haha", "lol", "lmao", "rofl", "yay", "woohoo", "yess", ":)", "😊", "😄", "😃"},
        intensity = 0.8,
        valence = 1.0,
        arousal = 0.6,
        category = "positive"
    },
    
    sadness = {
        words = {"sad", "unhappy", "depressed", "down", "miserable", "gloomy", "melancholy",
                "sorrowful", "dejected", "despondent", "heartbroken", "grief", "mourning"},
        expressions = {":(", ":'(", "😢", "😭", "😞", "sigh"},
        intensity = 0.7,
        valence = -0.8,
        arousal = -0.4,
        category = "negative"
    },
    
    anger = {
        words = {"angry", "mad", "furious", "enraged", "livid", "irate", "outraged",
                "irritated", "annoyed", "frustrated", "aggravated", "infuriated", "hate"},
        expressions = {"ugh", "grr", "argh", "damn", "dammit", ">:(", "😠", "😡", "💢"},
        intensity = 0.9,
        valence = -0.9,
        arousal = 0.8,
        category = "negative"
    },
    
    fear = {
        words = {"scared", "afraid", "frightened", "terrified", "anxious", "worried",
                "nervous", "panicked", "alarmed", "uneasy", "apprehensive", "concerned"},
        expressions = {"oh no", "yikes", "eek", "omg", "😱", "😨", "😰"},
        intensity = 0.8,
        valence = -0.7,
        arousal = 0.7,
        category = "negative"
    },
    
    surprise = {
        words = {"surprised", "shocked", "astonished", "amazed", "stunned", "startled",
                "astounded", "flabbergasted", "bewildered"},
        expressions = {"wow", "whoa", "omg", "oh my", "no way", "really", "😲", "😮", "🤯"},
        intensity = 0.6,
        valence = 0.0,
        arousal = 0.8,
        category = "neutral"
    },
    
    disgust = {
        words = {"disgusting", "gross", "revolting", "repulsive", "nasty", "vile",
                "nauseating", "sickening"},
        expressions = {"ew", "eww", "yuck", "bleh", "🤢", "🤮"},
        intensity = 0.7,
        valence = -0.8,
        arousal = 0.5,
        category = "negative"
    },
    
    anticipation = {
        words = {"excited", "eager", "looking forward", "can't wait", "anticipating",
                "expecting", "hoping", "awaiting"},
        expressions = {"yes!", "finally", "yay", "🎉", "🙌"},
        intensity = 0.6,
        valence = 0.5,
        arousal = 0.6,
        category = "positive"
    },
    
    trust = {
        words = {"trust", "believe", "faith", "confident", "sure", "certain",
                "reliable", "dependable"},
        expressions = {},
        intensity = 0.5,
        valence = 0.6,
        arousal = 0.2,
        category = "positive"
    },
    
    -- Secondary/complex emotions
    love = {
        words = {"love", "adore", "cherish", "affection", "caring", "devoted",
                "fondness", "attachment"},
        expressions = {"<3", "❤️", "💕", "😍", "🥰"},
        intensity = 0.9,
        valence = 1.0,
        arousal = 0.5,
        category = "positive"
    },
    
    guilt = {
        words = {"guilty", "ashamed", "remorseful", "regret", "sorry"},
        expressions = {"sorry", "my bad", "oops"},
        intensity = 0.6,
        valence = -0.6,
        arousal = -0.3,
        category = "negative"
    },
    
    shame = {
        words = {"embarrassed", "humiliated", "mortified", "ashamed", "disgraced"},
        expressions = {"ugh", "😳", "🙈"},
        intensity = 0.7,
        valence = -0.7,
        arousal = -0.2,
        category = "negative"
    },
    
    pride = {
        words = {"proud", "accomplished", "satisfied", "fulfilled", "triumphant"},
        expressions = {"yes!", "nailed it", "💪", "🏆"},
        intensity = 0.7,
        valence = 0.8,
        arousal = 0.4,
        category = "positive"
    },
    
    gratitude = {
        words = {"thankful", "grateful", "appreciative", "thanks", "thank you"},
        expressions = {"thanks", "thx", "ty", "thank you", "🙏"},
        intensity = 0.6,
        valence = 0.7,
        arousal = 0.3,
        category = "positive"
    },
    
    confusion = {
        words = {"confused", "puzzled", "perplexed", "baffled", "bewildered",
                "unclear", "lost", "uncertain"},
        expressions = {"huh", "what", "?", "idk", "dunno", "🤔", "😕"},
        intensity = 0.4,
        valence = -0.3,
        arousal = 0.2,
        category = "neutral"
    },
    
    boredom = {
        words = {"bored", "boring", "dull", "tedious", "monotonous", "uninteresting"},
        expressions = {"meh", "ugh", "😑", "😐"},
        intensity = 0.4,
        valence = -0.4,
        arousal = -0.6,
        category = "negative"
    },
    
    loneliness = {
        words = {"lonely", "alone", "isolated", "solitary", "abandoned"},
        expressions = {},
        intensity = 0.7,
        valence = -0.7,
        arousal = -0.5,
        category = "negative"
    },
    
    hope = {
        words = {"hopeful", "optimistic", "positive", "encouraged", "promising"},
        expressions = {"fingers crossed", "🤞"},
        intensity = 0.6,
        valence = 0.6,
        arousal = 0.3,
        category = "positive"
    },
    
    disappointment = {
        words = {"disappointed", "let down", "discouraged", "dismayed", "disheartened"},
        expressions = {"aw", "darn", "😞", "😔"},
        intensity = 0.6,
        valence = -0.6,
        arousal = -0.4,
        category = "negative"
    },
    
    relief = {
        words = {"relieved", "reassured", "comforted", "calmed"},
        expressions = {"phew", "thank god", "finally", "😌"},
        intensity = 0.5,
        valence = 0.5,
        arousal = -0.3,
        category = "positive"
    }
}

-- ============================================================================
-- EMOTIONAL STATE TRACKING
-- ============================================================================

-- User emotional profiles
local userProfiles = {}
local HISTORY_LIMIT = 20
local ANALYSIS_WINDOW = 5

-- Initialize user emotional profile
local function initUserProfile(user)
    if not userProfiles[user] then
        userProfiles[user] = {
            history = {},
            dominantEmotion = "neutral",
            emotionalBaseline = {valence = 0, arousal = 0},
            emotionalVolatility = 0,
            lastUpdate = os.time()
        }
    end
    return userProfiles[user]
end

-- ============================================================================
-- MULTI-DIMENSIONAL EMOTION DETECTION
-- ============================================================================

-- Detect all emotions in text with confidence scores
function M.detectEmotions(message)
    if not message then return {} end
    
    local text = message:lower()
    local detectedEmotions = {}
    
    for emotionName, emotionData in pairs(emotionDatabase) do
        local score = 0
        local matches = {}
        
        -- Check words
        for _, word in ipairs(emotionData.words) do
            if text:find(word, 1, true) then
                score = score + 1
                table.insert(matches, word)
            end
        end
        
        -- Check expressions
        for _, expr in ipairs(emotionData.expressions) do
            if text:find(expr, 1, true) then
                score = score + 1.5  -- Expressions weighted higher
                table.insert(matches, expr)
            end
        end
        
        if score > 0 then
            detectedEmotions[emotionName] = {
                score = score,
                confidence = math.min(score / 3, 1.0),  -- Normalize confidence
                intensity = emotionData.intensity,
                valence = emotionData.valence,
                arousal = emotionData.arousal,
                category = emotionData.category,
                matches = matches
            }
        end
    end
    
    return detectedEmotions
end

-- Get emotional dimensions (valence and arousal)
function M.getEmotionalDimensions(message)
    local emotions = M.detectEmotions(message)
    
    local totalValence = 0
    local totalArousal = 0
    local totalWeight = 0
    
    for _, data in pairs(emotions) do
        local weight = data.score * data.intensity
        totalValence = totalValence + (data.valence * weight)
        totalArousal = totalArousal + (data.arousal * weight)
        totalWeight = totalWeight + weight
    end
    
    if totalWeight == 0 then
        return {valence = 0, arousal = 0}
    end
    
    return {
        valence = totalValence / totalWeight,
        arousal = totalArousal / totalWeight
    }
end

-- Calculate overall sentiment with nuance
function M.detectSentiment(message)
    if not message then return "neutral", 0, {} end
    
    local emotions = M.detectEmotions(message)
    local dimensions = M.getEmotionalDimensions(message)
    
    -- Calculate sentiment category
    local sentiment
    if dimensions.valence > 0.3 then
        sentiment = "positive"
    elseif dimensions.valence < -0.3 then
        sentiment = "negative"
    else
        sentiment = "neutral"
    end
    
    -- Calculate sentiment strength
    local strength = math.abs(dimensions.valence)
    
    return sentiment, strength, emotions
end

-- Get dominant emotion with confidence
function M.getDominantEmotion(message)
    local emotions = M.detectEmotions(message)
    
    local dominantEmotion = nil
    local maxConfidence = 0
    
    for emotionName, data in pairs(emotions) do
        if data.confidence > maxConfidence then
            maxConfidence = data.confidence
            dominantEmotion = emotionName
        end
    end
    
    return dominantEmotion, maxConfidence
end

-- Detect emotion blend (multiple emotions present)
function M.getEmotionBlend(message)
    local emotions = M.detectEmotions(message)
    local blend = {}
    
    for emotionName, data in pairs(emotions) do
        if data.confidence > 0.3 then  -- Only significant emotions
            table.insert(blend, {
                emotion = emotionName,
                confidence = data.confidence,
                category = data.category
            })
        end
    end
    
    -- Sort by confidence
    table.sort(blend, function(a, b) return a.confidence > b.confidence end)
    
    return blend
end

-- ============================================================================
-- EMOTIONAL PROFILE MANAGEMENT
-- ============================================================================

-- Update user's emotional history
function M.update(user, message)
    if not user or not message then return end
    
    local profile = initUserProfile(user)
    local sentiment, strength, emotions = M.detectSentiment(message)
    local dominant, confidence = M.getDominantEmotion(message)
    local dimensions = M.getEmotionalDimensions(message)
    
    -- Add to history
    table.insert(profile.history, {
        sentiment = sentiment,
        strength = strength,
        emotion = dominant,
        confidence = confidence,
        valence = dimensions.valence,
        arousal = dimensions.arousal,
        emotions = emotions,
        timestamp = os.time(),
        messageLength = #message
    })
    
    -- Trim history
    while #profile.history > HISTORY_LIMIT do
        table.remove(profile.history, 1)
    end
    
    -- Update dominant emotion
    profile.dominantEmotion = dominant or "neutral"
    profile.lastUpdate = os.time()
    
    -- Calculate emotional baseline
    M.updateEmotionalBaseline(user)
    
    -- Calculate volatility
    M.calculateVolatility(user)
    
    return sentiment
end

-- Calculate user's emotional baseline
function M.updateEmotionalBaseline(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then return end
    
    local totalValence = 0
    local totalArousal = 0
    local count = 0
    
    -- Use recent history for baseline
    local windowStart = math.max(1, #profile.history - ANALYSIS_WINDOW + 1)
    
    for i = windowStart, #profile.history do
        local entry = profile.history[i]
        totalValence = totalValence + entry.valence
        totalArousal = totalArousal + entry.arousal
        count = count + 1
    end
    
    if count > 0 then
        profile.emotionalBaseline = {
            valence = totalValence / count,
            arousal = totalArousal / count
        }
    end
end

-- Calculate emotional volatility (how much mood fluctuates)
function M.calculateVolatility(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        profile.emotionalVolatility = 0
        return
    end
    
    local changes = {}
    
    for i = 2, #profile.history do
        local prev = profile.history[i - 1]
        local curr = profile.history[i]
        
        local valenceDelta = math.abs(curr.valence - prev.valence)
        local arousalDelta = math.abs(curr.arousal - prev.arousal)
        
        table.insert(changes, (valenceDelta + arousalDelta) / 2)
    end
    
    local totalChange = 0
    for _, change in ipairs(changes) do
        totalChange = totalChange + change
    end
    
    profile.emotionalVolatility = totalChange / #changes
end

-- ============================================================================
-- EMOTIONAL STATE QUERIES
-- ============================================================================

-- Get current emotional state
function M.get(user)
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return "neutral"
    end
    
    return profile.history[#profile.history].sentiment
end

-- Get emotional trend (improving, declining, stable, volatile)
function M.getTrend(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        return "stable"
    end
    
    -- High volatility indicates unstable mood
    if profile.emotionalVolatility > 0.5 then
        return "volatile"
    end
    
    -- Calculate trend from recent history
    local windowStart = math.max(1, #profile.history - ANALYSIS_WINDOW + 1)
    local valenceTrend = 0
    
    for i = windowStart + 1, #profile.history do
        local prev = profile.history[i - 1]
        local curr = profile.history[i]
        valenceTrend = valenceTrend + (curr.valence - prev.valence)
    end
    
    valenceTrend = valenceTrend / (#profile.history - windowStart)
    
    if valenceTrend > 0.15 then return "improving" end
    if valenceTrend < -0.15 then return "declining" end
    return "stable"
end

-- Get emotional consistency
function M.getConsistency(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        return "unknown"
    end
    
    if profile.emotionalVolatility < 0.2 then return "very_consistent" end
    if profile.emotionalVolatility < 0.4 then return "consistent" end
    if profile.emotionalVolatility < 0.6 then return "somewhat_variable" end
    return "highly_variable"
end

-- Detect emotional crisis
function M.isInCrisis(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 2 then
        return false
    end
    
    local recent = profile.history[#profile.history]
    
    -- Crisis indicators
    local strongNegative = (recent.valence < -0.7 and recent.strength > 0.6)
    local highVolatility = (profile.emotionalVolatility > 0.7)
    local negativeStreak = true
    
    -- Check for negative streak
    for i = math.max(1, #profile.history - 2), #profile.history do
        if profile.history[i].sentiment ~= "negative" then
            negativeStreak = false
            break
        end
    end
    
    return strongNegative or (highVolatility and negativeStreak)
end

-- Get emotional needs based on state
function M.getEmotionalNeeds(user)
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return {"neutral_engagement"}
    end
    
    local recent = profile.history[#profile.history]
    local trend = M.getTrend(user)
    local needs = {}
    
    -- Determine needs based on emotional state
    if M.isInCrisis(user) then
        table.insert(needs, "immediate_support")
        table.insert(needs, "validation")
        table.insert(needs, "empathy")
    elseif recent.sentiment == "negative" then
        if trend == "declining" then
            table.insert(needs, "emotional_support")
            table.insert(needs, "active_listening")
        else
            table.insert(needs, "gentle_encouragement")
        end
        table.insert(needs, "empathy")
    elseif recent.sentiment == "positive" then
        table.insert(needs, "celebration")
        table.insert(needs, "positive_reinforcement")
    else
        table.insert(needs, "neutral_engagement")
    end
    
    -- Address volatility
    if profile.emotionalVolatility > 0.6 then
        table.insert(needs, "stability")
        table.insert(needs, "grounding")
    end
    
    return needs
end

-- ============================================================================
-- RESPONSE ADJUSTMENT
-- ============================================================================

-- Generate emotionally appropriate response modifier
function M.adjustResponse(user, response)
    if not response then return "" end
    
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return response
    end
    
    local needs = M.getEmotionalNeeds(user)
    local trend = M.getTrend(user)
    
    -- Handle crisis situation
    if M.tableContains(needs, "immediate_support") then
        local support = {
            " I'm here for you.",
            " You're not alone in this.",
            " I'm listening."
        }
        response = response .. support[math.random(#support)]
    end
    
    -- Handle declining mood
    if trend == "declining" then
        local encouraging = {
            " Things can get better.",
            " I believe in you.",
            " This is temporary."
        }
        if math.random() < 0.4 then
            response = response .. encouraging[math.random(#encouraging)]
        end
    end
    
    -- Handle positive mood
    if M.tableContains(needs, "celebration") then
        if math.random() < 0.3 then
            response = response .. " 🎉"
        end
    end
    
    return response
end

-- Generate empathetic response
function M.generateEmpatheticResponse(message)
    local emotion, confidence = M.getDominantEmotion(message)
    
    if not emotion or confidence < 0.3 then return nil end
    
    local empathyResponses = {
        sadness = {
            "I'm sorry you're feeling this way.",
            "That sounds really difficult.",
            "I wish I could help make this better.",
            "It's okay to feel sad sometimes."
        },
        anger = {
            "I can hear that you're frustrated.",
            "That does sound really annoying.",
            "I understand why you'd be upset.",
            "Your anger is valid."
        },
        fear = {
            "That sounds really stressful.",
            "It's natural to feel anxious about that.",
            "I can see why you'd be worried.",
            "Your feelings are completely understandable."
        },
        joy = {
            "I'm so glad to hear that!",
            "That's wonderful!",
            "You seem really happy about this!",
            "That's fantastic news!"
        },
        gratitude = {
            "You're very welcome!",
            "I'm happy to help!",
            "Anytime!",
            "It's my pleasure!"
        },
        confusion = {
            "Let me try to explain that better.",
            "I can see how that would be confusing.",
            "What part would you like me to clarify?",
            "Let's break this down together."
        },
        disappointment = {
            "I'm sorry that didn't work out.",
            "That must be disappointing.",
            "I understand how let down you must feel.",
            "It's okay to be disappointed."
        },
        loneliness = {
            "You're not alone - I'm here.",
            "I'm here to talk whenever you need.",
            "I hear you.",
            "Thank you for sharing that with me."
        }
    }
    
    local responseList = empathyResponses[emotion]
    if responseList and #responseList > 0 then
        return responseList[math.random(#responseList)]
    end
    
    return nil
end

-- Helper function
function M.tableContains(tbl, value)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

return M
