-- HeapWarning client.
-- On connecting to a server, compare this game's JVM max heap (-Xmx) against the
-- server-configured minimum (HeapWarning.MinHeapMB). If it's below, show a
-- dismissible OK popup. It's only a notice - the player clicks OK and plays on.

require "HeapWarning/HeapWarning_Shared"

local SHOWN_THIS_SESSION = false

-- Try a few ways to reach java.lang.Runtime from Kahlua. PZ's Lua usually
-- exposes Java classes as bare globals (Runtime, System, ...), but we guard
-- every path so a missing one just falls through instead of erroring.
local function readMaxHeapMB()
    -- Path 1: the shared helper (bare `Runtime` global).
    local mb = HeapWarning.getMaxHeapMB()
    if mb then return mb end

    -- Path 2: luajava.bindClass, if available in this runtime.
    local ok, v = pcall(function()
        local RuntimeClass = luajava.bindClass("java.lang.Runtime")
        local bytes = RuntimeClass:getRuntime():maxMemory()
        return math.floor(tonumber(bytes) / (1024 * 1024) + 0.5)
    end)
    if ok and v and v > 0 then return v end

    return nil
end

local function showWarning(maxMB, minMB)
    local function fmt(n)
        -- MB -> a friendly string, with GB in parentheses.
        local gb = n / 1024
        return string.format("%d MB (~%.1f GB)", n, gb)
    end

    local text =
        "Your game is running with a small memory limit, which can cause stutters "
        .. "or crashes on this server.\n\n"
        .. "Your max heap (-Xmx): " .. fmt(maxMB) .. "\n"
        .. "Recommended minimum: " .. fmt(minMB) .. "\n\n"
        .. "To raise it, edit your game's JVM arguments (-Xmx) in the launcher / "
        .. "ProjectZomboid64.json and restart. This is just a notice - click OK to continue."

    -- Centered modal with a single OK button. No callback needed.
    local w = 480
    local h = 260
    local x = (getCore():getScreenWidth() - w) / 2
    local y = (getCore():getScreenHeight() - h) / 2
    local modal = ISModalDialog:new(x, y, w, h, text, false, nil, nil)
    modal:initialise()
    modal:addToUIManager()
    if modal.moveWithMouse ~= nil then
        modal.moveWithMouse = true
    end
end

local function onConnected()
    if SHOWN_THIS_SESSION then return end

    local minMB = HeapWarning.getMinHeapMB()
    if minMB <= 0 then return end -- check disabled by server

    local maxMB = readMaxHeapMB()
    if maxMB == nil then
        -- Couldn't read heap on this runtime; stay silent rather than nag.
        print("[HeapWarning] could not read JVM max heap; skipping check.")
        return
    end

    print("[HeapWarning] max heap = " .. tostring(maxMB)
        .. " MB, minimum = " .. tostring(minMB) .. " MB")

    if maxMB < minMB then
        SHOWN_THIS_SESSION = true
        showWarning(maxMB, minMB)
    end
end

Events.OnConnected.Add(onConnected)

-- Console helper to verify the heap read works in-game before trusting it:
--   HeapWarning.debugPrintHeap()
function HeapWarning.debugPrintHeap()
    local maxMB = readMaxHeapMB()
    print("[HeapWarning] debug: readMaxHeapMB() = " .. tostring(maxMB) .. " MB")
    return maxMB
end
