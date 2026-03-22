PrefabFiles =
{
    "folkmod_trash_bin",
}

Assets = {}

local _G = GLOBAL
local require = _G.require
local STRINGS = _G.STRINGS
local TECH = _G.TECH
local RECIPETABS = _G.RECIPETABS
local Ingredient = _G.Ingredient
local Vector3 = _G.Vector3
local ACTIONS = _G.ACTIONS
local TUNING = _G.TUNING

local CHEST_SLOTS = 300
local ICEBOX_SLOTS = 100
local FOLLOWER_SLOTS = 300
local TRASH_BIN_SLOTS = 100
local STACK_SIZE = 300
local TRASH_DAYS = 2
local FRIDGE_MULT = 2.0
local SHARE_MAP = true

TUNING.FOLKMOD_CHEST_SLOTS = CHEST_SLOTS
TUNING.FOLKMOD_ICEBOX_SLOTS = ICEBOX_SLOTS
TUNING.FOLKMOD_FOLLOWER_SLOTS = FOLLOWER_SLOTS
TUNING.FOLKMOD_TRASH_BIN_SLOTS = TRASH_BIN_SLOTS
TUNING.FOLKMOD_STACK_SIZE = STACK_SIZE
TUNING.FOLKMOD_TRASH_TIME = TUNING.TOTAL_DAY_TIME * TRASH_DAYS
TUNING.FOLKMOD_FRIDGE_MULT = FRIDGE_MULT

local containers = require("containers")

local function BuildSlotPos(total, columns, spacing)
    local rows = math.ceil(total / columns)
    local width = (columns - 1) * spacing
    local height = (rows - 1) * spacing
    local slotpos = {}

    for row = 0, rows - 1 do
        for col = 0, columns - 1 do
            local index = row * columns + col + 1
            if index > total then
                break
            end
            table.insert(slotpos, Vector3(col * spacing - width / 2, height / 2 - row * spacing, 0))
        end
    end

    return slotpos
end

local function ComputeChestLayout(total)
    if total >= 300 then
        return {
            columns = 20,
            spacing = 54,
            slotscale = 0.5,
            pos = Vector3(0, 80, 0),
            side_align_tip = 260,
        }
    elseif total >= 180 then
        return {
            columns = 15,
            spacing = 60,
            slotscale = 0.58,
            pos = Vector3(0, 120, 0),
            side_align_tip = 220,
        }
    end

    return {
        columns = 12,
        spacing = 68,
        slotscale = 0.72,
        pos = Vector3(0, 180, 0),
        side_align_tip = 180,
    }
end

local function ComputeIceboxLayout(total)
    if total >= 100 then
        return {
            columns = 12,
            spacing = 58,
            slotscale = 0.56,
            pos = Vector3(0, 150, 0),
            side_align_tip = 220,
        }
    end

    return {
        columns = 10,
        spacing = 62,
        slotscale = 0.64,
        pos = Vector3(0, 170, 0),
        side_align_tip = 180,
    }
end

local function ComputeTrashLayout(total)
    if total >= 100 then
        return {
            columns = 12,
            spacing = 58,
            slotscale = 0.56,
            pos = Vector3(0, 150, 0),
            side_align_tip = 220,
        }
    end

    return {
        columns = 10,
        spacing = 62,
        slotscale = 0.64,
        pos = Vector3(0, 170, 0),
        side_align_tip = 180,
    }
end

local function ComputeFollowerLayout(total)
    return {
        columns = 20,
        spacing = 54,
        slotscale = 0.5,
        pos = Vector3(0, 80, 0),
        side_align_tip = 260,
        total = total,
    }
end

local chest_layout = ComputeChestLayout(CHEST_SLOTS)
local icebox_layout = ComputeIceboxLayout(ICEBOX_SLOTS)
local trash_layout = ComputeTrashLayout(TRASH_BIN_SLOTS)
local follower_layout = ComputeFollowerLayout(FOLLOWER_SLOTS)
local chest_slotpos = BuildSlotPos(CHEST_SLOTS, chest_layout.columns, chest_layout.spacing)
local icebox_slotpos = BuildSlotPos(ICEBOX_SLOTS, icebox_layout.columns, icebox_layout.spacing)
local trash_slotpos = BuildSlotPos(TRASH_BIN_SLOTS, trash_layout.columns, trash_layout.spacing)
local follower_slotpos = BuildSlotPos(FOLLOWER_SLOTS, follower_layout.columns, follower_layout.spacing)

local function CopyTableShallow(source)
    local result = {}
    if source ~= nil then
        for k, v in pairs(source) do
            result[k] = v
        end
    end
    return result
end

local function PatchContainerParam(name, slotpos, widget)
    local old = containers.params[name] or {}
    local config = CopyTableShallow(old)
    config.widget = CopyTableShallow(old.widget)
    config.widget.slotpos = slotpos
    config.widget.animbank = widget.animbank
    config.widget.animbuild = widget.animbuild
    config.widget.pos = widget.pos
    config.widget.side_align_tip = widget.side_align_tip
    config.widget.slotscale = widget.slotscale
    config.widget.slotbg = nil
    config.widget.buttoninfo = old.widget and old.widget.buttoninfo or nil
    config.type = widget.type or config.type or "chest"
    config.issidewidget = widget.issidewidget
    config.openlimit = old.openlimit
    config.acceptsstacks = old.acceptsstacks
    config.itemtestfn = old.itemtestfn
    config.priorityfn = old.priorityfn
    config.excludefromcrafting = old.excludefromcrafting
    config.lowpriorityselection = old.lowpriorityselection
    config.usespecificslotsforitems = false
    containers.params[name] = config
end

PatchContainerParam(
    "treasurechest",
    chest_slotpos,
    {
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = chest_layout.pos,
        side_align_tip = chest_layout.side_align_tip,
        slotscale = chest_layout.slotscale,
        type = "chest",
        issidewidget = false,
    }
)

PatchContainerParam(
    "icebox",
    icebox_slotpos,
    {
        animbank = "ui_icebox_3x3",
        animbuild = "ui_icebox_3x3",
        pos = icebox_layout.pos,
        side_align_tip = icebox_layout.side_align_tip,
        slotscale = icebox_layout.slotscale,
        type = "chest",
        issidewidget = false,
    }
)

PatchContainerParam(
    "folkmod_trash_bin",
    trash_slotpos,
    {
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = trash_layout.pos,
        side_align_tip = trash_layout.side_align_tip,
        slotscale = trash_layout.slotscale,
        type = "chest",
        issidewidget = false,
    }
)

for _, prefab in ipairs({ "chester", "shadowchester", "snowchester", "hutch" }) do
    PatchContainerParam(
        prefab,
        follower_slotpos,
        {
            animbank = "ui_chest_3x3",
            animbuild = "ui_chest_3x3",
            pos = follower_layout.pos,
            side_align_tip = follower_layout.side_align_tip,
            slotscale = follower_layout.slotscale,
            type = "chest",
            issidewidget = false,
        }
    )
end

containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS or 0, CHEST_SLOTS, FOLLOWER_SLOTS, TRASH_BIN_SLOTS)

STRINGS.NAMES.FOLKMOD_TRASH_BIN = "Trash Bin"
STRINGS.RECIPE_DESC.FOLKMOD_TRASH_BIN = "100 slots. Items turn to ash after 2 days."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FOLKMOD_TRASH_BIN = "It holds 100 items, and unwanted stuff becomes ash after 2 days."

AddPrefabPostInitAny(function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    if inst.components.stackable ~= nil then
        if inst.components.stackable.SetMaxSize ~= nil then
            inst.components.stackable:SetMaxSize(STACK_SIZE)
        else
            inst.components.stackable.maxsize = STACK_SIZE
        end
    end
end)

local function BoostPreserver(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    if inst.components.preserver ~= nil then
        local old_mult = inst.components.preserver.perish_rate_multiplier
        if old_mult == nil then
            old_mult = TUNING.PERISH_FRIDGE_MULT or 0.5
        end
        local new_mult = old_mult / FRIDGE_MULT
        if inst.components.preserver.SetPerishRateMultiplier ~= nil then
            inst.components.preserver:SetPerishRateMultiplier(new_mult)
        else
            inst.components.preserver.perish_rate_multiplier = new_mult
        end
    end
end

AddPrefabPostInit("icebox", BoostPreserver)
AddPrefabPostInit("saltbox", BoostPreserver)

local protected_followers =
{
    "chester",
    "shadowchester",
    "snowchester",
    "hutch",
}

for _, prefab in ipairs(protected_followers) do
    AddPrefabPostInit(prefab, function(inst)
        if not _G.TheWorld.ismastersim then
            return
        end

        if inst.components.health ~= nil and inst.components.health.SetInvincible ~= nil then
            inst.components.health:SetInvincible(true)
        end
        inst:AddTag("notarget")
        if inst.components.combat ~= nil then
            inst.components.combat.canbeattacked = false
            if inst.components.combat.SetShouldAvoidAggro ~= nil then
                inst.components.combat:SetShouldAvoidAggro(true)
            end
        end
    end)
end

AddComponentAction("USEITEM", "sleepingbag", function(inst, doer, target, actions)
    if inst ~= nil and inst.prefab == "bedroll_straw" and doer ~= nil and doer:HasTag("player") then
        table.insert(actions, ACTIONS.SLEEPIN)
    end
end)

local function ShareMapBetweenPlayers()
    if not _G.TheWorld.ismastersim or not SHARE_MAP then
        return
    end

    local players = _G.AllPlayers or {}
    if #players <= 1 then
        return
    end

    for i = 1, #players do
        local src = players[i]
        if src ~= nil and src.player_classified ~= nil and src.player_classified.MapExplorer ~= nil then
            local data = src.player_classified.MapExplorer:RecordMap()
            if data ~= nil then
                for j = 1, #players do
                    if i ~= j then
                        local dst = players[j]
                        if dst ~= nil and dst.player_classified ~= nil and dst.player_classified.MapExplorer ~= nil then
                            dst.player_classified.MapExplorer:LearnRecordedMap(data)
                        end
                    end
                end
            end
        end
    end
end

AddPrefabPostInit("world", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    if SHARE_MAP then
        inst:DoPeriodicTask(15, ShareMapBetweenPlayers, 15)
    end
end)

AddRecipe2(
    "folkmod_trash_bin",
    {
        Ingredient("boards", 3),
        Ingredient("goldnugget", 2),
    },
    RECIPETABS.STRUCTURES,
    TECH.SCIENCE_ONE
)
