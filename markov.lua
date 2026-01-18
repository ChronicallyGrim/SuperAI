-- Module: markov.lua
-- Markov chain text generation for natural conversation

local M = {}

-- ============================================================================
-- MARKOV CHAIN DATA
-- ============================================================================

M.chains = {
    -- order -> {word1 word2 -> {possible next words with counts}}
    [1] = {},  -- Single word chains
    [2] = {},  -- Two word chains (better quality)
}

M.starters = {}  -- Words that start sentences
M.total_sequences = 0

-- ============================================================================
-- TRAINING (Learn from text)
-- ============================================================================

function M.train(text, order)
    order = order or 2
    
    -- Tokenize into words
    local words = {}
    for word in text:gmatch("%S+") do
        -- Clean punctuation but keep some
        word = word:gsub("^[%p]+", ""):gsub("[%p]+$", "")
        if #word > 0 then
            table.insert(words, word)
        end
    end
    
    if #words < order + 1 then
        return false
    end
    
    -- Record first word as starter
    if words[1] then
        M.starters[words[1]] = (M.starters[words[1]] or 0) + 1
    end
    
    -- Build chains
    for i = 1, #words - order do
        local state = ""
        
        -- Build the current state (N previous words)
        for j = 0, order - 1 do
            state = state .. words[i + j]
            if j < order - 1 then
                state = state .. " "
            end
        end
        
        local next_word = words[i + order]
        
        -- Initialize chain table
        if not M.chains[order] then
            M.chains[order] = {}
        end
        
        if not M.chains[order][state] then
            M.chains[order][state] = {}
        end
        
        -- Record next word
        M.chains[order][state][next_word] = (M.chains[order][state][next_word] or 0) + 1
        M.total_sequences = M.total_sequences + 1
    end
    
    return true
end

-- ============================================================================
-- GENERATION (Create new text)
-- ============================================================================

function M.generate(max_words, order, seed)
    max_words = max_words or 20
    order = order or 2
    
    local words = {}
    local current_state
    
    -- Start with seed or random starter
    if seed then
        -- Use provided seed
        local seed_words = {}
        for word in seed:gmatch("%S+") do
            table.insert(seed_words, word)
        end
        
        for i = 1, math.min(order, #seed_words) do
            table.insert(words, seed_words[i])
        end
        
        if #words == order then
            current_state = table.concat(words, " ")
        end
    end
    
    -- If no seed or seed too short, use random starter
    if not current_state then
        local starters_list = {}
        for word, count in pairs(M.starters) do
            for i = 1, count do
                table.insert(starters_list, word)
            end
        end
        
        if #starters_list > 0 then
            local start_word = starters_list[math.random(#starters_list)]
            table.insert(words, start_word)
            
            -- Build initial state
            if order == 1 then
                current_state = start_word
            else
                -- Need one more word
                if M.chains[order] and M.chains[order][start_word] then
                    local next = M.selectNextWord(M.chains[order][start_word])
                    if next then
                        table.insert(words, next)
                        current_state = start_word .. " " .. next
                    end
                end
            end
        end
    end
    
    if not current_state then
        return "I need more training data to generate responses."
    end
    
    -- Generate remaining words
    for i = #words + 1, max_words do
        if not M.chains[order] or not M.chains[order][current_state] then
            break
        end
        
        local next_word = M.selectNextWord(M.chains[order][current_state])
        if not next_word then
            break
        end
        
        table.insert(words, next_word)
        
        -- Update state (sliding window)
        if order == 1 then
            current_state = next_word
        else
            local state_words = {}
            for word in current_state:gmatch("%S+") do
                table.insert(state_words, word)
            end
            table.remove(state_words, 1)
            table.insert(state_words, next_word)
            current_state = table.concat(state_words, " ")
        end
        
        -- End on punctuation
        if next_word:match("[.!?]$") then
            break
        end
    end
    
    return table.concat(words, " ")
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function M.selectNextWord(possibilities)
    -- Weighted random selection
    local total_weight = 0
    for word, count in pairs(possibilities) do
        total_weight = total_weight + count
    end
    
    if total_weight == 0 then
        return nil
    end
    
    local random_value = math.random() * total_weight
    local cumulative = 0
    
    for word, count in pairs(possibilities) do
        cumulative = cumulative + count
        if random_value <= cumulative then
            return word
        end
    end
    
    -- Fallback
    local words = {}
    for word, _ in pairs(possibilities) do
        table.insert(words, word)
    end
    return words[math.random(#words)]
end

-- ============================================================================
-- CONTEXTUAL GENERATION
-- ============================================================================

function M.generateResponse(user_message, order)
    order = order or 2
    
    -- Extract keywords from user message
    local keywords = {}
    for word in user_message:gmatch("%S+") do
        word = word:gsub("[%p]+", ""):lower()
        if #word > 3 then
            table.insert(keywords, word)
        end
    end
    
    -- Try to find relevant starting state
    local best_state = nil
    local best_score = 0
    
    if M.chains[order] then
        for state, _ in pairs(M.chains[order]) do
            local score = 0
            local state_lower = state:lower()
            
            for _, keyword in ipairs(keywords) do
                if state_lower:find(keyword, 1, true) then
                    score = score + 1
                end
            end
            
            if score > best_score then
                best_score = score
                best_state = state
            end
        end
    end
    
    -- Generate from best state or use last few words of user message
    if best_state then
        return M.generate(15, order, best_state)
    elseif #keywords >= order then
        local seed = table.concat(keywords, " ", math.max(1, #keywords - order + 1))
        return M.generate(15, order, seed)
    else
        return M.generate(15, order)
    end
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "markov_data.dat"
    
    local data = {
        chains = M.chains,
        starters = M.starters,
        total_sequences = M.total_sequences
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
    filename = filename or "markov_data.dat"
    
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data then
            M.chains = data.chains or M.chains
            M.starters = data.starters or M.starters
            M.total_sequences = data.total_sequences or 0
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function M.getStats()
    local stats = {
        total_sequences = M.total_sequences,
        unique_starters = 0,
        chains_by_order = {}
    }
    
    for word, _ in pairs(M.starters) do
        stats.unique_starters = stats.unique_starters + 1
    end
    
    for order, chain in pairs(M.chains) do
        local count = 0
        for _, _ in pairs(chain) do
            count = count + 1
        end
        stats.chains_by_order[order] = count
    end
    
    return stats
end

-- ============================================================================
-- PRE-TRAINING DATA
-- ============================================================================

function M.initializeWithDefaults()
    -- Train on common conversational patterns
    local training_data = {
        "Hello! How are you doing today?",
        "I'm doing great, thanks for asking!",
        "What can I help you with?",
        "That's really interesting, tell me more.",
        "I understand what you mean.",
        "That makes a lot of sense to me.",
        "Thanks for explaining that.",
        "I appreciate you sharing that with me.",
        "That's a good question.",
        "Let me think about that for a moment.",
        "I see what you're saying.",
        "That's really cool!",
        "I love talking about this stuff.",
        "You're absolutely right about that.",
        "I hadn't thought about it that way.",
        "That's a great point!",
        "Tell me more about what you're thinking.",
        "I'm here to help however I can.",
        "What would you like to know?",
        "That sounds really interesting!",
    }
    
    for _, text in ipairs(training_data) do
        M.train(text, 1)
        M.train(text, 2)
    end
    
    M.save()
end

-- ============================================================================
-- AUTO-LEARN FROM CONVERSATIONS
-- ============================================================================

function M.learnFromConversation(user_message, bot_response)
    -- Learn from both sides of conversation
    M.train(user_message, 1)
    M.train(user_message, 2)
    M.train(bot_response, 1)
    M.train(bot_response, 2)
    
    -- Auto-save periodically
    if M.total_sequences % 50 == 0 then
        M.save()
    end
end

return M
