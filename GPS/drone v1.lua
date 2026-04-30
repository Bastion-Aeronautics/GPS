pi2 = math.pi * 2

function Pc(setpoint, variable, P)
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
altitudeP = 0.001
desiredHeading = 0 -- directly north

desiredX = 0
desiredY = 0 -- initializes to 0 to prevent crash

diveDistance = property.getNumber("Dive Distance")

function onTick()
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2) -- altitude
    gpsZ = input.getNumber(3)

    tiltX = input.getNumber(15)
    tiltY = input.getNumber(16)
    compass = input.getNumber(17)
	
	desiredX = input.getNumber(18)
	desiredY = input.getNumber(19)
	desiredZ = input.getNumber(20) -- altitude
	
	radarX = input.getNumber(22)
	radarY = input.getNumber(23)
	
	armed = input.getBool(21)
	
	desiredAltitude = input.getNumber(21) -- cruise altitude from radio

    desiredPitch = Pc(desiredAltitude, gpsY, altitudeP)

    desiredPitch = clamp(desiredPitch, -0.1, 0.1) -- limit pitch to 18 degrees

	dX = desiredX - gpsX
	dY = desiredY - gpsZ
	
	headingToGPS = (((((math.atan(dX,dY)/pi2)*-2)+1)%2)-1)/2

    yawDifference = ((compass-headingToGPS)%1+1.5)%1-0.5

	distanceToTarget = math.sqrt(dX*dX + dY*dY)
	
	diveAltitude = gpsY - desiredZ
	
	if (distanceToTarget < diveDistance) and armed then
		dive = true
	end

    if dive then
		pitch = Pc(-math.atan(diveAltitude/distanceToTarget)/pi2, tiltX, pitchP)
		if radarX ~= 0 or radarY ~= 0 then
			final = true
		end
	else
    	pitch = Pc(desiredPitch, tiltX, pitchP)
	end
	
	roll = Pc(0, tiltY, -rollP) -- rolls to level
    yaw = Pc(0, yawDifference, -yawP)
	
	if final then
		pitch = radarY
		yaw = radarX*0.5
	end

    output.setNumber(1, clamp(pitch,-1,1)) -- pitch UP is +
    output.setNumber(2, clamp(roll,-1,1)) -- roll RIGHT is +
    output.setNumber(3, clamp(yaw,-1,1)) -- yaw RIGHT is +

	output.setNumber(4, headingToGPS)
	output.setBool(1, dive)
	output.setBool(2, final)
end