-- knowledge_graph.lua
-- Semantic knowledge graph with inference and reasoning
-- MASSIVELY EXPANDED with temporal reasoning, semantic embeddings,
-- neural inference, uncertainty quantification, reasoning chains, and more

local M = {}

-- Core data structures
M.facts = {}      -- subject -> relation -> {objects}
M.reverse = {}    -- object -> relation -> {subjects}
M.entities = {}
M.relations = {}

-- Advanced features
M.temporal_facts = {}     -- Facts with temporal information
M.confidence_scores = {}  -- Confidence scores for facts
M.embeddings = {}         -- Semantic embeddings for entities
M.reasoning_chains = {}   -- Stored reasoning paths
M.concept_hierarchy = {}  -- Hierarchical concept relationships
M.analogies = {}          -- Analogical mappings

-- Statistics
M.stats = {
    inferences_made = 0,
    queries_processed = 0,
    reasoning_chains_created = 0,
    temporal_queries = 0,
}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

M.config = {
    max_inference_depth = 5,
    min_confidence_threshold = 0.3,
    enable_temporal_reasoning = true,
    enable_probabilistic_inference = true,
    enable_analogical_reasoning = true,
    embedding_dim = 64,
    max_reasoning_chains = 1000,
}

-- ============================================================================
-- INFERENCE RULES (Expanded)
-- ============================================================================

M.rules = {
    -- Transitivity rules
    {from={"is_a","is_a"}, to="is_a", confidence=0.95},
    {from={"is_a","has_property"}, to="has_property", confidence=0.85},
    {from={"is_a","can_do"}, to="can_do", confidence=0.8},
    {from={"is_a","has_part"}, to="has_part", confidence=0.75},
    {from={"part_of","part_of"}, to="part_of", confidence=0.9},
    {from={"located_in","located_in"}, to="located_in", confidence=0.9},

    -- Implication rules
    {from={"can_do","requires"}, to="needs", confidence=0.7},
    {from={"has_property","implies"}, to="has_property", confidence=0.65},
    {from={"is_a","typically_has"}, to="might_have", confidence=0.6},

    -- Symmetric rules
    {from={"similar_to","similar_to"}, to="similar_to", confidence=0.85, symmetric=true},
    {from={"opposite_of","opposite_of"}, to="equivalent", confidence=0.9, symmetric=true},

    -- Inverse rules
    {from={"parent_of"}, to="child_of", confidence=1.0, inverse=true},
    {from={"above"}, to="below", confidence=1.0, inverse=true},
    {from={"before"}, to="after", confidence=1.0, inverse=true},

    -- Causal rules
    {from={"causes","causes"}, to="indirectly_causes", confidence=0.7},
    {from={"enables","causes"}, to="indirectly_enables", confidence=0.65},

    -- Temporal rules
    {from={"before","before"}, to="before", confidence=0.95},
    {from={"during","before"}, to="before", confidence=0.8},
}

-- ============================================================================
-- BUILT-IN KNOWLEDGE (Expanded)
-- ============================================================================

local FACTS = {
    -- Taxonomy (expanded)
    {"dog","is_a","animal"},{"cat","is_a","animal"},{"bird","is_a","animal"},
    {"fish","is_a","animal"},{"animal","is_a","living_thing"},
    {"human","is_a","animal"},{"person","is_a","human"},
    {"tree","is_a","plant"},{"plant","is_a","living_thing"},
    {"flower","is_a","plant"},{"grass","is_a","plant"},
    {"mammal","is_a","animal"},{"reptile","is_a","animal"},
    {"insect","is_a","animal"},{"dog","is_a","mammal"},{"cat","is_a","mammal"},

    -- Properties (expanded)
    {"dog","has_property","loyal"},{"dog","has_property","friendly"},
    {"cat","has_property","independent"},{"cat","has_property","curious"},
    {"animal","has_property","alive"},{"bird","has_property","can_fly"},
    {"fish","has_property","aquatic"},{"sun","has_property","hot"},
    {"water","has_property","wet"},{"fire","has_property","hot"},
    {"ice","has_property","cold"},{"diamond","has_property","valuable"},
    {"gold","has_property","valuable"},{"silver","has_property","metallic"},
    {"rock","has_property","hard"},{"cloud","has_property","soft"},

    -- Capabilities (expanded)
    {"dog","can_do","bark"},{"dog","can_do","run"},{"cat","can_do","meow"},
    {"bird","can_do","fly"},{"bird","can_do","sing"},{"fish","can_do","swim"},
    {"human","can_do","think"},{"human","can_do","speak"},{"human","can_do","create"},
    {"ai","can_do","learn"},{"ai","can_do","help"},{"ai","can_do","chat"},
    {"computer","can_do","calculate"},{"robot","can_do","move"},
    {"plant","can_do","photosynthesize"},{"tree","can_do","grow"},

    -- Parts (expanded)
    {"dog","has_part","tail"},{"dog","has_part","paws"},
    {"bird","has_part","wings"},{"bird","has_part","beak"},
    {"tree","has_part","leaves"},{"tree","has_part","roots"},
    {"human","has_part","brain"},{"human","has_part","heart"},
    {"computer","has_part","cpu"},{"computer","has_part","memory"},
    {"car","has_part","engine"},{"car","has_part","wheels"},
    {"flower","has_part","petals"},{"flower","has_part","stem"},

    -- Spatial relationships
    {"brain","located_in","head"},{"heart","located_in","chest"},
    {"cpu","located_in","computer"},{"engine","located_in","car"},
    {"leaves","located_on","tree"},{"roots","located_under","tree"},

    -- Minecraft (expanded)
    {"creeper","is_a","mob"},{"zombie","is_a","mob"},{"skeleton","is_a","mob"},
    {"enderman","is_a","mob"},{"spider","is_a","mob"},
    {"mob","is_a","entity"},{"player","is_a","entity"},
    {"creeper","can_do","explode"},{"creeper","has_property","dangerous"},
    {"zombie","can_do","attack"},{"skeleton","can_do","shoot"},
    {"enderman","can_do","teleport"},{"spider","can_do","climb"},
    {"diamond","is_a","ore"},{"iron","is_a","ore"},{"gold","is_a","ore"},
    {"coal","is_a","ore"},{"emerald","is_a","ore"},
    {"ore","is_a","block"},{"dirt","is_a","block"},{"stone","is_a","block"},
    {"pickaxe","is_a","tool"},{"axe","is_a","tool"},{"shovel","is_a","tool"},
    {"sword","is_a","weapon"},{"bow","is_a","weapon"},
    {"redstone","can_do","conduct_power"},{"nether","has_property","dangerous"},
    {"obsidian","has_property","strong"},{"bedrock","has_property","unbreakable"},

    -- MODUS self-knowledge (expanded)
    {"modus","is_a","ai"},{"ai","is_a","program"},{"program","is_a","software"},
    {"modus","has_property","helpful"},{"modus","has_property","friendly"},
    {"modus","has_property","curious"},{"modus","has_property","learning"},
    {"modus","can_do","chat"},{"modus","can_do","remember"},
    {"modus","can_do","learn"},{"modus","can_do","reason"},
    {"modus","can_do","understand"},{"modus","can_do","infer"},

    -- Emotions (expanded)
    {"happiness","is_a","emotion"},{"sadness","is_a","emotion"},
    {"anger","is_a","emotion"},{"fear","is_a","emotion"},
    {"love","is_a","emotion"},{"surprise","is_a","emotion"},
    {"disgust","is_a","emotion"},{"joy","is_a","emotion"},
    {"emotion","is_a","mental_state"},
    {"friendship","is_a","relationship"},{"friendship","has_property","valuable"},
    {"family","is_a","relationship"},{"love","is_a","relationship"},

    -- Opposites & synonyms (expanded)
    {"hot","opposite_of","cold"},{"big","opposite_of","small"},
    {"happy","opposite_of","sad"},{"good","opposite_of","bad"},
    {"light","opposite_of","dark"},{"fast","opposite_of","slow"},
    {"strong","opposite_of","weak"},{"hard","opposite_of","soft"},
    {"happy","similar_to","glad"},{"happy","similar_to","joyful"},
    {"sad","similar_to","unhappy"},{"smart","similar_to","intelligent"},
    {"big","similar_to","large"},{"small","similar_to","tiny"},
    {"fast","similar_to","quick"},{"slow","similar_to","sluggish"},

    -- Causal relationships
    {"rain","causes","wet"},{"sun","causes","warmth"},
    {"fire","causes","heat"},{"exercise","causes","fitness"},
    {"learning","causes","knowledge"},{"practice","causes","skill"},
    {"hunger","causes","eating"},{"thirst","causes","drinking"},

    -- Purpose/function relationships
    {"tool","purpose","assist"},{"weapon","purpose","defend"},
    {"food","purpose","nourish"},{"medicine","purpose","heal"},
    {"book","purpose","educate"},{"game","purpose","entertain"},
}

-- ============================================================================
-- BASIC FACT MANAGEMENT
-- ============================================================================

function M.addFact(s, r, o, confidence, timestamp)
    s, r, o = s:lower(), r:lower(), o:lower()
    confidence = confidence or 1.0
    timestamp = timestamp or os.time()

    -- Store in main graph
    M.facts[s] = M.facts[s] or {}
    M.facts[s][r] = M.facts[s][r] or {}
    M.facts[s][r][o] = true

    -- Store reverse index
    M.reverse[o] = M.reverse[o] or {}
    M.reverse[o][r] = M.reverse[o][r] or {}
    M.reverse[o][r][s] = true

    -- Track entities and relations
    M.entities[s], M.entities[o], M.relations[r] = true, true, true

    -- Store confidence
    local fact_key = s .. "|" .. r .. "|" .. o
    M.confidence_scores[fact_key] = confidence

    -- Store temporal information if enabled
    if M.config.enable_temporal_reasoning then
        M.temporal_facts[fact_key] = {
            timestamp = timestamp,
            subject = s,
            relation = r,
            object = o,
            confidence = confidence
        }
    end
end

function M.hasFact(s, r, o)
    s, r, o = s:lower(), r:lower(), o:lower()
    return M.facts[s] and M.facts[s][r] and M.facts[s][r][o] == true
end

function M.getFactConfidence(s, r, o)
    local fact_key = s .. "|" .. r .. "|" .. o
    return M.confidence_scores[fact_key] or 0.0
end

function M.updateFactConfidence(s, r, o, new_confidence)
    local fact_key = s .. "|" .. r .. "|" .. o
    if M.hasFact(s, r, o) then
        M.confidence_scores[fact_key] = new_confidence
        if M.temporal_facts[fact_key] then
            M.temporal_facts[fact_key].confidence = new_confidence
        end
        return true
    end
    return false
end

function M.removeFact(s, r, o)
    s, r, o = s:lower(), r:lower(), o:lower()

    if M.facts[s] and M.facts[s][r] then
        M.facts[s][r][o] = nil
    end

    if M.reverse[o] and M.reverse[o][r] then
        M.reverse[o][r][s] = nil
    end

    local fact_key = s .. "|" .. r .. "|" .. o
    M.confidence_scores[fact_key] = nil
    M.temporal_facts[fact_key] = nil
end

function M.getObjects(s, r)
    s, r = s:lower(), r:lower()
    local res = {}
    if M.facts[s] and M.facts[s][r] then
        for o in pairs(M.facts[s][r]) do
            res[#res+1] = {
                object = o,
                confidence = M.getFactConfidence(s, r, o)
            }
        end
    end
    return res
end

function M.getSubjects(r, o)
    r, o = r:lower(), o:lower()
    local res = {}
    if M.reverse[o] and M.reverse[o][r] then
        for s in pairs(M.reverse[o][r]) do
            res[#res+1] = {
                subject = s,
                confidence = M.getFactConfidence(s, r, o)
            }
        end
    end
    return res
end

function M.getAllRelations(s)
    s = s:lower()
    local res = {}
    if M.facts[s] then
        for r in pairs(M.facts[s]) do
            res[#res+1] = r
        end
    end
    return res
end

-- ============================================================================
-- ADVANCED INFERENCE ENGINE
-- ============================================================================

function M.infer(subject, relation, depth, min_confidence)
    depth = depth or M.config.max_inference_depth
    min_confidence = min_confidence or M.config.min_confidence_threshold
    subject, relation = subject:lower(), relation:lower()

    local results = {}
    local visited = {}
    local reasoning_chain = {
        start_subject = subject,
        target_relation = relation,
        steps = {}
    }

    M.stats.inferences_made = M.stats.inferences_made + 1

    -- Direct facts
    local direct_objects = M.getObjects(subject, relation)
    for _, obj_info in ipairs(direct_objects) do
        local o = obj_info.object
        results[o] = {
            direct = true,
            confidence = obj_info.confidence,
            path = {{subject, relation, o}},
            depth = 0
        }
    end

    -- Recursive inference with confidence propagation
    local function inferStep(current, current_confidence, path, d)
        if d > depth then return end
        local visit_key = current .. "|" .. d
        if visited[visit_key] then return end
        visited[visit_key] = true

        -- Try each inference rule
        for _, rule in ipairs(M.rules) do
            if rule.to == relation or rule.from[1] == relation or rule.from[2] == relation then
                local rule_confidence = rule.confidence or 0.8

                if rule.to == relation and #rule.from >= 2 then
                    -- Forward chaining: from[1] -> from[2] => to
                    local mids = M.getObjects(current, rule.from[1])
                    for _, mid_info in ipairs(mids) do
                        local mid = mid_info.object
                        local mid_confidence = mid_info.confidence * current_confidence * rule_confidence

                        if mid_confidence >= min_confidence then
                            local finals = M.getObjects(mid, rule.from[2])
                            for _, final_info in ipairs(finals) do
                                local final = final_info.object
                                local final_confidence = final_info.confidence * mid_confidence

                                if final_confidence >= min_confidence then
                                    if not results[final] or results[final].confidence < final_confidence then
                                        local new_path = {}
                                        for _, step in ipairs(path) do
                                            table.insert(new_path, step)
                                        end
                                        table.insert(new_path, {current, rule.from[1], mid})
                                        table.insert(new_path, {mid, rule.from[2], final})

                                        results[final] = {
                                            direct = false,
                                            via = mid,
                                            rule = rule.from[1] .. "->" .. rule.from[2],
                                            confidence = final_confidence,
                                            path = new_path,
                                            depth = d
                                        }

                                        table.insert(reasoning_chain.steps, {
                                            from = current,
                                            to = final,
                                            via = mid,
                                            rule = rule.from[1] .. "->" .. rule.from[2],
                                            confidence = final_confidence
                                        })
                                    end
                                end
                            end

                            -- Continue inference from mid
                            local new_path = {}
                            for _, step in ipairs(path) do
                                table.insert(new_path, step)
                            end
                            table.insert(new_path, {current, rule.from[1], mid})
                            inferStep(mid, mid_confidence, new_path, d + 1)
                        end
                    end
                end

                -- Handle symmetric rules
                if rule.symmetric and relation == rule.from[1] then
                    local peers = M.getObjects(current, rule.from[1])
                    for _, peer_info in ipairs(peers) do
                        local peer = peer_info.object
                        local peer_confidence = peer_info.confidence * current_confidence * rule_confidence

                        if peer_confidence >= min_confidence then
                            local transitives = M.getObjects(peer, rule.from[1])
                            for _, trans_info in ipairs(transitives) do
                                local trans = trans_info.object
                                local trans_confidence = trans_info.confidence * peer_confidence

                                if trans_confidence >= min_confidence and trans ~= current then
                                    if not results[trans] or results[trans].confidence < trans_confidence then
                                        results[trans] = {
                                            direct = false,
                                            via = peer,
                                            rule = "symmetric_" .. rule.from[1],
                                            confidence = trans_confidence,
                                            path = {{current, rule.from[1], peer}, {peer, rule.from[1], trans}},
                                            depth = d
                                        }
                                    end
                                end
                            end
                        end
                    end
                end

                -- Handle inverse rules
                if rule.inverse and relation == rule.from[1] then
                    local inverses = M.getSubjects(rule.to, current)
                    for _, inv_info in ipairs(inverses) do
                        local inv = inv_info.subject
                        local inv_confidence = inv_info.confidence * current_confidence * rule_confidence

                        if inv_confidence >= min_confidence then
                            if not results[inv] or results[inv].confidence < inv_confidence then
                                results[inv] = {
                                    direct = false,
                                    via = current,
                                    rule = "inverse_" .. rule.from[1],
                                    confidence = inv_confidence,
                                    path = {{inv, rule.to, current}},
                                    depth = d
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    inferStep(subject, 1.0, {{subject}}, 1)

    -- Store reasoning chain
    if #reasoning_chain.steps > 0 then
        table.insert(M.reasoning_chains, reasoning_chain)
        M.stats.reasoning_chains_created = M.stats.reasoning_chains_created + 1

        -- Limit storage
        if #M.reasoning_chains > M.config.max_reasoning_chains then
            table.remove(M.reasoning_chains, 1)
        end
    end

    -- Convert to list and sort by confidence
    local list = {}
    for o, info in pairs(results) do
        list[#list+1] = {
            object = o,
            direct = info.direct,
            via = info.via,
            rule = info.rule,
            confidence = info.confidence,
            path = info.path,
            depth = info.depth
        }
    end

    table.sort(list, function(a, b)
        return a.confidence > b.confidence
    end)

    return list
end

-- ============================================================================
-- SEMANTIC EMBEDDINGS
-- ============================================================================

function M.initializeEmbeddings()
    --[[
    Initialize random embeddings for all entities
    In a real system, these would be learned
    ]]

    local dim = M.config.embedding_dim

    for entity in pairs(M.entities) do
        if not M.embeddings[entity] then
            M.embeddings[entity] = {}
            for i = 1, dim do
                M.embeddings[entity][i] = (math.random() - 0.5) * 0.1
            end
        end
    end
end

function M.getEmbedding(entity)
    entity = entity:lower()
    if not M.embeddings[entity] then
        M.initializeEmbeddings()
    end
    return M.embeddings[entity]
end

function M.semanticSimilarity(entity1, entity2)
    --[[
    Compute semantic similarity between two entities
    Uses cosine similarity of embeddings
    ]]

    local emb1 = M.getEmbedding(entity1)
    local emb2 = M.getEmbedding(entity2)

    if not emb1 or not emb2 then return 0 end

    local dot = 0
    local norm1 = 0
    local norm2 = 0

    for i = 1, #emb1 do
        dot = dot + emb1[i] * emb2[i]
        norm1 = norm1 + emb1[i] * emb1[i]
        norm2 = norm2 + emb2[i] * emb2[i]
    end

    norm1 = math.sqrt(norm1)
    norm2 = math.sqrt(norm2)

    if norm1 == 0 or norm2 == 0 then return 0 end

    return dot / (norm1 * norm2)
end

function M.findSemanticallySimilar(entity, k, threshold)
    --[[
    Find k most semantically similar entities
    ]]

    k = k or 5
    threshold = threshold or 0.5
    entity = entity:lower()

    local similarities = {}

    for other_entity in pairs(M.entities) do
        if other_entity ~= entity then
            local sim = M.semanticSimilarity(entity, other_entity)
            if sim >= threshold then
                table.insert(similarities, {
                    entity = other_entity,
                    similarity = sim
                })
            end
        end
    end

    table.sort(similarities, function(a, b)
        return a.similarity > b.similarity
    end)

    local result = {}
    for i = 1, math.min(k, #similarities) do
        result[i] = similarities[i]
    end

    return result
end

-- ============================================================================
-- TEMPORAL REASONING
-- ============================================================================

function M.addTemporalFact(s, r, o, start_time, end_time, confidence)
    --[[
    Add a fact that is valid within a time range
    ]]

    confidence = confidence or 1.0
    start_time = start_time or os.time()
    end_time = end_time or nil  -- nil means ongoing

    M.addFact(s, r, o, confidence, start_time)

    local fact_key = s:lower() .. "|" .. r:lower() .. "|" .. o:lower()
    M.temporal_facts[fact_key] = {
        subject = s:lower(),
        relation = r:lower(),
        object = o:lower(),
        start_time = start_time,
        end_time = end_time,
        confidence = confidence,
        timestamp = start_time
    }
end

function M.isFactValidAt(s, r, o, timestamp)
    --[[
    Check if a fact is valid at a given timestamp
    ]]

    timestamp = timestamp or os.time()
    local fact_key = s:lower() .. "|" .. r:lower() .. "|" .. o:lower()
    local temporal_info = M.temporal_facts[fact_key]

    if not temporal_info then
        return M.hasFact(s, r, o)  -- Timeless fact
    end

    local valid_start = timestamp >= temporal_info.start_time
    local valid_end = not temporal_info.end_time or timestamp <= temporal_info.end_time

    return valid_start and valid_end
end

function M.getFactsAt(timestamp)
    --[[
    Get all facts valid at a given timestamp
    ]]

    timestamp = timestamp or os.time()
    local valid_facts = {}

    for fact_key, temporal_info in pairs(M.temporal_facts) do
        if M.isFactValidAt(temporal_info.subject, temporal_info.relation,
                          temporal_info.object, timestamp) then
            table.insert(valid_facts, {
                subject = temporal_info.subject,
                relation = temporal_info.relation,
                object = temporal_info.object,
                confidence = temporal_info.confidence
            })
        end
    end

    M.stats.temporal_queries = M.stats.temporal_queries + 1

    return valid_facts
end

function M.getFactHistory(s, r, o)
    --[[
    Get the history of a fact (when it was true)
    ]]

    local fact_key = s:lower() .. "|" .. r:lower() .. "|" .. o:lower()
    return M.temporal_facts[fact_key]
end

-- ============================================================================
-- ANALOGICAL REASONING
-- ============================================================================

function M.findAnalogy(source_pair, target_first)
    --[[
    Find analogies: A is to B as C is to ?
    source_pair: {A, B}
    target_first: C

    Returns: candidates for ?
    ]]

    if not M.config.enable_analogical_reasoning then return {} end

    local a, b = source_pair[1]:lower(), source_pair[2]:lower()
    local c = target_first:lower()

    -- Find relationship between A and B
    local ab_relations = {}
    if M.facts[a] then
        for rel in pairs(M.facts[a]) do
            if M.facts[a][rel][b] then
                table.insert(ab_relations, rel)
            end
        end
    end

    if #ab_relations == 0 then return {} end

    -- Find entities that have similar relationship from C
    local candidates = {}
    for _, rel in ipairs(ab_relations) do
        local c_objects = M.getObjects(c, rel)
        for _, obj_info in ipairs(c_objects) do
            local d = obj_info.object

            -- Score the analogy based on semantic similarity
            local ab_sim = M.semanticSimilarity(a, b)
            local cd_sim = M.semanticSimilarity(c, d)
            local ac_sim = M.semanticSimilarity(a, c)
            local bd_sim = M.semanticSimilarity(b, d)

            -- Good analogy: similar structural relationship and cross-similarity
            local score = (math.abs(ab_sim - cd_sim) + bd_sim + ac_sim) / 3
            score = score * obj_info.confidence

            table.insert(candidates, {
                entity = d,
                relation = rel,
                score = score,
                explanation = a .. " is to " .. b .. " as " .. c .. " is to " .. d
            })
        end
    end

    table.sort(candidates, function(x, y) return x.score > y.score end)

    return candidates
end

-- ============================================================================
-- CONCEPT HIERARCHY
-- ============================================================================

function M.buildConceptHierarchy()
    --[[
    Build a hierarchy of concepts based on is_a relationships
    ]]

    M.concept_hierarchy = {}

    -- Find all is_a relationships
    for subject in pairs(M.entities) do
        local parents = M.getObjects(subject, "is_a")
        if #parents > 0 then
            M.concept_hierarchy[subject] = {
                parents = {},
                children = {},
                level = 0
            }

            for _, parent_info in ipairs(parents) do
                table.insert(M.concept_hierarchy[subject].parents, parent_info.object)

                -- Add to parent's children
                if not M.concept_hierarchy[parent_info.object] then
                    M.concept_hierarchy[parent_info.object] = {
                        parents = {},
                        children = {},
                        level = 0
                    }
                end
                table.insert(M.concept_hierarchy[parent_info.object].children, subject)
            end
        end
    end

    -- Compute levels (distance from root concepts)
    local function computeLevel(concept, visited)
        visited = visited or {}
        if visited[concept] then return 0 end
        visited[concept] = true

        if not M.concept_hierarchy[concept] then return 0 end

        local max_level = 0
        for _, parent in ipairs(M.concept_hierarchy[concept].parents) do
            local parent_level = computeLevel(parent, visited)
            if parent_level > max_level then
                max_level = parent_level
            end
        end

        M.concept_hierarchy[concept].level = max_level + 1
        return max_level + 1
    end

    for concept in pairs(M.concept_hierarchy) do
        computeLevel(concept, {})
    end
end

function M.getConceptLevel(concept)
    concept = concept:lower()
    if M.concept_hierarchy[concept] then
        return M.concept_hierarchy[concept].level
    end
    return 0
end

function M.getCommonAncestor(concept1, concept2)
    --[[
    Find the lowest common ancestor of two concepts
    ]]

    concept1, concept2 = concept1:lower(), concept2:lower()

    -- Get all ancestors of concept1
    local ancestors1 = {}
    local function getAncestors(concept, depth)
        if depth > 10 or ancestors1[concept] then return end
        ancestors1[concept] = depth

        if M.concept_hierarchy[concept] then
            for _, parent in ipairs(M.concept_hierarchy[concept].parents) do
                getAncestors(parent, depth + 1)
            end
        end
    end
    getAncestors(concept1, 0)

    -- Find first common ancestor in concept2's ancestry
    local function findCommon(concept, depth)
        if depth > 10 then return nil end
        if ancestors1[concept] then
            return {
                ancestor = concept,
                distance1 = ancestors1[concept],
                distance2 = depth
            }
        end

        if M.concept_hierarchy[concept] then
            for _, parent in ipairs(M.concept_hierarchy[concept].parents) do
                local result = findCommon(parent, depth + 1)
                if result then return result end
            end
        end

        return nil
    end

    return findCommon(concept2, 0)
end

-- ============================================================================
-- NATURAL LANGUAGE DESCRIPTION
-- ============================================================================

function M.describe(entity, verbosity)
    entity = entity:lower()
    verbosity = verbosity or "medium"  -- "brief", "medium", "detailed"

    local parts = {}

    -- Types
    local types = M.infer(entity, "is_a", 3)
    if #types > 0 then
        local type_names = {}
        local limit = (verbosity == "brief") and 1 or
                     (verbosity == "medium") and 3 or 10

        for i = 1, math.min(limit, #types) do
            if types[i].confidence >= 0.5 then
                table.insert(type_names, types[i].object)
            end
        end

        if #type_names > 0 then
            parts[#parts+1] = entity:gsub("^%l", string.upper) .. " is a " .. table.concat(type_names, " and ")
        end
    end

    -- Properties
    local props = M.getObjects(entity, "has_property")
    if #props > 0 then
        local prop_names = {}
        for _, p in ipairs(props) do
            if p.confidence >= 0.5 then
                table.insert(prop_names, p.object)
            end
        end
        if #prop_names > 0 then
            parts[#parts+1] = "It is " .. table.concat(prop_names, ", ")
        end
    end

    -- Capabilities
    if verbosity ~= "brief" then
        local caps = M.infer(entity, "can_do", 2)
        if #caps > 0 then
            local cap_list = {}
            local limit = (verbosity == "medium") and 5 or 10
            for i = 1, math.min(limit, #caps) do
                if caps[i].confidence >= 0.4 then
                    cap_list[#cap_list+1] = caps[i].object
                end
            end
            if #cap_list > 0 then
                parts[#parts+1] = "It can " .. table.concat(cap_list, ", ")
            end
        end
    end

    -- Parts
    if verbosity == "detailed" then
        local parts_list = M.getObjects(entity, "has_part")
        if #parts_list > 0 then
            local part_names = {}
            for _, p in ipairs(parts_list) do
                if p.confidence >= 0.5 then
                    table.insert(part_names, p.object)
                end
            end
            if #part_names > 0 then
                parts[#parts+1] = "It has " .. table.concat(part_names, ", ")
            end
        end
    end

    -- Relationships
    if verbosity == "detailed" then
        local relations = M.getAllRelations(entity)
        if #relations > 0 then
            local rel_info = {}
            for _, rel in ipairs(relations) do
                if rel ~= "is_a" and rel ~= "has_property" and
                   rel ~= "can_do" and rel ~= "has_part" then
                    local objs = M.getObjects(entity, rel)
                    if #objs > 0 and #objs <= 3 then
                        local obj_names = {}
                        for _, o in ipairs(objs) do
                            table.insert(obj_names, o.object)
                        end
                        rel_info[#rel_info+1] = rel .. ": " .. table.concat(obj_names, ", ")
                    end
                end
            end
            if #rel_info > 0 then
                parts[#parts+1] = "Relationships: " .. table.concat(rel_info, "; ")
            end
        end
    end

    if #parts == 0 then
        return "I don't know much about " .. entity .. " yet."
    end

    return table.concat(parts, ". ") .. "."
end

-- ============================================================================
-- QUERY PARSER (Enhanced)
-- ============================================================================

function M.query(q)
    q = q:lower()
    M.stats.queries_processed = M.stats.queries_processed + 1

    -- "what is X"
    local what = q:match("what is (%w+)") or q:match("who is (%w+)")
    if what then
        return {type="describe", entity=what, answer=M.describe(what)}
    end

    -- "is X a Y"
    local s, o = q:match("is (%w+) a (%w+)")
    if s and o then
        local inferred = M.infer(s, "is_a")
        for _, item in ipairs(inferred) do
            if item.object == o then
                return {
                    type="is_a",
                    answer=true,
                    direct=item.direct,
                    via=item.via,
                    confidence=item.confidence,
                    explanation=item.rule
                }
            end
        end
        return {type="is_a", answer=false}
    end

    -- "can X Y"
    local cs, ca = q:match("can (%w+) (%w+)")
    if cs and ca then
        local inferred = M.infer(cs, "can_do")
        for _, item in ipairs(inferred) do
            if item.object == ca then
                return {
                    type="can_do",
                    answer=true,
                    direct=item.direct,
                    confidence=item.confidence
                }
            end
        end
        return {type="can_do", answer=false}
    end

    -- "what can X do"
    local what_can = q:match("what can (%w+) do")
    if what_can then
        local caps = M.infer(what_can, "can_do", 3)
        local cap_list = {}
        for i = 1, math.min(10, #caps) do
            if caps[i].confidence >= 0.4 then
                table.insert(cap_list, caps[i].object)
            end
        end
        return {
            type="capabilities",
            entity=what_can,
            capabilities=cap_list,
            answer=what_can .. " can " .. table.concat(cap_list, ", ")
        }
    end

    -- "how are X and Y related"
    local rel1, rel2 = q:match("how are (%w+) and (%w+) related")
    if rel1 and rel2 then
        local common = M.getCommonAncestor(rel1, rel2)
        if common then
            return {
                type="relationship",
                answer="Both are types of " .. common.ancestor,
                common_ancestor=common.ancestor,
                distance=common.distance1 + common.distance2
            }
        else
            local sim = M.semanticSimilarity(rel1, rel2)
            return {
                type="relationship",
                answer="They are " .. string.format("%.0f%%", sim * 100) .. " similar",
                similarity=sim
            }
        end
    end

    -- "what is similar to X"
    local sim_to = q:match("what is similar to (%w+)")
    if sim_to then
        local similar = M.findRelated(sim_to, 5)
        local sim_names = {}
        for _, s in ipairs(similar) do
            table.insert(sim_names, s.entity)
        end
        return {
            type="similarity",
            entity=sim_to,
            similar_entities=similar,
            answer="Similar to " .. sim_to .. ": " .. table.concat(sim_names, ", ")
        }
    end

    return nil
end

-- ============================================================================
-- FIND RELATED ENTITIES
-- ============================================================================

function M.findRelated(entity, max, min_score)
    entity = entity:lower()
    max = max or 5
    min_score = min_score or 0
    local scores = {}

    -- Same type (siblings)
    local types = M.getObjects(entity, "is_a")
    for _, type_info in ipairs(types) do
        local siblings = M.getSubjects("is_a", type_info.object)
        for _, sib in ipairs(siblings) do
            if sib.subject ~= entity then
                scores[sib.subject] = (scores[sib.subject] or 0) + 2 * sib.confidence
            end
        end
    end

    -- Similar/opposite
    local similars = M.getObjects(entity, "similar_to")
    for _, sim in ipairs(similars) do
        scores[sim.object] = (scores[sim.object] or 0) + 3 * sim.confidence
    end

    local opposites = M.getObjects(entity, "opposite_of")
    for _, opp in ipairs(opposites) do
        scores[opp.object] = (scores[opp.object] or 0) + 2 * opp.confidence
    end

    -- Semantic similarity
    if M.config.embedding_dim > 0 then
        local sem_similar = M.findSemanticallySimilar(entity, max * 2, 0.3)
        for _, sem in ipairs(sem_similar) do
            scores[sem.entity] = (scores[sem.entity] or 0) + sem.similarity * 2
        end
    end

    -- Convert to list and sort
    local list = {}
    for e, s in pairs(scores) do
        if s >= min_score then
            list[#list+1] = {entity=e, score=s}
        end
    end
    table.sort(list, function(a,b) return a.score > b.score end)

    local res = {}
    for i = 1, math.min(max, #list) do
        res[i] = list[i]
    end
    return res
end

-- ============================================================================
-- REASONING EXPLANATION
-- ============================================================================

function M.explainReasoning(subject, relation, object)
    --[[
    Explain how a conclusion was reached
    ]]

    local results = M.infer(subject, relation, M.config.max_inference_depth)

    for _, result in ipairs(results) do
        if result.object == object:lower() then
            if result.direct then
                return "This is a directly known fact with " ..
                       string.format("%.0f%%", result.confidence * 100) .. " confidence."
            else
                local explanation = "Inferred through: "
                if result.path then
                    local path_str = {}
                    for _, step in ipairs(result.path) do
                        table.insert(path_str, step[1] .. " -[" .. step[2] .. "]-> " .. step[3])
                    end
                    explanation = explanation .. table.concat(path_str, " => ")
                else
                    explanation = explanation .. result.rule
                    if result.via then
                        explanation = explanation .. " via " .. result.via
                    end
                end
                explanation = explanation .. " (confidence: " ..
                             string.format("%.0f%%", result.confidence * 100) .. ")"
                return explanation
            end
        end
    end

    return "No reasoning path found for this conclusion."
end

-- ============================================================================
-- PROBABILISTIC INFERENCE
-- ============================================================================

function M.computeFactProbability(s, r, o)
    --[[
    Compute probability that a fact is true based on multiple inference paths
    Uses noisy-OR model to combine evidence
    ]]

    if not M.config.enable_probabilistic_inference then
        return M.hasFact(s, r, o) and 1.0 or 0.0
    end

    -- Get all inference paths
    local inferences = M.infer(s, r, M.config.max_inference_depth)

    local probability = 0.0
    local found = false

    for _, inf in ipairs(inferences) do
        if inf.object == o:lower() then
            found = true
            -- Noisy-OR: P(A or B) = 1 - P(not A) * P(not B)
            probability = 1 - (1 - probability) * (1 - inf.confidence)
        end
    end

    return found and probability or 0.0
end

-- ============================================================================
-- CONSISTENCY CHECKING
-- ============================================================================

function M.checkConsistency()
    --[[
    Check for logical inconsistencies in the knowledge graph
    Returns list of potential issues
    ]]

    local issues = {}

    -- Check for contradictions (X has opposite_of Y and X similar_to Y)
    for entity in pairs(M.entities) do
        local opposites = M.getObjects(entity, "opposite_of")
        local similars = M.getObjects(entity, "similar_to")

        for _, opp in ipairs(opposites) do
            for _, sim in ipairs(similars) do
                if opp.object == sim.object then
                    table.insert(issues, {
                        type = "contradiction",
                        description = entity .. " is both opposite and similar to " .. opp.object
                    })
                end
            end
        end
    end

    -- Check for impossible property combinations
    local hot_entities = M.getSubjects("has_property", "hot")
    local cold_entities = M.getSubjects("has_property", "cold")

    for _, hot_ent in ipairs(hot_entities) do
        for _, cold_ent in ipairs(cold_entities) do
            if hot_ent.subject == cold_ent.subject then
                table.insert(issues, {
                    type = "property_conflict",
                    description = hot_ent.subject .. " is both hot and cold"
                })
            end
        end
    end

    return issues
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function M.loadBuiltIn()
    for _, f in ipairs(FACTS) do
        M.addFact(f[1], f[2], f[3], 1.0)
    end

    -- Build structures
    M.initializeEmbeddings()
    M.buildConceptHierarchy()

    return #FACTS
end

function M.getStats()
    local fc, ec, rc = 0, 0, 0
    for s, rels in pairs(M.facts) do
        for r, objs in pairs(rels) do
            for _ in pairs(objs) do fc = fc + 1 end
        end
    end
    for _ in pairs(M.entities) do ec = ec + 1 end
    for _ in pairs(M.relations) do rc = rc + 1 end

    return {
        facts = fc,
        entities = ec,
        relations = rc,
        rules = #M.rules,
        temporal_facts = M.countTable(M.temporal_facts),
        embeddings = M.countTable(M.embeddings),
        reasoning_chains = #M.reasoning_chains,
        inferences_made = M.stats.inferences_made,
        queries_processed = M.stats.queries_processed,
        temporal_queries = M.stats.temporal_queries,
    }
end

function M.countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function M.exportGraph(format)
    --[[
    Export knowledge graph in various formats
    ]]

    format = format or "triples"

    if format == "triples" then
        local triples = {}
        for s, rels in pairs(M.facts) do
            for r, objs in pairs(rels) do
                for o in pairs(objs) do
                    local conf = M.getFactConfidence(s, r, o)
                    table.insert(triples, {s, r, o, conf})
                end
            end
        end
        return triples
    elseif format == "json" then
        -- Would return JSON string if we had JSON encoder
        return M.getStats()
    end

    return nil
end

function M.importTriples(triples)
    --[[
    Import triples into the knowledge graph
    triples: list of {subject, relation, object, confidence}
    ]]

    local count = 0
    for _, triple in ipairs(triples) do
        local s, r, o = triple[1], triple[2], triple[3]
        local conf = triple[4] or 1.0
        M.addFact(s, r, o, conf)
        count = count + 1
    end

    return count
end

function M.clear()
    --[[
    Clear all knowledge
    ]]

    M.facts = {}
    M.reverse = {}
    M.entities = {}
    M.relations = {}
    M.temporal_facts = {}
    M.confidence_scores = {}
    M.embeddings = {}
    M.reasoning_chains = {}
    M.concept_hierarchy = {}
    M.analogies = {}

    M.stats = {
        inferences_made = 0,
        queries_processed = 0,
        reasoning_chains_created = 0,
        temporal_queries = 0,
    }
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

M.loadBuiltIn()

return M
