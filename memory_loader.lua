-- memory_loader.lua
local partA = dofile("memory_RAID_partA.lua")
local partB = dofile("memory_RAID_partB.lua")
local memory = {}
for k,v in pairs(partA) do memory[k]=v end
for k,v in pairs(partB) do memory[k]=v end
return memory
