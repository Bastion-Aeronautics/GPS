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

onTick()
    gps_x, gps_y, gps_z = input.getNumber(1), input.getNumber(2), input.getNumber(3)
	gps = vec(gps_x, gps_y, gps_z)

	if input.getNumber(7) ~= 0 then
		target_x, target_y, target_z = input.getNumber(7), input.getNumber(8), input.getNumber(9)
		target = vec(target_x, target_y, target_z)
	end

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