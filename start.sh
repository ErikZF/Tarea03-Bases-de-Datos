#!/bin/bash

echo "--- Limpiando puertos ocupados ---"
fuser -k 5223/tcp 2>/dev/null

echo "--- Levantando Base de Datos ---"
cd database && docker compose down -v && docker compose up -d

echo "--- Levantando Backend ---"
cd ../backend/PlanillaAPI
dotnet run &
BACKEND_PID=$!
echo "--- Esperando 12 segundos al API ---"
sleep 12

echo "--- Levantando Frontend ---"
cd ../../frontend/planilla-app
ng serve -o

# Al final, si cierras el script, podrías querer matar el proceso de dotnet
trap "kill $BACKEND_PID" EXIT
