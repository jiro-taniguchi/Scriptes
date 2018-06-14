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
    goto = db.Column(db.String(128),unique=True, nullable=False)
    domain = db.Column(db.String(128),unique=True, nullable=False)
    password = db.Column(db.String(64), nullable=False)
    home = db.Column(db.String(255), nullable=False)
    uid = db.Column(db.Integer,nullable=False)
    gid = db.Column(db.Integer,nullable=False)
    active = db.Column(db.String(1), nullable=False,default='Y')
    user_expire =  db.relationship('expires',backref='u_expire',lazy=True)
    user_quota = db.relationship('quota', backref='u_quota', lazy=True)


## Peut ne pas etre utile.
class expires(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(100),unique=True, nullable=False)
    mailbox =  db.Column(db.String(255),unique=True, nullable=False)
    expire_stamp = db.Column(db.Integer, nullable=False,default=60)
    user_id = db.Column(db.Integer,db.ForeignKey('users.id'),nullable=False)

## Peut ne pas etre utile.
class quota(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(100),unique=True, nullable=False)
    bytes = db.Column(db.BigInteger, nullable=False,default=0)
    messages = db.Column(db.Integer, nullable=False,default=0)
    user_id = db.Column(db.Integer,db.ForeignKey('users.id'),nullable=False)







