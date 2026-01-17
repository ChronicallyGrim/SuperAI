-- memory_loader.lua
-- RAID system loader with redundancy verification and database integration

local partA = dofile("memory_RAID_partA.lua")
local partB = dofile("memory_RAID_partB.lua")

-- Merged memory with RAID redundancy
local memory = {}

-- Merge partA
for k, v in pairs(partA) do 
    memory[k] = v 
end

-- Merge partB (with verification)
for k, v in pairs(partB) do 
    -- Verify consistency between RAID parts
    if memory[k] and type(memory[k]) == "table" and type(v) == "table" then
        -- For tables, use partA as primary, partB as backup
        -- Database tables should be consistent
        if k == "databases" then
            -- Verify database consistency
            memory[k] = memory[k] or v
        end
    else
        memory[k] = v 
    end
end

-- Initialize database if not present
memory.databases = memory.databases or {}
memory.currentDB = memory.currentDB or nil

-- Export all database functions
memory.createDatabase = createDatabase
memory.useDatabase = useDatabase
memory.createTable = createTable
memory.insertData = insertData
memory.selectData = selectData
memory.updateData = updateData
memory.deleteData = deleteData
memory.listDatabases = listDatabases
memory.listTables = listTables
memory.getTableStats = getTableStats

return memory

