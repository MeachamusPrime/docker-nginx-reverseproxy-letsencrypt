# Nginx reverse proxy with embedded Let's Encrypt certificates

## What is it?

This [repository](https://github.com/bh42/docker-nginx-reverseproxy-letsencrypt) contains a Docker container which embeds an Nginx as reverse-proxy, linked with Let's Encrypt (using [acme.sh](https://acme.sh)) for SSL/TLS certificates.

You can find it on Docker Hub: [bh42/nginx-reverseproxy-letsencrypt](https://hub.docker.com/r/bh42/nginx-reverseproxy-letsencrypt)

The Nginx configuration is purposedly user-defined, so you can set it just the way you want.

However, you can find an example below.

## How does it work?

This image is based upon the official Nginx repository, using the alpine version (`nginx:alpine`).

[acme.sh](https://acme.sh) is installed, and certificates are generated/requested during the first start.

First of all, self-signed certificates are generated, so Nginx can start with your SSL/TLS configuration.

Then, [acme.sh](https://acme.sh) is used to requested LE-signed certificates, which will replace the self-signed ones.

## Usage

### Configuration

#### Volumes

Two volumes are used :
* `/certs`: all the certificates will be stored here (including dhparam.pem). You do not need to put anything by yourself, the container will do it itself.
* `/conf`: place your Nginx configuration file(s) here. An `nginx.conf` is required, the rest is up to you.

#### Environment variables

The following variables can be set:
* `DRYRUN`: set it to whatever value to use the staging Let's Encrypt environment during your tests.
* `KEYLENGTH`: defines the key length of your Let's Encrypt certificates (1024, 2048, 4096, ec-256, ec-384, ec-521 [not supported by LE yet], etc). Default is set to 4096.
* `EMAIL`: e-mail address used to register with ZeroSSL ([acme.sh wiki](https://github.com/acmesh-official/acme.sh/wiki/ZeroSSL.com-CA))
* `DHPARAM`: defines the Diffie-Hellman parameters key length. Default is set to 2048. *Be aware that it can take much time, way more than just a couple minutes.*
* `SERVICE_HOST_x`/`SERVICE_PROXY_x`/`SERVICE_PROXY_x_y`/`SERVICE_LOCATION_x_y`: Matched entries per domain. (Note that if you supply both `SERVICE_PROXY_x` and `SERVICE_PROXY_x_y` then `SERVICE_PROXY_x_y` will be ignored)
   * `SERVICE_HOST_x`: The domain for which you want certificates
      * `SERVICE_HOST_WEBSITE`, `SERVICE_HOST_API`, `SERVICE_HOST_REPOSITORIES`
   * `SERVICE_PROXY_x`: defines the hostname, URL, or IP Address of your proxy service (for example, if you have a website at `website.mydomain.com`, set it to `website.mydomain.com`). Use `SERVICE_PROXY_1` for `SERVICE_HOST_1`, etc.
      * `SERVICE_PROXY_WEBSITE`, `SERVICE_PROXY_API`
   * `SERVICE_PROXY_x_y`: defines the hostname, URL, or IP Address of one of your colocated proxy services (for example, if you have a website at `nuget.mydomain.com`, set it to `nuget.mydomain.com`). Use `SERVICE_PROXY_1_y` for `SERVICE_HOST_1`, etc.
      * `SERVICE_PROXY_REPOSITORIES_DOCKER`, `SERVICE_PROXY_REPOSITORIES_NUGET`, `SERVICE_PROXY_REPOSITORIES_NPM`
   * `SERVICE_LOCATION_x_y`: defines the location of one of your colocated services (for example, if you want a NuGet repository at `repo.mydomain.com/nuget`, set it to `/nuget`, or, for the root website, do not set `SERVICE_LOCATION_x_y`). Use `SERVICE_LOCATION_1_y` for `SERVICE_HOST_1`, etc.
      * `SERVICE_LOCATION_REPOSITORIES_NUGET`, `SERVICE_LOCATION_REPOSITORIES_NPM`
* `SERVICE_SUBJ_x`: the self-signed certificate subject of `SERVICE_HOST_x`. The expected format is the following: `/C=Country code/ST=State/L=City/O=Company/OU=Organization/CN=your.domain.tld`. It's not really useful, but still, it's there. Use `SERVICE_SUBJ_1` for `SERVICE_HOST_1`, etc.
  
Note regarding `SERVICE_PROXY_x`: these environment variables will automatically generate an nginx conf file named `x.conf` (`x` being lowercase'd), based on `service.conf.template`.

**_WARNING_**: Note that if your proxy services are reachable on the internet without the proxy, then your services are not protected by your proxy's TLS certificate.

### Docker cli

Here is an example with two domains:
```
docker run \
  -p 80:80 \
  -p 443:443 \
  -v /home/user/my_nginx_conf:/conf \
  -v /home/user/my_certs:/certs \
  -e KEYLENGTH=ec-384 \
  -e EMAIL=johndoe@gmail.com \
  -e DHPARAM=4096 \
  -e SERVICE_HOST_WEBSITE=www.mydomain.com \
  -e SERVICE_HOST_API=subdomain.mydomain.com \
  -e SERVICE_HOST_REPOSITORIES=repo.mydomain.com \
  -e SERVICE_PROXY_WEBSITE=website.mydomain.com \
  -e SERVICE_PROXY_API=api.mydomain.com \
  -e SERVICE_PROXY_REPOSITORIES_DOCKER=docker.mydomain.com \
  -e SERVICE_PROXY_REPOSITORIES_NUGET=nuget.mydomain.com \
  -e SERVICE_PROXY_REPOSITORIES_NPM=npm.mydomain.com \
  -e SERVICE_LOCATION_REPOSITORIES_NUGET=nuget \
  -e SERVICE_LOCATION_REPOSITORIES_NPM=npm \
  --name reverse-proxy \
  -t -d
```

### Docker-compose

```yaml
version: '3.7'
services:
  proxy:
    container_name: "proxy"
    image: bh42/nginx-reverseproxy-letsencrypt:latest
    environment:
      - KEYLENGTH=ec-384
      - EMAIL=johndoe@gmail.com
      - DHPARAM=4096
      - SERVICE_HOST_WEBSITE=www.mydomain.com
      - SERVICE_HOST_API=subdomain.mydomain.com
      - SERVICE_HOST_REPOSITORIES=repo.mydomain.com
      - SERVICE_PROXY_WEBSITE=website.mydomain.com
      - SERVICE_PROXY_API=api.mydomain.com
      - SERVICE_PROXY_REPOSITORIES_DOCKER=docker.mydomain.com
      - SERVICE_PROXY_REPOSITORIES_NUGET=nuget.mydomain.com
      - SERVICE_PROXY_REPOSITORIES_NPM=npm.mydomain.com
      - SERVICE_LOCATION_REPOSITORIES_NUGET=nuget
      - SERVICE_LOCATION_REPOSITORIES_NPM=npm
    restart: unless-stopped
    tty: true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /home/user/my_certs:/certs
      - /home/user/my_nginx_conf:/conf
```

### Nginx configuration notes

**Since the certificates will be stored in `/certs`, be sure to write your Nginx configuration file(s) accordingly!**

The configuration files in `/conf` will be placed in `/etc/nginx/conf.d` in the container.  
If you do not use any `SERVICE_PROXY_x` environment variables, you can set the `conf` volume in read only (`:ro`) mode.
