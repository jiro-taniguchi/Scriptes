from pathlib import Path

from flask import Flask
from flask_bcrypt import Bcrypt
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

DB_FILENAME='main.db'
app = Flask("MailGarbage", template_folder='./MG/templates', static_folder='./MG/static')
app.config['SECRET_KEY'] = "56ba4edb201afb619abcacf6a3f8c015"
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{DB_FILENAME}"
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'
from MG.models import User
if not Path(DB_FILENAME).is_file():
    db.create_all()


if User.query.filter_by(id=1).all() == []:
    password =bcrypt.generate_password_hash('admin').decode('utf-8')
    user = User(username="admin",password=password)
    db.session.add(user)
    db.session.commit()



