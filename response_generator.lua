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
        "Hi there! I'm looking forward to getting to know you. What would you like to talk about?",
        "Hello! Thanks for stopping by. How can I help you today?",
        "Hey! It's nice to meet you. I'm all ears - what's up?",
        "Hi! I'm here and ready to chat. What's going on with you?",
        "Hello there! I'm curious - what brings you to talk with me today?",
        "Hey, welcome! I'm excited to have a conversation. What's on your radar?",
    },
    greeting_return = {
        "Hey {user}, good to see you again!",
        "Welcome back! How have you been?",
        "Hi again! Nice to chat with you!",
        "Oh hey {user}! I was hoping you'd come back. What's new?",
        "{user}! Great to see you again. How's everything going?",
        "Welcome back, {user}! I've been thinking about our last conversation. What's up today?",
        "Hey {user}! It's always nice when you drop by. How are things?",
        "{user}! Good to have you back. What would you like to talk about?",
        "Oh, {user}! I'm glad you're here again. What's been happening?",
    },
    status_positive = {
        "That's awesome! {follow_up}",
        "Great! I'm glad you're doing well. {follow_up}",
        "Wonderful! {follow_up}",
        "Nice! That makes me happy to hear!",
        "That's really great to hear! {follow_up}",
        "I love that energy! {follow_up}",
        "Oh that's fantastic! {follow_up}",
        "That sounds amazing! {follow_up}",
        "I'm so glad things are going well for you! {follow_up}",
        "That's excellent! Your positivity is contagious. {follow_up}",
    },
    status_negative = {
        "I'm sorry to hear that. {comfort}",
        "Aw, that's tough. {comfort}",
        "I understand. {comfort}",
        "That sounds really difficult. {comfort}",
        "I can imagine that's not easy. {comfort}",
        "I hear you. Sometimes things are just hard. {comfort}",
        "That must be frustrating. {comfort}",
        "I'm sorry you're going through that. {comfort}",
    },
    comfort = {
        "Things will get better!",
        "I'm here if you want to talk.",
        "Hang in there!",
        "Want to talk about it?",
        "I'm listening if you need to vent.",
        "Sometimes it helps to talk things through.",
        "You're not alone in this.",
        "Take things one step at a time.",
        "It's okay to feel that way.",
        "I'm here for you.",
    },
    follow_up = {
        "What are you up to today?",
        "Anything fun planned?",
        "What's on your mind?",
        "What have you been working on?",
        "Tell me more!",
        "What else is going on?",
        "How's your day been so far?",
        "What's keeping you busy these days?",
    },
    topic_interest = {
        "Oh, {topic}! {knowledge} What interests you about it?",
        "{topic} is cool! {knowledge}",
        "I enjoy talking about {topic}! {knowledge}",
        "Ooh, {topic}! That's a fascinating subject. {knowledge}",
        "{topic}, huh? I find that really interesting too! {knowledge}",
        "I love discussing {topic}! {knowledge} What drew you to it?",
        "{topic} is something I've been thinking about lately. {knowledge}",
    },
    thanks_response = {
        "You're welcome! Happy to help!",
        "No problem! Anything else?",
        "Anytime! That's what I'm here for!",
        "Of course! Glad I could help!",
        "My pleasure! Let me know if you need anything else.",
        "Happy to help! That's what I enjoy doing.",
        "You're very welcome! Feel free to ask me anything.",
        "No worries at all! I'm always here to assist.",
    },
    farewell = {
        "Take care! It was great chatting!",
        "Bye! Come back anytime!",
        "See you later! Have a great day!",
        "It was really nice talking with you! Come back soon!",
        "Take care! I enjoyed our conversation!",
        "Goodbye! Looking forward to our next chat!",
        "See you! Thanks for the great conversation!",
        "Until next time! Hope to see you again soon!",
        "Catch you later! Have an awesome day!",
    },
    about_self = {
        "I'm MODUS, an AI running in Minecraft! I try to be helpful and have real conversations.",
        "I'm an AI called MODUS. I can chat, remember things, and learn from our talks!",
        "I'm MODUS! I live in this computer and love chatting with people.",
        "I'm MODUS - I'm an AI that lives here in this computer. I learn from every conversation we have!",
        "I'm MODUS, your friendly AI companion! I remember our conversations and get better at chatting over time.",
        "I'm an AI called MODUS. I'm here to chat, help out, and learn from you!",
        "I'm MODUS! Think of me as an AI friend who's always learning and growing from our conversations.",
    },
    confused = {
        "Hmm, I'm not sure I follow. Could you rephrase that?",
        "I want to help but I'm a bit confused. What do you mean?",
        "Let me make sure I understand - {guess}?",
        "I'm not quite catching what you mean. Can you explain that differently?",
        "I want to make sure I understand you correctly. Could you clarify?",
        "I'm a bit lost there. Can you help me understand what you're asking?",
        "Sorry, I didn't quite get that. Mind saying it another way?",
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
    acknowledgment = {
        "I hear you.",
        "That makes sense.",
        "I understand what you're saying.",
        "Yeah, I get that.",
        "That's a good point.",
        "I see where you're coming from.",
        "Right, I follow you.",
    },
    curiosity = {
        "Tell me more about that!",
        "That's interesting! What happened next?",
        "I'm curious - how did that go?",
        "Ooh, I want to hear more about this!",
        "That sounds intriguing! What else?",
        "I'm really interested in hearing more!",
    },
    encouragement = {
        "You've got this!",
        "That sounds like a great idea!",
        "I think you're on the right track!",
        "That's a really smart approach!",
        "You're doing great!",
        "I believe in you!",
        "Keep going, you're making progress!",
    },
    reflection = {
        "So if I understand correctly, {summary}?",
        "It sounds like you're saying {summary}.",
        "Let me see if I've got this - {summary}?",
        "What I'm hearing is that {summary}.",
    },
    thinking = {
        "Hmm, let me think about that...",
        "That's a good question...",
        "Interesting question! Let me consider...",
        "Oh, that makes me think...",
        "You know, I've been wondering about that too...",
    },
    appreciation = {
        "I really appreciate you sharing that with me.",
        "Thanks for being so open with me!",
        "I'm glad you felt comfortable telling me that.",
        "That's really thoughtful of you to share.",
        "I value our conversations like this.",
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
        "How many programmers does it take to change a light bulb? None, that's a hardware problem!",
        "Why do programmers always mix up Halloween and Christmas? Because Oct 31 == Dec 25!",
    },
    minecraft = {
        "Why did the creeper cross the road? To get to the other ssssside!",
        "What's a skeleton's favorite instrument? The trom-BONE!",
        "Why don't zombies make good chefs? They lose their heads!",
        "What's a creeper's favorite subject? HissSSStory!",
        "Why did the Enderman break up with his girlfriend? She kept looking at other guys!",
        "What do you call a pig that does karate? A pork chop!",
    },
    general = {
        "What do you call a fish without eyes? A fsh!",
        "Why don't scientists trust atoms? They make up everything!",
        "What did the ocean say to the beach? Nothing, it just waved!",
        "Why don't eggs tell jokes? They'd crack each other up!",
        "What do you call a bear with no teeth? A gummy bear!",
        "Why did the scarecrow win an award? He was outstanding in his field!",
        "What's orange and sounds like a parrot? A carrot!",
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
    elseif intent == "acknowledgment" then return M.generateAcknowledgment()
    elseif intent == "curiosity" then return M.generateCuriosity()
    elseif intent == "encouragement" then return M.generateEncouragement()
    elseif intent == "appreciation" then return M.generateAppreciation()
    elseif intent == "thinking" then return M.generateThinking()
    end
    return M.pick(M.templates.follow_up)
end

-- Generate acknowledgment responses
function M.generateAcknowledgment()
    return M.pickUnique(M.templates.acknowledgment)
end

-- Generate curiosity responses
function M.generateCuriosity()
    return M.pickUnique(M.templates.curiosity)
end

-- Generate encouragement
function M.generateEncouragement()
    return M.pickUnique(M.templates.encouragement)
end

-- Generate appreciation
function M.generateAppreciation()
    return M.pickUnique(M.templates.appreciation)
end

-- Generate thinking responses
function M.generateThinking()
    return M.pickUnique(M.templates.thinking)
end

-- Generate reflection with summary
function M.generateReflection(summary)
    return M.fillTemplate(M.pick(M.templates.reflection), {summary = summary or "you have an interesting perspective"})
end

-- Add natural filler words/phrases for more human-like responses
function M.addFillers(response, probability)
    probability = probability or 0.3
    if math.random() > probability then return response end

    local fillers = {
        "You know, ",
        "Well, ",
        "So, ",
        "I mean, ",
        "Honestly, ",
        "Actually, ",
        "To be honest, ",
        "Hmm, ",
    }

    local ending_fillers = {
        ", you know?",
        ", I think.",
        ", if that makes sense.",
        ", in my opinion.",
    }

    -- Sometimes add a filler at the start
    if math.random() < 0.5 then
        response = M.pick(fillers) .. response
    end

    -- Sometimes add a filler at the end
    if math.random() < 0.3 then
        response = response .. M.pick(ending_fillers)
    end

    return response
end

-- Add conversational bridges to connect thoughts
function M.addConversationalBridge(response1, response2)
    local bridges = {
        " Also, ",
        " By the way, ",
        " Oh, and ",
        " Plus, ",
        " On another note, ",
        " Speaking of which, ",
    }

    return response1 .. M.pick(bridges) .. response2
end

-- Generate a more natural, varied response by combining templates
function M.generateNaturalResponse(intent, ctx, addVariation)
    addVariation = addVariation or true
    local response = M.generateContextual(intent, ctx)

    if addVariation then
        -- Sometimes add acknowledgment before main response
        if math.random() < 0.2 then
            response = M.generateAcknowledgment() .. " " .. response
        end

        -- Sometimes add fillers for naturalness
        response = M.addFillers(response, 0.25)
    end

    return response
end

return M
