from flask_wtf import FlaskForm
from wtforms import BooleanField, StringField, SubmitField
from wtforms import validators
from wtforms.validators import DataRequired, Length, NoneOf, AnyOf


class SubscriptionForm(FlaskForm):

### Write your solution here!
    coursecode = StringField('Course Code', validators=[DataRequired()])
    neptun = StringField('Neptun Code', validators=[DataRequired(), Length(min=6, max=6)])
    name = StringField('Full Name', validators=[DataRequired()])
    iamhuman = BooleanField('I am human', validators=[DataRequired()])
    submit = SubmitField('Subscribe')
###    
