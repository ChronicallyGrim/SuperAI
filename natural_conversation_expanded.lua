-- natural_conversation.lua
-- Advanced natural conversation engine with multi-turn planning, style adaptation,
-- sophisticated conversation repair, and deep contextual awareness
-- Production-grade conversational AI orchestration system

local M = {}

-- Module dependencies (loaded on init)
local personality, convStrat, convMem, respGen, mood

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function M.init(deps)
    deps = deps or {}
    personality = deps.personality
    convStrat = deps.convStrat
    convMem = deps.convMem
    respGen = deps.respGen
    mood = deps.mood

    -- Initialize conversation planner
    M.conversationPlanner = {
        activePlans = {},
        planHistory = {},
        planningDepth = 3  -- How many turns ahead to plan
    }

    -- Initialize style adapter
    M.styleAdapter = {
        detectedUserStyle = {},
        adaptationLevel = 0.5
    }

    -- Initialize conversation metrics
    M.metrics = {
        totalTurns = 0,
        avgTurnLength = 0,
        topicSwitches = 0,
        repairAttempts = 0,
        successfulRepairs = 0,
        engagementScore = 0
    }

    return true
end

-- ============================================================================
-- MULTI-TURN CONVERSATION PLANNING
-- ============================================================================

-- Plan ahead for multiple conversational turns
function M.planConversation(user, currentContext, goalType)
    goalType = goalType or "engage"  -- engage, inform, support, explore

    local plan = {
        user = user,
        goal = goalType,
        turns = {},
        createdAt = os.time(),
        status = "active"
    }

    -- Generate turn-by-turn strategy
    if goalType == "engage" then
        table.insert(plan.turns, {
            intent = "acknowledge",
            followUp = "curiosity",
            tone = "warm"
        })
        table.insert(plan.turns, {
            intent = "deepen",
            followUp = "related_topic",
            tone = "curious"
        })
        table.insert(plan.turns, {
            intent = "expand",
            followUp = "user_perspective",
            tone = "interested"
        })
    elseif goalType == "support" then
        table.insert(plan.turns, {
            intent = "validate",
            followUp = "empathy",
            tone = "gentle"
        })
        table.insert(plan.turns, {
            intent = "explore_feelings",
            followUp = "supportive_question",
            tone = "caring"
        })
        table.insert(plan.turns, {
            intent = "offer_help",
            followUp = "encouragement",
            tone = "hopeful"
        })
    elseif goalType == "explore" then
        table.insert(plan.turns, {
            intent = "clarify",
            followUp = "probing_question",
            tone = "inquisitive"
        })
        table.insert(plan.turns, {
            intent = "connect_ideas",
            followUp = "synthesis",
            tone = "thoughtful"
        })
        table.insert(plan.turns, {
            intent = "deepen_understanding",
            followUp = "philosophical_angle",
            tone = "reflective"
        })
    end

    -- Store plan
    table.insert(M.conversationPlanner.activePlans, plan)

    return plan
end

-- Get next planned turn
function M.getNextPlannedTurn(user)
    for i, plan in ipairs(M.conversationPlanner.activePlans) do
        if plan.user == user and plan.status == "active" then
            if #plan.turns > 0 then
                local nextTurn = table.remove(plan.turns, 1)

                -- If plan exhausted, mark as complete
                if #plan.turns == 0 then
                    plan.status = "completed"
                    table.insert(M.conversationPlanner.planHistory, plan)
                    table.remove(M.conversationPlanner.activePlans, i)
                end

                return nextTurn
            end
        end
    end

    return nil
end

-- Update plan based on user response
function M.updatePlanBasedOnResponse(user, userMessage, userSentiment)
    for _, plan in ipairs(M.conversationPlanner.activePlans) do
        if plan.user == user and plan.status == "active" then
            -- If user is very negative, switch to support mode
            if userSentiment < -0.6 and plan.goal ~= "support" then
                plan.goal = "support"
                plan.turns = {}

                table.insert(plan.turns, {
                    intent = "validate",
                    followUp = "empathy",
                    tone = "gentle"
                })
                table.insert(plan.turns, {
                    intent = "offer_support",
                    followUp = "listening",
                    tone = "caring"
                })
            end

            -- If user asks deep question, switch to explore
            if userMessage:find("?") and #userMessage > 50 and plan.goal ~= "explore" then
                plan.goal = "explore"
                table.insert(plan.turns, 1, {
                    intent = "thoughtful_response",
                    followUp = "deeper_question",
                    tone = "reflective"
                })
            end
        end
    end
end

-- ============================================================================
-- CONVERSATIONAL CONTEXT BUILDING (Enhanced)
-- ============================================================================

-- Build comprehensive context for response generation
function M.buildContext(user, message, history)
    local ctx = {
        user = user,
        message = message,
        messageLength = #message,
        hasQuestion = message:find("?") ~= nil,
        isShort = #message < 20,
        isLong = #message > 100,
        wordCount = select(2, message:gsub("%S+", "")),
        exclamationCount = select(2, message:gsub("!", "")),
        questionCount = select(2, message:gsub("?", "")),
    }

    -- Detect message complexity
    ctx.complexity = M.assessMessageComplexity(message)

    -- Detect user engagement level
    ctx.engagementLevel = M.detectEngagementLevel(message, history)

    -- Add personality context
    if personality then
        ctx.personality = {
            formality = personality.getFormality(),
            enthusiasm = personality.getEnthusiasm(ctx),
            responseLength = personality.getResponseLength(ctx),
            shouldAskQuestion = personality.shouldAskQuestion(ctx),
            shouldAddHumor = personality.shouldAddHumor(ctx),
            initiativeLevel = personality.getInitiativeLevel(),
            assertiveness = personality.get("assertiveness"),
            empathy = personality.get("empathy")
        }
    end

    -- Add memory context
    if convMem then
        ctx.memory = convMem.getContextForResponse(user)
        ctx.isReturningUser = ctx.memory and ctx.memory.isReturning or false

        -- Get continuity suggestions
        ctx.continuity = convMem.getContinuitySuggestions()
    end

    -- Add conversational history analysis
    if history and #history > 0 then
        ctx.lastTopic = history[#history].topic
        ctx.conversationDepth = #history
        ctx.topicStability = M.analyzeTopicStability(history)
        ctx.sentimentTrajectory = M.analyzeSentimentTrajectory(history)
    end

    -- Add style context
    ctx.detectedUserStyle = M.detectUserStyle(message, history)

    -- Add planned turn if exists
    ctx.plannedTurn = M.getNextPlannedTurn(user)

    return ctx
end

-- Assess message complexity
function M.assessMessageComplexity(message)
    local score = 0

    -- Length-based complexity
    if #message > 100 then score = score + 1 end
    if #message > 200 then score = score + 1 end

    -- Subordinate clauses
    if message:find(" because ") or message:find(" although ") or message:find(" however ") then
        score = score + 1
    end

    -- Abstract concepts
    local abstractWords = {"think", "feel", "believe", "understand", "realize", "imagine"}
    for _, word in ipairs(abstractWords) do
        if message:lower():find(word) then
            score = score + 0.5
            break
        end
    end

    if score < 1 then return "simple" end
    if score < 2.5 then return "moderate" end
    return "complex"
end

-- Detect user engagement level
function M.detectEngagementLevel(message, history)
    local score = 0

    -- Length suggests engagement
    if #message > 50 then score = score + 1 end
    if #message > 150 then score = score + 1 end

    -- Questions suggest engagement
    if message:find("?") then score = score + 1 end

    -- Exclamations suggest emotional engagement
    if message:find("!") then score = score + 0.5 end

    -- Follow-up on previous topic suggests engagement
    if history and #history > 0 then
        local lastTopic = history[#history].topic
        if lastTopic and message:lower():find(lastTopic:lower(), 1, true) then
            score = score + 1.5
        end
    end

    if score < 1 then return "low" end
    if score < 3 then return "medium" end
    return "high"
end

-- Analyze topic stability
function M.analyzeTopicStability(history)
    if not history or #history < 2 then return "stable" end

    local topicChanges = 0
    for i = 2, #history do
        if history[i].topic ~= history[i-1].topic then
            topicChanges = topicChanges + 1
        end
    end

    local changeRate = topicChanges / (#history - 1)

    if changeRate < 0.3 then return "very_stable" end
    if changeRate < 0.6 then return "stable" end
    if changeRate < 0.8 then return "variable" end
    return "chaotic"
end

-- Analyze sentiment trajectory
function M.analyzeSentimentTrajectory(history)
    if not history or #history < 2 then return "neutral" end

    local recentSentiments = {}
    local start = math.max(1, #history - 4)

    for i = start, #history do
        if history[i].sentiment then
            table.insert(recentSentiments, history[i].sentiment)
        end
    end

    if #recentSentiments < 2 then return "neutral" end

    -- Calculate trend
    local trend = recentSentiments[#recentSentiments] - recentSentiments[1]

    if trend > 0.3 then return "improving" end
    if trend < -0.3 then return "declining" end
    return "stable"
end

-- ============================================================================
-- STYLE ADAPTATION
-- ============================================================================

-- Detect user's communication style
function M.detectUserStyle(message, history)
    local style = {
        formality = 0.5,
        emotionality = 0.5,
        verbosity = 0.5,
        directness = 0.5,
        humor = 0.5
    }

    -- Formality detection
    local formalWords = {"please", "thank you", "appreciate", "kindly", "regards"}
    local casualWords = {"hey", "yeah", "gonna", "wanna", "lol", "haha"}

    local formalCount = 0
    local casualCount = 0

    for _, word in ipairs(formalWords) do
        if message:lower():find(word, 1, true) then formalCount = formalCount + 1 end
    end
    for _, word in ipairs(casualWords) do
        if message:lower():find(word, 1, true) then casualCount = casualCount + 1 end
    end

    if formalCount > casualCount then
        style.formality = 0.7 + (formalCount * 0.1)
    elseif casualCount > formalCount then
        style.formality = 0.3 - (casualCount * 0.1)
    end

    -- Emotionality detection
    local emotionMarkers = {"!", "feel", "love", "hate", "amazing", "terrible", "wonderful", "awful"}
    local emotionCount = 0
    for _, marker in ipairs(emotionMarkers) do
        if message:lower():find(marker, 1, true) then emotionCount = emotionCount + 1 end
    end
    style.emotionality = math.min(0.3 + (emotionCount * 0.2), 1.0)

    -- Verbosity detection
    local wordCount = select(2, message:gsub("%S+", ""))
    if wordCount < 10 then
        style.verbosity = 0.2
    elseif wordCount < 30 then
        style.verbosity = 0.5
    else
        style.verbosity = 0.8
    end

    -- Directness detection
    if message:find("I think") or message:find("maybe") or message:find("perhaps") then
        style.directness = 0.3
    elseif message:find("definitely") or message:find("absolutely") or message:find("clearly") then
        style.directness = 0.8
    end

    -- Humor detection
    if message:find("lol") or message:find("haha") or message:find("lmao") or message:find("😂") then
        style.humor = 0.8
    end

    -- Update running average if we have history
    if history and #history > 0 then
        for key, value in pairs(style) do
            if M.styleAdapter.detectedUserStyle[key] then
                style[key] = (M.styleAdapter.detectedUserStyle[key] * 0.7) + (value * 0.3)
            end
        end
    end

    M.styleAdapter.detectedUserStyle = style
    return style
end

-- Adapt response style to match user
function M.adaptStyleToUser(response, userStyle)
    if not userStyle then return response end

    -- Match formality level
    if userStyle.formality > 0.7 then
        -- Make more formal
        response = response:gsub("gonna", "going to")
        response = response:gsub("wanna", "want to")
        response = response:gsub(" hey ", " hello ")
    elseif userStyle.formality < 0.3 then
        -- Make more casual
        response = response:gsub("Hello", "Hey")
        response = response:gsub("Greetings", "Hi")
    end

    -- Match verbosity
    if userStyle.verbosity < 0.3 and #response > 100 then
        -- Trim if user is concise
        local sentences = {}
        for sentence in response:gmatch("[^%.!?]+[%.!?]") do
            table.insert(sentences, sentence)
            if #sentences >= 2 then break end
        end
        response = table.concat(sentences, " ")
    end

    return response
end

-- ============================================================================
-- RESPONSE ENHANCEMENT (Massively Expanded)
-- ============================================================================

-- Enhance a basic response with personality, context, and style
function M.enhanceResponse(baseResponse, ctx)
    if not baseResponse or baseResponse == "" then
        return baseResponse
    end

    local enhanced = baseResponse

    -- Apply style adaptation
    if ctx.detectedUserStyle then
        enhanced = M.adaptStyleToUser(enhanced, ctx.detectedUserStyle)
    end

    -- Add natural fillers based on personality
    if respGen and ctx.personality then
        local fillerProb = ctx.personality.formality == "casual" and 0.3 or 0.1
        enhanced = respGen.addFillers(enhanced, fillerProb)
    end

    -- Add empathy if user seems down
    if convStrat and ctx.memory and ctx.memory.user then
        local moodTrend = ctx.memory.user.moodTrend or 0
        if moodTrend < -0.3 and math.random() < 0.4 then
            local empathy = convStrat.generateEmpathy("support")
            enhanced = enhanced .. " " .. empathy
        end
    end

    -- Add memory callback if relevant
    if convMem and ctx.continuity and ctx.continuity.previousTopic then
        if personality and personality.shouldAcknowledgePrevious(ctx) then
            local reference = convStrat and convStrat.generateMemoryReference(ctx.continuity.previousTopic, "recent") or
                            ("Last time we talked about " .. ctx.continuity.previousTopic .. ".")
            -- Sometimes weave it in naturally
            if math.random() < 0.3 then
                enhanced = reference .. " - " .. enhanced
            end
        end
    end

    -- Add thinking pause for complex topics
    if convStrat and ctx.complexity == "complex" then
        if math.random() < 0.4 then
            enhanced = (convStrat.generateThinkingPhrase() or "Let me think...") .. " " .. enhanced
        end
    end

    -- Add hedging if uncertain
    if personality and ctx.certainty and ctx.certainty < 0.5 then
        if personality.shouldHedge(ctx) then
            enhanced = M.addHedging(enhanced, "medium")
        end
    end

    -- Add enthusiasm markers for positive contexts
    if ctx.sentiment and ctx.sentiment > 0.6 and ctx.personality then
        if ctx.personality.enthusiasm == "high" and math.random() < 0.3 then
            if not enhanced:find("!") then
                enhanced = enhanced:gsub("%.$", "!")
            end
        end
    end

    return enhanced
end

-- Add hedging language
function M.addHedging(response, level)
    local hedges = {
        light = {"I think ", "perhaps ", "maybe "},
        medium = {"It seems to me that ", "I'd say ", "From my perspective, "},
        strong = {"I might be wrong, but ", "This is just my opinion, but ", "Take this with a grain of salt, but "}
    }

    local hedgeList = hedges[level] or hedges.medium
    local hedge = hedgeList[math.random(#hedgeList)]

    -- Don't double-hedge
    if response:find("I think") or response:find("maybe") or response:find("perhaps") then
        return response
    end

    return hedge .. response
end

-- ============================================================================
-- CONVERSATIONAL FLOW MANAGEMENT (Enhanced)
-- ============================================================================

-- Determine if AI should add a follow-up to keep conversation going
function M.shouldAddFollowUp(ctx)
    if not personality then return false end

    local initiative = personality.getInitiativeLevel()
    local baseProb = 0

    if initiative == "proactive" then
        baseProb = 0.6
    elseif initiative == "balanced" then
        baseProb = 0.35
    else
        baseProb = 0.15
    end

    -- Increase if engagement is high
    if ctx.engagementLevel == "high" then
        baseProb = baseProb * 1.3
    elseif ctx.engagementLevel == "low" then
        baseProb = baseProb * 0.7
    end

    -- Decrease if user message was long (they're talking a lot)
    if ctx.isLong then
        baseProb = baseProb * 0.8
    end

    return math.random() < baseProb
end

-- Generate a sophisticated follow-up question or statement
function M.generateFollowUp(ctx)
    if not convStrat then
        return nil
    end

    -- Use planned turn if available
    if ctx.plannedTurn then
        return M.executeP lannedTurn(ctx.plannedTurn)
    end

    -- Choose follow-up type based on context
    if ctx.lastTopic and math.random() < 0.5 then
        return convStrat.generateDepthQuestion("expansion")
    elseif ctx.memory and ctx.memory.user and ctx.memory.user.favoriteTopics and #ctx.memory.user.favoriteTopics > 0 then
        local topic = ctx.memory.user.favoriteTopics[1]
        return "By the way, how's " .. topic .. " going?"
    else
        return convStrat.generateHook("questions")
    end
end

-- Execute a planned conversation turn
function M.executePlannedTurn(plannedTurn)
    if not plannedTurn then return nil end

    -- Generate response based on planned intent
    if plannedTurn.intent == "deepen" then
        return "What made you interested in that?"
    elseif plannedTurn.intent == "expand" then
        return "Tell me more about that - I'm curious!"
    elseif plannedTurn.intent == "validate" then
        return "That makes complete sense. I understand why you'd feel that way."
    elseif plannedTurn.intent == "explore_feelings" then
        return "How are you feeling about all of this?"
    else
        return "What are your thoughts on that?"
    end
end

-- ============================================================================
-- CONVERSATION REPAIR (Massively Enhanced)
-- ============================================================================

-- Detect if conversation needs repair
function M.needsRepair(ctx)
    local repairNeeded = false
    local repairReason = nil

    -- User seems confused or frustrated
    if ctx.message:lower():find("what") and ctx.message:find("?") and ctx.messageLength < 30 then
        repairNeeded = true
        repairReason = "user_confused"
    end

    -- User explicitly says they don't understand
    if ctx.message:lower():find("don't understand") or ctx.message:lower():find("confused") then
        repairNeeded = true
        repairReason = "explicit_confusion"
    end

    -- Conversation has stalled (very short messages)
    if ctx.conversationDepth and ctx.conversationDepth > 3 then
        if ctx.messageLength < 15 and not ctx.hasQuestion then
            repairNeeded = true
            repairReason = "conversation_stall"
        end
    end

    -- Topic instability suggests repair needed
    if ctx.topicStability == "chaotic" then
        repairNeeded = true
        repairReason = "topic_chaos"
    end

    return repairNeeded, repairReason
end

-- Attempt conversation repair
function M.attemptRepair(repairReason, ctx)
    M.metrics.repairAttempts = M.metrics.repairAttempts + 1

    local repairResponse = ""

    if repairReason == "user_confused" then
        repairResponse = "Let me clarify - " .. M.generateClarification(ctx)
    elseif repairReason == "explicit_confusion" then
        repairResponse = "Sorry for the confusion! Let me explain that differently. " .. M.generateSimplification(ctx)
    elseif repairReason == "conversation_stall" then
        repairResponse = M.generateConversationReinvigoration(ctx)
    elseif repairReason == "topic_chaos" then
        repairResponse = "We've covered a lot of ground! Should we focus on one thing?"
    else
        repairResponse = "Let me make sure we're on the same page. " .. M.generateGrounding(ctx)
    end

    return repairResponse
end

-- Generate clarification
function M.generateClarification(ctx)
    return "What I meant was... " .. (ctx.lastAIStatement or "let me explain") .. ". Does that make more sense?"
end

-- Generate simplification
function M.generateSimplification(ctx)
    return "In simpler terms, it's like this: [simplified version]. Is that clearer?"
end

-- Reinvigorate stalled conversation
function M.generateConversationReinvigoration(ctx)
    local strategies = {
        "What's something you're curious about?",
        "Let's talk about something you're passionate about!",
        "What's on your mind today?",
        "Is there something specific you'd like to explore?",
        "What would make this conversation more interesting for you?"
    }

    return strategies[math.random(#strategies)]
end

-- Generate grounding statement
function M.generateGrounding(ctx)
    if ctx.lastTopic then
        return "We were talking about " .. ctx.lastTopic .. ". Want to continue with that?"
    end
    return "Let's take a step back. What would you like to focus on?"
end

-- ============================================================================
-- CONFIDENCE SCORING
-- ============================================================================

-- Calculate confidence in response
function M.calculateConfidence(response, ctx)
    local score = 0.5  -- Base confidence

    -- Higher confidence if we have relevant memory
    if ctx.memory and ctx.memory.user and ctx.memory.user.facts then
        local factCount = 0
        for _ in pairs(ctx.memory.user.facts) do factCount = factCount + 1 end
        score = score + (math.min(factCount, 5) * 0.05)
    end

    -- Higher confidence if response matches personality
    if personality and ctx.personality then
        score = score + 0.1
    end

    -- Lower confidence if topic is new
    if not ctx.lastTopic then
        score = score - 0.1
    end

    -- Higher confidence if planned
    if ctx.plannedTurn then
        score = score + 0.15
    end

    return math.max(0, math.min(1, score))
end

-- ============================================================================
-- NATURAL RESPONSE GENERATION (Enhanced)
-- ============================================================================

-- Generate a complete natural response with all enhancements
function M.generateNaturalResponse(user, message, baseResponse, history)
    -- Build comprehensive context
    local ctx = M.buildContext(user, message, history)

    -- Check if repair is needed
    local needsRepair, repairReason = M.needsRepair(ctx)
    if needsRepair then
        return M.attemptRepair(repairReason, ctx)
    end

    -- Update conversation plan based on user response
    if mood and mood.get(user) then
        local userSentiment = mood.get(user) == "positive" and 0.7 or
                            mood.get(user) == "negative" and -0.7 or 0
        M.updatePlanBasedOnResponse(user, message, userSentiment)
    end

    -- Enhance base response with personality and context
    local response = M.enhanceResponse(baseResponse, ctx)

    -- Add follow-up if appropriate
    if M.shouldAddFollowUp(ctx) then
        local followUp = M.generateFollowUp(ctx)
        if followUp then
            response = respGen and respGen.addConversationalBridge(response, followUp) or (response .. " " .. followUp)
        end
    end

    -- Calculate confidence
    ctx.responseConfidence = M.calculateConfidence(response, ctx)

    -- Track in conversation memory
    if convMem then
        convMem.addTurn("ai", response, {
            intent = ctx.intent,
            sentiment = ctx.sentiment,
            topics = ctx.topics,
            confidence = ctx.responseConfidence
        })
    end

    -- Update metrics
    M.updateMetrics(ctx, response)

    return response
end

-- ============================================================================
-- STATEMENT PROCESSING (Enhanced)
-- ============================================================================

-- Process a user statement with natural responses
function M.processStatement(user, message, userMood)
    if not respGen then
        return nil
    end

    local sentiment = 0
    if userMood == "positive" then
        sentiment = 0.8
    elseif userMood == "negative" then
        sentiment = -0.8
    end

    -- Generate contextual response based on mood
    local intent = sentiment > 0.3 and "status_positive" or
                   sentiment < -0.3 and "status_negative" or
                   "acknowledgment"

    local response = respGen.generateNaturalResponse(intent, {}, true)

    -- Sometimes add curiosity
    if personality and personality.get("curiosity") > 0.6 and math.random() < 0.4 then
        local curious = respGen.generateCuriosity()
        response = response .. " " .. curious
    end

    -- Create or update conversation plan
    if not M.getNextPlannedTurn(user) then
        local goalType = sentiment < -0.5 and "support" or "engage"
        M.planConversation(user, {sentiment = sentiment}, goalType)
    end

    return response
end

-- ============================================================================
-- QUESTION PROCESSING (Enhanced)
-- ============================================================================

-- Process a user question with intelligent responses
function M.processQuestion(user, message)
    if not convStrat then
        return nil
    end

    -- Check if we should express uncertainty
    local certainty = 0.3  -- Default low for unknown questions

    if personality and personality.shouldExpressUncertainty(certainty) then
        local thinking = convStrat.generateThinkingPhrase and convStrat.generateThinkingPhrase() or "Hmm, let me think..."
        local honest = "I'm not entirely sure about that."
        local curious = convStrat.generateDepthQuestion and convStrat.generateDepthQuestion("reasoning") or "What do you think?"

        return thinking .. " " .. honest .. " " .. curious
    end

    return nil
end

-- ============================================================================
-- EMPATHY AND EMOTIONAL INTELLIGENCE (Enhanced)
-- ============================================================================

-- Generate empathetic response to user emotion
function M.generateEmpatheticResponse(userMood, context)
    if not convStrat or not respGen then
        return nil
    end

    local response = ""

    if userMood == "negative" then
        -- Start with validation
        response = (convStrat.generateEmpathy and convStrat.generateEmpathy("validation")) or "I hear you."

        -- Add support
        local support = (convStrat.generateEmpathy and convStrat.generateEmpathy("support")) or "I'm here for you."
        response = response .. " " .. support

        -- Offer to listen
        if math.random() < 0.5 then
            local question = (convStrat.generateDepthQuestion and convStrat.generateDepthQuestion("feelings")) or "Want to talk about it?"
            response = response .. " " .. question
        end

        -- Create support plan
        M.planConversation(context.user, context, "support")

    elseif userMood == "positive" then
        -- Share in their joy
        response = respGen.generateEmpathy("happy")

        -- Show enthusiasm
        if personality and personality.get("enthusiasm") > 0.5 then
            local hook = (convStrat.generateHook and convStrat.generateHook("questions")) or "Tell me more!"
            response = response .. " " .. hook
        end

        -- Create engagement plan
        M.planConversation(context.user, context, "engage")
    end

    return response
end

-- ============================================================================
-- TOPIC TRANSITIONS (Enhanced)
-- ============================================================================

-- Generate smooth topic transition
function M.transitionTopic(oldTopic, newTopic, style)
    style = style or "smooth"

    local transitions = {
        smooth = {
            "Speaking of {old}, that reminds me of {new}.",
            "You know, {old} is interesting, and so is {new}.",
            "That's a great point about {old}. Along those lines, {new}.",
            "Before I forget, while we're on {old}, I wanted to mention {new}."
        },
        abrupt = {
            "Oh, by the way, {new}.",
            "Totally different topic: {new}.",
            "Random thought: {new}.",
            "This just came to mind: {new}."
        },
        bridge = {
            "That connects to something else: {new}.",
            "That makes me think about {new}.",
            "Similarly, {new}.",
            "In a related vein, {new}."
        }
    }

    local transitionList = transitions[style] or transitions.smooth
    local template = transitionList[math.random(#transitionList)]

    return template:gsub("{old}", oldTopic or "what we were discussing"):gsub("{new}", newTopic or "something else")
end

-- ============================================================================
-- METRICS AND ANALYTICS
-- ============================================================================

-- Update conversation metrics
function M.updateMetrics(ctx, response)
    M.metrics.totalTurns = M.metrics.totalTurns + 1

    -- Update average turn length
    local currentAvg = M.metrics.avgTurnLength
    M.metrics.avgTurnLength = ((currentAvg * (M.metrics.totalTurns - 1)) + #response) / M.metrics.totalTurns

    -- Track topic switches
    if ctx.lastTopic and ctx.currentTopic and ctx.lastTopic ~= ctx.currentTopic then
        M.metrics.topicSwitches = M.metrics.topicSwitches + 1
    end

    -- Update engagement score
    if ctx.engagementLevel == "high" then
        M.metrics.engagementScore = math.min(M.metrics.engagementScore + 0.1, 1.0)
    elseif ctx.engagementLevel == "low" then
        M.metrics.engagementScore = math.max(M.metrics.engagementScore - 0.05, 0)
    end
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function M.getStats()
    return {
        convMemEnabled = convMem ~= nil,
        convStratEnabled = convStrat ~= nil,
        respGenEnabled = respGen ~= nil,
        personalityEnabled = personality ~= nil,
        moodEnabled = mood ~= nil,
        totalTurns = M.metrics.totalTurns,
        avgTurnLength = M.metrics.avgTurnLength,
        topicSwitches = M.metrics.topicSwitches,
        repairAttempts = M.metrics.repairAttempts,
        repairSuccessRate = M.metrics.repairAttempts > 0 and
                           (M.metrics.successfulRepairs / M.metrics.repairAttempts) or 0,
        engagementScore = M.metrics.engagementScore,
        activePlans = #M.conversationPlanner.activePlans,
        completedPlans = #M.conversationPlanner.planHistory
    }
end

return M
