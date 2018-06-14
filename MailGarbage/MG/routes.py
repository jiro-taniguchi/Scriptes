from flask import  render_template, url_for, flash,redirect, request
from MG.form import OpenMailBox, AuthAdmin
from MG import app, db ,bcrypt
from MG.models import  User
from flask_login import login_user,current_user,logout_user, login_required


ADMIN="kinkazma"
PASS="admin"



@app.route("/", methods=['GET', 'POST'])
def openup():
    form = OpenMailBox()
    if form.validate_on_submit():
        flash(f'Mailbox created for {form.mail_address.data}!', "success")
        return redirect(url_for('openup'))
    return render_template('index.html', title="Open up", form=form)

@app.route("/admin/", methods=['GET', 'POST'])
def auth():
    if current_user.is_authenticated:
        return redirect(url_for('config'))
    form = AuthAdmin()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and bcrypt.check_password_hash(user.password, form.password.data):
            login_user(user)
            next_page = request.args.get('next')
            return redirect(next_page) if next_page else redirect(url_for('config'))
        else:
            flash(f'Login is not good {form.username.data}!', "danger")

    return render_template('admin.html', title="Admin authentication", form=form)


@app.route(r'/admin/config/')
@login_required
def config():

    return render_template('config.html', title="Config")


@app.route('/logout/')
@login_required
def logout():
    logout_user()
    return redirect(url_for('auth'))


@app.route('/mailbox/')
def mailbox():
    return "OK"