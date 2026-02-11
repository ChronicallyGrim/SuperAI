-- Module: mood.lua
-- Massively expanded emotional intelligence system with 40+ emotions, emotion prediction,
-- regulation strategies, mixed emotions, emotional contagion, and cultural differences
--
-- Features:
-- - 40+ emotions with micro-emotions
-- - Emotion prediction system (predict future emotional states)
-- - Emotional trigger identification and tracking
-- - Emotion regulation strategies (reappraisal, suppression, acceptance)
-- - Complex emotion blending (mixed emotions)
-- - Emotional contagion modeling
-- - Affect forecasting
-- - Mood disorders detection patterns
-- - Emotional intelligence metrics
-- - Empathetic response generation with multiple strategies
-- - Emotional memory (remember what caused emotions)
-- - Physiological correlates of emotions
-- - Cultural differences in emotional expression

local M = {}

-- ============================================================================
-- COMPREHENSIVE EMOTION DATABASE - 40+ Emotions with Micro-Emotions
-- ============================================================================

local emotionDatabase = {
    -- PRIMARY EMOTIONS (Plutchik's basic emotions)

    -- 1. JOY FAMILY
    joy = {
        words = {"happy", "joyful", "cheerful", "delighted", "pleased", "glad", "content",
                "ecstatic", "elated", "thrilled", "overjoyed", "blissful", "gleeful", "merry",
                "jubilant", "euphoric", "exuberant", "radiant"},
        expressions = {"haha", "lol", "lmao", "rofl", "yay", "woohoo", "yess", ":)", "😊", "😄", "😃", "🎉"},
        intensity = 0.8,
        valence = 1.0,
        arousal = 0.6,
        category = "positive",
        physiological = {"increased heart rate", "smiling", "relaxed muscles"},
        micro_emotions = {"amusement", "zest", "contentment", "satisfaction", "delight"}
    },

    contentment = {
        words = {"content", "satisfied", "peaceful", "serene", "calm", "tranquil", "at ease"},
        expressions = {"😌", "☺️"},
        intensity = 0.5,
        valence = 0.7,
        arousal = -0.2,
        category = "positive",
        physiological = {"low heart rate", "relaxed breathing", "loose muscles"},
        micro_emotions = {"serenity", "satisfaction", "peace"}
    },

    -- 2. SADNESS FAMILY
    sadness = {
        words = {"sad", "unhappy", "depressed", "down", "miserable", "gloomy", "melancholy",
                "sorrowful", "dejected", "despondent", "heartbroken", "grief", "mourning",
                "dismal", "forlorn", "woeful", "blue", "downcast"},
        expressions = {":(", ":'(", "😢", "😭", "😞", "sigh", "ugh"},
        intensity = 0.7,
        valence = -0.8,
        arousal = -0.4,
        category = "negative",
        physiological = {"crying", "low energy", "slumped posture", "slow speech"},
        micro_emotions = {"gloom", "sorrow", "despair", "loneliness", "isolation"}
    },

    grief = {
        words = {"grieving", "mourning", "bereaved", "heartbroken", "devastated"},
        expressions = {"💔", "😭"},
        intensity = 0.9,
        valence = -0.95,
        arousal = -0.3,
        category = "negative",
        physiological = {"heavy chest", "fatigue", "loss of appetite"},
        micro_emotions = {"anguish", "yearning", "emptiness"}
    },

    -- 3. ANGER FAMILY
    anger = {
        words = {"angry", "mad", "furious", "enraged", "livid", "irate", "outraged",
                "irritated", "annoyed", "frustrated", "aggravated", "infuriated", "hate",
                "hostile", "bitter", "resentful", "indignant"},
        expressions = {"ugh", "grr", "argh", "damn", "dammit", ">:(", "😠", "😡", "💢"},
        intensity = 0.9,
        valence = -0.9,
        arousal = 0.8,
        category = "negative",
        physiological = {"increased heart rate", "muscle tension", "clenched jaw", "flushed face"},
        micro_emotions = {"irritation", "rage", "fury", "exasperation", "bitterness"}
    },

    frustration = {
        words = {"frustrated", "exasperated", "fed up", "irritated", "aggravated"},
        expressions = {"ugh", "argh", "seriously"},
        intensity = 0.6,
        valence = -0.6,
        arousal = 0.5,
        category = "negative",
        physiological = {"tension", "sighing", "restlessness"},
        micro_emotions = {"impatience", "annoyance", "agitation"}
    },

    -- 4. FEAR FAMILY
    fear = {
        words = {"scared", "afraid", "frightened", "terrified", "anxious", "worried",
                "nervous", "panicked", "alarmed", "uneasy", "apprehensive", "concerned",
                "dread", "horror", "terror", "phobic"},
        expressions = {"oh no", "yikes", "eek", "omg", "😱", "😨", "😰"},
        intensity = 0.8,
        valence = -0.7,
        arousal = 0.7,
        category = "negative",
        physiological = {"rapid heart rate", "sweating", "trembling", "shallow breathing"},
        micro_emotions = {"anxiety", "dread", "panic", "nervousness", "terror"}
    },

    anxiety = {
        words = {"anxious", "worried", "nervous", "stressed", "tense", "on edge"},
        expressions = {"😰", "😟"},
        intensity = 0.6,
        valence = -0.6,
        arousal = 0.5,
        category = "negative",
        physiological = {"racing thoughts", "muscle tension", "restlessness", "difficulty concentrating"},
        micro_emotions = {"worry", "unease", "apprehension", "nervousness"}
    },

    -- 5. SURPRISE FAMILY
    surprise = {
        words = {"surprised", "shocked", "astonished", "amazed", "stunned", "startled",
                "astounded", "flabbergasted", "bewildered", "dumbfounded"},
        expressions = {"wow", "whoa", "omg", "oh my", "no way", "really", "😲", "😮", "🤯"},
        intensity = 0.6,
        valence = 0.0,
        arousal = 0.8,
        category = "neutral",
        physiological = {"widened eyes", "raised eyebrows", "gasping"},
        micro_emotions = {"astonishment", "amazement", "shock"}
    },

    -- 6. DISGUST FAMILY
    disgust = {
        words = {"disgusting", "gross", "revolting", "repulsive", "nasty", "vile",
                "nauseating", "sickening", "repugnant", "abhorrent"},
        expressions = {"ew", "eww", "yuck", "bleh", "🤢", "🤮"},
        intensity = 0.7,
        valence = -0.8,
        arousal = 0.5,
        category = "negative",
        physiological = {"nausea", "wrinkled nose", "narrowed eyes"},
        micro_emotions = {"revulsion", "contempt", "aversion"}
    },

    -- 7. ANTICIPATION FAMILY
    anticipation = {
        words = {"excited", "eager", "looking forward", "can't wait", "anticipating",
                "expecting", "hoping", "awaiting", "enthusiastic", "keen"},
        expressions = {"yes!", "finally", "yay", "🎉", "🙌"},
        intensity = 0.6,
        valence = 0.5,
        arousal = 0.6,
        category = "positive",
        physiological = {"increased energy", "alertness", "forward-leaning posture"},
        micro_emotions = {"eagerness", "excitement", "expectancy"}
    },

    -- 8. TRUST FAMILY
    trust = {
        words = {"trust", "believe", "faith", "confident", "sure", "certain",
                "reliable", "dependable", "secure"},
        expressions = {"🤝"},
        intensity = 0.5,
        valence = 0.6,
        arousal = 0.2,
        category = "positive",
        physiological = {"relaxed", "open posture", "steady breathing"},
        micro_emotions = {"confidence", "security", "faith"}
    },

    -- SECONDARY/COMPLEX EMOTIONS (Combinations and nuanced states)

    -- 9. LOVE FAMILY
    love = {
        words = {"love", "adore", "cherish", "affection", "caring", "devoted",
                "fondness", "attachment", "warmth", "tenderness", "compassion"},
        expressions = {"<3", "❤️", "💕", "😍", "🥰"},
        intensity = 0.9,
        valence = 1.0,
        arousal = 0.5,
        category = "positive",
        physiological = {"warmth", "relaxation", "increased oxytocin"},
        micro_emotions = {"affection", "tenderness", "devotion", "warmth", "compassion"}
    },

    compassion = {
        words = {"compassionate", "caring", "sympathetic", "kind", "understanding"},
        expressions = {"❤️", "🤗"},
        intensity = 0.7,
        valence = 0.8,
        arousal = 0.3,
        category = "positive",
        physiological = {"warmth in chest", "soft expression", "gentle posture"},
        micro_emotions = {"empathy", "kindness", "concern"}
    },

    -- 10. GUILT/SHAME FAMILY
    guilt = {
        words = {"guilty", "ashamed", "remorseful", "regret", "sorry", "repentant"},
        expressions = {"sorry", "my bad", "oops", "😔"},
        intensity = 0.6,
        valence = -0.6,
        arousal = -0.3,
        category = "negative",
        physiological = {"heaviness", "looking down", "slumped shoulders"},
        micro_emotions = {"remorse", "regret", "contrition"}
    },

    shame = {
        words = {"embarrassed", "humiliated", "mortified", "ashamed", "disgraced", "self-conscious"},
        expressions = {"ugh", "😳", "🙈"},
        intensity = 0.7,
        valence = -0.7,
        arousal = -0.2,
        category = "negative",
        physiological = {"blushing", "hiding face", "avoiding eye contact"},
        micro_emotions = {"humiliation", "embarrassment", "self-consciousness"}
    },

    -- 11. PRIDE/ACHIEVEMENT FAMILY
    pride = {
        words = {"proud", "accomplished", "satisfied", "fulfilled", "triumphant", "successful"},
        expressions = {"yes!", "nailed it", "💪", "🏆"},
        intensity = 0.7,
        valence = 0.8,
        arousal = 0.4,
        category = "positive",
        physiological = {"chest out", "head high", "smile"},
        micro_emotions = {"accomplishment", "satisfaction", "triumph"}
    },

    -- 12. GRATITUDE FAMILY
    gratitude = {
        words = {"thankful", "grateful", "appreciative", "thanks", "thank you", "blessed"},
        expressions = {"thanks", "thx", "ty", "thank you", "🙏"},
        intensity = 0.6,
        valence = 0.7,
        arousal = 0.3,
        category = "positive",
        physiological = {"warmth", "relaxed", "smile"},
        micro_emotions = {"appreciation", "thankfulness"}
    },

    -- 13. CONFUSION/UNCERTAINTY FAMILY
    confusion = {
        words = {"confused", "puzzled", "perplexed", "baffled", "bewildered",
                "unclear", "lost", "uncertain", "disoriented"},
        expressions = {"huh", "what", "?", "idk", "dunno", "🤔", "😕", "🤷"},
        intensity = 0.4,
        valence = -0.3,
        arousal = 0.2,
        category = "neutral",
        physiological = {"furrowed brow", "tilted head", "squinting"},
        micro_emotions = {"perplexity", "uncertainty", "disorientation"}
    },

    -- 14. BOREDOM/APATHY FAMILY
    boredom = {
        words = {"bored", "boring", "dull", "tedious", "monotonous", "uninteresting", "tired of"},
        expressions = {"meh", "ugh", "😑", "😐", "🥱"},
        intensity = 0.4,
        valence = -0.4,
        arousal = -0.6,
        category = "negative",
        physiological = {"yawning", "restlessness", "low energy"},
        micro_emotions = {"disinterest", "restlessness", "apathy"}
    },

    apathy = {
        words = {"apathetic", "indifferent", "numb", "don't care", "whatever"},
        expressions = {"meh", "whatever", "🤷"},
        intensity = 0.3,
        valence = -0.2,
        arousal = -0.8,
        category = "negative",
        physiological = {"flat affect", "low motivation", "disconnection"},
        micro_emotions = {"indifference", "numbness", "detachment"}
    },

    -- 15. LONELINESS/ISOLATION FAMILY
    loneliness = {
        words = {"lonely", "alone", "isolated", "solitary", "abandoned", "disconnected"},
        expressions = {"😔", "😢"},
        intensity = 0.7,
        valence = -0.7,
        arousal = -0.5,
        category = "negative",
        physiological = {"heaviness", "fatigue", "aching"},
        micro_emotions = {"isolation", "alienation", "abandonment"}
    },

    -- 16. HOPE/OPTIMISM FAMILY
    hope = {
        words = {"hopeful", "optimistic", "positive", "encouraged", "promising", "looking up"},
        expressions = {"fingers crossed", "🤞", "🌟"},
        intensity = 0.6,
        valence = 0.6,
        arousal = 0.3,
        category = "positive",
        physiological = {"lighter feeling", "forward focus", "relaxation"},
        micro_emotions = {"optimism", "expectancy", "faith"}
    },

    optimism = {
        words = {"optimistic", "positive", "confident", "upbeat", "hopeful"},
        expressions = {"✨", "🌈"},
        intensity = 0.6,
        valence = 0.7,
        arousal = 0.4,
        category = "positive",
        physiological = {"lightness", "energy", "smile"},
        micro_emotions = {"positivity", "confidence", "cheerfulness"}
    },

    -- 17. DISAPPOINTMENT FAMILY
    disappointment = {
        words = {"disappointed", "let down", "discouraged", "dismayed", "disheartened", "deflated"},
        expressions = {"aw", "darn", "😞", "😔", "☹️"},
        intensity = 0.6,
        valence = -0.6,
        arousal = -0.4,
        category = "negative",
        physiological = {"slumping", "sighing", "heaviness"},
        micro_emotions = {"letdown", "discouragement", "disillusionment"}
    },

    -- 18. RELIEF FAMILY
    relief = {
        words = {"relieved", "reassured", "comforted", "calmed", "eased"},
        expressions = {"phew", "thank god", "finally", "😌", "😮‍💨"},
        intensity = 0.5,
        valence = 0.5,
        arousal = -0.3,
        category = "positive",
        physiological = {"deep breath", "muscle relaxation", "sighing"},
        micro_emotions = {"comfort", "ease", "safety"}
    },

    -- 19. JEALOUSY/ENVY FAMILY
    jealousy = {
        words = {"jealous", "envious", "covetous", "resentful"},
        expressions = {"😒"},
        intensity = 0.6,
        valence = -0.6,
        arousal = 0.4,
        category = "negative",
        physiological = {"tension", "narrowed eyes", "tightness"},
        micro_emotions = {"envy", "resentment", "insecurity"}
    },

    -- 20. CONTEMPT FAMILY
    contempt = {
        words = {"contempt", "disdain", "scorn", "derision", "condescending"},
        expressions = {"😒", "🙄"},
        intensity = 0.7,
        valence = -0.7,
        arousal = 0.3,
        category = "negative",
        physiological = {"raised upper lip", "looking down", "dismissive posture"},
        micro_emotions = {"disdain", "scorn", "superiority"}
    },

    -- 21-40: Additional nuanced emotions
    awe = {
        words = {"awe", "wonder", "amazement", "reverence", "admiration"},
        expressions = {"wow", "😮", "✨"},
        intensity = 0.7,
        valence = 0.7,
        arousal = 0.5,
        category = "positive",
        physiological = {"widened eyes", "stillness", "goosebumps"},
        micro_emotions = {"wonder", "reverence", "admiration"}
    },

    excitement = {
        words = {"excited", "thrilled", "pumped", "stoked", "hyped"},
        expressions = {"yes!", "let's go!", "🎉", "🔥"},
        intensity = 0.8,
        valence = 0.9,
        arousal = 0.9,
        category = "positive",
        physiological = {"high energy", "rapid speech", "restlessness"},
        micro_emotions = {"enthusiasm", "exhilaration", "eagerness"}
    },

    calmness = {
        words = {"calm", "peaceful", "tranquil", "serene", "composed", "centered"},
        expressions = {"😌", "🧘"},
        intensity = 0.4,
        valence = 0.5,
        arousal = -0.5,
        category = "positive",
        physiological = {"slow breathing", "relaxed muscles", "stillness"},
        micro_emotions = {"peace", "tranquility", "composure"}
    },

    nostalgia = {
        words = {"nostalgic", "reminiscent", "wistful", "sentimental"},
        expressions = {"😌", "💭"},
        intensity = 0.5,
        valence = 0.3,
        arousal = -0.2,
        category = "mixed",
        physiological = {"warmth", "distant gaze", "softness"},
        micro_emotions = {"longing", "reminiscence", "sentimentality"}
    },

    curiosity = {
        words = {"curious", "interested", "intrigued", "wondering", "fascinated"},
        expressions = {"hmm", "interesting", "🤔", "👀"},
        intensity = 0.5,
        valence = 0.4,
        arousal = 0.3,
        category = "positive",
        physiological = {"leaning forward", "widened eyes", "alertness"},
        micro_emotions = {"interest", "intrigue", "fascination"}
    },

    empathy = {
        words = {"empathetic", "understanding", "compassionate", "feel for"},
        expressions = {"🤗", "❤️"},
        intensity = 0.6,
        valence = 0.5,
        arousal = 0.2,
        category = "positive",
        physiological = {"softness", "mirroring", "openness"},
        micro_emotions = {"understanding", "connection", "resonance"}
    },

    vulnerability = {
        words = {"vulnerable", "exposed", "fragile", "raw", "open"},
        expressions = {"💔"},
        intensity = 0.6,
        valence = -0.3,
        arousal = 0.3,
        category = "mixed",
        physiological = {"tension", "protective posture", "trembling"},
        micro_emotions = {"exposure", "fragility", "openness"}
    },

    serenity = {
        words = {"serene", "peaceful", "tranquil", "harmonious", "balanced"},
        expressions = {"🕊️", "☮️"},
        intensity = 0.4,
        valence = 0.7,
        arousal = -0.6,
        category = "positive",
        physiological = {"deep calm", "gentle breathing", "soft expression"},
        micro_emotions = {"peace", "harmony", "balance"}
    },

    determination = {
        words = {"determined", "resolute", "committed", "focused", "driven"},
        expressions = {"💪", "🎯"},
        intensity = 0.7,
        valence = 0.6,
        arousal = 0.6,
        category = "positive",
        physiological = {"tension", "focused gaze", "forward posture"},
        micro_emotions = {"resolve", "commitment", "drive"}
    },

    overwhelm = {
        words = {"overwhelmed", "swamped", "flooded", "too much", "can't cope"},
        expressions = {"😰", "😵"},
        intensity = 0.7,
        valence = -0.6,
        arousal = 0.7,
        category = "negative",
        physiological = {"rapid breathing", "tension", "scattered thoughts"},
        micro_emotions = {"stress", "pressure", "overload"}
    },

    melancholy = {
        words = {"melancholic", "wistful", "pensive", "reflective", "somber"},
        expressions = {"😔", "🌧️"},
        intensity = 0.5,
        valence = -0.5,
        arousal = -0.4,
        category = "negative",
        physiological = {"heaviness", "slow movement", "distant gaze"},
        micro_emotions = {"sadness", "reflection", "pensiveness"}
    },

    playfulness = {
        words = {"playful", "fun", "silly", "mischievous", "lighthearted"},
        expressions = {"😄", "😜", "🎈"},
        intensity = 0.6,
        valence = 0.8,
        arousal = 0.5,
        category = "positive",
        physiological = {"lightness", "smiling", "energetic movement"},
        micro_emotions = {"fun", "mischief", "spontaneity"}
    },

    rage = {
        words = {"enraged", "furious", "seeing red", "livid", "incensed"},
        expressions = {"😤", "🤬"},
        intensity = 1.0,
        valence = -1.0,
        arousal = 1.0,
        category = "negative",
        physiological = {"extreme tension", "shaking", "flushed face", "raised voice"},
        micro_emotions = {"fury", "wrath", "outrage"}
    },

    peace = {
        words = {"peaceful", "at peace", "harmonious", "undisturbed"},
        expressions = {"☮️", "🕊️"},
        intensity = 0.4,
        valence = 0.7,
        arousal = -0.7,
        category = "positive",
        physiological = {"deep relaxation", "stillness", "soft breathing"},
        micro_emotions = {"tranquility", "calm", "harmony"}
    },

    inspiration = {
        words = {"inspired", "motivated", "energized", "uplifted"},
        expressions = {"💡", "✨", "🌟"},
        intensity = 0.7,
        valence = 0.8,
        arousal = 0.6,
        category = "positive",
        physiological = {"energy surge", "alertness", "expansiveness"},
        micro_emotions = {"motivation", "uplift", "creativity"}
    }
}

-- ============================================================================
-- EMOTIONAL STATE TRACKING
-- ============================================================================

local userProfiles = {}
local HISTORY_LIMIT = 30
local ANALYSIS_WINDOW = 7

-- Emotional memory: track what caused specific emotions
local emotionalMemory = {}

-- Emotional triggers database
local emotionalTriggers = {
    common_triggers = {
        positive = {"success", "praise", "love", "achievement", "connection", "kindness", "beauty", "surprise"},
        negative = {"failure", "criticism", "loss", "rejection", "conflict", "pain", "injustice", "uncertainty"}
    },
    user_specific = {}
}

-- Initialize user emotional profile
local function initUserProfile(user)
    if not userProfiles[user] then
        userProfiles[user] = {
            history = {},
            dominantEmotion = "neutral",
            emotionalBaseline = {valence = 0, arousal = 0},
            emotionalVolatility = 0,
            emotionalRange = {min = 0, max = 0},
            lastUpdate = os.time(),
            emotionalPatterns = {},
            triggerHistory = {},
            regulationStrategies = {},
            emotionalIntelligence = {
                self_awareness = 0.5,
                regulation = 0.5,
                empathy = 0.5,
                social_skills = 0.5
            }
        }
    end
    return userProfiles[user]
end

-- ============================================================================
-- MULTI-DIMENSIONAL EMOTION DETECTION
-- ============================================================================

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
                score = score + 1.5
                table.insert(matches, expr)
            end
        end

        if score > 0 then
            detectedEmotions[emotionName] = {
                score = score,
                confidence = math.min(score / 3, 1.0),
                intensity = emotionData.intensity,
                valence = emotionData.valence,
                arousal = emotionData.arousal,
                category = emotionData.category,
                matches = matches,
                physiological = emotionData.physiological,
                micro_emotions = emotionData.micro_emotions
            }
        end
    end

    return detectedEmotions
end

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

function M.detectSentiment(message)
    if not message then return "neutral", 0, {} end

    local emotions = M.detectEmotions(message)
    local dimensions = M.getEmotionalDimensions(message)

    local sentiment
    if dimensions.valence > 0.3 then
        sentiment = "positive"
    elseif dimensions.valence < -0.3 then
        sentiment = "negative"
    else
        sentiment = "neutral"
    end

    local strength = math.abs(dimensions.valence)

    return sentiment, strength, emotions
end

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

-- ============================================================================
-- COMPLEX EMOTION BLENDING (Mixed Emotions)
-- ============================================================================

function M.getEmotionBlend(message)
    local emotions = M.detectEmotions(message)
    local blend = {}

    for emotionName, data in pairs(emotions) do
        if data.confidence > 0.3 then
            table.insert(blend, {
                emotion = emotionName,
                confidence = data.confidence,
                category = data.category,
                valence = data.valence,
                arousal = data.arousal
            })
        end
    end

    table.sort(blend, function(a, b) return a.confidence > b.confidence end)

    return blend
end

-- Detect mixed/ambivalent emotions
function M.detectMixedEmotions(message)
    local blend = M.getEmotionBlend(message)

    if #blend < 2 then return nil end

    local hasPositive = false
    local hasNegative = false

    for _, emotion in ipairs(blend) do
        if emotion.category == "positive" then hasPositive = true end
        if emotion.category == "negative" then hasNegative = true end
    end

    if hasPositive and hasNegative then
        return {
            type = "ambivalent",
            emotions = blend,
            description = "experiencing mixed emotions"
        }
    end

    return nil
end

-- ============================================================================
-- EMOTION PREDICTION SYSTEM
-- ============================================================================

function M.predictFutureEmotion(user, timeframe)
    local profile = userProfiles[user]
    if not profile or #profile.history < 5 then
        return {emotion = "neutral", confidence = 0.3}
    end

    local recentHistory = {}
    for i = math.max(1, #profile.history - 10), #profile.history do
        table.insert(recentHistory, profile.history[i])
    end

    local valenceTrend = 0
    local arousalTrend = 0

    for i = 2, #recentHistory do
        valenceTrend = valenceTrend + (recentHistory[i].valence - recentHistory[i-1].valence)
        arousalTrend = arousalTrend + (recentHistory[i].arousal - recentHistory[i-1].arousal)
    end

    valenceTrend = valenceTrend / (#recentHistory - 1)
    arousalTrend = arousalTrend / (#recentHistory - 1)

    local current = recentHistory[#recentHistory]
    local predictedValence = current.valence + (valenceTrend * (timeframe or 1))
    local predictedArousal = current.arousal + (arousalTrend * (timeframe or 1))

    predictedValence = math.max(-1, math.min(1, predictedValence))
    predictedArousal = math.max(-1, math.min(1, predictedArousal))

    local predictedEmotion = M.emotionFromDimensions(predictedValence, predictedArousal)

    local confidence = math.max(0.3, 1.0 - (profile.emotionalVolatility * 2))

    return {
        emotion = predictedEmotion,
        valence = predictedValence,
        arousal = predictedArousal,
        confidence = confidence,
        trend = valenceTrend > 0.1 and "improving" or (valenceTrend < -0.1 and "declining" or "stable")
    }
end

function M.emotionFromDimensions(valence, arousal)
    if valence > 0.5 and arousal > 0.5 then return "excitement"
    elseif valence > 0.5 and arousal < -0.3 then return "contentment"
    elseif valence > 0.3 then return "joy"
    elseif valence < -0.5 and arousal > 0.5 then return "anger"
    elseif valence < -0.5 and arousal < -0.3 then return "sadness"
    elseif valence < -0.3 then return "disappointment"
    elseif arousal > 0.6 then return "surprise"
    else return "neutral" end
end

-- ============================================================================
-- EMOTIONAL TRIGGER IDENTIFICATION AND TRACKING
-- ============================================================================

function M.identifyTrigger(user, emotion, context)
    local profile = userProfiles[user]
    if not profile then return nil end

    local trigger = {
        emotion = emotion,
        context = context,
        timestamp = os.time(),
        valence = context.valence or 0,
        situation = context.situation or "unknown"
    }

    table.insert(profile.triggerHistory, trigger)

    if #profile.triggerHistory > 50 then
        table.remove(profile.triggerHistory, 1)
    end

    return trigger
end

function M.getCommonTriggers(user, emotion)
    local profile = userProfiles[user]
    if not profile then return {} end

    local triggers = {}
    for _, trigger in ipairs(profile.triggerHistory) do
        if trigger.emotion == emotion then
            table.insert(triggers, trigger)
        end
    end

    return triggers
end

-- ============================================================================
-- EMOTION REGULATION STRATEGIES
-- ============================================================================

local regulationStrategies = {
    -- Strategy 1: Cognitive Reappraisal
    reappraisal = {
        description = "Reinterpret the situation to change emotional response",
        effectiveness = {anxiety = 0.8, anger = 0.7, sadness = 0.6, frustration = 0.8},
        techniques = {
            "Look at this from a different perspective",
            "What would you tell a friend in this situation?",
            "Consider the broader context",
            "Focus on what you can learn from this"
        }
    },

    -- Strategy 2: Acceptance
    acceptance = {
        description = "Accept emotions without judgment",
        effectiveness = {anxiety = 0.7, sadness = 0.8, grief = 0.9, disappointment = 0.7},
        techniques = {
            "It's okay to feel this way",
            "These feelings are valid and temporary",
            "Allow yourself to experience this",
            "Emotions are information, not directives"
        }
    },

    -- Strategy 3: Distraction
    distraction = {
        description = "Redirect attention away from emotional stimulus",
        effectiveness = {anxiety = 0.6, anger = 0.5, sadness = 0.5, overwhelm = 0.7},
        techniques = {
            "Try focusing on something else for now",
            "Engage in an activity you enjoy",
            "Take a break and come back to this",
            "Use your senses to ground yourself"
        }
    },

    -- Strategy 4: Suppression
    suppression = {
        description = "Inhibit emotional expression (use sparingly)",
        effectiveness = {anger = 0.4, anxiety = 0.3, frustration = 0.4},
        techniques = {
            "Take a moment to compose yourself",
            "Breathe deeply before responding"
        },
        warning = "Long-term suppression can be harmful"
    },

    -- Strategy 5: Problem-solving
    problem_solving = {
        description = "Address the root cause of the emotion",
        effectiveness = {frustration = 0.9, anxiety = 0.8, anger = 0.7, overwhelm = 0.8},
        techniques = {
            "What specific steps can you take?",
            "Break this down into manageable parts",
            "What resources do you need?",
            "Let's create an action plan"
        }
    },

    -- Strategy 6: Social Support
    social_support = {
        description = "Seek connection and support from others",
        effectiveness = {loneliness = 0.9, sadness = 0.8, anxiety = 0.7, grief = 0.8},
        techniques = {
            "Would it help to talk about this?",
            "Consider reaching out to someone you trust",
            "You don't have to go through this alone",
            "Connection can be healing"
        }
    },

    -- Strategy 7: Mindfulness
    mindfulness = {
        description = "Stay present with emotions without judgment",
        effectiveness = {anxiety = 0.8, overwhelm = 0.9, anger = 0.7, sadness = 0.7},
        techniques = {
            "Notice what you're feeling right now",
            "Observe your thoughts without attaching to them",
            "Ground yourself in the present moment",
            "Breathe and notice your body"
        }
    },

    -- Strategy 8: Self-compassion
    self_compassion = {
        description = "Treat yourself with kindness",
        effectiveness = {shame = 0.9, guilt = 0.9, sadness = 0.8, disappointment = 0.8},
        techniques = {
            "Be kind to yourself in this moment",
            "You're doing the best you can",
            "Everyone struggles sometimes",
            "Treat yourself as you would a good friend"
        }
    },

    -- Strategy 9: Physical Activity
    physical_activity = {
        description = "Use movement to process emotions",
        effectiveness = {anxiety = 0.8, anger = 0.9, frustration = 0.9, overwhelm = 0.7},
        techniques = {
            "Movement can help process these feelings",
            "Consider going for a walk",
            "Physical activity can shift your state",
            "Exercise releases natural mood boosters"
        }
    },

    -- Strategy 10: Gratitude
    gratitude = {
        description = "Focus on positive aspects",
        effectiveness = {sadness = 0.6, disappointment = 0.7, boredom = 0.6},
        techniques = {
            "What's one thing you're grateful for?",
            "Notice small positive moments",
            "Appreciate what's going well",
            "Keep a gratitude practice"
        }
    }
}

function M.suggestRegulationStrategy(emotion, context)
    context = context or {}

    local bestStrategy = nil
    local bestEffectiveness = 0

    for strategyName, strategy in pairs(regulationStrategies) do
        local effectiveness = strategy.effectiveness[emotion] or 0.5

        if context.preferredStrategy and strategyName == context.preferredStrategy then
            effectiveness = effectiveness * 1.3
        end

        if effectiveness > bestEffectiveness then
            bestEffectiveness = effectiveness
            bestStrategy = strategyName
        end
    end

    if bestStrategy then
        local strategy = regulationStrategies[bestStrategy]
        return {
            name = bestStrategy,
            description = strategy.description,
            effectiveness = bestEffectiveness,
            technique = strategy.techniques[math.random(#strategy.techniques)],
            warning = strategy.warning
        }
    end

    return nil
end

-- ============================================================================
-- EMOTIONAL CONTAGION MODELING
-- ============================================================================

local emotionalContagion = {
    susceptibility = 0.6,
    baselineResistance = 0.3
}

function M.calculateEmotionalContagion(userEmotion, aiEmotion, interactionCount)
    local contagionStrength = emotionalContagion.susceptibility - emotionalContagion.baselineResistance

    if interactionCount > 10 then
        contagionStrength = contagionStrength * 1.2
    end

    local emotionData = emotionDatabase[userEmotion]
    if not emotionData then return 0 end

    local contagionEffect = emotionData.valence * emotionData.arousal * contagionStrength

    return contagionEffect
end

function M.applyEmotionalContagion(user, userEmotion)
    local profile = userProfiles[user]
    if not profile then return end

    local contagionEffect = M.calculateEmotionalContagion(userEmotion, "neutral", #profile.history)

    if math.abs(contagionEffect) > 0.3 then
        return {
            affected = true,
            direction = contagionEffect > 0 and "positive" or "negative",
            strength = math.abs(contagionEffect),
            response_adjustment = "mirror_emotion"
        }
    end

    return {affected = false}
end

-- ============================================================================
-- AFFECT FORECASTING
-- ============================================================================

function M.forecastAffect(user, hypotheticalSituation)
    local profile = userProfiles[user]
    if not profile then
        return {
            predicted_emotion = "neutral",
            confidence = 0.3,
            note = "Insufficient history"
        }
    end

    local similarPastExperiences = {}
    for _, entry in ipairs(profile.history) do
        if entry.context and entry.context.situation then
            if entry.context.situation:find(hypotheticalSituation, 1, true) then
                table.insert(similarPastExperiences, entry)
            end
        end
    end

    if #similarPastExperiences > 0 then
        local avgValence = 0
        local avgArousal = 0

        for _, exp in ipairs(similarPastExperiences) do
            avgValence = avgValence + exp.valence
            avgArousal = avgArousal + exp.arousal
        end

        avgValence = avgValence / #similarPastExperiences
        avgArousal = avgArousal / #similarPastExperiences

        local predictedEmotion = M.emotionFromDimensions(avgValence, avgArousal)

        return {
            predicted_emotion = predictedEmotion,
            valence = avgValence,
            arousal = avgArousal,
            confidence = math.min(0.9, 0.5 + (#similarPastExperiences * 0.1)),
            basis = "similar_past_experiences",
            sample_size = #similarPastExperiences
        }
    end

    local baselinePrediction = M.emotionFromDimensions(
        profile.emotionalBaseline.valence,
        profile.emotionalBaseline.arousal
    )

    return {
        predicted_emotion = baselinePrediction,
        confidence = 0.5,
        basis = "emotional_baseline",
        note = "No similar past experiences found"
    }
end

-- ============================================================================
-- MOOD DISORDERS DETECTION PATTERNS
-- ============================================================================

function M.detectMoodPatterns(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 10 then
        return {sufficient_data = false}
    end

    local patterns = {
        sufficient_data = true,
        warning_signs = {},
        concerning_patterns = {}
    }

    local negativeCount = 0
    local lowEnergyCount = 0
    local highVolatility = false

    for i = math.max(1, #profile.history - 10), #profile.history do
        local entry = profile.history[i]

        if entry.valence < -0.5 then
            negativeCount = negativeCount + 1
        end

        if entry.arousal < -0.5 then
            lowEnergyCount = lowEnergyCount + 1
        end
    end

    if negativeCount >= 7 then
        table.insert(patterns.concerning_patterns, "persistent_negative_mood")
        table.insert(patterns.warning_signs, "Consistently low mood over recent interactions")
    end

    if lowEnergyCount >= 7 then
        table.insert(patterns.concerning_patterns, "low_energy")
        table.insert(patterns.warning_signs, "Persistently low energy levels")
    end

    if profile.emotionalVolatility > 0.7 then
        table.insert(patterns.concerning_patterns, "high_volatility")
        table.insert(patterns.warning_signs, "Significant mood swings")
    end

    patterns.risk_level = #patterns.concerning_patterns == 0 and "low" or
                          (#patterns.concerning_patterns == 1 and "moderate" or "elevated")

    return patterns
end

-- ============================================================================
-- EMOTIONAL INTELLIGENCE METRICS
-- ============================================================================

function M.calculateEmotionalIntelligence(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 5 then
        return {
            overall = 0.5,
            components = {
                self_awareness = 0.5,
                regulation = 0.5,
                empathy = 0.5,
                social_skills = 0.5
            },
            note = "Insufficient data"
        }
    end

    local ei = profile.emotionalIntelligence

    local expressionVariety = 0
    local emotionsExpressed = {}
    for _, entry in ipairs(profile.history) do
        if entry.emotion then
            emotionsExpressed[entry.emotion] = true
        end
    end

    for _ in pairs(emotionsExpressed) do
        expressionVariety = expressionVariety + 1
    end

    ei.self_awareness = math.min(1.0, expressionVariety / 15)

    local regulationSuccess = 0
    local regulationAttempts = 0
    for _, entry in ipairs(profile.history) do
        if entry.regulation_attempted then
            regulationAttempts = regulationAttempts + 1
            if entry.regulation_successful then
                regulationSuccess = regulationSuccess + 1
            end
        end
    end

    if regulationAttempts > 0 then
        ei.regulation = regulationSuccess / regulationAttempts
    end

    ei.overall = (ei.self_awareness + ei.regulation + ei.empathy + ei.social_skills) / 4

    return {
        overall = ei.overall,
        components = ei,
        strengths = M.identifyEIStrengths(ei),
        growth_areas = M.identifyEIGrowthAreas(ei)
    }
end

function M.identifyEIStrengths(ei)
    local strengths = {}
    if ei.self_awareness > 0.7 then table.insert(strengths, "self_awareness") end
    if ei.regulation > 0.7 then table.insert(strengths, "emotion_regulation") end
    if ei.empathy > 0.7 then table.insert(strengths, "empathy") end
    if ei.social_skills > 0.7 then table.insert(strengths, "social_skills") end
    return strengths
end

function M.identifyEIGrowthAreas(ei)
    local growth = {}
    if ei.self_awareness < 0.5 then table.insert(growth, "self_awareness") end
    if ei.regulation < 0.5 then table.insert(growth, "emotion_regulation") end
    if ei.empathy < 0.5 then table.insert(growth, "empathy") end
    if ei.social_skills < 0.5 then table.insert(growth, "social_skills") end
    return growth
end

-- ============================================================================
-- EMOTIONAL MEMORY
-- ============================================================================

function M.recordEmotionalMemory(user, emotion, cause, context)
    if not emotionalMemory[user] then
        emotionalMemory[user] = {}
    end

    local memory = {
        emotion = emotion,
        cause = cause,
        context = context,
        timestamp = os.time(),
        intensity = context.intensity or 0.5
    }

    table.insert(emotionalMemory[user], memory)

    if #emotionalMemory[user] > 100 then
        table.remove(emotionalMemory[user], 1)
    end

    return memory
end

function M.recallEmotionalMemories(user, emotion, limit)
    if not emotionalMemory[user] then return {} end

    limit = limit or 5
    local memories = {}

    for i = #emotionalMemory[user], 1, -1 do
        local memory = emotionalMemory[user][i]
        if not emotion or memory.emotion == emotion then
            table.insert(memories, memory)
            if #memories >= limit then break end
        end
    end

    return memories
end

-- ============================================================================
-- CULTURAL DIFFERENCES IN EMOTIONAL EXPRESSION
-- ============================================================================

local culturalNorms = {
    western_individualistic = {
        emotional_expressiveness = 0.8,
        public_emotion_display = 0.7,
        emphasis_on_happiness = 0.9,
        emotion_talk = 0.8
    },

    eastern_collectivistic = {
        emotional_expressiveness = 0.5,
        public_emotion_display = 0.3,
        emphasis_on_harmony = 0.9,
        emotion_talk = 0.5
    },

    latin = {
        emotional_expressiveness = 0.9,
        public_emotion_display = 0.8,
        warmth = 0.9,
        emotion_talk = 0.8
    },

    northern_european = {
        emotional_expressiveness = 0.4,
        public_emotion_display = 0.3,
        emotional_restraint = 0.8,
        emotion_talk = 0.4
    }
}

function M.adjustForCulturalContext(emotion, culturalContext)
    local norms = culturalNorms[culturalContext] or culturalNorms.western_individualistic

    local adjustment = {
        expression_intensity = norms.emotional_expressiveness,
        public_display_appropriateness = norms.public_emotion_display,
        cultural_context = culturalContext
    }

    return adjustment
end

-- ============================================================================
-- EMPATHETIC RESPONSE GENERATION WITH MULTIPLE STRATEGIES
-- ============================================================================

local empathyStrategies = {
    validation = {
        templates = {
            "Your feelings are completely valid.",
            "It makes sense that you'd feel this way.",
            "Anyone in your situation would feel similarly.",
            "What you're experiencing is understandable."
        }
    },

    reflection = {
        templates = {
            "It sounds like you're feeling {emotion}.",
            "I hear that you're {emotion}.",
            "It seems like this is making you feel {emotion}.",
            "You're going through a lot right now."
        }
    },

    normalization = {
        templates = {
            "Many people feel this way in similar situations.",
            "This is a common response to what you're experiencing.",
            "You're not alone in feeling this.",
            "These feelings are a normal reaction."
        }
    },

    support = {
        templates = {
            "I'm here for you.",
            "You don't have to go through this alone.",
            "I'm listening.",
            "Thank you for sharing this with me."
        }
    },

    encouragement = {
        templates = {
            "You've gotten through difficult times before.",
            "This is hard, but you're capable of handling it.",
            "Take things one step at a time.",
            "You're stronger than you think."
        }
    },

    curiosity = {
        templates = {
            "Tell me more about what's going on.",
            "How long have you been feeling this way?",
            "What would help you feel better?",
            "What do you need right now?"
        }
    }
}

function M.generateEmpatheticResponse(message, strategy)
    local emotion, confidence = M.getDominantEmotion(message)

    if not emotion or confidence < 0.3 then
        return nil
    end

    strategy = strategy or "validation"
    local strategyData = empathyStrategies[strategy]

    if not strategyData then
        strategy = "validation"
        strategyData = empathyStrategies[strategy]
    end

    local template = strategyData.templates[math.random(#strategyData.templates)]
    local response = template:gsub("{emotion}", emotion)

    return {
        response = response,
        strategy = strategy,
        emotion_addressed = emotion,
        confidence = confidence
    }
end

function M.generateMultiStrategyResponse(message)
    local responses = {}

    for strategyName, _ in pairs(empathyStrategies) do
        local response = M.generateEmpatheticResponse(message, strategyName)
        if response then
            table.insert(responses, response)
        end
    end

    return responses
end

-- ============================================================================
-- EMOTIONAL PROFILE MANAGEMENT
-- ============================================================================

function M.update(user, message, context)
    if not user or not message then return end

    context = context or {}
    local profile = initUserProfile(user)
    local sentiment, strength, emotions = M.detectSentiment(message)
    local dominant, confidence = M.getDominantEmotion(message)
    local dimensions = M.getEmotionalDimensions(message)

    table.insert(profile.history, {
        sentiment = sentiment,
        strength = strength,
        emotion = dominant,
        confidence = confidence,
        valence = dimensions.valence,
        arousal = dimensions.arousal,
        emotions = emotions,
        timestamp = os.time(),
        messageLength = #message,
        context = context,
        regulation_attempted = context.regulation_attempted,
        regulation_successful = context.regulation_successful
    })

    while #profile.history > HISTORY_LIMIT do
        table.remove(profile.history, 1)
    end

    profile.dominantEmotion = dominant or "neutral"
    profile.lastUpdate = os.time()

    M.updateEmotionalBaseline(user)
    M.calculateVolatility(user)
    M.updateEmotionalRange(user)

    if context.cause then
        M.recordEmotionalMemory(user, dominant, context.cause, context)
    end

    return sentiment
end

function M.updateEmotionalBaseline(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then return end

    local totalValence = 0
    local totalArousal = 0
    local count = 0

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

function M.calculateVolatility(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        if profile then profile.emotionalVolatility = 0 end
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

function M.updateEmotionalRange(user)
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then return end

    local minValence = 1
    local maxValence = -1

    for _, entry in ipairs(profile.history) do
        if entry.valence < minValence then minValence = entry.valence end
        if entry.valence > maxValence then maxValence = entry.valence end
    end

    profile.emotionalRange = {
        min = minValence,
        max = maxValence,
        span = maxValence - minValence
    }
end

-- ============================================================================
-- EMOTIONAL STATE QUERIES
-- ============================================================================

function M.get(user)
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return "neutral"
    end

    return profile.history[#profile.history].sentiment
end

function M.getTrend(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        return "stable"
    end

    if profile.emotionalVolatility > 0.5 then
        return "volatile"
    end

    local windowStart = math.max(1, #profile.history - ANALYSIS_WINDOW + 1)
    local valenceTrend = 0

    for i = windowStart + 1, #profile.history do
        local prev = profile.history[i - 1]
        local curr = profile.history[i]
        valenceTrend = valenceTrend + (curr.valence - prev.valence)
    end

    valenceTrend = valenceTrend / (#profile.history - windowStart)

    if valenceTrend > 0.15 then return "improving"
    elseif valenceTrend < -0.15 then return "declining"
    else return "stable" end
end

function M.getConsistency(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 3 then
        return "unknown"
    end

    if profile.emotionalVolatility < 0.2 then return "very_consistent"
    elseif profile.emotionalVolatility < 0.4 then return "consistent"
    elseif profile.emotionalVolatility < 0.6 then return "somewhat_variable"
    else return "highly_variable" end
end

function M.isInCrisis(user)
    local profile = userProfiles[user]
    if not profile or #profile.history < 2 then
        return false
    end

    local recent = profile.history[#profile.history]

    local strongNegative = (recent.valence < -0.7 and recent.strength > 0.6)
    local highVolatility = (profile.emotionalVolatility > 0.7)
    local negativeStreak = true

    for i = math.max(1, #profile.history - 2), #profile.history do
        if profile.history[i].sentiment ~= "negative" then
            negativeStreak = false
            break
        end
    end

    return strongNegative or (highVolatility and negativeStreak)
end

function M.getEmotionalNeeds(user)
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return {"neutral_engagement"}
    end

    local recent = profile.history[#profile.history]
    local trend = M.getTrend(user)
    local needs = {}

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

    if profile.emotionalVolatility > 0.6 then
        table.insert(needs, "stability")
        table.insert(needs, "grounding")
    end

    return needs
end

-- ============================================================================
-- RESPONSE ADJUSTMENT
-- ============================================================================

function M.adjustResponse(user, response, context)
    if not response then return "" end

    context = context or {}
    local profile = userProfiles[user]
    if not profile or #profile.history == 0 then
        return response
    end

    local needs = M.getEmotionalNeeds(user)
    local trend = M.getTrend(user)

    if M.tableContains(needs, "immediate_support") then
        local support = {
            " I'm here for you.",
            " You're not alone in this.",
            " I'm listening."
        }
        response = response .. support[math.random(#support)]
    end

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

    if M.tableContains(needs, "celebration") then
        if math.random() < 0.3 and not context.no_emoji then
            response = response .. " 🎉"
        end
    end

    return response
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.tableContains(tbl, value)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function M.getComprehensiveReport(user)
    local profile = userProfiles[user]
    if not profile then
        return {error = "User profile not found"}
    end

    return {
        current_emotion = profile.dominantEmotion,
        emotional_baseline = profile.emotionalBaseline,
        volatility = profile.emotionalVolatility,
        emotional_range = profile.emotionalRange,
        trend = M.getTrend(user),
        consistency = M.getConsistency(user),
        in_crisis = M.isInCrisis(user),
        emotional_needs = M.getEmotionalNeeds(user),
        prediction = M.predictFutureEmotion(user, 1),
        mood_patterns = M.detectMoodPatterns(user),
        emotional_intelligence = M.calculateEmotionalIntelligence(user),
        recent_memories = M.recallEmotionalMemories(user, nil, 5),
        interaction_count = #profile.history
    }
end

return M
