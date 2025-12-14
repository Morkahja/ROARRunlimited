ROARRunlimited

ROARRunlimited plays battle-themed emotes when you press selected action bar slots.
Each watched slot can trigger emotes with its own cooldown and chance.
Designed for Vanilla / Turtle WoW (1.12) and Lua 5.0.

Slash command: /roed
Author: babunigaming

Features

Watch unlimited action bar slots

Random built-in battle emotes

Independent cooldown tracking per slot

Configurable trigger chance

Saved settings between sessions

Tutorial (Quick Setup)

Find slot numbers

/roed watch


Press action bar buttons to see their slot numbers in chat.
Toggle off with /roed watch again.

Register a slot

/roed slot1 13
/roed slot2 24


You can register as many slots as you want.

Set emote chance

/roed chance1 40


Sets a 40% chance for emotes to trigger.

Set cooldown

/roed timer1 6


Sets a 6 second cooldown between emotes per slot.

Check status

/roed info

Commands Summary
/roed slotX <slotNumber>    Register an action bar slot
/roed chanceX <0-100>       Set emote chance
/roed timerX <seconds>      Set cooldown
/roed watch                 Toggle slot debug mode
/roed on | off               Enable or disable addon
/roed info                  Show current settings
/roed reset                 Clear all watched slots


X is only a label for readability. There is no limit.

Notes

Uses built-in emotes (/roar, /charge, etc.)

Cooldowns are tracked per slot, not globally

Fully compatible with Turtle WoW API behavior

ROARRunlimited turns your action bar into a war drum.
