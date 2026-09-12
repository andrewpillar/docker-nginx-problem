# Report

Detailed below are the problems encountered and the changes made to remediate
them, also detailed are the further changes made to the microservice too beyond
just the ones that solved the initial problem.

* [Problem 1: Misconfigured TLS certificate and key](#problem-1-misconfigured-tls-certificate-and-key)
* [Problem 2: Executable bitmask missing from script](#problem-3-executable-bitmask-missing-from-script)
* [Problem 3: Custom 404 page not displaying](#problem-3-custom-404-page-not-displaying)

* [Change 1: Reorganised entrypoint scripts](#change-1-reorganised-entrypoint-scripts)
* [Change 2: Formatted the entrypoint scripts](#change-2-formatted-the-entrypoint-scripts)
* [Change 3: NGINX configuration tweaks](#change-3-nginx-configuration-tweaks)

## Problem 1: Misconfigured TLS certificate and key

The container would fail to start with the following error,

```
2026/09/12 09:19:05 [emerg] 1#1: cannot load certificate "/etc/nginx/local.pem": BIO_new_file() failed (SSL: error:02001002:system library:fopen:No such file or directory:fopen('/etc/nginx/local.pem','r') error:2006D080:BIO routines:BIO_new_file:no such file)
nginx: [emerg] cannot load certificate "/etc/nginx/local.pem": BIO_new_file() failed (SSL: error:02001002:system library:fopen:No such file or directory:fopen('/etc/nginx/local.pem','r') error:2006D080:BIO routines:BIO_new_file:no such file)
```

This was due to the `ssl_certificate` and `ssl_ceritifcate_key` being
incorrectly configured, the following changes were made,

```diff
-ssl_certificate     local.pem;
-ssl_certificate_key local.key;
+ssl_certificate     /etc/nginx/localhost.pem;
+ssl_certificate_key /etc/nginx/localhost.key;
```

with these in place, the container started as expected.

## Problem 2: Executable bitmask missing from script

The executable bitmask was not set on the `41-get-404-page.sh` script, which
would have prevented its execution during the start of the container. Running
the command `chmod +x` solved this.

## Problem 3: Custom 404 page not displaying

When loading up NGINX in the browser, the default 404 page shipped with NGINX
was displayed as opposed to the custom one in the repository. The cause of this
was because of the `error_page` directive pointing to a missing location block.

The following changes were made to fix this,

```diff
-error_page 404 /var/www/nginx/errors/404.html;
+error_page 404 /errors/404.html;

location / {
  return 404;
}

location /errors {
  internal;

  alias /var/www/nginx/errors/;
}
```

The `alias` directive was used in place of the `root` directive, as the `alias`
directive would replace the `/errors` location with what was given to the
directive itself. So, the URI `/errors/404.html` would become
`/var/www/nginx/errors/404.html`, this also offers up flexibility when custom
error pages want to be used in the future, with minimal configuration overhead.

## Change 1: Reorganised entrypoint scripts

The following scripts were moved into the new `entrypoint/` directory,

* `entrypoint/40-generate-cert.sh`
* `entrypoint/41-get-404-page.sh`

This better conveys each of the scripts' purpose as it relates to the container,
which is that it is executed when the container starts.

## Change 2: Formatted the entrypoint scripts

A new `entrypoint_log` function was added to each of the entrypoint scripts.
This will log the given arguments if the `NGINX_ENTRYPOINT_QUEIT_LOGS` variable
is not set. This will also log the name of the script from which the logging is
being done. This will help provide better observability over which script is
executing when the container starts.

For the `entrypoint/40-generate-cert.sh` script, the `openssl` command has been
formatted so that it wraps across multiple lines, this has been done for better
legibility. It also makes use of a new `CN` variable, that defines the CN to use
during certificate generation.

For the `entrypoint/41-get-404-page.sh` script, the `curl` command has also been
wrapped across multiple lines. It also now makes use of globbing in the URL, so
that multiple files could be fetched at some point in the future, for example,

```bash
curl --silent \
    --show-error \
    --output "/var/www/nginx/errors/#1.html" \
    "https://raw.githubusercontent.com/asmithdt/docker-nginx-problem/main/{400,403,404}.html"
```

the above would download the `400.html`, `403.html`, and `404.html` files from
the repository, and download each one as their respective file via the `#1`
pattern in the output string. This would save on having to write multiple curl
commands, should new custom error pages get added in the future.

## Change 3: NGINX configuration tweaks

Both server blocks now listen on the IPv6 address,

```diff
server {
  listen 80;
+ listen [::]:80;

  server_name _;

  return 301 https://$host:$request_uri;
}

server {
  listen 443 ssl;
+ listen [::]:443 ssl;
```

the SSL protocol versions are now also explicitly defined, to ensure the latest
ones are being used,

```diff
+ssl_protocols TLSv1.2 TLSv1.3;
```
