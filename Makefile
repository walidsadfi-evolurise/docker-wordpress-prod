.PHONY: init up down logs ps wp bench backup restore lint
init:      ; sh scripts/init.sh
up:        ; docker compose up -d --build
down:      ; docker compose down
logs:      ; docker compose logs -f --tail=100
ps:        ; docker compose ps
wp:        ; docker compose run --rm wp $(ARGS)
bench:     ; sh scripts/bench.sh https://$$(grep ^SITE_HOST .env | cut -d= -f2) $(N)
backup:    ; docker compose exec backup /usr/local/bin/backup.sh
restore:   ; sh scripts/restore.sh $(DIR)
lint:      ; docker compose config -q && shellcheck scripts/*.sh backup/*.sh
