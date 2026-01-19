-- drive_config.lua
-- Configuration file mapping drive names to sides
-- Edit this file to match your physical setup

return {
    -- TOP drive (code storage) - can be nil to use computer root
    top = "top",
    
    -- LEFT drives (RAID A - permanent data storage)
    left = {"drive_30", "drive_29"},
    
    -- BACK drives (RAM A - temp storage during training)
    back = {"drive_45", "drive_43", "drive_44"},
    
    -- RIGHT drives (RAID B - permanent data storage)
    right = {"drive_32", "drive_31"},
    
    -- BOTTOM drives (RAM B - temp storage during training)
    bottom = {"drive_41", "drive_42", "drive_40"}
}
