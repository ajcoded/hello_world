import re
from datetime import datetime


class validate_user(): 
    def validate_user_data(self, UserObject):
        if("name" in UserObject and "dob" in UserObject) and bool(re.match('^[A-Za-z]*$', UserObject.get("name"))):
            try:
                if(datetime.now().date() > datetime.strptime(UserObject.get("dob"), '%Y-%m-%d').date()):
                    return True
            except ValueError:
                return False
        else:
            return False