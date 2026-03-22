local assets =
{
    Asset("ANIM", "anim/treasure_chest.zip"),
}

local prefabs =
{
    "ash",
    "collapse_small",
}

local TRASH_TIME = TUNING.FOLKMOD_TRASH_TIME or (TUNING.TOTAL_DAY_TIME * 2)

local function ApplyColor(inst)
    if inst.AnimState ~= nil then
        inst.AnimState:SetMultColour(0.2, 0.2, 0.2, 1)
    end
end

local function RefreshDeadlines(inst)
    inst._folkmod_deadlines = inst._folkmod_deadlines or {}
    if inst.components.container == nil then
        return
    end

    for slot = 1, inst.components.container:GetNumSlots() do
        local item = inst.components.container:GetItemInSlot(slot)
        if item ~= nil and item.prefab ~= "ash" and inst._folkmod_deadlines[slot] == nil then
            inst._folkmod_deadlines[slot] = GetTime() + TRASH_TIME
        elseif item == nil then
            inst._folkmod_deadlines[slot] = nil
        end
    end
end

local function OnItemGet(inst, data)
    if data ~= nil and data.slot ~= nil and inst.components.container ~= nil then
        local item = inst.components.container:GetItemInSlot(data.slot)
        if item ~= nil and item.prefab ~= "ash" then
            inst._folkmod_deadlines[data.slot] = GetTime() + TRASH_TIME
        else
            inst._folkmod_deadlines[data.slot] = nil
        end
    end
end

local function OnItemLose(inst, data)
    if data ~= nil and data.slot ~= nil then
        inst._folkmod_deadlines[data.slot] = nil
    end
end

local function ProcessTrash(inst)
    if inst.components.container == nil then
        return
    end

    local now = GetTime()
    for slot, deadline in pairs(inst._folkmod_deadlines or {}) do
        if deadline ~= nil and deadline <= now then
            local item = inst.components.container:RemoveItemBySlot(slot)
            inst._folkmod_deadlines[slot] = nil

            if item ~= nil then
                item:Remove()
                local ash = SpawnPrefab("ash")
                if ash ~= nil then
                    inst.components.container:GiveItem(ash, slot)
                end
            end
        end
    end

    RefreshDeadlines(inst)
end

local function onsave(inst, data)
    if next(inst._folkmod_deadlines or {}) ~= nil then
        data.folkmod_deadlines = {}
        for slot, deadline in pairs(inst._folkmod_deadlines) do
            data.folkmod_deadlines[slot] = math.max(0, deadline - GetTime())
        end
    end
end

local function onload(inst, data)
    inst._folkmod_deadlines = {}
    if data ~= nil and data.folkmod_deadlines ~= nil then
        for slot, remaining in pairs(data.folkmod_deadlines) do
            inst._folkmod_deadlines[tonumber(slot) or slot] = GetTime() + remaining
        end
    end
    ApplyColor(inst)
    RefreshDeadlines(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.MiniMapEntity:SetIcon("treasurechest.tex")

    inst.AnimState:SetBank("treasure_chest")
    inst.AnimState:SetBuild("treasure_chest")
    inst.AnimState:PlayAnimation("closed")

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        if inst.replica.container ~= nil then
            inst.replica.container:WidgetSetup("folkmod_trash_bin")
        end
        ApplyColor(inst)
        return inst
    end

    inst._folkmod_deadlines = {}

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("folkmod_trash_bin")
    inst.components.container.onopenfn = function(target)
        target.AnimState:PlayAnimation("open")
        target.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end
    inst.components.container.onclosefn = function(target)
        target.AnimState:PlayAnimation("closed")
        target.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)
    inst:DoPeriodicTask(10, ProcessTrash, 10)

    inst.OnSave = onsave
    inst.OnLoad = onload

    ApplyColor(inst)

    return inst
end

return Prefab("folkmod_trash_bin", fn, assets, prefabs),
    MakePlacer("folkmod_trash_bin_placer", "treasure_chest", "treasure_chest", "closed")
