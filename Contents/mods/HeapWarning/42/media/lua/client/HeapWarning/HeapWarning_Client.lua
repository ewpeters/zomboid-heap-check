-- HeapWarning client.
-- On connecting to a server, compare this game's JVM max heap (-Xmx) against the
-- server-configured minimum (HeapWarning.MinHeapMB). If it's below, show a
-- dismissible OK popup. It's only a notice - the player clicks OK and plays on.

require "HeapWarning/HeapWarning_Shared"

local SHOWN_THIS_SESSION = false

-- Read the JVM max heap in MB via the shared helper, which uses the
-- engine-exposed getPerformanceLocal() API. Returns nil if unavailable.
local function readMaxHeapMB()
    return HeapWarning.getMaxHeapMB()
end

local function showWarning(maxMB, minMB)
    local function fmt(n)
        -- MB -> a friendly string, with GB in parentheses.
        local gb = n / 1024
        return string.format("%d MB (~%.1f GB)", n, gb)
    end

    local text =
        "Your game is running with a small memory limit.\n\n"
        .. "Your max heap (-Xmx): " .. fmt(maxMB) .. "\n"
        .. "Recommended: " .. fmt(minMB) .. "\n\n"
        .. "Please adjust your -Xmx in ProjectZomboid64.json.\n\n"
        .. "This is just a notice - click OK to continue."

    -- Centered modal with a single OK button. No callback needed.
    local w = 480
    local h = 240
    local x = (getCore():getScreenWidth() - w) / 2
    local y = (getCore():getScreenHeight() - h) / 2
    local modal = ISModalDialog:new(x, y, w, h, text, false, nil, nil)
    modal:initialise()
    modal:addToUIManager()
    if modal.moveWithMouse ~= nil then
        modal.moveWithMouse = true
    end
end

-- Do the comparison and show the popup if the heap is below the minimum.
local function doCheck(maxMB)
    local minMB = HeapWarning.getMinHeapMB()
    if minMB <= 0 then return end -- check disabled by server

    print("[HeapWarning] max heap = " .. tostring(maxMB)
        .. " MB, minimum = " .. tostring(minMB) .. " MB")

    if maxMB < minMB then
        SHOWN_THIS_SESSION = true
        showWarning(maxMB, minMB)
    end
end

-- At OnGameStart (frame 0) the performance/stats subsystem isn't populated yet,
-- so getPerformanceLocal()["memory-max"] is nil. Arm an OnTick poller that
-- retries each tick until the stats are live, runs the check once, then removes
-- itself. Give up after MAX_TICKS so we never poll forever.
local MAX_TICKS = 300 -- ~several seconds at 60fps
local ticksWaited = 0
local pollFn -- forward declaration so the handler can remove itself

pollFn = function()
    if SHOWN_THIS_SESSION then
        Events.OnTick.Remove(pollFn)
        return
    end

    local maxMB = readMaxHeapMB()
    if maxMB ~= nil then
        Events.OnTick.Remove(pollFn)
        print("[HeapWarning] heap readable after " .. tostring(ticksWaited) .. " ticks")
        doCheck(maxMB)
        return
    end

    ticksWaited = ticksWaited + 1
    if ticksWaited >= MAX_TICKS then
        Events.OnTick.Remove(pollFn)
        print("[HeapWarning] could not read JVM max heap after "
            .. tostring(MAX_TICKS) .. " ticks; skipping check.")
    end
end

-- Arm the poller once per session. Called from multiple events because in B42
-- OnConnected does not reliably fire for a Host (listen-server) connect, whereas
-- OnGameStart fires once the player is in-world for SP/MP/Host alike.
local ARMED = false
local function armCheck(source)
    print("[HeapWarning] armCheck fired from " .. tostring(source))
    if ARMED or SHOWN_THIS_SESSION then return end
    ARMED = true
    ticksWaited = 0
    Events.OnTick.Add(pollFn)
end

Events.OnGameStart.Add(function() armCheck("OnGameStart") end)
Events.OnConnected.Add(function() armCheck("OnConnected") end)

print("[HeapWarning] client loaded (v" .. tostring(HeapWarning.VERSION)
    .. "); events registered.")

-- Console helper to verify the heap read works in-game before trusting it:
--   HeapWarning.debugPrintHeap()
function HeapWarning.debugPrintHeap()
    local maxMB = readMaxHeapMB()
    print("[HeapWarning] debug: readMaxHeapMB() = " .. tostring(maxMB) .. " MB")
    return maxMB
end
