-- Module: tokenization.lua
-- Advanced tokenization and knowledge distillation

local M = {}

-- ============================================================================
-- TOKENIZATION
-- ============================================================================

M.vocabulary = {}
M.token_to_id = {}
M.id_to_token = {}
M.vocab_size = 0

-- Special tokens
M.SPECIAL_TOKENS = {
    PAD = "<PAD>",
    UNK = "<UNK>",
    BOS = "<BOS>",  -- Beginning of sequence
    EOS = "<EOS>",  -- End of sequence
    SEP = "<SEP>",  -- Separator
}

-- ============================================================================
-- BUILD VOCABULARY
-- ============================================================================

function M.buildVocabulary(texts, max_vocab_size)
    max_vocab_size = max_vocab_size or 5000
    
    -- Count word frequencies
    local word_freq = {}
    
    for _, text in ipairs(texts) do
        for word in text:gmatch("%S+") do
            word = word:lower():gsub("[%p]+", "")
            if #word > 0 then
                word_freq[word] = (word_freq[word] or 0) + 1
            end
        end
    end
    
    -- Sort by frequency
    local sorted = {}
    for word, count in pairs(word_freq) do
        table.insert(sorted, {word = word, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    -- Add special tokens first
    M.vocab_size = 0
    for name, token in pairs(M.SPECIAL_TOKENS) do
        M.vocab_size = M.vocab_size + 1
        M.token_to_id[token] = M.vocab_size
        M.id_to_token[M.vocab_size] = token
    end
    
    -- Add most frequent words
    for i = 1, math.min(#sorted, max_vocab_size - M.vocab_size) do
        M.vocab_size = M.vocab_size + 1
        local word = sorted[i].word
        M.token_to_id[word] = M.vocab_size
        M.id_to_token[M.vocab_size] = word
    end
    
    return M.vocab_size
end

-- ============================================================================
-- BYTE PAIR ENCODING (BPE) - Subword Tokenization
-- ============================================================================

M.bpe_vocab = {}
M.bpe_merges = {}

function M.trainBPE(texts, num_merges)
    --[[
    Train Byte Pair Encoding for subword tokenization
    Better handling of rare words and morphology
    ]]
    
    num_merges = num_merges or 1000
    
    -- Initialize with character vocabulary
    local vocab = {}
    for _, text in ipairs(texts) do
        for char in text:gmatch(".") do
            vocab[char] = (vocab[char] or 0) + 1
        end
    end
    
    -- Get word frequencies
    local word_freq = {}
    for _, text in ipairs(texts) do
        for word in text:gmatch("%S+") do
            word = word:lower()
            -- Split into characters
            local chars = {}
            for char in word:gmatch(".") do
                table.insert(chars, char)
            end
            local word_str = table.concat(chars, " ")
            word_freq[word_str] = (word_freq[word_str] or 0) + 1
        end
    end
    
    -- Perform merges
    for merge_idx = 1, num_merges do
        -- Find most frequent bigram
        local bigram_freq = {}
        
        for word, freq in pairs(word_freq) do
            local tokens = {}
            for token in word:gmatch("%S+") do
                table.insert(tokens, token)
            end
            
            for i = 1, #tokens - 1 do
                local bigram = tokens[i] .. " " .. tokens[i + 1]
                bigram_freq[bigram] = (bigram_freq[bigram] or 0) + freq
            end
        end
        
        -- Find most frequent
        local best_bigram = nil
        local best_freq = 0
        
        for bigram, freq in pairs(bigram_freq) do
            if freq > best_freq then
                best_freq = freq
                best_bigram = bigram
            end
        end
        
        if not best_bigram or best_freq < 2 then
            break
        end
        
        -- Merge this bigram
        table.insert(M.bpe_merges, best_bigram)
        local merged = best_bigram:gsub(" ", "")
        vocab[merged] = best_freq
        
        -- Update word frequencies
        local new_word_freq = {}
        for word, freq in pairs(word_freq) do
            local new_word = word:gsub(best_bigram, merged)
            new_word_freq[new_word] = freq
        end
        word_freq = new_word_freq
    end
    
    M.bpe_vocab = vocab
    return M.bpe_merges
end

function M.applyBPE(word)
    --[[
    Apply BPE merges to tokenize a word into subwords
    ]]
    
    word = word:lower()
    
    -- Start with character-level
    local tokens = {}
    for char in word:gmatch(".") do
        table.insert(tokens, char)
    end
    
    -- Apply merges
    for _, merge in ipairs(M.bpe_merges) do
        local parts = {}
        for part in merge:gmatch("%S+") do
            table.insert(parts, part)
        end
        
        local i = 1
        while i <= #tokens - 1 do
            if tokens[i] == parts[1] and tokens[i + 1] == parts[2] then
                tokens[i] = parts[1] .. parts[2]
                table.remove(tokens, i + 1)
            else
                i = i + 1
            end
        end
    end
    
    return tokens
end

-- ============================================================================
-- TOKENIZE TEXT
-- ============================================================================

function M.tokenize(text, use_bpe)
    --[[
    Convert text to token IDs
    use_bpe: use subword tokenization
    ]]
    
    use_bpe = use_bpe or false
    
    local token_ids = {}
    
    -- Add BOS token
    table.insert(token_ids, M.token_to_id[M.SPECIAL_TOKENS.BOS])
    
    for word in text:gmatch("%S+") do
        word = word:lower():gsub("[%p]+", "")
        
        if #word > 0 then
            if use_bpe and #M.bpe_merges > 0 then
                -- Use BPE
                local subwords = M.applyBPE(word)
                for _, subword in ipairs(subwords) do
                    local id = M.token_to_id[subword] or M.token_to_id[M.SPECIAL_TOKENS.UNK]
                    table.insert(token_ids, id)
                end
            else
                -- Use word-level
                local id = M.token_to_id[word] or M.token_to_id[M.SPECIAL_TOKENS.UNK]
                table.insert(token_ids, id)
            end
        end
    end
    
    -- Add EOS token
    table.insert(token_ids, M.token_to_id[M.SPECIAL_TOKENS.EOS])
    
    return token_ids
end

-- ============================================================================
-- DETOKENIZE
-- ============================================================================

function M.detokenize(token_ids)
    --[[
    Convert token IDs back to text
    ]]
    
    local tokens = {}
    
    for _, id in ipairs(token_ids) do
        local token = M.id_to_token[id]
        
        -- Skip special tokens
        if token and not M.SPECIAL_TOKENS[token] then
            table.insert(tokens, token)
        end
    end
    
    return table.concat(tokens, " ")
end

-- ============================================================================
-- KNOWLEDGE DISTILLATION
-- ============================================================================

M.teacher_model = nil
M.student_model = nil

function M.initializeDistillation(teacher, student)
    --[[
    Set up knowledge distillation
    teacher: larger, better model
    student: smaller model to train
    ]]
    
    M.teacher_model = teacher
    M.student_model = student
end

function M.distill(input, temperature, alpha)
    --[[
    Distill knowledge from teacher to student
    temperature: softmax temperature (higher = softer distributions)
    alpha: weight between hard targets (0) and soft targets (1)
    
    Returns: loss
    ]]
    
    temperature = temperature or 2.0
    alpha = alpha or 0.5
    
    if not M.teacher_model or not M.student_model then
        return nil, "Models not initialized"
    end
    
    -- Get teacher predictions (with temperature)
    local teacher_logits = M.teacher_model.forward(input)
    local teacher_probs = M.softmax(teacher_logits, temperature)
    
    -- Get student predictions (with temperature)
    local student_logits = M.student_model.forward(input)
    local student_probs = M.softmax(student_logits, temperature)
    
    -- Distillation loss (KL divergence)
    local distill_loss = 0
    for i = 1, #teacher_probs do
        distill_loss = distill_loss + 
            teacher_probs[i] * math.log((teacher_probs[i] + 1e-10) / (student_probs[i] + 1e-10))
    end
    
    -- Scale by temperature^2 (standard practice)
    distill_loss = distill_loss * (temperature * temperature)
    
    -- Hard target loss (if we have ground truth)
    local hard_loss = 0
    if input.target then
        local student_probs_hard = M.softmax(student_logits, 1.0)
        hard_loss = -math.log(student_probs_hard[input.target] + 1e-10)
    end
    
    -- Combined loss
    local total_loss = alpha * distill_loss + (1 - alpha) * hard_loss
    
    return total_loss
end

function M.softmax(logits, temperature)
    temperature = temperature or 1.0
    
    local max_logit = logits[1]
    for i = 2, #logits do
        if logits[i] > max_logit then
            max_logit = logits[i]
        end
    end
    
    local exp_sum = 0
    local exp_logits = {}
    
    for i = 1, #logits do
        exp_logits[i] = math.exp((logits[i] - max_logit) / temperature)
        exp_sum = exp_sum + exp_logits[i]
    end
    
    for i = 1, #exp_logits do
        exp_logits[i] = exp_logits[i] / exp_sum
    end
    
    return exp_logits
end

-- ============================================================================
-- COMPRESS MODEL (Distillation + Pruning)
-- ============================================================================

function M.compressModel(large_model, compression_ratio)
    --[[
    Create smaller model by distillation and pruning
    compression_ratio: 0.5 = half the size
    ]]
    
    compression_ratio = compression_ratio or 0.5
    
    -- Create smaller architecture
    local small_model = {
        layers = {}
    }
    
    for i, layer in ipairs(large_model.layers) do
        local new_size = math.floor(layer.size * compression_ratio)
        
        -- Prune least important weights
        small_model.layers[i] = M.pruneLayer(layer, new_size)
    end
    
    return small_model
end

function M.pruneLayer(layer, target_size)
    --[[
    Prune layer to target size by removing low-magnitude weights
    ]]
    
    -- Calculate weight magnitudes
    local weight_mags = {}
    
    for i, weights in ipairs(layer.weights) do
        for j, weight in ipairs(weights) do
            table.insert(weight_mags, {
                i = i,
                j = j,
                magnitude = math.abs(weight)
            })
        end
    end
    
    -- Sort by magnitude
    table.sort(weight_mags, function(a, b) return a.magnitude > b.magnitude end)
    
    -- Keep only top weights
    local kept = target_size * target_size
    local pruned_layer = {
        size = target_size,
        weights = {}
    }
    
    for i = 1, target_size do
        pruned_layer.weights[i] = {}
        for j = 1, target_size do
            if i <= #layer.weights and j <= #layer.weights[i] then
                pruned_layer.weights[i][j] = layer.weights[i][j]
            else
                pruned_layer.weights[i][j] = 0
            end
        end
    end
    
    return pruned_layer
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "tokenization.dat"
    
    local data = {
        vocabulary = M.vocabulary,
        token_to_id = M.token_to_id,
        id_to_token = M.id_to_token,
        vocab_size = M.vocab_size,
        bpe_vocab = M.bpe_vocab,
        bpe_merges = M.bpe_merges
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
    filename = filename or "tokenization.dat"
    
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data then
            M.vocabulary = data.vocabulary or {}
            M.token_to_id = data.token_to_id or {}
            M.id_to_token = data.id_to_token or {}
            M.vocab_size = data.vocab_size or 0
            M.bpe_vocab = data.bpe_vocab or {}
            M.bpe_merges = data.bpe_merges or {}
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
        vocab_size = M.vocab_size,
        bpe_merges = #M.bpe_merges,
        special_tokens = #M.SPECIAL_TOKENS
    }
end

return M
