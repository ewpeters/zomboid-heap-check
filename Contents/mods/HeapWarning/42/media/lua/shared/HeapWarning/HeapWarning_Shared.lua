-- HeapWarning shared config.
-- The threshold lives in a sandbox option so the server owner sets it and it
-- syncs to every client automatically (no custom network traffic needed).

HeapWarning = HeapWarning or {}
HeapWarning.VERSION = "0.1.7"

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
-- B42 does not expose java.lang.Runtime or luajava to Lua (both are nil), so
-- reflection throws "attempted index of non-table: null". Instead we use the
-- engine-exposed getPerformanceLocal() global -- the same source vanilla's
-- ISStatisticsUI uses for its "Max (MB)" row. It returns a table whose
-- ["memory-max"] field is the JVM max heap already in MB.
-- Everything is pcall-guarded: if the API isn't available we return nil and the
-- caller skips the warning rather than erroring.
-- Returns: number (MB) on success, or nil if it couldn't be read.
function HeapWarning.getMaxHeapMB()
    local ok, mb = pcall(function()
        local perf = getPerformanceLocal()
        return perf and perf["memory-max"]
    end)
    if not ok or mb == nil then
        return nil
    end
    mb = tonumber(mb)
    if mb == nil or mb <= 0 then
        return nil
    end
    return math.floor(mb + 0.5)
end

return HeapWarning
