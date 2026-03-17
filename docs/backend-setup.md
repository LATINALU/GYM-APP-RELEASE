# Backend Setup - InsForge Integration

## Overview
GainWave utiliza el backend **InsForge** para persistencia de datos y autenticación.

## Repository
El backend está disponible en: https://github.com/SamamaHussain/insforge

## Configuración Rápida

### 1. Clonar el Backend
```bash
# Desde la carpeta raíz del proyecto
cd ..
git clone https://github.com/SamamaHussain/insforge.git backend
cd backend
```

### 2. Instalar Dependencias
```bash
npm install
```

### 3. Configurar Variables de Entorno
```bash
cp .env.gym-app.example .env
# Editar .env con tus credenciales
```

### 4. Iniciar Servicios
```bash
# Desarrollo local
docker-compose up -d

# O producción
docker-compose -f docker-compose.prod.yml up -d
```

## Variables de Entorno Clave
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Clave para tokens JWT
- `S3_BUCKET`: Para almacenamiento de archivos
- `POSTGREST_URL`: API REST endpoint

## Integración con Flutter
La app Flutter se conecta al backend a través de:
- `lib/src/infrastructure/insforge/` - Adaptadores HTTP
- La app principal usa Firebase Auth real por defecto

## Endpoints Principales
- `/api/auth/sessions` - Login
- `/api/auth/users` - Registro
- `/api/gyms` - Gestión de gimnasios
- `/api/exercises` - Biblioteca de ejercicios
- `/api/workout_routines` - Rutinas de entrenamiento

## Más Información
Ver la documentación completa en el repositorio de InsForge.
