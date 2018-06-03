from flask import *
from form import OpenMailBox
app = Flask("MailGarbage")
app.config['SECRET_KEY'] = "56ba4edb201afb619abcacf6a3f8c015"

@app.route("/", methods=['GET', 'POST'])
def openup():
    form = OpenMailBox()
    if form.validate_on_submit():
        flash(f'Mailbox created for {form.mail_address.data}!', "success")
        return redirect(url_for('mailbox'))
    return render_template('auth.html', title="Open up", form=form)

@app.route('/mailbox')
def mailbox():
    return "OK"

app.run(port=8081,debug=True)