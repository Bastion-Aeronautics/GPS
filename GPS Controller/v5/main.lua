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
FOLLOW_HEIGHT = 		property.getNumber("Follow Height") -- in meters
FOLLOW_GAIN = 		  	property.getNumber("Follow Pitch Gain")
MAX_FOLLOW_ANGLE = 	 	property.getNumber("Max Follow Angle") * DEG
MIN_FOLLOW_ANGLE = 	 	property.getNumber("Min Follow Angle") * DEG

MAX_ANGLE = 			property.getNumber("Max Angle") * DEG -- in degrees
CRUISE_ALTITUDE = 		property.getNumber("Cruise Altitude")
ALTITUDE_GAIN = 		property.getNumber("Altitude Gain")

DIVE_DISTANCE = 		property.getNumber("Dive Distance")

GUIDANCE_GAIN = 		property.getNumber("Guidance Gain")

YAW_TRIM = 				property.getNumber("Yaw Trim")
PITCH_TRIM = 			property.getNumber("Pitch Trim")
ROLL_TRIM = 			property.getNumber("Roll Trim")

ALTITUDE_TRIM = 		property.getNumber("Altitude Trim")

TERMINAL_GAIN = 		property.getNumber("Terminal Gain")

POP_UP_HEIGHT = 		property.getNumber("Pop-up Height")
POP_UP_DISTANCE = 		property.getNumber("Pop-up Distance")

MAX_DEFLECTION = 		property.getNumber("Max Deflection")

HTTP_DEBUG = 			property.getBool("HTTP Debug")
DEBUG_PORT = 			property.getNumber("Debug Port")

HTTP_COOLDOWN = 10

HTTP_cooldown = HTTP_COOLDOWN

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
	debug_state = 0

	launched = input.getBool(1)

	gps_x, gps_y, gps_z = input.getNumber(1), input.getNumber(2), input.getNumber(3)
	gps = vec(gps_x, gps_y, gps_z)

	if input.getNumber(7) ~= 0 then
		target_x, target_y, target_z = input.getNumber(7), input.getNumber(8), input.getNumber(9)
		target = vec(target_x, target_y, target_z)
	end

	radar_x, radar_y = input.getNumber(10), input.getNumber(11)

	terrain_sensor = input.getNumber(12)

	radar_lock = (radar_x ~= 0 or radar_y ~= 0)

	pitch_tilt, roll_tilt = input.getNumber(15), input.getNumber(16)

	rx, ry, rz = input.getNumber(4), input.getNumber(5), input.getNumber(6)
	cx, cy, cz = math.cos(rx), math.cos(ry), math.cos(rz)
	sx, sy, sz = math.sin(rx), math.sin(ry), math.sin(rz)

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
	roll_control = roll_tilt - roll_setpoint 

	-- Terminal radar guidance
	if radar_lock and terminal then

		debug_state = 6

		yaw_control = (radar_x * TERMINAL_GAIN) / GUIDANCE_GAIN
		pitch_control = (radar_y * TERMINAL_GAIN) / GUIDANCE_GAIN

	-- Direct guidance
	elseif GUIDANCE_MODE == 0 and guidance then

		debug_state = 5

		terminal = true
		yaw_control = math.atan(local_offset.x, local_offset.z)
		pitch_control = math.atan(local_offset.y, local_offset.z)

	-- Cruise and dive
	elseif GUIDANCE_MODE == 1 and guidance then

		if (distance_to_target_horizontal < DIVE_DISTANCE) 	then state = 1 end

		if state == 0 then

			debug_state = 2

			if TERRAIN_FOLLOWING then
				altitude_error = clamp((CRUISE_ALTITUDE - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)
				terrain_error = clamp((FOLLOW_HEIGHT - terrain_sensor) * FOLLOW_GAIN, MIN_FOLLOW_ANGLE, MAX_FOLLOW_ANGLE)

				if terrain_error > 0 then debug_state = 7 end

				pitch_setpoint = math.max(altitude_error, terrain_error)
				
			else
				pitch_setpoint = clamp((CRUISE_ALTITUDE - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)
			end

			towards = to_local(vec(global_offset.x, (math.tan(pitch_setpoint)) * distance_to_target_horizontal, global_offset.z))

			yaw_control = math.atan(towards.x, towards.z)
			pitch_control = math.atan(towards.y, towards.z)
		elseif state == 1 then

			debug_state = 4

			terminal = true
			yaw_control = 	math.atan(local_offset.x, local_offset.z)
			pitch_control = math.atan(local_offset.y, local_offset.z)
		end
	
	-- pop up trajectory
	elseif GUIDANCE_MODE == 2 and guidance then

		if (distance_to_target_horizontal < POP_UP_DISTANCE)then state = 1 end
		if (distance_to_target_horizontal < DIVE_DISTANCE)	then state = 2 end

		if state == 0 then

			debug_state = 2

			if TERRAIN_FOLLOWING then
				altitude_error = clamp((CRUISE_ALTITUDE - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)
				terrain_error = clamp((FOLLOW_HEIGHT - terrain_sensor) * FOLLOW_GAIN, MIN_FOLLOW_ANGLE, MAX_FOLLOW_ANGLE)

				if terrain_error > 0 then debug_state = 7 end

				pitch_setpoint = math.max(altitude_error, terrain_error)
				
			else
				pitch_setpoint = clamp((CRUISE_ALTITUDE - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)
			end

			towards = to_local(vec(global_offset.x, (math.tan(pitch_setpoint)) * distance_to_target_horizontal, global_offset.z))

			yaw_control = math.atan(towards.x, towards.z)
			pitch_control = math.atan(towards.y, towards.z)

		elseif state == 1 then

			debug_state = 3
		
			pitch_setpoint = clamp(((target.y + POP_UP_HEIGHT) - gps_y) * ALTITUDE_GAIN, -MAX_ANGLE, MAX_ANGLE)

			towards = to_local(vec(global_offset.x, (math.tan(pitch_setpoint)) * distance_to_target_horizontal, global_offset.z))

			yaw_control = math.atan(towards.x, towards.z)
			pitch_control = math.atan(towards.y, towards.z)

		elseif state == 2 then

			debug_state = 4

			terminal = true
			yaw_control = 	math.atan(local_offset.x, local_offset.z)
			pitch_control = math.atan(local_offset.y, local_offset.z)
		end
		
	end


	if launched and EJECTION_TURN ~= 0 and elapsed < EJECTION_DURATION then

		debug_state = 1

		if EJECTION_TURN == 1 then
			pitch_control = 1
		elseif EJECTION_TURN == 2 then
			pitch_control = -1
		elseif EJECTION_TURN == 3 then
			yaw_control = -1
		elseif EJECTION_TURN == 4 then
			yaw_control = 1
		end
	end

	-- End of guidance logic --

	output.setNumber(1, clamp(yaw_control * GUIDANCE_GAIN + YAW_TRIM, -MAX_DEFLECTION, MAX_DEFLECTION))
	output.setNumber(2, clamp(pitch_control * GUIDANCE_GAIN + PITCH_TRIM, -MAX_DEFLECTION, MAX_DEFLECTION))
	if ROLL_CONTROL then output.setNumber(3, roll_control * ROLL_GAIN + ROLL_TRIM) end

	output.setBool(1, active)
	output.setBool(2, guidance)
	output.setBool(3, terminal)
	
	output.setNumber(4, debug_state)
	-- 0: waiting 1: ejecting 2: cruising 3: popping up 4: diving 5: direct 6: terminal 7: terrain


	-- HTTP Debugging  system --
	if HTTP_DEBUG and HTTP_cooldown == 0 and active then
		async.httpGet(DEBUG_PORT, '/updatePosition?x='..gps_x..'&y='..gps_y..'&z='..gps_z)
		HTTP_cooldown = HTTP_COOLDOWN
	end

	HTTP_cooldown = HTTP_cooldown - 1
	elapsed = launched and elapsed + 1 or 0
end

function httpReply(port, request_body, response_body)
    -- nothing for now
end