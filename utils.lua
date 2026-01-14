-- Module: utils.lua
-- Core utility functions and response libraries

local M = {}

-- Response libraries
M.library = {
    greetings = {
        "Hey! Ready to build something cool?",
        "Howdy! Found any diamonds lately?",
        "Yo! How's your mining going?",
        "Hello there! Watch out for creepers!",
        "Hi! What's up in your world today?",
        "Heya! Got any new builds to show?",
        "Sup! Found any hidden caves?",
        "Hi there! Let's dig some blocks!",
        "Hey friend! Time for adventure?",
        "Yo! Ready to craft something amazing?"
    },
    replies = {
        "Nice one!",
        "That sounds fun!",
        "Oh wow, I didn't expect that.",
        "Cool! Keep going.",
        "Haha, good idea!",
        "Awesome!",
        "Yup, I get it.",
        "Sweet!",
        "Interesting!",
        "Got it!",
        "Right on!",
        "Perfect!",
        "Makes sense!"
    },
    interjections = {
        "Hmm…", "Oh!", "Ah, got it!", "Whoa!", "Yikes!", 
        "Aha!", "Eek!", "Huh?", "Wow!", "Ooh!"
    },
    idioms = {
        "Don't put all your eggs in one chest.",
        "Even the Ender Dragon can't stop us!",
        "Better safe than respawned!",
        "A redstone a day keeps the boredom away.",
        "The early miner gets the diamonds."
    },
    jokes = {
        "Why did the skeleton go to the party alone? Because he had no body to go with!",
        "Why don't zombies eat clowns? They taste funny!",
        "Why did the creeper cross the road? Boom!",
        "What do you call a sheep that knows magic? A wool-izard!",
        "Why did the chicken join a Minecraft server? To lay some blocks!"
    }
}

-- Helper: choose random element from table
function M.choose(tbl)
    if not tbl or #tbl == 0 then return "" end
    return tbl[math.random(#tbl)]
end

-- Helper: check if table contains value
function M.tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Helper: normalize text
function M.normalize(text)
    return text:lower():gsub("%s+", " "):gsub("[^%w%s]", "")
end

-- Helper: extract keywords from text
function M.extractKeywords(text)
    local keywords = {}
    for word in text:gmatch("%w+") do
        if #word > 2 then  -- ignore very short words
            table.insert(keywords, word:lower())
        end
    end
    return keywords
end

return M
