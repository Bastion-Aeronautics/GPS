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

-- PROPERTIES

-- GENERAL
-- eject direction: 0 = off  1 = up  2 = down  3 = left  4 = right
-- eject duration: time in ticks

-- altitude mode: off = absolute  on = relative (relative sets y=0 to target altitude)

-- gain: general gain for all axis

-- CRUISE
-- cruise pattern: 0 = direct  1 = level  2 = arc  3 = terrain follow

-- altitude: the target altitude for cruising
-- (acts as altitude floor for direct and terrain following mode)

-- max angle: max pitch angle allowed to adjust altitude (in degrees)

-- altitude gain: pitch per meter of deviation (in degrees)

-- restrict pitch during turns: 
-- (when next aimpoint is more than 90 degrees away, flatten delta vector to stay level)

-- TERMINAL
-- terminal distance: distance from target to start terminal phase
-- terminal pattern: 0 = direct  1 = top attack  2 = evasive



function onTick()
	self={x=input.getNumber(1),y=input.getNumber(2),z=input.getNumber(3),rx=input.getNumber(4),ry=input.getNumber(5),rz=input.getNumber(6)}
    self.IJK=vec.Euler(self.rx,self.ry,self.rz)



end