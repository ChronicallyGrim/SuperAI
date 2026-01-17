-- Module: autonomous_learning.lua
-- Self-training AI that learns from experience without explicit teaching

local M = {}

-- ============================================================================
-- PATTERN RECOGNITION & LEARNING
-- ============================================================================

M.patterns = {
    conversations = {},
    successful_patterns = {},
    failed_patterns = {},
    word_associations = {},
    response_templates = {}
}

-- Learn from successful interactions
function M.learnFromSuccess(user_message, bot_response, user_reaction)
    -- Extract pattern
    local pattern = {
        user_words = M.extractKeywords(user_message),
        response_type = M.classifyResponse(bot_response),
        context_length = #user_message,
        resulted_in = user_reaction or "neutral"
    }
    
    table.insert(M.patterns.successful_patterns, pattern)
    
    -- Build word associations (what words lead to what responses)
    for _, word in ipairs(pattern.user_words) do
        if not M.patterns.word_associations[word] then
            M.patterns.word_associations[word] = {
                responses = {},
                success_count = 0
            }
        end
        
        table.insert(M.patterns.word_associations[word].responses, bot_response)
        M.patterns.word_associations[word].success_count = 
            M.patterns.word_associations[word].success_count + 1
    end
end

-- Extract important keywords from text
function M.extractKeywords(text)
    local keywords = {}
    local stopwords = {
        ["the"] = true, ["a"] = true, ["an"] = true, ["and"] = true,
        ["or"] = true, ["but"] = true, ["is"] = true, ["are"] = true,
        ["was"] = true, ["were"] = true, ["it"] = true, ["this"] = true,
        ["that"] = true, ["to"] = true, ["of"] = true, ["in"] = true,
        ["for"] = true, ["on"] = true, ["with"] = true
    }
    
    for word in text:lower():gmatch("%w+") do
        if #word > 3 and not stopwords[word] then
            table.insert(keywords, word)
        end
    end
    
    return keywords
end

-- Classify response type
function M.classifyResponse(response)
    local lower = response:lower()
    
    if lower:find("?") then return "question"
    elseif lower:find("!") then return "exclamation"
    elseif lower:find("because") or lower:find("since") then return "explanation"
    elseif #response < 20 then return "short"
    elseif #response > 100 then return "detailed"
    else return "standard"
    end
end

-- ============================================================================
-- AUTONOMOUS IMPROVEMENT
-- ============================================================================

-- Automatically detect what works based on conversation flow
function M.analyzeConversationFlow(history)
    if #history < 3 then return nil end
    
    local insights = {
        engagement_level = 0,
        topics_that_worked = {},
        optimal_response_length = 0
    }
    
    -- Calculate engagement (longer user responses = higher engagement)
    local total_length = 0
    for _, entry in ipairs(history) do
        if entry.user then
            total_length = total_length + #entry.message
        end
    end
    insights.engagement_level = total_length / #history
    
    -- Find topics that led to continued conversation
    for i = 1, #history - 1 do
        if history[i].bot and history[i+1].user then
            local keywords = M.extractKeywords(history[i].bot)
            for _, keyword in ipairs(keywords) do
                table.insert(insights.topics_that_worked, keyword)
            end
        end
    end
    
    return insights
end

-- ============================================================================
-- RESPONSE EVOLUTION
-- ============================================================================

M.response_evolution = {
    variations = {},
    performance = {}
}

-- Generate variations of responses to test what works better
function M.generateVariations(base_response)
    local variations = {}
    
    -- Variation 1: Add enthusiasm
    table.insert(variations, base_response .. "!")
    
    -- Variation 2: Add question
    table.insert(variations, base_response .. " What do you think?")
    
    -- Variation 3: Make it shorter
    local short = base_response:sub(1, math.floor(#base_response * 0.7))
    table.insert(variations, short)
    
    -- Variation 4: Add casual language
    local casual = base_response:gsub("I would", "I'd"):gsub("I will", "I'll")
    table.insert(variations, casual)
    
    -- Variation 5: Add empathy
    table.insert(variations, "I understand. " .. base_response)
    
    return variations
end

-- Track which variations perform better
function M.trackVariationPerformance(variation, outcome)
    if not M.response_evolution.performance[variation] then
        M.response_evolution.performance[variation] = {
            uses = 0,
            successes = 0,
            failures = 0
        }
    end
    
    M.response_evolution.performance[variation].uses = 
        M.response_evolution.performance[variation].uses + 1
    
    if outcome == "success" then
        M.response_evolution.performance[variation].successes = 
            M.response_evolution.performance[variation].successes + 1
    else
        M.response_evolution.performance[variation].failures = 
            M.response_evolution.performance[variation].failures + 1
    end
end

-- Select best performing variation
function M.selectBestVariation(variations)
    local best = variations[1]
    local best_score = 0
    
    for _, variation in ipairs(variations) do
        local perf = M.response_evolution.performance[variation]
        if perf then
            local score = perf.successes / math.max(perf.uses, 1)
            if score > best_score then
                best_score = score
                best = variation
            end
        end
    end
    
    return best
end

-- ============================================================================
-- CONTEXT LEARNING
-- ============================================================================

-- Learn optimal context usage (when to reference past messages)
M.context_learning = {
    reference_success = {},
    optimal_lookback = 3
}

function M.learnContextUsage(referenced_past, outcome)
    if not M.context_learning.reference_success[referenced_past] then
        M.context_learning.reference_success[referenced_past] = {
            successes = 0,
            failures = 0
        }
    end
    
    if outcome == "success" then
        M.context_learning.reference_success[referenced_past].successes = 
            M.context_learning.reference_success[referenced_past].successes + 1
    else
        M.context_learning.reference_success[referenced_past].failures = 
            M.context_learning.reference_success[referenced_past].failures + 1
    end
    
    -- Adjust optimal lookback
    local total_success = 0
    local count = 0
    for lookback, stats in pairs(M.context_learning.reference_success) do
        local rate = stats.successes / (stats.successes + stats.failures)
        total_success = total_success + (rate * lookback)
        count = count + 1
    end
    
    if count > 0 then
        M.context_learning.optimal_lookback = math.floor(total_success / count)
    end
end

-- ============================================================================
-- IMPLICIT FEEDBACK DETECTION
-- ============================================================================

-- Detect user satisfaction without explicit feedback
function M.detectImplicitFeedback(user_message, previous_bot_response)
    local satisfaction = "neutral"
    local confidence = 0.5
    
    local lower = user_message:lower()
    
    -- Positive signals
    if lower:find("thanks") or lower:find("thank") or lower:find("awesome") or
       lower:find("great") or lower:find("perfect") or lower:find("exactly") then
        satisfaction = "positive"
        confidence = 0.9
    end
    
    -- Negative signals  
    if lower:find("no") or lower:find("wrong") or lower:find("what") or
       lower:find("huh") or lower:find("confused") then
        satisfaction = "negative"
        confidence = 0.8
    end
    
    -- Engagement signals
    if #user_message > 50 then
        -- Long response = engaged = probably good
        satisfaction = "positive"
        confidence = 0.6
    elseif #user_message < 5 then
        -- Very short = disengaged = probably bad
        satisfaction = "negative"
        confidence = 0.6
    end
    
    -- Follow-up question = interested = good
    if lower:find("?") then
        satisfaction = "positive"
        confidence = 0.7
    end
    
    return satisfaction, confidence
end

-- ============================================================================
-- AUTOMATIC QUALITY IMPROVEMENT
-- ============================================================================

-- Improve responses based on learned patterns
function M.improveResponse(raw_response, context)
    local improved = raw_response
    
    -- Apply learned patterns
    -- 1. Check if similar questions had better responses
    local keywords = M.extractKeywords(context.user_message or "")
    for _, keyword in ipairs(keywords) do
        if M.patterns.word_associations[keyword] then
            local assoc = M.patterns.word_associations[keyword]
            if assoc.success_count > 5 then
                -- This keyword has successful history
                -- We can be more confident
                improved = improved:gsub("maybe", "likely")
                improved = improved:gsub("I think", "I believe")
            end
        end
    end
    
    -- 2. Apply optimal response length
    local avg_successful_length = M.calculateAverageSuccessfulLength()
    if avg_successful_length > 0 then
        if #improved < avg_successful_length * 0.5 then
            -- Too short, add elaboration
            improved = improved .. " Let me explain further."
        elseif #improved > avg_successful_length * 1.5 then
            -- Too long, might be rambling
            -- Keep it as is for now (hard to auto-shorten meaningfully)
        end
    end
    
    -- 3. Generate and test variations
    local variations = M.generateVariations(improved)
    improved = M.selectBestVariation(variations)
    
    return improved
end

function M.calculateAverageSuccessfulLength()
    local total = 0
    local count = 0
    
    for _, pattern in ipairs(M.patterns.successful_patterns) do
        if pattern.response_type then
            total = total + pattern.context_length
            count = count + 1
        end
    end
    
    return count > 0 and (total / count) or 0
end

-- ============================================================================
-- CONTINUOUS LEARNING LOOP
-- ============================================================================

function M.processInteraction(user_message, bot_response, conversation_history)
    -- 1. Detect implicit feedback
    local satisfaction, confidence = M.detectImplicitFeedback(user_message, bot_response)
    
    -- 2. Learn from this interaction
    if satisfaction == "positive" and confidence > 0.6 then
        M.learnFromSuccess(user_message, bot_response, satisfaction)
    end
    
    -- 3. Analyze conversation flow
    if #conversation_history > 3 then
        local insights = M.analyzeConversationFlow(conversation_history)
        if insights then
            -- Store insights for future use
            M.storeInsights(insights)
        end
    end
    
    -- 4. Track variation performance
    M.trackVariationPerformance(bot_response, satisfaction)
    
    -- 5. Learn context usage
    local referenced_past = #conversation_history > 0
    M.learnContextUsage(referenced_past and #conversation_history or 0, satisfaction)
end

function M.storeInsights(insights)
    -- Store for later retrieval
    if not M.stored_insights then
        M.stored_insights = {}
    end
    table.insert(M.stored_insights, insights)
    
    -- Keep only last 100
    if #M.stored_insights > 100 then
        table.remove(M.stored_insights, 1)
    end
end

-- ============================================================================
-- ADAPTIVE BEHAVIOR
-- ============================================================================

-- Automatically adjust conversation style based on what works
function M.adaptConversationStyle(user_profile)
    local style = {
        formality = "medium",
        verbosity = "medium",
        use_questions = true,
        use_examples = true
    }
    
    -- Analyze successful patterns to determine optimal style
    local total_success = #M.patterns.successful_patterns
    if total_success > 10 then
        -- We have enough data to adapt
        
        local question_success = 0
        local short_response_success = 0
        
        for _, pattern in ipairs(M.patterns.successful_patterns) do
            if pattern.response_type == "question" then
                question_success = question_success + 1
            end
            if pattern.response_type == "short" then
                short_response_success = short_response_success + 1
            end
        end
        
        -- Adjust based on what worked
        if question_success / total_success > 0.6 then
            style.use_questions = true
        else
            style.use_questions = false
        end
        
        if short_response_success / total_success > 0.6 then
            style.verbosity = "low"
        else
            style.verbosity = "high"
        end
    end
    
    return style
end

-- ============================================================================
-- SAVE/LOAD LEARNING DATA
-- ============================================================================

function M.saveLearnedData(filename)
    filename = filename or "learned_data.dat"
    
    local data = {
        patterns = M.patterns,
        evolution = M.response_evolution,
        context = M.context_learning,
        insights = M.stored_insights
    }
    
    local serialized = textutils.serialize(data)
    local file = fs.open(filename, "w")
    if file then
        file.write(serialized)
        file.close()
        return true
    end
    return false
end

function M.loadLearnedData(filename)
    filename = filename or "learned_data.dat"
    
    if not fs.exists(filename) then
        return false, "No learned data file found"
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data then
            M.patterns = data.patterns or M.patterns
            M.response_evolution = data.evolution or M.response_evolution
            M.context_learning = data.context or M.context_learning
            M.stored_insights = data.insights or M.stored_insights
            return true
        end
    end
    
    return false, "Could not load data"
end

-- ============================================================================
-- STATS & MONITORING
-- ============================================================================

function M.getLearningSt ats()
    return {
        total_patterns = #M.patterns.successful_patterns,
        word_associations = 0,  -- Count keys
        variations_tested = 0,
        optimal_lookback = M.context_learning.optimal_lookback,
        avg_successful_length = M.calculateAverageSuccessfulLength()
    }
end

-- ============================================================================
-- INTEGRATION FUNCTION
-- ============================================================================

-- Call this after every bot response
function M.learn(user_message, bot_response, conversation_history)
    M.processInteraction(user_message, bot_response, conversation_history)
    
    -- Auto-save every 10 interactions
    if #M.patterns.successful_patterns % 10 == 0 then
        M.saveLearnedData()
    end
end

-- Call this before generating a response
function M.enhance(raw_response, context)
    return M.improveResponse(raw_response, context)
end

return M
