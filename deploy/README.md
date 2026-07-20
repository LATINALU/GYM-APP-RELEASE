# Despliegue de Quantum Gym (web) en un VPS

La app web es un frontend estático (Flutter web) que habla directo con
Firebase (Auth/Firestore). El VPS solo sirve archivos — no hay backend propio.

## Requisitos

- VPS con Ubuntu/Debian y Docker (`curl -fsSL https://get.docker.com | sh`)
- Un dominio con registro A apuntando a la IP del VPS (necesario para HTTPS;
  Firebase Auth **requiere HTTPS** fuera de localhost)
- OpenSSH en tu máquina Windows (incluido en Windows 10/11)

## Pasos (primera vez)

1. **Autoriza el dominio en Firebase**: consola de Firebase → Authentication →
   Settings → Authorized domains → agrega `TU-DOMINIO.com`. Sin esto el login
   falla con `auth/unauthorized-domain`.
2. Edita `deploy/Caddyfile` y reemplaza `TU-DOMINIO.com` por tu dominio.
3. Desde la raíz del proyecto:
   ```powershell
   .\deploy\deploy.ps1 -VpsHost root@IP-DEL-VPS
   ```
   El script compila (`flutter build web --release`), sube `build/web` +
   `deploy/` por scp y levanta `nginx` (app) + `caddy` (HTTPS automático).
4. Abre `https://TU-DOMINIO.com`.

## Deploys siguientes

El mismo comando: recompila, sube y reinicia. `index.html` y el service worker
se sirven sin caché, así que los usuarios reciben la versión nueva al recargar.

## Notas

- **App Check**: en web está desactivado hasta registrar un site key de
  ReCaptcha (consola Firebase → App Check → Web). Al tenerlo, pasar
  `ReCaptchaV3Provider('SITE_KEY')` en `main.dart` y quitar el guard `!kIsWeb`.
- **GIFs de ejercicios**: en web se sirven por red (caché del navegador);
  la descarga offline solo aplica a Android/desktop.
- **Puerto 8080**: la app queda también expuesta sin TLS en `http://IP:8080`
  para pruebas; puedes quitar ese mapeo de `docker-compose.yml` en producción.
- Sin Docker: sirve `build/web` con nginx nativo usando el bloque `server`
  de `deploy/nginx.conf` y TLS con certbot.
