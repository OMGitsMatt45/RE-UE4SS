-- Temporary QA diagnostic. F7 performs read-only reflection and virtual-call checks.
-- No property writes, parameter changes, console commands or save operations.
local target_path = "/Script/Engine.PlayerController:ClientRestart"
local hits = 0
local function log(message)
    print("[DQIIIReleaseQA] " .. message .. "\n")
end

log("LUA_OK")
RegisterHook(target_path, function()
    hits = hits + 1
    if hits <= 5 then log("HOOK_FIRED: count=" .. tostring(hits)) end
end)
log("HOOK_READY")

RegisterKeyBind(Key.F6, function()
    log("STATUS: count=" .. tostring(hits))
end)

RegisterKeyBind(Key.F7, function()
    ExecuteInGameThread(function()
    local ok, err = pcall(function()
        local system = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        assert(system and system:IsValid(), "System library CDO missing")
        local full_name = system:GetFullName()
        assert(type(full_name) == "string" and full_name:find("KismetSystemLibrary", 1, true))
        log("OBJECT_NAME_OK: " .. full_name)
        local controller = StaticFindObject("/Script/Engine.Default__PlayerController")
        assert(controller and controller:IsValid(), "PlayerController CDO missing")
        local cursor = controller.bShowMouseCursor
        assert(type(cursor) == "boolean", "Reflected bool returned " .. type(cursor))
        log("PROPERTY_READ_OK: bShowMouseCursor=" .. tostring(cursor))
        local math = StaticFindObject("/Script/Engine.Default__KismetMathLibrary")
        assert(math and math:IsValid(), "Math library CDO missing")
        local sum = math:Add_IntInt(7, 5)
        assert(sum == 12, "Add_IntInt returned " .. tostring(sum))
        log("PROCESSEVENT_SCALAR_OK: Add_IntInt=12")
        local version = system:GetEngineVersion():ToString()
        assert(type(version) == "string" and version:find("4.27", 1, true), tostring(version))
        log("PROCESSEVENT_STRING_OK: GetEngineVersion=" .. version)
        log("API_CHECKS_PASSED")
    end)
    if not ok then log("API_CHECK_ERROR: " .. tostring(err)) end
    end)
end)
