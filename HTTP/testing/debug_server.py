# Creating a Web server using Python and Flask
from flask import Flask, request
import logging
from graphing import plot_shit
app = Flask('app')

trajectory = [] # This list will store the trajectory points

@app.route('/updatePosition') # This function can be called to update the position
def updatePosition():
    current_x = request.args.get('x')
    current_y = request.args.get('y')
    current_z = request.args.get('z')
    trajectory.append((float(current_x), float(current_y), float(current_z))) # Store the position as a tuple in the trajectory list
    print(f"Position: {float(current_x):.0f}, {float(current_y):.0f}, {float(current_z):.0f}")
    return "OK"
plot_shit(trajectory)
logging.getLogger('werkzeug').disabled = True # Disable Flask's default logging

app.run(host = '0.0.0.0', port = 65454)