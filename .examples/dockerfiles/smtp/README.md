# SMTP section

In this subfolder are examples how to add SMTP support to the Friendica docker images.

Each directory represents the image-version of the Dockerfile.
It uses the stable-branches of the Friendica Dockerfiles out-of-the-box.
So if you want to use the develop-branch, you have to add the prefix `develop-` at the `FROM`clause (e.g. `FROM friendica:apache` -> `FROM friendica:develop-apache`)

- `SMTP_HOST` The host/IP of the SMTP-MTA

## Custom SMTP Settings

Currently, only `apache` and `fpm` supports custom SMTP settings.
You **have** to set `SMTP_TYPE` to `custom` for other settings than `SMTP_HOST` (default: `simple`) 

### SMTP Authentication
- `SMTP_USERNAME` Username for the SMTP-MTA user to authenticate.
- `SMTP_PASSWORD` Password for the SMTP-MTA user to authenticate.

### Additional settings 
- `SMTP_PORT` The port of the SMTP-MTA (default: `25`)
- `SMTP_AUTH` The authentication string for the SMTP-MTA (default: `A p`)
- `SMTP_TRUST_AUTH_MECH` The trusted authentication mechanism for the SMTP-MTA (default: `EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN`)
- `SMTP_AUTH_MECH` The authentication mechanism for the SMTP-MTA (default: `EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN`)