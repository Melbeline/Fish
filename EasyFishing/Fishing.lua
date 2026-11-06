-- Easy Fishing - one key to fish: its key binding (Esc > Options > Keybindings > Easy Fishing) casts
-- Fishing; while the line is out, the same key is the game's own Interact Key (INTERACTTARGET), which
-- reels in the bobber the game picks (its soft interact target): one press, one action. While fishing,
-- the game's interact settings are set as its gamepad mode sets them, then given back. Without a pole
-- in hand, the key first equips the one in the bags; the weapons it replaced are put back when fishing
-- mode is turned off (Mode.lua).

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



local button = CreateFrame("Button", "EasyFishingButton", UIParent, "SecureActionButtonTemplate")
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
-- (Mode.lua). Out of combat.
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
  if ns.weaponsLater then ns:WeaponsBack() end
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
  local sv = ns.db
  if sv and inHand and held.main and not IsPole(held.main) then
    sv.weapons = sv.weapons or {}
    sv.weapons[Me()] = { main = held.main, off = held.off }
  end
  held.main, held.off = GetInventoryItemLink("player", MAIN), GetInventoryItemLink("player", OFF)
end
ns.Pole = Pole

-- The weapons back in hand (fishing mode turned off), the pole in the bags
function ns:WeaponsBack()
  local sv = self.db
  local kept = sv and sv.weapons and sv.weapons[Me()]
  if not kept then return end
  if InCombatLockdown() then self.weaponsLater = true return end -- (when the fight ends: Pole)
  self.weaponsLater = nil
  sv.weapons[Me()] = nil
  if not next(sv.weapons) then sv.weapons = nil end
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
  local sv = ns.db
  if not sv then return end
  if on then
    sv.cvars = sv.cvars or {}
    for name, want in pairs(CVARS) do
      local now = GetCVarValue(name)
      local lower = want.atLeast and tonumber(now) and tonumber(now) >= tonumber(want.value)
      if now ~= nil and tostring(now) ~= want.value and not lower then
        if sv.cvars[name] == nil then sv.cvars[name] = tostring(now) end
        SetCVarValue(name, want.value)
      end
    end
    if next(sv.cvars) == nil then sv.cvars = nil end
  elseif sv.cvars then
    for name, value in pairs(sv.cvars) do SetCVarValue(name, value) end
    sv.cvars = nil
  end
end

local function Reel(on)
  if InCombatLockdown() or on == fishing then return end
  fishing = on
  ClearOverrideBindings(owner)
  if on then
    for _, key in ipairs({ GetBindingKey("CLICK EasyFishingButton:LeftButton") }) do
      SetOverrideBinding(owner, true, key, "INTERACTTARGET")
    end
  end
  Settings(on)
end
ns.Reel = Reel

local function IsFishing(spellID)
  if not (fishingName and spellID) or (issecretvalue and issecretvalue(spellID)) then return false end
  local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or (GetSpellInfo and GetSpellInfo(spellID))
  return name == fishingName
end

-- (clients with the interact key and soft targeting: WoW Forever)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, _, _, spellID)
  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    Settings(false) -- (given back, should the game have closed while fishing)
    if GetCVarValue("SoftTargetInteract") == nil then return end -- (a client with the interact key)
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
