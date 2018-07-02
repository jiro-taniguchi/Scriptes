import sys
from imaplib import  IMAP4
import getpass

IMAP_SERVER = 'imap.gmail.com'
EMAIL_ACCOUNT = "notatallawhistleblowerIswear@gmail.com"
EMAIL_FOLDER = "Top Secret/PRISM Documents"
OUTPUT_DIRECTORY = 'C:/src/tmp'

PASSWORD = getpass.getpass()


def process_mailbox(M):
    """
    Dump all emails in the folder to files in output directory.
    """

    rv, data = M.search(None, "ALL")
    if rv != 'OK':
        print("No messages found!")
        return

    for num in data[0].split():
        rv, data = M.fetch(num, '(RFC822)')
        if rv != 'OK':
            print("ERROR getting message", num)
            return
        print("Writing message ", num)
        f = open('%s/%s.eml' %(OUTPUT_DIRECTORY, num), 'wb')
        f.write(data[0][1])
        f.close()

def connect_to_server():
    M = IMAP4(IMAP_SERVER)
    M.login(EMAIL_ACCOUNT, PASSWORD)
    rv, data = M.select(EMAIL_FOLDER)
    if rv == 'OK':
        print("Processing mailbox: ", EMAIL_FOLDER)
        process_mailbox(M)
        M.close()
    else:
        print("ERROR: Unable to open mailbox ", rv)
    M.logout()
