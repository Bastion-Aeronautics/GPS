Pi=math.pi
Tau=math.pi*2
Sin=math.sin
Cos=math.cos
Tan=math.tan
Acos=math.acos
Asin=math.asin
Atan=math.atan
Sqrt=math.sqrt

Max = math.max
Min = math.min
Floor = math.floor
Ceil = math.ceil
Abs = math.abs

function Clamp(val, min, max) return Min(Max(val, min), max) end
function Lerp(a, b, t) return a + (b - a) * t end
function Map(t, a, b, c, d) return ((t - a) / (b - a)) * (d - c) + c end -- map a-b to c-d according to t
function Round(a) return Floor(a+0.5) end

--- @class vector
--- @function Creates a vector with x, y, and z components
--- @param x number The x-coordinate of the vector.
--- @param y number The y-coordinate of the vector.
--- @param z number The z-coordinate of the vector.
--- @return vector
function Vec(x,y,z)return{x=x,y=y,z=z}end

-- Self explanatory
function Add(A,B)return{x=A.x+B.x,y=A.y+B.y,z=A.z+B.z}end
function Sub(A,B)return{x=A.x-B.x,y=A.y-B.y,z=A.z-B.z}end
function Scale(A,n)return{x=A.x*n,y=A.y*n,z=A.z*n}end
function Dot(A,B)return A.x*B.x+A.y*B.y+A.z*B.z end
function Cross(A,B)return{x=A.y*B.z-A.z*B.y,y=A.z*B.x-A.x*B.z,z=A.x*B.y-A.y*B.x}end

-- Does various things to the length of vectors
function Len(A)return Sqrt(A.x*A.x+A.y*A.y+A.z*A.z)end
function SetLen(A,n)return Scale(Norm(A),n)end
function Norm(A)return Len(A)~=0 and Scale(A,1/Len(A))or{x=0,y=0,z=0}end


--- @function Linearly interpolates between two vectors A and B by t
--- @param A vector The starting vector.
--- @param B vector The ending vector.
--- @param t number The interpolation factor (0 to 1).
--- @return vector
function Lerp(A,B,t)return Add(A,Scale(Sub(B,A),t))end

--- @function Converts physics sensor rotation outputs to a rotation matrix for use in other functions
--- @param rx number The x rotation in radians.
--- @param ry number The y rotation in radians.
--- @param rz number The z rotation in radians.
--- @return vector
function IJK(rx,ry,rz)local cx,cy,cz=Cos(rx),Cos(ry),Cos(rz)local sx,sy,sz=Sin(rx),Sin(ry),Sin(rz) return Vec(Vec(cy*cz,cy*sz,-sy),Vec(-cx*sz+sx*sy*cz,cx*cz+sx*sy*sz,sx*cy),Vec(cx*sy*cz+sx*sz,cx*sy*sz-sx*cz,cx*cy))end

-- Projects vectors from global to local space and vice versa
function Local(A,ijk)return Vec(Dot(A, ijk.x),Dot(A, ijk.y),Dot(A, ijk.z))end
function Global(A,ijk)return Add(Scale(ijk.x, A.x),Add(Scale(ijk.y, A.y),Scale(ijk.z, A.z)))end

-- Projects vectors from cartesian to spherical coordinates and vice versa
function Sphere(A)return Vec(Atan(A.x,A.y),Asin(A.z/Len(A)),Len(A))end
function Cartesian(A)return Vec(A.z*Cos(A.y)*Sin(A.x),A.z*Cos(A.y)*Cos(A.x),A.z*Sin(A.y))end

-- PROPERTIES


-- GENERAL

-- Guidance Delay
-- Boost Delay

-- Mode: 0 = target  1 = waypoint  2 = datalink

-- Eject Direction: 0 = off  1 = up  2 = down  3 = left  4 = right
-- Eject Duration: time in ticks

-- Altitude Mode: off = absolute  on = relative (relative sets y=0 to target altitude)


-- CRUISE
-- Cruise Pattern: 0 = direct  1 = level  2 = arc  3 = terrain follow

-- Altitude: the target altitude for cruising
-- (acts as altitude floor for direct and terrain following mode)

-- Max Angle: max pitch angle allowed to adjust altitude (in degrees)

-- Altitude Gain: pitch per meter of deviation (in degrees)

-- Restrict Pitch During Turns: 
-- (when next aimpoint is more than 90 degrees away, flatten delta vector to stay level)

-- Terrain Follow Margin: the minimum distance to maintain from terrain (in meters)


-- TERMINAL
-- Terminal Distance: distance from target to start terminal phase
-- Terminal Pattern: 0 = direct  1 = top attack  2 = evasive
-- Evasion Amount: max angle to deviate from target (in degrees)


-- RADAR
-- Input Type: off = missile  on = radar
-- Allow Acquire: 0 = radar off  1 = radar on in terminal  2 = radar on at all times
-- Prioritise: 0 = default  1 = closeset to GPS  2 = closest to missile  3 = furthest from missile (anti chaff)  4 = smart (anti chaff anti distractions)


-- CONTROL
-- Pitch Gain
-- Yaw Gain
-- Roll Gain

-- Pitch Trim
-- Yaw Trim
-- Roll Trim

-- Level Angle (deg): the angle to maintain altitude

-- Margin: distance to start turning before waypoints


--[[

States:

0: Waiting for launch
    0:
        Go to last valid target transmitted through hardpoint

    1:
        Bool 1 adds new waypoint, bool 2 resets all waypoints
        Only register valid waypoints (for 60hz waypoint adding to work without tick finagling)

    2:
        Input 32 must be a valid datalink certificate, allows waypoint adding and resetting in flight

1: Launching (detachment turn + waiting for guidance)
    Ends when either guidance delay or ejection turn duration elapses (whichever one is later)

2: Cruising
    0:
        Go directly for the target with no regard for anything else

    1:
        Cruise at the set altitude until the terminal distance from target is reached

    2:
        Arcs over the target (idk how to do that yet ill ask mat)
        Arc peak is set to cruising altitude
        
    3:
        Terrain following, uses front laser to check highest point in terrain and set aimpoint to [margin] meters above that point
        Minimum altitude is set to cruising altitude

    Cruising ends either if:
        The terminal distance is reached
        Radar mode is 2 and a target is seen

3: Terminal
    0:
        Direct, keep going directly at the target
    
    1:
        Top attack, climbs at 45 degrees until [margin] is reached, then dive directly at the target
        
    2:
        Evasive, offsets aimpoint left and right on a sine wave multiplied by remaining distance to target
        (so the deviation converges to 0 as the target is reached)

    Terminal phase ends when the radar sees a target, or never is radar is not enabled

4: Radar
    0:
        Go for the first target in radar, the only available mode if using missile radar mode

    1:
        Go to the target that is closest to GPS target, by using the secondary LUA block

    2:
        Go to the target that is the closest to the missile

    3:
        Go to the target that is last in the target list

    4:
        Goes to the last target on the list that is also within a certain distance to the GPS target
    
]]--



launched = false
state = 0

-- sleeping  boosting  gliding  ejection turning  heading to waypoint  heading to target  popping up  avoiding terrain  diving  evading  target locked
debug_state = 0
elapsed = 0

target = Vec(0,0,0)

guide_delay             =   property.getNumber("Guidance Delay")
boost_delay             =   property.getNumber("Booster Delay")

-- Target, Waypoint, Datalink
mode                    =   property.getNumber("Mode")

eject_direction         =   property.getNumber("Eject Direction")
eject_duration          =   property.getNumber("Eject Duration")

-- Absolute, Relative to target
altitude_mode           =   property.getNumber("Altitude Mode")

roll_control            =   property.getBool("Active Roll Control")

-- Direct, Level, Arc, Terrain
cruise_pattern          =   property.getNumber("Cruise Pattern")
cruise_altitude         =   property.getNumber("Altitude")
max_angle               =   property.getNumber("Max Angle")
altitude_gain           =   property.getNumber("Altitude Gain")

flatten_large_turn      =   property.getBool("Restrict Pitch During Turns")

terrain_margin          =   property.getNumber("Terrain Follow Margin")

terminal_distance       =   property.getNumber("Terminal Distance")
terminal_pattern        =   property.getNumber("Terminal Pattern")
evasion_angle           =   property.getNumber("Evasion Angle") -- in degrees

popup_height            =   property.getNumber("Pop-up Height")
dive_angle              =   property.getNumber("Dive Angle")

radar_type              =   property.getNumber("Input Type")
allow_lock              =   property.getNumber("Allow Acquire")


x_gain                  =   property.getNumber("Pitch Gain")
x_trim                  =   property.getNumber("Pitch Trim")
y_gain                  =   property.getNumber("Yaw Gain")
y_trim                  =   property.getNumber("Yaw Trim")
r_gain                  =   property.getNumber("Roll Gain")
r_trim                  =   property.getNumber("Roll Trim")

aoa                     =   property.getNumber("Level Angle")
margin                  =   property.getNumber("Margin")

function onTick()
    -- reset guidance so theres no accidentally left over steering outputs from the last cycle
    guidance = Vec(0,0,0)

	self={x=input.getNumber(1),y=input.getNumber(2),z=input.getNumber(3),rx=input.getNumber(4),ry=input.getNumber(5),rz=input.getNumber(6),pitch=input.getNumber(15),roll=input.getNumber(16)}
    self.IJK=IJK(self.rx,self.ry,self.rz)

    -- Always TRUE once missile is launched
    if input.getBool(1) then launched = true end

    -- Increment elapsed time if launched
    if launched == true then elapsed = elapsed + 1 end

    -- global delta vector
    g_delta = Sub(target, self)

    -- main state machine
    if state == 0 then
        -- pre launch:

        if launched == true then state = 1 end

    elseif state == 1 then
        -- post launch: perform ejection turn and waiting

        -- turn on booster once the delay is up
        if elapsed > boost_delay then output.setBool(1, true) end

        -- ejection turn
        -- 0 = off  1 = up  2 = down  3 = left  4 = right
        if eject_direction ~= 0 then
            if elapsed <= eject_duration then 
                if      eject_direction == 1 then guidance.y = 1
                elseif  eject_direction == 2 then guidance.y = -1
                elseif  eject_direction == 3 then guidance.x = -1
                elseif  eject_direction == 4 then guidance.x = 1
                end
            end
        end

        -- exit phase once either guidance delay or ejection delay finishes (whichever one is last)
        if elapsed > Max(guide_delay, eject_duration) then state = 2 end

        -- debug state setting
        if elapsed <= eject_duration then debug_state = 3 end -- ejecting
        if elapsed <= guide_delay and elapsed > eject_duration then debug_state = 2 end -- waiting for guidance
        if elapsed > boost_delay and elapsed > eject_duration then debug_state = 1 end -- boosting and done ejecting

    elseif state == 2 then
        -- cruise: go to the target yknow

        if cruise_pattern == 0 then
            -- direct
            guidance = Sphere(Local(g_delta, self.IJK))

            debug_state = 5
        elseif cruise_pattern == 1 then
            

        end

        -- go to terminal when within distance
        if Len(g_delta) < terminal_distance then state = 3 end

    end

    if launched and roll_control then
        -- roll control: keep the missile level with the horizon
        guidance.z = -self.roll * r_gain + r_trim
    else
        guidance.z = 0
    end

    output.setNumber(1, guidance.x)
    output.setNumber(2, guidance.y)
    output.setNumber(3, guidance.z)
    output.setNumber(4, debug_state)
    output.setNumber(8, Len(g_delta))
end