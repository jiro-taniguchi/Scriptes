from flask_wtf import FlaskForm
from wtforms import StringField,SubmitField, PasswordField, SelectField
from wtforms.validators import DataRequired,Length,Email

class OpenMailBox(FlaskForm):
    mail_address = StringField('Email',validators=[ DataRequired("Ce champ est requis !"),Length(min=5,max=20, message="La taille de l'addresse doit etre entre 5 et 20 char"),Email("Ce n'est pas un mail !") ])
    submit = SubmitField('Validation')


class AuthAdmin(FlaskForm):
    username = StringField('Username',validators=[ DataRequired("Ce champ est requis !") ])
    password = PasswordField('Password',validators=[ DataRequired("Champs requis") ])
    submit = SubmitField('Validation')

class ConfigAdmin(FlaskForm):
    time_to_destroy = SelectField(label='time_to_destroy',validators=[ DataRequired("Champs requis")], choices=[(15, "15 Minute") , (30, "30 Minutes"), (60, "1 Heur"),(3, "3 Heur")])
