-- Clara Combo Points (the same file in Easy Fishing, the standalone addon) - fishing mode: while it is on, the game's music, ambience, dialogue and the
-- other voices (pets, emotes, error speech) are off, and its reverb and distance filtering; its sound
-- effects at 100 % (the bobber's splash is one of them: heard with them alone), the master volume
-- louder (x2 by default, up to x10, never past 100 %), and the sound kept when the game is in the
-- background: the splash heard over the rest. The game has no volume for one sound, nor any word of
-- a bite: its own channels only. Turned on and off from the
-- portrait's menu, the Fishing card of the professions window (the game's and ClassicUI's), and
-- the game's options (Esc > Options > AddOns > Clara Combo Points, or Easy Fishing, with the boost). All given back
-- when it is turned off, and at each logout (put on again at the next login); a setting changed by
-- the player meanwhile is left as it is.

local ADDON, ns = ...
local L = ns.L
local floor, min, max = math.floor, math.min, math.max

local OFF = { "Sound_EnableMusic", "Sound_EnableAmbience", "Sound_EnableDialog", "Sound_EnableErrorSpeech",
  "Sound_EnableEmoteSounds", "Sound_EnablePetSounds", "Sound_EnableReverb", "Sound_EnablePositionalLowPassFilter" }
local ON = { "Sound_EnableAllSound", "Sound_EnableSFX", "Sound_EnableGameplaySFX", "Sound_EnableSoundWhenGameIsInBG" }
local EFFECTS = { "Sound_SFXVolume", "Sound_GameplaySFX" } -- (the second: later clients only)
local MASTER = "Sound_MasterVolume"
ns.FISHING_BOOST_MAX = 10
local DEFAULT_BOOST = 2

local function Get(name)
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
  return GetCVar and GetCVar(name)
end
local function Set(name, value)
  if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar(name, value) elseif SetCVar then SetCVar(name, value) end
end
local function Volume(value) return tostring(floor(value * 100 + .5) / 100) end

function ns:FishingMode() return self.sv and self.sv.fishingMode == true end
function ns:FishingBoost()
  local boost = self.sv and tonumber(self.sv.fishingBoost)
  return boost and max(1, min(ns.FISHING_BOOST_MAX, floor(boost + .5))) or DEFAULT_BOOST
end

-- Given back: each setting as it was, unless the player changed it since
local function Restore()
  local sv = ns.sv
  local saved, set = sv and sv.fishingSound, sv and sv.fishingSoundSet
  if not saved then return end
  for name, value in pairs(saved) do
    if not set or set[name] == nil or Get(name) == set[name] then Set(name, value) end
  end
  sv.fishingSound, sv.fishingSoundSet = nil, nil
end

-- The fishing settings, the former values kept (in the saved settings: given back at the next
-- login should the game close meanwhile)
local function Apply()
  local sv = ns.sv
  if not sv then return end
  local saved, set = sv.fishingSound or {}, sv.fishingSoundSet or {}
  -- The player's own value: as kept, or as now if changed by the player since
  local function Own(name)
    local now = Get(name)
    if saved[name] ~= nil and (set[name] == nil or now == set[name]) then return saved[name] end
    return now
  end
  local function Want(name, value)
    local now = Get(name)
    if now == nil then return end -- (not in this client)
    saved[name] = Own(name)
    if now ~= value then Set(name, value) end
    set[name] = Get(name)
  end
  for _, name in ipairs(OFF) do Want(name, "0") end
  for _, name in ipairs(ON) do Want(name, "1") end
  for _, name in ipairs(EFFECTS) do Want(name, "1") end
  local master = tonumber(Own(MASTER))
  if master then Want(MASTER, Volume(min(1, master * ns:FishingBoost()))) end
  sv.fishingSound, sv.fishingSoundSet = next(saved) and saved or nil, next(set) and set or nil
end

local boxes = {} -- the professions window's (and any other) boxes showing the mode
local function Refresh()
  for box in pairs(boxes) do if box:IsVisible() then box:SetChecked(ns:FishingMode()) end end
  if ns.RefreshSettingsPage then ns:RefreshSettingsPage() end
end

function ns:SetFishingMode(on)
  if not self.sv then return end
  on = on and true or false
  self.sv.fishingMode = on or nil
  if on then Apply() else
    Restore()
    if self.FishingWeaponsBack then self:FishingWeaponsBack() end -- (the weapons the pole replaced: Fishing.lua)
  end
  Refresh()
end

function ns:SetFishingBoost(boost)
  if not self.sv then return end
  boost = max(1, min(ns.FISHING_BOOST_MAX, floor((tonumber(boost) or DEFAULT_BOOST) + .5)))
  self.sv.fishingBoost = boost ~= DEFAULT_BOOST and boost or nil
  if self:FishingMode() then Apply() end
end

-- Fishing learned (its line in the menus), or the mode on (to turn it off)
function ns:FishingModeOffered()
  if not (self.QolRuns and self:QolRuns("fishing")) then return false end -- (the module off, or Easy Fishing runs)
  if self:FishingMode() then return true end
  if GetProfessions then
    local _, _, _, fish = GetProfessions()
    if fish then return true end
  end
  for _, id in ipairs({ 7620, 7731, 7732, 18248, 131474 }) do
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- A box on the Fishing card of the professions window
---------------------------------------------------------------------------
local function NewBox(parent)
  local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  box:SetSize(24, 24)
  box.label = box.Text or box.text
  if box.label then
    box.label:SetFontObject("GameFontHighlightSmall")
    box.label:SetText(L.MENU_FISHING_MODE)
  end
  box:SetScript("OnClick", function(self)
    if PlaySound and SOUNDKIT then
      PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end
    ns:SetFishingMode(self:GetChecked())
  end)
  box:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.MENU_FISHING_MODE)
    GameTooltip:AddLine(L.FISHING_MODE_TIP:format(ns:FishingBoost()), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  box:SetScript("OnLeave", function() GameTooltip:Hide() end)
  boxes[box] = true
  return box
end

-- On the game's card: under its skill bar, named. On ClassicUI's book (the card cut to its row):
-- left of the row's spells, its name under it.
local function PlaceBox(card)
  local box = card.claraFishingMode or NewBox(card)
  card.claraFishingMode = box
  local known = card.professionInitialized and not (card.missingHeader and card.missingHeader:IsShown())
  local classic = ns.ClassicUIPrivate and ns.ClassicUIPrivate.prof and ns.ClassicUIPrivate.prof.shown
  box:ClearAllPoints()
  if box.label then box.label:ClearAllPoints() end
  local spell = card.SpellButton1
  local point, rel, _, x, y
  if spell then point, rel, _, x, y = spell:GetPoint(1) end
  -- (a casting button's anchor can come back secret: never compared, the other place then)
  if issecretvalue and (issecretvalue(point) or issecretvalue(rel) or issecretvalue(x) or issecretvalue(y)) then point, rel = nil, nil end
  if classic and rel == card and point == "TOPLEFT" then
    -- (from the card, where ClassicUI puts its first spell: a frame hung on a casting button would be
    -- locked with it in combat)
    local w, h = spell:GetWidth() or 30, spell:GetHeight() or 30
    for n = 2, 4 do -- (more spells: icons left of the first)
      local button = card["SpellButton" .. n]
      if button and button:IsShown() then x = x - w - 4 end
    end
    box:SetPoint("RIGHT", card, "TOPLEFT", x - 14, y - h / 2 + 6)
    if box.label then
      box.label:SetPoint("TOP", box, "BOTTOM", 0, 3)
      box.label:SetFontObject("GameFontNormalTiny")
    end
  else
    box:SetPoint("TOPLEFT", card, "TOPLEFT", 18, -76)
    if box.label then
      box.label:SetPoint("LEFT", box, "RIGHT", 2, 1)
      box.label:SetFontObject("GameFontHighlightSmall")
    end
  end
  box:SetShown(known or ns:FishingMode())
  box:SetChecked(ns:FishingMode())
end

local function FishingCard()
  local page = ProfessionsFrame and ProfessionsFrame.BookPage
  local content = page and page.ProfessionsContentFrame
  return content and content.SecondaryProfession2 -- (cooking, fishing, first aid)
end

local function DressBook()
  local page = ProfessionsFrame and ProfessionsFrame.BookPage
  if not page or page.claraFishingMode then return end
  page.claraFishingMode = true
  local function Place()
    local card = FishingCard()
    if card then PlaceBox(card) end
  end
  local function Soon() C_Timer.After(0, Place) end -- (after the client's fill, and ClassicUI's)
  page:HookScript("OnShow", Soon)
  if type(page.Update) == "function" then hooksecurefunc(page, "Update", Soon) end
  if page:IsShown() then Soon() end
end

---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    Restore() -- (given back, should the game have closed in fishing mode)
    if not ns:QolRuns("fishing") then return end -- (the module off, or Easy Fishing runs: given back only)
    if ns:FishingMode() then Apply() end
    -- the professions window, once the game loads it
    if EventUtil and EventUtil.ContinueOnAddOnLoaded then EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", DressBook) end
  elseif event == "PLAYER_LOGOUT" then
    Restore() -- (the game saves its settings as they were: the mode put on again at the next login)
  end
end)
