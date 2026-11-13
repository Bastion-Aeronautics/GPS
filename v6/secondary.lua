m=math

Pi=m.pi
Tau=m.pi*2
Inf=m.huge
Deg=m.pi/180
Sin=m.sin
Cos=m.cos
Tan=m.tan
Acos=m.acos
Asin=m.asin
Atan=m.atan
Sqrt=m.sqrt

Max = m.max
Min = m.min
Floor = m.floor
Ceil = m.ceil
Abs = m.abs

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
function Sphere(A)local horizontal = Sqrt(A.x*A.x + A.z*A.z)return Vec(Atan(A.x,A.z), Atan(A.y,horizontal), Len(A))end
function Cartesian(A)local horizontal = Cos(A.y) * A.z return Vec(Sin(A.x) * horizontal, Sin(A.y) * A.z, Cos(A.x) * horizontal)end

RADAR_TYPE              =   property.getBool("Input Type")

RADAR_PRIORITY          =   property.getNumber("Prioritise")
TOLERANCE               =   property.getNumber("Tolerance")

guidance = Vec(0, 0, 0)

self = {}
function onTick()
    
    if RADAR_TYPE == true then -- direct
        guidance = Vec(0, 0, 0)
        guidance.x = input.getNumber(1)
        guidance.y = input.getNumber(2)
        if input.getNumber(1) ~= 0 or input.getNumber(2) ~= 0 then
            has_target = true
        end

    else -- everything else
        guidance = Vec(0, 0, 0)
        self.GPS = Vec(input.getNumber(4), input.getNumber(8), input.getNumber(12))
        self.IJK = IJK(input.getNumber(16), input.getNumber(20), input.getNumber(24))

        targets = {}
        target_count = 0

        -- fetch all targets
        for i = 1, 8 do
            if (input.getBool((i*4)-3)) then
                distance = input.getNumber((i*4)-3)
                radarX = input.getNumber((i*4)-2)
                radarY = input.getNumber((i*4)-1)
                target = Global(Cartesian(Vec(radarX*Pi, radarY*Pi, distance)), self.IJK)
                if Len(Sub(target, self.GPS)) <= TOLERANCE then
                    targets[i] = target
                    target_count = target_count + 1
                    last_locked = i
                end
            end
        end

        if target_count > 0 then
            if RADAR_PRIORITY == 0 then -- default
                for i = 1, 8 do
                    if targets[i] then
                        guidance = targets[i]
                        break
                    end
                end

            elseif RADAR_PRIORITY == 1 then -- closest to gps
                lowest = Inf
                candidate = Vec(0, 0, 0)
                for _, target in pairs(targets) do
                    deviation = Len(Sub(target, self.GPS))
                    if deviation < lowest then
                        lowest = deviation
                        candidate = target
                    end
                end
                guidance = candidate

            elseif RADAR_PRIORITY == 2 then -- closest to missile
            
                lowest = Inf
                candidate = Vec(0, 0, 0)
                for _, target in pairs(targets) do
                    deviation = Len(target)
                    if deviation < lowest then
                        lowest = deviation
                        candidate = target
                    end
                end
                guidance = candidate

            elseif RADAR_PRIORITY == 3 then -- last in list
            
                guidance = targets[last_locked]

            elseif RADAR_PRIORITY == 4 then -- last in list within radius of gps
                for i = 8, 1, -1 do
                    if targets[i] then
                        guidance = targets[i]
                        break
                    end
                end
            end
        end
    end

    output.setNumber(1, guidance.x)
    output.setNumber(2, guidance.y)
    if RADAR_TYPE == false then output.setNumber(3, guidance.z) end
    output.setNumber(4, target_count)
end