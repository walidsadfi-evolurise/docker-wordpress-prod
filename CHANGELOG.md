# Changelog

## [0.1.0] - 2026-11-04

### Added

- Caddy (TLS, HTTP/3) → nginx (FastCGI page cache, rate limits, security headers) → PHP-FPM (opcache, JIT, Redis extension) → MariaDB + Redis.
- Cart/session/login aware cache bypass; REST API and admin-ajax never cached.
- Real WP-Cron container, WP-CLI tool service.
- Nightly encrypted backups (DB + wp-content) with local retention and S3 upload; verified restore script.
- Health checks on every service; three isolated networks; file-based secrets.
- Makefile, init/bench/restore scripts, CI that boots the stack and asserts cache hits.
