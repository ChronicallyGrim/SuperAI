-- natural_conversation.lua
-- High-level natural conversation engine that orchestrates all AI improvements
-- Makes conversations feel more human and Claude-like

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

    return true
end

-- ============================================================================
-- CONVERSATIONAL CONTEXT BUILDING
-- ============================================================================

-- Build rich context for response generation
function M.buildContext(user, message, history)
    local ctx = {
        user = user,
        message = message,
        messageLength = #message,
        hasQuestion = message:find("?") ~= nil,
        isShort = #message < 20,
        isLong = #message > 100,
    }

    -- Add personality context
    if personality then
        ctx.personality = {
            formality = personality.getFormality(),
            enthusiasm = personality.getEnthusiasm(ctx),
            responseLength = personality.getResponseLength(ctx),
            shouldAskQuestion = personality.shouldAskQuestion(ctx),
            shouldAddHumor = personality.shouldAddHumor(ctx),
        }
    end

    -- Add memory context
    if convMem then
        ctx.memory = convMem.getContextForResponse(user)
        ctx.isReturningUser = ctx.memory and ctx.memory.isReturning or false

        -- Get continuity suggestions
        ctx.continuity = convMem.getContinuitySuggestions()
    end

    -- Add conversational history
    if history and #history > 0 then
        ctx.lastTopic = history[#history].topic
        ctx.conversationDepth = #history
    end

    return ctx
end

-- ============================================================================
-- RESPONSE ENHANCEMENT
-- ============================================================================

-- Enhance a basic response with personality and context
function M.enhanceResponse(baseResponse, ctx)
    if not baseResponse or baseResponse == "" then
        return baseResponse
    end

    local enhanced = baseResponse

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
            local reference = convStrat.generateMemoryReference(ctx.continuity.previousTopic, "recent")
            -- Sometimes weave it in naturally
            if math.random() < 0.3 then
                enhanced = reference .. " - " .. enhanced
            end
        end
    end

    -- Add thinking pause for complex topics
    if convStrat and convStrat.shouldPauseBeforeResponse(ctx) then
        enhanced = convStrat.generateThinkingPhrase() .. " " .. enhanced
    end

    -- Add hedging if uncertain
    if personality and ctx.certainty and ctx.certainty < 0.5 then
        if personality.shouldHedge(ctx) then
            enhanced = convStrat.addHedge(enhanced, "medium")
        end
    end

    return enhanced
end

-- ============================================================================
-- CONVERSATIONAL FLOW MANAGEMENT
-- ============================================================================

-- Determine if AI should add a follow-up to keep conversation going
function M.shouldAddFollowUp(ctx)
    if not personality then return false end

    local initiative = personality.getInitiativeLevel()

    if initiative == "proactive" then
        return math.random() < 0.6
    elseif initiative == "balanced" then
        return math.random() < 0.35
    else
        return math.random() < 0.15
    end
end

-- Generate a follow-up question or statement
function M.generateFollowUp(ctx)
    if not convStrat then
        return nil
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

-- ============================================================================
-- NATURAL RESPONSE GENERATION
-- ============================================================================

-- Generate a complete natural response
function M.generateNaturalResponse(user, message, baseResponse, history)
    -- Build comprehensive context
    local ctx = M.buildContext(user, message, history)

    -- Enhance base response with personality and context
    local response = M.enhanceResponse(baseResponse, ctx)

    -- Add follow-up if appropriate
    if M.shouldAddFollowUp(ctx) then
        local followUp = M.generateFollowUp(ctx)
        if followUp then
            response = respGen and respGen.addConversationalBridge(response, followUp) or (response .. " " .. followUp)
        end
    end

    -- Track in conversation memory
    if convMem then
        convMem.addTurn("ai", response, {
            intent = ctx.intent,
            sentiment = ctx.sentiment,
            topics = ctx.topics
        })
    end

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
    local certainty = 0.3 -- Default low for unknown questions

    if personality and personality.shouldExpressUncertainty(certainty) then
        local thinking = convStrat.generateThinkingPhrase()
        local honest = "I'm not entirely sure about that."
        local curious = convStrat.generateDepthQuestion("reasoning")

        return thinking .. " " .. honest .. " " .. curious
    end

    return nil
end

-- ============================================================================
-- EMPATHY AND EMOTIONAL INTELLIGENCE
-- ============================================================================

-- Generate empathetic response to user emotion
function M.generateEmpatheticResponse(userMood, context)
    if not convStrat or not respGen then
        return nil
    end

    local response = ""

    if userMood == "negative" then
        -- Start with validation
        response = convStrat.generateEmpathy("validation")

        -- Add support
        response = response .. " " .. convStrat.generateEmpathy("support")

        -- Offer to listen
        if math.random() < 0.5 then
            response = response .. " " .. convStrat.generateDepthQuestion("feelings")
        end

    elseif userMood == "positive" then
        -- Share in their joy
        response = respGen.generateEmpathy("happy")

        -- Show enthusiasm
        if personality and personality.get("enthusiasm") > 0.5 then
            response = response .. " " .. convStrat.generateHook("questions")
        end
    end

    return response
end

-- ============================================================================
-- CONVERSATION REPAIR
-- ============================================================================

-- Handle when AI doesn't understand
function M.handleMisunderstanding(message, partialUnderstanding)
    if not convStrat then
        return "I'm not sure I understand. Can you explain that differently?"
    end

    local clarification = convStrat.generateClarification(partialUnderstanding or {})

    -- Add apologetic tone if appropriate
    if personality and personality.get("agreeableness") > 0.6 then
        return "Sorry, " .. clarification:gsub("^%u", string.lower)
    end

    return clarification
end

-- ============================================================================
-- TOPIC TRANSITIONS
-- ============================================================================

-- Generate smooth topic transition
function M.transitionTopic(oldTopic, newTopic, style)
    if not convStrat then
        return "By the way, " .. (newTopic or "something else I wanted to mention") .. "."
    end

    style = style or "smooth"
    return convStrat.generateTopicTransition(oldTopic, newTopic, style)
end

-- ============================================================================
-- CONVERSATION STATISTICS
-- ============================================================================

function M.getStats()
    return {
        convMemEnabled = convMem ~= nil,
        convStratEnabled = convStrat ~= nil,
        respGenEnabled = respGen ~= nil,
        personalityEnabled = personality ~= nil,
    }
end

return M
