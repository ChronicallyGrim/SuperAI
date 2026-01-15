-- Module: utils.lua
-- Advanced NLP utilities and response libraries with semantic understanding

local M = {}

-- ============================================================================
-- ADVANCED RESPONSE LIBRARIES - Contextual and varied
-- ============================================================================

M.library = {
    greetings = {
        casual = {
            "Hey! What's up?",
            "Hi there! How's it going?",
            "Hey! Good to see you!",
            "Yo! What brings you here?",
            "Sup! What's on your mind?",
        },
        formal = {
            "Good day! How may I assist you?",
            "Hello. What would you like to discuss?",
            "Greetings. How can I help you today?",
        },
        warm = {
            "Hey there! I'm really glad you're here!",
            "Hi! It's great to chat with you again!",
            "Hello! I was hoping we'd get to talk!",
            "Hey! I'm excited to hear from you!",
        },
        returning = {
            "Welcome back! How have you been?",
            "Hey again! What's new with you?",
            "Good to see you again! What's going on?",
        }
    },
    
    acknowledgments = {
        brief = {"I see.", "Got it.", "Right.", "Okay.", "Mm-hmm."},
        understanding = {
            "I see what you mean.",
            "That makes sense to me.",
            "I understand where you're coming from.",
            "I get that.",
            "That's a good point.",
        },
        thoughtful = {
            "Interesting perspective.",
            "I hadn't thought of it that way.",
            "That's worth considering.",
            "You've given me something to think about.",
        },
        validating = {
            "That's completely valid.",
            "Your feelings make sense.",
            "I can see why you'd think that.",
            "That's a reasonable way to look at it.",
        }
    },
    
    curiosity = {
        open = {
            "Tell me more about that.",
            "I'd love to hear more.",
            "What else can you share about that?",
            "Can you elaborate on that?",
        },
        specific = {
            "What made you think of that?",
            "How did that make you feel?",
            "What happened next?",
            "What was going through your mind?",
            "How did you end up in that situation?",
        },
        clarifying = {
            "What do you mean by that exactly?",
            "Could you explain that a bit more?",
            "I want to make sure I understand - what do you mean?",
            "Help me understand what you're saying.",
        },
        reflective = {
            "Why do you think that happened?",
            "What do you think that means?",
            "How do you feel about that looking back?",
            "What did you learn from that?",
        }
    },
    
    empathy = {
        supportive = {
            "I'm here for you.",
            "That sounds really tough.",
            "I can imagine how that feels.",
            "You're not alone in feeling this way.",
        },
        validating = {
            "Your feelings are completely valid.",
            "It's okay to feel that way.",
            "Anyone would feel the same in your situation.",
            "That's a natural response.",
        },
        encouraging = {
            "You're handling this really well.",
            "It takes courage to talk about this.",
            "You're stronger than you think.",
            "You've got this.",
        }
    },
    
    positive_reactions = {
        enthusiastic = {
            "That's amazing!",
            "Wow, that's fantastic!",
            "That's incredible!",
            "I'm so excited for you!",
        },
        warm = {
            "That's wonderful!",
            "I'm really happy to hear that!",
            "That's great news!",
            "That sounds lovely!",
        },
        measured = {
            "That's good to hear.",
            "Nice!",
            "That's positive.",
            "Glad that worked out.",
        }
    },
    
    transitions = {
        smooth = {"By the way,", "Also,", "Additionally,", "On that note,"},
        topical = {"Speaking of which,", "That reminds me,", "Related to that,"},
        casual = {"Oh, and", "Plus,", "Another thing,"},
        contrasting = {"On the other hand,", "However,", "Although,", "That said,"}
    },
    
    fillers = {
        thoughtful = {"Hmm...", "Let me think...", "Well...", "You know..."},
        hesitant = {"Uh...", "Um...", "Er..."},
        emphatic = {"Actually...", "Honestly...", "Frankly...", "To be fair..."}
    },
    
    reflections = {
        "So what you're saying is...",
        "It sounds like...",
        "What I'm hearing is...",
        "If I understand correctly...",
        "Let me see if I've got this right...",
    }
}

-- ============================================================================
-- ADVANCED NLP UTILITIES
-- ============================================================================

-- Enhanced stopword list for better keyword extraction
local stopWords = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "was", "are", "were", "be", "been",
    "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "may", "might", "can", "i", "you", "he", "she", "it", "we",
    "they", "this", "that", "these", "those", "my", "your", "his", "her",
    "its", "our", "their", "am", "been", "being", "having", "doing",
    "so", "than", "too", "very", "just", "what", "which", "who", "when",
    "where", "why", "how", "all", "each", "every", "both", "few", "more",
    "most", "some", "such", "no", "nor", "not", "only", "own", "same",
    "then", "there", "theirs", "them"
}

-- Normalize text with advanced cleaning
function M.normalize(text)
    if not text then return "" end
    
    text = text:lower()
    -- Replace multiple spaces with single space
    text = text:gsub("%s+", " ")
    -- Remove special characters but keep apostrophes for contractions
    text = text:gsub("[^%w%s']", "")
    -- Trim whitespace
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    
    return text
end

-- Extract keywords with TF-IDF-like weighting
function M.extractKeywords(text)
    if not text then return {} end
    
    local normalized = M.normalize(text)
    local words = {}
    local wordFreq = {}
    
    -- Count word frequencies
    for word in normalized:gmatch("%w+") do
        if #word > 2 and not M.tableContains(stopWords, word) then
            wordFreq[word] = (wordFreq[word] or 0) + 1
            if not M.tableContains(words, word) then
                table.insert(words, word)
            end
        end
    end
    
    -- Sort by frequency (most important first)
    table.sort(words, function(a, b)
        return wordFreq[a] > wordFreq[b]
    end)
    
    return words
end

-- Extract noun phrases (simple version)
function M.extractPhrases(text)
    if not text then return {} end
    
    local phrases = {}
    local lower = text:lower()
    
    -- Pattern: adjective + noun patterns
    for phrase in lower:gmatch("([%w]+%s+[%w]+)") do
        local words = {}
        for word in phrase:gmatch("%w+") do
            table.insert(words, word)
        end
        
        if #words == 2 and not M.tableContains(stopWords, words[1]) then
            table.insert(phrases, phrase)
        end
    end
    
    return phrases
end

-- Calculate semantic similarity between two strings
function M.similarity(str1, str2)
    if not str1 or not str2 then return 0 end
    
    local kw1 = M.extractKeywords(str1)
    local kw2 = M.extractKeywords(str2)
    
    if #kw1 == 0 or #kw2 == 0 then return 0 end
    
    -- Calculate Jaccard similarity
    local matches = 0
    local union = {}
    
    -- Add all words from both sets to union
    for _, word in ipairs(kw1) do
        union[word] = true
    end
    for _, word in ipairs(kw2) do
        union[word] = true
    end
    
    -- Count matches (intersection)
    for _, word1 in ipairs(kw1) do
        for _, word2 in ipairs(kw2) do
            if word1 == word2 then
                matches = matches + 1
                break
            end
        end
    end
    
    -- Count union size
    local unionSize = 0
    for _ in pairs(union) do
        unionSize = unionSize + 1
    end
    
    return matches / math.max(unionSize, 1)
end

-- Calculate Levenshtein distance for typo tolerance
function M.levenshteinDistance(s1, s2)
    if not s1 or not s2 then return math.huge end
    if s1 == s2 then return 0 end
    
    local len1, len2 = #s1, #s2
    if len1 == 0 then return len2 end
    if len2 == 0 then return len1 end
    
    local matrix = {}
    
    for i = 0, len1 do
        matrix[i] = {[0] = i}
    end
    
    for j = 0, len2 do
        matrix[0][j] = j
    end
    
    for i = 1, len1 do
        for j = 1, len2 do
            local cost = (s1:sub(i, i) == s2:sub(j, j)) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i-1][j] + 1,      -- deletion
                matrix[i][j-1] + 1,      -- insertion
                matrix[i-1][j-1] + cost  -- substitution
            )
        end
    end
    
    return matrix[len1][len2]
end

-- Check if text is similar to any in a list (fuzzy matching)
function M.fuzzyMatch(text, candidates, threshold)
    threshold = threshold or 2
    
    for _, candidate in ipairs(candidates) do
        if M.levenshteinDistance(text:lower(), candidate:lower()) <= threshold then
            return true, candidate
        end
    end
    
    return false, nil
end

-- Get sentiment intensity (more nuanced than just positive/negative)
function M.getSentimentIntensity(text)
    if not text then return 0 end
    
    local intensifiers = {
        very = 1.5, really = 1.5, extremely = 2.0, incredibly = 2.0,
        totally = 1.5, absolutely = 2.0, completely = 2.0,
        somewhat = 0.5, slightly = 0.5, kinda = 0.5, sorta = 0.5,
        barely = 0.3, hardly = 0.3
    }
    
    local negations = {"not", "no", "never", "nothing", "nobody", "nowhere", "neither", "none"}
    
    local words = {}
    for word in text:lower():gmatch("%w+") do
        table.insert(words, word)
    end
    
    local intensity = 1.0
    local negated = false
    
    for i, word in ipairs(words) do
        -- Check for intensifiers
        if intensifiers[word] then
            intensity = intensity * intensifiers[word]
        end
        
        -- Check for negations
        if M.tableContains(negations, word) then
            negated = not negated
        end
    end
    
    return negated and -intensity or intensity
end

-- Detect message complexity
function M.getComplexity(text)
    if not text then return "simple" end
    
    local wordCount = 0
    for _ in text:gmatch("%w+") do
        wordCount = wordCount + 1
    end
    
    local sentenceCount = 0
    for _ in text:gmatch("[.!?]+") do
        sentenceCount = sentenceCount + 1
    end
    
    sentenceCount = math.max(sentenceCount, 1)
    local avgWordsPerSentence = wordCount / sentenceCount
    
    if avgWordsPerSentence > 20 then return "complex" end
    if avgWordsPerSentence > 10 then return "moderate" end
    return "simple"
end

-- Get message length category
function M.getMessageLength(text)
    if not text then return "empty" end
    local len = #text
    if len == 0 then return "empty" end
    if len < 20 then return "short" end
    if len < 100 then return "medium" end
    if len < 300 then return "long" end
    return "very_long"
end

-- Detect if message is a question (enhanced)
function M.isQuestion(text)
    if not text then return false end
    
    -- Check for question mark
    if text:match("%?") then return true end
    
    local lower = text:lower()
    
    -- Question word starters
    local questionWords = {
        "what", "why", "how", "when", "where", "who", "which", "whose",
        "can", "could", "would", "should", "will", "do", "does", "did",
        "is", "are", "was", "were", "have", "has", "had", "am"
    }
    
    -- Check if starts with question word
    for _, qword in ipairs(questionWords) do
        if lower:match("^" .. qword .. "%s") or lower:match("^" .. qword .. "$") then
            return true
        end
    end
    
    return false
end

-- Detect rhetorical questions
function M.isRhetoricalQuestion(text)
    if not M.isQuestion(text) then return false end
    
    local rhetorical = {
        "obviously", "clearly", "of course", "duh", "seriously",
        "really think", "honestly", "come on"
    }
    
    local lower = text:lower()
    for _, phrase in ipairs(rhetorical) do
        if lower:find(phrase, 1, true) then
            return true
        end
    end
    
    return false
end

-- Extract time references
function M.extractTimeReferences(text)
    if not text then return {} end
    
    local timeRefs = {}
    local lower = text:lower()
    
    local timeWords = {
        past = {"yesterday", "ago", "last", "before", "earlier", "previously", "used to", "was", "were"},
        present = {"now", "today", "currently", "right now", "at the moment", "is", "are"},
        future = {"tomorrow", "will", "going to", "next", "later", "soon", "eventually", "planning"}
    }
    
    for tense, words in pairs(timeWords) do
        for _, word in ipairs(words) do
            if lower:find(word, 1, true) then
                table.insert(timeRefs, {tense = tense, word = word})
            end
        end
    end
    
    return timeRefs
end

-- Detect certainty level in statement
function M.getCertaintyLevel(text)
    if not text then return "neutral" end
    
    local lower = text:lower()
    
    local certain = {"definitely", "certainly", "absolutely", "sure", "positive", "without doubt", "clearly"}
    local uncertain = {"maybe", "perhaps", "possibly", "might", "could", "not sure", "don't know", "uncertain"}
    
    for _, word in ipairs(certain) do
        if lower:find(word, 1, true) then
            return "high"
        end
    end
    
    for _, word in ipairs(uncertain) do
        if lower:find(word, 1, true) then
            return "low"
        end
    end
    
    return "medium"
end

-- Choose random element from table
function M.choose(tbl)
    if not tbl or #tbl == 0 then return "" end
    return tbl[math.random(#tbl)]
end

-- Choose from nested table structure
function M.chooseNested(tbl, key)
    if not tbl or not key then return "" end
    local nested = tbl[key]
    if type(nested) == "table" and #nested > 0 then
        return M.choose(nested)
    elseif type(nested) == "string" then
        return nested
    end
    return ""
end

-- Check if table contains value
function M.tableContains(tbl, value)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Merge two tables
function M.mergeTables(t1, t2)
    local result = {}
    for k, v in pairs(t1 or {}) do
        result[k] = v
    end
    for k, v in pairs(t2 or {}) do
        result[k] = v
    end
    return result
end

-- Deep copy table
function M.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[M.deepCopy(orig_key)] = M.deepCopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

return M
