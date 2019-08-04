from datetime import datetime, date

class Utils:
    def date_diff(self, date_of_birth):
        dob = date(date_of_birth.year, date_of_birth.month, date_of_birth.day)
        today = date.today()
        if today.month == dob.month and today.day >= dob.day or today.month > dob.month:
            nextBirthdayYear = today.year + 1
        else:
            nextBirthdayYear = today.year
        nextBirthday = date(nextBirthdayYear, dob.month, dob.day)
        diff = nextBirthday - today
        return diff.days