-- Module: embeddings.lua
-- Word embeddings - convert words to high-dimensional vectors

local M = {}

-- ============================================================================
-- EMBEDDING STORAGE
-- ============================================================================

M.vocabulary = {}  -- word -> index
M.embeddings = {}  -- index -> vector
M.embedding_dim = 128
M.vocab_size = 0

-- ============================================================================
-- INITIALIZE EMBEDDINGS
-- ============================================================================

function M.initialize(dim, vocab)
    M.embedding_dim = dim or 128
    
    -- If vocab provided, create embeddings for it
    if vocab then
        for word, idx in pairs(vocab) do
            M.vocabulary[word] = idx
            M.embeddings[idx] = M.randomVector(M.embedding_dim)
        end
        M.vocab_size = #M.embeddings
    end
end

function M.randomVector(dim)
    local vec = {}
    local scale = math.sqrt(2.0 / dim)
    
    for i = 1, dim do
        vec[i] = (math.random() - 0.5) * 2 * scale
    end
    
    return vec
end

-- ============================================================================
-- ADD WORD TO VOCABULARY
-- ============================================================================

function M.addWord(word)
    word = word:lower()
    
    if M.vocabulary[word] then
        return M.vocabulary[word]
    end
    
    M.vocab_size = M.vocab_size + 1
    M.vocabulary[word] = M.vocab_size
    M.embeddings[M.vocab_size] = M.randomVector(M.embedding_dim)
    
    return M.vocab_size
end

-- ============================================================================
-- GET EMBEDDING
-- ============================================================================

function M.getEmbedding(word)
    word = word:lower()
    
    local idx = M.vocabulary[word]
    if not idx then
        -- Unknown word - add it
        idx = M.addWord(word)
    end
    
    return M.embeddings[idx]
end

-- ============================================================================
-- SENTENCE TO EMBEDDING
-- ============================================================================

function M.sentenceToEmbedding(sentence, method)
    --[[
    Convert sentence to single embedding vector
    method: "mean" (average) or "sum" or "weighted"
    ]]
    
    method = method or "mean"
    
    local words = {}
    for word in sentence:gmatch("%S+") do
        word = word:gsub("[%p]+", ""):lower()
        if #word > 0 then
            table.insert(words, word)
        end
    end
    
    if #words == 0 then
        return M.randomVector(M.embedding_dim)
    end
    
    local result = {}
    for i = 1, M.embedding_dim do
        result[i] = 0
    end
    
    -- Sum all word embeddings
    for _, word in ipairs(words) do
        local emb = M.getEmbedding(word)
        for i = 1, M.embedding_dim do
            result[i] = result[i] + emb[i]
        end
    end
    
    -- Average if requested
    if method == "mean" then
        for i = 1, M.embedding_dim do
            result[i] = result[i] / #words
        end
    end
    
    return result
end

-- ============================================================================
-- SEQUENCE TO EMBEDDINGS
-- ============================================================================

function M.sequenceToEmbeddings(sentence)
    --[[
    Convert sentence to sequence of word embeddings
    Returns: list of vectors, one per word
    ]]
    
    local embeddings = {}
    
    for word in sentence:gmatch("%S+") do
        word = word:gsub("[%p]+", ""):lower()
        if #word > 0 then
            table.insert(embeddings, M.getEmbedding(word))
        end
    end
    
    return embeddings
end

-- ============================================================================
-- SUBWORD TOKENIZATION (simple version)
-- ============================================================================

M.subword_vocab = {}

function M.tokenize(word)
    --[[
    Break word into subwords/characters
    Example: "playing" -> ["play", "ing"]
    ]]
    
    word = word:lower()
    
    -- Common suffixes
    local suffixes = {"ing", "ed", "er", "est", "ly", "tion", "sion", "ness", "ment", "ful", "less"}
    
    for _, suffix in ipairs(suffixes) do
        if word:sub(-#suffix) == suffix and #word > #suffix + 2 then
            local root = word:sub(1, -#suffix - 1)
            return {root, suffix}
        end
    end
    
    -- Common prefixes
    local prefixes = {"un", "re", "pre", "dis", "mis", "over", "under"}
    
    for _, prefix in ipairs(prefixes) do
        if word:sub(1, #prefix) == prefix and #word > #prefix + 2 then
            local rest = word:sub(#prefix + 1)
            return {prefix, rest}
        end
    end
    
    -- No subwords found, return whole word
    return {word}
end

function M.getTokenEmbedding(word)
    --[[
    Get embedding using subword tokenization
    Better for unknown words
    ]]
    
    local tokens = M.tokenize(word)
    
    if #tokens == 1 then
        return M.getEmbedding(tokens[1])
    end
    
    -- Average subword embeddings
    local result = {}
    for i = 1, M.embedding_dim do
        result[i] = 0
    end
    
    for _, token in ipairs(tokens) do
        local emb = M.getEmbedding(token)
        for i = 1, M.embedding_dim do
            result[i] = result[i] + emb[i]
        end
    end
    
    for i = 1, M.embedding_dim do
        result[i] = result[i] / #tokens
    end
    
    return result
end

-- ============================================================================
-- WORD SIMILARITY
-- ============================================================================

function M.similarity(word1, word2)
    local emb1 = M.getEmbedding(word1)
    local emb2 = M.getEmbedding(word2)
    
    return M.cosineSimilarity(emb1, emb2)
end

function M.cosineSimilarity(vec1, vec2)
    local dot = 0
    local norm1 = 0
    local norm2 = 0
    
    for i = 1, #vec1 do
        dot = dot + vec1[i] * vec2[i]
        norm1 = norm1 + vec1[i] * vec1[i]
        norm2 = norm2 + vec2[i] * vec2[i]
    end
    
    norm1 = math.sqrt(norm1)
    norm2 = math.sqrt(norm2)
    
    if norm1 == 0 or norm2 == 0 then return 0 end
    
    return dot / (norm1 * norm2)
end

-- ============================================================================
-- FIND SIMILAR WORDS
-- ============================================================================

function M.findSimilar(word, top_k)
    top_k = top_k or 5
    
    local target_emb = M.getEmbedding(word)
    local similarities = {}
    
    for w, idx in pairs(M.vocabulary) do
        if w ~= word:lower() then
            local sim = M.cosineSimilarity(target_emb, M.embeddings[idx])
            table.insert(similarities, {word = w, similarity = sim})
        end
    end
    
    table.sort(similarities, function(a, b) return a.similarity > b.similarity end)
    
    local results = {}
    for i = 1, math.min(top_k, #similarities) do
        table.insert(results, similarities[i])
    end
    
    return results
end

-- ============================================================================
-- WORD ANALOGIES (king - man + woman ≈ queen)
-- ============================================================================

function M.analogy(word_a, word_b, word_c)
    --[[
    Find word D such that: A is to B as C is to D
    Example: king is to man as woman is to ???
    ]]
    
    local emb_a = M.getEmbedding(word_a)
    local emb_b = M.getEmbedding(word_b)
    local emb_c = M.getEmbedding(word_c)
    
    -- Compute target: emb_c + (emb_a - emb_b)
    local target = {}
    for i = 1, M.embedding_dim do
        target[i] = emb_c[i] + (emb_a[i] - emb_b[i])
    end
    
    -- Find closest word
    local best_word = nil
    local best_sim = -1
    
    for word, idx in pairs(M.vocabulary) do
        if word ~= word_a:lower() and word ~= word_b:lower() and word ~= word_c:lower() then
            local sim = M.cosineSimilarity(target, M.embeddings[idx])
            if sim > best_sim then
                best_sim = sim
                best_word = word
            end
        end
    end
    
    return best_word, best_sim
end

-- ============================================================================
-- TRAIN EMBEDDINGS (Word2Vec style)
-- ============================================================================

function M.train(sentences, epochs, learning_rate)
    --[[
    Train embeddings using Skip-gram approach
    sentences: list of sentences
    ]]
    
    epochs = epochs or 5
    learning_rate = learning_rate or 0.01
    
    -- Build vocabulary from sentences
    for _, sentence in ipairs(sentences) do
        for word in sentence:gmatch("%S+") do
            word = word:gsub("[%p]+", ""):lower()
            if #word > 0 then
                M.addWord(word)
            end
        end
    end
    
    -- Training loop
    for epoch = 1, epochs do
        for _, sentence in ipairs(sentences) do
            local words = {}
            for word in sentence:gmatch("%S+") do
                word = word:gsub("[%p]+", ""):lower()
                if #word > 0 then
                    table.insert(words, word)
                end
            end
            
            -- Train on context windows
            local window = 2
            for i = 1, #words do
                local center_word = words[i]
                local center_idx = M.vocabulary[center_word]
                
                -- Get context words
                for j = math.max(1, i - window), math.min(#words, i + window) do
                    if i ~= j then
                        local context_word = words[j]
                        local context_idx = M.vocabulary[context_word]
                        
                        -- Update embeddings to make them more similar
                        M.updateEmbeddings(center_idx, context_idx, learning_rate)
                    end
                end
            end
        end
    end
end

function M.updateEmbeddings(idx1, idx2, lr)
    -- Simple update: move embeddings closer together
    for i = 1, M.embedding_dim do
        local diff = M.embeddings[idx2][i] - M.embeddings[idx1][i]
        M.embeddings[idx1][i] = M.embeddings[idx1][i] + lr * diff * 0.1
        M.embeddings[idx2][i] = M.embeddings[idx2][i] - lr * diff * 0.1
    end
end

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function M.save(filename)
    filename = filename or "embeddings.dat"
    
    local data = {
        vocabulary = M.vocabulary,
        embeddings = M.embeddings,
        embedding_dim = M.embedding_dim,
        vocab_size = M.vocab_size
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
    filename = filename or "embeddings.dat"
    
    if not fs.exists(filename) then
        return false
    end
    
    local file = fs.open(filename, "r")
    if file then
        local data = textutils.unserialize(file.readAll())
        file.close()
        
        if data then
            M.vocabulary = data.vocabulary
            M.embeddings = data.embeddings
            M.embedding_dim = data.embedding_dim
            M.vocab_size = data.vocab_size
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- INITIALIZE WITH COMMON WORDS
-- ============================================================================

function M.initializeDefaults()
    M.initialize(128)
    
    -- Add common words
    local common_words = {
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their",
        "what", "so", "up", "out", "if", "about", "who", "get", "which", "go",
        "me", "when", "make", "can", "like", "time", "no", "just", "him", "know",
        "take", "people", "into", "year", "your", "good", "some", "could", "them",
        "see", "other", "than", "then", "now", "look", "only", "come", "its", "over",
        "think", "also", "back", "after", "use", "two", "how", "our", "work", "first",
        "well", "way", "even", "new", "want", "because", "any", "these", "give", "day"
    }
    
    for _, word in ipairs(common_words) do
        M.addWord(word)
    end
    
    M.save()
end

return M
