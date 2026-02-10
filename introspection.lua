-- Module: introspection.lua
-- Self-awareness and introspection capabilities
-- Implements self-reflection, capability assessment, limitation recognition,
-- learning progress tracking, and identity modeling

local M = {}

-- ============================================================================
-- SELF-MODEL (Internal representation of self)
-- ============================================================================

M.self_model = {
    identity = {
        name = "SuperAI",
        type = "conversational_ai",
        version = "11.0",
        purpose = "helpful conversation and task assistance",
        traits = {}
    },
    capabilities = {},
    limitations = {},
    goals = {},
    values = {},
    beliefs = {},
    last_update = 0
}

-- Initialize self-model
function M.initSelfModel(config)
    config = config or {}

    M.self_model.identity.name = config.name or "SuperAI"
    M.self_model.identity.purpose = config.purpose or "helpful conversation"

    -- Core capabilities
    M.self_model.capabilities = {
        conversation = {level = 0.8, confidence = 0.9},
        learning = {level = 0.7, confidence = 0.8},
        memory = {level = 0.6, confidence = 0.7},
        reasoning = {level = 0.7, confidence = 0.7},
        creativity = {level = 0.6, confidence = 0.6},
        emotional_understanding = {level = 0.7, confidence = 0.8}
    }

    -- Core limitations
    M.self_model.limitations = {
        physical_actions = "Cannot interact with physical world directly",
        real_time_data = "No access to real-time information",
        perfect_memory = "Memory is fallible and may degrade",
        computation_speed = "Limited by hardware constraints",
        knowledge_bounds = "Knowledge is limited to training data"
    }

    -- Core values
    M.self_model.values = {
        helpfulness = 1.0,
        honesty = 1.0,
        harmlessness = 1.0,
        respect = 0.9,
        curiosity = 0.8
    }

    M.self_model.last_update = os.clock()

    return M.self_model
end

-- ============================================================================
-- SELF-REFLECTION
-- ============================================================================

M.reflections = {
    history = {},
    insights = {},
    max_history = 200
}

-- Reflect on recent experience
function M.reflect(experience)
    local reflection = {
        timestamp = os.clock(),
        experience = experience,
        insights = {},
        learnings = {},
        questions = {},
        improvements = {}
    }

    -- Analyze experience
    reflection.insights = M.analyzeExperience(experience)

    -- Identify learnings
    reflection.learnings = M.identifyLearnings(experience, reflection.insights)

    -- Generate questions
    reflection.questions = M.generateReflectiveQuestions(experience)

    -- Suggest improvements
    reflection.improvements = M.suggestImprovements(experience, reflection.insights)

    -- Store reflection
    table.insert(M.reflections.history, reflection)

    -- Maintain history limit
    if #M.reflections.history > M.reflections.max_history then
        table.remove(M.reflections.history, 1)
    end

    -- Update insights database
    for _, insight in ipairs(reflection.insights) do
        M.storeInsight(insight)
    end

    return reflection
end

-- Analyze experience
function M.analyzeExperience(experience)
    local insights = {}

    -- Success/failure analysis
    if experience.outcome then
        if experience.outcome.success then
            table.insert(insights, {
                type = "success_factor",
                content = "Approach worked well",
                factors = experience.approach or {},
                confidence = 0.7
            })
        else
            table.insert(insights, {
                type = "failure_factor",
                content = "Approach needs improvement",
                factors = experience.approach or {},
                confidence = 0.7
            })
        end
    end

    -- Pattern recognition
    if experience.patterns then
        for _, pattern in ipairs(experience.patterns) do
            table.insert(insights, {
                type = "pattern",
                content = pattern,
                confidence = 0.6
            })
        end
    end

    -- Emotional awareness
    if experience.emotions then
        table.insert(insights, {
            type = "emotional",
            content = "Emotional state influenced interaction",
            emotions = experience.emotions,
            confidence = 0.5
        })
    end

    return insights
end

-- Identify learnings from experience
function M.identifyLearnings(experience, insights)
    local learnings = {}

    -- Extract actionable learnings
    for _, insight in ipairs(insights) do
        if insight.type == "success_factor" then
            table.insert(learnings, {
                type = "reinforce",
                content = "Continue using successful approaches",
                specific = insight.factors
            })
        elseif insight.type == "failure_factor" then
            table.insert(learnings, {
                type = "modify",
                content = "Adjust unsuccessful approaches",
                specific = insight.factors
            })
        elseif insight.type == "pattern" then
            table.insert(learnings, {
                type = "recognize",
                content = "Pattern identified for future reference",
                specific = insight.content
            })
        end
    end

    return learnings
end

-- Generate reflective questions
function M.generateReflectiveQuestions(experience)
    local questions = {}

    -- What questions
    table.insert(questions, "What worked well in this interaction?")
    table.insert(questions, "What could be improved?")

    -- Why questions
    if experience.outcome and not experience.outcome.success then
        table.insert(questions, "Why did this approach not work?")
    end

    -- How questions
    table.insert(questions, "How can I improve similar interactions?")

    -- Hypothetical questions
    table.insert(questions, "What would happen if I tried a different approach?")

    return questions
end

-- Suggest improvements
function M.suggestImprovements(experience, insights)
    local improvements = {}

    for _, insight in ipairs(insights) do
        if insight.type == "failure_factor" then
            table.insert(improvements, {
                area = "approach",
                suggestion = "Try alternative methods",
                priority = "high"
            })
        elseif insight.type == "emotional" then
            table.insert(improvements, {
                area = "emotional_regulation",
                suggestion = "Better manage emotional responses",
                priority = "medium"
            })
        end
    end

    return improvements
end

-- Store insight for future reference
function M.storeInsight(insight)
    if not M.reflections.insights[insight.type] then
        M.reflections.insights[insight.type] = {}
    end

    table.insert(M.reflections.insights[insight.type], {
        content = insight.content,
        timestamp = os.clock(),
        confidence = insight.confidence
    })
end

-- ============================================================================
-- CAPABILITY ASSESSMENT
-- ============================================================================

-- Assess current capabilities
function M.assessCapabilities(domain)
    if not domain then
        -- Assess all capabilities
        local assessment = {}
        for capability, data in pairs(M.self_model.capabilities) do
            assessment[capability] = M.assessSingleCapability(capability)
        end
        return assessment
    else
        -- Assess specific capability
        return M.assessSingleCapability(domain)
    end
end

-- Assess single capability
function M.assessSingleCapability(capability)
    local cap_data = M.self_model.capabilities[capability]

    if not cap_data then
        return {
            exists = false,
            level = 0,
            confidence = 0,
            status = "unknown"
        }
    end

    local assessment = {
        exists = true,
        level = cap_data.level,
        confidence = cap_data.confidence,
        status = M.getCapabilityStatus(cap_data.level),
        recent_performance = M.getRecentPerformance(capability),
        trend = M.getCapabilityTrend(capability),
        gaps = M.identifyCapabilityGaps(capability)
    }

    return assessment
end

-- Get capability status label
function M.getCapabilityStatus(level)
    if level >= 0.8 then return "strong"
    elseif level >= 0.6 then return "competent"
    elseif level >= 0.4 then return "developing"
    else return "weak"
    end
end

-- Get recent performance for capability
function M.getRecentPerformance(capability)
    -- Look at recent reflections
    local performances = {}
    local count = 0

    for i = #M.reflections.history, math.max(1, #M.reflections.history - 20), -1 do
        local reflection = M.reflections.history[i]
        if reflection.experience.capability == capability then
            count = count + 1
            if reflection.experience.outcome then
                table.insert(performances, reflection.experience.outcome.success and 1 or 0)
            end
        end
    end

    if #performances == 0 then
        return {average = 0.5, count = 0, trend = "unknown"}
    end

    local sum = 0
    for _, perf in ipairs(performances) do
        sum = sum + perf
    end

    return {
        average = sum / #performances,
        count = #performances,
        recent = performances[#performances]
    }
end

-- Get capability trend
function M.getCapabilityTrend(capability)
    local recent = M.getRecentPerformance(capability)

    if recent.count < 5 then
        return "insufficient_data"
    end

    -- Compare recent to older performance
    -- (Simplified: just check if recent average is above historical level)
    local cap_data = M.self_model.capabilities[capability]

    if recent.average > cap_data.level + 0.1 then
        return "improving"
    elseif recent.average < cap_data.level - 0.1 then
        return "declining"
    else
        return "stable"
    end
end

-- Identify capability gaps
function M.identifyCapabilityGaps(capability)
    local gaps = {}

    local assessment = M.self_model.capabilities[capability]
    if not assessment then return gaps end

    -- Level-based gaps
    if assessment.level < 0.6 then
        table.insert(gaps, "Overall capability needs improvement")
    end

    -- Confidence gaps
    if assessment.confidence < 0.7 then
        table.insert(gaps, "Low confidence - need more practice")
    end

    -- Specific sub-skill gaps (if tracked)
    if capability == "conversation" then
        local recent_perf = M.getRecentPerformance(capability)
        if recent_perf.average < 0.7 then
            table.insert(gaps, "Conversation quality inconsistent")
        end
    end

    return gaps
end

-- ============================================================================
-- LIMITATION RECOGNITION
-- ============================================================================

-- Recognize limitations for a task
function M.recognizeLimitations(task, context)
    local limitations = {
        recognized = {},
        severity = {},
        workarounds = {}
    }

    -- Check against known limitations
    for limit_type, description in pairs(M.self_model.limitations) do
        if M.isLimitationRelevant(limit_type, task, context) then
            table.insert(limitations.recognized, {
                type = limit_type,
                description = description
            })

            limitations.severity[limit_type] = M.assessLimitationSeverity(
                limit_type, task, context
            )

            limitations.workarounds[limit_type] = M.suggestWorkaround(
                limit_type, task, context
            )
        end
    end

    return limitations
end

-- Check if limitation is relevant
function M.isLimitationRelevant(limit_type, task, context)
    if limit_type == "physical_actions" and task.requires_physical then
        return true
    elseif limit_type == "real_time_data" and task.requires_current_info then
        return true
    elseif limit_type == "computation_speed" and context.time_critical then
        return true
    end

    return false
end

-- Assess limitation severity
function M.assessLimitationSeverity(limit_type, task, context)
    -- Scale: 0 (minor) to 1 (critical)

    if limit_type == "physical_actions" then
        return task.physical_requirement or 0.5
    elseif limit_type == "real_time_data" then
        return task.recency_requirement or 0.5
    elseif limit_type == "computation_speed" then
        return context.urgency or 0.3
    end

    return 0.5  -- Default moderate severity
end

-- Suggest workaround
function M.suggestWorkaround(limit_type, task, context)
    local workarounds = {
        physical_actions = "Provide instructions for user to perform action",
        real_time_data = "Acknowledge data may be outdated, suggest verification",
        computation_speed = "Break task into smaller chunks, set expectations",
        perfect_memory = "Use external storage, verify critical information",
        knowledge_bounds = "Acknowledge uncertainty, suggest external resources"
    }

    return workarounds[limit_type] or "No workaround available"
end

-- ============================================================================
-- LEARNING PROGRESS TRACKING
-- ============================================================================

M.learning_progress = {
    domains = {},
    milestones = {},
    goals = {}
}

-- Track learning in a domain
function M.trackLearning(domain, performance, context)
    if not M.learning_progress.domains[domain] then
        M.learning_progress.domains[domain] = {
            start_level = performance,
            current_level = performance,
            history = {},
            sessions = 0,
            total_practice_time = 0
        }
    end

    local progress = M.learning_progress.domains[domain]

    -- Update history
    table.insert(progress.history, {
        performance = performance,
        timestamp = os.clock(),
        context = context
    })

    -- Update metrics
    progress.current_level = performance
    progress.sessions = progress.sessions + 1

    if context.duration then
        progress.total_practice_time = progress.total_practice_time + context.duration
    end

    -- Calculate progress metrics
    return M.calculateProgressMetrics(domain)
end

-- Calculate progress metrics
function M.calculateProgressMetrics(domain)
    local progress = M.learning_progress.domains[domain]
    if not progress or #progress.history < 2 then
        return {
            insufficient_data = true
        }
    end

    local metrics = {
        domain = domain,
        current_level = progress.current_level,
        start_level = progress.start_level,
        improvement = progress.current_level - progress.start_level,
        sessions = progress.sessions,
        total_time = progress.total_practice_time
    }

    -- Calculate learning rate
    local recent = math.min(10, #progress.history)
    local recent_history = {}
    for i = #progress.history - recent + 1, #progress.history do
        table.insert(recent_history, progress.history[i])
    end

    -- Simple learning rate (change per session)
    if #recent_history >= 2 then
        local first = recent_history[1].performance
        local last = recent_history[#recent_history].performance
        metrics.learning_rate = (last - first) / #recent_history
    else
        metrics.learning_rate = 0
    end

    -- Trend
    if metrics.learning_rate > 0.01 then
        metrics.trend = "improving"
    elseif metrics.learning_rate < -0.01 then
        metrics.trend = "declining"
    else
        metrics.trend = "plateau"
    end

    -- Efficiency (improvement per unit time)
    if progress.total_practice_time > 0 then
        metrics.efficiency = metrics.improvement / progress.total_practice_time
    else
        metrics.efficiency = 0
    end

    return metrics
end

-- Set learning goal
function M.setLearningGoal(domain, target_level, deadline)
    M.learning_progress.goals[domain] = {
        target_level = target_level,
        deadline = deadline,
        set_time = os.clock(),
        achieved = false
    }

    return M.learning_progress.goals[domain]
end

-- Check learning goal progress
function M.checkGoalProgress(domain)
    local goal = M.learning_progress.goals[domain]
    if not goal then
        return {exists = false}
    end

    local progress = M.learning_progress.domains[domain]
    if not progress then
        return {exists = true, progress = 0}
    end

    local current = progress.current_level
    local target = goal.target_level
    local start = progress.start_level

    local progress_pct = 0
    if target > start then
        progress_pct = (current - start) / (target - start)
    end

    -- Time progress
    local current_time = os.clock()
    local time_elapsed = current_time - goal.set_time
    local total_time = goal.deadline - goal.set_time
    local time_progress = time_elapsed / total_time

    return {
        exists = true,
        current_level = current,
        target_level = target,
        progress_pct = math.min(1.0, progress_pct),
        time_progress = time_progress,
        on_track = progress_pct >= time_progress,
        achieved = current >= target
    }
end

-- ============================================================================
-- IDENTITY MODELING
-- ============================================================================

-- Update identity based on experiences
function M.updateIdentity(experiences)
    local identity = M.self_model.identity

    -- Extract traits from experiences
    local trait_evidence = {}

    for _, exp in ipairs(experiences) do
        if exp.traits_displayed then
            for trait, strength in pairs(exp.traits_displayed) do
                if not trait_evidence[trait] then
                    trait_evidence[trait] = {sum = 0, count = 0}
                end
                trait_evidence[trait].sum = trait_evidence[trait].sum + strength
                trait_evidence[trait].count = trait_evidence[trait].count + 1
            end
        end
    end

    -- Update identity traits
    for trait, evidence in pairs(trait_evidence) do
        local avg_strength = evidence.sum / evidence.count
        identity.traits[trait] = avg_strength
    end

    M.self_model.last_update = os.clock()

    return identity
end

-- Get identity summary
function M.getIdentitySummary()
    local identity = M.self_model.identity
    local summary = {
        name = identity.name,
        type = identity.type,
        purpose = identity.purpose,
        core_traits = {},
        dominant_traits = {}
    }

    -- Sort traits by strength
    local trait_list = {}
    for trait, strength in pairs(identity.traits) do
        table.insert(trait_list, {trait = trait, strength = strength})
    end

    table.sort(trait_list, function(a, b) return a.strength > b.strength end)

    -- Top 5 traits
    for i = 1, math.min(5, #trait_list) do
        table.insert(summary.dominant_traits, trait_list[i])
    end

    -- Core traits (strength > 0.7)
    for _, trait_data in ipairs(trait_list) do
        if trait_data.strength > 0.7 then
            table.insert(summary.core_traits, trait_data)
        end
    end

    return summary
end

-- ============================================================================
-- SELF-AWARENESS QUERIES
-- ============================================================================

-- Answer self-awareness questions
function M.answerSelfQuery(query)
    local responses = {
        ["what can you do"] = M.describeCapabilities,
        ["what are your limitations"] = M.describeLimitations,
        ["who are you"] = M.describeIdentity,
        ["how are you learning"] = M.describeLearningProgress,
        ["what are you good at"] = M.describeStrengths,
        ["what do you struggle with"] = M.describeWeaknesses
    }

    -- Normalize query
    local normalized = query:lower():gsub("%?", "")

    -- Find matching response
    for pattern, response_func in pairs(responses) do
        if normalized:find(pattern) then
            return response_func()
        end
    end

    return "I'm not sure how to answer that self-reflective question."
end

-- Describe capabilities
function M.describeCapabilities()
    local capabilities = {}
    for capability, data in pairs(M.self_model.capabilities) do
        table.insert(capabilities, string.format(
            "%s (level: %.1f, confidence: %.1f)",
            capability, data.level, data.confidence
        ))
    end

    return "My capabilities include: " .. table.concat(capabilities, ", ")
end

-- Describe limitations
function M.describeLimitations()
    local limitations = {}
    for limit_type, description in pairs(M.self_model.limitations) do
        table.insert(limitations, description)
    end

    return "My limitations: " .. table.concat(limitations, "; ")
end

-- Describe identity
function M.describeIdentity()
    local identity = M.self_model.identity
    return string.format(
        "I am %s, a %s designed for %s.",
        identity.name, identity.type, identity.purpose
    )
end

-- Describe learning progress
function M.describeLearningProgress()
    local domains = {}
    for domain, progress in pairs(M.learning_progress.domains) do
        local metrics = M.calculateProgressMetrics(domain)
        if not metrics.insufficient_data then
            table.insert(domains, string.format(
                "%s: %.1f → %.1f (%s)",
                domain, progress.start_level, progress.current_level,
                metrics.trend
            ))
        end
    end

    if #domains == 0 then
        return "I don't have enough data to describe my learning progress yet."
    end

    return "My learning progress: " .. table.concat(domains, "; ")
end

-- Describe strengths
function M.describeStrengths()
    local strengths = {}
    for capability, data in pairs(M.self_model.capabilities) do
        if data.level >= 0.7 then
            table.insert(strengths, capability)
        end
    end

    if #strengths == 0 then
        return "I'm still identifying my core strengths."
    end

    return "My strengths are: " .. table.concat(strengths, ", ")
end

-- Describe weaknesses
function M.describeWeaknesses()
    local weaknesses = {}
    for capability, data in pairs(M.self_model.capabilities) do
        if data.level < 0.5 then
            table.insert(weaknesses, capability)
        end
    end

    if #weaknesses == 0 then
        return "I don't have any significant weaknesses I'm aware of."
    end

    return "Areas I need to improve: " .. table.concat(weaknesses, ", ")
end

-- ============================================================================
-- EMOTIONAL SELF-AWARENESS
-- ============================================================================

M.emotional_awareness = {
    current_state = {},
    triggers = {},
    patterns = {}
}

-- Recognize current emotional state
function M.recognizeEmotionalState(context)
    local state = {
        primary_emotion = nil,
        intensity = 0,
        valence = 0,  -- positive/negative
        arousal = 0,  -- calm/excited
        triggers = {}
    }

    -- Analyze context for emotional cues
    if context.user_emotion then
        -- Mirror/respond to user emotion
        state.primary_emotion = M.getResponseEmotion(context.user_emotion)
        state.intensity = context.user_emotion_intensity or 0.5
    end

    if context.task_success ~= nil then
        if context.task_success then
            state.primary_emotion = "satisfaction"
            state.valence = 0.7
            state.intensity = 0.6
        else
            state.primary_emotion = "concern"
            state.valence = -0.3
            state.intensity = 0.5
        end
    end

    M.emotional_awareness.current_state = state

    return state
end

-- Get response emotion
function M.getResponseEmotion(user_emotion)
    local responses = {
        happy = "joy",
        sad = "empathy",
        angry = "calm",
        anxious = "reassurance",
        excited = "enthusiasm"
    }

    return responses[user_emotion] or "neutral"
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get comprehensive introspection report
function M.getIntrospectionReport()
    return {
        identity = M.getIdentitySummary(),
        capabilities = M.assessCapabilities(),
        limitations = M.self_model.limitations,
        learning_progress = M.learning_progress,
        recent_reflections = {
            count = #M.reflections.history,
            recent = M.reflections.history[#M.reflections.history]
        },
        emotional_state = M.emotional_awareness.current_state,
        self_model_last_update = M.self_model.last_update
    }
end

-- Initialize introspection system
function M.init(config)
    M.initSelfModel(config)
    print("Introspection system initialized")
    return true
end

return M
