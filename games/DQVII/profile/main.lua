-- Observe ClientRestart without changing its parameters or return value.
-- Uses the public UE4SS API; the supplied DQXIS probe informed this test plan.
local target_path = "/Script/Engine.PlayerController:ClientRestart"
local registered = false
local attempted = false
local hits = 0

local function report(message)
    print("[DQVIIProbe] " .. message .. "\n")
end

local function observe_restart()
    hits = hits + 1
    if hits <= 5 then
        report("HOOK_FIRED: ClientRestart PRE; count=" .. tostring(hits))
    end
end

local function check_hook()
    if registered then
        report("STATUS: HOOK_READY; count=" .. tostring(hits))
        return
    end
    if attempted then
        report("STATUS: registration already attempted; restart before retrying")
        return
    end

    local lookup_ok, found = pcall(function()
        local object = StaticFindObject(target_path)
        return object ~= nil and object:IsValid()
    end)
    if not lookup_ok then
        report("LOOKUP_ERROR: " .. tostring(found))
        return
    end
    if not found then
        report("WAITING: target absent; F6 retries lookup")
        return
    end
    report("LOOKUP_OK: ClientRestart")

    attempted = true
    local hook_ok, pre, post = pcall(RegisterHook, target_path, observe_restart)
    if not hook_ok then
        report("HOOK_ERROR: " .. tostring(pre))
        return
    end
    if type(pre) ~= "number" or type(post) ~= "number" then
        report("HOOK_ERROR: unexpected registration identifiers")
        return
    end
    registered = true
    report("HOOK_READY: pre=" .. tostring(pre) .. "; post=" .. tostring(post))
end

report("LUA_OK: DQVII compatibility core 0.1.0")
local bind_ok, bind_error = pcall(RegisterKeyBind, Key.F6, check_hook)
if not bind_ok then
    report("KEYBIND_ERROR: " .. tostring(bind_error))
end
check_hook()
