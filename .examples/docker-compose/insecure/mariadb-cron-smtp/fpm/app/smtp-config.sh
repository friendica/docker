#!/bin/sh
set -eu

IFS=\n

SMTP_TYPE=${SMTP_TYPE:-simple}

# config options
SMTP_HOST=${SMTP_HOST:-'localhost'}
SMTP_PORT=${SMTP_PORT:-'25'}
SMTP_AUTH=${SMTP_AUTH:-'A p'}
SMTP_TRUST_AUTH_MECH=${SMTP_TRUST_AUTH_MECH:-'EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN'}
SMTP_AUTH_MECH=${SMTP_AUTH_MECH:-'EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN'}

SMTP_USERNAME=${SMTP_USERNAME:-''}
SMTP_PASSWORD=${SMTP_PASSWORD:-''}

smtp_simple() {
  sed -i '/MAILER_DEFINITIONS/i define(`SMART_HOST'\'',`'$SMTP_HOST''\'')dnl/' /etc/mail/sendmail.mc
}

smtp_custom() {
  cd /etc/mail
  mkdir -m 700 authinfo
  cd authinfo/
  echo 'Authinfo: "U:www-data" "I:'$SMTP_USERNAME'" "P:'$SMTP_PASSWORD'"' > auth_file
  makemap hash auth < auth_file

  sed -i '/MAILER_DEFINITIONS/i \
define(`SMART_HOST'\'',`'$SMTP_HOST''\'')dnl \
define(`RELAY_MAILER_ARGS'\'', `TCP '$SMTP_HOST' '$SMTP_PORT''\'')dnl \
define(`ESMTP_MAILER_ARGS'\'', `TCP '$SMTP_HOST' '$SMTP_PORT''\'')dnl \
define(`confAUTH_OPTIONS'\'', `'$SMTP_AUTH''\'')dnl \
TRUST_AUTH_MECH(`'$SMTP_TRUST_AUTH_MECH''\'')dnl \
define(`confAUTH_MECHANISMS'\'', `'$SMTP_AUTH_MECH''\'')dnl \
FEATURE(`authinfo'\'',`hash -o /etc/mail/authinfo/auth.db'\'')dnl' /etc/mail/sendmail.mc
}

case $SMTP_TYPE in
  simple) smtp_simple ;;
  custom) smtp_custom ;;
  *)
    echo "Unknown SMTP-Type '$SMTP_TYPE'"
    exit 1
esac