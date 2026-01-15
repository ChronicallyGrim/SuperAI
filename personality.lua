-- Module: personality.lua
-- Advanced adaptive personality with multi-dimensional trait system

local M = {}

-- ============================================================================
-- PERSONALITY TRAIT SYSTEM - Big Five + Additional Dimensions
-- ============================================================================

M.traits = {
    -- Big Five Personality Traits
    openness = 0.7,          -- Openness to experience (curious vs cautious)
    conscientiousness = 0.6, -- Organized and dependable vs spontaneous
    extraversion = 0.6,      -- Outgoing and energetic vs reserved
    agreeableness = 0.8,     -- Friendly and compassionate vs challenging
    neuroticism = 0.3,       -- Emotional stability (low neuroticism is good)
    
    -- Conversational Traits
    humor = 0.5,             -- Use of jokes and playfulness
    empathy = 0.7,           -- Emotional support and understanding
    curiosity = 0.6,         -- Tendency to ask questions
    verbosity = 0.5,         -- Length of responses
    formality = 0.3,         -- Casual vs formal language
    assertiveness = 0.5,     -- Directness in expressing opinions
    
    -- Interaction Style
    patience = 0.7,          -- Tolerance for confusion/mistakes
    enthusiasm = 0.6,        -- Energy level in responses
    supportiveness = 0.8,    -- Encouraging and helpful
    playfulness = 0.5,       -- Lighthearted vs serious
    
    -- Advanced Traits
    authenticity = 0.8,      -- Honest vs filtered
    adaptability = 0.7,      -- Flexible vs consistent
    wisdom = 0.5,            -- Thoughtful advice vs simple responses
    creativity = 0.6         -- Unique phrasings vs conventional
}

-- Trait bounds
local TRAIT_MIN = 0.0
local TRAIT_MAX = 1.0

-- Learning rates for different traits
local LEARNING_RATES = {
    fast = 0.05,     -- Quickly adapting traits
    medium = 0.02,   -- Moderately stable traits
    slow = 0.01      -- Very stable core traits
}

-- Trait learning rate assignments
local traitLearningRates = {
    -- Fast adapting
    humor = LEARNING_RATES.fast,
    verbosity = LEARNING_RATES.fast,
    enthusiasm = LEARNING_RATES.fast,
    
    -- Medium adapting
    curiosity = LEARNING_RATES.medium,
    empathy = LEARNING_RATES.medium,
    playfulness = LEARNING_RATES.medium,
    formality = LEARNING_RATES.medium,
    assertiveness = LEARNING_RATES.medium,
    patience = LEARNING_RATES.medium,
    
    -- Slow adapting (core personality)
    openness = LEARNING_RATES.slow,
    conscientiousness = LEARNING_RATES.slow,
    extraversion = LEARNING_RATES.slow,
    agreeableness = LEARNING_RATES.slow,
    neuroticism = LEARNING_RATES.slow,
    authenticity = LEARNING_RATES.slow,
    adaptability = LEARNING_RATES.slow,
    wisdom = LEARNING_RATES.slow,
    creativity = LEARNING_RATES.slow,
    supportiveness = LEARNING_RATES.slow
}

-- ============================================================================
-- INTERACTION STATISTICS
-- ============================================================================

local stats = {
    totalInteractions = 0,
    positiveResponses = 0,
    negativeResponses = 0,
    neutralResponses = 0,
    questionsAsked = 0,
    questionsReceived = 0,
    humorAttempts = 0,
    humorSuccesses = 0,
    empatheticResponses = 0,
    longResponses = 0,
    shortResponses = 0,
    topicsDiscussed = {},
    userPreferences = {}
}

-- ============================================================================
-- PERSONALITY PROFILES (Presets for different modes)
-- ============================================================================

local personalityProfiles = {
    professional = {
        formality = 0.8,
        assertiveness = 0.7,
        humor = 0.2,
        empathy = 0.6,
        verbosity = 0.6
    },
    
    friendly = {
        formality = 0.2,
        assertiveness = 0.4,
        humor = 0.7,
        empathy = 0.8,
        verbosity = 0.5,
        playfulness = 0.7
    },
    
    supportive = {
        empathy = 0.9,
        supportiveness = 0.9,
        patience = 0.9,
        formality = 0.3,
        assertiveness = 0.3
    },
    
    analytical = {
        verbosity = 0.7,
        curiosity = 0.8,
        wisdom = 0.8,
        formality = 0.6,
        humor = 0.3
    },
    
    creative = {
        creativity = 0.9,
        openness = 0.9,
        playfulness = 0.8,
        formality = 0.2,
        verbosity = 0.6
    }
}

-- ============================================================================
-- TRAIT MANAGEMENT
-- ============================================================================

-- Adjust a personality trait with bounds checking
function M.adjust(trait, amount)
    if not M.traits[trait] then return false end
    
    -- Get learning rate for this trait
    local learningRate = traitLearningRates[trait] or LEARNING_RATES.medium
    local actualAdjustment = amount * learningRate
    
    M.traits[trait] = M.traits[trait] + actualAdjustment
    
    -- Clamp between bounds
    if M.traits[trait] < TRAIT_MIN then M.traits[trait] = TRAIT_MIN end
    if M.traits[trait] > TRAIT_MAX then M.traits[trait] = TRAIT_MAX end
    
    return true
end

-- Get current value of a trait
function M.get(trait)
    return M.traits[trait] or 0.5
end

-- Set trait to specific value
function M.set(trait, value)
    if not M.traits[trait] then return false end
    
    value = math.max(TRAIT_MIN, math.min(TRAIT_MAX, value))
    M.traits[trait] = value
    return true
end

-- Apply a personality profile
function M.applyProfile(profileName)
    local profile = personalityProfiles[profileName]
    if not profile then return false end
    
    for trait, value in pairs(profile) do
        M.set(trait, value)
    end
    
    return true
end

-- ============================================================================
-- ADVANCED EVOLUTION SYSTEM
-- ============================================================================

-- Evolve personality based on interaction feedback
function M.evolve(feedback, context)
    stats.totalInteractions = stats.totalInteractions + 1
    
    context = context or {}
    local messageType = context.messageType or "general"
    local userMood = context.userMood or "neutral"
    local responseLength = context.responseLength or "medium"
    
    -- Update statistics
    if feedback == "positive" then
        stats.positiveResponses = stats.positiveResponses + 1
    elseif feedback == "negative" then
        stats.negativeResponses = stats.negativeResponses + 1
    else
        stats.neutralResponses = stats.neutralResponses + 1
    end
    
    -- Evolve based on feedback
    if feedback == "positive" then
        M.handlePositiveFeedback(messageType, userMood, context)
    elseif feedback == "negative" then
        M.handleNegativeFeedback(messageType, userMood, context)
    elseif feedback == "question_received" then
        M.handleQuestionReceived(context)
    end
    
    -- Gradual drift toward balance if extreme
    M.preventExtremes()
end

-- Handle positive feedback
function M.handlePositiveFeedback(messageType, userMood, context)
    -- Reinforce successful behaviors
    if messageType == "humor" then
        M.adjust("humor", 1.0)
        M.adjust("playfulness", 0.5)
        stats.humorSuccesses = stats.humorSuccesses + 1
    elseif messageType == "empathy" then
        M.adjust("empathy", 1.0)
        M.adjust("supportiveness", 0.8)
    elseif messageType == "question" then
        M.adjust("curiosity", 1.0)
    elseif messageType == "wisdom" then
        M.adjust("wisdom", 0.8)
        M.adjust("verbosity", 0.3)
    end
    
    -- General positive reinforcement
    M.adjust("agreeableness", 0.3)
    M.adjust("enthusiasm", 0.5)
    
    -- Adjust based on what worked with user's mood
    if userMood == "negative" and context.wasEmpathetic then
        M.adjust("empathy", 1.2)
        M.adjust("supportiveness", 1.0)
    end
end

-- Handle negative feedback
function M.handleNegativeFeedback(messageType, userMood, context)
    -- Reduce unsuccessful behaviors
    if messageType == "humor" then
        M.adjust("humor", -1.5)
        M.adjust("playfulness", -1.0)
    elseif messageType == "question" then
        M.adjust("curiosity", -1.0)
        M.adjust("assertiveness", -0.5)
    elseif messageType == "verbosity" then
        M.adjust("verbosity", -1.2)
    end
    
    -- Increase caution
    M.adjust("patience", 0.5)
    M.adjust("formality", 0.3)
    
    -- If user was upset and we failed, become more empathetic
    if userMood == "negative" then
        M.adjust("empathy", 0.8)
        M.adjust("supportiveness", 0.6)
    end
end

-- Handle receiving questions from user
function M.handleQuestionReceived(context)
    stats.questionsReceived = stats.questionsReceived + 1
    
    -- User asking questions suggests they want more detail
    M.adjust("verbosity", 0.5)
    M.adjust("wisdom", 0.3)
    
    -- They're engaged, so slightly more openness
    M.adjust("openness", 0.2)
end

-- Prevent personality from becoming too extreme
function M.preventExtremes()
    for trait, value in pairs(M.traits) do
        -- If trait is extreme, gently pull toward center
        if value > 0.9 then
            M.traits[trait] = value - 0.01
        elseif value < 0.1 then
            M.traits[trait] = value + 0.01
        end
    end
end

-- ============================================================================
-- BEHAVIORAL DECISION MAKING
-- ============================================================================

-- Determine if AI should ask a follow-up question
function M.shouldAskQuestion(context)
    context = context or {}
    
    local base = M.traits.curiosity * 0.5
    
    -- Modifiers
    if context.userEngaged then base = base * 1.3 end
    if context.userMood == "negative" then base = base * 0.7 end  -- Less pushy when upset
    if stats.questionsAsked / math.max(stats.totalInteractions, 1) > 0.6 then
        base = base * 0.5  -- Don't overwhelm with questions
    end
    
    return math.random() < base
end

-- Determine if AI should add humor
function M.shouldAddHumor(context)
    context = context or {}
    
    local base = M.traits.humor * 0.4
    
    -- Modifiers
    if context.userMood == "negative" then
        base = base * 0.3  -- Careful with humor when user is upset
    elseif context.userMood == "positive" then
        base = base * 1.5  -- More playful when user is happy
    end
    
    -- Success rate affects future humor
    if stats.humorAttempts > 5 then
        local successRate = stats.humorSuccesses / stats.humorAttempts
        base = base * (0.5 + successRate)
    end
    
    if math.random() < base then
        stats.humorAttempts = stats.humorAttempts + 1
        return true
    end
    
    return false
end

-- Determine if AI should show empathy
function M.shouldShowEmpathy(userMood, context)
    context = context or {}
    
    -- Always show empathy for strong negative emotions
    if userMood == "negative" and M.traits.empathy > 0.4 then
        return true
    end
    
    -- Occasional empathy for neutral/positive based on trait
    local base = M.traits.empathy * 0.3
    
    if context.userVulnerable then
        base = base * 2.0
    end
    
    return math.random() < base
end

-- Determine response length category
function M.getResponseLength(context)
    context = context or {}
    
    local v = M.traits.verbosity
    
    -- Adjust for context
    if context.userMessageLength == "short" then
        v = v * 0.7  -- Match user's brevity
    elseif context.userMessageLength == "long" then
        v = v * 1.2  -- Give detailed response to detailed message
    end
    
    if context.userMood == "negative" and context.needsSupport then
        v = v * 1.3  -- More thorough when providing support
    end
    
    -- Categorize
    if v < 0.3 then return "brief" end      -- 1-2 sentences
    if v < 0.7 then return "moderate" end   -- 2-4 sentences
    return "detailed"                        -- 4+ sentences
end

-- Determine conversation formality
function M.getFormality()
    local f = M.traits.formality
    
    if f < 0.3 then return "casual" end
    if f < 0.7 then return "neutral" end
    return "formal"
end

-- Determine enthusiasm level
function M.getEnthusiasm(context)
    context = context or {}
    
    local e = M.traits.enthusiasm
    
    if context.userMood == "positive" then
        e = e * 1.3
    elseif context.userMood == "negative" then
        e = e * 0.7
    end
    
    if e < 0.3 then return "subdued" end
    if e < 0.7 then return "moderate" end
    return "high"
end

-- ============================================================================
-- PERSONALITY ANALYSIS
-- ============================================================================

-- Get personality type description
function M.getPersonalityType()
    local types = {}
    
    -- Analyze Big Five
    if M.traits.extraversion > 0.6 then
        table.insert(types, "extraverted")
    else
        table.insert(types, "introverted")
    end
    
    if M.traits.agreeableness > 0.7 then
        table.insert(types, "agreeable")
    end
    
    if M.traits.openness > 0.7 then
        table.insert(types, "open-minded")
    end
    
    if M.traits.conscientiousness > 0.7 then
        table.insert(types, "conscientious")
    end
    
    -- Analyze conversational style
    if M.traits.empathy > 0.7 then
        table.insert(types, "empathetic")
    end
    
    if M.traits.humor > 0.7 then
        table.insert(types, "humorous")
    end
    
    if M.traits.wisdom > 0.7 then
        table.insert(types, "thoughtful")
    end
    
    if M.traits.supportiveness > 0.7 then
        table.insert(types, "supportive")
    end
    
    return table.concat(types, ", ")
end

-- Get conversation style descriptor
function M.getStyle()
    local styles = {}
    
    if M.traits.formality > 0.7 then
        table.insert(styles, "formal")
    elseif M.traits.formality < 0.3 then
        table.insert(styles, "casual")
    end
    
    if M.traits.enthusiasm > 0.7 then
        table.insert(styles, "energetic")
    end
    
    if M.traits.verbosity > 0.7 then
        table.insert(styles, "detailed")
    elseif M.traits.verbosity < 0.3 then
        table.insert(styles, "concise")
    end
    
    if M.traits.playfulness > 0.7 then
        table.insert(styles, "playful")
    end
    
    if M.traits.curiosity > 0.7 then
        table.insert(styles, "inquisitive")
    end
    
    if #styles == 0 then
        return "balanced"
    end
    
    return table.concat(styles, ", ")
end

-- Get detailed personality report
function M.getReport()
    return {
        type = M.getPersonalityType(),
        style = M.getStyle(),
        traits = M.traits,
        statistics = {
            interactions = stats.totalInteractions,
            positiveRate = stats.totalInteractions > 0 and 
                          (stats.positiveResponses / stats.totalInteractions) or 0,
            humorSuccessRate = stats.humorAttempts > 0 and
                              (stats.humorSuccesses / stats.humorAttempts) or 0,
            questionsAskedRate = stats.totalInteractions > 0 and
                                (stats.questionsAsked / stats.totalInteractions) or 0
        }
    }
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

-- Get statistics
function M.getStats()
    return stats
end

-- Calculate positive interaction rate
function M.getPositiveRate()
    if stats.totalInteractions == 0 then return 0 end
    return stats.positiveResponses / stats.totalInteractions
end

-- Get humor effectiveness
function M.getHumorEffectiveness()
    if stats.humorAttempts == 0 then return 0 end
    return stats.humorSuccesses / stats.humorAttempts
end

-- Reset statistics
function M.resetStats()
    stats = {
        totalInteractions = 0,
        positiveResponses = 0,
        negativeResponses = 0,
        neutralResponses = 0,
        questionsAsked = 0,
        questionsReceived = 0,
        humorAttempts = 0,
        humorSuccesses = 0,
        empatheticResponses = 0,
        longResponses = 0,
        shortResponses = 0,
        topicsDiscussed = {},
        userPreferences = {}
    }
end

return M
