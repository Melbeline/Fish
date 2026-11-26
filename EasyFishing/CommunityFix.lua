-- Community fixes (from Clara Combo Points, the same in each of Melbeline's addons; only one copy runs: Clara's when
-- Clara Combo Points is there, else the first of these addons to start).
-- 1. The community chats back after a login: a bug of the game's (WoW's own for years, WoW Forever's too): a community
--    whose chat a window shows (Guild & Communities > Add to Chat Window, its box ticked) is at times not joined as the
--    game starts: its lines never come and it has no /number, though its box stays ticked. After the login (the clubs
--    in, 15 seconds for the game to join them on its own) and every 30 seconds after, the community chats the windows
--    show are looked at: one not joined is joined again, as the game does when its box is ticked, silently. Once
--    Blizzard fixes it, nothing is left to join: nothing is done.
-- 2. Who is online in a community: the game's Guild & Communities window asks for a community's members, never for their
--    presence (its chat channels window does both): its list could show them all offline. The community it shows (not
--    the guild) is subscribed to its members' presence too, the window shown, as the chat channels window does. The
--    player's own presence (Battle.net's Appear Offline hides a player from the communities) is left alone.

local ADDON = ...
local FIRST_LOOK = 15 -- seconds after the clubs are in
local EVERY = 30      -- seconds: the windows looked at again

local issecret = issecretvalue or function() return false end

local function Mine()
  -- (Clara Combo Points, or another of these addons, runs them already: this copy stands aside)
  if _G.ClaraCommunityFix then return false end
  _G.ClaraCommunityFix = ADDON or "?"
  return true
end

---------------------------------------------------------------------------
-- 1. The community chats the chat windows show, joined again when the game has not
---------------------------------------------------------------------------
local function Shown()
  local out, seen = {}, {}
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local frame = _G["ChatFrame" .. i]
    local list = frame and frame.channelList
    if type(list) ~= "table" and GetChatWindowChannels then list = { GetChatWindowChannels(i) } end
    for _, name in pairs(type(list) == "table" and list or {}) do
      if type(name) == "string" and not issecret(name) and not seen[name] then
        local club, stream = name:match("^Community:(%d+):(%d+)$")
        if club then
          seen[name] = true
          out[#out + 1] = { name = name, club = tonumber(club), stream = tonumber(stream) }
        end
      end
    end
  end
  return out
end

local function Joined(name)
  local ok, id = pcall(GetChannelName, name)
  if not ok or issecret(id) then return true end -- (cannot tell: left alone)
  return type(id) == "number" and id > 0
end

local function Ours(club)
  local ok, info = pcall(C_Club.GetClubInfo, club)
  return ok and info ~= nil
end

local function Look()
  if InCombatLockdown and InCombatLockdown() then return end -- (again at the next look)
  if not (C_Club and C_Club.AddClubStreamChatChannel and C_Club.GetClubInfo and GetChannelName) then return end
  for _, c in ipairs(Shown()) do
    if Ours(c.club) and not Joined(c.name) then pcall(C_Club.AddClubStreamChatChannel, c.club, c.stream) end
  end
end

local looked, ticker
local function FirstLook()
  if looked then return end
  looked = true
  Look()
  if not ticker and C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(EVERY, Look) end
end

---------------------------------------------------------------------------
-- 2. The communities window's community subscribed to its members' presence
---------------------------------------------------------------------------
local function Subscribe(frame, clubId)
  if not (C_Club and C_Club.SetClubPresenceSubscription) or clubId == nil or issecret(clubId) then return end
  if not (frame and frame.IsShown and frame:IsShown()) then return end
  local info = C_Club.GetClubInfo and C_Club.GetClubInfo(clubId)
  if type(info) == "table" and Enum and Enum.ClubType and info.clubType == Enum.ClubType.Guild then return end
  pcall(C_Club.SetClubPresenceSubscription, clubId)
end

local hooked = false
local function HookPresence()
  local f = _G.CommunitiesFrame
  if hooked or type(f) ~= "table" or type(f.OnClubSelected) ~= "function" then return end
  hooked = true
  hooksecurefunc(f, "OnClubSelected", function(self, clubId) Subscribe(self, clubId) end)
  f:HookScript("OnShow", function(self)
    if C_Timer and C_Timer.After then C_Timer.After(0, function() Subscribe(self, self.selectedClubId) end) end
  end)
end

---------------------------------------------------------------------------
-- Started at the login, if no other copy runs them
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg)
  if event == "PLAYER_LOGIN" then
    if not (C_Club and Mine()) then self:UnregisterAllEvents() return end
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ADDON_LOADED")
    pcall(self.RegisterEvent, self, "INITIAL_CLUBS_LOADED")
    HookPresence()
  elseif event == "ADDON_LOADED" then
    if arg == "Blizzard_Communities" then HookPresence() end
  elseif event == "PLAYER_ENTERING_WORLD" then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    -- (the clubs' event missed, as after a reload: looked at a little later all the same)
    if C_Timer and C_Timer.After then C_Timer.After(FIRST_LOOK + 10, FirstLook) end
  elseif event == "INITIAL_CLUBS_LOADED" then
    if C_Timer and C_Timer.After then C_Timer.After(FIRST_LOOK, FirstLook) else FirstLook() end
  end
end)
