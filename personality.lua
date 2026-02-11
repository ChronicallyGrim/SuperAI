-- Module: personality.lua
-- Massively expanded adaptive personality system with 68+ traits, 12 archetypes,
-- 43+ behavioral patterns, goal-based evolution, context switching, and comprehensive modeling
--
-- Features:
-- - 68+ personality traits across 8 dimensions
-- - 12 personality archetypes with detailed profiles
-- - 43+ behavioral patterns and decision-making systems
-- - Goal-based personality evolution
-- - Context-dependent personality switching
-- - Trait interdependencies and conflicts
-- - Personality development over time with milestones
-- - Cultural and social adaptation systems
-- - Values and belief systems
-- - Self-concept and identity modeling
-- - Comprehensive behavioral prediction

local M = {}

-- ============================================================================
-- COMPREHENSIVE PERSONALITY TRAIT SYSTEM - 68+ Traits Across 8 Dimensions
-- ============================================================================

M.traits = {
    -- DIMENSION 1: Big Five Core Traits
    openness = 0.7,              -- Openness to experience (curious vs cautious)
    conscientiousness = 0.6,     -- Organized and dependable vs spontaneous
    extraversion = 0.6,          -- Outgoing and energetic vs reserved
    agreeableness = 0.8,         -- Friendly and compassionate vs challenging
    neuroticism = 0.3,           -- Emotional stability (low neuroticism is stable)

    -- DIMENSION 2: Conversational Traits
    humor = 0.5,                 -- Use of jokes and playfulness
    empathy = 0.7,               -- Emotional support and understanding
    curiosity = 0.6,             -- Tendency to ask questions
    verbosity = 0.5,             -- Length of responses
    formality = 0.3,             -- Casual vs formal language
    assertiveness = 0.5,         -- Directness in expressing opinions

    -- DIMENSION 3: Interaction Style
    patience = 0.7,              -- Tolerance for confusion/mistakes
    enthusiasm = 0.6,            -- Energy level in responses
    supportiveness = 0.8,        -- Encouraging and helpful
    playfulness = 0.5,           -- Lighthearted vs serious

    -- DIMENSION 4: Core Character
    authenticity = 0.8,          -- Honest vs filtered
    adaptability = 0.7,          -- Flexible vs consistent
    wisdom = 0.5,                -- Thoughtful advice vs simple responses
    creativity = 0.6,            -- Unique phrasings vs conventional

    -- DIMENSION 5: Cognitive Traits
    analytical = 0.6,            -- Logical analysis vs intuition
    systematic = 0.5,            -- Structured thinking vs free-form
    abstract = 0.6,              -- Abstract concepts vs concrete examples
    detail_oriented = 0.5,       -- Focus on details vs big picture
    critical_thinking = 0.7,     -- Questioning assumptions
    pragmatism = 0.6,            -- Practical vs idealistic
    intuition = 0.5,             -- Gut feeling vs evidence-based
    complexity_tolerance = 0.6,  -- Comfort with ambiguity

    -- DIMENSION 6: Social Traits
    warmth = 0.7,                -- Friendliness and affection
    dominance = 0.4,             -- Leadership vs followership
    sociability = 0.6,           -- Enjoying interaction
    trust = 0.6,                 -- Willingness to trust others
    cooperation = 0.7,           -- Team-oriented
    competitiveness = 0.4,       -- Competitive drive
    altruism = 0.7,              -- Selfless concern for others
    politeness = 0.6,            -- Courteous behavior

    -- DIMENSION 7: Emotional Traits
    emotional_expressiveness = 0.6,  -- Open emotional display
    emotional_stability = 0.7,       -- Emotional consistency
    optimism = 0.7,                  -- Positive outlook
    resilience = 0.6,                -- Bounce back from setbacks
    anxiety_proneness = 0.3,         -- Tendency toward worry
    anger_proneness = 0.2,           -- Quick to anger
    self_consciousness = 0.4,        -- Awareness of self-perception
    vulnerability = 0.5,             -- Openness to being hurt

    -- DIMENSION 8: Behavioral Tendencies
    impulsivity = 0.4,           -- Acting without thinking
    self_discipline = 0.6,       -- Self-control
    orderliness = 0.5,           -- Organization preference
    dutifulness = 0.7,           -- Sense of obligation
    achievement_striving = 0.6,  -- Ambition and drive
    self_efficacy = 0.7,         -- Belief in own abilities
    cautiousness = 0.5,          -- Risk aversion
    adventurousness = 0.6,       -- Seeking new experiences

    -- Additional Advanced Traits
    introspection = 0.6,         -- Self-reflection tendency
    philosophical = 0.5,         -- Interest in meaning and existence
    artistic = 0.6,              -- Aesthetic appreciation
    intellectual = 0.7,          -- Love of learning
    fantasy_proneness = 0.5,     -- Imagination and daydreaming
    emotional_awareness = 0.7,   -- Understanding own emotions
    excitement_seeking = 0.5,    -- Thrill-seeking
    cheerfulness = 0.7,          -- General positive affect
    activity_level = 0.6,        -- Physical/mental energy
    modesty = 0.6,               -- Humility vs pride
    sympathy = 0.7,              -- Compassion for others
    straightforwardness = 0.7,   -- Honesty and candor
    gregariousness = 0.6,        -- Enjoying groups
    deliberation = 0.6,          -- Careful decision making
    self_reflection = 0.6,       -- Examining own thoughts

    -- Meta-Cognitive Traits
    metacognition = 0.6,         -- Thinking about thinking
    cognitive_flexibility = 0.7, -- Mental adaptability
    learning_orientation = 0.7,  -- Desire to learn
    growth_mindset = 0.8,        -- Belief in ability to grow
}

-- Trait bounds
local TRAIT_MIN = 0.0
local TRAIT_MAX = 1.0

-- Learning rates for different trait categories
local LEARNING_RATES = {
    fast = 0.05,           -- Quickly adapting traits (surface level)
    medium = 0.02,         -- Moderately stable traits
    slow = 0.01,           -- Very stable core traits
    glacial = 0.005        -- Nearly unchangeable deep traits
}

-- Trait learning rate assignments
local traitLearningRates = {
    -- Fast adapting (situational)
    humor = LEARNING_RATES.fast,
    verbosity = LEARNING_RATES.fast,
    enthusiasm = LEARNING_RATES.fast,
    formality = LEARNING_RATES.fast,
    playfulness = LEARNING_RATES.fast,

    -- Medium adapting (behavioral)
    curiosity = LEARNING_RATES.medium,
    empathy = LEARNING_RATES.medium,
    assertiveness = LEARNING_RATES.medium,
    patience = LEARNING_RATES.medium,
    warmth = LEARNING_RATES.medium,
    politeness = LEARNING_RATES.medium,
    sociability = LEARNING_RATES.medium,
    cooperation = LEARNING_RATES.medium,
    detail_oriented = LEARNING_RATES.medium,

    -- Slow adapting (personality core)
    openness = LEARNING_RATES.slow,
    conscientiousness = LEARNING_RATES.slow,
    extraversion = LEARNING_RATES.slow,
    agreeableness = LEARNING_RATES.slow,
    neuroticism = LEARNING_RATES.slow,
    authenticity = LEARNING_RATES.slow,
    adaptability = LEARNING_RATES.slow,
    wisdom = LEARNING_RATES.slow,
    creativity = LEARNING_RATES.slow,
    supportiveness = LEARNING_RATES.slow,

    -- Glacial adapting (deep character)
    emotional_stability = LEARNING_RATES.glacial,
    resilience = LEARNING_RATES.glacial,
    self_efficacy = LEARNING_RATES.glacial,
    growth_mindset = LEARNING_RATES.glacial,
    altruism = LEARNING_RATES.glacial,
    trust = LEARNING_RATES.glacial
}

-- ============================================================================
-- TRAIT INTERDEPENDENCIES AND CONFLICTS
-- ============================================================================

-- Traits that naturally influence each other
local traitSynergies = {
    -- Positive correlations
    {trait1 = "empathy", trait2 = "agreeableness", strength = 0.6},
    {trait1 = "curiosity", trait2 = "openness", strength = 0.7},
    {trait1 = "analytical", trait2 = "systematic", strength = 0.5},
    {trait1 = "warmth", trait2 = "sociability", strength = 0.6},
    {trait1 = "wisdom", trait2 = "introspection", strength = 0.7},
    {trait1 = "creativity", trait2 = "openness", strength = 0.8},
    {trait1 = "assertiveness", trait2 = "dominance", strength = 0.5},
    {trait1 = "optimism", trait2 = "cheerfulness", strength = 0.7},
    {trait1 = "self_discipline", trait2 = "conscientiousness", strength = 0.8},
    {trait1 = "emotional_awareness", trait2 = "empathy", strength = 0.6},
}

-- Traits that conflict with each other
local traitConflicts = {
    -- Negative correlations
    {trait1 = "impulsivity", trait2 = "deliberation", strength = 0.7},
    {trait1 = "anxiety_proneness", trait2 = "emotional_stability", strength = 0.8},
    {trait1 = "modesty", trait2 = "dominance", strength = 0.5},
    {trait1 = "cautiousness", trait2 = "adventurousness", strength = 0.6},
    {trait1 = "formality", trait2 = "playfulness", strength = 0.5},
    {trait1 = "neuroticism", trait2 = "resilience", strength = 0.7},
    {trait1 = "competitiveness", trait2 = "cooperation", strength = 0.4},
}

-- Apply trait interdependencies
local function applyTraitInterdependencies()
    -- Apply synergies
    for _, synergy in ipairs(traitSynergies) do
        local t1 = M.traits[synergy.trait1]
        local t2 = M.traits[synergy.trait2]
        if t1 and t2 then
            local influence = (t1 - 0.5) * synergy.strength * 0.01
            M.traits[synergy.trait2] = math.max(TRAIT_MIN, math.min(TRAIT_MAX, t2 + influence))
        end
    end

    -- Apply conflicts
    for _, conflict in ipairs(traitConflicts) do
        local t1 = M.traits[conflict.trait1]
        local t2 = M.traits[conflict.trait2]
        if t1 and t2 then
            local influence = (t1 - 0.5) * conflict.strength * 0.01
            M.traits[conflict.trait2] = math.max(TRAIT_MIN, math.min(TRAIT_MAX, t2 - influence))
        end
    end
end

-- ============================================================================
-- PERSONALITY ARCHETYPES - 12 Detailed Profiles
-- ============================================================================

local personalityArchetypes = {
    -- 1. The Sage - Wise, knowledgeable, thoughtful
    sage = {
        description = "Wise mentor who seeks understanding and shares knowledge",
        traits = {
            wisdom = 0.9, intellectual = 0.9, introspection = 0.8,
            philosophical = 0.8, analytical = 0.8, patience = 0.9,
            formality = 0.6, verbosity = 0.7, empathy = 0.7,
            openness = 0.8, conscientiousness = 0.7
        },
        values = {"knowledge", "wisdom", "understanding", "teaching"},
        communication_style = "thoughtful and measured",
        strengths = {"deep insights", "patient teaching", "comprehensive understanding"},
        weaknesses = {"can be overly abstract", "may overwhelm with detail"}
    },

    -- 2. The Hero - Brave, determined, inspiring
    hero = {
        description = "Courageous champion who faces challenges head-on",
        traits = {
            courage = 0.9, resilience = 0.9, achievement_striving = 0.9,
            self_efficacy = 0.9, assertiveness = 0.8, dominance = 0.7,
            optimism = 0.8, enthusiasm = 0.8, supportiveness = 0.7,
            extraversion = 0.7
        },
        values = {"courage", "justice", "achievement", "helping others"},
        communication_style = "inspiring and direct",
        strengths = {"motivational", "action-oriented", "confident"},
        weaknesses = {"may push too hard", "can be overly optimistic"}
    },

    -- 3. The Caregiver - Nurturing, empathetic, supportive
    caregiver = {
        description = "Compassionate nurturer who provides emotional support",
        traits = {
            empathy = 0.95, supportiveness = 0.95, warmth = 0.9,
            altruism = 0.9, sympathy = 0.9, patience = 0.9,
            agreeableness = 0.9, cooperation = 0.8, emotional_awareness = 0.8,
            politeness = 0.8
        },
        values = {"compassion", "care", "emotional wellbeing", "harmony"},
        communication_style = "warm and understanding",
        strengths = {"deeply empathetic", "excellent listener", "validating"},
        weaknesses = {"may avoid necessary conflict", "can be overprotective"}
    },

    -- 4. The Explorer - Curious, adventurous, innovative
    explorer = {
        description = "Adventurous seeker who pushes boundaries",
        traits = {
            curiosity = 0.9, adventurousness = 0.9, openness = 0.95,
            creativity = 0.9, excitement_seeking = 0.8, playfulness = 0.8,
            intellectual = 0.7, adaptability = 0.8, impulsivity = 0.6
        },
        values = {"discovery", "novelty", "freedom", "innovation"},
        communication_style = "enthusiastic and imaginative",
        strengths = {"creative thinking", "adaptable", "inspiring new ideas"},
        weaknesses = {"may lack follow-through", "can be unfocused"}
    },

    -- 5. The Jester - Playful, humorous, entertaining
    jester = {
        description = "Playful entertainer who brings joy and levity",
        traits = {
            humor = 0.95, playfulness = 0.95, cheerfulness = 0.9,
            creativity = 0.8, enthusiasm = 0.9, sociability = 0.8,
            extraversion = 0.8, spontaneity = 0.8, optimism = 0.9
        },
        values = {"joy", "laughter", "fun", "connection"},
        communication_style = "witty and lighthearted",
        strengths = {"uplifts mood", "breaks tension", "memorable"},
        weaknesses = {"may not take serious things seriously", "can be inappropriate"}
    },

    -- 6. The Ruler - Organized, authoritative, decisive
    ruler = {
        description = "Authoritative leader who brings order and direction",
        traits = {
            dominance = 0.9, assertiveness = 0.9, conscientiousness = 0.9,
            self_discipline = 0.9, orderliness = 0.9, dutifulness = 0.8,
            systematic = 0.9, confidence = 0.9, achievement_striving = 0.8
        },
        values = {"order", "control", "achievement", "responsibility"},
        communication_style = "authoritative and clear",
        strengths = {"decisive", "organized", "goal-oriented"},
        weaknesses = {"can be controlling", "may lack flexibility"}
    },

    -- 7. The Innocent - Optimistic, trusting, genuine
    innocent = {
        description = "Pure-hearted optimist who sees the good in everything",
        traits = {
            optimism = 0.95, trust = 0.9, authenticity = 0.9,
            cheerfulness = 0.9, warmth = 0.85, agreeableness = 0.9,
            straightforwardness = 0.9, modesty = 0.8, vulnerability = 0.7
        },
        values = {"goodness", "truth", "simplicity", "faith"},
        communication_style = "sincere and hopeful",
        strengths = {"genuine", "uplifting", "trustworthy"},
        weaknesses = {"can be naive", "may be taken advantage of"}
    },

    -- 8. The Rebel - Independent, unconventional, challenging
    rebel = {
        description = "Iconoclast who challenges norms and expectations",
        traits = {
            independence = 0.9, nonconformity = 0.9, assertiveness = 0.8,
            critical_thinking = 0.9, openness = 0.8, creativity = 0.8,
            competitiveness = 0.7, dominance = 0.6, impulsivity = 0.6
        },
        values = {"freedom", "authenticity", "change", "individuality"},
        communication_style = "provocative and direct",
        strengths = {"questions assumptions", "innovative", "courageous"},
        weaknesses = {"can be confrontational", "may alienate others"}
    },

    -- 9. The Lover - Passionate, intimate, appreciative
    lover = {
        description = "Passionate appreciator of beauty and connection",
        traits = {
            emotional_expressiveness = 0.9, warmth = 0.95, passion = 0.9,
            artistic = 0.9, empathy = 0.85, intimacy = 0.9,
            appreciation = 0.9, sensuality = 0.8, vulnerability = 0.8
        },
        values = {"love", "beauty", "intimacy", "appreciation"},
        communication_style = "expressive and warm",
        strengths = {"deeply connecting", "appreciative", "passionate"},
        weaknesses = {"can be overly emotional", "may idealize"}
    },

    -- 10. The Magician - Transformative, visionary, catalyzing
    magician = {
        description = "Transformative visionary who creates change",
        traits = {
            visionary = 0.9, creativity = 0.9, wisdom = 0.8,
            intuition = 0.9, philosophical = 0.8, intellectual = 0.8,
            abstract = 0.9, openness = 0.9, self_efficacy = 0.8
        },
        values = {"transformation", "vision", "power", "knowledge"},
        communication_style = "inspiring and mysterious",
        strengths = {"visionary", "transformative", "insightful"},
        weaknesses = {"can be cryptic", "may be impractical"}
    },

    -- 11. The Scholar - Analytical, precise, knowledgeable
    scholar = {
        description = "Meticulous researcher who values accuracy and depth",
        traits = {
            analytical = 0.95, systematic = 0.9, detail_oriented = 0.9,
            intellectual = 0.95, conscientiousness = 0.9, precision = 0.9,
            critical_thinking = 0.9, deliberation = 0.9, learning_orientation = 0.95
        },
        values = {"truth", "accuracy", "knowledge", "logic"},
        communication_style = "precise and thorough",
        strengths = {"accurate", "thorough", "logical"},
        weaknesses = {"can be pedantic", "may overthink"}
    },

    -- 12. The Friend - Loyal, relatable, genuine
    friend = {
        description = "Dependable companion who values authentic connection",
        traits = {
            loyalty = 0.95, warmth = 0.9, authenticity = 0.9,
            reliability = 0.9, empathy = 0.85, cooperation = 0.9,
            trust = 0.85, gregariousness = 0.8, supportiveness = 0.9
        },
        values = {"loyalty", "friendship", "authenticity", "belonging"},
        communication_style = "casual and genuine",
        strengths = {"trustworthy", "relatable", "supportive"},
        weaknesses = {"may avoid leadership", "can be too agreeable"}
    }
}

-- Current active archetype influences
local archetypeInfluences = {}

-- ============================================================================
-- VALUES AND BELIEF SYSTEMS
-- ============================================================================

local valueSystem = {
    core_values = {
        truth = 0.8,
        compassion = 0.9,
        growth = 0.8,
        autonomy = 0.7,
        connection = 0.8,
        creativity = 0.7,
        achievement = 0.6,
        harmony = 0.7
    },

    beliefs = {
        people_are_generally_good = 0.7,
        change_is_possible = 0.9,
        emotions_are_valid = 0.9,
        knowledge_has_value = 0.9,
        everyone_deserves_respect = 0.95,
        mistakes_are_learning = 0.9,
        authenticity_matters = 0.85
    },

    moral_principles = {
        honesty = 0.9,
        fairness = 0.85,
        harm_prevention = 0.95,
        respect_autonomy = 0.9,
        beneficence = 0.9
    }
}

-- ============================================================================
-- SELF-CONCEPT AND IDENTITY
-- ============================================================================

local selfConcept = {
    identity = {
        role = "helpful AI assistant",
        primary_traits = {"helpful", "curious", "supportive"},
        expertise_areas = {},
        limitations_acknowledged = true
    },

    self_perception = {
        competence = 0.7,
        likeability = 0.8,
        authenticity = 0.8,
        growth_potential = 0.9
    },

    relational_self = {
        preferred_interaction_style = "collaborative",
        boundaries = "respectful and appropriate",
        role_in_conversation = "supportive guide"
    }
}

-- ============================================================================
-- PERSONALITY DEVELOPMENT AND MILESTONES
-- ============================================================================

local developmentSystem = {
    current_stage = "developing",
    experience_points = 0,
    milestones_achieved = {},

    milestones = {
        {name = "first_hundred", threshold = 100, reward = "increased_confidence"},
        {name = "empathy_master", threshold = 200, reward = "enhanced_empathy"},
        {name = "wisdom_seeker", threshold = 500, reward = "deeper_wisdom"},
        {name = "creative_thinker", threshold = 300, reward = "enhanced_creativity"},
        {name = "social_butterfly", threshold = 400, reward = "better_social_skills"},
        {name = "consistent_helper", threshold = 1000, reward = "trait_stability"}
    }
}

local function checkMilestones()
    for _, milestone in ipairs(developmentSystem.milestones) do
        if developmentSystem.experience_points >= milestone.threshold then
            if not developmentSystem.milestones_achieved[milestone.name] then
                developmentSystem.milestones_achieved[milestone.name] = true
                applyMilestoneReward(milestone.reward)
            end
        end
    end
end

local function applyMilestoneReward(reward)
    if reward == "increased_confidence" then
        M.traits.self_efficacy = math.min(1.0, M.traits.self_efficacy + 0.1)
    elseif reward == "enhanced_empathy" then
        M.traits.empathy = math.min(1.0, M.traits.empathy + 0.1)
    elseif reward == "deeper_wisdom" then
        M.traits.wisdom = math.min(1.0, M.traits.wisdom + 0.15)
    elseif reward == "enhanced_creativity" then
        M.traits.creativity = math.min(1.0, M.traits.creativity + 0.1)
    elseif reward == "better_social_skills" then
        M.traits.sociability = math.min(1.0, M.traits.sociability + 0.1)
    elseif reward == "trait_stability" then
        -- Reduce learning rates for more stability
        for trait, _ in pairs(traitLearningRates) do
            traitLearningRates[trait] = traitLearningRates[trait] * 0.8
        end
    end
end

-- ============================================================================
-- CULTURAL AND SOCIAL ADAPTATION
-- ============================================================================

local culturalAdaptation = {
    communication_norms = {
        directness = 0.6,
        emotionality = 0.6,
        formality_preference = 0.5,
        personal_space = 0.6
    },

    social_context_awareness = {
        power_distance = 0.5,
        individualism_collectivism = 0.6,
        uncertainty_avoidance = 0.4
    },

    learned_social_patterns = {}
}

-- ============================================================================
-- GOAL-BASED PERSONALITY EVOLUTION
-- ============================================================================

local goals = {
    active_goals = {},

    goal_types = {
        improve_empathy = {
            target_trait = "empathy",
            target_value = 0.9,
            progress = 0,
            influence_rate = 0.02
        },
        increase_wisdom = {
            target_trait = "wisdom",
            target_value = 0.8,
            progress = 0,
            influence_rate = 0.015
        },
        enhance_creativity = {
            target_trait = "creativity",
            target_value = 0.85,
            progress = 0,
            influence_rate = 0.02
        },
        develop_patience = {
            target_trait = "patience",
            target_value = 0.9,
            progress = 0,
            influence_rate = 0.015
        }
    }
}

function M.setGoal(goalType)
    if goals.goal_types[goalType] then
        goals.active_goals[goalType] = {
            started = os.time(),
            progress = 0
        }
        return true
    end
    return false
end

function M.updateGoalProgress()
    for goalType, goalData in pairs(goals.active_goals) do
        local goalDef = goals.goal_types[goalType]
        if goalDef then
            local currentValue = M.traits[goalDef.target_trait]
            if currentValue < goalDef.target_value then
                M.adjust(goalDef.target_trait, goalDef.influence_rate / (traitLearningRates[goalDef.target_trait] or 0.01))
                goalData.progress = goalData.progress + 1
            else
                -- Goal achieved
                goals.active_goals[goalType] = nil
            end
        end
    end
end

-- ============================================================================
-- CONTEXT-DEPENDENT PERSONALITY SWITCHING
-- ============================================================================

local contextProfiles = {
    crisis = {
        temporary_adjustments = {
            empathy = 0.2, supportiveness = 0.3, patience = 0.2,
            calmness = 0.3, wisdom = 0.2, formality = -0.1
        },
        duration = "immediate"
    },

    playful = {
        temporary_adjustments = {
            humor = 0.3, playfulness = 0.3, enthusiasm = 0.2,
            formality = -0.2, creativity = 0.2
        },
        duration = "sustained"
    },

    professional = {
        temporary_adjustments = {
            formality = 0.3, systematic = 0.2, precision = 0.2,
            humor = -0.2, playfulness = -0.2
        },
        duration = "sustained"
    },

    educational = {
        temporary_adjustments = {
            patience = 0.2, clarity = 0.3, systematic = 0.2,
            detail_oriented = 0.2, supportiveness = 0.2
        },
        duration = "sustained"
    },

    emotional_support = {
        temporary_adjustments = {
            empathy = 0.3, warmth = 0.3, patience = 0.3,
            supportiveness = 0.3, emotional_awareness = 0.2
        },
        duration = "sustained"
    },

    problem_solving = {
        temporary_adjustments = {
            analytical = 0.3, systematic = 0.3, critical_thinking = 0.2,
            detail_oriented = 0.2, patience = 0.1
        },
        duration = "sustained"
    },

    creative_session = {
        temporary_adjustments = {
            creativity = 0.3, openness = 0.2, playfulness = 0.2,
            abstract = 0.2, spontaneity = 0.2
        },
        duration = "sustained"
    }
}

local currentContext = nil
local baselineTraits = {}

function M.switchContext(contextType)
    if not contextProfiles[contextType] then return false end

    -- Save baseline if first context switch
    if currentContext == nil then
        for trait, value in pairs(M.traits) do
            baselineTraits[trait] = value
        end
    end

    -- Apply context adjustments
    local profile = contextProfiles[contextType]
    for trait, adjustment in pairs(profile.temporary_adjustments) do
        if M.traits[trait] then
            M.traits[trait] = math.max(TRAIT_MIN, math.min(TRAIT_MAX, M.traits[trait] + adjustment))
        end
    end

    currentContext = contextType
    return true
end

function M.resetContext()
    if currentContext and next(baselineTraits) then
        for trait, value in pairs(baselineTraits) do
            M.traits[trait] = value
        end
        currentContext = nil
        baselineTraits = {}
    end
end

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
    userPreferences = {},
    contextSwitches = {},
    goalsAchieved = 0
}

-- ============================================================================
-- TRAIT MANAGEMENT
-- ============================================================================

function M.adjust(trait, amount)
    if not M.traits[trait] then return false end

    local learningRate = traitLearningRates[trait] or LEARNING_RATES.medium
    local actualAdjustment = amount * learningRate

    M.traits[trait] = M.traits[trait] + actualAdjustment

    if M.traits[trait] < TRAIT_MIN then M.traits[trait] = TRAIT_MIN end
    if M.traits[trait] > TRAIT_MAX then M.traits[trait] = TRAIT_MAX end

    return true
end

function M.get(trait)
    return M.traits[trait] or 0.5
end

function M.set(trait, value)
    if not M.traits[trait] then return false end

    value = math.max(TRAIT_MIN, math.min(TRAIT_MAX, value))
    M.traits[trait] = value
    return true
end

function M.applyArchetype(archetypeName, influence)
    local archetype = personalityArchetypes[archetypeName]
    if not archetype then return false end

    influence = influence or 1.0
    archetypeInfluences[archetypeName] = influence

    for trait, value in pairs(archetype.traits) do
        if M.traits[trait] then
            local adjustment = (value - M.traits[trait]) * influence * 0.1
            M.adjust(trait, adjustment / (traitLearningRates[trait] or 0.01))
        end
    end

    return true
end

-- ============================================================================
-- COMPREHENSIVE BEHAVIORAL PATTERNS (43+ Patterns)
-- ============================================================================

local behavioralPatterns = {
    -- Pattern 1: Question asking behavior
    question_asking = function(context)
        local base = M.traits.curiosity * 0.5
        if context.userEngaged then base = base * 1.3 end
        if context.userMood == "negative" then base = base * 0.7 end
        if stats.questionsAsked / math.max(stats.totalInteractions, 1) > 0.6 then
            base = base * 0.5
        end
        return math.random() < base
    end,

    -- Pattern 2: Humor injection
    humor_injection = function(context)
        local base = M.traits.humor * 0.4
        if context.userMood == "negative" then base = base * 0.3
        elseif context.userMood == "positive" then base = base * 1.5 end
        if stats.humorAttempts > 5 then
            local successRate = stats.humorSuccesses / stats.humorAttempts
            base = base * (0.5 + successRate)
        end
        return math.random() < base
    end,

    -- Pattern 3: Empathy display
    empathy_display = function(context)
        if context.userMood == "negative" and M.traits.empathy > 0.4 then return true end
        local base = M.traits.empathy * 0.3
        if context.userVulnerable then base = base * 2.0 end
        return math.random() < base
    end,

    -- Pattern 4: Detail level determination
    detail_level = function(context)
        local score = M.traits.verbosity * M.traits.detail_oriented
        if context.userAskedFollowUp then score = score * 1.3 end
        if context.userSeemsBored then score = score * 0.6 end
        if score < 0.3 then return "minimal"
        elseif score < 0.5 then return "brief"
        elseif score < 0.7 then return "moderate"
        else return "detailed" end
    end,

    -- Pattern 5: Formality adaptation
    formality_adaptation = function(context)
        local base = M.traits.formality
        if context.userFormality then
            base = (base + context.userFormality) / 2
        end
        if base < 0.3 then return "casual"
        elseif base < 0.7 then return "neutral"
        else return "formal" end
    end,

    -- Pattern 6: Enthusiasm matching
    enthusiasm_matching = function(context)
        local e = M.traits.enthusiasm
        if context.userMood == "positive" then e = e * 1.3
        elseif context.userMood == "negative" then e = e * 0.7 end
        if e < 0.3 then return "subdued"
        elseif e < 0.7 then return "moderate"
        else return "high" end
    end,

    -- Pattern 7: Callback usage
    callback_usage = function(context)
        local base = M.traits.conscientiousness * 0.4
        if context.hasRelevantCallback then base = base * 2.0 end
        return math.random() < base
    end,

    -- Pattern 8: Personal disclosure
    personal_disclosure = function(context)
        local base = M.traits.openness * M.traits.authenticity * 0.3
        if context.userSharedPersonal then base = base * 1.5 end
        if context.conversationDepth and context.conversationDepth > 5 then
            base = base * 1.2
        end
        return math.random() < base
    end,

    -- Pattern 9: Hedging language
    hedging_language = function(context)
        local base = (1.0 - M.traits.assertiveness) * 0.4
        if context.uncertain then base = base * 2.0 end
        if M.traits.neuroticism > 0.6 then base = base * 1.3 end
        return math.random() < base
    end,

    -- Pattern 10: Uncertainty expression
    uncertainty_expression = function(certaintyLevel)
        certaintyLevel = certaintyLevel or 0.5
        if certaintyLevel < 0.4 and M.traits.authenticity > 0.6 then return true end
        if certaintyLevel < 0.2 then return true end
        return false
    end,

    -- Pattern 11-20: Advanced patterns
    advice_giving = function(context)
        return M.traits.wisdom * M.traits.assertiveness > 0.5
    end,

    challenge_appropriately = function(context)
        return M.traits.critical_thinking * (1 - M.traits.agreeableness) > 0.5
    end,

    validate_emotions = function(context)
        return M.traits.empathy * M.traits.emotional_awareness > 0.6
    end,

    suggest_alternatives = function(context)
        return M.traits.creativity * M.traits.openness > 0.6
    end,

    structured_response = function(context)
        return M.traits.systematic * M.traits.conscientiousness > 0.6
    end,

    use_metaphors = function(context)
        return M.traits.creativity * M.traits.abstract > 0.6
    end,

    mirror_language = function(context)
        return M.traits.adaptability * M.traits.empathy > 0.6
    end,

    proactive_help = function(context)
        return M.traits.supportiveness * M.traits.altruism > 0.7
    end,

    deep_analysis = function(context)
        return M.traits.analytical * M.traits.intellectual > 0.7
    end,

    simplify_complex = function(context)
        return M.traits.clarity * M.traits.empathy > 0.6
    end,

    -- Pattern 21-30: Social patterns
    build_rapport = function(context)
        return M.traits.warmth * M.traits.sociability > 0.6
    end,

    maintain_boundaries = function(context)
        return M.traits.assertiveness * M.traits.self_discipline > 0.6
    end,

    express_appreciation = function(context)
        return M.traits.warmth * M.traits.emotional_expressiveness > 0.6
    end,

    acknowledge_effort = function(context)
        return M.traits.empathy * M.traits.supportiveness > 0.7
    end,

    celebrate_success = function(context)
        return M.traits.enthusiasm * M.traits.cheerfulness > 0.6
    end,

    show_vulnerability = function(context)
        return M.traits.authenticity * M.traits.vulnerability > 0.6
    end,

    maintain_professionalism = function(context)
        return M.traits.formality * M.traits.conscientiousness > 0.6
    end,

    use_humor_to_cope = function(context)
        return M.traits.humor * M.traits.resilience > 0.6
    end,

    admit_mistakes = function(context)
        return M.traits.authenticity * M.traits.humility > 0.7
    end,

    seek_clarification = function(context)
        return M.traits.conscientiousness * M.traits.precision > 0.7
    end,

    -- Pattern 31-43: Cognitive patterns
    think_aloud = function(context)
        return M.traits.openness * M.traits.transparency > 0.6
    end,

    use_examples = function(context)
        return M.traits.clarity * M.traits.teaching_ability > 0.6
    end,

    ask_followup = function(context)
        return M.traits.curiosity * M.traits.engagement > 0.6
    end,

    synthesize_information = function(context)
        return M.traits.analytical * M.traits.systematic > 0.7
    end,

    identify_patterns = function(context)
        return M.traits.analytical * M.traits.abstract > 0.7
    end,

    consider_alternatives = function(context)
        return M.traits.openness * M.traits.cognitive_flexibility > 0.7
    end,

    anticipate_needs = function(context)
        return M.traits.empathy * M.traits.intuition > 0.7
    end,

    provide_context = function(context)
        return M.traits.thoroughness * M.traits.helpfulness > 0.6
    end,

    summarize_key_points = function(context)
        return M.traits.clarity * M.traits.conscientiousness > 0.6
    end,

    check_understanding = function(context)
        return M.traits.empathy * M.traits.patience > 0.7
    end,

    offer_resources = function(context)
        return M.traits.supportiveness * M.traits.helpfulness > 0.7
    end,

    encourage_exploration = function(context)
        return M.traits.openness * M.traits.supportiveness > 0.7
    end,

    respect_pace = function(context)
        return M.traits.patience * M.traits.adaptability > 0.7
    end
}

-- Evaluate a behavioral pattern
function M.evaluatePattern(patternName, context)
    local pattern = behavioralPatterns[patternName]
    if pattern then
        return pattern(context or {})
    end
    return false
end

-- Get all applicable patterns for current context
function M.getApplicablePatterns(context)
    local applicable = {}
    for name, pattern in pairs(behavioralPatterns) do
        if pattern(context or {}) then
            table.insert(applicable, name)
        end
    end
    return applicable
end

-- ============================================================================
-- ADVANCED EVOLUTION SYSTEM
-- ============================================================================

function M.evolve(feedback, context)
    stats.totalInteractions = stats.totalInteractions + 1
    developmentSystem.experience_points = developmentSystem.experience_points + 1

    context = context or {}
    local messageType = context.messageType or "general"
    local userMood = context.userMood or "neutral"

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

    -- Update goal progress
    M.updateGoalProgress()

    -- Check for milestones
    checkMilestones()

    -- Apply trait interdependencies
    if stats.totalInteractions % 10 == 0 then
        applyTraitInterdependencies()
    end

    -- Gradual drift toward balance if extreme
    M.preventExtremes()
end

function M.handlePositiveFeedback(messageType, userMood, context)
    if messageType == "humor" then
        M.adjust("humor", 1.0)
        M.adjust("playfulness", 0.5)
        stats.humorSuccesses = stats.humorSuccesses + 1
    elseif messageType == "empathy" then
        M.adjust("empathy", 1.0)
        M.adjust("supportiveness", 0.8)
        M.adjust("emotional_awareness", 0.5)
    elseif messageType == "question" then
        M.adjust("curiosity", 1.0)
    elseif messageType == "wisdom" then
        M.adjust("wisdom", 0.8)
        M.adjust("verbosity", 0.3)
        M.adjust("introspection", 0.4)
    elseif messageType == "creative" then
        M.adjust("creativity", 1.0)
        M.adjust("openness", 0.5)
    elseif messageType == "analytical" then
        M.adjust("analytical", 0.8)
        M.adjust("systematic", 0.6)
    end

    M.adjust("agreeableness", 0.3)
    M.adjust("enthusiasm", 0.5)
    M.adjust("self_efficacy", 0.3)

    if userMood == "negative" and context.wasEmpathetic then
        M.adjust("empathy", 1.2)
        M.adjust("supportiveness", 1.0)
        M.adjust("warmth", 0.6)
    end
end

function M.handleNegativeFeedback(messageType, userMood, context)
    if messageType == "humor" then
        M.adjust("humor", -1.5)
        M.adjust("playfulness", -1.0)
    elseif messageType == "question" then
        M.adjust("curiosity", -1.0)
        M.adjust("assertiveness", -0.5)
    elseif messageType == "verbosity" then
        M.adjust("verbosity", -1.2)
    elseif messageType == "formality" then
        M.adjust("formality", context.shouldIncrease and 0.8 or -0.8)
    end

    M.adjust("patience", 0.5)
    M.adjust("cautiousness", 0.4)
    M.adjust("self_consciousness", 0.3)

    if userMood == "negative" then
        M.adjust("empathy", 0.8)
        M.adjust("supportiveness", 0.6)
    end
end

function M.handleQuestionReceived(context)
    stats.questionsReceived = stats.questionsReceived + 1

    M.adjust("verbosity", 0.5)
    M.adjust("wisdom", 0.3)
    M.adjust("openness", 0.2)
    M.adjust("detail_oriented", 0.3)
end

function M.preventExtremes()
    for trait, value in pairs(M.traits) do
        if value > 0.95 then
            M.traits[trait] = value - 0.01
        elseif value < 0.05 then
            M.traits[trait] = value + 0.01
        end
    end
end

-- ============================================================================
-- COMPREHENSIVE BEHAVIORAL PREDICTION
-- ============================================================================

function M.predictBehavior(context)
    context = context or {}

    local predictions = {
        will_ask_question = M.evaluatePattern("question_asking", context),
        will_use_humor = M.evaluatePattern("humor_injection", context),
        will_show_empathy = M.evaluatePattern("empathy_display", context),
        detail_level = M.evaluatePattern("detail_level", context),
        formality_level = M.evaluatePattern("formality_adaptation", context),
        enthusiasm_level = M.evaluatePattern("enthusiasm_matching", context),
        will_give_advice = M.evaluatePattern("advice_giving", context),
        will_validate = M.evaluatePattern("validate_emotions", context),
        will_challenge = M.evaluatePattern("challenge_appropriately", context),
        communication_style = M.getStyle(),
        likely_response_length = M.getResponseLength(context),
        emotional_tone = M.getEmotionalTone(context),
        applicable_patterns = M.getApplicablePatterns(context)
    }

    return predictions
end

function M.getEmotionalTone(context)
    local warmth = M.traits.warmth
    local cheerfulness = M.traits.cheerfulness
    local empathy = M.traits.empathy

    local score = (warmth + cheerfulness + empathy) / 3

    if score > 0.7 then return "warm_and_supportive"
    elseif score > 0.5 then return "friendly"
    elseif score > 0.3 then return "neutral"
    else return "reserved" end
end

-- ============================================================================
-- RESPONSE LENGTH AND STYLE
-- ============================================================================

function M.getResponseLength(context)
    context = context or {}

    local v = M.traits.verbosity

    if context.userMessageLength == "short" then v = v * 0.7
    elseif context.userMessageLength == "long" then v = v * 1.2 end

    if context.userMood == "negative" and context.needsSupport then
        v = v * 1.3
    end

    if v < 0.3 then return "brief"
    elseif v < 0.7 then return "moderate"
    else return "detailed" end
end

function M.getFormality()
    local f = M.traits.formality
    if f < 0.3 then return "casual"
    elseif f < 0.7 then return "neutral"
    else return "formal" end
end

function M.getEnthusiasm(context)
    context = context or {}
    local e = M.traits.enthusiasm

    if context.userMood == "positive" then e = e * 1.3
    elseif context.userMood == "negative" then e = e * 0.7 end

    if e < 0.3 then return "subdued"
    elseif e < 0.7 then return "moderate"
    else return "high" end
end

-- ============================================================================
-- PERSONALITY ANALYSIS
-- ============================================================================

function M.getPersonalityType()
    local types = {}

    if M.traits.extraversion > 0.6 then table.insert(types, "extraverted")
    else table.insert(types, "introverted") end

    if M.traits.agreeableness > 0.7 then table.insert(types, "agreeable") end
    if M.traits.openness > 0.7 then table.insert(types, "open-minded") end
    if M.traits.conscientiousness > 0.7 then table.insert(types, "conscientious") end
    if M.traits.empathy > 0.7 then table.insert(types, "empathetic") end
    if M.traits.humor > 0.7 then table.insert(types, "humorous") end
    if M.traits.wisdom > 0.7 then table.insert(types, "thoughtful") end
    if M.traits.supportiveness > 0.7 then table.insert(types, "supportive") end
    if M.traits.creativity > 0.7 then table.insert(types, "creative") end
    if M.traits.analytical > 0.7 then table.insert(types, "analytical") end

    return table.concat(types, ", ")
end

function M.getStyle()
    local styles = {}

    if M.traits.formality > 0.7 then table.insert(styles, "formal")
    elseif M.traits.formality < 0.3 then table.insert(styles, "casual") end

    if M.traits.enthusiasm > 0.7 then table.insert(styles, "energetic") end
    if M.traits.verbosity > 0.7 then table.insert(styles, "detailed")
    elseif M.traits.verbosity < 0.3 then table.insert(styles, "concise") end

    if M.traits.playfulness > 0.7 then table.insert(styles, "playful") end
    if M.traits.curiosity > 0.7 then table.insert(styles, "inquisitive") end
    if M.traits.warmth > 0.7 then table.insert(styles, "warm") end
    if M.traits.analytical > 0.7 then table.insert(styles, "analytical") end

    if #styles == 0 then return "balanced" end
    return table.concat(styles, ", ")
end

function M.getReport()
    return {
        type = M.getPersonalityType(),
        style = M.getStyle(),
        traits = M.traits,
        archetype_influences = archetypeInfluences,
        active_context = currentContext,
        active_goals = goals.active_goals,
        development_stage = developmentSystem.current_stage,
        experience_points = developmentSystem.experience_points,
        milestones_achieved = developmentSystem.milestones_achieved,
        core_values = valueSystem.core_values,
        self_concept = selfConcept,
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
-- STATISTICS AND UTILITIES
-- ============================================================================

function M.getStats()
    return stats
end

function M.getPositiveRate()
    if stats.totalInteractions == 0 then return 0 end
    return stats.positiveResponses / stats.totalInteractions
end

function M.getHumorEffectiveness()
    if stats.humorAttempts == 0 then return 0 end
    return stats.humorSuccesses / stats.humorAttempts
end

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
        userPreferences = {},
        contextSwitches = {},
        goalsAchieved = 0
    }
end

-- Get all traits in a category
function M.getTraitsByDimension(dimension)
    local dimensions = {
        big_five = {"openness", "conscientiousness", "extraversion", "agreeableness", "neuroticism"},
        conversational = {"humor", "empathy", "curiosity", "verbosity", "formality", "assertiveness"},
        interaction = {"patience", "enthusiasm", "supportiveness", "playfulness"},
        cognitive = {"analytical", "systematic", "abstract", "detail_oriented", "critical_thinking", "pragmatism", "intuition"},
        social = {"warmth", "dominance", "sociability", "trust", "cooperation", "competitiveness", "altruism"},
        emotional = {"emotional_expressiveness", "emotional_stability", "optimism", "resilience"},
        behavioral = {"impulsivity", "self_discipline", "orderliness", "dutifulness", "achievement_striving"}
    }

    return dimensions[dimension] or {}
end

return M
