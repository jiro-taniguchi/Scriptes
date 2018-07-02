from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_login import LoginManager
from pathlib import Path
from configparser import ConfigParser
from os import path

DB_FILENAME='main.db'
app = Flask("MailGarbage",template_folder='./MG/templates', static_folder='./MG/static')
app.config['SECRET_KEY'] = "56ba4edb201afb619abcacf6a3f8c015"
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{DB_FILENAME}"
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'

config_tokens = { 'will_backup':True, 'max_number_mailbox':78, 'time_to_destroy':15, 'password':"Qwerty!!" }
config_file = f"{path.abspath('.')}/MG/static/mg_config.txt"
MGConfig = ConfigParser()
if Path(config_file).is_file():
    MGConfig.read(config_file)
    for keys in MGConfig['main']:
        if not keys in config_tokens.keys():
            MGConfig['main'][keys] = config_tokens[keys]
            with open(config_file) as c:
                MGConfig.write(c)
else:
    MGConfig['main'] = {}
    for key in config_tokens.keys():
        print(key)
        MGConfig['main'][f"{key}"] = str(config_tokens[key])
    with open(config_file, 'w') as c:
        MGConfig.write(c)
MGConfig.read(config_file)



from MG import routes
from MG.models import User
if not Path(DB_FILENAME).is_file():
    db.create_all()




if User.query.filter_by(id=1).all() == []:
    password =bcrypt.generate_password_hash('admin').decode('utf-8')
    user = User(username="admin",password=password)
    db.session.add(user)
    db.session.commit()



