#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILE="odoo-compose.yml"

echo "=== Demarrage Odoo avec Nginx (Audit Logs) ==="

# Etape 1: Arreter les conteneurs existants
echo "[1/3] Arret des conteneurs existants..."
docker compose -f "$COMPOSE_FILE" down

# Etape 2: Build de l'image
echo "[2/3] Build de l'image Odoo..."
docker compose -f "$COMPOSE_FILE" build

# Etape 3: Demarrer tous les services
echo "[3/3] Demarrage des services..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "=== Odoo demarre avec succes! ==="
echo ""
echo "Acces: http://localhost:8069"
echo "Login: admin / admin (premier demarrage)"
echo ""
echo "=== Audit Logs ==="
echo "Les logs d'authentification sont captures par Nginx avec:"
echo "  - IP reelle du client"
echo "  - User-Agent"
echo "  - Login et mot de passe testes"
echo ""
echo "Voir les logs en temps reel:"
echo "  docker logs -f odoo-nginx"
echo ""
echo "Filtrer les tentatives de login:"
echo "  docker logs odoo-nginx 2>&1 | grep authenticate"
echo ""
echo "Commandes utiles:"
echo "  - Arreter: docker compose -f $COMPOSE_FILE down"
echo "  - Arreter + supprimer donnees: docker compose -f $COMPOSE_FILE down -v"
