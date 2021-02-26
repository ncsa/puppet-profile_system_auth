#! /bin/bash

RANDSTRING=`head -c 16 /dev/random  | base64 | grep -o . | sort -R | tr -d "\n" | head -c 14`
REQCLASS1=`date | base64 | tr -dc A-Z | grep -o . | sort -R | tr -d "\n" | head -c2`
REQCLASS2=`date | base64 | tr -dc a-z | grep -o . | sort -R | tr -d "\n" | head -c2`
REQCLASS3=`date | tr -dc 0-9 | grep -o . | sort -R | tr -d "\n" | head -c2`
REQCHARS=`echo $REQCLASS1$REQCLASS2$REQCLASS3`
TEMPPASS=`echo "$RANDSTRING$REQCHARS" | grep -o . | sort -R | tr -d "\n"`

echo "$1" | base64 --decode > /root/createhost.keytab

echo -e "$TEMPPASS\n$TEMPPASS" | kadmin -kt /root/createhost.keytab -p $2/createhost@NCSA.EDU -q "addprinc host/$(hostname -f)@NCSA.EDU"
echo -e "$TEMPPASS" | kadmin -p host/$(hostname -f)@NCSA.EDU -q "ktadd host/$(hostname -f)@NCSA.EDU"
rm -f /root/createhost.keytab
