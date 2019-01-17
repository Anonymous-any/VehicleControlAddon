

vehicleControlAddonTransmissionBase = {}
vehicleControlAddonTransmissionBase_mt = Class(vehicleControlAddonTransmissionBase)

vehicleControlAddonTransmissionBase.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }


function vehicleControlAddonTransmissionBase:new( mt, name, noGears, timeGears, rangeGearOverlap, timeRanges )
	local self = {}

	if mt == nil then 
		setmetatable(self, vehicleControlAddonTransmissionBase_mt)
	else 
		setmetatable(self, mt)
	end 

	self.name             = name 
	self.numberOfGears    = noGears 
	self.numberOfRanges   = 1 + #rangeGearOverlap
	self.rangeGearFromTo  = {} 
	local ft = { from = 1, to = self.numberOfGears, ofs = 0 }
	local i  = 1
	while true do 
		table.insert( self.rangeGearFromTo, { from = ft.from, to = ft.to, ofs = ft.ofs } )
		if rangeGearOverlap[i] == nil then 
			break 
		end 
		ft.from = ft.from + self.numberOfGears - rangeGearOverlap[i]
		ft.to   = ft.to   + self.numberOfGears - rangeGearOverlap[i]
		ft.ofs  = ft.ofs  + self.numberOfGears - rangeGearOverlap[i]
		i       = i + 1
	end 
	self.rangeGearOverlap = rangeGearOverlap
	self.changeTimeGears  = timeGears
	self.changeTimeRanges = timeRanges

	return self
end 

function vehicleControlAddonTransmissionBase:initGears( vehicle )
	local initGear = false 
	if     vehicle.vcaGear == 0 then 
		initGear = true 
		vehicle:vcaSetState( "vcaGear", 1 )
		vehicle:vcaSetState( "vcaRange", self.numberOfRanges )			
	elseif vehicle.vcaGear < 1 then 
		initGear = true 
		vehicle:vcaSetState( "vcaGear", 1 )
	elseif vehicle.vcaGear > self.numberOfGears then 
		initGear = true 
		vehicle:vcaSetState( "vcaGear", self.numberOfGears )
	end 
	if     vehicle.vcaRange < 1 then   
		initGear = true 
		vehicle:vcaSetState( "vcaRange", 1 )
	elseif vehicle.vcaRange > self.numberOfRanges then 
		initGear = true 
		vehicle:vcaSetState( "vcaRange", self.numberOfRanges )
	end 
	return initGear 
end 

function vehicleControlAddonTransmissionBase:getName()
	return self.name 
end 

function vehicleControlAddonTransmissionBase:getGearText( gear, range )
	local text = ""
	if     self.numberOfRanges <= 1 then 
	elseif self.numberOfRanges == 2 then
		if range <= 1 then 
			text = "L"
		else 
			text = "H"
		end 
	elseif self.numberOfRanges <= 4 then
		if     range <= 1 then 
			text = "L"
		elseif range == 2 then
			text = "M"
		elseif range == 3 then 
			text = "H"
		else
			text = "S" 
		end 
	else
		text = tostring( range )
	end 
	
	if     self.numberOfRanges <= 1 then 
	elseif self.numberOfRanges == 2 then
		if gear <= 1 then 
			text = text .." +"
		else 
			text = text .." -"
		end 
	else 
		text = text.." "..tostring(gear)
	end 
	
	return text 
end 

function vehicleControlAddonTransmissionBase:gearUp( vehicle )
	vehicle:vcaSetState("vcaShifterIndex", 0)
	if vehicle.vcaGear < self.numberOfGears then 
		vehicle:vcaSetState( "vcaGear", vehicle.vcaGear + 1 )
	end 
end 

function vehicleControlAddonTransmissionBase:gearDown( vehicle )
	vehicle:vcaSetState("vcaShifterIndex", 0)
	if vehicle.vcaGear > 1 then 
		vehicle:vcaSetState( "vcaGear", vehicle.vcaGear - 1 )
	end 
end 

function vehicleControlAddonTransmissionBase:rangeUp( vehicle )
	if vehicle.vcaRange < self.numberOfRanges then 
		local o = self.rangeGearOverlap[vehicle.vcaRange]
		vehicle:vcaSetState( "vcaRange", vehicle.vcaRange + 1 )
		if o ~= nil and o ~= 0 and vehicle.vcaShifterIndex <= 0 then 
			vehicle:vcaSetState( "vcaGear", math.max( 1, vehicle.vcaGear - o ) )
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:rangeDown( vehicle )
	if vehicle.vcaRange > 1 then 
		vehicle:vcaSetState( "vcaRange", vehicle.vcaRange - 1 )
		local o = self.rangeGearOverlap[vehicle.vcaRange]
		if o ~= nil and o ~= 0 and vehicle.vcaShifterIndex <= 0 then 
			vehicle:vcaSetState( "vcaGear", math.min( self.numberOfGears, vehicle.vcaGear + o ) )
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:gearShifter( vehicle, number, isPressed )
	if isPressed then 
		local goFwd = nil 
		local list  = self:getGearShifterIndeces( vehicle.vcaShifterLH )
		local num2  = 0
		
		if number == 7 then 
			if not vehicle.vcaShuttleCtrl then 
				return 
			end 
			
			vehicle.vcaShifter7isR1 = true 
			goFwd = false 
			
			num2 = 2
			for i,l in pairs(list) do  
				if i > 1 and l > vehicle.vcaLaunchGear then 
					break 
				end 
				num2 = i  
			end 
		else			
			if vehicle.vcaShuttleCtrl and vehicle.vcaShifter7isR1 == nil then 
				vehicle.vcaShifter7isR1 = true 
			end 
			if vehicle.vcaShifter7isR1 then 
				goFwd = true 
			end 
			
			num2 =  number + number 
		end 
		
		if not vehicle.vcaShifterLH and num2 > 1 then 
			num2 = num2 - 1
		end 
		local index = list[num2] 
		if index == nil then 
			print("Cannot find correct gear for shifter position "..tostring(number))
			return 
		end 
		
		local g, r = self:getBestGearRangeFromIndex( vehicle.vcaGear, vehicle.vcaRange, index )
	
		vehicle:vcaSetState( "vcaShifterIndex", number )
		vehicle:vcaSetState( "vcaGear", g )
		vehicle:vcaSetState( "vcaRange", r )
		vehicle:vcaSetState( "vcaNeutral", false )
		if goFwd ~= nil then
			vehicle:vcaSetState( "vcaShuttleFwd", goFwd )
		end
	else 
		vehicle:vcaSetState( "vcaNeutral", true )
		if vehicle.spec_motorized.motor.vcaLoad ~= nil then  
			vehicle:vcaSetState("vcaBOVVolume",vehicle.spec_motorized.motor.vcaLoad)
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:getGearShifterIndeces( )
	if self.gearShifterIndeces == nil then 
		self.gearShifterLH = highRange
		local numGears = self:getNumberOfRatios()	
		local offset   = 0
		offset = math.max( numGears - 12 )	
		self.gearShifterIndeces = {} 
		for i=1,12 do 
			table.insert( self.gearShifterIndeces, math.max( 1, i + offset ) )
		end 
	end 
			
	return self.gearShifterIndeces
end 

function vehicleControlAddonTransmissionBase:getGearRatio( index )
	return vehicleControlAddonTransmissionBase.gearRatios[index]
end 

function vehicleControlAddonTransmissionBase:getNumberOfRatios( )
	return 12
end 

function vehicleControlAddonTransmissionBase:getRatioIndex( gear, range )
	if self.rangeGearFromTo[range] == nil then 
		return 0
	end
	return self.rangeGearFromTo[range].ofs + gear 
end 

function vehicleControlAddonTransmissionBase:getBestGearRangeFromIndex( oldGear, oldRange, index )
	local i = self:getRatioIndex( oldGear, oldRange )
	
	if index == nil or i == index then 
		return oldGear, oldRange 
	end 
	
	local g = oldGear 
	local r = oldRange 
	
	while true do 
		if self.rangeGearFromTo[r] ~= nil then 
			g = index - self.rangeGearFromTo[r].ofs 
			if 1 <= g and g <= self.numberOfGears then 
				return g, r 
			end 
		end 
		if i < index then 
			r = r + 1 
			if r > self.numberOfRanges then 
				return self.numberOfGears, self.numberOfRanges 
			end 
		else 
			r = r - 1 
			if r < 1 then 
				return 1, 1
			end 
		end 
	end 
	
	return 1, self.numberOfRanges
end 

function vehicleControlAddonTransmissionBase:getRatioIndexList()
	return { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
end 

function vehicleControlAddonTransmissionBase:getRatioIndexListOfGear( gear )
	return self:getRatioIndexList()
end 

function vehicleControlAddonTransmissionBase:getRatioIndexListOfRange( range )
	return self:getRatioIndexList()
end 

function vehicleControlAddonTransmissionBase:actionCallback( vehicle, actionName, keyStatus )
	if     actionName == "vcaGearUp"   then
		self:gearUp( vehicle )
	elseif actionName == "vcaGearDown" then
		self:gearDown( vehicle )
	elseif actionName == "vcaRangeUp"  then
		self:rangeUp( vehicle )
	elseif actionName == "vcaRangeDown"then
		self:rangeDown( vehicle )
	elseif actionName == "vcaShifter1" then
		self:gearShifter( vehicle, 1, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter2" then
		self:gearShifter( vehicle, 2, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter3" then
		self:gearShifter( vehicle, 3, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter4" then
		self:gearShifter( vehicle, 4, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter5" then
		self:gearShifter( vehicle, 5, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter6" then
		self:gearShifter( vehicle, 6, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter7" then 
		self:gearShifter( vehicle, 7, keyStatus >= 0.5 )
	elseif actionName == "vcaShifterLH" and vehicle.vcaShifterIndex > 0 then 
		vehicle:vcaSetState( "vcaShifterLH", not vehicle.vcaShifterLH )
		if not vehicle.vcaNeutral then 
			self:gearShifter( vehicle, vehicle.vcaShifterIndex, keyStatus >= 0.5 )
		end 
	end 
end 

vehicleControlAddonTransmissionIVT = {}
function vehicleControlAddonTransmissionIVT:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmissionIVT,vehicleControlAddonTransmissionBase), "IVT", 1, 0, {}, 0 )
	return self 
end 

vehicleControlAddonTransmission4x4 = {}
function vehicleControlAddonTransmission4x4:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmission4x4,vehicleControlAddonTransmissionBase), "4X4", 4, 750, {2,1,1}, 1000 )
	return self 
end 

vehicleControlAddonTransmission4PS = {}
function vehicleControlAddonTransmission4PS:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmission4PS,vehicleControlAddonTransmissionBase), "4PS", 4, 0, {2,1,1}, 750 )
	return self 
end 

vehicleControlAddonTransmission2x6 = {}
function vehicleControlAddonTransmission2x6:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmission2x6,vehicleControlAddonTransmissionBase), "2X6", 6, 750, {0}, 1000 )
	return self 
end 

vehicleControlAddonTransmissionFPS = {}
function vehicleControlAddonTransmissionFPS:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmissionFPS,vehicleControlAddonTransmissionBase), "FPS", 12, 0, {}, 0 )
	return self 
end 

vehicleControlAddonTransmission6PS = {}
function vehicleControlAddonTransmission6PS:new()
	local self = vehicleControlAddonTransmissionBase:new( Class(vehicleControlAddonTransmission6PS,vehicleControlAddonTransmissionBase), "6PS", 2, 0, {0,0,0,0,0}, 750 )
	return self 
end 
