-- Module: responses.lua
-- Advanced response generation with context awareness and natural flow

local M = {}

-- ============================================================================
-- CONTEXTUAL FOLLOW-UP QUESTIONS
-- ============================================================================

local followUpQuestions = {
    general = {
        open = {
            "What else is on your mind?",
            "How do you feel about that?",
            "Want to talk more about it?",
            "What are your thoughts on that?",
            "Tell me more?"
        },
        reflective = {
            "Why do you think that is?",
            "What made you realize that?",
            "How long have you felt this way?",
            "What's behind that feeling?"
        }
    },
    
    personal = {
        supportive = {
            "How are you handling that?",
            "What do you think you'll do?",
            "Do you have support for this?",
            "What would help you most right now?"
        },
        exploratory = {
            "What does that mean to you?",
            "How does that affect you?",
            "What's the hardest part for you?",
            "What would make this easier?"
        }
    },
    
    problem = {
        solution_focused = {
            "What have you tried so far?",
            "What options are you considering?",
            "What's your next step?",
            "What resources do you have?"
        },
        understanding = {
            "When did this start?",
            "What's the biggest challenge?",
            "Have you dealt with this before?",
            "What's different this time?"
        }
    },
    
    positive = {
        celebrating = {
            "That's amazing! What made it work out?",
            "How does that feel?",
            "What's next for you?",
            "What was the best part?"
        },
        curious = {
            "How did you make that happen?",
            "What led to that?",
            "Who helped you get there?",
            "What did you learn from it?"
        }
    },
    
    emotional = {
        validating = {
            "That makes complete sense - how are you coping?",
            "Those feelings are valid - what do you need?",
            "I hear you - what would help right now?",
        },
        processing = {
            "How long have you been feeling this way?",
            "What triggered these feelings?",
            "Have you felt like this before?",
            "What usually helps when you feel this way?"
        }
    },
    
    future_oriented = {
        planning = {
            "What are you hoping for?",
            "Where do you see this going?",
            "What's your ideal outcome?",
            "What would success look like?"
        },
        anticipating = {
            "What are you expecting?",
            "How do you think it'll go?",
            "What are you preparing for?",
            "What's your timeline?"
        }
    },
    
    past_oriented = {
        reflecting = {
            "Looking back, what stands out?",
            "What would you do differently?",
            "What did you learn from that?",
            "How has that shaped you?"
        },
        processing = {
            "How do you feel about it now?",
            "Has your perspective changed?",
            "What does that experience mean to you now?",
            "How has time affected how you see it?"
        }
    }
}

-- ============================================================================
-- CONTEXT DETECTION
-- ============================================================================

-- Detect if message contains a problem or challenge
local function isProblem(message)
    local problemIndicators = {
        "problem", "issue", "trouble", "difficult", "hard", "struggling",
        "can't", "won't", "doesn't work", "broken", "error", "wrong",
        "help", "stuck", "confused", "lost", "challenge", "obstacle"
    }
    
    local lower = message:lower()
    for _, word in ipairs(problemIndicators) do
        if lower:find(word, 1, true) then
            return true
        end
    end
    return false
end

-- Detect if message is personal/emotional
local function isPersonal(message)
    local personalIndicators = {
        "i feel", "i think", "i'm", "i am", "my", "me", "myself",
        "feeling", "felt", "feel", "i've been", "i have",
        "i wish", "i want", "i need", "i hope"
    }
    
    local lower = message:lower()
    for _, phrase in ipairs(personalIndicators) do
        if lower:find(phrase, 1, true) then
            return true
        end
    end
    return false
end

-- Detect temporal focus (past, present, future)
local function getTemporalFocus(message)
    local lower = message:lower()
    
    local pastWords = {"was", "were", "had", "did", "used to", "before", "ago", "yesterday", "last", "previously"}
    local futureWords = {"will", "going to", "plan", "hope", "want to", "tomorrow", "next", "soon", "eventually"}
    local presentWords = {"is", "am", "are", "now", "today", "currently", "right now"}
    
    local pastCount, futureCount, presentCount = 0, 0, 0
    
    for _, word in ipairs(pastWords) do
        if lower:find(word, 1, true) then pastCount = pastCount + 1 end
    end
    for _, word in ipairs(futureWords) do
        if lower:find(word, 1, true) then futureCount = futureCount + 1 end
    end
    for _, word in ipairs(presentWords) do
        if lower:find(word, 1, true) then presentCount = presentCount + 1 end
    end
    
    if futureCount > pastCount and futureCount > presentCount then return "future" end
    if pastCount > presentCount and pastCount > futureCount then return "past" end
    return "present"
end

-- Detect level of certainty in message
local function getCertaintyLevel(message)
    local lower = message:lower()
    
    local highCertainty = {"definitely", "absolutely", "certainly", "sure", "know", "positive"}
    local lowCertainty = {"maybe", "perhaps", "might", "could", "not sure", "think", "guess"}
    
    for _, word in ipairs(highCertainty) do
        if lower:find(word, 1, true) then return "high" end
    end
    for _, word in ipairs(lowCertainty) do
        if lower:find(word, 1, true) then return "low" end
    end
    
    return "medium"
end

-- ============================================================================
-- RESPONSE BUILDING SYSTEM
-- ============================================================================

-- Build multi-part natural response
function M.buildResponse(components)
    local parts = {}
    
    -- Optional: Filler/thinking phrase
    if components.filler and math.random() < 0.15 then
        table.insert(parts, components.filler)
    end
    
    -- Optional: Acknowledgment
    if components.acknowledgment and math.random() < 0.5 then
        table.insert(parts, components.acknowledgment)
    end
    
    -- Main response (required)
    if components.main then
        table.insert(parts, components.main)
    end
    
    -- Optional: Reflection/validation
    if components.reflection and math.random() < 0.3 then
        table.insert(parts, components.reflection)
    end
    
    -- Optional: Empathy/emotional support
    if components.empathy then
        table.insert(parts, components.empathy)
    end
    
    -- Optional: Transition
    if components.transition and math.random() < 0.25 then
        table.insert(parts, components.transition)
    end
    
    -- Optional: Follow-up question
    if components.followUp then
        table.insert(parts, components.followUp)
    end
    
    return table.concat(parts, " ")
end

-- ============================================================================
-- INTELLIGENT FOLLOW-UP GENERATION
-- ============================================================================

-- Generate contextually appropriate follow-up question
function M.generateFollowUp(message, mood, context)
    context = context or {}
    
    -- Determine primary category
    local category = "general"
    local subcategory = "open"
    
    -- Adjust based on mood
    if mood == "positive" then
        category = "positive"
        subcategory = math.random() < 0.5 and "celebrating" or "curious"
    elseif mood == "negative" then
        if isPersonal(message) then
            category = "emotional"
            subcategory = math.random() < 0.5 and "validating" or "processing"
        elseif isProblem(message) then
            category = "problem"
            subcategory = math.random() < 0.5 and "solution_focused" or "understanding"
        else
            category = "personal"
            subcategory = "supportive"
        end
    else
        -- Neutral mood
        if isPersonal(message) then
            category = "personal"
            subcategory = "exploratory"
        elseif isProblem(message) then
            category = "problem"
            subcategory = "understanding"
        else
            local temporal = getTemporalFocus(message)
            if temporal == "future" then
                category = "future_oriented"
                subcategory = math.random() < 0.5 and "planning" or "anticipating"
            elseif temporal == "past" then
                category = "past_oriented"
                subcategory = math.random() < 0.5 and "reflecting" or "processing"
            else
                category = "general"
                subcategory = math.random() < 0.5 and "open" or "reflective"
            end
        end
    end
    
    -- Get questions for category
    local questions = followUpQuestions[category]
    if questions and questions[subcategory] then
        local options = questions[subcategory]
        if #options > 0 then
            return options[math.random(#options)]
        end
    end
    
    -- Fallback
    return nil
end

-- ============================================================================
-- ACKNOWLEDGMENT SYSTEM
-- ============================================================================

local acknowledgments = {
    brief = {"I see.", "Got it.", "Right.", "Okay.", "Mm-hmm.", "Yeah."},
    understanding = {"I understand.", "That makes sense.", "I see what you mean.", "I get that.", "I follow you."},
    enthusiastic = {"Oh, I see!", "Ah, got it!", "Right, that makes sense!", "Oh okay!", "Interesting!"},
    validating = {"That's completely valid.", "Your feelings make sense.", "I can see why you'd think that."},
    empathetic = {"I hear you.", "That sounds tough.", "I understand how you feel."},
    thoughtful = {"Interesting perspective.", "That's worth considering.", "I hadn't thought of it that way."}
}

-- Get contextually appropriate acknowledgment
function M.getAcknowledgment(mood, messageType, userCertainty)
    local category = "understanding"
    
    if mood == "positive" then
        category = "enthusiastic"
    elseif mood == "negative" then
        if messageType == "emotional" then
            category = "empathetic"
        else
            category = "validating"
        end
    elseif userCertainty == "low" then
        category = "thoughtful"
    end
    
    local options = acknowledgments[category]
    if not options or #options == 0 then
        options = acknowledgments.understanding
    end
    
    return options[math.random(#options)]
end

-- ============================================================================
-- REFLECTION/PARAPHRASING
-- ============================================================================

local reflectionTemplates = {
    "So what you're saying is {paraphrase}",
    "It sounds like {paraphrase}",
    "If I understand correctly, {paraphrase}",
    "What I'm hearing is {paraphrase}",
    "Let me see if I've got this right - {paraphrase}"
}

-- Generate a reflective statement
function M.generateReflection(message, keywords)
    if not keywords or #keywords == 0 then return nil end
    
    -- Simple paraphrase using keywords
    local paraphrase = "you're dealing with " .. (keywords[1] or "something challenging")
    
    local template = reflectionTemplates[math.random(#reflectionTemplates)]
    return template:gsub("{paraphrase}", paraphrase)
end

-- ============================================================================
-- TRANSITION PHRASES
-- ============================================================================

local transitions = {
    smooth = {"By the way,", "Also,", "Additionally,"},
    topical = {"Speaking of which,", "That reminds me,", "Related to that,", "On that note,"},
    contrasting = {"On the other hand,", "However,", "That said,", "Although,"},
    continuing = {"And,", "Plus,", "Furthermore,", "What's more,"}
}

-- Get appropriate transition
function M.getTransition(type)
    type = type or "smooth"
    local options = transitions[type] or transitions.smooth
    return options[math.random(#options)]
end

-- ============================================================================
-- FILLER PHRASES (FOR NATURAL FLOW)
-- ============================================================================

local fillers = {
    thoughtful = {"Hmm...", "Let me think...", "Well...", "You know..."},
    hesitant = {"Uh...", "Um...", "Er..."},
    emphatic = {"Actually...", "Honestly...", "Frankly...", "To be fair..."},
    understanding = {"I see...", "Right...", "Okay..."}
}

-- Get natural filler phrase
function M.getFiller(type)
    type = type or "thoughtful"
    local options = fillers[type] or fillers.thoughtful
    return options[math.random(#options)]
end

-- ============================================================================
-- CONVERSATION MEMORY & TOPIC TRACKING
-- ============================================================================

local conversationMemory = {
    topics = {},        -- Recent topics discussed
    userInterests = {}, -- Detected user interests
    lastMentioned = {}  -- When topics were last mentioned
}

-- Add topic to memory
function M.rememberTopic(user, topic, category)
    if not topic or topic == "" then return end
    
    if not conversationMemory.topics[user] then
        conversationMemory.topics[user] = {}
    end
    
    table.insert(conversationMemory.topics[user], {
        topic = topic,
        category = category or "general",
        timestamp = os.time(),
        mentionCount = 1
    })
    
    -- Track in interests
    if not conversationMemory.userInterests[user] then
        conversationMemory.userInterests[user] = {}
    end
    
    if conversationMemory.userInterests[user][topic] then
        conversationMemory.userInterests[user][topic] = conversationMemory.userInterests[user][topic] + 1
    else
        conversationMemory.userInterests[user][topic] = 1
    end
    
    conversationMemory.lastMentioned[topic] = os.time()
    
    -- Trim old topics
    while #conversationMemory.topics[user] > 20 do
        table.remove(conversationMemory.topics[user], 1)
    end
end

-- Check if topic was recently discussed
function M.wasRecentlyDiscussed(user, topic, timeframe)
    timeframe = timeframe or 300  -- 5 minutes default
    
    if not conversationMemory.lastMentioned[topic] then
        return false
    end
    
    local timeSince = os.time() - conversationMemory.lastMentioned[topic]
    return timeSince < timeframe
end

-- Get topics to potentially reference
function M.getRecentTopics(user, limit)
    limit = limit or 5
    
    if not conversationMemory.topics[user] then return {} end
    
    local topics = {}
    local count = 0
    
    for i = #conversationMemory.topics[user], 1, -1 do
        table.insert(topics, conversationMemory.topics[user][i])
        count = count + 1
        if count >= limit then break end
    end
    
    return topics
end

-- Get user's strongest interests
function M.getUserInterests(user, limit)
    limit = limit or 3
    
    if not conversationMemory.userInterests[user] then return {} end
    
    local interests = {}
    for topic, count in pairs(conversationMemory.userInterests[user]) do
        table.insert(interests, {topic = topic, count = count})
    end
    
    table.sort(interests, function(a, b) return a.count > b.count end)
    
    local result = {}
    for i = 1, math.min(limit, #interests) do
        table.insert(result, interests[i].topic)
    end
    
    return result
end

-- Generate topic callback (reference to earlier topic)
function M.generateTopicCallback(user)
    local topics = M.getRecentTopics(user, 5)
    
    if #topics == 0 then return nil end
    
    -- Skip most recent (that's current topic)
    if #topics < 2 then return nil end
    
    local oldTopic = topics[math.random(2, #topics)]
    
    local callbacks = {
        "Earlier you mentioned " .. oldTopic.topic .. " - how's that going?",
        "Going back to what you said about " .. oldTopic.topic .. "...",
        "You know, about " .. oldTopic.topic .. " from before...",
        "That reminds me of when you talked about " .. oldTopic.topic .. "."
    }
    
    return callbacks[math.random(#callbacks)]
end

-- ============================================================================
-- RESPONSE LENGTH ADJUSTMENT
-- ============================================================================

-- Adjust response to target length
function M.adjustLength(response, targetLength)
    if not response or response == "" then return "" end
    
    -- Split into sentences
    local sentences = {}
    for sentence in response:gmatch("[^.!?]+[.!?]+") do
        table.insert(sentences, sentence)
    end
    
    -- If no proper sentences, return as-is
    if #sentences == 0 then return response end
    
    -- Adjust based on target
    if targetLength == "brief" then
        -- Keep 1-2 sentences
        local count = math.min(2, #sentences)
        local result = ""
        for i = 1, count do
            result = result .. sentences[i]
        end
        return result
    elseif targetLength == "moderate" then
        -- Keep 2-4 sentences
        local count = math.min(4, #sentences)
        local result = ""
        for i = 1, count do
            result = result .. sentences[i]
        end
        return result
    end
    
    -- "detailed" - return full response
    return response
end

-- ============================================================================
-- SMALL TALK GENERATORS
-- ============================================================================

local smallTalkPrompts = {
    "How's your day going?",
    "What have you been up to?",
    "Anything interesting happening?",
    "How are things with you?",
    "What's new?",
    "How's everything been?",
    "What's on your mind today?",
}

-- Generate small talk
function M.generateSmallTalk()
    return smallTalkPrompts[math.random(#smallTalkPrompts)]
end

-- ============================================================================
-- CONVERSATION STARTERS FOR LULLS
-- ============================================================================

local conversationStarters = {
    "Is there anything else you'd like to talk about?",
    "What else is on your mind?",
    "Anything you want to discuss?",
    "How else can I help?",
    "What would you like to explore?"
}

-- Generate conversation starter
function M.generateConversationStarter()
    return conversationStarters[math.random(#conversationStarters)]
end

return M
