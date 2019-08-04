import platform
from flask import Flask
import os

app = Flask(__name__)
ENV=os.getenv("ENV_TYPE")
if ENV == 'PROD':
    DATASOURCE_USERNAME=os.getenv("DATASOURCE_USERNAME")
    DATASOURCE_PASSWORD=os.getenv("DATASOURCE_PASSWORD")
    SPRING_DATASOURCE_URL=os.getenv("SPRING_DATASOURCE_URL")
    app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://'+DATASOURCE_USERNAME+':'+DATASOURCE_PASSWORD+'@'+SPRING_DATASOURCE_URL+'/{db instance name}'
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False