-- Module: meta_cognition.lua
-- Meta-cognitive processes: thinking about thinking
-- Implements self-awareness, confidence calibration, uncertainty estimation,
-- decision quality assessment, and cognitive monitoring

local M = {}

-- ============================================================================
-- CONFIDENCE CALIBRATION SYSTEM
-- ============================================================================

-- Tracks prediction accuracy vs confidence to calibrate future predictions
M.confidence_history = {
    predictions = {},  -- {confidence, was_correct, task_type, timestamp}
    calibration_curves = {},  -- By task type
    max_history = 1000
}

-- Add a prediction outcome for calibration
function M.recordPredictionOutcome(confidence, was_correct, task_type, context)
    task_type = task_type or "general"

    table.insert(M.confidence_history.predictions, {
        confidence = confidence,
        correct = was_correct,
        task_type = task_type,
        context = context or {},
        timestamp = os.clock()
    })

    -- Maintain history limit
    if #M.confidence_history.predictions > M.confidence_history.max_history then
        table.remove(M.confidence_history.predictions, 1)
    end

    -- Update calibration curve
    M.updateCalibrationCurve(task_type)
end

-- Calculate calibration curve for a task type
function M.updateCalibrationCurve(task_type)
    local predictions = {}

    -- Filter predictions for this task type
    for _, pred in ipairs(M.confidence_history.predictions) do
        if pred.task_type == task_type then
            table.insert(predictions, pred)
        end
    end

    if #predictions < 10 then return nil end

    -- Create bins for confidence levels
    local bins = {}
    for i = 1, 10 do
        bins[i] = {
            conf_min = (i-1) / 10,
            conf_max = i / 10,
            total = 0,
            correct = 0,
            avg_confidence = 0
        }
    end

    -- Populate bins
    for _, pred in ipairs(predictions) do
        local bin_idx = math.min(10, math.floor(pred.confidence * 10) + 1)
        bins[bin_idx].total = bins[bin_idx].total + 1
        bins[bin_idx].avg_confidence = bins[bin_idx].avg_confidence + pred.confidence
        if pred.correct then
            bins[bin_idx].correct = bins[bin_idx].correct + 1
        end
    end

    -- Calculate accuracy per bin
    for _, bin in ipairs(bins) do
        if bin.total > 0 then
            bin.accuracy = bin.correct / bin.total
            bin.avg_confidence = bin.avg_confidence / bin.total
        else
            bin.accuracy = 0
            bin.avg_confidence = 0
        end
    end

    M.confidence_history.calibration_curves[task_type] = bins

    return bins
end

-- Get calibrated confidence based on raw confidence and task type
function M.getCalibratedConfidence(raw_confidence, task_type)
    task_type = task_type or "general"

    local curve = M.confidence_history.calibration_curves[task_type]
    if not curve then return raw_confidence end

    -- Find appropriate bin
    local bin_idx = math.min(10, math.floor(raw_confidence * 10) + 1)
    local bin = curve[bin_idx]

    if not bin or bin.total < 5 then
        return raw_confidence  -- Not enough data
    end

    -- Return calibrated confidence (actual accuracy at this confidence level)
    return bin.accuracy
end

-- Get calibration metrics
function M.getCalibrationMetrics(task_type)
    task_type = task_type or "general"

    local predictions = {}
    for _, pred in ipairs(M.confidence_history.predictions) do
        if pred.task_type == task_type then
            table.insert(predictions, pred)
        end
    end

    if #predictions == 0 then
        return {
            total_predictions = 0,
            overall_accuracy = 0,
            calibration_error = 0,
            overconfidence = 0
        }
    end

    -- Calculate overall accuracy
    local correct = 0
    local total_conf = 0
    local total_error = 0

    for _, pred in ipairs(predictions) do
        if pred.correct then correct = correct + 1 end
        total_conf = total_conf + pred.confidence

        -- Expected calibration error (ECE)
        local actual = pred.correct and 1 or 0
        total_error = total_error + math.abs(pred.confidence - actual)
    end

    local accuracy = correct / #predictions
    local avg_confidence = total_conf / #predictions
    local calibration_error = total_error / #predictions
    local overconfidence = avg_confidence - accuracy

    return {
        total_predictions = #predictions,
        overall_accuracy = accuracy,
        average_confidence = avg_confidence,
        calibration_error = calibration_error,
        overconfidence = overconfidence,
        underconfident = overconfidence < -0.05,
        well_calibrated = math.abs(overconfidence) < 0.05,
        overconfident = overconfidence > 0.05
    }
end

-- ============================================================================
-- UNCERTAINTY ESTIMATION
-- ============================================================================

M.uncertainty = {
    sources = {},  -- Different sources of uncertainty
    current_state = {}
}

-- Types of uncertainty
M.UNCERTAINTY_TYPES = {
    EPISTEMIC = "epistemic",  -- Lack of knowledge (reducible)
    ALEATORIC = "aleatoric",  -- Inherent randomness (irreducible)
    MODEL = "model",          -- Model limitations
    DATA = "data"             -- Data quality/quantity
}

-- Estimate uncertainty for a task
function M.estimateUncertainty(task, context)
    local uncertainty = {
        total = 0,
        components = {},
        dominant_source = nil,
        confidence_interval = {lower = 0, upper = 1}
    }

    -- Epistemic uncertainty (knowledge gaps)
    local epistemic = M.estimateEpistemicUncertainty(task, context)
    uncertainty.components.epistemic = epistemic
    uncertainty.total = uncertainty.total + epistemic.value

    -- Aleatoric uncertainty (randomness)
    local aleatoric = M.estimateAleatoricUncertainty(task, context)
    uncertainty.components.aleatoric = aleatoric
    uncertainty.total = uncertainty.total + aleatoric.value

    -- Model uncertainty
    local model = M.estimateModelUncertainty(task, context)
    uncertainty.components.model = model
    uncertainty.total = uncertainty.total + model.value

    -- Data uncertainty
    local data = M.estimateDataUncertainty(task, context)
    uncertainty.components.data = data
    uncertainty.total = uncertainty.total + data.value

    -- Normalize
    uncertainty.total = math.min(1.0, uncertainty.total)

    -- Find dominant source
    local max_val = 0
    for source, component in pairs(uncertainty.components) do
        if component.value > max_val then
            max_val = component.value
            uncertainty.dominant_source = source
        end
    end

    -- Estimate confidence interval
    uncertainty.confidence_interval = M.calculateConfidenceInterval(
        uncertainty.total, context
    )

    return uncertainty
end

-- Estimate epistemic (knowledge) uncertainty
function M.estimateEpistemicUncertainty(task, context)
    local uncertainty = {
        value = 0,
        reasons = {}
    }

    -- Check knowledge base coverage
    if context.knowledge_coverage then
        local coverage = context.knowledge_coverage
        if coverage < 0.3 then
            uncertainty.value = uncertainty.value + 0.4
            table.insert(uncertainty.reasons, "low knowledge coverage")
        elseif coverage < 0.6 then
            uncertainty.value = uncertainty.value + 0.2
            table.insert(uncertainty.reasons, "moderate knowledge coverage")
        end
    end

    -- Check memory/experience
    if context.similar_experiences then
        if context.similar_experiences < 5 then
            uncertainty.value = uncertainty.value + 0.3
            table.insert(uncertainty.reasons, "limited experience")
        end
    end

    -- Check task familiarity
    if context.task_familiarity then
        uncertainty.value = uncertainty.value + (1 - context.task_familiarity) * 0.4
        if context.task_familiarity < 0.3 then
            table.insert(uncertainty.reasons, "unfamiliar task type")
        end
    end

    return uncertainty
end

-- Estimate aleatoric (randomness) uncertainty
function M.estimateAleatoricUncertainty(task, context)
    local uncertainty = {
        value = 0,
        reasons = {}
    }

    -- Check input variability
    if context.input_variability then
        uncertainty.value = uncertainty.value + context.input_variability * 0.3
        if context.input_variability > 0.7 then
            table.insert(uncertainty.reasons, "high input variability")
        end
    end

    -- Check stochastic elements
    if context.has_randomness then
        uncertainty.value = uncertainty.value + 0.2
        table.insert(uncertainty.reasons, "inherent randomness")
    end

    -- Check ambiguity
    if context.ambiguity_level then
        uncertainty.value = uncertainty.value + context.ambiguity_level * 0.4
        if context.ambiguity_level > 0.6 then
            table.insert(uncertainty.reasons, "ambiguous input")
        end
    end

    return uncertainty
end

-- Estimate model uncertainty
function M.estimateModelUncertainty(task, context)
    local uncertainty = {
        value = 0,
        reasons = {}
    }

    -- Check model complexity vs task
    if context.model_complexity and context.task_complexity then
        local complexity_gap = context.task_complexity - context.model_complexity
        if complexity_gap > 0.3 then
            uncertainty.value = uncertainty.value + complexity_gap * 0.5
            table.insert(uncertainty.reasons, "model may be too simple")
        end
    end

    -- Check model disagreement (if ensemble)
    if context.model_disagreement then
        uncertainty.value = uncertainty.value + context.model_disagreement * 0.4
        if context.model_disagreement > 0.5 then
            table.insert(uncertainty.reasons, "high model disagreement")
        end
    end

    -- Check training data distribution
    if context.out_of_distribution_score then
        uncertainty.value = uncertainty.value + context.out_of_distribution_score * 0.5
        if context.out_of_distribution_score > 0.7 then
            table.insert(uncertainty.reasons, "out of distribution")
        end
    end

    return uncertainty
end

-- Estimate data uncertainty
function M.estimateDataUncertainty(task, context)
    local uncertainty = {
        value = 0,
        reasons = {}
    }

    -- Check data quality
    if context.data_quality then
        uncertainty.value = uncertainty.value + (1 - context.data_quality) * 0.4
        if context.data_quality < 0.5 then
            table.insert(uncertainty.reasons, "poor data quality")
        end
    end

    -- Check data quantity
    if context.data_quantity then
        if context.data_quantity < 0.3 then
            uncertainty.value = uncertainty.value + 0.3
            table.insert(uncertainty.reasons, "insufficient data")
        end
    end

    -- Check data recency
    if context.data_staleness then
        uncertainty.value = uncertainty.value + context.data_staleness * 0.3
        if context.data_staleness > 0.7 then
            table.insert(uncertainty.reasons, "stale data")
        end
    end

    return uncertainty
end

-- Calculate confidence interval
function M.calculateConfidenceInterval(uncertainty, context)
    local confidence_level = context.confidence_level or 0.95

    -- Convert uncertainty to standard error
    local std_error = uncertainty * 0.5

    -- Z-score for confidence level (approximation)
    local z_scores = {
        [0.90] = 1.645,
        [0.95] = 1.96,
        [0.99] = 2.576
    }
    local z = z_scores[confidence_level] or 1.96

    -- Calculate interval
    local margin = z * std_error
    local point_estimate = context.point_estimate or 0.5

    return {
        lower = math.max(0, point_estimate - margin),
        upper = math.min(1, point_estimate + margin),
        width = margin * 2,
        confidence_level = confidence_level
    }
end

-- ============================================================================
-- DECISION QUALITY ASSESSMENT
-- ============================================================================

M.decisions = {
    history = {},  -- Past decisions and outcomes
    metrics = {},
    max_history = 500
}

-- Record a decision
function M.recordDecision(decision)
    table.insert(M.decisions.history, {
        timestamp = os.clock(),
        options = decision.options or {},
        chosen = decision.chosen,
        reasoning = decision.reasoning or "",
        confidence = decision.confidence or 0.5,
        context = decision.context or {},
        outcome = nil,  -- To be filled later
        quality_score = nil
    })

    if #M.decisions.history > M.decisions.max_history then
        table.remove(M.decisions.history, 1)
    end
end

-- Record decision outcome
function M.recordDecisionOutcome(decision_idx, outcome)
    if decision_idx < 1 or decision_idx > #M.decisions.history then
        return false
    end

    local decision = M.decisions.history[decision_idx]
    decision.outcome = outcome
    decision.quality_score = M.assessDecisionQuality(decision, outcome)

    return true
end

-- Assess decision quality
function M.assessDecisionQuality(decision, outcome)
    local quality = {
        score = 0,
        factors = {}
    }

    -- Outcome quality (0-1)
    local outcome_score = outcome.success and 1 or 0
    if outcome.value then
        outcome_score = outcome.value
    end
    quality.factors.outcome = outcome_score * 0.4

    -- Process quality (was reasoning sound?)
    local process_score = M.assessReasoningQuality(decision.reasoning, decision.options)
    quality.factors.process = process_score * 0.3

    -- Confidence calibration (was confidence appropriate?)
    local calibration_score = 1 - math.abs(decision.confidence - outcome_score)
    quality.factors.calibration = calibration_score * 0.2

    -- Efficiency (time, resources)
    if outcome.efficiency then
        quality.factors.efficiency = outcome.efficiency * 0.1
    else
        quality.factors.efficiency = 0.05
    end

    -- Calculate total
    for _, factor_score in pairs(quality.factors) do
        quality.score = quality.score + factor_score
    end

    return quality
end

-- Assess reasoning quality
function M.assessReasoningQuality(reasoning, options)
    local score = 0.5  -- Start neutral

    if not reasoning or reasoning == "" then
        return 0.3  -- Weak reasoning
    end

    -- Check for consideration of alternatives
    local mentioned_alternatives = 0
    for _, option in ipairs(options or {}) do
        if reasoning:find(option.name) then
            mentioned_alternatives = mentioned_alternatives + 1
        end
    end

    if mentioned_alternatives > 1 then
        score = score + 0.2
    end

    -- Check for pros/cons consideration
    if reasoning:find("because") or reasoning:find("advantage") or
       reasoning:find("benefit") or reasoning:find("drawback") then
        score = score + 0.2
    end

    -- Check for evidence
    if reasoning:find("data") or reasoning:find("evidence") or
       reasoning:find("shows") or reasoning:find("indicates") then
        score = score + 0.1
    end

    return math.min(1.0, score)
end

-- Get decision-making statistics
function M.getDecisionStats(time_window)
    time_window = time_window or math.huge
    local current_time = os.clock()

    local stats = {
        total_decisions = 0,
        evaluated_decisions = 0,
        avg_quality = 0,
        avg_confidence = 0,
        confidence_accuracy = 0,
        decision_speed = 0
    }

    local quality_sum = 0
    local conf_sum = 0
    local conf_accuracy_sum = 0
    local evaluated = 0

    for _, decision in ipairs(M.decisions.history) do
        if current_time - decision.timestamp <= time_window then
            stats.total_decisions = stats.total_decisions + 1
            conf_sum = conf_sum + (decision.confidence or 0.5)

            if decision.quality_score then
                evaluated = evaluated + 1
                quality_sum = quality_sum + decision.quality_score.score

                -- Check confidence accuracy
                local outcome_score = decision.outcome.success and 1 or
                                     (decision.outcome.value or 0)
                conf_accuracy_sum = conf_accuracy_sum +
                                   (1 - math.abs(decision.confidence - outcome_score))
            end
        end
    end

    if stats.total_decisions > 0 then
        stats.avg_confidence = conf_sum / stats.total_decisions
    end

    if evaluated > 0 then
        stats.evaluated_decisions = evaluated
        stats.avg_quality = quality_sum / evaluated
        stats.confidence_accuracy = conf_accuracy_sum / evaluated
    end

    return stats
end

-- ============================================================================
-- COGNITIVE MONITORING
-- ============================================================================

M.cognitive_state = {
    attention = 1.0,
    focus_quality = 1.0,
    mental_fatigue = 0.0,
    cognitive_load = 0.0,
    processing_speed = 1.0,
    error_rate = 0.0,
    last_update = 0
}

-- Update cognitive state
function M.updateCognitiveState(context)
    local state = M.cognitive_state
    local current_time = os.clock()
    local time_delta = current_time - state.last_update

    -- Attention drift over time
    state.attention = math.max(0.3, state.attention - time_delta * 0.01)

    -- Mental fatigue accumulation
    if context.task_difficulty then
        state.mental_fatigue = math.min(1.0,
            state.mental_fatigue + context.task_difficulty * 0.05)
    end

    -- Cognitive load from active tasks
    if context.active_tasks then
        state.cognitive_load = math.min(1.0, #context.active_tasks * 0.2)
    end

    -- Processing speed (affected by fatigue and load)
    state.processing_speed = 1.0 - (state.mental_fatigue * 0.3) -
                                   (state.cognitive_load * 0.2)

    -- Focus quality
    state.focus_quality = state.attention * state.processing_speed

    -- Error rate (increases with fatigue and load)
    state.error_rate = (state.mental_fatigue * 0.4) + (state.cognitive_load * 0.3)

    state.last_update = current_time

    return state
end

-- Refresh cognitive resources (rest/reset)
function M.refreshCognitiveResources(amount)
    amount = amount or 1.0

    local state = M.cognitive_state
    state.attention = math.min(1.0, state.attention + amount * 0.5)
    state.mental_fatigue = math.max(0.0, state.mental_fatigue - amount * 0.7)
    state.cognitive_load = math.max(0.0, state.cognitive_load - amount * 0.3)

    return state
end

-- Check if cognitive resources are depleted
function M.needsCognitiveRest()
    local state = M.cognitive_state

    return state.mental_fatigue > 0.7 or
           state.cognitive_load > 0.8 or
           state.attention < 0.4 or
           state.focus_quality < 0.5
end

-- Get cognitive capacity for new task
function M.getCognitiveCapacity()
    local state = M.cognitive_state

    local capacity = (1 - state.cognitive_load) * state.focus_quality *
                     (1 - state.error_rate)

    return {
        available = capacity,
        quality = state.focus_quality,
        reliability = 1 - state.error_rate,
        recommendation = capacity > 0.6 and "good" or
                        capacity > 0.3 and "acceptable" or "rest_needed"
    }
end

-- ============================================================================
-- THINKING STRATEGIES
-- ============================================================================

M.thinking_strategies = {
    current_strategy = nil,
    strategy_history = {},
    strategy_effectiveness = {}
}

-- Available thinking strategies
M.STRATEGIES = {
    FAST = {
        name = "fast_intuitive",
        description = "Quick, intuitive thinking (System 1)",
        accuracy_target = 0.7,
        speed_multiplier = 2.0,
        cognitive_load = 0.3
    },
    SLOW = {
        name = "slow_analytical",
        description = "Deliberate, analytical thinking (System 2)",
        accuracy_target = 0.9,
        speed_multiplier = 0.5,
        cognitive_load = 0.8
    },
    CREATIVE = {
        name = "creative_divergent",
        description = "Divergent, creative exploration",
        accuracy_target = 0.6,
        speed_multiplier = 0.7,
        cognitive_load = 0.6
    },
    CRITICAL = {
        name = "critical_evaluation",
        description = "Critical analysis and evaluation",
        accuracy_target = 0.85,
        speed_multiplier = 0.6,
        cognitive_load = 0.7
    }
}

-- Select thinking strategy
function M.selectThinkingStrategy(task, context)
    -- Consider task requirements
    local urgency = context.urgency or 0.5
    local complexity = context.complexity or 0.5
    local cognitive_capacity = M.getCognitiveCapacity().available

    local selected = nil

    -- High urgency, low complexity → Fast
    if urgency > 0.7 and complexity < 0.5 then
        selected = M.STRATEGIES.FAST

    -- High complexity, time available → Slow
    elseif complexity > 0.6 and urgency < 0.5 and cognitive_capacity > 0.6 then
        selected = M.STRATEGIES.SLOW

    -- Open-ended, exploration needed → Creative
    elseif context.requires_creativity or (not context.clear_criteria) then
        selected = M.STRATEGIES.CREATIVE

    -- Evaluation task → Critical
    elseif context.evaluation_task then
        selected = M.STRATEGIES.CRITICAL

    -- Default based on cognitive capacity
    else
        selected = cognitive_capacity > 0.6 and M.STRATEGIES.SLOW or M.STRATEGIES.FAST
    end

    M.thinking_strategies.current_strategy = selected

    return selected
end

-- Apply thinking strategy
function M.applyThinkingStrategy(strategy, task_function, context)
    local start_time = os.clock()

    -- Adjust cognitive load
    M.cognitive_state.cognitive_load = strategy.cognitive_load

    -- Execute task with strategy
    local result, success = task_function(context)

    local end_time = os.clock()
    local duration = end_time - start_time

    -- Record strategy use
    table.insert(M.thinking_strategies.strategy_history, {
        strategy = strategy.name,
        task = context.task_type,
        duration = duration,
        success = success,
        timestamp = start_time
    })

    -- Update effectiveness
    M.updateStrategyEffectiveness(strategy.name, success, duration)

    return result, success
end

-- Update strategy effectiveness
function M.updateStrategyEffectiveness(strategy_name, success, duration)
    if not M.thinking_strategies.strategy_effectiveness[strategy_name] then
        M.thinking_strategies.strategy_effectiveness[strategy_name] = {
            uses = 0,
            successes = 0,
            avg_duration = 0,
            total_duration = 0
        }
    end

    local eff = M.thinking_strategies.strategy_effectiveness[strategy_name]
    eff.uses = eff.uses + 1
    if success then
        eff.successes = eff.successes + 1
    end
    eff.total_duration = eff.total_duration + duration
    eff.avg_duration = eff.total_duration / eff.uses
    eff.success_rate = eff.successes / eff.uses
end

-- ============================================================================
-- META-LEARNING (Learning to Learn)
-- ============================================================================

M.meta_learning = {
    learning_strategies = {},
    strategy_performance = {},
    adaptation_history = {}
}

-- Learning strategies
M.LEARNING_STRATEGIES = {
    REPETITION = "repetition",
    ELABORATION = "elaboration",
    ORGANIZATION = "organization",
    METACOGNITIVE = "metacognitive",
    INTERLEAVING = "interleaving"
}

-- Track learning episode
function M.recordLearningEpisode(strategy, task_type, performance)
    table.insert(M.meta_learning.adaptation_history, {
        strategy = strategy,
        task_type = task_type,
        performance = performance,
        timestamp = os.clock()
    })

    -- Update strategy performance
    if not M.meta_learning.strategy_performance[strategy] then
        M.meta_learning.strategy_performance[strategy] = {
            total = 0,
            sum_performance = 0,
            by_task = {}
        }
    end

    local perf = M.meta_learning.strategy_performance[strategy]
    perf.total = perf.total + 1
    perf.sum_performance = perf.sum_performance + performance
    perf.avg_performance = perf.sum_performance / perf.total

    -- By task type
    if not perf.by_task[task_type] then
        perf.by_task[task_type] = {total = 0, sum = 0}
    end
    perf.by_task[task_type].total = perf.by_task[task_type].total + 1
    perf.by_task[task_type].sum = perf.by_task[task_type].sum + performance
    perf.by_task[task_type].avg = perf.by_task[task_type].sum /
                                   perf.by_task[task_type].total
end

-- Recommend learning strategy
function M.recommendLearningStrategy(task_type, context)
    local performances = {}

    for strategy, perf in pairs(M.meta_learning.strategy_performance) do
        local task_perf = perf.by_task[task_type]
        if task_perf and task_perf.total >= 3 then
            performances[strategy] = task_perf.avg
        else
            performances[strategy] = perf.avg_performance or 0.5
        end
    end

    -- Find best strategy
    local best_strategy = nil
    local best_performance = 0

    for strategy, performance in pairs(performances) do
        if performance > best_performance then
            best_performance = performance
            best_strategy = strategy
        end
    end

    return best_strategy or M.LEARNING_STRATEGIES.METACOGNITIVE
end

-- ============================================================================
-- SELF-MONITORING
-- ============================================================================

-- Monitor own performance
function M.monitorPerformance(task, result, expected)
    local monitoring = {
        task = task,
        timestamp = os.clock(),
        result = result,
        expected = expected,
        discrepancy = nil,
        needs_attention = false,
        corrective_action = nil
    }

    -- Check for discrepancy
    if expected then
        if type(result) == "number" and type(expected) == "number" then
            monitoring.discrepancy = math.abs(result - expected)
            monitoring.needs_attention = monitoring.discrepancy > 0.2
        elseif result ~= expected then
            monitoring.discrepancy = "mismatch"
            monitoring.needs_attention = true
        end
    end

    -- Suggest corrective action
    if monitoring.needs_attention then
        monitoring.corrective_action = M.suggestCorrectiveAction(
            task, monitoring.discrepancy
        )
    end

    return monitoring
end

-- Suggest corrective action
function M.suggestCorrectiveAction(task, discrepancy)
    local actions = {}

    if type(discrepancy) == "number" then
        if discrepancy > 0.5 then
            table.insert(actions, "review task requirements")
            table.insert(actions, "check for systematic errors")
        elseif discrepancy > 0.2 then
            table.insert(actions, "refine approach")
            table.insert(actions, "gather more information")
        end
    else
        table.insert(actions, "re-evaluate task understanding")
        table.insert(actions, "consider alternative approaches")
    end

    return actions
end

-- ============================================================================
-- KNOWLEDGE ABOUT OWN CAPABILITIES
-- ============================================================================

M.capability_knowledge = {
    strengths = {},
    weaknesses = {},
    limits = {},
    learning_curves = {}
}

-- Update capability knowledge
function M.updateCapabilityKnowledge(domain, performance, context)
    -- Track performance trend
    if not M.capability_knowledge.learning_curves[domain] then
        M.capability_knowledge.learning_curves[domain] = {}
    end

    table.insert(M.capability_knowledge.learning_curves[domain], {
        performance = performance,
        timestamp = os.clock(),
        context = context
    })

    -- Analyze trend
    local curve = M.capability_knowledge.learning_curves[domain]
    if #curve >= 5 then
        local recent = {curve[#curve-4], curve[#curve-3], curve[#curve-2],
                       curve[#curve-1], curve[#curve]}
        local avg_recent = 0
        for _, point in ipairs(recent) do
            avg_recent = avg_recent + point.performance
        end
        avg_recent = avg_recent / #recent

        -- Classify
        if avg_recent > 0.8 then
            M.capability_knowledge.strengths[domain] = avg_recent
            M.capability_knowledge.weaknesses[domain] = nil
        elseif avg_recent < 0.5 then
            M.capability_knowledge.weaknesses[domain] = avg_recent
            M.capability_knowledge.strengths[domain] = nil
        end
    end
end

-- Get capability assessment
function M.getCapabilityAssessment(domain)
    if M.capability_knowledge.strengths[domain] then
        return {
            level = "strong",
            score = M.capability_knowledge.strengths[domain],
            confidence = "high"
        }
    elseif M.capability_knowledge.weaknesses[domain] then
        return {
            level = "weak",
            score = M.capability_knowledge.weaknesses[domain],
            confidence = "high"
        }
    else
        return {
            level = "unknown",
            score = 0.5,
            confidence = "low"
        }
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get comprehensive meta-cognitive status
function M.getMetaCognitiveStatus()
    return {
        cognitive_state = M.cognitive_state,
        capacity = M.getCognitiveCapacity(),
        current_strategy = M.thinking_strategies.current_strategy,
        calibration = M.getCalibrationMetrics("general"),
        decision_stats = M.getDecisionStats(3600),  -- Last hour
        strengths = M.capability_knowledge.strengths,
        weaknesses = M.capability_knowledge.weaknesses,
        needs_rest = M.needsCognitiveRest()
    }
end

-- Initialize meta-cognition system
function M.init()
    M.cognitive_state.last_update = os.clock()
    print("Meta-cognition system initialized")
    return true
end

return M
