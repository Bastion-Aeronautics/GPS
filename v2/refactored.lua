pi2 = math.pi * 2
sin = math.sin
cos = math.cos
tan = math.tan
atan = math.atan

function Pc(setpoint, variable, P)
    if setpoint == nil or variable == nil then return 0 end
    local error = setpoint - variable
    return error * P
end

function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

pitchP = property.getNumber("Pitch P")
rollP = property.getNumber("Roll P")
yawP = property.getNumber("Yaw P")
altitudeP = property.getNumber("Altitude P")

pitchMax = property.getNumber("Max Pitch") / 360 -- Max angle when under altitude control

rollMax = property.getNumber("Turn Roll Angle") / 360 -- Bank angle when turning

cruiseAltitude = property.getNumber("Default Cruise Altitude")
diveDistance = property.getNumber("Default Dive Distance")

gain = property.getNumber("Terminal Gain")

avoidHeight = property.getNumber("Terrain Avoidance Threshold")

mode = 1 -- start in cruise

-- henryshallah let me not misspell random functions

function onTick()
    -- Physics Sensor
    currentX = input.getNumber(1) -- GPS X
    currentY = input.getNumber(2) -- altitude
    currentZ = input.getNumber(3) -- GPS Y

    tiltX = input.getNumber(4) -- Pitch
    tiltY = input.getNumber(5) -- Roll
    compass = input.getNumber(6) -- Compass (horrible)
    
    ID = input.getNumber(12) -- Missile group ID for datalink (Bool 10 to 32)

    terrain = input.getNumber(13) -- Distance from terrain

    terrainHeight = currentY - terrain

    radarYaw = input.getNumber(14) -- Radar Yaw
    radarPitch = input.getNumber(15) -- Radar Pitch

    locked = radarYaw ~= 0 or radarPitch ~= 0

    selected = (input.getNumber(16) == ID) or input.getBool(8) -- ID 1 would be Bool 10

    -- Datalink
    -- (Bool 1) Launch (permanently on after launch)
    if (input.getBool(1) and selected) then launched = true end 

    launchPulse = launched and not lastLaunched -- True only on the tick that launched changes from false to true
    lastLaunched = launched

    -- (Bool 2) Update target coordinate (7,8,9)
    if (input.getBool(2) and selected) or ((targetX == nil or targetY == nil or targetZ == nil) and launchPulse) then 
        targetX = input.getNumber(7) -- GPS X
        targetY = input.getNumber(8) -- altitude
        targetZ = input.getNumber(9) -- GPS Y
    end
    
    -- (Bool 3) Update cruise altitude (10)
    if (input.getBool(3) and selected) or (cruiseAltitude == nil and launchPulse) then
        cruiseAltitude = input.getNumber(10)
    end

    -- (Bool 4) Update dive distance (11)
    if (input.getBool(4) and selected) or (diveDistance == nil and launchPulse) then
        diveDistance = input.getNumber(11)
    end
    
    -- (Bool 5) Update mode (6: Loiter or Dive)
    if (input.getBool(5) and selected) then
        armed = input.getBool(6)
    end

    -- (Bool 7) Self destruct (optional)
    if (input.getBool(7) and selected) then
		output.setBool(2, true)
    end

    -- (Bool 8) Select all drones

    -- (Bool 9) No radar mode (for purely gps guidance)
    if (input.getBool(9) and selected) then
        noRadar = input.getBool(10)
    end

	if launched then
		-- Guidance code
		deltaX = targetX - currentX -- GPS X
		deltaY = targetY - currentY -- Altitude
		deltaZ = targetZ - currentZ -- GPS Y

		targetHeading = (((((math.atan(deltaX,deltaZ)/pi2)*-2)+1)%2)-1)/2

		GPSdistanceToTarget = math.sqrt(deltaX*deltaX + deltaZ*deltaZ)
		realDistanceToTarget = math.sqrt(deltaX*deltaX + deltaY*deltaY + deltaZ*deltaZ)

		diveAngleToTarget = -math.atan(deltaY/GPSdistanceToTarget)/pi2

		altitudeHold = Pc(altitudeSetpoint, currentY, altitudeP)


		---- Guidance logic ----

		altitudeSetpoint = math.max(cruiseAltitude, (terrainHeight + avoidHeight)) -- Don't go below 50m above terrain

		pitchSetpoint = clamp(altitudeHold, -pitchMax, pitchMax)
		headingSetpoint = targetHeading
		rollSetpoint = -clamp((((compass-headingSetpoint)%1+1.5)%1-0.5)/4, -rollMax, rollMax)

		if GPSdistanceToTarget < diveDistance and armed then
			mode = 2
		end

		if locked and not noRadar then
			mode = 3
		end


		-- Cascade control to fins
		yawDifference = ((compass-headingSetpoint)%1+1.5)%1-0.5

		if mode == 1 then
			yaw = Pc(0, yawDifference, -yawP)
			pitch = Pc(pitchSetpoint, tiltX, pitchP)
			roll = Pc(rollSetpoint, tiltY, -rollP)
		end

		if mode == 2 then
			yaw = Pc(0, yawDifference, -yawP)
			pitch = Pc(-diveAngleToTarget, tiltX, pitchP)
			roll = Pc(rollSetpoint, tiltY, -rollP)
		end

		if mode == 3 then
			yaw = radarYaw*gain
			pitch = radarPitch*gain
		end

		-- Yaw and pitch are first so output composite can be fed directly into missile fin
		output.setNumber(1,clamp(yaw,-1,1)) -- Right +
		output.setNumber(2,clamp(pitch,-1,1)) -- Up +
		output.setNumber(3,clamp(roll,-1,1)) -- Right +

		-- Datalink feedback
		output.setNumber(4, currentX)
		output.setNumber(5, currentY)
		output.setNumber(6, currentZ)

		output.setNumber(14, GPSdistanceToTarget)
		
		output.setNumber(8, pitchSetpoint)
		output.setNumber(9, rollSetpoint)
		output.setNumber(10, headingSetpoint)
		
		output.setNumber(11, tiltX) -- pitch
		output.setNumber(12, tiltY) -- roll
		output.setNumber(13, compass)

		output.setBool(1, launched)
		
		if (altitudeSetpoint - currentY > 50) and (mode == 1) then
			output.setNumber(7, 0)
		else
			output.setNumber(7, mode)
		end	
	else
		output.setNumber(7, -1)
	end
end