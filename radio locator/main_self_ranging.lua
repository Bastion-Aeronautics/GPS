function Vec(x,y,z)return{x=x,y=y,z=z}end
function Add(A,B)return{x=A.x+B.x,y=A.y+B.y,z=A.z+B.z}end
function Sub(A,B)return{x=A.x-B.x,y=A.y-B.y,z=A.z-B.z}end
function Scale(A,n)return{x=A.x*n,y=A.y*n,z=A.z*n}end
function Dot(A,B)return A.x*B.x+A.y*B.y+A.z*B.z end
function Len(A)return math.sqrt(A.x*A.x+A.y*A.y+A.z*A.z)end
function SetLen(A,n)return Scale(Norm(A),n)end
function Norm(A)return Len(A)~=0 and Scale(A,1/Len(A))or{x=0,y=0,z=0}end
function Cross(A,B)return{x=A.y*B.z-A.z*B.y,y=A.z*B.x-A.x*B.z,z=A.x*B.y-A.y*B.x}end
function Lerp(A,B,t)return Add(A,Scale(Sub(B,A),t))end
function Euler(rx,ry,rz)local cx,cy,cz=math.cos(rx),math.cos(ry),math.cos(rz)local sx,sy,sz=math.sin(rx),math.sin(ry),math.sin(rz)local local_x={x=cy*cz,y=cy*sz,z=-sy}local local_y={x=-cx*sz+sx*sy*cz,y=cx*cz+sx*sy*sz,z=sx*cy}local local_z=Cross(local_x,local_y)return{x=local_x,y=local_y,z=local_z}end
function Local(A,ijk)return Vec(Dot(A, ijk.x),Dot(A, ijk.y),Dot(A, ijk.z))end
function Global(A,ijk)return Add(Scale(ijk.x, A.x),Add(Scale(ijk.y, A.y),Scale(ijk.z, A.z)))end
function Sphere(A)return Vec(math.atan(A.x,A.y),math.asin(A.z/Len(A)))end

arm_length = property.getNumber("arm length")

radio_c = 0
radio_x = 0
radio_y = 0
radio_z = 0

function onTick()
	self={x=input.getNumber(1),y=input.getNumber(2),z=input.getNumber(3),rx=input.getNumber(4),ry=input.getNumber(5),rz=input.getNumber(6)}
    self.IJK=Euler(self.rx,self.ry,self.rz)

    if input.getNumber(7) ~= 0 then
	    radio_c = input.getNumber(7)
	    radio_x = input.getNumber(8)
	    radio_y = input.getNumber(9)
	    radio_z = input.getNumber(10)
    end
	
	range_c = -radio_c+1
    range_x = -radio_x+1
    range_y = -radio_y+1
    range_z = -radio_z+1

    unit_delta = Vec(range_x - range_c, range_y - range_c, range_z - range_c)
    delta = SetLen(unit_delta, range_c*strength)

    target = Sub(self, Global(delta, self.IJK))

    output.setNumber(1, target.x)
    output.setNumber(2, target.y)
    output.setNumber(3, target.z)
    output.setNumber(4, range_c * strength)
end