from flask_wtf import FlaskForm
from wtforms import StringField,SubmitField
from wtforms.validators import DataRequired,Length,Email

class OpenMailBox(FlaskForm):
    mail_address = StringField('Email',validators=[ DataRequired("Ce champ est requis !"),Length(min=5,max=20, message="La taille de l'addresse doit etre entre 5 et 20 char"),Email("Ce n'est pas un mail !") ])
    submit = SubmitField('Validation')

