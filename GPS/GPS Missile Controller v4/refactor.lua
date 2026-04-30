PI=math.pi
TAU=math.pi*2
DEG=math.pi/180
function clamp(val, min, max) return math.min(math.max(val, min), max) end
function lerp(a, b, t) return a + (b - a) * t end
function map(t, a, b, c, d) return ((t - a) / (b - a)) * (d - c) + c end -- map a-b to c-d according to t

vec=function(x,y,z) return {x=x,y=y,z=z} end
function vec_add(A,B) return vec(A.x+B.x,A.y+B.y,A.z+B.z) end
function vec_sub(A,B) return vec(A.x-B.x,A.y-B.y,A.z-B.z) end
function vec_scal(A,n) return vec(A.x*n,A.y*n,A.z*n) end
function vec_dot(A,B) return A.x*B.x+A.y*B.y+A.z*B.z end
function vec_div(A,n) return vec_scal(A,1/n) end
function vec_length(A) return math.sqrt(A.x*A.x+A.y*A.y+A.z*A.z) end
function vec_norm(A) return vec_length(A)~=0 and vec_div(A,vec_length(A)) or vec(0,0,0) end
function vec_cross(A,B) return vec(A.y*B.z-A.z*B.y,A.z*B.x-A.x*B.z,A.x*B.y-A.y*B.x) end
function vec_lerp(A,B,t) return vec_add(A,vec_scal(vec_sub(B,A),t)) end
function to_local(A) return vec(vec_dot(A, local_x), vec_dot(A, local_y), vec_dot(A, local_z)) end

-- Property settings --

-- Activation Delay: ticks to wait after launch before activating booster
-- Guidance Delay: ticks to wait after launch before guiding

-- Guidance Mode: 0 for direct, 1 for cruising, 2 for ballistic

-- Ejection Turn: none/up/down, if true missile will pitch down fully after launch to clear the vehicle

-- Roll Control: true/false
-- Roll Gain: proportional gain for roll control, only used if Roll Control is true
-- Max Roll: the angle the missile will roll to during turns, in degrees

-- Terrain Following: true/false
-- Follow Angle: the angle the missile will pitch to to follow terrain
-- Follow Max Distance: the distance from terrain at which the missile will begin to pitch up
-- Follow Min Distance: the distance from terrain at which the missile will reach the max follow angle

-- Max Angle: limits the angle of ascent during cruise phase, in degrees
-- Cruise Altitude: altitude at which missile will cruise until dive phase, in meters
-- Altitude Gain: Proportional gain for altitude control during cruise phase

-- Dive Distance: distance from target at which missile will transition from cruise to dive, in meters

-- Guidance Gain: proportional gain for yaw and pitch control

-- Yaw Trim: added to yaw control before output
-- Pitch Trim: same thing

-- Altitude Trim: the angle the missile needs to hold to maintain altitude

ACTIVATION_DELAY = 		property.getNumber("Activation Delay") -- in ticks
GUIDANCE_DELAY = 		property.getNumber("Guidance Delay")

GUIDANCE_MODE = 		property.getNumber("Guidance Mode") -- 0 for direct, 1 for cruising, 2 for ballistic

EJECTION_TURN = 		property.getNumber("Ejection Turn") -- 0 for none, 1 for up, -1 for down
EJECTION_DURATION = 	property.getNumber("Ejection Duration") -- in ticks, how long to hold the ejection turn

ROLL_CONTROL = 			property.getBool  ("Roll Control")
ROLL_GAIN = 			property.getNumber("Roll Gain")
MAX_ROLL = 				property.getNumber("Max Roll") / 360 -- in degrees
MAX_ROLL_TURN = 		property.getNumber("Max Roll Turn") / 360 -- in degrees, only used if Roll Control is true

TERRAIN_FOLLOWING = 	property.getBool  ("Terrain Following")
FOLLOW_ANGLE = 			property.getNumber("Follow Angle") * DEG -- in degrees
FOLLOW_MAX_DISTANCE = 	property.getNumber("Follow Max Distance")
FOLLOW_MIN_DISTANCE = 	property.getNumber("Follow Min Distance")

MAX_ANGLE = 			property.getNumber("Max Angle") * DEG -- in degrees
CRUISE_ALTITUDE = 		property.getNumber("Cruise Altitude")
ALTITUDE_GAIN = 		property.getNumber("Altitude Gain")

DIVE_DISTANCE = 		property.getNumber("Dive Distance")

GUIDANCE_GAIN = 		property.getNumber("Guidance Gain")

YAW_TRIM = 				property.getNumber("Yaw Trim")
PITCH_TRIM = 			property.getNumber("Pitch Trim")
ROLL_TRIM = 			property.getNumber("Roll Trim")

ALTITUDE_TRIM = 		property.getNumber("Altitude Trim")

elapsed = 0
state = 0
active = false
guidance = false
terminal = false

target = vec(0,0,0)
towards = vec(0,0,0)

yaw_control = 0
pitch_control = 0
roll_control = 0

function onTick()
	launched = input.getBool(1)

	gps_x, gps_y, gps_z = input.getNumber(1), input.getNumber(2), input.getNumber(3)
	gps = vec(gps_x, gps_y, gps_z)

	if input.getNumber(7) ~= 0 then
		target_x, target_y, target_z = input.getNumber(7), input.getNumber(8), input.getNumber(9)
		target = vec(target_x, target_y, target_z)
	end

	radar_x, radar_y = input.getNumber(10), input.getNumber(11)

	radar_lock = (radar_x ~= 0 or radar_y ~= 0)

	pitch_tilt, roll_tilt = input.getNumber(15), input.getNumber(16)

	rx, ry, rz = input.getNumber(4), input.getNumber(5), input.getNumber(6)
	cx, cy, cz = math.cos(rx), math.cos(ry), math.cos(rz)
	sx, sy, sz = math.sin(rx), math.sin(ry), math.sin(rz)

    -- Generates vectors representing the missile's local axes
	local_x = vec(cy*cz,cy*sz,-sy)			            --right
	local_y = vec(-cx*sz+sx*sy*cz,cx*cz+sx*sy*sz,sx*cy) --up
	local_z = vec_cross(local_x,local_y) 	            --forward

	global_offset = vec_sub(target, gps)
	global_offset_norm = vec_norm(global_offset)

	distance_to_target = vec_length(global_offset)
	distance_to_target_horizontal = vec_length(vec(global_offset.x, 0, global_offset.z))

	local_offset = to_local(global_offset)


	-- Guidance logic --
	if launched and elapsed > ACTIVATION_DELAY then active = true end
	if launched and elapsed > GUIDANCE_DELAY then guidance = true end

	roll_setpoint = 0
	roll_control = roll_setpoint - roll_tilt

	-- Terminal radar guidance
	if radar_lock then

		yaw_control = radar_x * TERMINAL_GAIN
		pitch_control = radar_y * TERMINAL_GAIN

	-- Direct guidance
	elseif GUIDANCE_MODE == 0 and guidance then

		terminal = true
		yaw_control = math.atan(local_offset.x, local_offset.z)
		pitch_control = math.atan(local_offset.y, local_offset.z)

	-- Cruise and dive
	elseif GUIDANCE_MODE == 1 and guidance then

		if (distance_to_target_horizontal < DIVE_DISTANCE) 	then state = 1 end
		if (radar_lock and state == 1) 						then state = 2 end

		if state == 0 then
			pitch_setpoint = clamp((CRUISE_ALTITUDE - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)
			towards = to_local(vec(global_offset.x, (math.tan(pitch_setpoint)) * distance_to_target_horizontal, global_offset.z))

			yaw_control = math.atan(towards.x, towards.z)
			pitch_control = math.atan(towards.y, towards.z)
		elseif state == 1 then
			terminal = true
			yaw_control = 	math.atan(local_offset.x, local_offset.z)
			pitch_control = math.atan(local_offset.y, local_offset.z)
		end
	
	-- Ballistic trajectory
	elseif GUIDANCE_MODE == 2 and guidance then

		if state == 0 then
			towards = to_local(vec(global_offset.x, CRUISE_ALTITUDE, global_offset.z))

			if vec_length(towards) > 100 then
				yaw_control = math.atan(towards.x, towards.z)
				pitch_control = math.atan(towards.y, towards.z)
			else
				state = 1
			end

		elseif state == 1 then

			terminal = true
			yaw_control = math.atan(local_offset.x, local_offset.z)
			pitch_control = math.atan(local_offset.y, local_offset.z)
			
		end
	end


	if EJECTION_TURN ~= 0 and elapsed < EJECTION_DURATION then
		pitch_control = EJECTION_TURN
	end

	-- End of guidance logic --

	output.setNumber(1, yaw_control 	* GUIDANCE_GAIN 	+ YAW_TRIM	)
	output.setNumber(2, pitch_control 	* GUIDANCE_GAIN 	+ PITCH_TRIM)
	if ROLL_CONTROL then output.setNumber(3, roll_control * ROLL_GAIN + ROLL_TRIM) end

	output.setBool(1, active)
	output.setBool(2, guidance)
	output.setBool(3, terminal)

	elapsed = launched and elapsed + 1 or 0
end