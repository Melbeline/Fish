-- Clara Combo Points (the same file in Easy Fishing, the standalone addon) - one key to fish, with the keyboard and
-- mouse (no gamepad mode): its key binding (Esc > Options > Keybindings > Clara Combo Points, or Easy Fishing: Fish /
-- Reel in) casts Fishing; while
-- the line is out, the same key is the game's own Interact Key (INTERACTTARGET), which reels in
-- the bobber the game itself picks (its soft interact target): one press, one action, the moment
-- left to the player. While fishing, the game's interact settings are set as its gamepad mode sets
-- them (the interact key on for the keyboard too, 20 yards, an icon over the bobber), then given
-- back. Without a fishing pole in hand, the key first equips the one in the bags (one press), the
-- weapons it replaces kept and put back when fishing mode is turned off (FishingMode.lua).

local ADDON, ns = ...
local L = ns.L

local FISHING = { 7620, 7731, 7732, 18248, 131474 } -- (its ranks, and the later single spell)
-- The game's interact settings while fishing (its gamepad mode's: Blizzard_Gamepad/Core.lua)
local ANY = Enum and Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
local CVARS = {
  SoftTargetInteract = { value = tostring(ANY) },
  SoftTargetInteractRange = { value = "20", atLeast = true },
  SoftTargetInteractArc = { value = "1", atLeast = true },
  SoftTargetIconGameObject = { value = "1" },
  SoftTargetIconInteract = { value = "1" },
}

-- The key's button and its binding: Clara's, or the standalone Easy Fishing's (this file is shared with it, as it is:
-- its Shell.lua names its own button, its Bindings.xml lists the binding)
local BUTTON = ns.FISHING_BUTTON or "ClaraFishingButton"
local ACTION = "CLICK " .. BUTTON .. ":LeftButton"
if not ns.FISHING_BUTTON then BINDING_CATEGORY_CLARA = "Clara" end
_G["BINDING_NAME_" .. ACTION] = L.FISH_BINDING

local button = CreateFrame("Button", BUTTON, UIParent, "SecureActionButtonTemplate")
button:RegisterForClicks("AnyUp", "AnyDown") -- (the game's template acts on one of them: one press, one cast)
button:SetAttribute("type", "spell")
button:Hide()

local fishingName -- Fishing's name in the game's language, once known
local function FishingName()
  for _, id in ipairs(FISHING) do
    if IsPlayerSpell and IsPlayerSpell(id) then
      local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or (GetSpellInfo and GetSpellInfo(id))
      if name then return name end
    end
  end
end

local function Learn()
  if InCombatLockdown() then return end
  local name = FishingName()
  if name and name ~= fishingName then
    fishingName = name
    button:SetAttribute("spell", name)
  end
end

---------------------------------------------------------------------------
-- The pole: without one in hand, the key equips the one in the bags (one press), the next press
-- casts; the weapons it took the place of are kept, put back when fishing mode is turned off
-- (FishingMode.lua). Out of combat.
---------------------------------------------------------------------------
local MAIN, OFF = 16, 17

local function IsPole(item)
  if not item or not (C_Item and C_Item.GetItemInfoInstant) then return false end
  local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(item)
  return classID == 2 and subclassID == 20 -- (weapon, fishing pole)
end

local function PoleInBags()
  if not (C_Container and C_Container.GetContainerNumSlots) then return end
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if type(info) == "table" and info.itemID and IsPole(info.itemID) then return info.itemID end
    end
  end
end

local held = {} -- the weapons in hand, as last seen

local function Me() return UnitGUID("player") or "?" end

local function Pole()
  if InCombatLockdown() then return end
  if ns.fishingWeaponsLater then ns:FishingWeaponsBack() end
  if not fishingName then return end
  local inHand = IsPole(GetInventoryItemID("player", MAIN))
  local pole = not inHand and PoleInBags()
  if pole then
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", "/equip item:" .. pole)
  else
    button:SetAttribute("type", "spell")
    button:SetAttribute("macrotext", nil)
  end
  -- the pole just put on: the weapons it replaced, kept
  local sv = ns.sv
  if sv and inHand and held.main and not IsPole(held.main) then
    sv.fishingWeapons = sv.fishingWeapons or {}
    sv.fishingWeapons[Me()] = { main = held.main, off = held.off }
  end
  held.main, held.off = GetInventoryItemLink("player", MAIN), GetInventoryItemLink("player", OFF)
end
ns.FishingPole = Pole

-- The weapons back in hand (fishing mode turned off), the pole in the bags
function ns:FishingWeaponsBack()
  local sv = self.sv
  local kept = sv and sv.fishingWeapons and sv.fishingWeapons[Me()]
  if not kept then return end
  if InCombatLockdown() then self.fishingWeaponsLater = true return end -- (when the fight ends: Pole)
  self.fishingWeaponsLater = nil
  sv.fishingWeapons[Me()] = nil
  if not next(sv.fishingWeapons) then sv.fishingWeapons = nil end
  if not IsPole(GetInventoryItemID("player", MAIN)) or not (C_Item and C_Item.EquipItemByName) then return end
  if kept.main then C_Item.EquipItemByName(kept.main, MAIN) end
  if kept.off then C_Timer.After(0.3, function()
    if not InCombatLockdown() then C_Item.EquipItemByName(kept.off, OFF) end
  end) end
end

---------------------------------------------------------------------------
-- While the line is out
---------------------------------------------------------------------------
local owner = CreateFrame("Frame") -- (the override bindings')
local fishing = false

local function SetCVarValue(name, value)
  if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar(name, value) elseif SetCVar then SetCVar(name, value) end
end
local function GetCVarValue(name)
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
  return GetCVar and GetCVar(name)
end

-- The game's settings for it, the former values kept (in the saved settings: given back at the
-- next login should the game close meanwhile)
local function Settings(on)
  local sv = ns.sv
  if not sv then return end
  if on then
    sv.fishingCVars = sv.fishingCVars or {}
    for name, want in pairs(CVARS) do
      local now = GetCVarValue(name)
      local lower = want.atLeast and tonumber(now) and tonumber(now) >= tonumber(want.value)
      if now ~= nil and tostring(now) ~= want.value and not lower then
        if sv.fishingCVars[name] == nil then sv.fishingCVars[name] = tostring(now) end
        SetCVarValue(name, want.value)
      end
    end
    if next(sv.fishingCVars) == nil then sv.fishingCVars = nil end
  elseif sv.fishingCVars then
    for name, value in pairs(sv.fishingCVars) do SetCVarValue(name, value) end
    sv.fishingCVars = nil
  end
end

local function Reel(on)
  if InCombatLockdown() or on == fishing then return end
  fishing = on
  ClearOverrideBindings(owner)
  if on then
    for _, key in ipairs({ GetBindingKey(ACTION) }) do
      SetOverrideBinding(owner, true, key, "INTERACTTARGET")
    end
  end
  Settings(on)
end
ns.FishingReel = Reel

local function IsFishing(spellID)
  if not (fishingName and spellID) or (issecretvalue and issecretvalue(spellID)) then return false end
  local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or (GetSpellInfo and GetSpellInfo(spellID))
  return name == fishingName
end

-- (WoW Forever only: its interact key and soft targeting)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, _, _, spellID)
  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    Settings(false) -- (given back, should the game have closed while fishing)
    if not ns.FOREVER or not ns:QolRuns("fishing") then return end -- (the module off, or Easy Fishing runs)
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    Learn()
    Pole()
  elseif event == "SPELLS_CHANGED" then
    Learn()
    Pole()
  elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_REGEN_ENABLED" then
    Pole()
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
    if IsFishing(spellID) then Reel(true) end
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LOGOUT" then
    Reel(false)
  end
end)
