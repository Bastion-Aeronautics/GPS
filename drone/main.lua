pi=math.pi
tau=math.pi*2
function clamp(val, min, max) return math.min(math.max(val, min), max) end
function lerp(a, b, t) return a + (b - a) * t end
function map(t, a, b, c, d) return ((t - a) / (b - a)) * (d - c) + c end
vec={}
function vec.New(x,y,z)return{x=x,y=y,z=z}end
function vec.Add(A,B)return{x=A.x+B.x,y=A.y+B.y,z=A.z+B.z}end
function vec.Sub(A,B)return{x=A.x-B.x,y=A.y-B.y,z=A.z-B.z}end
function vec.Scale(A,n)return{x=A.x*n,y=A.y*n,z=A.z*n}end
function vec.Dot(A,B)return A.x*B.x+A.y*B.y+A.z*B.z end
function vec.Len(A)return math.sqrt(A.x*A.x+A.y*A.y+A.z*A.z)end
function vec.SetLen(A,n)return vec.Scale(vec.Norm(A),n)end
function vec.Norm(A)return vec.Len(A)~=0 and vec.Scale(A,1/vec.Len(A))or{x=0,y=0,z=0}end
function vec.Cross(A,B)return{x=A.y*B.z-A.z*B.y,y=A.z*B.x-A.x*B.z,z=A.x*B.y-A.y*B.x}end
function vec.Lerp(A,B,t)return vec.Add(A,vec.Scale(vec.Sub(B,A),t))end
function vec.Euler(rx,ry,rz)local cx,cy,cz=math.cos(rx),math.cos(ry),math.cos(rz)local sx,sy,sz=math.sin(rx),math.sin(ry),math.sin(rz)local local_x={x=cy*cz,y=cy*sz,z=-sy}local local_y={x=-cx*sz+sx*sy*cz,y=cx*cz+sx*sy*sz,z=sx*cy}local local_z=vec.Cross(local_x,local_y)return{x=local_x,y=local_y,z=local_z}end
function vec.Local(A,ijk)return vec.New(vec.Dot(A, ijk.x),vec.Dot(A, ijk.y),vec.Dot(A, ijk.z))end
function vec.Global(A,ijk)return vec.Add(vec.Scale(ijk.x, A.x),vec.Add(vec.Scale(ijk.y, A.y),vec.Scale(ijk.z, A.z)))end
function vec.Raycast(A,ijk,distance)return vec.Global(vec.SetLen(A,distance),ijk)end
function vec.Heading(A)return {x=math.atan(A.x,A.z),y=math.atan(A.y,A.z)}end

YAW_GAIN = 1
PITCH_GAIN = 2

MAX_ANGLE = 20 /360
ALTITUDE_GAIN = 0.001

ROLLING = -0.05
MAX_ROLL = 0.05

cruise_altitude = 800

LOITER_DISTANCE = 300

function onTick()
	self={}
	self.x=input.getNumber(1)
	self.y=input.getNumber(2)
	self.z=input.getNumber(3)
	self.rx=input.getNumber(4)
	self.ry=input.getNumber(5)
	self.rz=input.getNumber(6)
	self.pitch=input.getNumber(15)
	self.roll=input.getNumber(16)
    self.IJK=vec.Euler(self.rx,self.ry,self.rz)

	-- Code goes here
	
	if input.getBool(1) then
		launched = true
	end
	
	target = vec.New(input.getNumber(7), input.getNumber(8), input.getNumber(9))

    delta = vec.Sub(target, self)

    pitch_setpoint = clamp(cruise_altitude - self.y, -MAX_ANGLE, MAX_ANGLE)
	
	towards = vec.Heading(vec.Local(vec.New(delta.x, (math.tan(pitch_setpoint)) * vec.Len({x=delta.x, y=0, z=delta.z}), delta.z),self.IJK))
	

    yaw_control = towards.x * YAW_GAIN
    pitch_control = towards.y * PITCH_GAIN

    roll_setpoint = clamp(towards.x * ROLLING, -MAX_ROLL, MAX_ROLL)

	roll_control = (self.roll - roll_setpoint) * 10
	
	output.setNumber(1, towards.x * YAW_GAIN)
	output.setNumber(2, towards.y * PITCH_GAIN)
	output.setNumber(3, roll_control)
	output.setNumber(4, launched and -1 or 0)

end