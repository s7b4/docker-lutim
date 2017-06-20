# docker-lutim

## Projet Lutim

https://framagit.org/luc/lutim#tab-readme

## Compose

### `docker-compose.yml`

Le format 2.2 est nécessaire à cause de l'option init, l'option init permet de recharger Hypnotoad

	services:
	  app:
	    image: s7b4/lutim
	    init: true
	    network_mode: bridge
	    ports:
	    - 8080:8080/tcp
	    restart: always
	version: '2.2'


## Cron lutim

### Nettoyage de la db

	docker-compose exec app docker-carton exec script/lutim cron cleanbdd --mode production

### Nettoyage des images

	docker-compose exec app docker-carton exec script/lutim cron cleanfiles --mode production

### Cron des statistiques

	docker-compose exec app docker-carton exec script/lutim cron stats --mode production
	docker-compose exec app kill -USR2 1
