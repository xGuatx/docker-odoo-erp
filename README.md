# Docker Odoo ERP avec Audit Logs

Stack Docker pour Odoo 19 avec capture des logs d'authentification via Nginx reverse proxy.

## Architecture

```
Client (192.168.x.x)
        |
        v
+---------------+
|     Nginx     |  <-- Capture IP reelle + logs auth (login/password)
|   (port 80)   |
+---------------+
        |
        v
+---------------+
|     Odoo      |
|  (port 8069)  |
+---------------+
        |
        v
+---------------+
|  PostgreSQL   |
|  (port 5432)  |
+---------------+
```

## Problematique

Odoo en Docker ne voit pas l'IP reelle du client :
- Docker utilise un reseau bridge avec NAT
- Le conteneur voit uniquement l'IP du gateway Docker (ex: 172.22.0.1)
- Meme depuis une autre machine du reseau, l'IP capturee reste celle du gateway

## Solution

Nginx en reverse proxy :
- Capture l'IP reelle du client avant le NAT Docker
- Transmet l'IP via les headers `X-Forwarded-For` et `X-Real-IP`
- Log le body des requetes POST (contient login + password)

## Informations capturees

Chaque requete HTTP est loggee par Nginx avec :
- **IP reelle** du client
- **Timestamp**
- **URL** demandee
- **User-Agent** (navigateur, OS, device)
- **Body** de la requete (login + password pour /web/session/authenticate)

## Resultats des tests

### Test depuis le reseau local (Android)

```
192.168.1.81 - [03/Feb/2026:22:46:34 +0000]
"POST /web/login HTTP/1.1" 200
"Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 Chrome/144.0.0.0 Mobile Safari/537.36"
```

### Test avec capture du mot de passe

```
192.168.1.81 - [03/Feb/2026:23:08:14 +0000]
"POST /web/session/authenticate HTTP/1.1" 200
"Mozilla/5.0 (Linux; Android 10)"
body:{"jsonrpc":"2.0","params":{"db":"odoo","login":"admin","password":"test123"}}
```

### Informations extraites

| Champ       | Valeur                          |
|-------------|--------------------------------|
| IP          | 192.168.1.81                   |
| Device      | Mobile                         |
| OS          | Android 10                     |
| Browser     | Chrome Mobile 144.0            |
| Login       | admin                          |
| Password    | test123                        |

## Demarrage rapide

```bash
./start-odoo.sh
```

Acces : http://localhost:8069

## Voir les logs d'authentification

```bash
# Temps reel
docker logs -f odoo-nginx

# Filtrer les tentatives de login
docker logs odoo-nginx 2>&1 | grep authenticate
```

## Commandes utiles

```bash
# Demarrer
docker compose -f odoo-compose.yml up -d

# Arreter
docker compose -f odoo-compose.yml down

# Arreter + supprimer les donnees
docker compose -f odoo-compose.yml down -v

# Logs Odoo
docker logs -f odoo-app

# Logs Nginx (authentification)
docker logs -f odoo-nginx
```

## Structure

```
docker-odoo-erp/
|-- Dockerfile          # Image Odoo 19
|-- odoo-compose.yml    # Stack Docker (Odoo + PostgreSQL + Nginx)
|-- nginx.conf          # Config Nginx avec capture body
|-- start-odoo.sh       # Script de demarrage
+-- README.md
```

## Securite

**ATTENTION** : Cette configuration capture les mots de passe en clair dans les logs Nginx.

A utiliser uniquement pour :
- Environnement de test/lab
- Honeypot
- Audit de securite

**Ne pas utiliser en production** sans adapter la configuration.

## Personnalisation

### Changer le port

Modifier dans `odoo-compose.yml` :
```yaml
nginx:
  ports:
    - "8080:80"  # Nouveau port
```

### Desactiver la capture des passwords

Modifier dans `nginx.conf`, remplacer le log_format par :
```nginx
log_format detailed '$remote_addr - [$time_local] "$request" $status "$http_user_agent"';
```

## Pourquoi pas de module Odoo custom ?

Un module Odoo pour logger les authentifications a ete teste mais :
- Redondant avec les logs Nginx (qui capturent plus d'infos)
- Ajoute une surface d'attaque supplementaire
- Necessite des dependances Python (user-agents)
- Ne capture que les auth reussies par defaut

Nginx capture tout (succes + echecs) sans modifier Odoo.

## License

Usage personnel - Environnement de test uniquement.

Odoo Community Edition est open-source (LGPL).
