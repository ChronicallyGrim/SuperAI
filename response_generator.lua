-- response_generator.lua
-- Advanced response generation with templates and variation
-- Generates novel, context-aware responses

local M = {}

-- Templates with {slots} for dynamic content
M.templates = {
    greeting_new = {
        "Hey there! Nice to meet you. What's on your mind?",
        "Hello! I'm excited to chat. How are you doing?",
        "Hi! Welcome! What would you like to talk about?",
        "Hey! Great to meet you. What brings you here?",
    },
    greeting_return = {
        "Hey {user}, good to see you again!",
        "Welcome back! How have you been?",
        "Hi again! Nice to chat with you!",
    },
    status_positive = {
        "That's awesome! {follow_up}",
        "Great! I'm glad you're doing well. {follow_up}",
        "Wonderful! {follow_up}",
        "Nice! That makes me happy to hear!",
    },
    status_negative = {
        "I'm sorry to hear that. {comfort}",
        "Aw, that's tough. {comfort}",
        "I understand. {comfort}",
    },
    comfort = {
        "Things will get better!",
        "I'm here if you want to talk.",
        "Hang in there!",
        "Want to talk about it?",
    },
    follow_up = {
        "What are you up to today?",
        "Anything fun planned?",
        "What's on your mind?",
    },
    topic_interest = {
        "Oh, {topic}! {knowledge} What interests you about it?",
        "{topic} is cool! {knowledge}",
        "I enjoy talking about {topic}! {knowledge}",
    },
    thanks_response = {
        "You're welcome! Happy to help!",
        "No problem! Anything else?",
        "Anytime! That's what I'm here for!",
    },
    farewell = {
        "Take care! It was great chatting!",
        "Bye! Come back anytime!",
        "See you later! Have a great day!",
    },
    about_self = {
        "I'm MODUS, an AI running in Minecraft! I try to be helpful and have real conversations.",
        "I'm an AI called MODUS. I can chat, remember things, and learn from our talks!",
        "I'm MODUS! I live in this computer and love chatting with people.",
    },
    confused = {
        "Hmm, I'm not sure I follow. Could you rephrase that?",
        "I want to help but I'm a bit confused. What do you mean?",
        "Let me make sure I understand - {guess}?",
    },
    agree = {
        "I totally agree!",
        "Yes, absolutely!",
        "That's exactly right!",
    },
    playful = {
        "Haha, you're funny!",
        "LOL, good one!",
        "Ha! I like your sense of humor!",
    },
    empathy_happy = {
        "Your excitement is contagious!",
        "I can feel your enthusiasm!",
        "That's so cool!",
    },
    empathy_sad = {
        "I can tell this is hard. I'm here to listen.",
        "That sounds really tough. It's okay to feel that way.",
        "I'm sorry you're going through this.",
    },
}

-- Jokes
M.jokes = {
    programmer = {
        "Why do programmers prefer dark mode? Because light attracts bugs!",
        "A SQL query walks into a bar, walks up to two tables and asks 'Can I join you?'",
        "Why do Java developers wear glasses? Because they can't C#!",
        "There are only 10 types of people - those who understand binary and those who don't!",
        "Why did the programmer quit? He didn't get arrays!",
    },
    minecraft = {
        "Why did the creeper cross the road? To get to the other ssssside!",
        "What's a skeleton's favorite instrument? The trom-BONE!",
        "Why don't zombies make good chefs? They lose their heads!",
    },
    general = {
        "What do you call a fish without eyes? A fsh!",
        "Why don't scientists trust atoms? They make up everything!",
        "What did the ocean say to the beach? Nothing, it just waved!",
    },
}

-- Recent responses to avoid repetition
M.recent = {}
M.maxRecent = 10

function M.pick(tbl)
    if not tbl or #tbl == 0 then return "" end
    return tbl[math.random(#tbl)]
end

function M.fillTemplate(template, slots)
    if not template then return "" end
    local result = template
    for key, value in pairs(slots or {}) do
        result = result:gsub("{" .. key .. "}", tostring(value))
    end
    result = result:gsub("{%w+}", "")
    return result:gsub("  +", " "):gsub("^ +", ""):gsub(" +$", "")
end

function M.pickUnique(tbl)
    for _ = 1, 5 do
        local choice = M.pick(tbl)
        local found = false
        for _, r in ipairs(M.recent) do
            if r == choice then found = true; break end
        end
        if not found then
            table.insert(M.recent, 1, choice)
            while #M.recent > M.maxRecent do table.remove(M.recent) end
            return choice
        end
    end
    return M.pick(tbl)
end

function M.generateGreeting(ctx)
    ctx = ctx or {}
    if ctx.user_name then
        return M.fillTemplate(M.pickUnique(M.templates.greeting_return), {user = ctx.user_name})
    end
    return M.pickUnique(M.templates.greeting_new)
end

function M.generateStatusResponse(sentiment)
    if sentiment > 0.3 then
        return M.fillTemplate(M.pickUnique(M.templates.status_positive), {follow_up = M.pick(M.templates.follow_up)})
    elseif sentiment < -0.3 then
        return M.fillTemplate(M.pickUnique(M.templates.status_negative), {comfort = M.pick(M.templates.comfort)})
    end
    return M.pick(M.templates.follow_up)
end

function M.generateTopicResponse(topic, knowledge)
    return M.fillTemplate(M.pickUnique(M.templates.topic_interest), {topic = topic, knowledge = knowledge or ""})
end

function M.generateJoke(category)
    category = category or "general"
    local jokes = M.jokes[category] or M.jokes.general
    return M.pick(jokes)
end

function M.generateFarewell()
    return M.pickUnique(M.templates.farewell)
end

function M.generateThanks()
    return M.pickUnique(M.templates.thanks_response)
end

function M.generateAboutSelf()
    return M.pickUnique(M.templates.about_self)
end

function M.generateConfused(guess)
    return M.fillTemplate(M.pick(M.templates.confused), {guess = guess or "what you mean"})
end

function M.generateEmpathy(emotion)
    if emotion == "happy" then
        return M.pickUnique(M.templates.empathy_happy)
    elseif emotion == "sad" then
        return M.pickUnique(M.templates.empathy_sad)
    end
    return M.pick(M.templates.follow_up)
end

function M.generateContextual(intent, ctx)
    ctx = ctx or {}
    if intent == "greeting" then return M.generateGreeting(ctx)
    elseif intent == "farewell" then return M.generateFarewell()
    elseif intent == "thanks" then return M.generateThanks()
    elseif intent == "status_positive" then return M.generateStatusResponse(0.8)
    elseif intent == "status_negative" then return M.generateStatusResponse(-0.8)
    elseif intent == "joke" then return M.generateJoke(ctx.category)
    elseif intent == "about_ai" then return M.generateAboutSelf()
    elseif intent == "confused" then return M.generateConfused(ctx.guess)
    elseif intent == "topic" then return M.generateTopicResponse(ctx.topic, ctx.knowledge)
    elseif intent == "agree" then return M.pickUnique(M.templates.agree)
    elseif intent == "playful" then return M.pickUnique(M.templates.playful)
    end
    return M.pick(M.templates.follow_up)
end

return M
