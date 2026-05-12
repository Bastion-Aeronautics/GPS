function onTick()

    for i = 1, 8 do
        previousLocked = locked
        locked = input.getBool((i*4)-3)

        distance = input.getNumber((i*4)-3)
        radarX = input.getNumber((i*4)-2)
        radarY = input.getNumber((i*4)-1)
        lockedTime = input.getNumber(i*4)

        if not locked and lastLocked then
            output.setNumber(1, radarX)
            output.setNumber(2, radarY)
        end

        lastLocked = locked
    end
end