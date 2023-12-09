
_SETTINGS:SetEraWWII()
_SETTINGS:SetMetric()
_SETTINGS:SetPlayerMenuOn()

local enemies = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryAirplane():FilterStart()
local RP = ZONE:New("Controlled Zone"):GetCoordinate()
local ww2gci = ZONE:New("Controlled Zone"):Trigger(enemies)
ww2gci:SetCheckTime(20)
local gcidraw = ZONE:New("Controlled Zone"):DrawZone(-1,{1,0,0},nil,{1,0,0},0.1,2,true)
local knownbaddies = SET_GROUP:New()
local baddiesseen = {}
local minheight = 500 --ft
local thresheight = 90 -- 10% chance to find a low flying group
local thresblur = 75 -- 25% chance to escape the radar overall

MESSAGE.SetMSRS(MSRS.path,MSRS.port,MSRS.google,38.4,radio.modulation.AM,nil,nil,MSRS.Voices.Google.Standard.de_DE_Standard_D,coalition.side.RED,1,"RLM",RP)

function Announce(Baddy)
  local badcoord = Baddy:GetCoordinate()
  local badsize = Baddy:CountAliveUnits()
  local BR = badcoord:ToStringBR(RP)
  BR = string.gsub(BR,"BR,","Richtung und Distanz, ")
  BR = string.gsub(BR,"for","in")
  BR = string.gsub(BR,"°"," Grad")
  local text = string.format("Feindliche Gruppe, %s", BR)
  --text = '<prosody rate="fast">'..text..'</prosody>'
  MESSAGE:New(text,15,"RLM"):ToSRSRed():ToRed()
end

--- Create some radar blur - doesn't take into account further radar sweeps
-- and changes in AGL over time.
function RadarBlur(Group)
  local found = true
  local group = Group -- Wrapper.Group#GROUP
  local AGL = UTILS.MetersToFeet(group:GetAltitude(true)) -- get AGL in feet
  local fheight = math.floor(math.random(1,10000)/100)
  local fblur = math.floor(math.random(1,10000)/100)
  if AGL <= minheight and fheight < thresheight then found = false end
  if fblur > thresblur then found = false end
  return found
end

function ww2gci:OnAfterEnteredZone(From,Event,To,Controllable)
  local group = Controllable -- Wrapper.Group#GROUP
  if group and group:IsAlive() and (not baddiesseen[group:GetName()]) and RadarBlur(group) then
    local text = 'Achtung! An alle Einheiten! Neuer Feindkontakt!'
    MESSAGE:New(text,15,"RLM"):ToSRSRed():ToRed()
    Announce(group)
    knownbaddies:AddGroup(group,true)
    baddiesseen[group:GetName()] = true
  end
end

function ww2gci:OnAfterLeftZone(From,Event,To,Controllable)
  local group = Controllable -- Wrapper.Group#GROUP
  if group and group:IsAlive() and baddiesseen[group:GetName()] then
    local text = 'Achtung! An alle Einheiten! Feindkontakt abgebrochen! Letzte bekannte Position:'
    --text = '<prosody rate="fast">'..text..'</prosody>'
    MESSAGE:New(text,15,"RLM"):ToSRSRed():ToRed()
    Announce(group)
    knownbaddies:Remove(group:GetName(),true)
    baddiesseen[group:GetName()] = false
  end
end

function Picture()
  if knownbaddies:CountAlive() > 0 then
    local text = "Achtung! An alle Einheiten! Lagebild!"
    MESSAGE:New(text,15,"RLM"):ToSRSRed():ToRed()
    knownbaddies:ForEachGroupAlive(
      function(grp)
        Announce(grp)
      end
    )
  else
    local text = 'Achtung! An alle Einheiten! Lagebild! Keine Feindkontakte!'
    --text = '<prosody rate="fast">'..text..'</prosody>'
    MESSAGE:New(text,15,"RLM"):ToSRSRed():ToRed()
  end
end

local timer = TIMER:New(Picture)
timer:Start(10,60)


