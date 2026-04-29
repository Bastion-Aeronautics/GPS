tau=2*m.pi
IN=input.getNumber
ON=output.setNumber
IB=input.getBool
OB=output.setBool
vec=function(x,y,z) return {x=x,y=y,z=z} end
function vec_add(A,B) return vec(A.x+B.x,A.y+B.y,A.z+B.z) end
function vec_sub(A,B) return vec(A.x-B.x,A.y-B.y,A.z-B.z) end
function vec_mult(A,n) return vec(A.x*n,A.y*n,A.z*n) end
function vec_dot(A,B) return A.x*B.x+A.y*B.y+A.z*B.z end
function vec_div(A,n) return vec(A.x/n,A.y/n,A.z/n) end
function vec_length(vec) return m.sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z) end
function vec_norm(A) return A.x~=0 and vec_div(A,vec_length(A)) or vec(0,0,0) end
function vec_cross(A,B) return vec(A.y*B.z-A.z*B.y,A.z*B.x-A.x*B.z,A.x*B.y-A.y*B.x) end
function clamp(val, min, max) return math.min(math.max(val, min), max) end
gps = vec(0,0,0)

direct = property.getNumber("Guidance Type")

state = 0

max_angle = property.getNumber("Max Climb Angle")

altitude = property.getNumber("Cruise Altitude")

dive_distance = property.getNumber("Dive Distance")

altitude_P = property.getNumber("Altitude P")

gain = property.getNumber("Guidance Gain")

function onTick()
	missile_position = vec(IN(1), IN(2), IN(3))
	rx,ry,rz=IN(4),IN(5),IN(6)
	
	cx,cy,cz=m.cos(rx),m.cos(ry),m.cos(rz)

	sx,sy,sz=m.sin(rx),m.sin(ry),m.sin(rz)
	Xn = vec(cy*cz,cy*sz,-sy) 						--right
	Yn = vec(-cx*sz+sx*sy*cz,cx*cz+sx*sy*sz,sx*cy)    --up
	Zn = vec_cross(Xn,Yn) 							--forward

	if IN(7) ~= 0 then
		gps = vec(IN(7), IN(8), IN(9)) --target gps coordinates (y is altitude)
	end

	towards = vec_sub(gps, missile_position) -- range in world frame
	
	pitch_setpoint = clamp((altitude-IN(2))*altitude_P, -max_angle, max_angle)
	
	distance_to_target = vec_length(vec(towards.x,0,towards.z))
	
	if state == 0 then
		guide = vec(towards.x, (m.tan(pitch_setpoint*(m.pi/180)))*distance_to_target, towards.z)
	elseif state == 1 then
		guide = towards
	end
	
	local_range = vec(vec_dot(guide, Xn), vec_dot(guide, Yn), vec_dot(guide, Zn)) 
	--project range into local frame, so coords are now expressed as right, up, fwd
	
	if distance_to_target &lt; dive_distance then
		state = 1
	else
		state = 0
	end
	
	if direct == 1 then state = 1 end

	ON(1, m.atan(local_range.x, local_range.z)*gain) --yaw output

	ON(2, m.atan(local_range.y, local_range.z)*gain) --pitch output

end