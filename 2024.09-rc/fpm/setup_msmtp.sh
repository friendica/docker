#!/bin/sh
set -eu

if [ -n "${SMTP_DOMAIN+x}" ] && [ -n "${SMTP+x}" ] && [ "${SMTP}" != "localhost" ]; then
  SITENAME="${FRIENDICA_SITENAME:-Friendica Social Network}"
  echo "Setup MSMTP for '$SITENAME' with '$SMTP' ..."

  smtp_from="${SMTP_FROM:=no-reply}"
  smtp_auth="${SMTP_AUTH:=on}"
  # https://github.com/friendica/docker/issues/233
  smtp_starttls="${SMTP_STARTTLS:=on}"

  # Setup MSMTP
  usermod --comment "$(echo "$SITENAME" | tr -dc '[:print:]')" root
  usermod --comment "$(echo "$SITENAME" | tr -dc '[:print:]')" www-data

  # add possible mail-senders
  {
    echo "www-data: $smtp_from@$SMTP_DOMAIN"
    echo "root: $smtp_from@$SMTP_DOMAIN"
  } >/etc/aliases

  # create msmtp settings
  {
    echo "account default"
    echo "host $SMTP"
    if [ -n "${SMTP_PORT+x}" ]; then echo "port $SMTP_PORT"; else echo "port 587"; fi
    echo "from \"$smtp_from@$SMTP_DOMAIN\""
    echo "tls_certcheck off" # No certcheck because of internal docker mail-hostnames
    if [ -n "${SMTP_TLS+x}" ]; then echo "tls on"; fi
    echo "tls_starttls $smtp_starttls";
    if [ -n "${SMTP_AUTH_USER+x}" ]; then echo "auth $smtp_auth"; fi
    if [ -n "${SMTP_AUTH_USER+x}" ]; then echo "user \"$SMTP_AUTH_USER\""; fi
    if [ -n "${SMTP_AUTH_PASS+x}" ]; then echo "password \"$SMTP_AUTH_PASS\""; fi
    echo "logfile -"
    echo "aliases /etc/aliases"
  } >/etc/msmtprc

  echo "Setup finished"
fi
