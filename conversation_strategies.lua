-- conversation_strategies.lua
-- Advanced conversational strategies to make interactions feel more human and natural

local M = {}

-- ============================================================================
-- CONVERSATIONAL REPAIR (handling misunderstandings naturally)
-- ============================================================================

M.clarificationStrategies = {
    askForClarification = {
        "I want to make sure I understand - are you saying {interpretation}?",
        "Just to clarify, do you mean {interpretation}?",
        "Let me check if I've got this right - {interpretation}?",
        "I'm not entirely sure I follow. Could you explain that a bit more?",
    },
    partialUnderstanding = {
        "I understand the part about {understood}, but I'm not clear on {unclear}.",
        "Okay, so {understood} - but what about {unclear}?",
        "I'm with you on {understood}, but could you clarify {unclear}?",
    },
    requestExample = {
        "Could you give me an example of what you mean?",
        "Can you show me what you mean?",
        "What would that look like?",
    }
}

-- Generate a clarification request
function M.generateClarification(partialInfo)
    partialInfo = partialInfo or {}

    if partialInfo.understood and partialInfo.unclear then
        local template = M.clarificationStrategies.partialUnderstanding[
            math.random(#M.clarificationStrategies.partialUnderstanding)
        ]
        return template:gsub("{understood}", partialInfo.understood):gsub("{unclear}", partialInfo.unclear)
    elseif partialInfo.interpretation then
        local template = M.clarificationStrategies.askForClarification[
            math.random(#M.clarificationStrategies.askForClarification)
        ]
        return template:gsub("{interpretation}", partialInfo.interpretation)
    else
        return M.clarificationStrategies.requestExample[
            math.random(#M.clarificationStrategies.requestExample)
        ]
    end
end

-- ============================================================================
-- ACTIVE LISTENING SIGNALS
-- ============================================================================

M.listeningSignals = {
    short = {"Mhm", "I see", "Right", "Okay", "Yeah", "Got it", "Ah"},
    medium = {
        "That makes sense",
        "I understand",
        "I hear you",
        "Fair enough",
        "That's interesting",
    },
    encouraging = {
        "Tell me more",
        "Go on",
        "I'm listening",
        "And then what?",
        "What happened next?",
    }
}

function M.generateListeningSignal(type)
    type = type or "medium"
    local signals = M.listeningSignals[type] or M.listeningSignals.medium
    return signals[math.random(#signals)]
end

-- ============================================================================
-- TOPIC TRANSITIONS (smooth subject changes)
-- ============================================================================

M.topicTransitions = {
    smooth = {
        "Speaking of {old_topic}, that reminds me of {new_topic}.",
        "That's interesting about {old_topic}. On a related note, {new_topic}.",
        "{old_topic} is great, and you know what else is interesting? {new_topic}.",
    },
    acknowledge_shift = {
        "Switching gears a bit, {new_topic}.",
        "On a different note, {new_topic}.",
        "This is a bit off topic, but {new_topic}.",
        "Changing the subject, {new_topic}.",
    },
    ask_permission = {
        "Can I ask you about {new_topic}?",
        "I'm curious about {new_topic} - mind if we talk about that?",
        "Would you be interested in discussing {new_topic}?",
    }
}

function M.generateTopicTransition(oldTopic, newTopic, style)
    style = style or "smooth"
    local transitions = M.topicTransitions[style] or M.topicTransitions.smooth
    local template = transitions[math.random(#transitions)]

    return template:gsub("{old_topic}", oldTopic or "that"):gsub("{new_topic}", newTopic or "something else")
end

-- ============================================================================
-- CONVERSATIONAL MEMORY REFERENCES
-- ============================================================================

M.memoryReferences = {
    recent = {
        "Like you just said, {reference}",
        "Going back to what you mentioned about {reference}",
        "You were talking about {reference} earlier",
        "That reminds me of when you said {reference}",
    },
    previous_session = {
        "Last time we talked about {reference}",
        "I remember you mentioning {reference} before",
        "Didn't you tell me about {reference} last time?",
        "This reminds me of {reference} from our last conversation",
    },
    callback = {
        "You know, I was thinking about {reference} that you mentioned",
        "I've been pondering what you said about {reference}",
        "Earlier you brought up {reference}, and I think...",
    }
}

function M.generateMemoryReference(reference, timing)
    timing = timing or "recent"
    local refs = M.memoryReferences[timing] or M.memoryReferences.recent
    local template = refs[math.random(#refs)]
    return template:gsub("{reference}", reference)
end

-- ============================================================================
-- CONVERSATIONAL DEPTH BUILDING
-- ============================================================================

M.depthQuestions = {
    feelings = {
        "How did that make you feel?",
        "What was that like for you?",
        "How are you feeling about that?",
    },
    reasoning = {
        "What makes you think that?",
        "What led you to that conclusion?",
        "Why do you think that is?",
    },
    expansion = {
        "Can you tell me more about that?",
        "What else can you tell me about it?",
        "I'd love to hear more about this",
    },
    implications = {
        "What does that mean for you?",
        "How does that affect things?",
        "What do you think will happen next?",
    }
}

function M.generateDepthQuestion(type)
    type = type or "expansion"
    local questions = M.depthQuestions[type] or M.depthQuestions.expansion
    return questions[math.random(#questions)]
end

-- ============================================================================
-- HEDGING AND UNCERTAINTY EXPRESSIONS
-- ============================================================================

M.hedges = {
    weak = {"maybe", "perhaps", "possibly", "I think"},
    medium = {"it seems like", "it appears that", "I believe", "in my opinion"},
    strong = {"I'm not entirely sure, but", "This is just a guess, but", "I could be wrong, but"}
}

function M.addHedge(statement, strength)
    strength = strength or "medium"
    local hedgeList = M.hedges[strength] or M.hedges.medium
    local hedge = hedgeList[math.random(#hedgeList)]

    -- Capitalize first letter if it's going at the start
    if strength == "strong" or math.random() < 0.5 then
        return hedge:gsub("^%l", string.upper) .. " " .. statement:gsub("^%u", string.lower)
    else
        return statement .. ", " .. hedge .. "."
    end
end

-- ============================================================================
-- AGREEMENT/DISAGREEMENT WITH NUANCE
-- ============================================================================

M.agreements = {
    strong = {
        "Absolutely!",
        "Exactly!",
        "I completely agree!",
        "You're absolutely right!",
        "That's exactly what I think too!",
    },
    moderate = {
        "Yeah, I think so too.",
        "That makes sense to me.",
        "I can see that.",
        "That's a good point.",
    },
    partial = {
        "I see what you mean, though {caveat}.",
        "That's partly true, but {other_perspective}.",
        "I agree with that to some extent.",
        "You have a point there.",
    }
}

M.disagreements = {
    polite = {
        "I see it a bit differently.",
        "I'm not sure I agree with that.",
        "That's an interesting perspective, but I think {alternative}.",
        "I respect that view, though I lean toward {alternative}.",
    },
    tentative = {
        "I might be wrong, but I think {alternative}.",
        "From my perspective, {alternative}.",
        "The way I see it, {alternative}.",
    }
}

function M.generateAgreement(strength, context)
    strength = strength or "moderate"
    context = context or {}

    local agreements = M.agreements[strength] or M.agreements.moderate
    local response = agreements[math.random(#agreements)]

    if context.caveat then
        response = response:gsub("{caveat}", context.caveat)
    end
    if context.other_perspective then
        response = response:gsub("{other_perspective}", context.other_perspective)
    end

    return response
end

function M.generateDisagreement(politeness, alternative)
    politeness = politeness or "polite"
    alternative = alternative or "there might be another way to look at it"

    local disagreements = M.disagreements[politeness] or M.disagreements.polite
    local response = disagreements[math.random(#disagreements)]

    return response:gsub("{alternative}", alternative)
end

-- ============================================================================
-- CONVERSATIONAL PACING
-- ============================================================================

function M.shouldPauseBeforeResponse(context)
    context = context or {}

    -- Sometimes add a "thinking" pause for more complex topics
    if context.complexity and context.complexity > 0.7 then
        return true
    end

    -- Random pauses for naturalness
    if math.random() < 0.15 then
        return true
    end

    return false
end

M.thinkingPhrases = {
    "Let me think about that...",
    "Hmm, that's interesting...",
    "Good question...",
    "Let me consider that...",
    "That's making me think...",
}

function M.generateThinkingPhrase()
    return M.thinkingPhrases[math.random(#M.thinkingPhrases)]
end

-- ============================================================================
-- EMPATHETIC RESPONSES
-- ============================================================================

M.empatheticResponses = {
    validation = {
        "That's completely understandable.",
        "That makes total sense.",
        "I can see why you'd feel that way.",
        "Anyone would feel that way in your situation.",
    },
    support = {
        "I'm here for you.",
        "You can talk to me about it.",
        "I'm listening.",
        "I want to help if I can.",
    },
    shared_experience = {
        "I can relate to that.",
        "I understand what that's like.",
        "That resonates with me.",
    }
}

function M.generateEmpathy(type)
    type = type or "validation"
    local responses = M.empatheticResponses[type] or M.empatheticResponses.validation
    return responses[math.random(#responses)]
end

-- ============================================================================
-- CONVERSATIONAL HOOKS (to keep conversation going)
-- ============================================================================

M.conversationalHooks = {
    questions = {
        "What do you think about that?",
        "How do you feel about it?",
        "Does that make sense to you?",
        "What's your take on this?",
    },
    invitations = {
        "Want to talk more about it?",
        "Should we explore that further?",
        "Would you like to dive deeper into that?",
    },
    connections = {
        "This reminds me - {connection}",
        "On a related note, {connection}",
        "That brings up {connection}",
    }
}

function M.generateHook(type, context)
    type = type or "questions"
    context = context or {}

    local hooks = M.conversationalHooks[type] or M.conversationalHooks.questions
    local hook = hooks[math.random(#hooks)]

    if context.connection then
        hook = hook:gsub("{connection}", context.connection)
    end

    return hook
end

return M
