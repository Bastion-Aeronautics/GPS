# Creating a Web server using Python and Flask
from flask import Flask
import logging
app = Flask('app')

click = False

@app.route('/toggleClick') # This function can be called to toggle the value of click
def toggleClick():
    global click
    click = not click
    print("c: " + str(click))
    return str(click) ##str() converts to string for sending over http

@app.route('/readClick') # This function can be called to read the value of `click`
def readClick():
    global click
    return str(click)

logging.getLogger('werkzeug').disabled = True # Disable Flask's default logging

app.run(host = '0.0.0.0', port = 1575)