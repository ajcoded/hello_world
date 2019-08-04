from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import json
from settings import app
from datetime import datetime

db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = 'users'
    username = db.Column(db.String(80), primary_key=True)
    dob = db.Column(db.Date(), nullable=False)

    def add_user(_name, _dob):
        new_user = User(username=_name, dob=_dob)
        db.session.add(new_user)
        db.session.commit()

    def get_all_users():
        
        all_users=[]
        users = User.query.all()
        
        for user in users:
            all_users.append(user.as_dict())

        return all_users
    
    def __repr__(self):
        user_object = {
            'name': self.username,
            'dob': self.dob
        }
        return json.dumps(user_object)

    def as_dict(self):
        user = {}
        for c in self.__table__.columns:
            if c.name == 'username':
                user[c.name] = getattr(self, c.name)
            elif c.name == 'dob':
                user[c.name] = getattr(self, c.name).isoformat()
            else:
                user[c.name] = getattr(self, c.name)
        return user
