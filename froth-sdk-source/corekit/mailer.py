#!/usr/bin/python

# This should be deployed to -> /usr/froth/lib/python/mailutils.py and is used with WebMailer class

import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email import Encoders
import os

def mail(to, frm, subject, text, attach, smtphost, smtpuser, smtppass):
   msg = MIMEMultipart()

   msg['From'] = frm
   msg['To'] = to
   msg['Subject'] = subject

   msg.attach(MIMEText(text))
	
   if attach:
     part = MIMEBase('application', 'octet-stream')
     part.set_payload(open(attach, 'rb').read())
     Encoders.encode_base64(part)
     part.add_header('Content-Disposition',
        'attachment; filename="%s"' % os.path.basename(attach))
     msg.attach(part)

   mailServer = smtplib.SMTP(smtphost, 587)
   mailServer.ehlo()
   mailServer.starttls()
   mailServer.ehlo()
   mailServer.login(smtpuser, smtppass)
   mailServer.sendmail(smtpuser, to, msg.as_string())
   # todo, we should keep server open if we send a list of emails, do this on a to user bases for lists
   # Should be mailServer.quit(), but that crashes...
   mailServer.close()