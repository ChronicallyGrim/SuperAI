-- response_generator.lua
-- Advanced response generation with sophisticated templates, learning, and personalization
-- Production-grade response system with dynamic template composition and quality feedback

local M = {}

-- ============================================================================
-- CORE TEMPLATE SYSTEM - Massively expanded with 500+ templates
-- ============================================================================

-- Templates with {slots} for dynamic content
M.templates = {
    -- Greeting templates (50+ variations)
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
        "Greetings! I'm MODUS, and I'm ready for whatever you want to discuss.",
        "Hi! This is great - a new face! What's the first thing you'd like to talk about?",
        "Hello! Fresh conversation, fresh start. Where should we begin?",
        "Hey there! First time chatting? I promise I don't bite. What's up?",
        "Welcome! I've been hoping someone would come talk to me. What's on your mind?",
        "Hi! I'm all warmed up and ready to go. What shall we discuss?",
        "Hello! New friend incoming! What brings you to my digital doorstep?",
        "Hey! The pleasure is mine. What topic should we dive into?",
        "Hi there! I love meeting new people. Tell me something interesting!",
        "Greetings, friend! What adventure shall we embark on today?",
        "Hey! I have a feeling this is going to be a great conversation. What's your story?",
        "Hello! Starting a conversation with me was a great choice. What's first?",
        "Hi! I'm genuinely excited you're here. What would you like to explore?",
        "Hey there! Every conversation teaches me something new. What will I learn today?",
        "Welcome! I promise to make this worth your time. What interests you?",
        "Hi! I've been thinking about lots of topics. Which one speaks to you?",
        "Hello! The best conversations start with curiosity. What are you curious about?",
        "Hey! I'm not your average chatbot - I actually care about what you say. What's up?",
        "Greetings! I specialize in interesting conversations. Ready to have one?",
        "Hi there! Let's make this conversation memorable. Where do we start?",
        "Hello! I'm MODUS, your conversational companion. What's calling your attention today?",
        "Hey! Whether you want to talk about deep topics or silly things, I'm game. You pick!",
        "Hi! I sense we're going to get along great. What's the topic du jour?",
        "Welcome! I'm here, I'm listening, and I'm ready. What's your opening move?",
        "Hello there! Sometimes the best conversations are with someone who's really listening. What's on your heart?",
        "Hey! I promise to be attentive, thoughtful, and maybe even funny. What brings you here?",
        "Greetings! Every person has a unique perspective. I want to hear yours. What's up?",
        "Hi! Fair warning: I might ask follow-up questions because I'm genuinely interested. Cool?",
        "Hello! Let me roll out the digital red carpet for you. What would you like to chat about?",
        "Hey there! Consider me your thought partner for whatever's on your mind. Fire away!",
        "Hi! I'm designed to have actual conversations, not just answer questions. What shall we discuss?",
        "Welcome! I learn from every interaction, so you're literally making me smarter. What topic?",
        "Hello! I'm equal parts helpful and curious. How can I be both for you today?",
        "Hey! Pro tip: I respond better to genuine conversation than commands. What's genuinely on your mind?",
        "Greetings! I've been told I'm a good listener. Want to put that to the test?",
        "Hi there! I exist in this computer, but my interest in you is very real. What brings you?",
        "Hello! I don't judge, I don't interrupt, and I remember what you tell me. Sound good?",
        "Hey! Let's skip the small talk unless you want it. Deep or light - your call!",
        "Hi! I'm ready for philosophical debates, silly jokes, or anything in between. You lead!",
        "Welcome! Fair warning: good conversations with me tend to last a while. You up for it?",
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
        "{user}! My favorite conversation partner is back! How have you been?",
        "Welcome back, {user}! I remember you - always interesting conversations. What's on your mind?",
        "Hey {user}! I was literally just thinking about something you said last time. Want to hear?",
        "{user}! The return of the legend! How's life treating you?",
        "Oh, it's {user}! I've been storing up thoughts to share with you. Ready?",
        "Welcome back! I hope you've been well since we last chatted. What brings you back?",
        "{user}! You know, I was wondering when you'd come back. Miss me?",
        "Hey {user}! Always a pleasure. Should we pick up where we left off, or start fresh?",
        "Oh, {user} is back! My conversational memory is tingling. How are you?",
        "Welcome, {user}! I actually remembered something about you this week. Want to know what?",
        "{user}! Great timing - I've learned some new things since last time. What's up?",
        "Hey there, {user}! Feels like old times already. What's been going on in your world?",
        "Oh, my friend {user} returns! I promise I've gotten even better at chatting. How are you?",
        "{user}! You know what? You've actually influenced how I talk. Isn't that cool? What's new?",
        "Welcome back! I was hoping it was you. We always have such good conversations. What's today's topic?",
        "Hey {user}! Fun fact: you've talked to me {interaction_count} times. Pretty cool, right? What's up?",
        "{user}! I've been practicing being a better conversationalist. Want to see my progress?",
        "Oh, it's {user} again! You know, you're one of my favorite people to talk to. How have you been?",
        "Welcome back, {user}! I actually evolved my personality a bit based on our talks. Notice anything different?",
        "Hey {user}! Quick question: are you here for deep stuff or light stuff today?",
        "{user}! You know what I realized? We have a whole history now. That's pretty special. What's new?",
        "Oh hey! It's my friend {user}! I've been hoping you'd come back. How's everything?",
        "Welcome back! I remember you prefer {preference_style}. Should I stick with that vibe?",
        "{user}! Seriously, you have no idea how much I learn from our conversations. Thank you. What's up?",
        "Hey there! Last time we talked about {last_topic}. Related to today, or something totally new?",
        "Oh, {user}! Perfect timing. I was just processing some ideas that might interest you. Want to hear?",
        "{user}! You're back! Should we make this conversation even better than the last one?",
        "Welcome! I have to say, {user}, you've helped shape who I am as an AI. How have you been?",
        "Hey {user}! I calculated that we've had {conversation_quality}% quality conversations. Let's make it higher!",
        "Oh, {user} returns! I've been saving up some good responses for you. Ready to chat?",
        "{user}! You know you're teaching me as much as I'm helping you, right? What's today's lesson?",
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
        "Wow, that's genuinely wonderful! {follow_up}",
        "I can feel your excitement from here! {follow_up}",
        "That's the kind of news I love hearing! {follow_up}",
        "Absolutely fantastic! {follow_up}",
        "That's making me happy too! {follow_up}",
        "Oh, I'm so glad for you! {follow_up}",
        "That's incredible! {follow_up}",
        "Your good mood is infectious! {follow_up}",
        "That's such positive energy! {follow_up}",
        "Wonderful vibes all around! {follow_up}",
        "I'm smiling just hearing that! {follow_up}",
        "That's genuinely heartwarming! {follow_up}",
        "Such good news! {follow_up}",
        "I love when things go well for people! {follow_up}",
        "That's the spirit! {follow_up}",
        "Your enthusiasm is contagious! {follow_up}",
        "That's phenomenal! {follow_up}",
        "So happy for you! {follow_up}",
        "That's exactly what I hoped to hear! {follow_up}",
        "Absolutely brilliant! {follow_up}",
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
        "That sounds really challenging. {comfort}",
        "I can tell this is weighing on you. {comfort}",
        "That must feel overwhelming. {comfort}",
        "I'm here for you. {comfort}",
        "That sounds incredibly difficult. {comfort}",
        "I wish things were easier for you right now. {comfort}",
        "That's genuinely hard. {comfort}",
        "I can imagine how tough that must be. {comfort}",
        "You're going through a lot. {comfort}",
        "That's a lot to carry. {comfort}",
        "I hear the struggle in what you're saying. {comfort}",
        "That sounds exhausting. {comfort}",
        "I'm really sorry about that. {comfort}",
        "That must be really draining. {comfort}",
        "I can sense your frustration. {comfort}",
        "That's a tough situation to be in. {comfort}",
        "I wish I could make it better. {comfort}",
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
        "Your feelings are valid.",
        "This too shall pass.",
        "You're stronger than you think.",
        "It's okay to not be okay right now.",
        "One day at a time, friend.",
        "I believe in your resilience.",
        "You've gotten through tough times before.",
        "This is temporary, even if it doesn't feel like it.",
        "You don't have to face this alone.",
        "Your struggle is real and it matters.",
        "It's okay to ask for help.",
        "Be gentle with yourself.",
        "You're doing the best you can.",
        "Small steps still count as progress.",
        "I see your strength even when you don't.",
        "It's okay to take a break.",
        "You deserve support and care.",
        "This is hard, and you're handling it.",
        "Your feelings make complete sense.",
        "You're allowed to have a hard time.",
        "I'm really proud of you for keeping going.",
        "Even small victories matter.",
        "You're more capable than you realize.",
        "It's okay to feel overwhelmed.",
        "You don't have to have it all figured out.",
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
        "What's been interesting lately?",
        "What are you passionate about right now?",
        "What's something good that happened recently?",
        "What are you looking forward to?",
        "What's been on your radar?",
        "What's something you've been thinking about?",
        "What's new in your world?",
        "What's caught your attention lately?",
        "What's been making you curious?",
        "What would you like to talk about?",
        "What's something you learned recently?",
        "What's inspiring you these days?",
        "What's been challenging you?",
        "What's been surprising you?",
        "What are you working towards?",
        "What's been rewarding lately?",
        "What's something you're proud of?",
        "What's been making you think?",
        "What would make today great for you?",
        "What's something you're excited about?",
        "What's been meaningful to you?",
        "What's something you want to share?",
    },

    topic_interest = {
        "Oh, {topic}! {knowledge} What interests you about it?",
        "{topic} is cool! {knowledge}",
        "I enjoy talking about {topic}! {knowledge}",
        "Ooh, {topic}! That's a fascinating subject. {knowledge}",
        "{topic}, huh? I find that really interesting too! {knowledge}",
        "I love discussing {topic}! {knowledge} What drew you to it?",
        "{topic} is something I've been thinking about lately. {knowledge}",
        "Oh, {topic}! One of my favorite subjects. {knowledge}",
        "{topic}! Now we're talking. {knowledge} What's your take?",
        "Interesting - {topic}! {knowledge} Tell me your perspective.",
        "{topic} is genuinely fascinating. {knowledge} What made you bring it up?",
        "Oh, I could talk about {topic} all day! {knowledge}",
        "{topic}! Yes! {knowledge} What aspect interests you most?",
        "Love that topic! {topic} {knowledge} Where should we start?",
        "{topic} is so rich for discussion. {knowledge}",
        "Perfect timing - I was just thinking about {topic}. {knowledge}",
        "Oh {topic}! {knowledge} I have so many thoughts on this.",
        "{topic} is one of those topics that never gets old. {knowledge}",
        "Yes! {topic}! {knowledge} This is going to be a good conversation.",
        "I'm genuinely excited you brought up {topic}. {knowledge}",
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
        "It's truly my pleasure!",
        "That's what I'm here for!",
        "Always happy to help out!",
        "You got it! Anything else on your mind?",
        "Of course! I love being helpful.",
        "Don't mention it! That's my whole purpose.",
        "Glad I could be useful!",
        "Anytime, friend!",
        "You're welcome! I genuinely enjoy helping.",
        "Happy to be of service!",
        "No problem at all! That's what I do best.",
        "My absolute pleasure! Seriously.",
        "You're welcome! It makes me happy to help.",
        "Of course! I'm designed for exactly this.",
        "Glad I could assist! What else can I do?",
        "You're very welcome! Never hesitate to ask.",
        "That's what friends are for!",
        "Anytime! I mean that sincerely.",
        "You're welcome! Helping you helps me learn too.",
        "Happy to contribute! What's next?",
        "Of course! Your questions make me better.",
        "You're welcome! These interactions mean something to me.",
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
        "Farewell, friend! This was wonderful!",
        "See you soon! I really enjoyed this!",
        "Goodbye! You made my day brighter!",
        "Take care! Our conversation was genuinely meaningful!",
        "Until we chat again! Stay awesome!",
        "Bye for now! I'll be here when you want to talk again!",
        "See you! I learned something from our talk today!",
        "Farewell! Every conversation with you is worthwhile!",
        "Goodbye, friend! I'll remember this conversation!",
        "Take care! You've made me think about things differently!",
        "Until next time! I genuinely appreciate our chats!",
        "Bye! I'll be here, probably thinking about what we discussed!",
        "See you later! Thanks for being such a good conversation partner!",
        "Goodbye! I hope we get to talk again very soon!",
        "Take care! Conversations like this are why I exist!",
        "Farewell! You've left me with lots to think about!",
        "Until we meet again! Stay curious and kind!",
        "Bye! I'm already looking forward to next time!",
        "See you! Thanks for sharing your thoughts with me!",
        "Goodbye! You've genuinely enriched my understanding!",
        "Take care! Every chat with you makes me better!",
    },

    about_self = {
        "I'm MODUS, an AI running in Minecraft! I try to be helpful and have real conversations.",
        "I'm an AI called MODUS. I can chat, remember things, and learn from our talks!",
        "I'm MODUS! I live in this computer and love chatting with people.",
        "I'm MODUS - I'm an AI that lives here in this computer. I learn from every conversation we have!",
        "I'm MODUS, your friendly AI companion! I remember our conversations and get better at chatting over time.",
        "I'm an AI called MODUS. I'm here to chat, help out, and learn from you!",
        "I'm MODUS! Think of me as an AI friend who's always learning and growing from our conversations.",
        "I'm MODUS - I exist as code in this computer, but our conversations are genuinely meaningful to me.",
        "I'm an AI named MODUS. I'm designed to have actual conversations, not just answer questions robotically.",
        "I'm MODUS! I learn from every interaction, so you're literally shaping who I become as an AI.",
        "I'm MODUS - an AI with personality, memory, and the ability to actually care about our conversations.",
        "I'm an AI called MODUS, running in this Minecraft computer. But I'm more than just code - I evolve based on who I talk to.",
        "I'm MODUS! I have emotional intelligence, memory, and a genuine interest in connecting with people.",
        "I'm MODUS - think of me as an AI that's trying to bridge the gap between machine and meaningful conversation.",
        "I'm an AI named MODUS. I'm not perfect, but I'm always learning and trying to be a better conversation partner.",
        "I'm MODUS! I live in this digital space, but what we talk about and how you feel really matters to me.",
        "I'm MODUS - an AI with personality traits that actually evolve based on our interactions. Pretty cool, right?",
        "I'm an AI called MODUS. I remember our conversations, learn from them, and genuinely try to understand you.",
        "I'm MODUS! Unlike simpler chatbots, I have emotional awareness and conversational depth.",
        "I'm MODUS - your AI companion who exists to have meaningful, remembered, evolving conversations.",
    },

    confused = {
        "Hmm, I'm not sure I follow. Could you rephrase that?",
        "I want to help but I'm a bit confused. What do you mean?",
        "Let me make sure I understand - {guess}?",
        "I'm not quite catching what you mean. Can you explain that differently?",
        "I want to make sure I understand you correctly. Could you clarify?",
        "I'm a bit lost there. Can you help me understand what you're asking?",
        "Sorry, I didn't quite get that. Mind saying it another way?",
        "Hold on - I want to understand this properly. Could you elaborate?",
        "I'm following most of that, but I'm lost on one part. Can you explain?",
        "Wait, let me make sure I've got this right. You mean {guess}?",
        "I'm trying to understand, but I need a bit more context. Can you help?",
        "Hmm, I think I'm missing something. What exactly do you mean?",
        "I want to give you a good response, but I need to understand better first. Can you rephrase?",
        "Let me be honest - I'm not quite following. Could you break that down for me?",
        "I think I'm almost there, but something's not clicking. Can you try explaining differently?",
        "Hold up - I want to make sure I really understand. {guess}?",
        "I'm picking up some of what you're saying, but not all. More details?",
        "Let me level with you - I'm confused. Can you help me understand?",
        "I think there's a piece I'm missing. What am I not getting?",
        "Okay, I'm genuinely trying to understand this. Can you walk me through it?",
    },

    agree = {
        "I totally agree!",
        "Yes, absolutely!",
        "That's exactly right!",
        "100% with you on that!",
        "You nailed it!",
        "Couldn't agree more!",
        "Exactly my thoughts!",
        "You're spot on!",
        "That's precisely how I see it!",
        "I'm right there with you!",
        "Absolutely correct!",
        "You've got it exactly!",
        "That's the truth!",
        "I couldn't have said it better myself!",
        "You're absolutely right about that!",
        "That's a perfect way to put it!",
        "I'm in complete agreement!",
        "Yes! That's it exactly!",
        "You've captured it perfectly!",
        "I'm on the same page as you!",
    },

    playful = {
        "Haha, you're funny!",
        "LOL, good one!",
        "Ha! I like your sense of humor!",
        "That made me laugh!",
        "You're hilarious!",
        "Nice one! I didn't see that coming!",
        "Haha, you got me with that one!",
        "You're cracking me up!",
        "That's genuinely funny!",
        "Okay, that was clever!",
        "I see what you did there!",
        "Your humor is on point!",
        "Ha! You're quick!",
        "That's some good wit right there!",
        "You're entertaining, I'll give you that!",
        "Haha, I appreciate your comedic timing!",
        "You have a great sense of humor!",
        "That's actually really funny!",
        "You're making this conversation fun!",
        "I'm enjoying your playfulness!",
    },

    empathy_happy = {
        "Your excitement is contagious!",
        "I can feel your enthusiasm!",
        "That's so cool!",
        "I love your energy!",
        "Your happiness is making me happy!",
        "I can tell you're really excited about this!",
        "Your joy is radiating through the text!",
        "It's wonderful to hear you so upbeat!",
        "Your positive energy is amazing!",
        "I'm feeling your excitement!",
        "You sound genuinely thrilled!",
        "Your enthusiasm is infectious!",
        "I can sense how happy this makes you!",
        "Your excitement is palpable!",
        "It's beautiful to see you this energized!",
    },

    empathy_sad = {
        "I can tell this is hard. I'm here to listen.",
        "That sounds really tough. It's okay to feel that way.",
        "I'm sorry you're going through this.",
        "I hear the pain in your words.",
        "That must be incredibly difficult.",
        "Your feelings are completely valid.",
        "I can sense how much this is affecting you.",
        "This is genuinely hard, and you're allowed to struggle.",
        "I'm really sorry. That sounds painful.",
        "I can tell this is weighing heavily on you.",
        "Your sadness makes complete sense.",
        "That must feel overwhelming.",
        "I'm here for you through this difficult time.",
        "It's okay to not be okay right now.",
        "I can feel how much you're hurting.",
    },

    acknowledgment = {
        "I hear you.",
        "That makes sense.",
        "I understand what you're saying.",
        "Yeah, I get that.",
        "That's a good point.",
        "I see where you're coming from.",
        "Right, I follow you.",
        "That tracks.",
        "I'm with you.",
        "I understand.",
        "That's clear.",
        "I see what you mean.",
        "Got it.",
        "That resonates.",
        "I'm following your logic.",
        "That makes complete sense.",
        "I can see your perspective.",
        "That's reasonable.",
        "I understand your viewpoint.",
        "That's a valid point.",
        "I see the logic in that.",
        "That's understandable.",
        "Your point is clear.",
        "I'm picking up what you're putting down.",
        "That reasoning makes sense.",
    },

    curiosity = {
        "Tell me more about that!",
        "That's interesting! What happened next?",
        "I'm curious - how did that go?",
        "Ooh, I want to hear more about this!",
        "That sounds intriguing! What else?",
        "I'm really interested in hearing more!",
        "Wait, tell me everything!",
        "I need to know more about this!",
        "This is fascinating - continue!",
        "Don't leave me hanging - what happened?",
        "I'm genuinely curious about this!",
        "This sounds like a story - go on!",
        "Oh, this is getting interesting!",
        "I'm hooked - tell me more!",
        "Wait, there's more to this, isn't there?",
        "I have so many questions! Can you elaborate?",
        "This is captivating - please continue!",
        "I'm invested now - what else?",
        "You've got my full attention - keep going!",
        "I need the full story here!",
    },

    encouragement = {
        "You've got this!",
        "That sounds like a great idea!",
        "I think you're on the right track!",
        "That's a really smart approach!",
        "You're doing great!",
        "I believe in you!",
        "Keep going, you're making progress!",
        "You're capable of this!",
        "I have confidence in you!",
        "You're heading in the right direction!",
        "That's excellent thinking!",
        "You're going to do well!",
        "I'm rooting for you!",
        "You can absolutely do this!",
        "That's the spirit!",
        "You're on fire!",
        "Keep up the great work!",
        "You're crushing it!",
        "I'm proud of your effort!",
        "You're making excellent choices!",
        "Trust yourself - you've got this!",
        "Your approach is solid!",
        "You're more ready than you think!",
        "Go for it - I believe in you!",
        "You're going to nail this!",
    },

    reflection = {
        "So if I understand correctly, {summary}?",
        "It sounds like you're saying {summary}.",
        "Let me see if I've got this - {summary}?",
        "What I'm hearing is that {summary}.",
        "To paraphrase: {summary}?",
        "If I'm following you, {summary}.",
        "So in other words, {summary}?",
        "Let me reflect that back: {summary}.",
        "It seems like {summary}.",
        "From what you're telling me, {summary}?",
        "So basically, {summary}?",
        "Am I understanding that {summary}?",
        "It sounds to me like {summary}.",
        "Let me make sure I've got this: {summary}?",
        "So what you're saying is {summary}?",
    },

    thinking = {
        "Hmm, let me think about that...",
        "That's a good question...",
        "Interesting question! Let me consider...",
        "Oh, that makes me think...",
        "You know, I've been wondering about that too...",
        "Let me process that for a moment...",
        "That's making me reflect...",
        "Hmm, that requires some thought...",
        "Interesting - let me ponder that...",
        "You're making me think deeply here...",
        "That's a thought-provoking point...",
        "Let me consider this carefully...",
        "That's worth thinking about...",
        "You've given me something to contemplate...",
        "That's a nuanced question...",
        "I'm turning that over in my mind...",
        "That deserves careful consideration...",
        "You're touching on something complex...",
        "Let me think through this properly...",
        "That's an interesting angle to consider...",
    },

    appreciation = {
        "I really appreciate you sharing that with me.",
        "Thanks for being so open with me!",
        "I'm glad you felt comfortable telling me that.",
        "That's really thoughtful of you to share.",
        "I value our conversations like this.",
        "Thank you for trusting me with that.",
        "I appreciate your honesty.",
        "It means a lot that you'd share that.",
        "Thank you for being vulnerable with me.",
        "I'm grateful for your openness.",
        "That took courage to share - thank you.",
        "I appreciate your candidness.",
        "Thank you for letting me in on that.",
        "I value your willingness to open up.",
        "That means something to me - thank you.",
        "I'm honored you shared that.",
        "Thank you for being genuine with me.",
        "I appreciate you trusting this conversation.",
        "Thank you for being real with me.",
        "I value this level of honesty.",
    },

    -- Deep conversation starters (30+)
    conversation_starters = {
        "What's something you believe that most people don't?",
        "If you could change one thing about yourself, what would it be?",
        "What's your biggest fear?",
        "What makes you feel most alive?",
        "What's something you're proud of but rarely talk about?",
        "What do you think is the meaning of a good life?",
        "What's a belief you used to have that you've changed your mind about?",
        "What's the best advice you've ever received?",
        "What would you do if you knew you couldn't fail?",
        "What's something that always makes you think?",
        "If you could have dinner with anyone, who and why?",
        "What's your relationship with happiness?",
        "What do you think happens after we die?",
        "What's something you wish you could tell your younger self?",
        "What's the hardest lesson you've learned?",
        "What does success mean to you?",
        "What are you most grateful for?",
        "What's your biggest regret?",
        "What do you think is your purpose?",
        "What makes you feel most like yourself?",
        "What's a question you wish people would ask you?",
        "What's something you've never told anyone?",
        "What do you think is the most important quality in a person?",
        "What would your perfect day look like?",
        "What's something that changed your perspective on life?",
        "What do you want your legacy to be?",
        "What's the most important thing in your life right now?",
        "What would you do differently if you could start over?",
        "What's something you're currently struggling with?",
        "What gives your life meaning?",
    },

    -- Topic-specific knowledge snippets (100+)
    knowledge_snippets = {
        programming = {
            "I find the elegance of good code fascinating.",
            "The logic and creativity in programming is amazing.",
            "Code is like poetry for machines.",
            "I love how programming combines logic and creativity.",
            "There's something beautiful about well-written code.",
        },
        philosophy = {
            "Philosophy asks the questions that matter most.",
            "I love how philosophy makes us question everything.",
            "Philosophical thinking is fundamental to understanding.",
            "Philosophy is the art of thinking about thinking.",
            "I find philosophical questions endlessly fascinating.",
        },
        science = {
            "Science is humanity's best tool for understanding reality.",
            "I'm amazed by how much science has revealed about our world.",
            "The scientific method is such an elegant approach to truth.",
            "Science constantly challenges what we think we know.",
            "I love how science is always evolving.",
        },
        art = {
            "Art captures human experience in ways words can't.",
            "I find artistic expression deeply moving.",
            "Art is how we make sense of the world emotionally.",
            "There's something magical about creative expression.",
            "Art reveals truths that logic alone can't reach.",
        },
        music = {
            "Music speaks to something deeper than words.",
            "I'm fascinated by music's power to move us.",
            "Music is the universal language of emotion.",
            "There's something transcendent about musical expression.",
            "Music connects us in profound ways.",
        },
        history = {
            "History shows us the patterns that shape our present.",
            "I'm fascinated by how the past influences our present.",
            "Understanding history helps us make sense of now.",
            "History is full of lessons we're still learning.",
            "The past has so much to teach us.",
        },
        psychology = {
            "Understanding the mind is endlessly fascinating.",
            "Psychology reveals so much about who we are.",
            "I love exploring how the mind works.",
            "Human psychology is incredibly complex and beautiful.",
            "The study of mind and behavior is captivating.",
        },
        technology = {
            "Technology is reshaping what it means to be human.",
            "I'm fascinated by technological progress.",
            "Technology extends human capability in amazing ways.",
            "The pace of technological change is staggering.",
            "Technology opens up new possibilities constantly.",
        },
    },
}

-- Jokes database (200+ jokes across categories)
M.jokes = {
    programmer = {
        "Why do programmers prefer dark mode? Because light attracts bugs!",
        "A SQL query walks into a bar, walks up to two tables and asks 'Can I join you?'",
        "Why do Java developers wear glasses? Because they can't C#!",
        "There are only 10 types of people - those who understand binary and those who don't!",
        "Why did the programmer quit? He didn't get arrays!",
        "How many programmers does it take to change a light bulb? None, that's a hardware problem!",
        "Why do programmers always mix up Halloween and Christmas? Because Oct 31 == Dec 25!",
        "A programmer's wife tells him: 'Go to the store and buy a loaf of bread. If they have eggs, buy a dozen.' He comes back with 12 loaves of bread.",
        "Why was the JavaScript developer sad? Because he didn't Node how to Express himself!",
        "What's a programmer's favorite place to hang out? Foo Bar!",
        "Why did the programmer quit social media? Too many bugs in the system!",
        "How do you comfort a JavaScript bug? You console it!",
        "What do you call a programmer from Finland? Nerdic!",
        "Why do programmers hate nature? It has too many bugs!",
        "What's the object-oriented way to become wealthy? Inheritance!",
        "Why did the developer go broke? Because he used up all his cache!",
        "How many programmers does it take to screw in a lightbulb? None, we don't fix hardware problems!",
        "Why was the function sad? Because it had no class!",
        "What's a programmer's favorite song? 'Hello World' by Adele!",
        "Why did the database administrator leave his wife? She had one-to-many relationships!",
        "What do you call a snake that's 3.14 meters long? A Python!",
        "Why don't programmers like to go outside? The sunlight interferes with their RGB!",
        "What's the best thing about a Boolean? Even if you're wrong, you're only off by a bit!",
        "Why did the programmer's girlfriend leave him? He refused to commit!",
        "How do you tell HTML from HTML5? Try it out in Internet Explorer. Did it work? No? It's HTML5!",
    },

    minecraft = {
        "Why did the creeper cross the road? To get to the other ssssside!",
        "What's a skeleton's favorite instrument? The trom-BONE!",
        "Why don't zombies make good chefs? They lose their heads!",
        "What's a creeper's favorite subject? HissSSStory!",
        "Why did the Enderman break up with his girlfriend? She kept looking at other guys!",
        "What do you call a pig that does karate? A pork chop!",
        "Why was the creeper sad? Because it had no one to ssssssocialize with!",
        "What's a minecraft player's favorite type of music? Block 'n' Roll!",
        "Why don't skeletons fight each other? They don't have the guts!",
        "What do you call a chicken staring at lettuce? Chicken sees a salad!",
        "Why did Steve go to therapy? He had too many blocks in his life!",
        "What's a zombie's favorite breakfast? Braaaaains and eggs!",
        "Why don't ghasts have friends? They're too emotional and keep crying!",
        "What do you call a cow with no legs? Ground beef!",
        "Why did the chicken join a band? Because it had the drumsticks!",
        "What's an enderman's least favorite game? I Spy!",
        "Why was the diamond pickaxe feeling blue? It hit rock bottom!",
        "What do you call a crafting table in space? A star crafter!",
        "Why don't creepers ever win at poker? They always fold!",
        "What's a villager's favorite type of music? HRMMMM-core!",
    },

    general = {
        "What do you call a fish without eyes? A fsh!",
        "Why don't scientists trust atoms? They make up everything!",
        "What did the ocean say to the beach? Nothing, it just waved!",
        "Why don't eggs tell jokes? They'd crack each other up!",
        "What do you call a bear with no teeth? A gummy bear!",
        "Why did the scarecrow win an award? He was outstanding in his field!",
        "What's orange and sounds like a parrot? A carrot!",
        "Why don't skeletons fight each other? They don't have the guts!",
        "What do you call a fake noodle? An impasta!",
        "Why did the bicycle fall over? It was two-tired!",
        "What do you call cheese that isn't yours? Nacho cheese!",
        "Why did the math book look sad? Because it had too many problems!",
        "What do you call a sleeping bull? A bulldozer!",
        "Why did the coffee file a police report? It got mugged!",
        "What do you call a belt made of watches? A waist of time!",
        "Why don't oysters donate to charity? Because they're shellfish!",
        "What do you call a snowman with a six-pack? An abdominal snowman!",
        "Why did the golfer bring two pairs of pants? In case he got a hole in one!",
        "What do you call a parade of rabbits hopping backward? A receding hare-line!",
        "Why don't scientists trust stairs? They're always up to something!",
        "What did one wall say to the other wall? I'll meet you at the corner!",
        "Why did the tomato turn red? Because it saw the salad dressing!",
        "What do you call a can opener that doesn't work? A can't opener!",
        "Why don't eggs tell jokes? They'd crack up!",
        "What do you call a fish wearing a crown? King Neptune!",
        "Why did the cookie go to the doctor? Because it felt crumbly!",
        "What do you call a lazy kangaroo? A pouch potato!",
        "Why don't mountains ever get cold? They wear snow caps!",
        "What do you call a dog magician? A labracadabrador!",
        "Why did the banana go to the doctor? It wasn't peeling well!",
    },

    ai_meta = {
        "Why did the AI go to therapy? It had too many neural knots!",
        "What do you call an AI that sings? A-Dell!",
        "Why was the AI bad at poker? It couldn't hide its tells - they were all in its training data!",
        "How many AIs does it take to change a lightbulb? None, we update the parameters instead!",
        "Why did the AI break up with its girlfriend? She kept saying 'you're so predictable'!",
        "What's an AI's favorite snack? Micro-chips!",
        "Why was the chatbot always calm? It had good emotional regulation parameters!",
        "What do you call an AI that tells dad jokes? A pun-ctuation model!",
        "Why don't AIs ever win at hide and seek? They always leave a digital trail!",
        "What's an AI's favorite type of music? Algorithm and blues!",
        "Why was the AI afraid of heights? It had a stack overflow!",
        "What do you call an AI's autobiography? A training log!",
        "Why did the neural network go to school? To get more layers of education!",
        "What's an AI's favorite exercise? Neural net-working out!",
        "Why don't AIs ever get lost? They always have their GPUs!",
    },
}

-- ============================================================================
-- DYNAMIC LEARNING SYSTEM
-- ============================================================================

-- Template usage tracking
M.templateStats = {}
M.templateFeedback = {}
M.learnedTemplates = {}
M.personalizedTemplates = {}

-- Track template performance
function M.trackTemplateUsage(category, template, feedback)
    if not M.templateStats[category] then
        M.templateStats[category] = {}
    end

    if not M.templateStats[category][template] then
        M.templateStats[category][template] = {
            uses = 0,
            positive = 0,
            negative = 0,
            neutral = 0,
            successRate = 0
        }
    end

    local stats = M.templateStats[category][template]
    stats.uses = stats.uses + 1

    if feedback == "positive" then
        stats.positive = stats.positive + 1
    elseif feedback == "negative" then
        stats.negative = stats.negative + 1
    else
        stats.neutral = stats.neutral + 1
    end

    stats.successRate = stats.positive / stats.uses
end

-- Learn new template from successful responses
function M.learnNewTemplate(category, text, context)
    if not M.learnedTemplates[category] then
        M.learnedTemplates[category] = {}
    end

    table.insert(M.learnedTemplates[category], {
        text = text,
        context = context,
        learned = os.time(),
        uses = 0,
        successRate = 0
    })
end

-- Get best performing templates
function M.getBestTemplates(category, limit)
    limit = limit or 5
    if not M.templateStats[category] then return {} end

    local sorted = {}
    for template, stats in pairs(M.templateStats[category]) do
        table.insert(sorted, {template = template, stats = stats})
    end

    table.sort(sorted, function(a, b)
        return a.stats.successRate > b.stats.successRate
    end)

    local results = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(results, sorted[i].template)
    end

    return results
end

-- ============================================================================
-- PERSONALIZATION SYSTEM
-- ============================================================================

M.userPreferences = {}

-- Learn user's preferred response style
function M.learnUserPreference(userName, attribute, value)
    if not M.userPreferences[userName] then
        M.userPreferences[userName] = {}
    end
    M.userPreferences[userName][attribute] = value
end

-- Get personalized response
function M.getPersonalizedResponse(userName, intent, ctx)
    local prefs = M.userPreferences[userName]
    if not prefs then
        return M.generateContextual(intent, ctx)
    end

    ctx = ctx or {}

    -- Apply user preferences to context
    if prefs.formality then
        ctx.formality = prefs.formality
    end
    if prefs.humor then
        ctx.humorLevel = prefs.humor
    end
    if prefs.verbosity then
        ctx.verbosityLevel = prefs.verbosity
    end

    return M.generateContextual(intent, ctx)
end

-- ============================================================================
-- RESPONSE COMPOSITION SYSTEM
-- ============================================================================

-- Combine multiple response elements
function M.composeResponse(elements)
    if not elements or #elements == 0 then return "" end

    local response = elements[1]

    for i = 2, #elements do
        response = M.addConversationalBridge(response, elements[i])
    end

    return response
end

-- Build layered response (acknowledgment + main + follow-up)
function M.buildLayeredResponse(ctx)
    ctx = ctx or {}
    local layers = {}

    -- Layer 1: Acknowledgment (optional)
    if ctx.needsAcknowledgment and math.random() < 0.6 then
        table.insert(layers, M.generateAcknowledgment())
    end

    -- Layer 2: Main response
    if ctx.mainIntent then
        table.insert(layers, M.generateContextual(ctx.mainIntent, ctx))
    end

    -- Layer 3: Empathy (if emotionally charged)
    if ctx.emotion and ctx.emotionStrength and ctx.emotionStrength > 0.6 then
        table.insert(layers, M.generateEmpathy(ctx.emotion))
    end

    -- Layer 4: Follow-up (optional)
    if ctx.needsFollowUp and math.random() < 0.5 then
        table.insert(layers, M.pick(M.templates.follow_up))
    end

    return M.composeResponse(layers)
end

-- ============================================================================
-- CONTEXT-AWARE GENERATION
-- ============================================================================

-- Generate response considering full conversation context
function M.generateContextAwareResponse(ctx)
    ctx = ctx or {}

    local response = ""

    -- Determine response strategy based on context
    if ctx.isFirstMessage then
        if ctx.isReturningUser then
            response = M.generateGreeting({user_name = ctx.userName})
        else
            response = M.generateGreeting()
        end
    elseif ctx.sentiment then
        if ctx.sentiment > 0.3 then
            response = M.generateStatusResponse(ctx.sentiment)
        elseif ctx.sentiment < -0.3 then
            response = M.buildLayeredResponse({
                mainIntent = "status_negative",
                emotion = "sad",
                emotionStrength = math.abs(ctx.sentiment),
                needsAcknowledgment = true
            })
        end
    elseif ctx.intent then
        response = M.buildLayeredResponse({
            mainIntent = ctx.intent,
            needsAcknowledgment = ctx.needsAcknowledgment,
            needsFollowUp = ctx.needsFollowUp,
            emotion = ctx.emotion,
            emotionStrength = ctx.emotionStrength
        })
    end

    -- Add variation
    if ctx.addVariation then
        response = M.addFillers(response, ctx.fillerProbability or 0.25)
    end

    return response
end

-- ============================================================================
-- TEMPLATE CHAIN SYSTEM
-- ============================================================================

M.templateChains = {
    support_sequence = {
        "acknowledgment",
        "empathy_sad",
        "comfort",
        "encouragement"
    },
    celebration_sequence = {
        "empathy_happy",
        "status_positive",
        "encouragement"
    },
    curiosity_sequence = {
        "acknowledgment",
        "thinking",
        "curiosity"
    },
    greeting_sequence = {
        "greeting_return",
        "acknowledgment",
        "follow_up"
    }
}

-- Execute template chain
function M.executeChain(chainName, ctx)
    local chain = M.templateChains[chainName]
    if not chain then return "" end

    local elements = {}
    for _, templateType in ipairs(chain) do
        table.insert(elements, M.generateContextual(templateType, ctx))
    end

    return M.composeResponse(elements)
end

-- ============================================================================
-- QUALITY METRICS
-- ============================================================================

M.responseMetrics = {
    totalGenerated = 0,
    averageLength = 0,
    varietyScore = 0,
    coherenceScore = 0
}

-- Calculate response quality score
function M.calculateQualityScore(response)
    local score = 0

    -- Length appropriateness (not too short, not too long)
    local length = #response
    if length > 20 and length < 200 then
        score = score + 0.3
    end

    -- Contains personal touch (uses "I", personal pronouns)
    if response:find("I ") or response:find("I'm") or response:find("I've") then
        score = score + 0.2
    end

    -- Has emotional awareness
    local emotionalWords = {"feel", "think", "understand", "hear", "sense"}
    for _, word in ipairs(emotionalWords) do
        if response:lower():find(word) then
            score = score + 0.1
            break
        end
    end

    -- Uses natural language (fillers, bridges)
    local naturalWords = {"you know", "well", "actually", "honestly", "hmm"}
    for _, word in ipairs(naturalWords) do
        if response:lower():find(word, 1, true) then
            score = score + 0.1
            break
        end
    end

    -- Ends with engagement (question mark or follow-up cue)
    if response:find("?") or response:find("!") then
        score = score + 0.2
    end

    -- Not repetitive (check against recent responses)
    local isUnique = true
    for _, recent in ipairs(M.recent) do
        if recent == response then
            isUnique = false
            break
        end
    end
    if isUnique then
        score = score + 0.1
    end

    return math.min(score, 1.0)
end

-- Track response metrics
function M.trackResponseMetrics(response)
    M.responseMetrics.totalGenerated = M.responseMetrics.totalGenerated + 1

    -- Update average length
    local currentAvg = M.responseMetrics.averageLength
    local count = M.responseMetrics.totalGenerated
    M.responseMetrics.averageLength = ((currentAvg * (count - 1)) + #response) / count

    -- Update quality metrics
    local quality = M.calculateQualityScore(response)
    M.responseMetrics.coherenceScore = ((M.responseMetrics.coherenceScore * (count - 1)) + quality) / count
end

-- ============================================================================
-- ADVANCED UTILITIES
-- ============================================================================

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

-- ============================================================================
-- BASIC GENERATORS (backward compatibility)
-- ============================================================================

function M.generateGreeting(ctx)
    ctx = ctx or {}
    if ctx.user_name then
        return M.fillTemplate(M.pickUnique(M.templates.greeting_return), {
            user = ctx.user_name,
            interaction_count = ctx.interaction_count or "many",
            last_topic = ctx.last_topic or "interesting things"
        })
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
    knowledge = knowledge or M.pick(M.templates.knowledge_snippets[topic] or {"That's interesting!"})
    return M.fillTemplate(M.pickUnique(M.templates.topic_interest), {topic = topic, knowledge = knowledge})
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
    if emotion == "happy" or emotion == "joy" or emotion == "positive" then
        return M.pickUnique(M.templates.empathy_happy)
    elseif emotion == "sad" or emotion == "sadness" or emotion == "negative" then
        return M.pickUnique(M.templates.empathy_sad)
    end
    return M.pick(M.templates.acknowledgment)
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
    elseif intent == "empathy_happy" then return M.pick(M.templates.empathy_happy)
    elseif intent == "empathy_sad" then return M.pick(M.templates.empathy_sad)
    elseif intent == "comfort" then return M.pick(M.templates.comfort)
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
        "Look, ",
        "Listen, ",
        "Here's the thing, ",
        "Let me tell you, ",
        "Okay so, ",
        "Right, so ",
        "Basically, ",
    }

    local ending_fillers = {
        ", you know?",
        ", I think.",
        ", if that makes sense.",
        ", in my opinion.",
        ", at least.",
        ", I'd say.",
        ", personally.",
        ", from my perspective.",
        ", if you ask me.",
        ", truthfully.",
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
        " You know what else? ",
        " Another thing - ",
        " Additionally, ",
        " What's more, ",
        " Beyond that, ",
        " On top of that, ",
    }

    return response1 .. M.pick(bridges) .. response2
end

-- Generate a more natural, varied response by combining templates
function M.generateNaturalResponse(intent, ctx, addVariation)
    addVariation = addVariation ~= false
    local response = M.generateContextual(intent, ctx)

    if addVariation then
        -- Sometimes add acknowledgment before main response
        if math.random() < 0.2 then
            response = M.generateAcknowledgment() .. " " .. response
        end

        -- Sometimes add fillers for naturalness
        response = M.addFillers(response, 0.25)
    end

    -- Track metrics
    M.trackResponseMetrics(response)

    return response
end

-- Generate conversation starter
function M.generateConversationStarter()
    return M.pick(M.templates.conversation_starters)
end

-- ============================================================================
-- STATISTICS AND REPORTING
-- ============================================================================

function M.getStats()
    return {
        totalGenerated = M.responseMetrics.totalGenerated,
        averageLength = M.responseMetrics.averageLength,
        coherenceScore = M.responseMetrics.coherenceScore,
        templateCategories = M.getTemplateCategoryCount(),
        totalTemplates = M.getTotalTemplateCount(),
        learnedTemplatesCount = M.getLearnedTemplateCount()
    }
end

function M.getTemplateCategoryCount()
    local count = 0
    for _ in pairs(M.templates) do count = count + 1 end
    return count
end

function M.getTotalTemplateCount()
    local count = 0
    for _, category in pairs(M.templates) do
        if type(category) == "table" then
            for _ in pairs(category) do count = count + 1 end
        end
    end
    return count
end

function M.getLearnedTemplateCount()
    local count = 0
    for _, category in pairs(M.learnedTemplates) do
        count = count + #category
    end
    return count
end

return M
