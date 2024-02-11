

NRAT = {
  ClassName     				 	= "NRAT",
  verbose        				 	=   0,
  flightgroup_name      		 	= nil,
  flightgroup_route 	 		 	=	{},
  flightgroup_route_height_table 	= nil,
  flightgroup_route_speed_table		= nil,
  departureAirport 					= nil,
  dep_parkingSpot 					= nil,
  destinationAirport 				= nil, 
  nomarkeronwaypoints 				= true,
  nomessage        					= true,
  SpawnObject 						= nil,
  maxgrouponmap 					= 1,
  CIVflight 						= nil,
  alias 							= nil,
  flightgroup 						= nil,
  takeofftype						= SPAWN.Takeoff.Cold,
  defaultROE						= ENUMS.ROE.WeaponHold,
  defaultROT						= ENUMS.ROT.NoReaction,
  randomizeCallsign					= false,
}

NRAT.version="0.0.1"

function NRAT:New( CIVGroup, CIVGroupAlias, WP_table, departureAirport, destinationAirport)

  local self=BASE:Inherit(self, FSM:New() ) -- #NRAT
  
  -- at least needed to run:
  -- a group (planes) to route
  -- 1 wp and departure or destination airport
  -- or two airports
  

	self.flightgroup_name = CIVGroup
	self.alias = CIVGroupAlias
	self.flightgroup_route = WP_table 
	self.departureAirport = departureAirport or nil 
	self.destinationAirport = destinationAirport or nil 
	-- self.StartDelay = StartDelay or nil
	-- self.RepeatInterval = RepeatInterval or nil
	-- self.NumRepeat = NumRepeat or nil


  if false then
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
	
	-- Start State.
  self:SetStartState("Stopped")
	
	  -- Add FSM transitions.
  --                 From State  -->   Event         -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("Running",       "Stop",               "Stopped")     -- Stop FSM.
	

  return self  
	
end

  
local function createFlightGroup(group,self)
    -- Create a flightgroup that will go to Kobuleti.
    local flightgroup=FLIGHTGROUP:New(group)
  
    -- Set destination.    
	flightgroup:SetDefaultROE(self.defaultROE)
	flightgroup:SetDefaultROT(self.defaultROT)
	flightgroup:Activate()
	flightgroup:SetCheckZones(AllZones)
	
	-- if self.departureAirport == nil then
	
		-- if self.flightgroup_route_height_table then
			-- flightgroup:Teleport(self.flightgroup_route[1]:SetAltitude(self.flightgroup_route_height_table[1]),0,true) 
		-- else
			-- flightgroup:Teleport(self.flightgroup_route[1],0,true)
		-- end
	-- end
	
	if self.destinationAirport ~= nil then
		flightgroup:SetDestinationbase(self.destinationAirport)
	end
    
	if self.flightgroup_route ~= nil then
		if self.flightgroup_route_height_table~= nil then
		
			if self.flightgroup_route_speed_table ~= nil then
				for k,v in pairs(self.flightgroup_route) do
					flightgroup:AddWaypoint(v:SetAltitude(self.flightgroup_route_height_table[k]),self.flightgroup_route_speed_table[k],nil,self.flightgroup_route_height_table[k],true)
				end
			else
				for k,v in pairs(self.flightgroup_route) do
					flightgroup:AddWaypoint(v:SetAltitude(self.flightgroup_route_height_table[k]),nil,nil,self.flightgroup_route_height_table[k],true)
				end
			end
		else
			for k,v in pairs(self.flightgroup_route) do
				flightgroup:AddWaypoint(v,nil,nil,nil,true)
			end	
		end
	end
    -- We need to tell the FLIGHTCONTROL that this flight is ready for takeoff. This is done randomly within the next 10 min.
    --flightgroup:SetReadyForTakeoff(true, math.random(600))
	
	if self.destinationAirport ~= nil then
		flightgroup:SetDestinationbase(self.destinationAirport)
		
		function flightgroup:OnAfterPassingWaypoint(From, Event, To, Waypoint)
			local waypoint = Waypoint --Ops.OpsGroup#OPSGROUP.Waypoint
			local flightgroup_route = self.flightgroup_route

			local uid = flightgroup:GetWaypointUID(waypoint)

			local text=string.format("Group passed waypoint UID=%d", uid)
			MESSAGE:New(text, 10, flightgroup:GetName()):ToAll()
			flightgroup:I(text)
			  

			
		end
		  
	
		
	else

		function flightgroup:OnAfterPassingWaypoint(From, Event, To, Waypoint)
		
			local waypoint=Waypoint --Ops.OpsGroup#OPSGROUP.Waypoint
			
			local uid = flightgroup:GetWaypointUID(waypoint)
				
			  local text=string.format("Group passed waypoint UID=%d", uid)

			  MESSAGE:New(text, 10, flightgroup:GetName()):ToAll()
			  flightgroup:I(text)
			  
			-- At final waypoint destroy the group.
			if flightgroup:HasPassedFinalWaypoint()  then
				flightgroup:Despawn(0,false)
			end

		end
	end
	
	
	
	
	
  end

function NRAT:onafterStart(From, Event, To)

	
	local desAirbase=AIRBASE:FindByName(self.destinationAirport)
  local Spawn=SPAWN:NewWithAlias(self.flightgroup_name, self.alias)
  
	if self.randomizeCallsign == true then
		Spawn:InitRandomizeCallsign()
		BASE:I("random Callsign")
	end
	
  	if self.departureAirport == nil then
--	
		local heading = nil
		
		if self.flightgroup_route[2]  then
			heading = self.flightgroup_route[1]:GetAngleDegrees(self.flightgroup_route[1]:GetDirectionVec3(self.flightgroup_route[2]:GetVec3()))
		else
			heading = self.flightgroup_route[1]:GetAngleDegrees(self.flightgroup_route[1]:GetDirectionVec3(desAirbase:GetVec3()))
		end
		
		Spawn:InitHeading(heading)
		
		
		local initposition = self.flightgroup_route[1]:GetVec3()
		
		if self.flightgroup_route_height_table then
			initposition = POINT_VEC3:NewFromVec3(initposition)
			initposition = initposition:SetY( UTILS.FeetToMeters(self.flightgroup_route_height_table[1]) ):GetVec3()	
		end
		
		
		Spawn:OnSpawnGroup(createFlightGroup,self)
    	
		
		self.CIVflight = Spawn:SpawnFromVec3(initposition, nil)
		
	else
	
		if self.dep_parkingSpot == nil then
			
			Spawn:OnSpawnGroup(createFlightGroup,self)
			self.CIVflight = Spawn:SpawnAtAirbase(AIRBASE:FindByName(self.departureAirport),self.takeofftype)
		
		else
			
			Spawn:OnSpawnGroup(createFlightGroup,self)
			self.CIVflight = Spawn:SpawnAtParkingSpot(AIRBASE:FindByName(self.departureAirport),self.dep_parkingSpot,self.takeofftype)				
		
		end
	end
	
	
	return self
end

function NRAT:SetDepartureParkingSpot(parkingSpot)
  self.dep_parkingSpot = parkingSpot or nil
  return self
end

function NRAT:SetAltitude(HeightTable)
	self.flightgroup_route_height_table = HeightTable
	return self
end

function NRAT:SetSpeed(SpeedTable)
	self.flightgroup_route_speed_table = SpeedTable
	return self
end

function NRAT:SetRandomizeCallsign(boole)
	self.randomizeCallsign = boole or false
	return self
end


function NRAT:SetTakeoffType(takeofftype)
	self.takeofftype = takeofftype or SPAWN.Takeoff.Cold
	return self
end

function NRAT:SetDefaultROE(defaultROE)
	self.defaultROE = defaultROE or ENUMS.ROE.WeaponHold
	return self
end

function NRAT:SetDefaultROT(defaultROT)
	self.defaultROT = defaultROT or ENUMS.ROT.NoReaction
	return self
end
