from flask_wtf import FlaskForm
from wtforms import StringField,SubmitField, PasswordField, SelectField,BooleanField,IntegerField
from wtforms.validators import DataRequired,Length,Email,EqualTo



class OpenMailBox(FlaskForm):
    mail_address = StringField('Email',validators=[ DataRequired("Ce champ est requis !"),Length(min=5,max=20, message="La taille de l'addresse doit etre entre 5 et 20 char"),Email("Ce n'est pas un mail !") ])
    submit = SubmitField('Validation')


class AuthAdmin(FlaskForm):
    username = StringField('Username',validators=[ DataRequired("Ce champ est requis !") ])
    password = PasswordField('Password',validators=[ DataRequired("Champs requis") ])
    remember = BooleanField('Se souvenir de moi')
    submit = SubmitField('Validation')


class ConfigAdmin(FlaskForm):
    time_to_destroy = SelectField(coerce=int,label="Durée de vie de boite mails: ", choices=[(15, "15 minutes"), (30, "30 minutes"), (60, "1 heure")], default=15)
    will_backup = BooleanField(label="Sauvegarder les mails",default=False)
    max_number_mailbox = IntegerField(label="Nombre maximum de mail",default=60)
    password = StringField('Mot de pass des boites mails')
    submit = SubmitField('Validation')


class PasswordChange(FlaskForm):
    password = PasswordField('Mot de pass actuelle', validators=[DataRequired("Champs requis")])
    new_password = PasswordField('Nouveau mot de pass', validators=[DataRequired("Champs requis")])
    confirm = PasswordField('Confirmation', validators=[DataRequired("Champs requis"), EqualTo('new_password')])
    submit = SubmitField('Validation')
