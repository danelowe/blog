---
title: Simple and Robust Nginx config for Magento
date: 2015-02-05 13:02 UTC
tags: Magento, Sysadmin
---

I have a few requirements for my Magento Nginx configuration

1. I need to understand what it is doing, at first glance.
2. I need to be able to create subdomains in a DRY fashion.
3. It needs to be secure.
4. It needs to work, and be performant.

This is not using any load-balancer. It is a single server fronted by Nginx.

This isn't too much to ask, but the idiomatic Nginx config for Magento just wasn't cutting it for me. 

I've always been bugged by the fact that Magento dumps application code, shell scripts and configuration files
directly in the public directory.
If one bit of config is missed, or a compromising file is added or renamed without updating the nginx config, 
that becomes one opportunity for the wrong file to be accessed in the wrong way via the web server. 
 
So, what can we do? We can revisit the way Magento is served:

* We define an 'App Server' that only serves the Magento App, and nothing else.
* We define one or more 'Asset Servers' that only serve static assets.
* On the App server, we route every single request through one of the few whitelisted entry points for Magento.
* On the Asset Servers, we only serve files from whitelisted directories. 
* We optimise the configuration of each server separately. 
* We make use of generic includes to make our intentions clearer, and make it easier to add new server configs.

Not only is this approach a little more secure, it makes things a lot easier to reason and maintain. 
Have a look through the configuration below and see if you would agree. 
 
## The App Server

~~~nginx
# sites-available/mydomain
server {
    listen         80;
    server_name    mydomain.com www.mydomain.com;
    rewrite        ^ https://www.mydomain.com$request_uri? permanent;
}

server {
    listen 443 default ssl;
    server_name mydomain.com www.mydomain.com;
    root /var/www/magento/current/public;

    include includes/ssl;
    include includes/mage;

    fastcgi_param  MAGE_RUN_CODE default;

    location /admin               { return 404; }
}
~~~

The first server block simply redirects any HTTP request to HTTPS.

I don't think there is any reason not to do this, and plenty of reasons to always do it. 
The overheads are probably negligible when you've already got Magento as an overhead. 
Any cookie that is sent over HTTP has the potential to be intercepted. 
Remember, Magento uses a persistent session ID stored in a cookie.

Note the use of the includes. 
This is simply including boilerplate config that will be shared among all of the 'app servers'.
I will show you this boilerplate config in a tick. 

In this case, each app server represents a new store view with a specified domain.
For this reason, the MAGE_RUN_CODE is specified in this server block. 
There probably is a way of conditionally defining the MAGE_RUN_CODE within the same server block,
but it feels much cleaner to me to define each domain in it's own server block.

This particular app server does not allow access to the admin interface. It will always return a 404 here. 
 
### The Magento Boilerplate

~~~nginx
# includes/mage
gzip             on;
gzip_min_length  1000;
gzip_proxied     expired no-cache no-store private auth;
gzip_types       text/plain application/xml application/x-javascript text/css;
gzip_disable     "MSIE [1-6]\.";

expires        off;
include        fastcgi_params;
fastcgi_param  HTTPS $fastcgi_https;
fastcgi_param  SCRIPT_FILENAME  $document_root/index.php;
fastcgi_param  MAGE_RUN_TYPE store;


location /api {
    rewrite ^/api/rest /api?type=rest last;
    include        fastcgi_params; 
    fastcgi_pass unix:/dev/shm/php-fastcgi.socket;
    fastcgi_param  SCRIPT_FILENAME  $document_root/api.php;
}

location = /ajax {
    include        fastcgi_params; 
    fastcgi_pass unix:/dev/shm/php-fastcgi.socket;
    fastcgi_param  SCRIPT_FILENAME  $document_root/ajax.php;
}

location / {
    fastcgi_pass unix:/dev/shm/php-fastcgi.socket;
}

location ~ .php$              { return 404; }
location /app/                { return 404; }
location /downloader/         { return 404; }
location /errors/             { return 404; }
location /media/              { return 404; }
location /assets/             { return 404; }
location /images/             { return 404; }
location /skin/               { return 404; }
location /includes/           { return 404; }
location /lib/                { return 404; }
location /media/downloadable/ { return 404; }
location /pkginfo/            { return 404; }
location /report/config.xml   { return 404; }
location /shell/              { return 404; }
location /var/                { return 404; }
location /.                   { return 404; }

if (-f $document_root/maintenance.html) {
    return 503;
}
error_page 503 @maintenance;
location @maintenance {
    try_files /maintenance.html =404;
}
error_page 404 /404;
~~~

Again, this configuration all seems quite simple and easy to understand. 
No complex rewrite rules or confusion over which location is matched.

Every single request to an 'App Server' is routed to PHP-FPM. 
No static assets or non-PHP files are served.

In addition, every single request is routed through one of three whitelisted entry points; 
index.php, api.php or ajax.php.
ajax.php is a custom entry point that I use for ajax requests that do not load the entire Magento environment.
Simply remove the location block to revoke access to that entry point. I love the simplicity. 

Note all the locations that return 404. 
I think it is important to point out that this is not particularly required 
to prevent access to these files and directories. 
Remember any location that is not explicitly defined will be served via PHP-FPM using index.php as the entry point, 
and so will return a Magento 404 
The point in these 404 locations is simply to increase performance in the case that any request is made 
to these locations, by circumventing PHP.

However, to contradict that, there is some config just below that uses the /404 location to serve any 404.
This will be routed through php as well to serve the Magento 404 page.
At the moment I'm considering whether to generate a static 404 page during the build process, 
or create another entry point that doesn't load the entire Magento environment.
You may want to consider changing this 404 config or removing the 404 locations.
 
## The Admin server

Remember we blocked access to the Magento admin at the web server level on the first 'App Server'. 
We need to define a new server block for our admin server. 
Note how little new config is needed.

~~~nginx 
# sites-available/admin
server {
    listen         80;
    server_name    magentoadmin.mydomain.com;
    rewrite        ^ https://magentoadmin.mydomain.com$request_uri? permanent;
}
server {
    listen 123.123.123.123:443 ssl;
    server_name magentoadmin.mydomain.com;
    root /var/www/magento/current/public;

    include includes/ssl;
    include includes/mage;

    auth_basic            "mage";
    auth_basic_user_file  htpasswd;
    fastcgi_param  MAGE_RUN_CODE default;
    location = / {
        return 301 https://magentoadmin.mydomain.com/index.php/admin;
    }
}
~~~

It is immediately clear what the differences are. 
We redirect to the admin path for convenience, and require a HTTP Basic Auth password.
 
The password is a quick and convenient way to add a bit of extra security because:

* It means you're not 100% reliant on Magento/PHP to provide security. 
A lot of attack vectors could be removed if one is refused by the web server. 
* It can mask the fact that you're even using Magento. 
* It makes it easy to use tools like Fail2Ban to lock out a brute force attack.
* It means that a brute-force won't be using up the server's resources as much as it otherwise would.

## Asset Servers

~~~nginx
# sites-available/assets
server {
    listen 80;
    server_name  assets.mydomain.com;
    root  /var/www/magento/current/public/assets;
    include includes/assets;
    location /assets/ {
        alias /var/www/magento/current/public/assets/;
        break;
    }
    location /media/ {
        alias /var/www/magento/current/public/media/;
        break;
    }
    location /images/ {
        alias /var/www/magento/current/public/images/;
        break;
    }
    location /skin/ {
        alias /var/www/magento/current/public/skin/;
        break;
    }
}
~~~

Again it is immediately clear what we are doing.
We are 'whitelisting' some directories to serve static assets from on assets.mydomain.com. 

### The Asset Boilerplate

Add any config you want here to apply to all static assets, 
e.g. set their expires headers, static GZip, and hotlink protection. 
You could also explicitly whitelist the file types here too. Or set some CORS headers.  

~~~nginx
# includes/assets
add_header "Access-Control-Allow-Origin" "*";
gzip_static on;
expires max;
add_header Cache-Control public;
valid_referers none blocked mydomain.com *.mydomain.com;
if ($invalid_referer) {
    return   403;
}
~~~

## The complete setup.

Put all these files together, and you'll have what 
I consider to be quite a simple and reasonable Nginx configuration to serve a Magento site from a single box. 
 
Is there anything that you would add or change? 

P.S. I actually have these files as part of my repository, and change nginx.conf to include them

P.P.S **Don't forget to setup Magento to use the static asset servers, 
and make sure to whitelist your sitemaps and any product feeds you may have**  
