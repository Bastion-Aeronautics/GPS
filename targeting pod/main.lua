pi=math.pi
tau=math.pi*2
sin=math.sin
cos=math.cos
tan=math.tan
acos=math.acos
asin=math.asin
atan=math.atan
sqrt=math.sqrt

function clamp(val, min, max) return math.min(math.max(val, min), max) end
function lerp(a, b, t) return a + (b - a) * t end
function map(t, a, b, c, d) return ((t - a) / (b - a)) * (d - c) + c end -- map a-b to c-d according to t
function round(a) return math.floor(a+0.5) end

function Vec(x,y,z)return{x=x,y=y,z=z}end
function Add(A,B)return Vec(A.x+B.x,A.y+B.y,A.z+B.z)end
function Sub(A,B)return Vec(A.x-B.x,A.y-B.y,A.z-B.z)end
function Scale(A,n)return Vec(A.x*n,A.y*n,A.z*n)end
function Dot(A,B)return A.x*B.x+A.y*B.y+A.z*B.z end
function Len(A)return sqrt(A.x*A.x+A.y*A.y+A.z*A.z)end
function SetLen(A,n)return Scale(Norm(A),n)end
function Norm(A)return Len(A)~=0 and Scale(A,1/Len(A))or Vec(0,0,0)end
function Cross(A,B)return Vec(A.y*B.z-A.z*B.y,A.z*B.x-A.x*B.z,A.x*B.y-A.y*B.x)end
function Lerp(A,B,t)return Add(A,Scale(Sub(B,A),t))end
function IJK(rx,ry,rz)local cx,cy,cz=cos(rx),cos(ry),cos(rz)local sx,sy,sz=sin(rx),sin(ry),sin(rz) return Vec(Vec(cy*cz,cy*sz,-sy),Vec(-cx*sz+sx*sy*cz,cx*cz+sx*sy*sz,sx*cy),Vec(cx*sy*cz+sx*sz,cx*sy*sz-sx*cz,cx*cy))end
function LIJK(x,y,ijk)local ca,ce,cr=cos(x),cos(y),1 local sa,se,sr=sin(x),sin(y),0 return Vec(Global(Vec(cr*ca+sr*se*sa,-sr*ce,sr*se*ca-cr*sa),ijk),Global(Vec(sr*ca-cr*se*sa,cr*ce,-cr*se*ca-sr*sa),ijk),Global(Vec(sa*ce,se,ca*ce),ijk))end
function PIJK(ijk)local z=Norm(Vec(ijk.z.x,0,ijk.z.z))local x=Vec(z.z,0,-z.x)local y=Cross(x,z)return Vec(x,y,z)end
function Local(A,ijk)return Vec(Dot(A, ijk.x),Dot(A, ijk.y),Dot(A, ijk.z))end
function Global(A,ijk)return Add(Scale(ijk.x, A.x),Add(Scale(ijk.y, A.y),Scale(ijk.z, A.z)))end
function Sphere(A)return Vec(atan(A.x,A.y),asin(A.z/Len(A)))end
function Project(A)local w,h=256,192 return w/2+A.x/A.z*1.343*w/2,h/2-A.y/A.z*1.343*w/2 end
function Point(A,ijk,lijk)return Project(Local(Global(A,ijk),lijk))end
function Horizon(v,pijk,lijk)return Project(Local(Global(v,pijk),lijk))end

function onTick()



    output.setNumber(1, slewX)
    output.setNumber(2, slewY)
end

function onDraw()

end