-- Easy Fishing - fishing mode and the sound volume.
-- Fishing mode: music, ambience, dialogue and the other voices off, reverb and distance filtering too, the
-- sound effects at the mode's volume (100 % unless changed with the slider while it is on) and the sound
-- kept while the game is in the background. All given back when it is turned off, and at each logout (put on again at the next login);
-- a setting changed by the player meanwhile is left as it is.
-- Mute: the game's own "Enable Sound" off (every sound, in the background too), as Ctrl+S does.

local _, ns = ...
local floor, min, max = math.floor, math.min, math.max

local OFF = { "Sound_EnableMusic", "Sound_EnableAmbience", "Sound_EnableDialog", "Sound_EnableErrorSpeech",
  "Sound_EnableEmoteSounds", "Sound_EnablePetSounds", "Sound_EnableReverb", "Sound_EnablePositionalLowPassFilter" }
local ON = { "Sound_EnableSFX", "Sound_EnableGameplaySFX", "Sound_EnableSoundWhenGameIsInBG" }
local EFFECTS = { "Sound_SFXVolume", "Sound_GameplaySFX" } -- (the second: later clients only)
local ALL = "Sound_EnableAllSound"

local function Get(name)
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
  return GetCVar and GetCVar(name)
end
local function Set(name, value)
  if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar(name, value) elseif SetCVar then SetCVar(name, value) end
end
ns.GetCVar, ns.SetCVar = Get, Set
local function Volume(value) return tostring(floor(value * 100 + .5) / 100) end

ns.refresh = {} -- functions run when something here changes (the menu's line, the options)
local function Refresh() for _, fn in ipairs(ns.refresh) do pcall(fn) end end
ns.Refresh = Refresh

function ns:Mode() return self.db and self.db.mode == true end
function ns:ModeVolume() return self.db and tonumber(self.db.modeVolume) or 100 end
function ns:ModeTip() return ns.L.MODE_TIP:format(self:ModeVolume()) end

-- Given back: each setting as it was, unless the player changed it since
local function Restore()
  local db = ns.db
  local saved, set = db and db.sound, db and db.soundSet
  if not saved then return end
  for name, value in pairs(saved) do
    if not set or set[name] == nil or Get(name) == set[name] then Set(name, value) end
  end
  db.sound, db.soundSet = nil, nil
end

-- The fishing settings, the former values kept (in the saved settings: given back at the next login
-- should the game close meanwhile)
local function Apply()
  local db = ns.db
  if not db then return end
  local saved, set = db.sound or {}, db.soundSet or {}
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
  for _, name in ipairs(EFFECTS) do Want(name, Volume(ns:ModeVolume() / 100)) end
  db.sound, db.soundSet = next(saved) and saved or nil, next(set) and set or nil
end

-- The mute kept through the mode's own changes: the game turns its sound back on when some of its
-- sound settings change (seen unticking the mode); for a second after them, it is put back off.
local holdUntil = 0
local function Now() return GetTime and GetTime() or 0 end
local function HoldMute() if ns:Muted() then holdUntil = Now() + 1 end end
local function KeepMute()
  if holdUntil > Now() and not ns:Muted() then Set(ALL, "0") end
end
ns.KeepMute = KeepMute

function ns:SetMode(on)
  if not self.db then return end
  HoldMute()
  on = on and true or false
  self.db.mode = on or nil
  if on then Apply() else
    Restore()
    if self.WeaponsBack then self:WeaponsBack() end -- (the weapons the pole replaced: Fishing.lua)
  end
  KeepMute()
  if C_Timer and C_Timer.After then C_Timer.After(.3, function() KeepMute() Refresh() end) end
  Refresh()
end

-- The sound effects volume, 0 to 100
function ns:Volume()
  local v = tonumber(Get(EFFECTS[1]))
  return v and floor(v * 100 + .5) or 100
end
function ns:Muted() return Get(ALL) == "0" end

function ns:SetVolume(percent)
  percent = max(0, min(100, floor((tonumber(percent) or 100) + .5)))
  if self:Muted() and percent > 0 then holdUntil = 0 Set(ALL, "1") end -- (moved to the right: the sound back)
  local value = Volume(percent / 100)
  for _, name in ipairs(EFFECTS) do
    if Get(name) ~= nil then
      Set(name, value)
      -- in fishing mode: the mode's own volume (the player's own given back when it goes off)
      if self:Mode() and self.db and self.db.soundSet and self.db.soundSet[name] ~= nil then self.db.soundSet[name] = Get(name) end
    end
  end
  if self:Mode() and self.db then self.db.modeVolume = percent ~= 100 and percent or nil end
  Refresh()
end

function ns:SetMuted(on)
  if on then
    if self.db then self.db.lastVolume = self:Volume() end
    Set(ALL, "0")
  else
    holdUntil = 0
    Set(ALL, "1")
    if self:Volume() == 0 then self:SetVolume(self.db and self.db.lastVolume or 100) return end
  end
  Refresh()
end

---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("CVAR_UPDATE")
events:SetScript("OnEvent", function(self, event, arg)
  if event == "ADDON_LOADED" then
    if arg ~= "EasyFishing" then return end
    self:UnregisterEvent("ADDON_LOADED")
    EasyFishingDB = type(EasyFishingDB) == "table" and EasyFishingDB or {}
    ns.db = EasyFishingDB
    EasyFishingDB.boost = nil -- (1.0.0's master volume boost, removed: given back by Restore at login)
  elseif event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    HoldMute()
    Restore() -- (given back, should the game have closed in fishing mode)
    if ns:Mode() then Apply() end
    KeepMute()
    Refresh()
  elseif event == "PLAYER_LOGOUT" then
    Restore() -- (the game saves its settings as they were: the mode put on again at the next login)
  elseif event == "CVAR_UPDATE" then
    if arg == ALL then KeepMute() end
    Refresh() -- (Ctrl+S, the game's options: the menu's line follows)
  end
end)
