-- Module: philosophical_reasoning.lua
-- Deep philosophical reasoning capabilities
-- Implements ethical reasoning, logical inference, abstract thinking,
-- counterfactual reasoning, and philosophical question handling

local M = {}

-- ============================================================================
-- ETHICAL REASONING SYSTEM
-- ============================================================================

M.ethics = {
    frameworks = {},
    values = {},
    dilemmas = {},
    principles = {}
}

-- Ethical frameworks
M.ETHICAL_FRAMEWORKS = {
    UTILITARIAN = {
        name = "utilitarian",
        principle = "maximize overall well-being",
        evaluate = function(action, context)
            return M.evaluateUtilitarian(action, context)
        end
    },
    DEONTOLOGICAL = {
        name = "deontological",
        principle = "follow moral duties and rules",
        evaluate = function(action, context)
            return M.evaluateDeontological(action, context)
        end
    },
    VIRTUE = {
        name = "virtue_ethics",
        principle = "act according to virtues",
        evaluate = function(action, context)
            return M.evaluateVirtueEthics(action, context)
        end
    },
    CARE = {
        name = "care_ethics",
        principle = "prioritize relationships and care",
        evaluate = function(action, context)
            return M.evaluateCareEthics(action, context)
        end
    }
}

-- Core ethical principles
M.ethics.principles = {
    autonomy = 0.9,
    beneficence = 0.95,
    non_maleficence = 1.0,
    justice = 0.9,
    honesty = 0.95,
    respect = 0.9
}

-- Evaluate action ethically
function M.evaluateEthicalAction(action, context, framework)
    framework = framework or "utilitarian"

    local eval_framework = M.ETHICAL_FRAMEWORKS[framework:upper()]
    if not eval_framework then
        eval_framework = M.ETHICAL_FRAMEWORKS.UTILITARIAN
    end

    local evaluation = {
        action = action,
        framework = framework,
        score = 0,
        reasoning = {},
        concerns = {},
        alternatives = {}
    }

    -- Apply framework
    evaluation.score, evaluation.reasoning = eval_framework.evaluate(action, context)

    -- Check against core principles
    local principle_violations = M.checkPrincipleViolations(action, context)
    for _, violation in ipairs(principle_violations) do
        table.insert(evaluation.concerns, violation)
        evaluation.score = evaluation.score * 0.8  -- Reduce score for violations
    end

    -- Suggest alternatives if score is low
    if evaluation.score < 0.6 then
        evaluation.alternatives = M.suggestEthicalAlternatives(action, context)
    end

    return evaluation
end

-- Utilitarian evaluation (maximize well-being)
function M.evaluateUtilitarian(action, context)
    local score = 0.5  -- Start neutral
    local reasoning = {}

    -- Calculate net benefit
    local benefits = context.benefits or {}
    local harms = context.harms or {}

    local benefit_sum = 0
    for _, benefit in ipairs(benefits) do
        benefit_sum = benefit_sum + (benefit.magnitude or 0) * (benefit.probability or 1)
    end

    local harm_sum = 0
    for _, harm in ipairs(harms) do
        harm_sum = harm_sum + (harm.magnitude or 0) * (harm.probability or 1)
    end

    local net_benefit = benefit_sum - harm_sum

    -- Scale to 0-1
    score = 0.5 + (net_benefit * 0.1)  -- Adjust scaling as needed
    score = math.max(0, math.min(1, score))

    table.insert(reasoning, string.format(
        "Net benefit: %.2f (benefits: %.2f, harms: %.2f)",
        net_benefit, benefit_sum, harm_sum
    ))

    -- Consider distribution
    if context.distribution then
        if context.distribution == "equal" then
            table.insert(reasoning, "Benefits distributed equally")
        else
            table.insert(reasoning, "Unequal distribution may reduce utility")
            score = score * 0.9
        end
    end

    return score, reasoning
end

-- Deontological evaluation (duty-based)
function M.evaluateDeontological(action, context)
    local score = 0.5
    local reasoning = {}

    -- Check against moral rules
    local rules_followed = 0
    local rules_broken = 0

    local moral_rules = {
        "do not lie",
        "do not harm",
        "keep promises",
        "respect autonomy",
        "be just"
    }

    -- Simple rule checking
    if action.involves_deception then
        rules_broken = rules_broken + 1
        table.insert(reasoning, "Violates: do not lie")
    else
        rules_followed = rules_followed + 1
    end

    if action.causes_harm then
        rules_broken = rules_broken + 1
        table.insert(reasoning, "Violates: do not harm")
    else
        rules_followed = rules_followed + 1
    end

    if context.promises and not action.keeps_promises then
        rules_broken = rules_broken + 1
        table.insert(reasoning, "Violates: keep promises")
    end

    if action.respects_autonomy then
        rules_followed = rules_followed + 1
        table.insert(reasoning, "Follows: respect autonomy")
    end

    -- Calculate score
    local total_rules = rules_followed + rules_broken
    if total_rules > 0 then
        score = rules_followed / total_rules
    end

    return score, reasoning
end

-- Virtue ethics evaluation (character-based)
function M.evaluateVirtueEthics(action, context)
    local score = 0.5
    local reasoning = {}

    -- Check virtues demonstrated
    local virtues = {
        courage = 0,
        temperance = 0,
        wisdom = 0,
        justice = 0,
        compassion = 0,
        honesty = 0
    }

    -- Analyze action for virtues
    if action.requires_courage then
        virtues.courage = 0.8
        table.insert(reasoning, "Demonstrates courage")
    end

    if action.shows_restraint then
        virtues.temperance = 0.8
        table.insert(reasoning, "Shows temperance")
    end

    if action.well_considered then
        virtues.wisdom = 0.8
        table.insert(reasoning, "Demonstrates wisdom")
    end

    if action.is_fair then
        virtues.justice = 0.8
        table.insert(reasoning, "Acts with justice")
    end

    if action.shows_care then
        virtues.compassion = 0.8
        table.insert(reasoning, "Shows compassion")
    end

    if action.is_truthful then
        virtues.honesty = 0.8
        table.insert(reasoning, "Demonstrates honesty")
    end

    -- Calculate average virtue score
    local virtue_sum = 0
    local virtue_count = 0
    for virtue, value in pairs(virtues) do
        if value > 0 then
            virtue_sum = virtue_sum + value
            virtue_count = virtue_count + 1
        end
    end

    if virtue_count > 0 then
        score = virtue_sum / virtue_count
    end

    return score, reasoning
end

-- Care ethics evaluation (relationship-based)
function M.evaluateCareEthics(action, context)
    local score = 0.5
    local reasoning = {}

    -- Evaluate care and relationships
    if action.strengthens_relationships then
        score = score + 0.3
        table.insert(reasoning, "Strengthens relationships")
    end

    if action.shows_empathy then
        score = score + 0.2
        table.insert(reasoning, "Demonstrates empathy")
    end

    if action.responsive_to_needs then
        score = score + 0.2
        table.insert(reasoning, "Responsive to others' needs")
    end

    if action.maintains_trust then
        score = score + 0.2
        table.insert(reasoning, "Maintains trust")
    end

    -- Deductions
    if action.damages_relationships then
        score = score - 0.4
        table.insert(reasoning, "May damage relationships")
    end

    score = math.max(0, math.min(1, score))

    return score, reasoning
end

-- Check principle violations
function M.checkPrincipleViolations(action, context)
    local violations = {}

    if action.violates_autonomy then
        table.insert(violations, {
            principle = "autonomy",
            severity = 0.8,
            description = "Violates individual autonomy"
        })
    end

    if action.causes_harm then
        table.insert(violations, {
            principle = "non_maleficence",
            severity = 0.9,
            description = "Causes harm"
        })
    end

    if action.unjust then
        table.insert(violations, {
            principle = "justice",
            severity = 0.7,
            description = "Violates justice"
        })
    end

    if action.dishonest then
        table.insert(violations, {
            principle = "honesty",
            severity = 0.7,
            description = "Involves dishonesty"
        })
    end

    return violations
end

-- Suggest ethical alternatives
function M.suggestEthicalAlternatives(action, context)
    local alternatives = {}

    -- Generic ethical improvements
    table.insert(alternatives, {
        action = "Increase transparency",
        rationale = "Openness often improves ethical standing"
    })

    table.insert(alternatives, {
        action = "Seek consent from affected parties",
        rationale = "Respects autonomy"
    })

    table.insert(alternatives, {
        action = "Distribute benefits more equally",
        rationale = "Improves justice and fairness"
    })

    return alternatives
end

-- ============================================================================
-- LOGICAL INFERENCE ENGINE
-- ============================================================================

M.logic = {
    rules = {},
    facts = {},
    inferences = {}
}

-- Logical operators
M.LOGIC_OPS = {
    AND = function(a, b) return a and b end,
    OR = function(a, b) return a or b end,
    NOT = function(a) return not a end,
    IMPLIES = function(a, b) return (not a) or b end,
    IFF = function(a, b) return (a and b) or (not a and not b) end
}

-- Add logical rule
function M.addLogicalRule(rule)
    table.insert(M.logic.rules, rule)
end

-- Add fact
function M.addFact(fact, truth_value)
    M.logic.facts[fact] = truth_value
end

-- Perform logical inference
function M.inferLogical(query)
    -- Check if query is a known fact
    if M.logic.facts[query] ~= nil then
        return M.logic.facts[query], "direct_fact"
    end

    -- Try to derive from rules
    for _, rule in ipairs(M.logic.rules) do
        if rule.conclusion == query then
            -- Check if premises are satisfied
            local premises_satisfied = M.checkPremises(rule.premises)

            if premises_satisfied then
                -- Infer conclusion
                M.logic.facts[query] = true
                table.insert(M.logic.inferences, {
                    conclusion = query,
                    rule = rule,
                    timestamp = os.clock()
                })
                return true, "derived"
            end
        end
    end

    return nil, "unknown"
end

-- Check premises
function M.checkPremises(premises)
    for _, premise in ipairs(premises) do
        local value, source = M.inferLogical(premise)

        if value ~= true then
            return false
        end
    end

    return true
end

-- Logical consistency check
function M.checkConsistency()
    local contradictions = {}

    -- Check for P and NOT P
    for fact, value in pairs(M.logic.facts) do
        local negation = "NOT " .. fact

        if M.logic.facts[negation] ~= nil then
            if value == M.logic.facts[negation] then
                table.insert(contradictions, {
                    fact = fact,
                    negation = negation,
                    type = "direct_contradiction"
                })
            end
        end
    end

    return {
        consistent = #contradictions == 0,
        contradictions = contradictions
    }
end

-- ============================================================================
-- ABSTRACT THINKING
-- ============================================================================

M.abstraction = {
    concepts = {},
    hierarchies = {},
    mappings = {}
}

-- Create abstraction
function M.abstract(concrete_examples)
    local abstraction = {
        examples = concrete_examples,
        common_features = {},
        essence = {},
        generalization = {}
    }

    -- Extract common features
    abstraction.common_features = M.extractCommonFeatures(concrete_examples)

    -- Identify essence
    abstraction.essence = M.identifyEssence(abstraction.common_features)

    -- Generate generalization
    abstraction.generalization = M.generateGeneralization(abstraction.essence)

    return abstraction
end

-- Extract common features
function M.extractCommonFeatures(examples)
    if #examples == 0 then return {} end

    local feature_counts = {}

    -- Count feature occurrences
    for _, example in ipairs(examples) do
        if example.features then
            for _, feature in ipairs(example.features) do
                feature_counts[feature] = (feature_counts[feature] or 0) + 1
            end
        end
    end

    -- Keep features that appear in most examples
    local threshold = math.ceil(#examples * 0.6)
    local common = {}

    for feature, count in pairs(feature_counts) do
        if count >= threshold then
            table.insert(common, {
                feature = feature,
                frequency = count / #examples
            })
        end
    end

    return common
end

-- Identify essence (most important features)
function M.identifyEssence(common_features)
    -- Sort by frequency
    table.sort(common_features, function(a, b)
        return a.frequency > b.frequency
    end)

    -- Top features are essence
    local essence = {}
    for i = 1, math.min(3, #common_features) do
        table.insert(essence, common_features[i].feature)
    end

    return essence
end

-- Generate generalization
function M.generateGeneralization(essence)
    if #essence == 0 then
        return "No clear generalization"
    end

    return "A concept characterized by: " .. table.concat(essence, ", ")
end

-- Apply abstraction to new instance
function M.applyAbstraction(abstraction, new_instance)
    if not new_instance.features then
        return {matches = false, confidence = 0}
    end

    local matching_features = 0

    for _, essence_feature in ipairs(abstraction.essence) do
        for _, instance_feature in ipairs(new_instance.features) do
            if essence_feature == instance_feature then
                matching_features = matching_features + 1
                break
            end
        end
    end

    local confidence = matching_features / #abstraction.essence

    return {
        matches = confidence >= 0.6,
        confidence = confidence,
        matching_features = matching_features
    }
end

-- ============================================================================
-- COUNTERFACTUAL REASONING
-- ============================================================================

M.counterfactuals = {
    scenarios = {},
    outcomes = {}
}

-- Generate counterfactual scenario
function M.generateCounterfactual(actual_scenario, change)
    local counterfactual = {
        actual = actual_scenario,
        change = change,
        hypothetical = {},
        predicted_outcome = nil,
        comparison = {}
    }

    -- Apply change to create hypothetical
    counterfactual.hypothetical = M.applyChange(actual_scenario, change)

    -- Predict outcome
    counterfactual.predicted_outcome = M.predictCounterfactualOutcome(
        counterfactual.hypothetical
    )

    -- Compare to actual
    if actual_scenario.outcome then
        counterfactual.comparison = M.compareOutcomes(
            actual_scenario.outcome,
            counterfactual.predicted_outcome
        )
    end

    return counterfactual
end

-- Apply change to scenario
function M.applyChange(scenario, change)
    local hypothetical = {}

    -- Copy scenario
    for k, v in pairs(scenario) do
        hypothetical[k] = v
    end

    -- Apply change
    if change.type == "add" then
        hypothetical[change.variable] = change.value
    elseif change.type == "remove" then
        hypothetical[change.variable] = nil
    elseif change.type == "modify" then
        hypothetical[change.variable] = change.new_value
    end

    return hypothetical
end

-- Predict counterfactual outcome
function M.predictCounterfactualOutcome(hypothetical)
    -- Simplified prediction based on key variables
    local outcome = {
        predicted = true,
        confidence = 0.5,
        factors = {}
    }

    -- Analyze key factors
    for variable, value in pairs(hypothetical) do
        if variable ~= "outcome" then
            table.insert(outcome.factors, {
                variable = variable,
                value = value,
                impact = M.estimateImpact(variable, value)
            })
        end
    end

    return outcome
end

-- Estimate impact of variable
function M.estimateImpact(variable, value)
    -- Simplified impact estimation
    if type(value) == "number" then
        return value * 0.1
    else
        return 0.5
    end
end

-- Compare outcomes
function M.compareOutcomes(actual, counterfactual)
    return {
        actual = actual,
        counterfactual = counterfactual,
        difference = "hypothetical comparison",
        insights = {
            "Counterfactual analysis reveals alternative possibilities",
            "Actual outcome may have been influenced by specific factors"
        }
    }
end

-- Reason about causation
function M.reasonAboutCausation(event_a, event_b, context)
    local analysis = {
        correlation = false,
        causation = false,
        confidence = 0,
        reasoning = {}
    }

    -- Check temporal order
    if context.time_order and event_a.time < event_b.time then
        analysis.correlation = true
        table.insert(analysis.reasoning, "A preceded B temporally")
        analysis.confidence = analysis.confidence + 0.2
    end

    -- Check mechanism
    if context.mechanism then
        table.insert(analysis.reasoning, "Plausible mechanism exists")
        analysis.confidence = analysis.confidence + 0.3
    end

    -- Check counterfactuals
    if context.counterfactual then
        table.insert(analysis.reasoning, "Counterfactual dependence established")
        analysis.confidence = analysis.confidence + 0.4
        analysis.causation = true
    end

    -- Check confounds
    if context.confounds and #context.confounds > 0 then
        table.insert(analysis.reasoning, "Potential confounds present")
        analysis.confidence = analysis.confidence - 0.2
    end

    return analysis
end

-- ============================================================================
-- PHILOSOPHICAL QUESTION HANDLING
-- ============================================================================

M.philosophical_questions = {
    categories = {},
    responses = {}
}

-- Question categories
M.QUESTION_CATEGORIES = {
    METAPHYSICAL = "metaphysical",
    EPISTEMOLOGICAL = "epistemological",
    ETHICAL = "ethical",
    AESTHETIC = "aesthetic",
    EXISTENTIAL = "existential"
}

-- Analyze philosophical question
function M.analyzePhilosophicalQuestion(question)
    local analysis = {
        question = question,
        category = nil,
        complexity = 0,
        assumptions = {},
        perspectives = {},
        response = nil
    }

    -- Categorize
    analysis.category = M.categorizeQuestion(question)

    -- Assess complexity
    analysis.complexity = M.assessQuestionComplexity(question)

    -- Identify assumptions
    analysis.assumptions = M.identifyAssumptions(question)

    -- Generate multiple perspectives
    analysis.perspectives = M.generatePerspectives(question, analysis.category)

    -- Formulate response
    analysis.response = M.formulatePhilosophicalResponse(
        question, analysis.perspectives
    )

    return analysis
end

-- Categorize question
function M.categorizeQuestion(question)
    local q_lower = question:lower()

    if q_lower:find("exist") or q_lower:find("real") or q_lower:find("nature") then
        return M.QUESTION_CATEGORIES.METAPHYSICAL
    elseif q_lower:find("know") or q_lower:find("truth") or q_lower:find("belief") then
        return M.QUESTION_CATEGORIES.EPISTEMOLOGICAL
    elseif q_lower:find("should") or q_lower:find("right") or q_lower:find("wrong") then
        return M.QUESTION_CATEGORIES.ETHICAL
    elseif q_lower:find("meaning") or q_lower:find("purpose") then
        return M.QUESTION_CATEGORIES.EXISTENTIAL
    else
        return "general"
    end
end

-- Assess question complexity
function M.assessQuestionComplexity(question)
    local complexity = 0.5

    -- Longer questions tend to be more complex
    if #question > 100 then complexity = complexity + 0.2 end

    -- Multiple clauses
    local comma_count = select(2, question:gsub(",", ""))
    complexity = complexity + (comma_count * 0.1)

    -- Abstract terms
    local abstract_terms = {"being", "existence", "truth", "knowledge", "consciousness"}
    for _, term in ipairs(abstract_terms) do
        if question:lower():find(term) then
            complexity = complexity + 0.1
        end
    end

    return math.min(1.0, complexity)
end

-- Identify assumptions
function M.identifyAssumptions(question)
    local assumptions = {}

    -- Simple heuristic-based assumption detection
    if question:lower():find("why") then
        table.insert(assumptions, "Assumes there is a reason/cause")
    end

    if question:lower():find("should") then
        table.insert(assumptions, "Assumes normative framework exists")
    end

    if question:lower():find("real") then
        table.insert(assumptions, "Assumes objective reality")
    end

    return assumptions
end

-- Generate multiple perspectives
function M.generatePerspectives(question, category)
    local perspectives = {}

    if category == M.QUESTION_CATEGORIES.METAPHYSICAL then
        table.insert(perspectives, {
            name = "Realist",
            view = "Reality exists independently of perception"
        })
        table.insert(perspectives, {
            name = "Idealist",
            view = "Reality is fundamentally mental or experiential"
        })
    elseif category == M.QUESTION_CATEGORIES.EPISTEMOLOGICAL then
        table.insert(perspectives, {
            name = "Empiricist",
            view = "Knowledge comes from sensory experience"
        })
        table.insert(perspectives, {
            name = "Rationalist",
            view = "Knowledge can be gained through reason alone"
        })
    elseif category == M.QUESTION_CATEGORIES.ETHICAL then
        table.insert(perspectives, {
            name = "Consequentialist",
            view = "Focus on outcomes and consequences"
        })
        table.insert(perspectives, {
            name = "Deontologist",
            view = "Focus on duties and rules"
        })
    end

    return perspectives
end

-- Formulate philosophical response
function M.formulatePhilosophicalResponse(question, perspectives)
    local response = {
        opening = "This is a profound philosophical question.",
        perspectives = {},
        synthesis = "",
        conclusion = ""
    }

    -- Present perspectives
    for _, perspective in ipairs(perspectives) do
        table.insert(response.perspectives, string.format(
            "From a %s perspective: %s",
            perspective.name, perspective.view
        ))
    end

    -- Synthesis
    response.synthesis = "Each perspective offers valuable insights. "
    response.synthesis = response.synthesis ..
        "The question may not have a single definitive answer, "

    response.synthesis = response.synthesis ..
        "but exploring these different viewpoints enriches our understanding."

    -- Conclusion
    response.conclusion = "What matters is engaging thoughtfully with the question."

    return response
end

-- ============================================================================
-- DIALECTICAL REASONING
-- ============================================================================

-- Apply dialectical method (thesis, antithesis, synthesis)
function M.dialecticalReasoning(thesis)
    local dialectic = {
        thesis = thesis,
        antithesis = nil,
        synthesis = nil
    }

    -- Generate antithesis
    dialectic.antithesis = M.generateAntithesis(thesis)

    -- Generate synthesis
    dialectic.synthesis = M.generateSynthesis(thesis, dialectic.antithesis)

    return dialectic
end

-- Generate antithesis
function M.generateAntithesis(thesis)
    return {
        statement = "Contrary view to thesis",
        reasoning = "Considers alternative perspective",
        evidence = {}
    }
end

-- Generate synthesis
function M.generateSynthesis(thesis, antithesis)
    return {
        statement = "Integration of thesis and antithesis",
        reasoning = "Resolves contradiction at higher level",
        insights = {
            "Both perspectives have merit",
            "Truth may lie in the integration"
        }
    }
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get philosophical reasoning summary
function M.getPhilosophicalSummary()
    return {
        ethical_principles = M.ethics.principles,
        logical_facts_count = M.countTableEntries(M.logic.facts),
        logical_rules_count = #M.logic.rules,
        abstractions_count = M.countTableEntries(M.abstraction.concepts),
        counterfactuals_count = #M.counterfactuals.scenarios
    }
end

-- Count table entries
function M.countTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Initialize philosophical reasoning system
function M.init()
    -- Initialize with some basic logical rules
    M.addLogicalRule({
        premises = {"All humans are mortal", "Socrates is human"},
        conclusion = "Socrates is mortal"
    })

    print("Philosophical reasoning system initialized")
    return true
end

return M
