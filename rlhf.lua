-- Module: rlhf.lua
-- Reinforcement Learning from Human Feedback
-- Learn what responses are good/bad from user reactions

local M = {}

-- ============================================================================
-- REWARD MODEL
-- ============================================================================

M.reward_model = {
    weights = {},
    biases = {},
    input_size = 128,  -- Embedding dimension
    hidden_size = 64,
    output_size = 1,   -- Reward score
    learning_rate = 0.01
}

M.feedback_history = {}
M.preference_pairs = {}

-- ============================================================================
-- INITIALIZE REWARD MODEL
-- ============================================================================

function M.initializeRewardModel(input_size, hidden_size)
    M.reward_model.input_size = input_size or 128
    M.reward_model.hidden_size = hidden_size or 64
    
    -- Initialize weights
    local scale = math.sqrt(2.0 / M.reward_model.input_size)
    
    -- Input to hidden
    M.reward_model.weights[1] = {}
    for i = 1, M.reward_model.hidden_size do
        M.reward_model.weights[1][i] = {}
        for j = 1, M.reward_model.input_size do
            M.reward_model.weights[1][i][j] = (math.random() - 0.5) * 2 * scale
        end
    end
    
    -- Hidden to output
    M.reward_model.weights[2] = {}
    for i = 1, M.reward_model.output_size do
        M.reward_model.weights[2][i] = {}
        for j = 1, M.reward_model.hidden_size do
            M.reward_model.weights[2][i][j] = (math.random() - 0.5) * 2 * scale
        end
    end
    
    -- Biases
    M.reward_model.biases[1] = {}
    for i = 1, M.reward_model.hidden_size do
        M.reward_model.biases[1][i] = 0
    end
    
    M.reward_model.biases[2] = {}
    for i = 1, M.reward_model.output_size do
        M.reward_model.biases[2][i] = 0
    end
end

-- ============================================================================
-- PREDICT REWARD
-- ============================================================================

function M.predictReward(response_embedding)
    --[[
    Predict how good a response is
    Returns: reward score (higher = better)
    ]]
    
    if not M.reward_model.weights[1] then
        M.initializeRewardModel()
    end
    
    -- Forward pass through reward model
    local hidden = {}
    for i = 1, M.reward_model.hidden_size do
        local sum = M.reward_model.biases[1][i]
        for j = 1, M.reward_model.input_size do
            sum = sum + M.reward_model.weights[1][i][j] * response_embedding[j]
        end
        hidden[i] = M.relu(sum)
    end
    
    -- Output layer
    local output = M.reward_model.biases[2][1]
    for j = 1, M.reward_model.hidden_size do
        output = output + M.reward_model.weights[2][1][j] * hidden[j]
    end
    
    return output
end

-- ============================================================================
-- RECORD FEEDBACK
-- ============================================================================

function M.recordFeedback(user_message, bot_response, rating, embedding)
    --[[
    Record user feedback on a response
    rating: 1 (bad), 2 (neutral), 3 (good), 4 (great), 5 (excellent)
    ]]
    
    table.insert(M.feedback_history, {
        user_message = user_message,
        bot_response = bot_response,
        rating = rating,
        embedding = embedding,
        timestamp = os.time()
    })
    
    -- Keep only last 1000 feedbacks
    if #M.feedback_history > 1000 then
        table.remove(M.feedback_history, 1)
    end
    
    -- Auto-save
    if #M.feedback_history % 10 == 0 then
        M.save()
    end
end

-- ============================================================================
-- IMPLICIT FEEDBACK (detect from conversation)
-- ============================================================================

function M.detectImplicitFeedback(user_response, bot_previous_message)
    --[[
    Infer feedback from user's next message
    Returns: estimated rating (1-5)
    ]]
    
    local lower = user_response:lower()
    
    -- Very positive signals
    if lower:find("perfect") or lower:find("exactly") or lower:find("awesome") or
       lower:find("brilliant") or lower:find("love it") then
        return 5
    end
    
    -- Positive signals
    if lower:find("thanks") or lower:find("thank") or lower:find("great") or
       lower:find("good") or lower:find("helpful") or lower:find("yes!") then
        return 4
    end
    
    -- Negative signals
    if lower:find("no that's wrong") or lower:find("that's not right") or
       lower:find("incorrect") or lower:find("you're wrong") then
        return 1
    end
    
    -- Confusion signals
    if lower:find("what") or lower:find("huh") or lower:find("confused") or
       lower:find("i don't understand") or lower:find("that doesn't make sense") then
        return 2
    end
    
    -- Continued conversation = neutral/slightly positive
    if #user_response > 20 then
        return 3
    end
    
    -- Very short response = disengaged
    if #user_response < 5 then
        return 2
    end
    
    return 3  -- Default neutral
end

-- ============================================================================
-- TRAIN REWARD MODEL
-- ============================================================================

function M.trainRewardModel(epochs)
    --[[
    Train reward model on collected feedback
    ]]
    
    epochs = epochs or 10
    
    if #M.feedback_history < 5 then
        return false, "Not enough feedback data"
    end
    
    if not M.reward_model.weights[1] then
        M.initializeRewardModel()
    end
    
    local lr = M.reward_model.learning_rate
    
    for epoch = 1, epochs do
        local total_loss = 0
        
        for _, feedback in ipairs(M.feedback_history) do
            if feedback.embedding then
                -- Forward pass
                local predicted_reward = M.predictReward(feedback.embedding)
                
                -- Normalize rating to [0, 1]
                local target_reward = (feedback.rating - 1) / 4
                
                -- Loss (MSE)
                local loss = (predicted_reward - target_reward) ^ 2
                total_loss = total_loss + loss
                
                -- Backward pass (simplified)
                local error = predicted_reward - target_reward
                
                -- Update weights (simplified gradient descent)
                for i = 1, M.reward_model.output_size do
                    for j = 1, M.reward_model.hidden_size do
                        M.reward_model.weights[2][i][j] = M.reward_model.weights[2][i][j] - lr * error
                    end
                    M.reward_model.biases[2][i] = M.reward_model.biases[2][i] - lr * error
                end
            end
        end
        
        if epoch % 5 == 0 then
            print(string.format("Epoch %d: Loss = %.4f", epoch, total_loss / #M.feedback_history))
        end
    end
    
    M.save()
    return true
end

-- ============================================================================
-- PREFERENCE LEARNING (A vs B)
-- ============================================================================

function M.recordPreference(response_a, response_b, preferred, context)
    --[[
    Record that user preferred response A over B (or vice versa)
    preferred: "a" or "b"
    ]]
    
    table.insert(M.preference_pairs, {
        response_a = response_a,
        response_b = response_b,
        preferred = preferred,
        context = context,
        timestamp = os.time()
    })
    
    if #M.preference_pairs > 500 then
        table.remove(M.preference_pairs, 1)
    end
end

function M.trainFromPreferences(epochs)
    --[[
    Train using preference pairs (Bradley-Terry model)
    ]]
    
    epochs = epochs or 10
    
    if #M.preference_pairs < 3 then
        return false, "Not enough preference pairs"
    end
    
    -- Simplified preference learning
    -- In real RLHF, this would update the policy model
    -- Here we update the reward model to prefer winning responses
    
    for epoch = 1, epochs do
        for _, pair in ipairs(M.preference_pairs) do
            -- Boost score for preferred response
            if pair.preferred == "a" then
                -- Response A was better
                -- In full implementation, update model parameters
            elseif pair.preferred == "b" then
                -- Response B was better
            end
        end
    end
    
    return true
end

-- ============================================================================
-- POLICY OPTIMIZATION (PPO-style)
-- ============================================================================

M.policy_stats = {
    good_responses = 0,
    bad_responses = 0,
    avg_reward = 0
}

function M.updatePolicy(response, reward, baseline)
    --[[
    Update policy based on reward
    In full RL, this would update the language model
    Here we track stats for guidance
    ]]
    
    baseline = baseline or 0.5
    
    local advantage = reward - baseline
    
    if advantage > 0 then
        M.policy_stats.good_responses = M.policy_stats.good_responses + 1
    else
        M.policy_stats.bad_responses = M.policy_stats.bad_responses + 1
    end
    
    -- Update running average
    local total = M.policy_stats.good_responses + M.policy_stats.bad_responses
    if total > 0 then
        M.policy_stats.avg_reward = 
            (M.policy_stats.avg_reward * (total - 1) + reward) / total
    end
end

-- ============================================================================
-- RESPONSE RANKING
-- ============================================================================

function M.rankResponses(responses, embeddings)
    --[[
    Rank multiple candidate responses by predicted quality
    responses: list of response texts
    embeddings: list of response embeddings
    
    Returns: responses sorted by quality (best first)
    ]]
    
    local ranked = {}
    
    for i, response in ipairs(responses) do
        local reward = M.predictReward(embeddings[i])
        table.insert(ranked, {
            response = response,
            reward = reward,
            index = i
        })
    end
    
    table.sort(ranked, function(a, b) return a.reward > b.reward end)
    
    return ranked
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.relu(x)
    return x > 0 and x or 0
end

function M.sigmoid(x)
    if x < -45 then return 0 end
    if x > 45 then return 1 end
    return 1 / (1 + math.exp(-x))
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "rlhf_data.dat"
    
    local data = {
        reward_model = M.reward_model,
        feedback_history = M.feedback_history,
        preference_pairs = M.preference_pairs,
        policy_stats = M.policy_stats
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

function M.load(filename)
    filename = filename or "rlhf_data.dat"
    
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data then
            M.reward_model = data.reward_model or M.reward_model
            M.feedback_history = data.feedback_history or {}
            M.preference_pairs = data.preference_pairs or {}
            M.policy_stats = data.policy_stats or M.policy_stats
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- STATS
-- ============================================================================

function M.getStats()
    return {
        total_feedback = #M.feedback_history,
        preference_pairs = #M.preference_pairs,
        good_responses = M.policy_stats.good_responses,
        bad_responses = M.policy_stats.bad_responses,
        avg_reward = M.policy_stats.avg_reward
    }
end

return M
