from flask import  render_template, url_for, flash,redirect, request
from MG.form import OpenMailBox, AuthAdmin , ConfigAdmin, PasswordChange
from MG import app, db ,bcrypt, MGConfig, config_file
from MG.models import  User, users
from flask_login import login_user,current_user,logout_user, login_required
from imaplib import IMAP4

ADMIN="kinkazma"
PASS=MGConfig['main']['password']
IMAP_SERVER = "10.0.3.202"





@app.route("/", methods=['GET', 'POST'])
@app.route("/home/", methods=['GET', 'POST'])
def home():
    form = OpenMailBox()
    if form.validate_on_submit():
        one_mail_user = form.mail_address.data.split('@')[0]
        one_mail_domain = form.mail_address.data.split('@')[1]
        one_user = users.query.filter_by(username=one_mail_user).first()
        if one_user:
            print("exist")
        else:
            one_user = users(username=one_mail_user,password=PASS,home=f"/var/mail/vhosts/{one_mail_domain}/{one_mail_user}/",domain=one_mail_domain,uid=5000,gid=5000,active=True)
            db.session.add(one_user)
            db.session.commit()
        flash(f'Mailbox created for {form.mail_address.data}!', "success")
        return redirect(url_for('openup',email=form.mail_address.data))
    return render_template('index.html', title="Open up", form=form)

@app.route("/openup/")
def openup():
    output=""
    one_user = request.args.get('email')

    M = IMAP4(IMAP_SERVER)
    try:
        M.login_cram_md5(one_user, PASS)
    except:

        return "Failed to login"
    rv, data = M.select("INBOX")
    if rv == 'OK':
        print("Processing mailbox: ", "INBOX")
        rvx, datax = M.search(None, "ALL")
        print(len(datax))
        if len(datax) == 1:
            return "No messages found!"
        for num in datax[0].split():
            rvx, datax = M.fetch(num, '(RFC822)')
            if rvx != 'OK':
                output+=f"ERROR getting message {num}"
                continue
            output+=f"Writing message , {num} {data[0][1]}"

        return output
    else:
        M.logout()
        return ("ERROR: Unable to open mailbox ", rv)



@app.route("/admin/", methods=['GET', 'POST'])
def login():
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

def str2bool(value):
    return value.lower() in ('true')

@app.route(r'/admin/config/', methods=['GET', 'POST'])
@login_required
def config():
    #MGConfig = ConfigParser()
    #MGConfig.read(config_file)
    #form = ConfigAdmin(will_backup=str2bool(MGConfig['main']['will_backup']), time_to_destroy=MGConfig['main']['time_to_destroy'],max_number_mailbox=MGConfig['main']['max_number_mailbox'])
    main_arg=""
    for key in MGConfig['main'].keys():
        main_arg+=f"{key}=\"{MGConfig['main'][str(key)]}\","
    exec(f"global form; form = ConfigAdmin({main_arg}submit={True})")
    if form.validate_on_submit():
        print(form.will_backup.data,form.max_number_mailbox.data)
        MGConfig['main'] = {  'will_backup': form.will_backup.data,'max_number_mailbox':form.max_number_mailbox.data, 'time_to_destroy':form.time_to_destroy.data}
        with open(config_file, 'w') as configfile:
            MGConfig.write(configfile)
        flash('Config sauvegarder !', "success")
        return redirect('home')
    return render_template('config.html', title="Config", form=form,config=MGConfig)

@app.route(r'/admin/account/', methods=['GET', 'POST'])
@login_required
def account():
    form = PasswordChange()
    if form.validate_on_submit():
        user = User.query.filter_by(username=current_user.username).first()
        if bcrypt.check_password_hash(user.password, form.password.data):
            hashed_password = bcrypt.generate_password_hash(form.new_password.data).decode('utf-8')
            user.password = hashed_password
            db.session.commit()
            flash('Password changer !', "success")
            return redirect(url_for('logout'))
        else:
            flash(f'Bad password !', "danger")
            return redirect(url_for('account'))
    return render_template('account.html', title="Account", form=form)

@app.route('/logout/')
@login_required
def logout():
    logout_user()
    return redirect(url_for('home'))



@app.route('/about/')
def about():
    return "OK"

@app.route('/mailbox/')
def mailbox():
    return "OK"