-- Module: main_logic.lua
-- Advanced conversational AI with deep contextual understanding

local M = {}

-- Load dependencies
local utils = require("utils")
local personality = require("personality")
local mood = require("mood")
local responses = require("responses")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local BOT_NAME = "SuperAI"
local DEFAULT_USER = "User"
local VERSION = "2.0 Advanced"

-- ============================================================================
-- ADVANCED MEMORY SYSTEM
-- ============================================================================

local memory = {
    users = {},
    conversations = {},
    context = {},
    learned = {},
    relationships = {},
    chatColor = colors and colors.cyan or 6
}

local MAX_CONTEXT = 15
local MAX_CONVERSATION_HISTORY = 50

-- Initialize comprehensive user profile
local function initUser(username)
    if not memory.users[username] then
        memory.users[username] = {
            nickname = username,
            joinedAt = os.time(),
            lastSeen = os.time(),
            totalInteractions = 0,
            preferences = {
                responseLength = "moderate",
                formality = "casual",
                needsSupport = false
            },
            emotionalProfile = {
                baseline = {valence = 0, arousal = 0},
                currentState = "neutral",
                volatility = 0
            },
            conversationStyle = {
                asksQuestions = false,
                sharesPersonal = false,
                sendsLongMessages = false,
                usesHumor = false
            },
            topics = {},
            relationshipLevel = 1  -- 1-5 scale of familiarity
        }
    end
    
    memory.users[username].lastSeen = os.time()
    return memory.users[username]
end

-- Update user's conversation style
local function updateConversationStyle(user, message)
    local userData = memory.users[user]
    if not userData then return end
    
    local style = userData.conversationStyle
    
    -- Track question asking
    if utils.isQuestion(message) then
        style.asksQuestions = true
    end
    
    -- Track personal sharing
    if message:lower():find("i feel") or message:lower():find("i think") or 
       message:lower():find("i'm ") or message:lower():find("my ") then
        style.sharesPersonal = true
    end
    
    -- Track message length preference
    if #message > 100 then
        style.sendsLongMessages = true
    end
    
    -- Track humor usage
    if message:find("haha") or message:find("lol") or message:find("😂") then
        style.usesHumor = true
    end
end

-- Update relationship level
local function updateRelationship(user)
    local userData = memory.users[user]
    if not userData then return end
    
    local interactions = userData.totalInteractions
    
    -- Relationship grows with interaction
    if interactions > 50 then
        userData.relationshipLevel = 5
    elseif interactions > 30 then
        userData.relationshipLevel = 4
    elseif interactions > 15 then
        userData.relationshipLevel = 3
    elseif interactions > 5 then
        userData.relationshipLevel = 2
    else
        userData.relationshipLevel = 1
    end
end

-- ============================================================================
-- CONTEXT MANAGEMENT
-- ============================================================================

-- Add to conversation context with rich metadata
local function addToContext(user, message, response, metadata)
    metadata = metadata or {}
    
    table.insert(memory.context, {
        user = user,
        message = message,
        response = response,
        intent = metadata.intent,
        category = metadata.category,
        mood = metadata.mood,
        emotions = metadata.emotions,
        topics = metadata.topics,
        timestamp = os.time()
    })
    
    while #memory.context > MAX_CONTEXT do
        table.remove(memory.context, 1)
    end
end

-- Get recent conversation context
local function getRecentContext(user, limit)
    limit = limit or 5
    local userContext = {}
    
    for i = #memory.context, 1, -1 do
        if memory.context[i].user == user then
            table.insert(userContext, 1, memory.context[i])
            if #userContext >= limit then break end
        end
    end
    
    return userContext
end

-- Detect conversation topic shift
local function hasTopicShifted(user, currentTopics)
    local recentContext = getRecentContext(user, 3)
    if #recentContext < 2 then return false end
    
    local previousTopics = recentContext[#recentContext - 1].topics or {}
    
    -- Check for topic overlap
    local overlap = 0
    for _, prevTopic in ipairs(previousTopics) do
        for _, currTopic in ipairs(currentTopics) do
            if prevTopic == currTopic then
                overlap = overlap + 1
            end
        end
    end
    
    return overlap == 0 and #previousTopics > 0
end

-- ============================================================================
-- ADVANCED INTENT DETECTION
-- ============================================================================

local intentPatterns = {
    greeting = {
        priority = 1,
        patterns = {"^hi+$", "^hello", "^hey+", "^greetings", "^sup", "^yo+", "^howdy"},
        requires_start = true
    },
    
    farewell = {
        priority = 1,
        patterns = {"^bye", "^goodbye", "^see you", "^gotta go", "^later", "^take care", "^good night", "^goodnight"},
        requires_start = true
    },
    
    gratitude = {
        priority = 2,
        patterns = {"thank you", "thanks", "thx", "ty", "appreciate", "grateful"},
        requires_start = false
    },
    
    apology = {
        priority = 2,
        patterns = {"sorry", "my bad", "apologize", "my fault"},
        requires_start = false
    },
    
    agreement = {
        priority = 3,
        patterns = {"^yes$", "^yeah$", "^yep$", "^yup$", "^sure$", "^okay$", "^ok$", "i agree", "exactly", "absolutely"},
        requires_start = false
    },
    
    disagreement = {
        priority = 3,
        patterns = {"^no$", "^nope$", "^nah$", "i disagree", "don't think so", "not really"},
        requires_start = false
    },
    
    help_request = {
        priority = 2,
        patterns = {"help me", "can you help", "need help", "assist me", "i need", "could you"},
        requires_start = false
    },
    
    clarification = {
        priority = 2,
        patterns = {"what do you mean", "can you explain", "i don't understand", "confused", "unclear"},
        requires_start = false
    },
    
    sharing_positive = {
        priority = 3,
        patterns = {"i'm happy", "i'm excited", "i'm glad", "great news", "good news", "awesome"},
        requires_start = false
    },
    
    sharing_negative = {
        priority = 3,
        patterns = {"i'm sad", "i'm upset", "i'm angry", "i'm frustrated", "having trouble", "difficult time"},
        requires_start = false
    },
    
    question = {
        priority = 4,
        patterns = {"%?"},
        requires_start = false
    },
    
    statement = {
        priority = 5,
        patterns = {".*"},
        requires_start = false
    }
}

-- Detect user's intent with priority system
local function detectIntent(message)
    local lower = message:lower()
    local detectedIntents = {}
    
    for intentName, intentData in pairs(intentPatterns) do
        for _, pattern in ipairs(intentData.patterns) do
            local match = false
            
            if intentData.requires_start then
                match = lower:match(pattern) ~= nil
            else
                match = lower:find(pattern) ~= nil
            end
            
            if match then
                table.insert(detectedIntents, {
                    intent = intentName,
                    priority = intentData.priority
                })
                break
            end
        end
    end
    
    -- Sort by priority
    table.sort(detectedIntents, function(a, b) return a.priority < b.priority end)
    
    -- Return highest priority intent
    if #detectedIntents > 0 then
        return detectedIntents[1].intent
    end
    
    return "statement"
end

-- ============================================================================
-- SEMANTIC CATEGORY DETECTION
-- ============================================================================

local semanticCategories = {
    personal = {
        keywords = {"i", "me", "my", "myself", "i'm", "i am", "i feel", "i think"},
        weight = 1.5
    },
    
    emotional = {
        keywords = {"feel", "feeling", "felt", "emotion", "mood", "happy", "sad", "angry", "excited", "nervous", "anxious"},
        weight = 2.0
    },
    
    problem_solving = {
        keywords = {"problem", "issue", "solve", "fix", "help", "trouble", "difficult", "challenge", "struggle"},
        weight = 1.8
    },
    
    future_planning = {
        keywords = {"will", "going to", "plan", "future", "next", "later", "tomorrow", "soon", "want to", "hope to"},
        weight = 1.3
    },
    
    past_reflection = {
        keywords = {"was", "were", "had", "did", "before", "ago", "yesterday", "last", "used to", "remember"},
        weight = 1.2
    },
    
    inquiry = {
        keywords = {"how", "what", "why", "when", "where", "who", "which", "can", "could", "would", "should"},
        weight = 1.4
    },
    
    casual = {
        keywords = {"just", "kinda", "sorta", "like", "lol", "haha", "yeah", "cool", "nice"},
        weight = 0.8
    },
    
    philosophical = {
        keywords = {"meaning", "life", "purpose", "why", "existence", "believe", "truth", "reality"},
        weight = 1.6
    }
}

-- Detect semantic category
local function detectCategory(message)
    local lower = message:lower()
    local scores = {}
    
    for category, data in pairs(semanticCategories) do
        scores[category] = 0
        for _, keyword in ipairs(data.keywords) do
            if lower:find(keyword, 1, true) then
                scores[category] = scores[category] + data.weight
            end
        end
    end
    
    -- Find highest scoring category
    local bestCategory = "general"
    local bestScore = 0
    
    for category, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestCategory = category
        end
    end
    
    return bestCategory, bestScore
end

-- ============================================================================
-- RESPONSE GENERATION STRATEGIES
-- ============================================================================

-- Handle greetings
local function handleGreeting(user, message, context)
    local userData = memory.users[user]
    local greeting
    
    if userData.relationshipLevel >= 3 then
        greeting = utils.chooseNested(utils.library.greetings, "returning")
    elseif userData.totalInteractions > 0 then
        greeting = utils.chooseNested(utils.library.greetings, "warm")
    else
        greeting = utils.chooseNested(utils.library.greetings, "casual")
    end
    
    -- Personalize with nickname
    if userData.nickname ~= user and userData.relationshipLevel >= 2 then
        greeting = greeting .. " " .. userData.nickname .. "!"
    end
    
    -- Maybe ask how they are
    if personality.shouldAskQuestion({userEngaged = true}) then
        greeting = greeting .. " How are you doing?"
    end
    
    return greeting
end

-- Handle gratitude
local function handleGratitude(user, message, context)
    local responses = {
        "You're very welcome!",
        "Happy to help!",
        "Anytime!",
        "No problem at all!",
        "Glad I could help!",
        "My pleasure!",
        "Of course!"
    }
    
    local response = utils.choose(responses)
    
    -- Add warmth for close relationships
    if memory.users[user].relationshipLevel >= 4 then
        response = response .. " I'm always here for you."
    end
    
    return response
end

-- Handle farewells
local function handleFarewell(user, message, context)
    local farewells = {
        "Goodbye! Take care!",
        "See you later!",
        "Bye! Have a great day!",
        "Later! Come back anytime!",
        "Farewell! Talk to you soon!",
        "Take care!",
        "Until next time!"
    }
    
    local response = utils.choose(farewells)
    
    -- Personalize for established relationships
    if memory.users[user].relationshipLevel >= 3 then
        response = response .. " It was great talking with you."
    end
    
    return response
end

-- Handle questions
local function handleQuestion(user, message, userMood, context)
    local components = {}
    
    -- Acknowledgment
    components.acknowledgment = responses.getAcknowledgment(userMood, "question", "low")
    
    -- Main response - honest about limitations
    local honestResponses = {
        "I'm not entirely sure, but I'm happy to think through it with you.",
        "That's an interesting question. What are your thoughts on it?",
        "Hmm, I'd need to think about that. What's your perspective?",
        "Good question. I'm curious what you think about it.",
        "I'm not certain, but let's explore that together.",
        "That's worth discussing. What made you wonder about that?"
    }
    
    components.main = utils.choose(honestResponses)
    
    -- Maybe ask follow-up
    if personality.shouldAskQuestion({userMood = userMood}) then
        components.followUp = "What's your take on it?"
    end
    
    return responses.buildResponse(components)
end

-- Handle statements with advanced understanding
local function handleStatement(user, message, userMood, context)
    local components = {}
    local userData = memory.users[user]
    
    -- Determine response components based on context
    local category = context.category
    local certainty = utils.getCertaintyLevel(message)
    local temporal = responses.getTemporalFocus and context.temporal or "present"
    
    -- Filler for naturalness
    if math.random() < 0.15 and personality.get("authenticity") > 0.6 then
        components.filler = responses.getFiller("thoughtful")
    end
    
    -- Acknowledgment
    if math.random() < 0.6 then
        components.acknowledgment = responses.getAcknowledgment(userMood, category, certainty)
    end
    
    -- Generate main response based on category
    if category == "emotional" or category == "personal" then
        -- Empathetic response for emotional content
        if personality.shouldShowEmpathy(userMood, {userVulnerable = true}) then
            components.empathy = mood.generateEmpatheticResponse(message)
        end
        
        -- Reflective listening
        if context.keywords and #context.keywords > 0 and math.random() < 0.3 then
            components.reflection = responses.generateReflection(message, context.keywords)
        end
        
        -- Main supportive response
        local supportive = {
            "I hear what you're saying.",
            "That sounds significant.",
            "I appreciate you sharing that with me.",
            "Thank you for being open about that.",
            "I'm listening."
        }
        components.main = utils.choose(supportive)
        
    elseif category == "problem_solving" then
        -- Problem-focused response
        local problemResponses = {
            "That sounds like a real challenge.",
            "I can see why that would be difficult.",
            "Problems like that can be frustrating.",
            "That's a tough situation."
        }
        components.main = utils.choose(problemResponses)
        
        -- Offer support
        if math.random() < 0.5 then
            components.empathy = "What have you tried so far?"
        end
        
    elseif category == "future_planning" then
        -- Future-oriented response
        local futureResponses = {
            "That sounds like an interesting plan.",
            "It's good that you're thinking ahead.",
            "Planning for the future is important.",
            "I hope that works out well for you."
        }
        components.main = utils.choose(futureResponses)
        
    elseif category == "past_reflection" then
        -- Past-oriented response
        local pastResponses = {
            "Reflecting on the past can be valuable.",
            "It's interesting how we see things differently in hindsight.",
            "Those experiences shape who we are.",
            "Looking back can give us perspective."
        }
        components.main = utils.choose(pastResponses)
        
    else
        -- General conversational response
        if context.keywords and #context.keywords > 0 then
            local mainResponses = {
                "I hear what you're saying about " .. context.keywords[1] .. ".",
                "That's interesting.",
                "I see.",
                "Tell me more about that.",
                "How do you feel about that?"
            }
            components.main = utils.choose(mainResponses)
        else
            components.main = utils.choose(utils.library.acknowledgments.understanding)
        end
    end
    
    -- Add follow-up question if appropriate
    if personality.shouldAskQuestion({userMood = userMood, userEngaged = userData.conversationStyle.asksQuestions}) then
        components.followUp = responses.generateFollowUp(message, userMood, context)
    end
    
    -- Build and adjust response
    local response = responses.buildResponse(components)
    local targetLength = personality.getResponseLength({
        userMessageLength = utils.getMessageLength(message),
        userMood = userMood,
        needsSupport = category == "emotional"
    })
    
    response = responses.adjustLength(response, targetLength)
    
    return response
end

-- Handle apologies from user
local function handleApology(user, message, context)
    local responses = {
        "No worries at all!",
        "It's completely fine!",
        "Don't worry about it!",
        "No problem!",
        "That's okay!",
        "No need to apologize!"
    }
    
    return utils.choose(responses)
end

-- Handle agreement
local function handleAgreement(user, message, context)
    local responses = {
        "I'm glad we're on the same page!",
        "Great to hear!",
        "Absolutely!",
        "I think so too!",
        "Glad you agree!"
    }
    
    return utils.choose(responses)
end

-- ============================================================================
-- MAIN INTERPRETATION ENGINE
-- ============================================================================

local function interpret(message, user)
    -- Initialize user
    user = user or DEFAULT_USER
    local userData = initUser(user)
    userData.totalInteractions = userData.totalInteractions + 1
    
    -- Update conversation style
    updateConversationStyle(user, message)
    updateRelationship(user)
    
    -- Analyze emotional content
    mood.update(user, message)
    local userMood = mood.get(user)
    local emotions = mood.detectEmotions(message)
    
    -- Detect intent and category
    local intent = detectIntent(message)
    local category, categoryScore = detectCategory(message)
    
    -- Extract semantic information
    local keywords = utils.extractKeywords(message)
    local complexity = utils.getComplexity(message)
    local certainty = utils.getCertaintyLevel(message)
    local temporal = responses.getTemporalFocus and responses.getTemporalFocus(message) or "present"
    
    -- Build context object
    local context = {
        intent = intent,
        category = category,
        mood = userMood,
        emotions = emotions,
        keywords = keywords,
        complexity = complexity,
        certainty = certainty,
        temporal = temporal,
        messageLength = utils.getMessageLength(message),
        isQuestion = utils.isQuestion(message)
    }
    
    -- Check for topic shift
    if hasTopicShifted(user, keywords) and math.random() < 0.3 then
        -- Acknowledge topic shift
        local transition = responses.getTransition("topical")
        context.topicShift = true
    end
    
    -- Generate response based on intent
    local response
    local wasEmpathetic = false
    
    if intent == "greeting" then
        response = handleGreeting(user, message, context)
        
    elseif intent == "gratitude" then
        response = handleGratitude(user, message, context)
        personality.evolve("positive", {messageType = "general"})
        
    elseif intent == "farewell" then
        response = handleFarewell(user, message, context)
        
    elseif intent == "apology" then
        response = handleApology(user, message, context)
        
    elseif intent == "agreement" then
        response = handleAgreement(user, message, context)
        personality.evolve("positive", {messageType = "general"})
        
    elseif intent == "disagreement" then
        response = "I understand. We can have different perspectives on things."
        
    elseif intent == "help_request" then
        response = "I'm here to help! What do you need?"
        
    elseif intent == "clarification" then
        response = "Let me try to explain that better. What part would you like me to clarify?"
        
    elseif intent == "sharing_positive" then
        response = "That's wonderful! I'm so happy for you! " .. (responses.generateFollowUp(message, "positive", context) or "")
        personality.evolve("positive", {messageType = "empathy", wasEmpathetic = true})
        wasEmpathetic = true
        
    elseif intent == "sharing_negative" then
        local empathyResponse = mood.generateEmpatheticResponse(message)
        if empathyResponse then
            response = empathyResponse .. " " .. (responses.generateFollowUp(message, "negative", context) or "")
        else
            response = handleStatement(user, message, userMood, context)
        end
        personality.evolve("positive", {messageType = "empathy", wasEmpathetic = true})
        wasEmpathetic = true
        
    elseif intent == "question" then
        response = handleQuestion(user, message, userMood, context)
        
    else
        response = handleStatement(user, message, userMood, context)
    end
    
    -- Apply mood adjustment
    context.wasEmpathetic = wasEmpathetic
    response = mood.adjustResponse(user, response)
    
    -- Store in context
    addToContext(user, message, response, {
        intent = intent,
        category = category,
        mood = userMood,
        emotions = emotions,
        topics = keywords
    })
    
    -- Remember topics
    if keywords and #keywords > 0 then
        for _, keyword in ipairs(keywords) do
            responses.rememberTopic(user, keyword, category)
        end
    end
    
    return response
end

-- ============================================================================
-- CHAT INTERFACE
-- ============================================================================

local function setColor(color)
    if term and term.setTextColor then
        pcall(term.setTextColor, color)
    end
end

local function displayMessage(speaker, message, color)
    setColor(color or colors.white)
    print("<" .. speaker .. "> " .. message)
    setColor(colors.white)
end

local function showWelcome()
    if term and term.clear then term.clear() end
    if term and term.setCursorPos then term.setCursorPos(1, 1) end
    
    print("========================================")
    print("      " .. BOT_NAME .. " v" .. VERSION)
    print("========================================")
    print("")
    print("Hello! I'm here to have a real conversation with you.")
    print("You can talk to me about anything on your mind.")
    print("")
    print("Type 'quit' or 'exit' to end our chat.")
    print("Type 'help' for tips on talking with me.")
    print("")
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================

function M.run()
    showWelcome()
    
    local user = DEFAULT_USER
    
    -- Main conversation loop
    while true do
        -- Prompt for input
        setColor(colors.yellow)
        write("> ")
        setColor(colors.white)
        
        local input = read()
        
        -- Handle special commands
        if input:lower() == "quit" or input:lower() == "exit" then
            local farewell = handleFarewell(user, input, {})
            displayMessage(BOT_NAME, farewell, memory.chatColor)
            break
            
        elseif input:lower() == "help" then
            displayMessage(BOT_NAME, "Just talk to me naturally! Share what's on your mind, ask questions, or tell me about your day. I'm here to listen and chat with you.", memory.chatColor)
            
        elseif input == "" then
            displayMessage(BOT_NAME, "I'm listening...", memory.chatColor)
            
        else
            -- Generate and display response
            local response = interpret(input, user)
            displayMessage(BOT_NAME, response, memory.chatColor)
        end
        
        print("")  -- Add spacing between exchanges
    end
end

return M
