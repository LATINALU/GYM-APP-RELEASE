# Quantum Gym — imagen para servir el build web con nginx.
#
# El build de Flutter se hace FUERA de la imagen (en tu máquina o en CI):
#   flutter build web --release
# y luego:
#   docker build -f deploy/Dockerfile -t quantum-gym-web .
#
# Así la imagen pesa ~15 MB y no necesita el SDK de Flutter en el VPS.

FROM nginx:1.27-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

EXPOSE 80
