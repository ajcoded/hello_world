from flask import Flask, jsonify, request, Response
from datetime import datetime
from sqlalchemy.exc import IntegrityError
from validate import validate_user
from utils import Utils
import json
import re
from db import User
from settings import *

@app.route('/hello', methods=['PUT'])
def add_user():
    request_data = request.get_json()
    if(validate_user().validate_user_data(request_data)):
        try:
            User.add_user(request_data["name"], datetime.strptime(request_data["dob"], "%Y-%m-%d").date())
            response = Response("", 204, mimetype='application/json')
        except IntegrityError:
            response = Response("User already exist", 409, mimetype='application/json')
        return response
    else:
        invalidUserObjectErrorMsg = {
            "error": "Invalid user passed in request",
            "helpstring": "contact your local administrator"
        }
        return Response(json.dumps(invalidUserObjectErrorMsg), 400, mimetype='application/json')

@app.route('/hello/<string:username>')
def find_user_by_name(username):
    return_value = {}
    users = User.get_all_users()
    for user in users:
        if(username == user.get("username")):
            util = Utils()
            days_left = util.date_diff(datetime.strptime(user.get("dob"), '%Y-%m-%d').date())
            if days_left < 365 or days_left != 366:
                return_value = "Hello {}, Your birthday is in {} day(s)".format(username, days_left)
            else:
                return_value = "Hello {}, Happy birthday...!!!".format(username) 
    return Response(json.dumps(return_value), 200, mimetype='application/json') 

app.run(port=5000, debug=False, host='0.0.0.0')