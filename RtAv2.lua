-- RtAv2.lua (Pure Lua Implementation)
-- Replaces RtAv2.dll for AviUtl2 (64-bit) compatibility
-- Includes LuaJIT FFI safe file IO for Windows UTF-8/Japanese paths

local RtAv2 = {}

local ffi = nil
pcall(function() ffi = require("ffi") end)

-- Declare kernel32 for MultiByteToWideChar
local kernel32 = nil
if ffi then
    pcall(function() kernel32 = ffi.load("kernel32") end)
end

-- Declare C runtime (msvcrt) for _wfopen, fclose, fread, fseek, ftell
local msvcrt = nil
if ffi then
    pcall(function() msvcrt = ffi.load("msvcrt") end)
    if not msvcrt then
        pcall(function() msvcrt = ffi.load("ucrtbase") end)
    end
end

-- Safe print helper utilizing AviUtl2's native log print
local print = _G.print or function() end

-- Initialize first log
print("RtAv2 - 読み込み完了")

-- Utility to split string
local function split(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

-- Clean surrounding double quotes from path
local function clean_path(path)
    if not path then return nil end
    local cleaned = path:gsub('^"', ''):gsub('"$', '')
    return cleaned
end

-- FFI safe file reader for Windows UTF-8 paths
local function read_file_utf8(path)
    if not ffi or not kernel32 or not msvcrt then
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return content
    end
    
    local success, result = pcall(function()
        ffi.cdef[[
            typedef unsigned short wchar_t;
            typedef struct FILE FILE;
            FILE * _wfopen(const wchar_t * filename, const wchar_t * mode);
            int fclose(FILE * stream);
            size_t fread(void * ptr, size_t size, size_t nmemb, FILE * stream);
            int fseek(FILE * stream, long offset, int whence);
            long ftell(FILE * stream);
            int MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char * lpMultiByteStr, int cbMultiByte, wchar_t * lpWideCharStr, int cchWideChar);
        ]]
        
        local CP_UTF8 = 65001
        local wlen = kernel32.MultiByteToWideChar(CP_UTF8, 0, path, -1, nil, 0)
        if wlen <= 0 then return nil end
        
        local wpath = ffi.new("wchar_t[?]", wlen)
        kernel32.MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, wlen)
        
        local wmode = ffi.new("wchar_t[2]")
        wmode[0] = string.byte('r')
        wmode[1] = 0
        
        local fp = msvcrt._wfopen(wpath, wmode)
        if fp == nil then return nil end
        
        msvcrt.fseek(fp, 0, 2)
        local size = msvcrt.ftell(fp)
        msvcrt.fseek(fp, 0, 0)
        
        if size <= 0 then
            msvcrt.fclose(fp)
            return ""
        end
        
        local buf = ffi.new("char[?]", size + 1)
        local read_bytes = msvcrt.fread(buf, 1, size, fp)
        msvcrt.fclose(fp)
        
        return ffi.string(buf, read_bytes)
    end)
    
    if success and result then
        return result
    else
        if not success then
            print("FFI read failed, falling back to standard io.open. Error: " .. tostring(result))
        end
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return content
    end
end

-- Check if file exists safely
function RtAv2.isOpen(path)
    path = clean_path(path)
    if not path or path == "" then return false end
    
    if not ffi or not kernel32 or not msvcrt then
        local f = io.open(path, "r")
        if f then
            f:close()
            return true
        end
        return false
    end
    
    local success, result = pcall(function()
        ffi.cdef[[
            typedef unsigned short wchar_t;
            typedef struct FILE FILE;
            FILE * _wfopen(const wchar_t * filename, const wchar_t * mode);
            int fclose(FILE * stream);
            int MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char * lpMultiByteStr, int cbMultiByte, wchar_t * lpWideCharStr, int cchWideChar);
        ]]
        
        local CP_UTF8 = 65001
        local wlen = kernel32.MultiByteToWideChar(CP_UTF8, 0, path, -1, nil, 0)
        if wlen <= 0 then return false end
        
        local wpath = ffi.new("wchar_t[?]", wlen)
        kernel32.MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, wlen)
        
        local wmode = ffi.new("wchar_t[2]")
        wmode[0] = string.byte('r')
        wmode[1] = 0
        
        local fp = msvcrt._wfopen(wpath, wmode)
        if fp ~= nil then
            msvcrt.fclose(fp)
            return true
        end
        return false
    end)
    
    if success then
        return result
    else
        print("FFI isOpen failed, falling back to standard io.open. Error: " .. tostring(result))
        local f = io.open(path, "r")
        if f then
            f:close()
            return true
        end
        return false
    end
end

-- Parse RPP file
function RtAv2.getRpp(path)
    path = clean_path(path)
    
    print("RtAv2 - 解析開始")

    local content = read_file_utf8(path)
    if not content then 
        print("RtAv2 - 解析失敗 (ファイル読み込みに失敗しました)")
        print("RtAv2 - 解析終了")
        return nil 
    end

    print("RtAv2 - バージョンを調べています")
    
    local data = {
        tempo = 120,
        baseBpm = 120,
        track = {},
        maxitem = 0,
        version = "PureLuaFFI"
    }

    local currentTrack = nil
    local currentItem = nil
    local trackIdx = 0
    
    print("RtAv2 - テンポを調べています")
    print("RtAv2 - トラック数を調べています")
    print("RtAv2 - トラック名を調べています")
    print("RtAv2 - アイテムを調べています")
    
    for line in content:gmatch("[^\r\n]+") do
        local cleanLine = line:match("^%s*(.-)%s*$")
        
        -- Parse TEMPO
        local tempoVal = cleanLine:match("^TEMPO%s+([%d%.]+)")
        if tempoVal then
            data.tempo = tonumber(tempoVal)
        end

        -- Start TRACK
        if cleanLine:find("^%s*<TRACK") then
            trackIdx = trackIdx + 1
            currentTrack = {
                name = "Track " .. trackIdx,
                item = {}
            }
            table.insert(data.track, currentTrack)
            currentItem = nil
        end

        -- Track NAME
        if currentTrack and not currentItem and cleanLine:find("^%s*NAME%s+") then
            local name = cleanLine:match('^%s*NAME%s+"(.-)"') or cleanLine:match("^%s*NAME%s+(.*)")
            if name then
                currentTrack.name = name
            end
        end

        -- Start ITEM
        if currentTrack and cleanLine:find("^%s*<ITEM") then
            currentItem = {
                pos = 0,
                length = 0,
                pich = 0
            }
            table.insert(currentTrack.item, currentItem)
        end

        -- Item properties
        if currentItem then
            local pos = cleanLine:match("^%s*POSITION%s+([%-?%d%.]+)")
            if pos then currentItem.pos = tonumber(pos) end

            local len = cleanLine:match("^%s*LENGTH%s+([%-?%d%.]+)")
            if len then currentItem.length = tonumber(len) end

            if cleanLine:find("^%s*PLAYRATE") then
                local parts = split(cleanLine, " ")
                if #parts >= 4 then
                    currentItem.pich = tonumber(parts[4]) or 0
                end
            end
        end
    end

    print("RtAv2 - 解析終了")

    -- Write to a dedicated debug log file
    pcall(function()
        local log_path = "C:\\ProgramData\\aviutl2\\Log\\rtav2_debug.log"
        local logf = io.open(log_path, "a")
        if logf then
            logf:write(string.format("[%s] Loaded RPP: path=%s, tempo=%s, tracks=%d\n", os.date("%Y-%m-%d %H:%M:%S"), path, tostring(data.tempo), #data.track))
            for idx, tr in ipairs(data.track) do
                logf:write(string.format("  Track %d (%s): items=%d\n", idx, tr.name, #tr.item))
            end
            logf:close()
        end
    end)
    
    return data
end

function RtAv2.type(val)
    return type(val)
end

return RtAv2
