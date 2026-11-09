Pi=math.pi
Tau=math.pi*2
Sin=math.sin
Cos=math.cos
Tan=math.tan
Acos=math.acos
Asin=math.asin
Atan=math.atan
Sqrt=math.sqrt

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
-- Prioritise: 0 = default  1 = closeset to GPS  2 = closest to missile  3 = furthest from missile (anti chaff)


-- CONTROL
-- Pitch Gain
-- Yaw Gain
-- Roll Gain

-- Pitch Trim
-- Yaw Trim
-- Roll Trim

-- Level Angle (deg): the angle to maintain altitude

-- Margin: distance to start turning before waypoints


function onTick()
	self={x=input.getNumber(1),y=input.getNumber(2),z=input.getNumber(3),rx=input.getNumber(4),ry=input.getNumber(5),rz=input.getNumber(6)}
    self.IJK=IJK(self.rx,self.ry,self.rz)



end