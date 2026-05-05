"""
Ballistic Calculator v1
This script calculates the firing angle for a projectile to hit a target at a given distance,
taking into account gravity and air resistance (drag). It's designed for use in a game or simulation
environment, likely Stormworks, where projectiles follow ballistic trajectories.
"""

import math

# Bullet parameters
muzzle_velocity = 800          # Initial velocity of the projectile (units per second)
drag = 0.002 * 60              # Drag coefficient, scaled by 60 (likely for per-tick simulation)
lifeSpan = 1500 / 60           # Maximum lifespan of the projectile in seconds (converted from ticks)

gravity = 30                   # Gravity acceleration (units per second squared)
error = 0.001                    # Error tolerance for the solution (acceptable vertical error in units)

# Global variables for output
offset = 0
time = 0


def solve(dist, height):
    """
    Function to solve for the firing angle given a target distance.
    Uses an iterative method to find the angle where the projectile hits the target.
    
    Args:
        dist: Horizontal distance to target
    
    Returns:
        tuple: (angle in radians, time of flight, success flag)
    """
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


        print(f"Time: {t:.0f} ticks, Y: {y:.3f}, Angle: {math.degrees(a):.4f} degrees")  # Debug output

        # Adjust angle using atan approximation for correction
        a = a - math.atan2(y - yT, x)



    return a, t, False          # Return angle, time, and failure flag after max iterations


def get_y(v, t):
    """
    Function to calculate vertical position at time t with initial vertical velocity v.
    Accounts for gravity and drag using the equation of motion.
    
    Args:
        v: Initial vertical velocity
        t: Time
    
    Returns:
        float: Vertical position
    """
    return -gravity * t / drag + (gravity / drag + v) * (1 - math.exp(-drag * t)) / drag


def get_time(v, x):
    """
    Function to calculate time to reach horizontal distance x with initial horizontal velocity v.
    Solves the drag equation for time.
    
    Args:
        v: Initial horizontal velocity
        x: Horizontal distance
    
    Returns:
        float: Time to reach distance x
    """
    return -math.log(1 - drag * x / v) / drag


def on_tick(dist, height):
    """
    Main tick function, called every simulation tick.
    
    Args:
        dist: Current target distance
        height: Current target height
    
    Returns:
        tuple: (offset, time, success flag)
    """
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
    test_distance = 800
    test_height = -300  # Assuming target is at the same height as the shooter

    print("\n\n")
    if test_height >= 0:
        print(f"Firing at {test_distance}m away, {test_height}m up")
    else:
        print(f"Firing at {test_distance}m away, {-test_height}m down")
    print()

    result_offset, result_time, success, drop = on_tick(test_distance, test_height)

    if success:
        print()
        print(f"Firing angle: {drop*(180/math.pi):.4f} degrees")
        print(f"Time to target: {result_time:.4f} seconds")
    else:
        print()
        print(f"Failed to find solution for distance {test_distance}")

    print("\n")