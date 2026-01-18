-- install_trainers.lua
-- Quick installer for training programs

local GITHUB_USER = "your_username"
local GITHUB_REPO = "your_repo"

print("=== Trainer Installation ===")
print("")

-- Get GitHub info
print("What's your GitHub username?")
write("> ")
local username = read()

print("What's your repository name?")
write("> ")
local repo = read()

print("")
print("Installing trainers from " .. username .. "/" .. repo .. "...")
print("")

-- Download auto_trainer.lua
print("Downloading auto_trainer.lua...")
local url1 = "https://raw.githubusercontent.com/" .. username .. "/" .. repo .. "/main/auto_trainer.lua"
local response1 = http.get(url1)

if response1 then
    local content1 = response1.readAll()
    response1.close()
    
    local file1 = fs.open("auto_trainer.lua", "w")
    file1.write(content1)
    file1.close()
    
    print("✓ auto_trainer.lua installed!")
else
    print("✗ Failed to download auto_trainer.lua")
end

-- Download ai_vs_ai.lua
print("Downloading ai_vs_ai.lua...")
local url2 = "https://raw.githubusercontent.com/" .. username .. "/" .. repo .. "/main/ai_vs_ai.lua"
local response2 = http.get(url2)

if response2 then
    local content2 = response2.readAll()
    response2.close()
    
    local file2 = fs.open("ai_vs_ai.lua", "w")
    file2.write(content2)
    file2.close()
    
    print("✓ ai_vs_ai.lua installed!")
else
    print("✗ Failed to download ai_vs_ai.lua")
end

print("")
print("Installation complete!")
print("")
print("Run these programs:")
print("  > auto_trainer")
print("  > ai_vs_ai")
