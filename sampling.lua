-- Module: sampling.lua
-- Advanced sampling methods for text generation

local M = {}

-- ============================================================================
-- TEMPERATURE SAMPLING
-- ============================================================================

function M.temperatureSample(probabilities, temperature)
    --[[
    Sample from probability distribution with temperature
    temperature < 1: more confident/focused
    temperature = 1: unchanged
    temperature > 1: more random/creative
    ]]
    
    temperature = temperature or 1.0
    
    -- Apply temperature
    local scaled_probs = {}
    local sum = 0
    
    for i, prob in ipairs(probabilities) do
        local scaled = math.exp(math.log(prob + 1e-10) / temperature)
        scaled_probs[i] = scaled
        sum = sum + scaled
    end
    
    -- Normalize
    for i = 1, #scaled_probs do
        scaled_probs[i] = scaled_probs[i] / sum
    end
    
    -- Sample
    return M.categoricalSample(scaled_probs)
end

-- ============================================================================
-- TOP-K SAMPLING
-- ============================================================================

function M.topKSample(probabilities, k)
    --[[
    Only sample from top K most likely options
    Prevents selecting unlikely bad options
    ]]
    
    k = k or 40
    
    -- Create list of {index, prob}
    local indexed = {}
    for i, prob in ipairs(probabilities) do
        table.insert(indexed, {index = i, prob = prob})
    end
    
    -- Sort by probability
    table.sort(indexed, function(a, b) return a.prob > b.prob end)
    
    -- Keep only top K
    local top_k = {}
    local sum = 0
    for i = 1, math.min(k, #indexed) do
        table.insert(top_k, indexed[i])
        sum = sum + indexed[i].prob
    end
    
    -- Renormalize
    local renormalized = {}
    for i, item in ipairs(top_k) do
        renormalized[i] = item.prob / sum
    end
    
    -- Sample from top K
    local sample_idx = M.categoricalSample(renormalized)
    return top_k[sample_idx].index
end

-- ============================================================================
-- TOP-P (NUCLEUS) SAMPLING
-- ============================================================================

function M.topPSample(probabilities, p)
    --[[
    Sample from smallest set of options whose cumulative prob >= p
    Adaptive: uses fewer options for confident predictions,
    more options for uncertain predictions
    ]]
    
    p = p or 0.9
    
    -- Sort by probability
    local indexed = {}
    for i, prob in ipairs(probabilities) do
        table.insert(indexed, {index = i, prob = prob})
    end
    table.sort(indexed, function(a, b) return a.prob > b.prob end)
    
    -- Find nucleus (minimum set with cumulative prob >= p)
    local nucleus = {}
    local cumulative = 0
    
    for i, item in ipairs(indexed) do
        table.insert(nucleus, item)
        cumulative = cumulative + item.prob
        
        if cumulative >= p then
            break
        end
    end
    
    -- Renormalize nucleus
    local sum = 0
    for _, item in ipairs(nucleus) do
        sum = sum + item.prob
    end
    
    local renormalized = {}
    for i, item in ipairs(nucleus) do
        renormalized[i] = item.prob / sum
    end
    
    -- Sample from nucleus
    local sample_idx = M.categoricalSample(renormalized)
    return nucleus[sample_idx].index
end

-- ============================================================================
-- BEAM SEARCH
-- ============================================================================

function M.beamSearch(generate_fn, start_state, beam_width, max_length)
    --[[
    Beam search for finding best sequence
    generate_fn: function(state) -> {next_states, probabilities}
    start_state: initial state
    beam_width: number of candidates to keep
    max_length: maximum sequence length
    
    Returns: best sequence found
    ]]
    
    beam_width = beam_width or 3
    max_length = max_length or 20
    
    -- Initialize beam with start state
    local beams = {{
        state = start_state,
        score = 0,
        sequence = {},
        done = false
    }}
    
    for step = 1, max_length do
        local candidates = {}
        
        -- Expand each beam
        for _, beam in ipairs(beams) do
            if not beam.done then
                local next_states, probs = generate_fn(beam.state)
                
                -- Create candidates
                for i = 1, #next_states do
                    local new_sequence = {}
                    for _, item in ipairs(beam.sequence) do
                        table.insert(new_sequence, item)
                    end
                    table.insert(new_sequence, i)
                    
                    table.insert(candidates, {
                        state = next_states[i],
                        score = beam.score + math.log(probs[i] + 1e-10),
                        sequence = new_sequence,
                        done = next_states[i].done or false
                    })
                end
            else
                -- Keep done beams
                table.insert(candidates, beam)
            end
        end
        
        -- Keep top beam_width candidates
        table.sort(candidates, function(a, b) return a.score > b.score end)
        
        beams = {}
        for i = 1, math.min(beam_width, #candidates) do
            table.insert(beams, candidates[i])
        end
        
        -- Check if all beams are done
        local all_done = true
        for _, beam in ipairs(beams) do
            if not beam.done then
                all_done = false
                break
            end
        end
        
        if all_done then
            break
        end
    end
    
    -- Return best beam
    return beams[1]
end

-- ============================================================================
-- GREEDY SAMPLING (always pick most likely)
-- ============================================================================

function M.greedySample(probabilities)
    local max_idx = 1
    local max_prob = probabilities[1]
    
    for i = 2, #probabilities do
        if probabilities[i] > max_prob then
            max_prob = probabilities[i]
            max_idx = i
        end
    end
    
    return max_idx
end

-- ============================================================================
-- CATEGORICAL SAMPLING (standard random sampling)
-- ============================================================================

function M.categoricalSample(probabilities)
    local r = math.random()
    local cumulative = 0
    
    for i, prob in ipairs(probabilities) do
        cumulative = cumulative + prob
        if r <= cumulative then
            return i
        end
    end
    
    return #probabilities
end

-- ============================================================================
-- COMBINED SAMPLING STRATEGY
-- ============================================================================

function M.smartSample(probabilities, config)
    --[[
    Combined sampling strategy
    config: {
        method = "temperature" | "top_k" | "top_p" | "greedy",
        temperature = 1.0,
        top_k = 40,
        top_p = 0.9
    }
    ]]
    
    config = config or {}
    local method = config.method or "top_p"
    
    if method == "greedy" then
        return M.greedySample(probabilities)
        
    elseif method == "temperature" then
        local temp = config.temperature or 1.0
        return M.temperatureSample(probabilities, temp)
        
    elseif method == "top_k" then
        local k = config.top_k or 40
        return M.topKSample(probabilities, k)
        
    elseif method == "top_p" then
        local p = config.top_p or 0.9
        return M.topPSample(probabilities, p)
        
    else
        -- Default to top-p
        return M.topPSample(probabilities, 0.9)
    end
end

-- ============================================================================
-- DIVERSE BEAM SEARCH
-- ============================================================================

function M.diverseBeamSearch(generate_fn, start_state, num_groups, group_size, max_length, diversity_penalty)
    --[[
    Beam search that encourages diversity
    Useful for generating multiple different responses
    ]]
    
    num_groups = num_groups or 2
    group_size = group_size or 2
    max_length = max_length or 20
    diversity_penalty = diversity_penalty or 0.5
    
    local groups = {}
    
    -- Initialize groups
    for g = 1, num_groups do
        groups[g] = {{
            state = start_state,
            score = 0,
            sequence = {},
            done = false
        }}
    end
    
    local all_sequences = {}
    
    for step = 1, max_length do
        for g = 1, num_groups do
            local candidates = {}
            
            for _, beam in ipairs(groups[g]) do
                if not beam.done then
                    local next_states, probs = generate_fn(beam.state)
                    
                    for i = 1, #next_states do
                        local new_sequence = {}
                        for _, item in ipairs(beam.sequence) do
                            table.insert(new_sequence, item)
                        end
                        table.insert(new_sequence, i)
                        
                        -- Apply diversity penalty based on other groups
                        local penalty = 0
                        for other_g = 1, g - 1 do
                            for _, other_beam in ipairs(groups[other_g]) do
                                if #other_beam.sequence >= #new_sequence then
                                    if other_beam.sequence[#new_sequence] == i then
                                        penalty = penalty + diversity_penalty
                                    end
                                end
                            end
                        end
                        
                        table.insert(candidates, {
                            state = next_states[i],
                            score = beam.score + math.log(probs[i] + 1e-10) - penalty,
                            sequence = new_sequence,
                            done = next_states[i].done or false
                        })
                    end
                end
            end
            
            -- Keep top candidates for this group
            table.sort(candidates, function(a, b) return a.score > b.score end)
            
            groups[g] = {}
            for i = 1, math.min(group_size, #candidates) do
                table.insert(groups[g], candidates[i])
            end
        end
    end
    
    -- Collect all final beams
    for g = 1, num_groups do
        for _, beam in ipairs(groups[g]) do
            table.insert(all_sequences, beam)
        end
    end
    
    -- Sort by score
    table.sort(all_sequences, function(a, b) return a.score > b.score end)
    
    return all_sequences
end

-- ============================================================================
-- REPETITION PENALTY
-- ============================================================================

function M.applyRepetitionPenalty(probabilities, previous_tokens, penalty)
    --[[
    Reduce probability of tokens that were recently used
    Prevents boring repetitive text
    ]]
    
    penalty = penalty or 1.2
    
    local penalized = {}
    for i, prob in ipairs(probabilities) do
        penalized[i] = prob
    end
    
    -- Apply penalty to repeated tokens
    for _, token in ipairs(previous_tokens) do
        if penalized[token] then
            penalized[token] = penalized[token] / penalty
        end
    end
    
    -- Renormalize
    local sum = 0
    for _, prob in ipairs(penalized) do
        sum = sum + prob
    end
    
    for i = 1, #penalized do
        penalized[i] = penalized[i] / sum
    end
    
    return penalized
end

-- ============================================================================
-- TYPICAL SAMPLING
-- ============================================================================

function M.typicalSample(probabilities, tau)
    --[[
    Sample typical tokens (not too likely, not too unlikely)
    Based on information theory
    ]]
    
    tau = tau or 0.95
    
    -- Compute entropy
    local entropy = 0
    for _, prob in ipairs(probabilities) do
        if prob > 0 then
            entropy = entropy - prob * math.log(prob)
        end
    end
    
    -- Compute "typicality" of each token
    local typical = {}
    for i, prob in ipairs(probabilities) do
        local surprise = -math.log(prob + 1e-10)
        local deviation = math.abs(surprise - entropy)
        table.insert(typical, {
            index = i,
            prob = prob,
            deviation = deviation
        })
    end
    
    -- Sort by deviation (most typical first)
    table.sort(typical, function(a, b) return a.deviation < b.deviation end)
    
    -- Keep tokens until cumulative prob >= tau
    local kept = {}
    local cumulative = 0
    
    for _, item in ipairs(typical) do
        table.insert(kept, item)
        cumulative = cumulative + item.prob
        
        if cumulative >= tau then
            break
        end
    end
    
    -- Renormalize and sample
    local sum = 0
    for _, item in ipairs(kept) do
        sum = sum + item.prob
    end
    
    local renormalized = {}
    for i, item in ipairs(kept) do
        renormalized[i] = item.prob / sum
    end
    
    local sample_idx = M.categoricalSample(renormalized)
    return kept[sample_idx].index
end

return M
