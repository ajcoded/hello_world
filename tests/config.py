#""""
# This configuration file is for tests, This will create different db for tests.
#""""
class Config:
    """
    the actual key shoule be outside of the source code under version control
    Used to restrict cookie modfication, cross site attacks etc 
    """

    """
    SQLAlchemy
    Use sqlite for local development
    """
    SQLALCHEMY_DATABASE_URI = 'sqlite:///users_test.db'


    
    