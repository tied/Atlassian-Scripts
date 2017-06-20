These are scripts and notes compiled while migrating JIRA and Confluence from Cloud to Server.

This command does a quick comparison between the modulus value in the cert vs the modulous value in the key. md5 hash is not necessary but makes it more readable. I did not write this, adding it here for easy access.
(openssl x509 -noout -modulus -in domain.crt | openssl md5; openssl rsa -noout -modulus -in private.key | openssl md5) | uniq
