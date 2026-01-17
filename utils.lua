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

-- ============================================================================
-- ADVANCED TEXT ANALYSIS
-- ============================================================================

-- Detect writing style
function M.detectWritingStyle(text)
    if not text or #text < 10 then return "minimal" end
    
    local wordCount = #M.tokenize(text)
    local sentenceCount = select(2, text:gsub("[.!?]+", "")) + 1
    local avgWordsPerSentence = wordCount / sentenceCount
    
    -- Count complex words (more than 3 syllables - rough approximation)
    local complexWords = 0
    for word in text:gmatch("%w+") do
        local vowelCount = select(2, word:lower():gsub("[aeiou]+", ""))
        if vowelCount > 3 then
            complexWords = complexWords + 1
        end
    end
    
    local complexityRatio = complexWords / wordCount
    
    if avgWordsPerSentence > 20 or complexityRatio > 0.3 then
        return "elaborate"
    elseif avgWordsPerSentence > 12 or complexityRatio > 0.2 then
        return "moderate"
    elseif avgWordsPerSentence > 7 then
        return "casual"
    else
        return "concise"
    end
end

-- Detect if message is a story
function M.detectStory(text)
    if not text then return false end
    
    local storyIndicators = {
        beginnings = {"so i", "yesterday", "last week", "one time", "once i", "there was", "remember when"},
        middles = {"and then", "but then", "suddenly", "after that", "next"},
        details = {"because", "which", "where", "when", "who", "while"},
    }
    
    local lower = text:lower()
    local indicatorCount = 0
    
    for category, indicators in pairs(storyIndicators) do
        for _, indicator in ipairs(indicators) do
            if lower:find(indicator, 1, true) then
                indicatorCount = indicatorCount + 1
            end
        end
    end
    
    return indicatorCount >= 2
end

-- Detect communication style
function M.detectCommunicationStyle(messages)
    -- Analyze last few messages to determine style
    if not messages or #messages < 3 then return "balanced" end
    
    local totalLength = 0
    local questionCount = 0
    local exclamationCount = 0
    local statementCount = 0
    
    for _, msg in ipairs(messages) do
        totalLength = totalLength + #msg
        if msg:find("?") then questionCount = questionCount + 1 end
        if msg:find("!") then exclamationCount = exclamationCount + 1 end
        if msg:find("%.") then statementCount = statementCount + 1 end
    end
    
    local avgLength = totalLength / #messages
    
    if questionCount > #messages * 0.6 then
        return "inquisitive"
    elseif exclamationCount > #messages * 0.5 then
        return "enthusiastic"
    elseif avgLength > 150 then
        return "detailed"
    elseif avgLength < 30 then
        return "brief"
    else
        return "balanced"
    end
end

-- ============================================================================
-- CONVERSATION QUALITY METRICS
-- ============================================================================

-- Calculate conversation depth
function M.getConversationDepth(messages)
    if not messages or #messages == 0 then return 0 end
    
    local depthScore = 0
    local deepTopics = {
        "feel", "think", "believe", "understand", "realize", "learn",
        "grow", "change", "wonder", "question", "meaning", "purpose",
        "value", "important", "matter", "care", "love", "fear", "hope"
    }
    
    for _, msg in ipairs(messages) do
        local lower = msg:lower()
        for _, topic in ipairs(deepTopics) do
            if lower:find(topic) then
                depthScore = depthScore + 1
            end
        end
    end
    
    return depthScore / #messages
end

-- Detect engagement level
function M.detectEngagement(message)
    if not message then return "low" end
    
    local length = #message
    local hasQuestion = message:find("?") ~= nil
    local hasExclamation = message:find("!") ~= nil
    local wordCount = #M.tokenize(message)
    
    local engagementScore = 0
    
    if length > 50 then engagementScore = engagementScore + 2 end
    if hasQuestion then engagementScore = engagementScore + 1 end
    if hasExclamation then engagementScore = engagementScore + 1 end
    if wordCount > 10 then engagementScore = engagementScore + 1 end
    
    if engagementScore >= 4 then
        return "high"
    elseif engagementScore >= 2 then
        return "medium"
    else
        return "low"
    end
end

-- ============================================================================
-- RESPONSE MATCHING UTILITIES
-- ============================================================================

-- Match user's tone
function M.matchTone(userMessage)
    if not userMessage then return "neutral" end
    
    local lower = userMessage:lower()
    
    -- Check for formal tone
    local formalWords = {"sir", "madam", "please", "kindly", "would you", "could you"}
    for _, word in ipairs(formalWords) do
        if lower:find(word) then
            return "formal"
        end
    end
    
    -- Check for casual/slang
    local casualWords = {"yeah", "nah", "gonna", "wanna", "dunno", "kinda", "sorta", "lol", "omg"}
    local casualCount = 0
    for _, word in ipairs(casualWords) do
        if lower:find(word) then
            casualCount = casualCount + 1
        end
    end
    
    if casualCount >= 2 then
        return "casual"
    end
    
    -- Check for enthusiastic
    local exclamations = select(2, userMessage:gsub("!", ""))
    if exclamations >= 2 then
        return "enthusiastic"
    end
    
    -- Check for serious/contemplative
    local seriousWords = {"honestly", "seriously", "really", "actually", "truth"}
    for _, word in ipairs(seriousWords) do
        if lower:find(word) then
            return "serious"
        end
    end
    
    return "neutral"
end

-- ============================================================================
-- CONVERSATION TOPIC EXTRACTION
-- ============================================================================

-- Extract main topics from text
function M.extractTopics(text)
    if not text then return {} end
    
    local topicCategories = {
        emotions = {"feel", "emotion", "happy", "sad", "angry", "scared", "excited", "anxious", "worried"},
        work = {"work", "job", "career", "boss", "coworker", "project", "task", "deadline", "meeting"},
        relationships = {"friend", "family", "partner", "relationship", "love", "trust", "conflict", "connection"},
        health = {"health", "sick", "tired", "energy", "sleep", "exercise", "stress", "pain"},
        goals = {"goal", "dream", "ambition", "want", "wish", "hope", "plan", "achieve", "success"},
        challenges = {"problem", "difficult", "hard", "struggle", "issue", "trouble", "challenge", "obstacle"},
        learning = {"learn", "study", "understand", "knowledge", "skill", "practice", "improve", "grow"}
    }
    
    local foundTopics = {}
    local lower = text:lower()
    
    for category, keywords in pairs(topicCategories) do
        for _, keyword in ipairs(keywords) do
            if lower:find(keyword) then
                if not M.tableContains(foundTopics, category) then
                    table.insert(foundTopics, category)
                end
                break
            end
        end
    end
    
    return foundTopics
end

-- ============================================================================
-- PERSONALIZATION UTILITIES
-- ============================================================================

-- Detect user's preferred communication pace
function M.detectPreferredPace(responseTime)
    if not responseTime then return "normal" end
    
    if responseTime < 5 then
        return "fast" -- User responds quickly
    elseif responseTime > 30 then
        return "slow" -- User takes time to respond
    else
        return "normal"
    end
end

-- Suggest response length based on user's messages
function M.suggestResponseLength(userMessages)
    if not userMessages or #userMessages == 0 then return "medium" end
    
    local totalLength = 0
    for _, msg in ipairs(userMessages) do
        totalLength = totalLength + #msg
    end
    
    local avgLength = totalLength / #userMessages
    
    if avgLength < 30 then
        return "short" -- Match user's brevity
    elseif avgLength > 150 then
        return "long" -- Match user's detail
    else
        return "medium"
    end
end

-- ============================================================================
-- EMPATHY UTILITIES
-- ============================================================================

-- Detect vulnerability in message
function M.detectVulnerability(message)
    if not message then return false end
    
    local vulnerabilityIndicators = {
        "struggling", "difficult", "hard", "can't", "don't know",
        "worried", "scared", "afraid", "anxious", "overwhelmed",
        "lonely", "alone", "help", "lost", "confused", "unsure"
    }
    
    local lower = message:lower()
    for _, indicator in ipairs(vulnerabilityIndicators) do
        if lower:find(indicator) then
            return true
        end
    end
    
    return false
end

-- Detect celebration/success in message
function M.detectSuccess(message)
    if not message then return false end
    
    local successIndicators = {
        "finally", "accomplished", "achieved", "succeeded", "won",
        "finished", "completed", "did it", "made it", "proud",
        "excited", "happy", "great news", "good news", "success"
    }
    
    local lower = message:lower()
    for _, indicator in ipairs(successIndicators) do
        if lower:find(indicator) then
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- INTELLIGENT PARAPHRASING
-- ============================================================================

-- Paraphrase common phrases
M.paraphrases = {
    ["how are you"] = {"How's it going?", "How are things?", "How have you been?", "What's up?"},
    ["thank you"] = {"Thanks!", "I appreciate it!", "Much appreciated!", "That means a lot!"},
    ["i understand"] = {"I get it.", "I see what you mean.", "That makes sense.", "I follow you."},
    ["i agree"] = {"Exactly.", "Totally.", "I'm with you on that.", "You're right."},
    ["that's interesting"] = {"That's fascinating!", "How intriguing!", "That's noteworthy!", "That caught my attention!"},
    ["tell me more"] = {"I'd love to hear more.", "Go on...", "What else?", "Continue..."},
}

-- Get paraphrase
function M.getParaphrase(phrase)
    local lower = phrase:lower()
    
    for original, alternatives in pairs(M.paraphrases) do
        if lower:find(original, 1, true) then
            return alternatives[math.random(#alternatives)]
        end
    end
    
    return phrase
end

-- ============================================================================
-- TEXT VARIATION
-- ============================================================================

-- Add variety to responses
function M.addVariety(baseResponse)
    if not baseResponse then return "" end
    
    local starters = {"", "Well, ", "So, ", "Actually, ", "You know, ", "I think ", "Honestly, "}
    local enders = {"", "!", ".", " :)", " 😊"}
    
    if math.random() < 0.3 then
        local starter = starters[math.random(#starters)]
        baseResponse = starter .. baseResponse
    end
    
    if math.random() < 0.2 then
        local ender = enders[math.random(#enders)]
        baseResponse = baseResponse .. ender
    end
    
    return baseResponse
end

-- ============================================================================
-- GRAPH ALGORITHMS & ADVANCED MATH
-- ============================================================================

-- Graph data structure
M.Graph = {}
M.Graph.__index = M.Graph

function M.Graph.new(directed)
    return setmetatable({
        vertices = {},
        edges = {},
        directed = directed or false,
    }, M.Graph)
end

function M.Graph:addVertex(id, data)
    if not self.vertices[id] then
        self.vertices[id] = {
            id = id,
            data = data or {},
            neighbors = {},
        }
        return true
    end
    return false
end

function M.Graph:addEdge(from, to, weight)
    if not self.vertices[from] or not self.vertices[to] then
        return false
    end
    
    weight = weight or 1
    
    if not self.edges[from] then
        self.edges[from] = {}
    end
    
    self.edges[from][to] = weight
    table.insert(self.vertices[from].neighbors, to)
    
    if not self.directed then
        if not self.edges[to] then
            self.edges[to] = {}
        end
        self.edges[to][from] = weight
        table.insert(self.vertices[to].neighbors, from)
    end
    
    return true
end

function M.Graph:getNeighbors(id)
    if self.vertices[id] then
        return self.vertices[id].neighbors
    end
    return {}
end

function M.Graph:getWeight(from, to)
    if self.edges[from] and self.edges[from][to] then
        return self.edges[from][to]
    end
    return nil
end

-- BFS pathfinding
function M.Graph:findPath(start, goal)
    if not self.vertices[start] or not self.vertices[goal] then
        return nil
    end
    
    local queue = {start}
    local visited = {[start] = true}
    local parent = {}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        if current == goal then
            local path = {}
            while current do
                table.insert(path, 1, current)
                current = parent[current]
            end
            return path
        end
        
        for _, neighbor in ipairs(self:getNeighbors(current)) do
            if not visited[neighbor] then
                visited[neighbor] = true
                parent[neighbor] = current
                table.insert(queue, neighbor)
            end
        end
    end
    
    return nil
end

-- Dijkstra's shortest path
function M.Graph:shortestPath(start, goal)
    if not self.vertices[start] or not self.vertices[goal] then
        return nil, nil
    end
    
    local dist = {}
    local prev = {}
    local unvisited = {}
    
    for id, _ in pairs(self.vertices) do
        dist[id] = math.huge
        unvisited[id] = true
    end
    dist[start] = 0
    
    while next(unvisited) do
        local minDist = math.huge
        local current = nil
        
        for id, _ in pairs(unvisited) do
            if dist[id] < minDist then
                minDist = dist[id]
                current = id
            end
        end
        
        if current == goal then
            local path = {}
            while current do
                table.insert(path, 1, current)
                current = prev[current]
            end
            return path, dist[goal]
        end
        
        unvisited[current] = nil
        
        for _, neighbor in ipairs(self:getNeighbors(current)) do
            if unvisited[neighbor] then
                local alt = dist[current] + self:getWeight(current, neighbor)
                if alt < dist[neighbor] then
                    dist[neighbor] = alt
                    prev[neighbor] = current
                end
            end
        end
    end
    
    return nil, nil
end

-- Check if graph has cycles
function M.Graph:hasCycle()
    local visited = {}
    local recStack = {}
    
    local function detectCycle(node, parent)
        visited[node] = true
        recStack[node] = true
        
        for _, neighbor in ipairs(self:getNeighbors(node)) do
            if not visited[neighbor] then
                if detectCycle(neighbor, node) then
                    return true
                end
            elseif recStack[neighbor] and neighbor ~= parent then
                return true
            end
        end
        
        recStack[node] = false
        return false
    end
    
    for id, _ in pairs(self.vertices) do
        if not visited[id] then
            if detectCycle(id, nil) then
                return true
            end
        end
    end
    
    return false
end

-- Advanced math functions
M.math = {}

-- Calculate factorial
function M.math.factorial(n)
    if n <= 1 then return 1 end
    return n * M.math.factorial(n - 1)
end

-- Calculate fibonacci
function M.math.fibonacci(n)
    if n <= 1 then return n end
    local a, b = 0, 1
    for i = 2, n do
        a, b = b, a + b
    end
    return b
end

-- Calculate GCD (greatest common divisor)
function M.math.gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

-- Calculate LCM (least common multiple)
function M.math.lcm(a, b)
    return (a * b) / M.math.gcd(a, b)
end

-- Check if number is prime
function M.math.isPrime(n)
    if n < 2 then return false end
    if n == 2 then return true end
    if n % 2 == 0 then return false end
    
    for i = 3, math.sqrt(n), 2 do
        if n % i == 0 then
            return false
        end
    end
    return true
end

-- Get prime factors
function M.math.primeFactors(n)
    local factors = {}
    local d = 2
    
    while n > 1 do
        while n % d == 0 do
            table.insert(factors, d)
            n = n / d
        end
        d = d + 1
        if d * d > n then
            if n > 1 then
                table.insert(factors, n)
            end
            break
        end
    end
    
    return factors
end

-- Calculate power efficiently
function M.math.power(base, exp)
    if exp == 0 then return 1 end
    if exp == 1 then return base end
    
    local half = M.math.power(base, math.floor(exp / 2))
    
    if exp % 2 == 0 then
        return half * half
    else
        return base * half * half
    end
end

-- Matrix operations
M.math.matrix = {}

-- Matrix multiplication
function M.math.matrix.multiply(a, b)
    local rows_a, cols_a = #a, #a[1]
    local rows_b, cols_b = #b, #b[1]
    
    if cols_a ~= rows_b then
        return nil, "Incompatible dimensions"
    end
    
    local result = {}
    for i = 1, rows_a do
        result[i] = {}
        for j = 1, cols_b do
            result[i][j] = 0
            for k = 1, cols_a do
                result[i][j] = result[i][j] + a[i][k] * b[k][j]
            end
        end
    end
    
    return result
end

-- Matrix transpose
function M.math.matrix.transpose(m)
    local result = {}
    for i = 1, #m[1] do
        result[i] = {}
        for j = 1, #m do
            result[i][j] = m[j][i]
        end
    end
    return result
end

return M
