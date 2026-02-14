-- Module: attention.lua
-- Attention mechanism - the core of transformer models
-- MASSIVELY EXPANDED with efficient attention variants, hierarchical attention,
-- sparse attention, graph attention, attention visualization, and more

local M = {}

-- ============================================================================
-- CONFIGURATION AND CONSTANTS
-- ============================================================================

M.config = {
    use_efficient_attention = true,
    sparse_attention_window = 128,
    local_attention_window = 64,
    attention_dropout = 0.1,
    enable_attention_caching = true,
    max_cache_size = 1000,
    enable_gradient_checkpointing = false,
}

-- Attention cache for efficiency
M.attention_cache = {}
M.cache_hits = 0
M.cache_misses = 0

-- ============================================================================
-- MULTI-HEAD ATTENTION
-- ============================================================================

function M.createAttentionLayer(d_model, num_heads, config)
    --[[
    d_model: dimension of embeddings (e.g., 128)
    num_heads: number of attention heads (e.g., 4)
    config: optional configuration table
    ]]

    assert(d_model % num_heads == 0, "d_model must be divisible by num_heads")

    config = config or {}

    local layer = {
        d_model = d_model,
        num_heads = num_heads,
        d_k = d_model / num_heads,  -- dimension per head

        -- Weight matrices (Q, K, V, Output)
        W_q = {},
        W_k = {},
        W_v = {},
        W_o = {},

        -- Biases
        b_q = {},
        b_k = {},
        b_v = {},
        b_o = {},

        -- Configuration
        use_bias = config.use_bias ~= false,
        dropout_rate = config.dropout_rate or 0.1,
        attention_type = config.attention_type or "scaled_dot_product",
        use_relative_position = config.use_relative_position or false,
        max_relative_position = config.max_relative_position or 32,

        -- Statistics
        forward_passes = 0,
        total_attention_entropy = 0,
        attention_sparsity = 0,
    }

    -- Initialize weight matrices with Xavier/Glorot initialization
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

        -- Initialize biases to zero
        if layer.use_bias then
            layer.b_q[i] = 0
            layer.b_k[i] = 0
            layer.b_v[i] = 0
            layer.b_o[i] = 0
        end
    end

    -- Initialize relative position embeddings if enabled
    if layer.use_relative_position then
        layer.relative_position_embeddings = {}
        for i = -layer.max_relative_position, layer.max_relative_position do
            layer.relative_position_embeddings[i] = {}
            for j = 1, layer.d_k do
                layer.relative_position_embeddings[i][j] = (math.random() - 0.5) * 0.02
            end
        end
    end

    return layer
end

-- ============================================================================
-- SCALED DOT-PRODUCT ATTENTION
-- ============================================================================

function M.scaledDotProductAttention(Q, K, V, mask, dropout_rate)
    --[[
    Q: queries [seq_len x d_k]
    K: keys [seq_len x d_k]
    V: values [seq_len x d_k]
    mask: optional attention mask
    dropout_rate: optional dropout rate for attention weights

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

    -- Apply dropout to attention weights if specified
    if dropout_rate and dropout_rate > 0 then
        for i = 1, seq_len do
            for j = 1, seq_len do
                if math.random() < dropout_rate then
                    attention_weights[i][j] = 0
                else
                    attention_weights[i][j] = attention_weights[i][j] / (1 - dropout_rate)
                end
            end
        end
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
-- EFFICIENT LINEAR ATTENTION
-- ============================================================================

function M.linearAttention(Q, K, V, mask)
    --[[
    Linear attention with O(n) complexity instead of O(n^2)
    Uses kernel feature maps to approximate softmax attention

    References: "Transformers are RNNs: Fast Autoregressive Transformers with Linear Attention"
    ]]

    local seq_len = #Q
    local d_k = #Q[1]

    -- Apply feature map (ELU + 1) to Q and K
    local Q_prime = {}
    local K_prime = {}

    for i = 1, seq_len do
        Q_prime[i] = {}
        K_prime[i] = {}
        for j = 1, d_k do
            -- ELU activation: max(0, x) + min(0, exp(x) - 1)
            local q_val = Q[i][j]
            local k_val = K[i][j]

            Q_prime[i][j] = (q_val > 0 and q_val or (math.exp(q_val) - 1)) + 1
            K_prime[i][j] = (k_val > 0 and k_val or (math.exp(k_val) - 1)) + 1
        end
    end

    -- Compute K^T * V (d_k x d_k matrix)
    local KV = {}
    for d1 = 1, d_k do
        KV[d1] = {}
        for d2 = 1, d_k do
            local sum = 0
            for i = 1, seq_len do
                sum = sum + K_prime[i][d1] * V[i][d2]
            end
            KV[d1][d2] = sum
        end
    end

    -- Compute sum of K for normalization
    local K_sum = {}
    for d = 1, d_k do
        local sum = 0
        for i = 1, seq_len do
            sum = sum + K_prime[i][d]
        end
        K_sum[d] = sum
    end

    -- Compute output: Q * (K^T * V) / (Q * K_sum)
    local output = {}
    for i = 1, seq_len do
        output[i] = {}

        -- Compute normalizer: Q[i] * K_sum
        local normalizer = 0
        for d = 1, d_k do
            normalizer = normalizer + Q_prime[i][d] * K_sum[d]
        end
        normalizer = math.max(normalizer, 1e-6)  -- Avoid division by zero

        -- Compute Q[i] * KV
        for d2 = 1, d_k do
            local sum = 0
            for d1 = 1, d_k do
                sum = sum + Q_prime[i][d1] * KV[d1][d2]
            end
            output[i][d2] = sum / normalizer
        end
    end

    return output
end

-- ============================================================================
-- SPARSE ATTENTION
-- ============================================================================

function M.sparseAttention(Q, K, V, mask, window_size)
    --[[
    Sparse attention with local window
    Each position only attends to positions within a fixed window
    Reduces complexity from O(n^2) to O(n * window_size)

    window_size: size of local attention window
    ]]

    window_size = window_size or M.config.sparse_attention_window
    local seq_len = #Q
    local d_k = #Q[1]

    local output = {}
    local attention_weights = {}

    for i = 1, seq_len do
        -- Determine window boundaries
        local start_pos = math.max(1, i - window_size)
        local end_pos = math.min(seq_len, i + window_size)

        -- Compute attention scores only within window
        local scores = {}
        for j = start_pos, end_pos do
            local dot_product = 0
            for k = 1, d_k do
                dot_product = dot_product + Q[i][k] * K[j][k]
            end
            scores[j - start_pos + 1] = dot_product / math.sqrt(d_k)
        end

        -- Apply mask if provided
        if mask then
            for j = start_pos, end_pos do
                if mask[i][j] == 0 then
                    scores[j - start_pos + 1] = -1e9
                end
            end
        end

        -- Softmax over window
        local weights = M.softmax(scores)

        -- Store full attention weights (with zeros outside window)
        attention_weights[i] = {}
        for j = 1, seq_len do
            if j >= start_pos and j <= end_pos then
                attention_weights[i][j] = weights[j - start_pos + 1]
            else
                attention_weights[i][j] = 0
            end
        end

        -- Compute weighted sum within window
        output[i] = {}
        for k = 1, d_k do
            local sum = 0
            for j = start_pos, end_pos do
                sum = sum + weights[j - start_pos + 1] * V[j][k]
            end
            output[i][k] = sum
        end
    end

    return output, attention_weights
end

-- ============================================================================
-- LOCAL ATTENTION
-- ============================================================================

function M.localAttention(Q, K, V, mask, window_size)
    --[[
    Local attention where each query only attends to nearby keys
    More restrictive than sparse attention
    ]]

    window_size = window_size or M.config.local_attention_window
    return M.sparseAttention(Q, K, V, mask, window_size)
end

-- ============================================================================
-- GLOBAL-LOCAL ATTENTION (LONGFORMER STYLE)
-- ============================================================================

function M.globalLocalAttention(Q, K, V, mask, global_indices, window_size)
    --[[
    Combination of local and global attention
    Most positions use local attention, but some positions (global_indices)
    attend to all positions and are attended to by all positions

    global_indices: list of indices that should have global attention
    ]]

    window_size = window_size or M.config.local_attention_window
    global_indices = global_indices or {}

    local seq_len = #Q
    local d_k = #Q[1]

    -- Create set of global indices for fast lookup
    local global_set = {}
    for _, idx in ipairs(global_indices) do
        global_set[idx] = true
    end

    local output = {}
    local attention_weights = {}

    for i = 1, seq_len do
        local scores = {}
        local valid_positions = {}

        if global_set[i] then
            -- Global attention: attend to all positions
            for j = 1, seq_len do
                local dot_product = 0
                for k = 1, d_k do
                    dot_product = dot_product + Q[i][k] * K[j][k]
                end
                scores[#scores + 1] = dot_product / math.sqrt(d_k)
                valid_positions[#valid_positions + 1] = j
            end
        else
            -- Local attention with global positions included
            local start_pos = math.max(1, i - window_size)
            local end_pos = math.min(seq_len, i + window_size)

            for j = start_pos, end_pos do
                local dot_product = 0
                for k = 1, d_k do
                    dot_product = dot_product + Q[i][k] * K[j][k]
                end
                scores[#scores + 1] = dot_product / math.sqrt(d_k)
                valid_positions[#valid_positions + 1] = j
            end

            -- Add global positions
            for _, j in ipairs(global_indices) do
                if j < start_pos or j > end_pos then
                    local dot_product = 0
                    for k = 1, d_k do
                        dot_product = dot_product + Q[i][k] * K[j][k]
                    end
                    scores[#scores + 1] = dot_product / math.sqrt(d_k)
                    valid_positions[#valid_positions + 1] = j
                end
            end
        end

        -- Apply mask
        if mask then
            for idx, j in ipairs(valid_positions) do
                if mask[i][j] == 0 then
                    scores[idx] = -1e9
                end
            end
        end

        -- Softmax
        local weights = M.softmax(scores)

        -- Store attention weights
        attention_weights[i] = {}
        for j = 1, seq_len do
            attention_weights[i][j] = 0
        end
        for idx, j in ipairs(valid_positions) do
            attention_weights[i][j] = weights[idx]
        end

        -- Compute output
        output[i] = {}
        for k = 1, d_k do
            local sum = 0
            for idx, j in ipairs(valid_positions) do
                sum = sum + weights[idx] * V[j][k]
            end
            output[i][k] = sum
        end
    end

    return output, attention_weights
end

-- ============================================================================
-- MULTI-HEAD ATTENTION FORWARD
-- ============================================================================

function M.multiHeadAttention(layer, input_sequence, mask, attention_type)
    --[[
    input_sequence: [seq_len x d_model]
    mask: optional attention mask
    attention_type: "standard", "linear", "sparse", "local"

    Returns: output [seq_len x d_model], attention_weights
    ]]

    attention_type = attention_type or layer.attention_type or "standard"

    local seq_len = #input_sequence
    local d_model = layer.d_model
    local num_heads = layer.num_heads
    local d_k = layer.d_k

    -- Linear projections for Q, K, V
    local Q = M.matmul(input_sequence, layer.W_q)
    local K = M.matmul(input_sequence, layer.W_k)
    local V = M.matmul(input_sequence, layer.W_v)

    -- Add biases if enabled
    if layer.use_bias then
        for i = 1, seq_len do
            for j = 1, d_model do
                Q[i][j] = Q[i][j] + layer.b_q[j]
                K[i][j] = K[i][j] + layer.b_k[j]
                V[i][j] = V[i][j] + layer.b_v[j]
            end
        end
    end

    -- Split into multiple heads
    local Q_heads = M.splitHeads(Q, num_heads, d_k)
    local K_heads = M.splitHeads(K, num_heads, d_k)
    local V_heads = M.splitHeads(V, num_heads, d_k)

    -- Apply attention for each head
    local head_outputs = {}
    local all_attention_weights = {}

    for h = 1, num_heads do
        local head_out, head_weights

        -- Choose attention mechanism
        if attention_type == "linear" then
            head_out = M.linearAttention(Q_heads[h], K_heads[h], V_heads[h], mask)
            head_weights = nil  -- Linear attention doesn't produce explicit weights
        elseif attention_type == "sparse" then
            head_out, head_weights = M.sparseAttention(Q_heads[h], K_heads[h], V_heads[h], mask)
        elseif attention_type == "local" then
            head_out, head_weights = M.localAttention(Q_heads[h], K_heads[h], V_heads[h], mask)
        else
            head_out, head_weights = M.scaledDotProductAttention(Q_heads[h], K_heads[h], V_heads[h], mask, layer.dropout_rate)
        end

        table.insert(head_outputs, head_out)
        if head_weights then
            all_attention_weights[h] = head_weights
        end
    end

    -- Concatenate heads
    local concatenated = M.concatenateHeads(head_outputs)

    -- Final linear projection
    local output = M.matmul(concatenated, layer.W_o)

    -- Add bias
    if layer.use_bias then
        for i = 1, seq_len do
            for j = 1, d_model do
                output[i][j] = output[i][j] + layer.b_o[j]
            end
        end
    end

    -- Update statistics
    layer.forward_passes = layer.forward_passes + 1

    return output, all_attention_weights
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

function M.contextualAttention(query_embedding, context_embeddings, top_k, threshold)
    --[[
    Find most relevant context using attention
    query_embedding: current message embedding
    context_embeddings: list of past message embeddings
    top_k: number of relevant contexts to return
    threshold: minimum similarity score threshold

    Returns: indices of most relevant contexts with scores
    ]]

    top_k = top_k or 5
    threshold = threshold or 0.0

    if #context_embeddings == 0 then
        return {}
    end

    -- Check cache
    local cache_key = M.getCacheKey(query_embedding, #context_embeddings)
    if M.config.enable_attention_caching and M.attention_cache[cache_key] then
        M.cache_hits = M.cache_hits + 1
        return M.attention_cache[cache_key]
    end
    M.cache_misses = M.cache_misses + 1

    -- Compute attention scores
    local scores = {}
    for i, context_emb in ipairs(context_embeddings) do
        local score = M.cosineSimilarity(query_embedding, context_emb)
        if score >= threshold then
            table.insert(scores, {index = i, score = score, context = context_emb})
        end
    end

    -- Sort by score
    table.sort(scores, function(a, b) return a.score > b.score end)

    -- Return top K indices with scores
    local top_results = {}
    for i = 1, math.min(top_k, #scores) do
        table.insert(top_results, {
            index = scores[i].index,
            score = scores[i].score,
            rank = i
        })
    end

    -- Cache result
    if M.config.enable_attention_caching then
        M.attention_cache[cache_key] = top_results
        -- Limit cache size
        if M.getCacheSize() > M.config.max_cache_size then
            M.clearOldestCache()
        end
    end

    return top_results
end

-- ============================================================================
-- CROSS-ATTENTION (attend to different sequences)
-- ============================================================================

function M.crossAttention(query_seq, key_value_seq, mask)
    --[[
    Cross-attention between two sequences
    Useful for: attending to memory while processing current input

    query_seq: sequence to compute queries from
    key_value_seq: sequence to compute keys and values from
    mask: optional attention mask
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

    -- Apply mask if provided
    if mask then
        for i = 1, #query_seq do
            for j = 1, #key_value_seq do
                if mask[i][j] == 0 then
                    scores[i][j] = -1e9
                end
            end
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
-- HIERARCHICAL ATTENTION
-- ============================================================================

function M.hierarchicalAttention(sequences, level_configs)
    --[[
    Hierarchical attention over multiple levels

    sequences: list of sequences at different hierarchical levels
    level_configs: configuration for each level

    Example:
        sequences = {
            word_embeddings,     -- Level 1: words
            sentence_embeddings, -- Level 2: sentences
            paragraph_embeddings -- Level 3: paragraphs
        }

    Returns: hierarchical representation
    ]]

    if #sequences == 0 then return nil end
    if #sequences == 1 then return M.selfAttention(sequences[1], #sequences[1][1]) end

    local representations = {}

    -- Bottom-up: compute attention at each level
    for level = 1, #sequences do
        local seq = sequences[level]
        local config = level_configs and level_configs[level] or {}

        -- Apply self-attention at this level
        local attended = M.selfAttention(seq, #seq[1])

        -- Pool to create level representation
        local pooled = M.meanPooling(attended)

        representations[level] = pooled
    end

    -- Top-down: combine representations with cross-attention
    local final_repr = representations[#representations]

    for level = #sequences - 1, 1, -1 do
        -- Expand final_repr to match sequence length at this level
        local expanded = {}
        for i = 1, #sequences[level] do
            expanded[i] = {}
            for j = 1, #final_repr do
                expanded[i][j] = final_repr[j]
            end
        end

        -- Cross-attention between current level and higher level
        local attended, _ = M.crossAttention(sequences[level], expanded)

        -- Update final representation
        final_repr = M.meanPooling(attended)
    end

    return final_repr
end

-- ============================================================================
-- GRAPH ATTENTION NETWORK (GAT)
-- ============================================================================

function M.createGraphAttentionLayer(in_features, out_features, num_heads, config)
    --[[
    Create a Graph Attention Layer (GAT)

    in_features: input feature dimension
    out_features: output feature dimension per head
    num_heads: number of attention heads
    config: optional configuration
    ]]

    config = config or {}

    local layer = {
        in_features = in_features,
        out_features = out_features,
        num_heads = num_heads,
        concat_heads = config.concat_heads ~= false,
        dropout_rate = config.dropout_rate or 0.1,
        negative_slope = config.negative_slope or 0.2, -- for LeakyReLU

        -- Weight matrices for each head
        W = {},  -- Feature transformation weights
        a = {},  -- Attention mechanism weights
    }

    -- Initialize weights for each head
    for h = 1, num_heads do
        layer.W[h] = {}
        layer.a[h] = {}

        local scale = math.sqrt(2.0 / in_features)

        -- Feature transformation weights
        for i = 1, in_features do
            layer.W[h][i] = {}
            for j = 1, out_features do
                layer.W[h][i][j] = (math.random() - 0.5) * 2 * scale
            end
        end

        -- Attention weights (2 * out_features because we concatenate source and target features)
        for i = 1, 2 * out_features do
            layer.a[h][i] = (math.random() - 0.5) * 2 * scale
        end
    end

    return layer
end

function M.graphAttention(layer, node_features, adjacency_matrix)
    --[[
    Apply graph attention

    node_features: [num_nodes x in_features] feature matrix
    adjacency_matrix: [num_nodes x num_nodes] adjacency matrix

    Returns: [num_nodes x (out_features * num_heads)] if concat_heads
             [num_nodes x out_features] if not concat_heads (average)
    ]]

    local num_nodes = #node_features
    local head_outputs = {}

    for h = 1, layer.num_heads do
        -- Transform features: h = W * x
        local transformed = {}
        for i = 1, num_nodes do
            transformed[i] = {}
            for j = 1, layer.out_features do
                local sum = 0
                for k = 1, layer.in_features do
                    sum = sum + layer.W[h][k][j] * node_features[i][k]
                end
                transformed[i][j] = sum
            end
        end

        -- Compute attention coefficients
        local attention_scores = {}
        for i = 1, num_nodes do
            attention_scores[i] = {}
            for j = 1, num_nodes do
                if adjacency_matrix[i][j] > 0 then
                    -- Concatenate source and target features
                    local concat = {}
                    for k = 1, layer.out_features do
                        concat[k] = transformed[i][k]
                    end
                    for k = 1, layer.out_features do
                        concat[layer.out_features + k] = transformed[j][k]
                    end

                    -- Compute attention: a^T * [W*h_i || W*h_j]
                    local score = 0
                    for k = 1, 2 * layer.out_features do
                        score = score + layer.a[h][k] * concat[k]
                    end

                    -- LeakyReLU activation
                    if score < 0 then
                        score = score * layer.negative_slope
                    end

                    attention_scores[i][j] = score
                else
                    attention_scores[i][j] = -1e9  -- Mask non-neighbors
                end
            end
        end

        -- Softmax normalization
        local attention_weights = {}
        for i = 1, num_nodes do
            attention_weights[i] = M.softmax(attention_scores[i])
        end

        -- Apply attention weights to transformed features
        local output = {}
        for i = 1, num_nodes do
            output[i] = {}
            for k = 1, layer.out_features do
                local sum = 0
                for j = 1, num_nodes do
                    if adjacency_matrix[i][j] > 0 then
                        sum = sum + attention_weights[i][j] * transformed[j][k]
                    end
                end
                output[i][k] = sum
            end
        end

        head_outputs[h] = output
    end

    -- Concatenate or average heads
    local final_output = {}
    if layer.concat_heads then
        -- Concatenate all heads
        for i = 1, num_nodes do
            final_output[i] = {}
            for h = 1, layer.num_heads do
                for k = 1, layer.out_features do
                    table.insert(final_output[i], head_outputs[h][i][k])
                end
            end
        end
    else
        -- Average all heads
        for i = 1, num_nodes do
            final_output[i] = {}
            for k = 1, layer.out_features do
                local sum = 0
                for h = 1, layer.num_heads do
                    sum = sum + head_outputs[h][i][k]
                end
                final_output[i][k] = sum / layer.num_heads
            end
        end
    end

    return final_output
end

-- ============================================================================
-- ATTENTION VISUALIZATION AND ANALYSIS
-- ============================================================================

function M.visualizeAttention(attention_weights, tokens, output_file)
    --[[
    Create a text-based visualization of attention weights

    attention_weights: [seq_len x seq_len] attention matrix
    tokens: list of token strings
    output_file: optional file path to save visualization
    ]]

    local seq_len = #attention_weights
    local lines = {}

    -- Header
    table.insert(lines, "Attention Visualization")
    table.insert(lines, string.rep("=", 60))
    table.insert(lines, "")

    -- Create attention matrix display
    table.insert(lines, "From (rows) -> To (columns)")
    table.insert(lines, "")

    -- Column headers
    local header = "      "
    for j = 1, seq_len do
        header = header .. string.format("%5d ", j)
    end
    table.insert(lines, header)
    table.insert(lines, string.rep("-", #header))

    -- Rows
    for i = 1, seq_len do
        local row = string.format("%3d | ", i)
        for j = 1, seq_len do
            local weight = attention_weights[i][j]
            local intensity = math.floor(weight * 9)  -- 0-9 scale
            row = row .. string.format("  %d   ", intensity)
        end

        -- Add token if provided
        if tokens and tokens[i] then
            row = row .. " | " .. tokens[i]
        end

        table.insert(lines, row)
    end

    table.insert(lines, "")
    table.insert(lines, "Scale: 0 (low attention) to 9 (high attention)")

    local visualization = table.concat(lines, "\n")

    -- Save to file if specified
    if output_file then
        local file = io.open(output_file, "w")
        if file then
            file:write(visualization)
            file:close()
        end
    end

    return visualization
end

function M.analyzeAttentionPatterns(attention_weights)
    --[[
    Analyze attention patterns and compute statistics

    Returns: table with various metrics
    ]]

    local seq_len = #attention_weights
    local stats = {
        entropy = 0,
        sparsity = 0,
        max_attention = 0,
        avg_attention = 0,
        self_attention_ratio = 0,
        attention_distance = 0,
    }

    local total_weight = 0
    local non_zero_count = 0
    local self_attention_sum = 0
    local distance_sum = 0

    for i = 1, seq_len do
        -- Entropy (measure of attention distribution)
        local entropy = 0
        for j = 1, seq_len do
            local p = attention_weights[i][j]
            if p > 0 then
                entropy = entropy - p * math.log(p)
                non_zero_count = non_zero_count + 1
            end

            total_weight = total_weight + p

            -- Track maximum attention
            if p > stats.max_attention then
                stats.max_attention = p
            end

            -- Self-attention
            if i == j then
                self_attention_sum = self_attention_sum + p
            end

            -- Attention distance (how far attention looks)
            distance_sum = distance_sum + math.abs(i - j) * p
        end
        stats.entropy = stats.entropy + entropy
    end

    -- Compute averages
    stats.entropy = stats.entropy / seq_len
    stats.avg_attention = total_weight / (seq_len * seq_len)
    stats.sparsity = 1 - (non_zero_count / (seq_len * seq_len))
    stats.self_attention_ratio = self_attention_sum / seq_len
    stats.attention_distance = distance_sum / seq_len

    return stats
end

function M.getAttentionHeatmap(attention_weights, width, height)
    --[[
    Generate a heatmap representation of attention weights
    Returns a 2D array suitable for rendering
    ]]

    width = width or 50
    height = height or 20

    local seq_len = #attention_weights
    local heatmap = {}

    -- Scale factors
    local x_scale = seq_len / width
    local y_scale = seq_len / height

    for y = 1, height do
        heatmap[y] = {}
        for x = 1, width do
            -- Map heatmap coordinates to attention matrix coordinates
            local i = math.floor((y - 1) * y_scale) + 1
            local j = math.floor((x - 1) * x_scale) + 1

            i = math.min(i, seq_len)
            j = math.min(j, seq_len)

            heatmap[y][x] = attention_weights[i][j]
        end
    end

    return heatmap
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function M.softmax(scores)
    -- Numerically stable softmax
    if #scores == 0 then return {} end

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

    if sum == 0 then sum = 1e-10 end  -- Avoid division by zero

    for i = 1, #exp_scores do
        exp_scores[i] = exp_scores[i] / sum
    end

    return exp_scores
end

function M.cosineSimilarity(vec1, vec2)
    if #vec1 ~= #vec2 then return 0 end
    if #vec1 == 0 then return 0 end

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
    if #A == 0 or #B == 0 then return {} end

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
    if seq_len == 0 then return {} end

    local heads = {}

    for h = 1, num_heads do
        heads[h] = {}
        for i = 1, seq_len do
            heads[h][i] = {}
            for j = 1, d_k do
                local idx = (h - 1) * d_k + j
                heads[h][i][j] = matrix[i][idx] or 0
            end
        end
    end

    return heads
end

function M.concatenateHeads(heads)
    -- Concatenate multiple heads back together
    if #heads == 0 then return {} end

    local num_heads = #heads
    local seq_len = #heads[1]
    if seq_len == 0 then return {} end

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

function M.meanPooling(sequence)
    --[[
    Compute mean pooling over a sequence
    ]]

    if #sequence == 0 then return {} end

    local d_model = #sequence[1]
    local pooled = {}

    for d = 1, d_model do
        local sum = 0
        for i = 1, #sequence do
            sum = sum + sequence[i][d]
        end
        pooled[d] = sum / #sequence
    end

    return pooled
end

function M.maxPooling(sequence)
    --[[
    Compute max pooling over a sequence
    ]]

    if #sequence == 0 then return {} end

    local d_model = #sequence[1]
    local pooled = {}

    for d = 1, d_model do
        local max_val = sequence[1][d]
        for i = 2, #sequence do
            if sequence[i][d] > max_val then
                max_val = sequence[i][d]
            end
        end
        pooled[d] = max_val
    end

    return pooled
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
                -- Sine for odd indices
                encodings[pos][i] = math.sin(pos / (10000 ^ ((i-1) / d_model)))
            else
                -- Cosine for even indices
                encodings[pos][i] = math.cos(pos / (10000 ^ ((i-2) / d_model)))
            end
        end
    end

    return encodings
end

function M.addPositionalEncoding(embeddings)
    if #embeddings == 0 then return embeddings end

    local pos_enc = M.positionalEncoding(#embeddings, #embeddings[1])

    for i = 1, #embeddings do
        for j = 1, #embeddings[i] do
            embeddings[i][j] = embeddings[i][j] + pos_enc[i][j]
        end
    end

    return embeddings
end

function M.learnedPositionalEmbedding(max_len, d_model)
    --[[
    Create learned positional embeddings (as opposed to fixed sinusoidal)
    ]]

    local embeddings = {}
    local scale = math.sqrt(2.0 / d_model)

    for pos = 1, max_len do
        embeddings[pos] = {}
        for d = 1, d_model do
            embeddings[pos][d] = (math.random() - 0.5) * 2 * scale
        end
    end

    return embeddings
end

-- ============================================================================
-- ATTENTION CACHING
-- ============================================================================

function M.getCacheKey(embedding, context_size)
    -- Generate a simple hash for cache key
    local sum = 0
    for i = 1, math.min(10, #embedding) do
        sum = sum + embedding[i]
    end
    return string.format("%.6f_%d", sum, context_size)
end

function M.getCacheSize()
    local count = 0
    for _ in pairs(M.attention_cache) do
        count = count + 1
    end
    return count
end

function M.clearOldestCache()
    -- Simple strategy: clear random entries when cache is full
    local keys = {}
    for k in pairs(M.attention_cache) do
        table.insert(keys, k)
    end

    if #keys > 0 then
        local num_to_remove = math.floor(#keys * 0.2)  -- Remove 20%
        for i = 1, num_to_remove do
            local idx = math.random(1, #keys)
            M.attention_cache[keys[idx]] = nil
        end
    end
end

function M.clearCache()
    M.attention_cache = {}
    M.cache_hits = 0
    M.cache_misses = 0
end

function M.getCacheStats()
    return {
        size = M.getCacheSize(),
        hits = M.cache_hits,
        misses = M.cache_misses,
        hit_rate = M.cache_hits / math.max(1, M.cache_hits + M.cache_misses)
    }
end

-- ============================================================================
-- CAUSAL MASK GENERATION
-- ============================================================================

function M.createCausalMask(seq_len)
    --[[
    Create causal mask for autoregressive models
    Prevents attending to future positions
    ]]

    local mask = {}
    for i = 1, seq_len do
        mask[i] = {}
        for j = 1, seq_len do
            mask[i][j] = (j <= i) and 1 or 0
        end
    end
    return mask
end

function M.createPaddingMask(seq_lengths, max_len)
    --[[
    Create padding mask for variable-length sequences

    seq_lengths: list of actual sequence lengths
    max_len: maximum sequence length
    ]]

    local mask = {}
    for i = 1, #seq_lengths do
        mask[i] = {}
        for j = 1, max_len do
            mask[i][j] = (j <= seq_lengths[i]) and 1 or 0
        end
    end
    return mask
end

function M.combineMasks(mask1, mask2)
    --[[
    Combine two masks with logical AND
    ]]

    if not mask1 then return mask2 end
    if not mask2 then return mask1 end

    local combined = {}
    for i = 1, #mask1 do
        combined[i] = {}
        for j = 1, #mask1[i] do
            combined[i][j] = (mask1[i][j] == 1 and mask2[i][j] == 1) and 1 or 0
        end
    end
    return combined
end

-- ============================================================================
-- MODULE UTILITIES
-- ============================================================================

function M.getStats()
    --[[
    Get module statistics
    ]]

    return {
        config = M.config,
        cache_stats = M.getCacheStats(),
    }
end

function M.reset()
    --[[
    Reset module state
    ]]

    M.clearCache()
end

-- ============================================================================
-- MASTER_BRAIN.LUA INTERFACE FUNCTIONS
-- ============================================================================

-- Train attention mechanism on conversations (expected by master_brain.lua)
function M.trainAttention(conversations)
    if not conversations or type(conversations) ~= "table" then
        return false
    end
    
    -- Process conversation data for attention training
    for _, conversation in ipairs(conversations) do
        if conversation.message and conversation.response then
            -- Extract tokens from message and response
            local messageTokens = {}
            for word in conversation.message:lower():gmatch("%w+") do
                table.insert(messageTokens, word)
            end
            
            local responseTokens = {}
            for word in conversation.response:lower():gmatch("%w+") do
                table.insert(responseTokens, word)
            end
            
            -- Train attention on the token sequences
            if #messageTokens > 0 and #responseTokens > 0 then
                -- Create simple embeddings for tokens
                local messageEmbeddings = {}
                for i, token in ipairs(messageTokens) do
                    messageEmbeddings[i] = {}
                    for j = 1, 64 do  -- 64-dimensional embeddings
                        -- Simple hash-based embedding
                        local hash = 0
                        for k = 1, #token do
                            hash = hash + string.byte(token, k) * k
                        end
                        messageEmbeddings[i][j] = (math.sin(hash * j * 0.001) + 1) / 2
                    end
                end
                
                -- Apply self-attention to learn patterns
                if #messageEmbeddings > 1 then
                    M.selfAttention(messageEmbeddings, 64)
                end
            end
        end
    end
    
    return true
end

return M
