# Creating a Web server using Python and Flask
from flask import Flask, request
import logging
app = Flask('app')


@app.route('/updatePosition') # This function can be called to update the position
def updatePosition():
    print("Position: " + str(request.args.get('x')) + ", " + str(request.args.get('y')) + ", " + str(request.args.get('z')))

logging.getLogger('werkzeug').disabled = True # Disable Flask's default logging

app.run(host = '0.0.0.0', port = 1575)