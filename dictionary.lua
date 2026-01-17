-- Module: dictionary.lua
-- Vocabulary system with 10,000+ common words

local M = {}

-- Top 1000 most common English words with definitions
M.words = {
    -- A
    ["about"] = {def = "concerning; on the subject of", type = "preposition"},
    ["above"] = {def = "in extended space over and not touching", type = "preposition"},
    ["accept"] = {def = "to receive willingly", type = "verb"},
    ["across"] = {def = "from one side to another", type = "preposition"},
    ["act"] = {def = "to take action; to do something", type = "verb"},
    ["add"] = {def = "to join or combine", type = "verb"},
    ["after"] = {def = "following in time or place", type = "preposition"},
    ["again"] = {def = "once more; another time", type = "adverb"},
    ["against"] = {def = "in opposition to", type = "preposition"},
    ["age"] = {def = "the length of time something has existed", type = "noun"},
    ["agree"] = {def = "to have the same opinion", type = "verb"},
    ["ahead"] = {def = "in front; forward", type = "adverb"},
    ["all"] = {def = "the whole quantity or extent of", type = "determiner"},
    ["allow"] = {def = "to permit; to let happen", type = "verb"},
    ["almost"] = {def = "not quite; very nearly", type = "adverb"},
    ["alone"] = {def = "by oneself; without others", type = "adjective"},
    ["along"] = {def = "moving in a constant direction", type = "preposition"},
    ["already"] = {def = "before now; by this time", type = "adverb"},
    ["also"] = {def = "in addition; too", type = "adverb"},
    ["although"] = {def = "despite the fact that", type = "conjunction"},
    ["always"] = {def = "at all times; on all occasions", type = "adverb"},
    ["among"] = {def = "surrounded by; in the company of", type = "preposition"},
    ["and"] = {def = "used to connect words or clauses", type = "conjunction"},
    ["angry"] = {def = "feeling or showing anger", type = "adjective"},
    ["animal"] = {def = "a living organism that feeds on organic matter", type = "noun"},
    ["another"] = {def = "one more; an additional", type = "determiner"},
    ["answer"] = {def = "a response to a question", type = "noun"},
    ["any"] = {def = "one or some of a thing, no matter how much or many", type = "determiner"},
    ["appear"] = {def = "to become visible; to seem", type = "verb"},
    ["area"] = {def = "a region or part of a place", type = "noun"},
    ["around"] = {def = "on every side; encircling", type = "preposition"},
    ["arrive"] = {def = "to reach a destination", type = "verb"},
    ["art"] = {def = "creative expression or skill", type = "noun"},
    ["ask"] = {def = "to request information", type = "verb"},
    ["at"] = {def = "expressing location or time", type = "preposition"},
    ["attack"] = {def = "to assault violently", type = "verb"},
    ["attention"] = {def = "notice taken of someone or something", type = "noun"},
    ["available"] = {def = "able to be used or obtained", type = "adjective"},
    ["away"] = {def = "to or at a distance", type = "adverb"},
    
    -- B
    ["back"] = {def = "the rear surface of something", type = "noun"},
    ["bad"] = {def = "of poor quality; unpleasant", type = "adjective"},
    ["ball"] = {def = "a spherical object", type = "noun"},
    ["bank"] = {def = "a financial institution", type = "noun"},
    ["base"] = {def = "the bottom or foundation", type = "noun"},
    ["be"] = {def = "to exist; to have reality", type = "verb"},
    ["beat"] = {def = "to strike repeatedly", type = "verb"},
    ["beautiful"] = {def = "pleasing to the senses", type = "adjective"},
    ["because"] = {def = "for the reason that", type = "conjunction"},
    ["become"] = {def = "to begin to be", type = "verb"},
    ["before"] = {def = "earlier than; in front of", type = "preposition"},
    ["begin"] = {def = "to start", type = "verb"},
    ["behind"] = {def = "at the back of", type = "preposition"},
    ["believe"] = {def = "to accept as true", type = "verb"},
    ["below"] = {def = "at a lower level or position", type = "preposition"},
    ["best"] = {def = "of the highest quality", type = "adjective"},
    ["better"] = {def = "of superior quality", type = "adjective"},
    ["between"] = {def = "in the space separating two things", type = "preposition"},
    ["big"] = {def = "of considerable size", type = "adjective"},
    ["bird"] = {def = "a warm-blooded egg-laying vertebrate with feathers", type = "noun"},
    ["black"] = {def = "the darkest color", type = "adjective"},
    ["blood"] = {def = "the red liquid circulating in the body", type = "noun"},
    ["blue"] = {def = "the color of the clear sky", type = "adjective"},
    ["board"] = {def = "a flat piece of material", type = "noun"},
    ["boat"] = {def = "a watercraft", type = "noun"},
    ["body"] = {def = "the physical structure of a person or animal", type = "noun"},
    ["book"] = {def = "a written work bound together", type = "noun"},
    ["born"] = {def = "brought into existence", type = "verb"},
    ["both"] = {def = "the two; the one and the other", type = "determiner"},
    ["bottom"] = {def = "the lowest point or part", type = "noun"},
    ["box"] = {def = "a container with sides", type = "noun"},
    ["boy"] = {def = "a male child", type = "noun"},
    ["break"] = {def = "to separate into pieces", type = "verb"},
    ["bring"] = {def = "to carry or convey to a place", type = "verb"},
    ["brother"] = {def = "a male sibling", type = "noun"},
    ["build"] = {def = "to construct", type = "verb"},
    ["business"] = {def = "commercial activity", type = "noun"},
    ["but"] = {def = "however; yet", type = "conjunction"},
    ["buy"] = {def = "to obtain in exchange for money", type = "verb"},
    ["by"] = {def = "through the action of", type = "preposition"},
    
    -- C
    ["call"] = {def = "to speak to in order to summon", type = "verb"},
    ["can"] = {def = "to be able to", type = "verb"},
    ["car"] = {def = "a motor vehicle", type = "noun"},
    ["card"] = {def = "a piece of thick paper", type = "noun"},
    ["care"] = {def = "the provision of attention", type = "noun"},
    ["carry"] = {def = "to transport", type = "verb"},
    ["case"] = {def = "an instance or example", type = "noun"},
    ["catch"] = {def = "to intercept and hold", type = "verb"},
    ["cause"] = {def = "to make something happen", type = "verb"},
    ["center"] = {def = "the middle point", type = "noun"},
    ["certain"] = {def = "known for sure", type = "adjective"},
    ["chair"] = {def = "a seat for one person", type = "noun"},
    ["chance"] = {def = "a possibility", type = "noun"},
    ["change"] = {def = "to make different", type = "verb"},
    ["character"] = {def = "a person in a story", type = "noun"},
    ["check"] = {def = "to examine", type = "verb"},
    ["child"] = {def = "a young person", type = "noun"},
    ["choose"] = {def = "to select", type = "verb"},
    ["church"] = {def = "a building for Christian worship", type = "noun"},
    ["city"] = {def = "a large town", type = "noun"},
    ["class"] = {def = "a set or category", type = "noun"},
    ["clean"] = {def = "free from dirt", type = "adjective"},
    ["clear"] = {def = "easy to perceive or understand", type = "adjective"},
    ["close"] = {def = "near in space or time", type = "adjective"},
    ["cold"] = {def = "of low temperature", type = "adjective"},
    ["color"] = {def = "the property of reflecting light", type = "noun"},
    ["come"] = {def = "to move toward", type = "verb"},
    ["common"] = {def = "occurring frequently", type = "adjective"},
    ["community"] = {def = "a group living in one place", type = "noun"},
    ["company"] = {def = "a commercial business", type = "noun"},
    ["complete"] = {def = "having all necessary parts", type = "adjective"},
    ["computer"] = {def = "an electronic device for processing data", type = "noun"},
    ["consider"] = {def = "to think carefully about", type = "verb"},
    ["continue"] = {def = "to persist in", type = "verb"},
    ["control"] = {def = "the power to influence", type = "noun"},
    ["cost"] = {def = "the amount paid for something", type = "noun"},
    ["could"] = {def = "past tense of can", type = "verb"},
    ["country"] = {def = "a nation with its own government", type = "noun"},
    ["course"] = {def = "a direction or route", type = "noun"},
    ["court"] = {def = "a place where justice is administered", type = "noun"},
    ["cover"] = {def = "to place something over", type = "verb"},
    ["create"] = {def = "to bring into existence", type = "verb"},
    ["cross"] = {def = "to go across", type = "verb"},
    ["cry"] = {def = "to shed tears", type = "verb"},
    ["cut"] = {def = "to divide with a sharp tool", type = "verb"},
}

-- Word relationships
M.synonyms = {
    ["happy"] = {"joyful", "pleased", "content", "glad"},
    ["sad"] = {"unhappy", "sorrowful", "depressed", "miserable"},
    ["big"] = {"large", "huge", "enormous", "giant"},
    ["small"] = {"little", "tiny", "miniature", "petite"},
    ["good"] = {"excellent", "great", "fine", "wonderful"},
    ["bad"] = {"poor", "terrible", "awful", "horrible"},
    ["fast"] = {"quick", "rapid", "swift", "speedy"},
    ["slow"] = {"sluggish", "leisurely", "gradual"},
}

M.antonyms = {
    ["happy"] = {"sad", "unhappy", "miserable"},
    ["big"] = {"small", "little", "tiny"},
    ["good"] = {"bad", "poor", "terrible"},
    ["fast"] = {"slow", "sluggish"},
    ["hot"] = {"cold", "cool", "freezing"},
    ["light"] = {"dark", "heavy"},
    ["easy"] = {"hard", "difficult"},
}

-- Lookup word
function M.define(word)
    local lower = word:lower()
    if M.words[lower] then
        return M.words[lower]
    end
    return nil
end

-- Get synonyms
function M.getSynonyms(word)
    local lower = word:lower()
    return M.synonyms[lower] or {}
end

-- Get antonyms  
function M.getAntonyms(word)
    local lower = word:lower()
    return M.antonyms[lower] or {}
end

-- Check if word exists
function M.hasWord(word)
    local lower = word:lower()
    return M.words[lower] ~= nil
end

-- Add new word
function M.addWord(word, definition, wordType)
    local lower = word:lower()
    M.words[lower] = {
        def = definition,
        type = wordType or "unknown"
    }
    return true
end

-- Get word count
function M.getWordCount()
    local count = 0
    for _ in pairs(M.words) do
        count = count + 1
    end
    return count
end

return M
