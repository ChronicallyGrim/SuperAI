-- raid_system.lua
-- RAID 0 (Striping) across 4 drives for maximum capacity
-- RIGHT (2 drives) + BOTTOM (2 drives) = 4-drive RAID array

local M = {}

-- Detect RAID drives (using peripheral.find for wired networks)
local function detectRAIDDrives()
    local all_drives = {peripheral.find("drive")}
    local raid_drives = {}
    
    -- Categorize drives by their location
    -- We want RIGHT and BOTTOM drives for RAID
    for _, drive_wrap in ipairs(all_drives) do
        local name = peripheral.getName(drive_wrap)
        
        -- Check if it's on RIGHT or BOTTOM side
        if name:match("^right_") or name:match("^bottom_") then
            table.insert(raid_drives, name)
        end
    end
    
    return raid_drives
end

-- Initialize RAID array
local RAID_DRIVES = {}
local RAID_INITIALIZED = false

function M.init()
    RAID_DRIVES = detectRAIDDrives()
    
    if #RAID_DRIVES < 2 then
        error("RAID 0 requires at least 2 drives! Found: " .. #RAID_DRIVES)
    end
    
    print("RAID 0 initialized with " .. #RAID_DRIVES .. " drives:")
    for i, drive in ipairs(RAID_DRIVES) do
        print("  [" .. i .. "] " .. drive)
    end
    
    -- Create RAID metadata directory on each drive
    for _, drive in ipairs(RAID_DRIVES) do
        if not fs.exists(drive .. "/raid_meta") then
            fs.makeDir(drive .. "/raid_meta")
        end
    end
    
    RAID_INITIALIZED = true
    return #RAID_DRIVES
end

-- RAID 0 Write: Split data across drives in chunks
-- Chunk size: 4KB (4096 bytes)
local CHUNK_SIZE = 4096

function M.write(filepath, data)
    if not RAID_INITIALIZED then
        M.init()
    end
    
    if #RAID_DRIVES == 0 then
        error("No RAID drives available!")
    end
    
    local data_length = #data
    local num_chunks = math.ceil(data_length / CHUNK_SIZE)
    
    -- Write metadata to drive 0 (track which drives have which chunks)
    local meta = {
        filepath = filepath,
        total_chunks = num_chunks,
        chunk_size = CHUNK_SIZE,
        data_length = data_length,
        drives_used = {}
    }
    
    -- Write chunks in round-robin across drives (RAID 0 striping)
    for chunk_idx = 0, num_chunks - 1 do
        local drive_idx = (chunk_idx % #RAID_DRIVES) + 1
        local drive = RAID_DRIVES[drive_idx]
        
        local chunk_start = chunk_idx * CHUNK_SIZE + 1
        local chunk_end = math.min(chunk_start + CHUNK_SIZE - 1, data_length)
        local chunk_data = data:sub(chunk_start, chunk_end)
        
        -- Write chunk to drive
        local chunk_path = drive .. "/raid_data/" .. filepath .. ".chunk" .. chunk_idx
        
        -- Create directory if needed
        local dir = chunk_path:match("(.*/)")
        if dir and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        local f = fs.open(chunk_path, "w")
        f.write(chunk_data)
        f.close()
        
        table.insert(meta.drives_used, {drive = drive, chunk = chunk_idx})
    end
    
    -- Save metadata
    local meta_path = RAID_DRIVES[1] .. "/raid_meta/" .. filepath:gsub("/", "_") .. ".meta"
    local meta_dir = meta_path:match("(.*/)")
    if meta_dir and not fs.exists(meta_dir) then
        fs.makeDir(meta_dir)
    end
    
    local mf = fs.open(meta_path, "w")
    mf.write(textutils.serialize(meta))
    mf.close()
    
    return true
end

-- RAID 0 Read: Reassemble data from chunks across drives
function M.read(filepath)
    if not RAID_INITIALIZED then
        M.init()
    end
    
    -- Read metadata
    local meta_path = RAID_DRIVES[1] .. "/raid_meta/" .. filepath:gsub("/", "_") .. ".meta"
    
    if not fs.exists(meta_path) then
        return nil  -- File doesn't exist
    end
    
    local mf = fs.open(meta_path, "r")
    local meta = textutils.unserialize(mf.readAll())
    mf.close()
    
    if not meta then
        return nil
    end
    
    -- Reassemble data from chunks
    local data_parts = {}
    
    for chunk_idx = 0, meta.total_chunks - 1 do
        local drive_idx = (chunk_idx % #RAID_DRIVES) + 1
        local drive = RAID_DRIVES[drive_idx]
        local chunk_path = drive .. "/raid_data/" .. filepath .. ".chunk" .. chunk_idx
        
        if fs.exists(chunk_path) then
            local f = fs.open(chunk_path, "r")
            local chunk_data = f.readAll()
            f.close()
            table.insert(data_parts, chunk_data)
        else
            error("RAID 0 FAILURE: Missing chunk " .. chunk_idx .. " on " .. drive)
        end
    end
    
    return table.concat(data_parts)
end

-- Delete file from RAID
function M.delete(filepath)
    if not RAID_INITIALIZED then
        M.init()
    end
    
    -- Read metadata to find all chunks
    local meta_path = RAID_DRIVES[1] .. "/raid_meta/" .. filepath:gsub("/", "_") .. ".meta"
    
    if not fs.exists(meta_path) then
        return false
    end
    
    local mf = fs.open(meta_path, "r")
    local meta = textutils.unserialize(mf.readAll())
    mf.close()
    
    -- Delete all chunks
    for chunk_idx = 0, meta.total_chunks - 1 do
        local drive_idx = (chunk_idx % #RAID_DRIVES) + 1
        local drive = RAID_DRIVES[drive_idx]
        local chunk_path = drive .. "/raid_data/" .. filepath .. ".chunk" .. chunk_idx
        
        if fs.exists(chunk_path) then
            fs.delete(chunk_path)
        end
    end
    
    -- Delete metadata
    fs.delete(meta_path)
    
    return true
end

-- Check if file exists in RAID
function M.exists(filepath)
    if not RAID_INITIALIZED then
        M.init()
    end
    
    local meta_path = RAID_DRIVES[1] .. "/raid_meta/" .. filepath:gsub("/", "_") .. ".meta"
    return fs.exists(meta_path)
end

-- List files in RAID
function M.list(directory)
    if not RAID_INITIALIZED then
        M.init()
    end
    
    local files = {}
    local meta_dir = RAID_DRIVES[1] .. "/raid_meta"
    
    if not fs.exists(meta_dir) then
        return files
    end
    
    local function scanDir(dir)
        local items = fs.list(dir)
        for _, item in ipairs(items) do
            local path = dir .. "/" .. item
            if fs.isDir(path) then
                scanDir(path)
            elseif item:match("%.meta$") then
                -- Extract original filepath from metadata filename
                local original = item:gsub("%.meta$", ""):gsub("_", "/")
                if not directory or original:match("^" .. directory) then
                    table.insert(files, original)
                end
            end
        end
    end
    
    scanDir(meta_dir)
    return files
end

-- Get RAID statistics
function M.stats()
    if not RAID_INITIALIZED then
        M.init()
    end
    
    local total_space = 0
    local used_space = 0
    local free_space = 0
    
    for _, drive in ipairs(RAID_DRIVES) do
        if fs.exists(drive) then
            local drive_free = fs.getFreeSpace(drive)
            local drive_capacity = fs.getCapacity(drive)
            
            free_space = free_space + drive_free
            total_space = total_space + drive_capacity
            used_space = used_space + (drive_capacity - drive_free)
        end
    end
    
    return {
        drives = #RAID_DRIVES,
        total_space = total_space,
        used_space = used_space,
        free_space = free_space,
        capacity_mb = total_space / (1024 * 1024)
    }
end

-- Simple file operations (wrappers for common use)
function M.writeFile(path, content)
    return M.write(path, content)
end

function M.readFile(path)
    return M.read(path)
end

function M.deleteFile(path)
    return M.delete(path)
end

return M
