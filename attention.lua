-- Module: attention.lua
-- Attention mechanism - the core of transformer models

local M = {}

-- ============================================================================
-- MULTI-HEAD ATTENTION
-- ============================================================================

function M.createAttentionLayer(d_model, num_heads)
    --[[
    d_model: dimension of embeddings (e.g., 128)
    num_heads: number of attention heads (e.g., 4)
    ]]
    
    assert(d_model % num_heads == 0, "d_model must be divisible by num_heads")
    
    local layer = {
        d_model = d_model,
        num_heads = num_heads,
        d_k = d_model / num_heads,  -- dimension per head
        
        -- Weight matrices (Q, K, V, Output)
        W_q = {},
        W_k = {},
        W_v = {},
        W_o = {},
    }
    
    -- Initialize weight matrices
    local scale = math.sqrt(2.0 / d_model)
    
    for i = 1, d_model do
        layer.W_q[i] = {}
        layer.W_k[i] = {}
        layer.W_v[i] = {}
        layer.W_o[i] = {}
        
        for j = 1, d_model do
            layer.W_q[i][j] = (math.random() - 0.5) * 2 * scale
            layer.W_k[i][j] = (math.random() - 0.5) * 2 * scale
            layer.W_v[i][j] = (math.random() - 0.5) * 2 * scale
            layer.W_o[i][j] = (math.random() - 0.5) * 2 * scale
        end
    end
    
    return layer
end

-- ============================================================================
-- SCALED DOT-PRODUCT ATTENTION
-- ============================================================================

function M.scaledDotProductAttention(Q, K, V, mask)
    --[[
    Q: queries [seq_len x d_k]
    K: keys [seq_len x d_k]
    V: values [seq_len x d_k]
    mask: optional attention mask
    
    Returns: attention output and attention weights
    ]]
    
    local seq_len = #Q
    local d_k = #Q[1]
    
    -- Compute attention scores: Q * K^T / sqrt(d_k)
    local scores = {}
    for i = 1, seq_len do
        scores[i] = {}
        for j = 1, seq_len do
            local dot_product = 0
            for k = 1, d_k do
                dot_product = dot_product + Q[i][k] * K[j][k]
            end
            scores[i][j] = dot_product / math.sqrt(d_k)
        end
    end
    
    -- Apply mask if provided
    if mask then
        for i = 1, seq_len do
            for j = 1, seq_len do
                if mask[i][j] == 0 then
                    scores[i][j] = -1e9  -- Large negative value
                end
            end
        end
    end
    
    -- Apply softmax to get attention weights
    local attention_weights = {}
    for i = 1, seq_len do
        attention_weights[i] = M.softmax(scores[i])
    end
    
    -- Compute weighted sum: attention_weights * V
    local output = {}
    for i = 1, seq_len do
        output[i] = {}
        for k = 1, d_k do
            local sum = 0
            for j = 1, seq_len do
                sum = sum + attention_weights[i][j] * V[j][k]
            end
            output[i][k] = sum
        end
    end
    
    return output, attention_weights
end

-- ============================================================================
-- MULTI-HEAD ATTENTION FORWARD
-- ============================================================================

function M.multiHeadAttention(layer, input_sequence)
    --[[
    input_sequence: [seq_len x d_model]
    
    Returns: output [seq_len x d_model]
    ]]
    
    local seq_len = #input_sequence
    local d_model = layer.d_model
    local num_heads = layer.num_heads
    local d_k = layer.d_k
    
    -- Linear projections for Q, K, V
    local Q = M.matmul(input_sequence, layer.W_q)
    local K = M.matmul(input_sequence, layer.W_k)
    local V = M.matmul(input_sequence, layer.W_v)
    
    -- Split into multiple heads
    local Q_heads = M.splitHeads(Q, num_heads, d_k)
    local K_heads = M.splitHeads(K, num_heads, d_k)
    local V_heads = M.splitHeads(V, num_heads, d_k)
    
    -- Apply attention for each head
    local head_outputs = {}
    for h = 1, num_heads do
        local head_out, _ = M.scaledDotProductAttention(Q_heads[h], K_heads[h], V_heads[h])
        table.insert(head_outputs, head_out)
    end
    
    -- Concatenate heads
    local concatenated = M.concatenateHeads(head_outputs)
    
    -- Final linear projection
    local output = M.matmul(concatenated, layer.W_o)
    
    return output
end

-- ============================================================================
-- SELF-ATTENTION (simplified for conversation context)
-- ============================================================================

function M.selfAttention(tokens, d_model)
    --[[
    Simple self-attention for finding relevant context
    tokens: list of token embeddings
    
    Returns: attention-weighted representation
    ]]
    
    if #tokens == 0 then return nil end
    if #tokens == 1 then return tokens[1] end
    
    local seq_len = #tokens
    
    -- Compute pairwise similarities (simplified attention scores)
    local scores = {}
    for i = 1, seq_len do
        scores[i] = {}
        for j = 1, seq_len do
            -- Cosine similarity
            scores[i][j] = M.cosineSimilarity(tokens[i], tokens[j])
        end
    end
    
    -- Softmax to get attention weights
    local attention_weights = {}
    for i = 1, seq_len do
        attention_weights[i] = M.softmax(scores[i])
    end
    
    -- Weighted sum of tokens
    local output = {}
    for i = 1, seq_len do
        output[i] = {}
        for d = 1, d_model do
            local sum = 0
            for j = 1, seq_len do
                sum = sum + attention_weights[i][j] * tokens[j][d]
            end
            output[i][d] = sum
        end
    end
    
    return output
end

-- ============================================================================
-- CONTEXTUAL ATTENTION (find relevant messages in history)
-- ============================================================================

function M.contextualAttention(query_embedding, context_embeddings, top_k)
    --[[
    Find most relevant context using attention
    query_embedding: current message embedding
    context_embeddings: list of past message embeddings
    top_k: number of relevant contexts to return
    
    Returns: indices of most relevant contexts
    ]]
    
    top_k = top_k or 5
    
    if #context_embeddings == 0 then
        return {}
    end
    
    -- Compute attention scores
    local scores = {}
    for i, context_emb in ipairs(context_embeddings) do
        local score = M.cosineSimilarity(query_embedding, context_emb)
        table.insert(scores, {index = i, score = score})
    end
    
    -- Sort by score
    table.sort(scores, function(a, b) return a.score > b.score end)
    
    -- Return top K indices
    local top_indices = {}
    for i = 1, math.min(top_k, #scores) do
        table.insert(top_indices, scores[i].index)
    end
    
    return top_indices
end

-- ============================================================================
-- CROSS-ATTENTION (attend to different sequences)
-- ============================================================================

function M.crossAttention(query_seq, key_value_seq)
    --[[
    Cross-attention between two sequences
    Useful for: attending to memory while processing current input
    ]]
    
    local d_model = #query_seq[1]
    
    -- Use query from first sequence, keys and values from second
    local scores = {}
    for i = 1, #query_seq do
        scores[i] = {}
        for j = 1, #key_value_seq do
            scores[i][j] = M.cosineSimilarity(query_seq[i], key_value_seq[j])
        end
    end
    
    -- Apply softmax
    local attention_weights = {}
    for i = 1, #query_seq do
        attention_weights[i] = M.softmax(scores[i])
    end
    
    -- Weighted sum
    local output = {}
    for i = 1, #query_seq do
        output[i] = {}
        for d = 1, d_model do
            local sum = 0
            for j = 1, #key_value_seq do
                sum = sum + attention_weights[i][j] * key_value_seq[j][d]
            end
            output[i][d] = sum
        end
    end
    
    return output, attention_weights
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.softmax(scores)
    -- Numerically stable softmax
    local max_score = scores[1]
    for i = 2, #scores do
        if scores[i] > max_score then
            max_score = scores[i]
        end
    end
    
    local exp_scores = {}
    local sum = 0
    for i = 1, #scores do
        exp_scores[i] = math.exp(scores[i] - max_score)
        sum = sum + exp_scores[i]
    end
    
    for i = 1, #exp_scores do
        exp_scores[i] = exp_scores[i] / sum
    end
    
    return exp_scores
end

function M.cosineSimilarity(vec1, vec2)
    if #vec1 ~= #vec2 then return 0 end
    
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

function M.matmul(A, B)
    -- Matrix multiplication A * B
    local rows = #A
    local cols = #B[1]
    local inner = #A[1]
    
    local result = {}
    for i = 1, rows do
        result[i] = {}
        for j = 1, cols do
            local sum = 0
            for k = 1, inner do
                sum = sum + A[i][k] * B[k][j]
            end
            result[i][j] = sum
        end
    end
    
    return result
end

function M.splitHeads(matrix, num_heads, d_k)
    -- Split matrix into multiple heads
    local seq_len = #matrix
    local heads = {}
    
    for h = 1, num_heads do
        heads[h] = {}
        for i = 1, seq_len do
            heads[h][i] = {}
            for j = 1, d_k do
                local idx = (h - 1) * d_k + j
                heads[h][i][j] = matrix[i][idx]
            end
        end
    end
    
    return heads
end

function M.concatenateHeads(heads)
    -- Concatenate multiple heads back together
    local num_heads = #heads
    local seq_len = #heads[1]
    local d_k = #heads[1][1]
    
    local result = {}
    for i = 1, seq_len do
        result[i] = {}
        for h = 1, num_heads do
            for j = 1, d_k do
                table.insert(result[i], heads[h][i][j])
            end
        end
    end
    
    return result
end

-- ============================================================================
-- POSITIONAL ENCODING
-- ============================================================================

function M.positionalEncoding(seq_len, d_model)
    --[[
    Generate positional encodings for transformer
    Allows model to understand position in sequence
    ]]
    
    local encodings = {}
    
    for pos = 1, seq_len do
        encodings[pos] = {}
        for i = 1, d_model do
            if i % 2 == 1 then
                -- Sine for even indices
                encodings[pos][i] = math.sin(pos / (10000 ^ ((i-1) / d_model)))
            else
                -- Cosine for odd indices
                encodings[pos][i] = math.cos(pos / (10000 ^ ((i-2) / d_model)))
            end
        end
    end
    
    return encodings
end

function M.addPositionalEncoding(embeddings)
    local pos_enc = M.positionalEncoding(#embeddings, #embeddings[1])
    
    for i = 1, #embeddings do
        for j = 1, #embeddings[i] do
            embeddings[i][j] = embeddings[i][j] + pos_enc[i][j]
        end
    end
    
    return embeddings
end

return M
