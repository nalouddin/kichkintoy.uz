#!/bin/bash
# Kichkintoy Connect — server deploy skripti
# Serverda shu papkada ishga tushiring: bash deploy.sh

set -e

echo "=== Kichkintoy Deploy ==="

# Docker va Docker Compose borligini tekshirish
if ! command -v docker &> /dev/null; then
    echo "Docker o'rnatilmagan. O'rnatilmoqda..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Eski containerlarni to'xtatish (ma'lumotlar saqlanadi!)
docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true

# Yangi build va ishga tushirish
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build

echo ""
echo "=== Tayyor! ==="
echo "Web:    http://bolajon.tersu.uz"
echo "API:    http://bolajon.tersu.uz/api/v1/"
echo "Docs:   http://bolajon.tersu.uz/docs"
echo ""
echo "Loglarni ko'rish: docker compose -f docker-compose.prod.yml logs -f"
