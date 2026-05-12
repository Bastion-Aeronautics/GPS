prop = input.property()

pi=math.pi
tau=math.pi*2
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

function getIJK(rx, ry, rz)
	local cx, cy, cz = math.cos(rx), math.cos(ry), math.cos(rz)
	local sx, sy, sz = math.sin(rx), math.sin(ry), math.sin(rz)
    local local_x = vec(cy*cz,cy*sz,-sy)			            --right
	local local_y = vec(-cx*sz+sx*sy*cz,cx*cz+sx*sy*sz,sx*cy) --up
	local local_z = vec_cross(local_x,local_y)
    return vec(local_x, local_y, local_z)
end

function toLocal(A, ijk) vec(vec_dot(A, ijk.x), vec_dot(A, ijk.y), vec_dot(A, ijk.z)) end
function toGlobal(A, ijk) vec_add(vec_scal(ijk.x, A.x), vec_add(vec_scal(ijk.y, A.y), vec_scal(ijk.z, A.z))) end


-- Property Settings --


-- LAUNCHING --

-- Activation delay:    TICKS to wait after launch to activate booster
-- Guidance delay:      TICKS to wait after launch to allow guidance

-- Ejection Turn:       0. None    1. Up    2. Down    3. Left    4. Right
-- Ejection Duration:   TICKS to perform ejection turning


-- GUIDANCE --

-- Guidance:            0. Direct    1. Cruising
-- Guidance Law:        0. Direct    1. Proportional Navigation (PN)
-- Guidance Factor:     Multiplier for guidance control signals (useful for PN tuning)


-- PATHING --

-- Cruise Mode:         False: Absolute altitude    True: Relative to target Y
-- Cruise Altitude:     Altitude to maintain when cruising

-- MAX Angle:           Maximum pitch angle allowed for altitude controller
-- MIN Angle:           Minimum pitch angle allowed for altitude controller

-- Altitude Gain:       Altitude Controller Gain in [ Degrees / Meter ]

-- Self Tune: False: Normal, go to target as usual    True: Run self tuning routine



SELF_TUNE = prop("Mode") 
function onTick()

    current_X, current_Y, current_Z = input.getNumber(1), input.getNumber(2), input.getNumber(3)

    rx, ry, rz = input.getNumber(4), input.getNumber(5), input.getNumber(6)
    ijk = getIJK(rx, ry, rz)

    if not SELF_TUNE then
        -- guidance logic

    else
        -- autotrim and dynamic modelling (see dynamic_modelling.md)

    end
end