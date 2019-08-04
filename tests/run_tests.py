import sys
import pytest
from datetime import datetime

from db import db
from server import *
from settings import *

@pytest.fixture()
def post_data(scope='module'):
    suser = User(name='TestStudent', dob='1990-10-10')
    return suser

@pytest.fixture(scope='module')
def init_database():
    # Create the database and the database table
    try:
        db.create_all()
        # Insert Uset=r data
        user1 = User(name='TestUserA', dob=datetime(2010, 5, 17))
        db.session.add(user1)
        # Commit the changes for the students
        db.session.commit()

        yield db  # this is where the testing happens!

        db.drop_all()
        
    except Exception as e:
        print(e)