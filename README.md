# docker-wordpress-prod

[![CI](https://github.com/walidsadfi-evolurise/docker-wordpress-prod/actions/workflows/ci.yml/badge.svg)](https://github.com/walidsadfi-evolurise/docker-wordpress-prod/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A production WordPress / WooCommerce stack in one `docker compose up`.** Automatic TLS, nginx full-page cache that knows about carts and logged-in users, tuned PHP-FPM and MariaDB, Redis object cache, real cron, encrypted off-site backups, health checks on every service. The CI boots the whole thing, installs WooCommerce and asserts that the second page view is a cache hit.

```
                 ┌──────────┐      ┌───────────┐      ┌──────────┐
  internet ───▶  │  Caddy   │ ───▶ │   nginx   │ ───▶ │ PHP-FPM  │ ──┬─▶ MariaDB
                 │ TLS/HTTP3│      │ page cache│      │ WordPress│   └─▶ Redis
                 └──────────┘      └───────────┘      └──────────┘
                                                        ▲      ▲
                                                 cron ──┘      └── backup ──▶ S3
```

## Why

Most WordPress Docker examples stop at "it boots". This one is what I deploy for clients: the parts that keep a shop fast and recoverable under real traffic, with the reasoning written down next to each setting.

- **nginx FastCGI cache** keyed per URL, bypassed for POST, query strings, `wp-admin`, cart, checkout, account pages, WooCommerce session and login cookies. The REST API and `admin-ajax` are never cached, so agents and the Store API always see live stock and prices.
- **Three networks** (`edge`, `app`, `data`): the database and Redis are not reachable from the edge, PHP is not reachable from the internet.
- **Secrets as files**, never in `.env` or the image.
- **Rate limits** on `wp-login.php` and `xmlrpc.php` blocked outright.
- **WP-Cron on a real clock** (`DISABLE_WP_CRON` + a cron container), so scheduled sales, emails and stock syncs run even with no visitors.
- **Backups** every night: MariaDB dump + `wp-content` archive, AES-256 encrypted with GnuPG, checksummed, kept N days locally and copied to any S3-compatible bucket (AWS, OVH, Scaleway, MinIO). A restore script that verifies checksums first.
- **Health checks** on Caddy, nginx, PHP-FPM (status page), MariaDB and Redis, with `depends_on: condition: service_healthy` so `compose up --wait` means "ready to serve".

## Quick start

Requirements: a Linux host with Docker Engine 24+ and Compose v2, a DNS record pointing at it, ports 80/443 open.

```bash
git clone https://github.com/walidsadfi-evolurise/docker-wordpress-prod.git
cd docker-wordpress-prod
make init                 # creates .env and random secrets
$EDITOR .env              # SITE_HOST and ACME_EMAIL at least
make up                   # builds the PHP image, starts everything, waits for health
make wp ARGS="core install --url=https://shop.example.com --title=Shop --admin_user=admin --admin_email=you@example.com --prompt=admin_password"
make wp ARGS="plugin install woocommerce redis-cache --activate"
make wp ARGS="redis enable"
```

Open `https://shop.example.com`. Caddy obtains the certificate on first request.

## Day-2 operations

| Task | Command |
| --- | --- |
| Logs | `make logs` |
| WP-CLI | `make wp ARGS="plugin list"` |
| Benchmark | `make bench N=50` (home page, Store API, REST index; shows `X-Cache`) |
| Backup now | `make backup` |
| Restore | `make restore DIR=backups/20261104T030000Z` |
| Flush page cache | `docker compose exec nginx sh -c 'rm -rf /var/cache/nginx/*'` |
| Update images | edit `WORDPRESS_TAG` in `.env`, then `make up` |

Backups live in the `backups` volume (`docker compose exec backup ls /backups`). To copy one out: `docker cp "$(docker compose ps -q backup)":/backups/<stamp> ./`.

## Tuning

The defaults target a 2 vCPU / 4 GB host serving a WooCommerce shop. Three numbers matter:

| Setting | File | Rule of thumb |
| --- | --- | --- |
| `pm.max_children` | `php/www.conf` | RAM for PHP ÷ worker RSS (60–90 MB on WooCommerce) |
| `innodb_buffer_pool_size` | `mariadb/my.cnf` | ~60 % of RAM dedicated to the database |
| `REDIS_MAXMEMORY` | `.env` | 256 MB covers most catalogs under 50k products |

Cache TTL is 10 minutes for pages (`fastcgi_cache_valid` in `nginx/conf.d/wordpress.conf`); stock-sensitive pages are bypassed anyway. For a purge on publish, install any plugin that deletes `/var/cache/nginx` entries or shorten the TTL.

## Where it fits

- **Single VPS**: as is. Caddy on the host ports, everything else internal.
- **Behind Cloudflare or a load balancer**: drop the `caddy` service (`compose.ci.yml` shows how), publish `nginx` and let the edge terminate TLS. nginx already trusts `X-Forwarded-Proto` from private ranges.
- **Kubernetes**: the same nginx/PHP/MariaDB/Redis split, with ingress-nginx and Helm, lives in [wordpress-k8s-stack](https://github.com/walidsadfi-evolurise/wordpress-k8s-stack).

## CI

`.github/workflows/ci.yml` lints (`compose config`, ShellCheck, `nginx -t`) and then boots the stack on the runner, installs WordPress, WooCommerce and the Redis object cache, creates a product and asserts: page 200, second hit `X-Cache: HIT`, Store API uncached and showing the product, HSTS present, `X-Powered-By` absent, Redis connected, backup script completes.

## Limits

- Single-node. For multi-node you need shared storage for `wp-content/uploads` (S3 offload plugin or NFS) and an external database.
- Caddy's HTTP/3 needs UDP 443 open on the host firewall.
- The backup container holds the S3 credentials; scope that IAM user to the bucket.

## License

MIT © [Walid Sadfi](https://github.com/walidsadfi-evolurise)

---

### En français

Stack WordPress / WooCommerce de production : TLS automatique, cache de page nginx qui respecte paniers et sessions, PHP-FPM et MariaDB réglés, Redis, cron réel, sauvegardes chiffrées vers S3, healthchecks partout. C'est la base que je déploie pour mes clients, avec la raison de chaque réglage écrite à côté.

Besoin d'une mise en production ou d'un audit de performance ? [Profil Malt](https://www.malt.fr/profile/walidsadfi).
