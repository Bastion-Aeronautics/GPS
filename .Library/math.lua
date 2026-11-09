Pi=math.pi
Tau=math.pi*2

function Clamp(val, min, max) return math.min(math.max(val, min), max) end
function Lerp(a, b, t) return a + (b - a) * t end
function Map(t, a, b, c, d) return ((t - a) / (b - a)) * (d - c) + c end -- map a-b to c-d according to t
function Round(a) return math.floor(a+0.5) end