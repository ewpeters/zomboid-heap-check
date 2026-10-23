-- HeapWarning shared config.
-- The threshold lives in a sandbox option so the server owner sets it and it
-- syncs to every client automatically (no custom network traffic needed).

HeapWarning = HeapWarning or {}
HeapWarning.VERSION = "0.1.0"

local DEFAULT_MIN_HEAP_MB = 4096

-- Minimum acceptable JVM max heap (-Xmx) in MB, from the server's sandbox vars.
-- 0 disables the check (treated as "no minimum").
function HeapWarning.getMinHeapMB()
    local sv = SandboxVars and SandboxVars.HeapWarning
    if not sv then return DEFAULT_MIN_HEAP_MB end
    local v = sv.MinHeapMB
    if v == nil then return DEFAULT_MIN_HEAP_MB end
    if v < 0 then return DEFAULT_MIN_HEAP_MB end
    return v
end

-- Read this JVM's configured max heap (-Xmx) in MB.
-- There is no vanilla Lua API for this, so we reflect into java.lang.Runtime.
-- Kahlua exposes Java statics via the global class path; maxMemory() returns
-- bytes. Everything is pcall-guarded: if the reflection isn't available we
-- return nil and the caller skips the warning rather than erroring.
-- Returns: number (MB) on success, or nil if it couldn't be read.
function HeapWarning.getMaxHeapMB()
    local ok, bytes = pcall(function()
        return Runtime.getRuntime():maxMemory()
    end)
    if not ok or bytes == nil then
        return nil
    end
    -- maxMemory() returns a Java long; divide to MB.
    local mb = tonumber(bytes) / (1024 * 1024)
    if mb == nil or mb <= 0 then
        return nil
    end
    return math.floor(mb + 0.5)
end

return HeapWarning
