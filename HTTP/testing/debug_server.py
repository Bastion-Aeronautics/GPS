# Creating a Web server using Python and Flask
from flask import Flask, request
import logging
import time
import threading
import matplotlib.pyplot as plt

def plot_shit(trajectory):
    x = [p[0] for p in trajectory]
    z = [p[1] for p in trajectory]
    y = [p[2] for p in trajectory]


    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')

    ax.plot(x, y, z)
    ax.set_xlabel('GPS X')
    ax.set_ylabel('GPS Y')
    ax.set_zlabel('Altitude')
    plt.savefig("graph.png")
    plt.show()

app = Flask('app')

trajectory = [] # This list will store the trajectory points
missile_hit = False
missile_launched = False
last_update_time = time.time()

def monitor_timeout():
    global missile_hit, last_update_time, missile_launched
    while True:
        if time.time() - last_update_time > 5 and not missile_hit and missile_launched:
            missile_hit = True
            print("Missile has hit the target (timeout)")
            plot_shit(trajectory)
        time.sleep(1)

@app.route('/updatePosition') # This function can be called to update the position
def updatePosition():
    global missile_return, missile_hit, last_update_time
    missile_launched = True
    missile_return = True
    current_x = request.args.get('x')
    current_y = request.args.get('y')
    current_z = request.args.get('z')
    trajectory.append((float(current_x), float(current_y), float(current_z))) # Store the position as a tuple in the trajectory list
    print(f"Position: {float(current_x):.0f}, {float(current_y):.0f}, {float(current_z):.0f}")
    last_update_time = time.time()
    missile_hit = False  # Reset on new update
    return "OK"

logging.getLogger('werkzeug').disabled = True # Disable Flask's default logging

# Start the timeout monitor thread
threading.Thread(target=monitor_timeout, daemon=True).start()

app.run(host = '0.0.0.0', port = 65454)