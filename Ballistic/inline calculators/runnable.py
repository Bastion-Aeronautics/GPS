import math
import time as t

# Bullet parameters
muzzle_velocity = 800          # Initial velocity of the projectile
drag = 0.002 * 60              # Drag coefficient, scaled by 60
lifeSpan = 1500 / 60           # Maximum lifespan of the projectile in seconds

gravity = 30                   # Gravity acceleration
error = 0.001                    # Error tolerance for the solution

# Global variables for output
offset = 0
time = 0


def solve(dist, height):
    
    x = dist                    # Horizontal distance to target
    yT = height                      # Target vertical position (assuming flat ground)

    a = 0                       # Initial guess for angle (radians)
    t = 0                       # Time of flight

    # Iterate up to 10 times to refine the angle
    for k in range(1, 16):
        vx = muzzle_velocity * math.cos(a)   # Horizontal component of velocity
        vy = muzzle_velocity * math.sin(a)   # Vertical component of velocity

        t = get_time(vx, x)     # Calculate time to reach horizontal distance
        if t > lifeSpan:        # Check if time exceeds projectile lifespan
            return a, t, False  # Return angle, time, and failure flag

        y = get_y(vy, t)        # Calculate vertical position at time t

        if abs(y - yT) < error:     # Check if vertical position is within error tolerance
            return a, t, True   # Return angle, time, and success flag


        print(f"ToF: {t*60:.0f} ticks, Y: {y:.3f}, Angle: {math.degrees(a):.4f} degrees")  # Debug output

        # Adjust angle using atan approximation for correction
        a = a - math.atan2(y - yT, x)



    return a, t, False          # Return angle, time, and failure flag after max iterations


def get_y(v, t):
    
    return -gravity * t / drag + (gravity / drag + v) * (1 - math.exp(-drag * t)) / drag


def get_time(v, x):
    return -math.log(1 - drag * x / v) / drag
        


def on_tick(dist, height):

    global offset, time
    
    drp, t, ok = solve(dist, height)  # Solve for drop angle and success flag
    if ok:
        offset = dist * math.tan(drp)  # Calculate horizontal offset for aiming
        time = t                       # Set time of flight
        return offset, time, True, drp
    else:
        return None, None, False, None


# Example usage
if __name__ == "__main__":
    # Test the ballistic calculator
    test_distance = 1000
    test_height = 0  # Assuming target is at the same height as the shooter

    print("\n\n")
    if test_height >= 0:
        print(f"Firing at {test_distance}m away, {test_height}m up")
    else:
        print(f"Firing at {test_distance}m away, {-test_height}m down")
    print()

    result_offset, result_time, success, drop = on_tick(test_distance, test_height)

    if success:
        print()
        print(f"Calculated firing angle: +{drop*(180/math.pi):.3f} degrees")
        print(f"Approximate time to target: {result_time:.3f} seconds")
    else:
        print()
        print(f"Failed to find solution for distance {test_distance}")

    print("")

    input("Press Enter to run performance test")

    start_time = t.perf_counter()

    print("\n")
    print("\033[2mRunning performance test\033[0m")

    for distance in range(100, 5001):
        for height in range(-100, 100):
            result_offset, result_time, success, drop = on_tick(distance, height)

    end_time = t.perf_counter()
    print("")
    print(f"Ran 1 million calculation cycles in {end_time - start_time:.2f} seconds")
    print(f"\033[1m\033[32mAverage cycle time: {(end_time - start_time) / 1000000 * 1000000:.2f}us\033[0m")
    print("\n")