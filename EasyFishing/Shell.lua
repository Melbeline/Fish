-- Easy Fishing - what Clara Combo Points' fishing files (Fishing.lua, FishingMode.lua: the same files, as they are)
-- find in Clara: its button's name (its binding: Bindings.xml), its saved settings (EasyFishingDB: those of 1.0.x
-- carried over, the sound settings kept while its fishing mode was on given back as before), the build it runs on, and
-- the page to refresh when the mode changes. The rest of the addon is its own: the portrait's menu (Menu.lua) and its
-- page in the game's options (Options.lua).

local ADDON, ns = ...

ns.FISHING_BUTTON = "EasyFishingButton" -- (Fishing.lua: its key's button; Bindings.xml: CLICK EasyFishingButton:LeftButton)

-- WoW Forever (its builds 160xx): its interact key and soft targeting, which the key uses
local toc = select(4, GetBuildInfo())
ns.FOREVER = type(toc) == "number" and toc >= 16000 and toc < 20000

-- Clara asks whether its fishing module runs: here, always
function ns:QolRuns() return true end

-- The options page and the menu follow the mode (FishingMode.lua calls this)
ns.refresh = {}
function ns:RefreshSettingsPage()
  for _, fn in ipairs(self.refresh) do pcall(fn) end
end

-- 1.0.x's saved settings, under Clara's names
local function Carry(db)
  if db.v2 then return end
  if db.mode ~= nil then db.fishingMode = db.mode == true or nil end
  if db.sound then db.fishingSound, db.fishingSoundSet = db.sound, db.soundSet end -- (given back by FishingMode.lua)
  if db.weapons then db.fishingWeapons = db.weapons end
  if db.cvars then db.fishingCVars = db.cvars end
  db.mode, db.sound, db.soundSet, db.weapons, db.cvars = nil, nil, nil, nil, nil
  db.modeVolume, db.lastVolume, db.boost = nil, nil, nil
  db.v2 = true
end
ns.Carry = Carry -- (for its test)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  EasyFishingDB = type(EasyFishingDB) == "table" and EasyFishingDB or {}
  Carry(EasyFishingDB)
  ns.sv = EasyFishingDB
end)
