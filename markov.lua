-- Module: markov.lua
-- Advanced Markov chain text generation for natural conversation
-- Features: Higher-order chains, backoff smoothing, temperature sampling, quality scoring

local M = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

M.config = {
    max_order = 4,           -- Support up to 4-word chains
    default_order = 2,       -- Default generation order
    min_frequency = 2,       -- Ignore patterns seen less than this
    temperature = 1.0,       -- Sampling randomness (0.5 = conservative, 2.0 = creative)
    max_length = 30,         -- Max words per response
    quality_threshold = 0.3, -- Min quality score (0-1)
}

-- ============================================================================
-- MARKOV CHAIN DATA
-- ============================================================================

M.chains = {
    -- order -> {state -> {next_word -> count}}
    [1] = {},  -- Single word chains
    [2] = {},  -- Two word chains (better quality)
    [3] = {},  -- Three word chains (more coherent)
    [4] = {},  -- Four word chains (best coherence, but sparse)
}

M.starters = {}  -- Words that start sentences (with counts)
M.enders = {}    -- Words that end sentences (with counts)
M.total_sequences = 0
M.ngram_counts = {} -- Track frequency of all n-grams

-- ============================================================================
-- ADVANCED TOKENIZATION
-- ============================================================================

function M.tokenize(text)
    local words = {}
    local current = ""

    for i = 1, #text do
        local char = text:sub(i, i)

        if char:match("%s") then
            -- Space found, add word if not empty
            if #current > 0 then
                table.insert(words, current)
                current = ""
            end
        elseif char:match("[.!?]") then
            -- Sentence ender - attach to current word
            if #current > 0 then
                table.insert(words, current .. char)
                current = ""
            else
                table.insert(words, char)
            end
        elseif char:match("[,;:]") then
            -- Punctuation - attach to current word
            if #current > 0 then
                table.insert(words, current .. char)
                current = ""
            end
        else
            current = current .. char
        end
    end

    -- Add final word
    if #current > 0 then
        table.insert(words, current)
    end

    return words
end

function M.isSentenceEnd(word)
    return word:match("[.!?]$") ~= nil
end

function M.isSentenceStart(word)
    -- Check if word starts with capital letter
    local first = word:sub(1, 1)
    return first == first:upper() and first ~= first:lower()
end

-- ============================================================================
-- TRAINING (Learn from text)
-- ============================================================================

function M.train(text, max_order)
    max_order = max_order or M.config.max_order

    -- Advanced tokenization preserves punctuation
    local words = M.tokenize(text)

    if #words < 2 then
        return false
    end

    -- Record first word as starter
    if words[1] then
        M.starters[words[1]] = (M.starters[words[1]] or 0) + 1
    end

    -- Record last word as ender if it has sentence-ending punctuation
    if words[#words] and M.isSentenceEnd(words[#words]) then
        M.enders[words[#words]] = (M.enders[words[#words]] or 0) + 1
    end

    -- Build chains for all orders (1 to max_order)
    for order = 1, math.min(max_order, M.config.max_order) do
        if #words >= order + 1 then
            for i = 1, #words - order do
                -- Build the current state (N previous words)
                local state_words = {}
                for j = 0, order - 1 do
                    table.insert(state_words, words[i + j])
                end
                local state = table.concat(state_words, " ")

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

                -- Track n-gram frequency
                local ngram = state .. " " .. next_word
                M.ngram_counts[ngram] = (M.ngram_counts[ngram] or 0) + 1

                M.total_sequences = M.total_sequences + 1
            end
        end
    end

    return true
end

-- ============================================================================
-- ADVANCED SAMPLING WITH TEMPERATURE
-- ============================================================================

function M.selectNextWord(possibilities, temperature)
    temperature = temperature or M.config.temperature

    if not possibilities or not next(possibilities) then
        return nil
    end

    -- Filter by minimum frequency
    local filtered = {}
    for word, count in pairs(possibilities) do
        if count >= M.config.min_frequency then
            filtered[word] = count
        end
    end

    -- If filtering removed everything, use original
    if not next(filtered) then
        filtered = possibilities
    end

    -- Apply temperature to weights
    local weights = {}
    local total_weight = 0

    for word, count in pairs(filtered) do
        -- Temperature < 1.0 makes it more deterministic (favors high counts)
        -- Temperature > 1.0 makes it more random (flattens distribution)
        local weight = math.pow(count, 1.0 / temperature)
        weights[word] = weight
        total_weight = total_weight + weight
    end

    if total_weight == 0 then
        return nil
    end

    -- Weighted random selection
    local random_value = math.random() * total_weight
    local cumulative = 0

    for word, weight in pairs(weights) do
        cumulative = cumulative + weight
        if random_value <= cumulative then
            return word
        end
    end

    -- Fallback
    local words = {}
    for word, _ in pairs(filtered) do
        table.insert(words, word)
    end
    return words[math.random(#words)]
end

-- ============================================================================
-- BACKOFF SMOOTHING (Try higher order, fall back to lower if no match)
-- ============================================================================

function M.generateWithBackoff(max_words, max_order, seed, temperature)
    max_words = max_words or M.config.max_length
    max_order = max_order or M.config.default_order
    temperature = temperature or M.config.temperature

    local words = {}
    local current_order = max_order

    -- Start with seed or random starter
    if seed then
        local seed_words = M.tokenize(seed)
        for i = 1, math.min(max_order, #seed_words) do
            table.insert(words, seed_words[i])
        end
    end

    -- If no seed or seed too short, use random starter
    if #words == 0 then
        local starters_list = {}
        for word, count in pairs(M.starters) do
            for i = 1, count do
                table.insert(starters_list, word)
            end
        end

        if #starters_list > 0 then
            local start_word = starters_list[math.random(#starters_list)]
            table.insert(words, start_word)
        else
            return "I need more training data to generate responses."
        end
    end

    -- Generate remaining words with backoff
    for i = #words + 1, max_words do
        local next_word = nil

        -- Try orders from high to low (backoff smoothing)
        for order = math.min(current_order, #words), 1, -1 do
            -- Build state from last N words
            local state_words = {}
            local start_idx = math.max(1, #words - order + 1)
            for j = start_idx, #words do
                table.insert(state_words, words[j])
            end
            local state = table.concat(state_words, " ")

            -- Try to get next word at this order
            if M.chains[order] and M.chains[order][state] then
                next_word = M.selectNextWord(M.chains[order][state], temperature)
                if next_word then
                    break -- Found word at this order
                end
            end
        end

        if not next_word then
            break -- No continuation found at any order
        end

        table.insert(words, next_word)

        -- End on sentence boundary
        if M.isSentenceEnd(next_word) then
            break
        end
    end

    if #words == 0 then
        return "I need more training data to generate responses."
    end

    return table.concat(words, " ")
end

-- ============================================================================
-- LEGACY GENERATION (for compatibility)
-- ============================================================================

function M.generate(max_words, order, seed)
    -- Wrapper for backward compatibility
    return M.generateWithBackoff(max_words, order, seed, M.config.temperature)
end

-- ============================================================================
-- QUALITY SCORING
-- ============================================================================

function M.scoreResponse(text)
    -- Score response quality (0-1, higher is better)
    local score = 0.5 -- Start neutral
    local words = M.tokenize(text)

    if #words == 0 then
        return 0.0
    end

    -- Bonus for proper length (10-25 words is ideal)
    if #words >= 10 and #words <= 25 then
        score = score + 0.2
    elseif #words >= 5 and #words <= 30 then
        score = score + 0.1
    end

    -- Bonus for ending with punctuation
    if M.isSentenceEnd(words[#words]) then
        score = score + 0.1
    end

    -- Bonus for starting with capital
    if M.isSentenceStart(words[1]) then
        score = score + 0.1
    end

    -- Penalty for very short responses
    if #words < 3 then
        score = score - 0.3
    end

    -- Bonus for variety (unique words)
    local unique = {}
    for _, word in ipairs(words) do
        unique[word:lower()] = true
    end
    local uniqueness = 0
    for _ in pairs(unique) do uniqueness = uniqueness + 1 end
    local variety = uniqueness / #words
    score = score + (variety * 0.2)

    return math.max(0.0, math.min(1.0, score))
end

-- ============================================================================
-- CONTEXTUAL GENERATION WITH QUALITY FILTERING
-- ============================================================================

function M.generateResponse(user_message, max_order, num_attempts)
    max_order = max_order or M.config.default_order
    num_attempts = num_attempts or 3

    -- Extract keywords from user message
    local keywords = {}
    local user_words = M.tokenize(user_message)
    for _, word in ipairs(user_words) do
        local clean = word:gsub("[%p]+", ""):lower()
        if #clean > 3 then
            table.insert(keywords, clean)
        end
    end

    -- Try to find relevant starting states across all orders
    local best_state = nil
    local best_score = 0
    local best_order = 1

    for order = max_order, 1, -1 do
        if M.chains[order] then
            for state, _ in pairs(M.chains[order]) do
                local score = 0
                local state_lower = state:lower()

                -- Score based on keyword matches
                for _, keyword in ipairs(keywords) do
                    if state_lower:find(keyword, 1, true) then
                        score = score + 1
                    end
                end

                if score > best_score then
                    best_score = score
                    best_state = state
                    best_order = order
                end
            end
        end
    end

    -- Generate multiple attempts and pick the best quality
    local best_response = nil
    local best_quality = 0

    for attempt = 1, num_attempts do
        local response

        if best_state and best_score > 0 then
            -- Generate from context-relevant state
            response = M.generateWithBackoff(M.config.max_length, max_order, best_state, M.config.temperature)
        elseif #keywords >= 2 then
            -- Use last keywords as seed
            local seed = table.concat(keywords, " ", math.max(1, #keywords - 1))
            response = M.generateWithBackoff(M.config.max_length, max_order, seed, M.config.temperature)
        else
            -- Random generation
            response = M.generateWithBackoff(M.config.max_length, max_order, nil, M.config.temperature)
        end

        if response and not response:match("training data") then
            local quality = M.scoreResponse(response)

            if quality > best_quality then
                best_quality = quality
                best_response = response
            end

            -- If we got a good-enough response, stop trying
            if quality >= 0.7 then
                break
            end
        end
    end

    -- Return best response if it meets quality threshold
    if best_response and best_quality >= M.config.quality_threshold then
        return best_response
    end

    -- Fallback
    return M.generateWithBackoff(M.config.max_length, max_order)
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "markov_data.dat"

    local data = {
        chains = M.chains,
        starters = M.starters,
        enders = M.enders,
        total_sequences = M.total_sequences,
        ngram_counts = M.ngram_counts,
        config = M.config
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
            M.enders = data.enders or M.enders
            M.total_sequences = data.total_sequences or 0
            M.ngram_counts = data.ngram_counts or {}

            -- Merge config (preserve new defaults, load saved values)
            if data.config then
                for k, v in pairs(data.config) do
                    M.config[k] = v
                end
            end

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
        unique_enders = 0,
        chains_by_order = {},
        unique_ngrams = 0,
        config = M.config
    }

    for word, _ in pairs(M.starters) do
        stats.unique_starters = stats.unique_starters + 1
    end

    for word, _ in pairs(M.enders) do
        stats.unique_enders = stats.unique_enders + 1
    end

    for order, chain in pairs(M.chains) do
        local count = 0
        for _, _ in pairs(chain) do
            count = count + 1
        end
        stats.chains_by_order[order] = count
    end

    for _ in pairs(M.ngram_counts) do
        stats.unique_ngrams = stats.unique_ngrams + 1
    end

    return stats
end

-- ============================================================================
-- CONFIGURATION HELPERS
-- ============================================================================

function M.setTemperature(temp)
    M.config.temperature = math.max(0.1, math.min(3.0, temp))
end

function M.setQualityThreshold(threshold)
    M.config.quality_threshold = math.max(0.0, math.min(1.0, threshold))
end

function M.setMaxOrder(order)
    M.config.max_order = math.max(1, math.min(4, order))
end

-- ============================================================================
-- INIT (called automatically by cluster_worker on module load)
-- ============================================================================

function M.init()
    -- Try to load saved training data first
    if M.load() then
        return
    end
    -- No saved data found, seed with defaults
    M.initializeWithDefaults()
end

-- ============================================================================
-- PRE-TRAINING DATA
-- ============================================================================

function M.initializeWithDefaults()
    -- Train on common conversational patterns with higher-order chains
    local training_data = {
        -- Greetings / small talk
        "Hello! How are you doing today?",
        "I'm doing great, thanks for asking!",
        "Hey there, nice to meet you!",
        "Hi! What brings you here today?",
        "Good to see you! How have you been?",
        "Not bad, just hanging out and chatting.",
        "I'm doing well, thanks for checking in.",
        "Hey! Always good to hear from you.",
        -- Questions and curiosity
        "What can I help you with?",
        "That's a good question, let me think about it.",
        "Tell me more about what you're thinking.",
        "What would you like to know?",
        "Have you thought about it from another angle?",
        "What made you curious about that?",
        "I'd love to hear more about that topic.",
        "Can you explain what you mean by that?",
        -- Acknowledgements and responses
        "That's really interesting, tell me more.",
        "I understand what you mean.",
        "That makes a lot of sense to me.",
        "Thanks for explaining that.",
        "I appreciate you sharing that with me.",
        "I see what you're saying.",
        "That's really cool!",
        "I love talking about this stuff.",
        "You're absolutely right about that.",
        "I hadn't thought about it that way.",
        "That's a great point!",
        "I'm here to help however I can.",
        "That sounds really interesting!",
        "Wow, I didn't know that before.",
        "That's fascinating, thanks for telling me.",
        "I get what you're saying now.",
        -- Opinions and discussion
        "I think that depends on a few things.",
        "That's a tricky one to answer.",
        "There are a lot of ways to look at it.",
        "Honestly, I'm not totally sure about that.",
        "It's hard to say without more context.",
        "That could go either way really.",
        "I think you might be onto something there.",
        "From what I know that sounds about right.",
        -- Encouragement
        "Don't worry, I'm sure you'll figure it out.",
        "That sounds like a solid plan to me.",
        "You're doing great, keep it up!",
        "I believe you can handle it.",
        "That's a really smart way to approach things.",
        -- Casual filler
        "Yeah that totally makes sense.",
        "Oh interesting, I hadn't considered that.",
        "Haha, fair enough I suppose.",
        "I can see why you'd think that.",
        "Good point, I think you're right.",
        "Honestly same, I feel that way too sometimes.",
        "That's kind of wild when you think about it.",
        -- More complex conversational patterns
        "I appreciate you taking the time to explain this to me.",
        "From my perspective, it seems like there might be multiple solutions.",
        "That's an interesting way to look at the problem.",
        "I'm curious to hear what you think about this approach.",
        "Based on what you've told me, it sounds like a solid idea.",
        "Let me know if you want to explore that further.",
        "I'm happy to discuss this more if you'd like.",
        "That makes sense when you put it that way.",
        "I can see both sides of that argument.",
        "It's always interesting to consider different perspectives.",
    }

    for _, text in ipairs(training_data) do
        -- Train on all orders (1-4) for maximum flexibility
        M.train(text, M.config.max_order)
    end

    M.save()
end

-- ============================================================================
-- AUTO-LEARN FROM CONVERSATIONS
-- ============================================================================

function M.learnFromConversation(user_message, bot_response)
    -- Learn from both sides of conversation with all orders
    M.train(user_message, M.config.max_order)
    M.train(bot_response, M.config.max_order)

    -- Auto-save periodically
    if M.total_sequences % 50 == 0 then
        M.save()
    end
end

return M
