PORT = property.getNumber("HTTP Port")
ID = property.getNumber("Track ID")

-- Tick function that will be executed every logic tick
function onTick()
	if input.getBool(1) then
		async.httpGet(PORT, '/updatePosition?x='..gps_x..'&y='..gps_y..'&z='..gps_z..'&id='..ID)
    end
end