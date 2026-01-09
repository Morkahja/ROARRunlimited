-- ROARRunlimited v1.1 FIXED
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0 safe
-- SavedVariables: ROEDDB
-- Author: babunigaming
-- Slash command: /roed

-------------------------------------------------
-- Battle emote pool
-------------------------------------------------
local EMOTE_TOKENS_BATTLE = {
  "ROAR","CHARGE","CHEER","FLEX"
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOTS = {}   -- [instance] = { slot, chance, cd, last }
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
  if type(ROEDDB.slots) ~= "table" then ROEDDB.slots = {} end
  return ROEDDB
end

local _loaded = false
local function ensureLoaded()
  if _loaded then return end
  local db = ensureDB()

  WATCH_SLOTS = db.slots

  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.chance == nil then cfg.chance = 100 end
    if cfg.cd == nil then cfg.cd = 6 end
    if cfg.last == nil then cfg.last = 0 end
  end

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
-- Emote logic
-------------------------------------------------
local function doBattleEmoteForSlot(cfg)
  if not ENABLED then return end
  if not cfg or not cfg.slot then return end

  local now = GetTime()
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
  if not cmd then return "", "" end
  return cmd, rest
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()

  if WATCH_MODE then
    chat("pressed slot " .. slot)
  end

  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then
      doBattleEmoteForSlot(cfg)
    end
  end

  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands
-------------------------------------------------
SLASH_ROED1 = "/roed"
SlashCmdList["ROED"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  local _, _, slotIndex = string.find(cmd, "^slot(%d+)$")
  if slotIndex then
    local instance = tonumber(slotIndex)
    local slot = tonumber(rest)
    if instance and slot then
      WATCH_SLOTS[instance] = WATCH_SLOTS[instance] or {}
      WATCH_SLOTS[instance].slot = slot
      WATCH_SLOTS[instance].chance = WATCH_SLOTS[instance].chance or 100
      WATCH_SLOTS[instance].cd = WATCH_SLOTS[instance].cd or 6
      WATCH_SLOTS[instance].last = 0
      chat("instance"..instance.." watching slot "..slot)
    else
      chat("usage: /roed slotX <slot>")
    end
    return
  end

  local _, _, chanceIndex = string.find(cmd, "^chance(%d+)$")
  if chanceIndex then
    local instance = tonumber(chanceIndex)
    local n = tonumber(rest)
    if WATCH_SLOTS[instance] and n and n >= 0 and n <= 100 then
      WATCH_SLOTS[instance].chance = n
      chat("instance"..instance.." chance "..n.."%")
    else
      chat("invalid instance or value")
    end
    return
  end

  local _, _, timerIndex = string.find(cmd, "^timer(%d+)$")
  if timerIndex then
    local instance = tonumber(timerIndex)
    local n = tonumber(rest)
    if WATCH_SLOTS[instance] and n and n >= 0 then
      WATCH_SLOTS[instance].cd = n
      chat("instance"..instance.." cd "..n.."s")
    else
      chat("invalid instance or value")
    end
    return
  end

  if cmd == "reset" then
    WATCH_SLOTS = {}
    ensureDB().slots = WATCH_SLOTS
    chat("all instances cleared")
    return
  end

  if cmd == "info" then
    chat("enabled: "..tostring(ENABLED))
    for i, cfg in pairs(WATCH_SLOTS) do
      chat("instance"..i..": slot "..cfg.slot.." | chance "..cfg.chance.."% | cd "..cfg.cd.."s")
    end
    return
  end

  if cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode "..(WATCH_MODE and "ON" or "OFF"))
    return
  end

  if cmd == "on" then ENABLED = true chat("enabled") return end
  if cmd == "off" then ENABLED = false chat("disabled") return end

  chat("/roed slotX <n> | chanceX <0-100> | timerX <sec> | watch | info | reset")
end

-------------------------------------------------
-- Init / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000))
    math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slots = WATCH_SLOTS
    db.enabled = ENABLED
  end
end)
