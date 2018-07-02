from MG import db,login_manager
from flask_login import UserMixin

@login_manager.user_loader
def load_user(user_id):
    return  User.query.get(int(user_id))

class User(db.Model, UserMixin):
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(20),unique=True, nullable=False)
    password = db.Column(db.String(60), nullable=False)

    def __repr__(self):
        return f"User('{self.username}')"

class users(db.Model, UserMixin):
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(128),unique=True, nullable=False)
    password = db.Column(db.String(64), nullable=False)
    home = db.Column(db.String(128),unique=True, nullable=False)
    goto = db.Column(db.String(128),unique=True, nullable=True)
    domain  =  db.Column(db.String(64), nullable=False)
    uid = db.Column(db.Integer,nullable=False)
    gid = db.Column(db.Integer,nullable=False)
    active = db.Column(db.String(1), nullable=False,default='Y')

    def __repr__(self):
        return f"User('{self.username}')"


## Peut ne pas etre utile.
class domain(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    domain = db.Column(db.String(100),unique=True, nullable=False)
    def __repr__(self):
        return f"User('{self.domain}')"

## Peut ne pas etre utile.
class aliases(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    email = db.Column(db.String(100),unique=True, nullable=False)
    alias = db.Column(db.BigInteger, nullable=False,default=0)
    def __repr__(self):
        return f"User('{self.email}')"







