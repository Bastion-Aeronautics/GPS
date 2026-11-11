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
function Sphere(A)return Vec(Atan(A.x,A.z),Atan(A.y,A.z),Len(A))end
function Cartesian(A)local z_sign = Cos(A.x) < 0 and -1 or 1 local direction = Vec(Sin(A.x) * Cos(A.y) * z_sign,Sin(A.y) * Cos(A.x) * z_sign,Cos(A.x) * Cos(A.y) * z_sign)return Scale(Norm(direction), A.z)end

RADAR_TYPE              =   property.getNumber("Input Type")

RADAR_PRIORITY          =   property.getNumber("Prioritise")
TOLERANCE               =   property.getNumber("Tolerance")

function onTick()
    has_target = false
    guidance = Vec(0, 0, 0)

    if RADAR_TYPE == 0 then -- direct
        guidance.x = input.getNumber(1)
        guidance.y = input.getNumber(2)
        if input.getNumber(1) ~= 0 or input.getNumber(2) ~= 0 then
            has_target = true
        end

    else -- everything else
        GPS = Vec(input.getNumber(4), input.getNumber(8), input.getNumber(12))
        targets = {}

        if input.getBool(1) == true then -- there is a target
            has_target = true

            -- fetch all targets
	        for i = 1, 8 do
                if (input.getBool((i*4)-3)) then
                    distance = input.getNumber((i*4)-3)
                    radarX = input.getNumber((i*4)-2)
                    radarY = input.getNumber((i*4)-1)
                    targets[i] = Vec(radarX, radarY, distance)
                    last_locked = i
                end
            end

            if RADAR_PRIORITY == 0 then -- default
                guidance = targets[1]
            elseif RADAR_PRIORITY == 1 then -- closest to gps
                lowest = Inf
                candidate = Vec(0, 0, 0)

                for target in targets do
                    deviation = Len(Sub(Cartesian(target), GPS))
                    if deviation < lowest then
                        candidate = target
                    end
                end

                guidance = candidate

            elseif RADAR_PRIORITY == 2 then -- closest to missile
                lowest = Inf
                candidate = Vec(0, 0, 0)

                for target in targets do
                    deviation = target.z -- distance
                    if deviation < lowest then
                        candidate = target
                    end
                end

                guidance = candidate

            elseif RADAR_PRIORITY == 3 then -- last in list
                guidance = targets[last_locked]

            elseif RADAR_PRIORITY == 4 then -- last in list within radius of gps
                for i = #targets, 1, -1 do
                    target = targets[i]
                    deviation = Len(Sub(Cartesian(target), GPS))
                    if deviation < TOLERANCE then
                        guidance = target
                    end
                end
            end
        end
    end

    output.setNumber(1, guidance.x)
    output.setNumber(2, guidance.y)
    output.setBool(1, has_target)
end