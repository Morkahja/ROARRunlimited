-- ROARRunlimited v1.0
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0 safe
-- SavedVariables: ROEDDB
-- Author: babunigaming
-- Slash command: /roed

-------------------------------------------------
-- Battle emote pool
-------------------------------------------------
local EMOTE_TOKENS_BATTLE = {
  "ROAR","CHARGE","CHEER","BORED","FLEX"
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOTS = {}   -- [slot] = { chance=100, cd=6, last=0 }
local WATCH_MODE = false
local ENABLED = true

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444ROED:|r " .. text)
  end
end

local function ensureDB()
  if type(ROEDDB) ~= "table" then ROEDDB = {} end
  return ROEDDB
end

local _loaded = false
local function ensureLoaded()
  if _loaded then return end
  local db = ensureDB()
  WATCH_SLOTS = db.slots or {}
  if db.enabled ~= nil then ENABLED = db.enabled end
  _loaded = true
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function performEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("makes a battle cry!", "EMOTE")
  end
end

-------------------------------------------------
-- Emote logic per slot
-------------------------------------------------
local function doBattleEmoteForSlot(slot)
  if not ENABLED then return end

  local cfg = WATCH_SLOTS[slot]
  if not cfg then return end

  local now = GetTime()
  cfg.last = cfg.last or 0
  cfg.cd = cfg.cd or 0
  cfg.chance = cfg.chance or 100

  if now - cfg.last < cfg.cd then return end
  cfg.last = now

  if math.random(1,100) <= cfg.chance then
    local e = pick(EMOTE_TOKENS_BATTLE)
    if e then performEmote(e) end
  end
end

-------------------------------------------------
-- Utility
-------------------------------------------------
local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()

  if WATCH_MODE then
    chat("pressed slot " .. tostring(slot))
  end

  if WATCH_SLOTS[slot] then
    doBattleEmoteForSlot(slot)
  end

  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands (/roed)
-------------------------------------------------
SLASH_ROED1 = "/roed"
SlashCmdList["ROED"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  -- /roed slotX <slotNumber>
  local slotIndex = string.match(cmd, "^slot(%d+)$")
  if slotIndex then
    local n = tonumber(rest)
    if n then
      WATCH_SLOTS[n] = WATCH_SLOTS[n] or { chance = 100, cd = 6, last = 0 }
      ensureDB().slots = WATCH_SLOTS
      chat("watching slot " .. n)
    else
      chat("usage: /roed slotX <slotNumber>")
    end
    return
  end

  -- /roed chanceX <0-100>
  local chanceIndex = string.match(cmd, "^chance(%d+)$")
  if chanceIndex then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      for _, cfg in pairs(WATCH_SLOTS) do
        cfg.chance = n
      end
      chat("chance set to " .. n .. "% for all watched slots")
    else
      chat("usage: /roed chanceX <0-100>")
    end
    return
  end

  -- /roed timerX <seconds>
  local timerIndex = string.match(cmd, "^timer(%d+)$")
  if timerIndex then
    local n = tonumber(rest)
    if n and n >= 0 then
      for _, cfg in pairs(WATCH_SLOTS) do
        cfg.cd = n
      end
      chat("cooldown set to " .. n .. "s for all watched slots")
    else
      chat("usage: /roed timerX <seconds>")
    end
    return
  end

  if cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode " .. (WATCH_MODE and "ON" or "OFF"))
    return
  end

  if cmd == "on" then
    ENABLED = true
    ensureDB().enabled = true
    chat("ROARRunlimited enabled.")
    return
  end

  if cmd == "off" then
    ENABLED = false
    ensureDB().enabled = false
    chat("ROARRunlimited disabled.")
    return
  end

  if cmd == "reset" then
    WATCH_SLOTS = {}
    ensureDB().slots = {}
    chat("all watched slots cleared.")
    return
  end

  if cmd == "info" then
    chat("enabled: " .. tostring(ENABLED))
    local count = 0
    for slot, cfg in pairs(WATCH_SLOTS) do
      count = count + 1
      chat("slot "..slot.." | chance "..cfg.chance.."% | cd "..cfg.cd.."s")
    end
    if count == 0 then chat("no watched slots.") end
    return
  end

  chat("/roed slotX <n> | chanceX <0-100> | timerX <sec> | watch | on | off | info | reset")
end

-------------------------------------------------
-- Init / RNG / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000))
    math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slots = WATCH_SLOTS
    db.enabled = ENABLED
  end
end)
