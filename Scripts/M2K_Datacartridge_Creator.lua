-------------------------------------
-- M2K Datacartridge
-------------------------------------

--[[

Mirage 2000C Datacartridge Generator v1.0
Author: Applevangelist

Prerequisites

* Familiarize yourself with M2K data cartridges or DTCSs in the flight manual, section 19-6
* Desanitize the mission scripting environment in here C:\Program Files\Eagle Dynamics\DCS World.Openbeta\Scripts\MissionScripting.lua or 
  here C:\Program Files\Eagle Dynamics\DCS World\Scripts\MissionScripting.lua depending on which version of DCS you are running
  Add two minus signs in front of the sanitizeModule lines, they should look like this:
      --sanitizeModule('os')
      --sanitizeModule('io')
      --sanitizeModule('lfs')
  This is necessary, so the file can be written to disk
* Ensure that the directory Datacartridges exists here
  C:\Users\<yourname>\Saved Games\DCS\Datacartridges
  or
  C:\Users\<yourname>\Saved Games\DCS.openbeta\Datacartridges
  depending on which version of DCS you are running
* Note - Currently the Mirage does not detect freshly created DTCs in-game. It will find the cartrige after the next restart, however.

Creating a data cartridge

While in-game, press F10 to bring up the map. Place a marker on the map and enter this text: "M2K New CAP_Kutaisi". This will create a new data set called
"CAP_Kutaisi" - this will show up on the cartridge in-game later on when selecting a cartride. Mission names must not contain spaces or pattern matching
magic characters (http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_(Regular_Expressions)), i.e. none of these: %,-,.,?,+,*

"M2K" is the keyword which always needs to come first to detect an entry.

Creating a new data set deletes existing entries, so if you made a mistake you can start anew.

Assuming we are starting from Kutaisi, let's create our first waypoint. Put a marker on the start of the runway 07 in Kutaisi and enter this text:
"M2K BUT1 name=Kutaisi cp=67". This will create our first waypoint (BUT) with the number one. The runway heading is cp, in this case 67 degrees magnetic. The altitude is automatically
taken as land height at this point. With cp as a parameter, rd (route desiree) is automatically set to equal cp, and pd (glidepath) is set to 3.5.

Create another waypoint on the map, by placing a new marker on the map, e.g. "M2K BUT2 alt=5000". This creates waypoint two, with an altitude of 5000 meters.

You may create up to 20 waypoints for a single plan. 1-10 waypoints will be stored the the Mirage's INS system under BUT 11-20. If you use more than 10 waypoints, the Mirage will start
adding waypoints at BUT1, overwriting whatever is there.

Known keywords (all optional) for BUT creation are: "alt", "cp", "pd", "rd" and "name". The format is always (except for name) "key=xxxx.xx" where x are numbers and . the decimal separator, e.g. alt=5000.23. 
The format for "name" is "name=abc" where abc is alphanumeric, no spaces, no special characters.
Entries are separated by spaces. Special keywords are "FT" to switch to foot for altitude entries and "KM" to switch back to meters.
Example with multiple parameters given "M2K BUT4 alt=25000 FT rd=267" - BUT four, altitude 25000ft, route desiree 267 degrees.

Creating a new BUT with an existing number will overwrite the existing BUT, i.e. you can correct entries this way.

Creating BAD entries

If you want e.g. to use this system to plan for a preplanned strike, you can amend a BUT with BAD (delta deviation) information. This is done like so:
Let's assume you have created BUT3 to be your ingress point for the strike: "M2K BUT3 alt=150 FT rd=90". Now put a marker on the target area in the map
and add this text: "M2K BAD3". This will amend the info for BUT3 with the delta distance information and delta altitude (ground height automatically assumed).
Optionally you can use the keyword "dalt" to give the delta altitude yourself: "M2K BAD3 dalt=-56" (foot in this case, because we switched to imperial prior.

Creating a new BAD with an existing number will overwrite the existing BAD information, i.e. you can correct entries this way.

Saving
Place a marker and add this text: "M2K Save". This will save the DTC data to your directory. The filname will be "mapname_missionname.dtc", e.g. "Caucasus_CAP_Kutaisi.dtc"

--]]

local debug = true
local CartridgeGenerator = MARKEROPS_BASE:New("M2K",{"New","BUT","BAD","Save","FT","KM"},false)
local map = UTILS.GetDCSMap()

local cartridge = REPORT:New("--Mirage 2000C Data Cartridge")
local waypoints = {}
local wptcount = 0
local metric = true

if lfs == nil then
  env.info("*****Note - lfs and os need to be desanitized for M2K Datacatridge Generator to work!")
else

  local path = lfs.writedir().."Datacartridges\\"
  local filename = ""
  
  function CartridgeGenerator:OnAfterMarkChanged(From,Event,To,Text,Keywords,Coord,idx)
    self:I("**** Mark Changed *****")
    self:I("**** Text = "..tostring(Text))
    local function FindInKeywords(word)
      local found = false
      for _,_word in pairs(Keywords) do
        if string.lower(word) == string.lower(_word) then 
          found = true
        end
      end
      return found
    end
    
    local function FillWptTable(name,number,lat,lon,alt,cp,pd,rd,dalt,off_lat,off_lon)
      local wpttable = {
          name = name,
          number = number,
          text = nil,
          lat = lat,
          lon = lon,
          alt = alt,
          cp = cp,
          pd = nil,
          rd = nil,
          off_lat = off_lat,
          off_lon = off_lon,
          dalt = dalt,
        }
      if cp then 
        wpttable.rd = rd or cp
        wpttable.pd= pd or 3.5
      end
      return wpttable
    end
    
    local function GetKeyValue(Key)
      return string.match(Text,Key.."=([%d%p]+)")
    end
    
    local function GetKeyValueText(Key)
      return string.match(Text,Key.."=([%a%p]+)")
    end
    
    local function CheckOverwrite(number)
      local exists, index
      for _id,_data in pairs(waypoints) do
        if _data.number == number then
          exists = true
          index = _id
          break
        end
      end
      if exists then
        waypoints[index] = nil
      end
      return
    end
    
    local function GetWaypoint(number)
      local exists, index
      for _id,_data in pairs(waypoints) do
        if _data.number == number then
          exists = true
          index = _id
          break
        end
      end
      if exists then
        return waypoints[index]
      end
      return nil
    end
    
    if FindInKeywords("FT") then
      metric = false
    end
    
    if FindInKeywords("KM") then
      metric = true
    end
    
    if FindInKeywords("New") then
      local name = string.match(Text,"%s([%w%d%p]+)$")
      self:I("**** Name = "..tostring(name))
      cartridge = REPORT:New("--Mirage 2000C Data Cartridge")
      cartridge:Add(string.format("\nterrain='%s'\naircraft='M-2000C'\ndate='23/01/2003'\nname='%s'\nwaypoints={}\n",map,name))
      self:I("**** Cartridge\n"..tostring(cartridge:Text()))
      waypoints = nil
      waypoints = {}
      wptcount = 0
      MESSAGE:New("New DTC "..name.." created!",10,"M2K DTC"):ToAllIf(debug):ToLog()
      filename = name
    end
    
    if FindInKeywords("BUT") then
      wptcount = wptcount+1
      local name = "Waypoint "..tostring(wptcount)
      local number = string.match(Text,"BUT([%d]+)") or wptcount
      CheckOverwrite(number)
      local lat, lon = coord.LOtoLL( Coord:GetVec3() )
      local lattxt, lontxt = UTILS.tostringLLM2KData(lat,lon,4)
      local alt = GetKeyValue("alt") or Coord:GetLandHeight()
      if not metric then
        alt = UTILS.FeetToMeters(tonumber(alt))
      end
      --local dalt = GetKeyValue("dalt")
      local cp = GetKeyValue("cp")
      local pd = GetKeyValue("pd")
      local rd = GetKeyValue("rd")
      local tname = GetKeyValueText("name")
      if not tname then tname = name end
      if cp then
        pd = pd or 3.5
        rd = rd or cp
      end
      local text = string.format('waypoints[%d] = { name="%s", lat="%s", lon="%s", alt=%.1f',tonumber(number), tname, lattxt, lontxt, tonumber(alt))
      if cp then text = text .. string.format(', cp=%.1f',cp) end -- runway heading
      if pd then text = text .. string.format(', pd=%.1f',pd) end -- glide path
      if rd then text = text .. string.format(', rd=%.1f',rd) end -- route desiree
      text = text .. ' }'
      local wpt = FillWptTable(tname,number,lattxt,lontxt,alt,cp,pd,rd)
      wpt.text = text
      waypoints[name]=wpt
      MESSAGE:New("New BUT created!",10,"M2K DTC"):ToAllIf(debug):ToLog()
      MESSAGE:New(text,10,"M2K DTC"):ToAllIf(debug):ToLog()
      UTILS.PrintTableToLog(waypoints,1)
    end
    
    if FindInKeywords("BAD") then
      wptcount = wptcount+1
      local name = "Waypoint BAD "..tostring(wptcount)
      local number = string.match(Text,"BAD([%d]+)") or wptcount
      local wpt = GetWaypoint(number)
      if not wpt then
        MESSAGE:New("No matching BUT waypoint for this BAD!",10,"M2K DTC"):ToAllIf(debug)
        return
      end
      name = "Waypoint "..tostring(number)
      local tname = wpt.name
      local lat, lon = coord.LOtoLL( Coord:GetVec3() )
      local off_lat, off_lon = UTILS.tostringLLM2KData(lat,lon,4)
      local dalt = GetKeyValue("dalt") or Coord:GetLandHeight()
      if not metric then
        dalt = UTILS.FeetToMeters(tonumber(dalt))
      end
      dalt = dalt - wpt.alt
      --local wpt = FillWptTable(name,number,wpt.lat,wpt.lon,wpt.alt,wpt.cp,wpt.pd,wpt.rd,dalt,off_lat,off_lon)
      --local text = wpt.text
      --text = string.gsub(text," }$","")
      local text = string.format('waypoints[%d] = { name="%s", lat="%s", lon="%s", alt=%.1f',tonumber(number), tname, wpt.lat, wpt.lon, tonumber(wpt.alt))
      if wpt.cp then text = text .. string.format(', cp=%.1f',wpt.cp) end -- runway heading
      if wpt.pd then text = text .. string.format(', pd=%.1f',wpt.pd) end -- glide path
      if wpt.rd then text = text .. string.format(', rd=%.1f',wpt.rd) end -- route desiree
      text = text .. string.format(', off_lat="%s", off_lon="%s", dalt=%.1f',off_lat,off_lon,dalt)
      text = text .. ' }'
      wpt.name = tname
      wpt.off_lat = off_lat
      wpt.off_lon = off_lon
      wpt.dalt = dalt
      wpt.text = text
      waypoints[name]=wpt
      self:I(text)
      MESSAGE:New("BUT updated with BAD!",10,"M2K DTC"):ToAllIf(debug)
      MESSAGE:New(text,10,"M2K DTC"):ToAllIf(debug)
      UTILS.PrintTableToLog(waypoints,1)
    end
    
    if FindInKeywords("Save") then
      local filename = map.."_"..filename..".dtc"
      for _,_entry in pairs(waypoints) do
        cartridge:Add(_entry.text)
      end
      self:I(cartridge:Text())
      local success = UTILS.SaveToFile(path,filename,cartridge:Text())
      MESSAGE:New("Save successful: "..tostring(success),10):ToAllIf(debug):ToLog()
    end
    
  end

end
