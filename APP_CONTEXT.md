# 🧠 CONTEXTO TÉCNICO Y FUNCIONAL: QUANTUM GYM

Este documento es la referencia definitiva para entender la estructura, navegación y lógica de negocio de la aplicación.

---

## 🏛️ ARQUITECTURA: Clean + Hexagonal
La aplicación utiliza una arquitectura separada por capas para permitir el intercambio de tecnologías (ej. cambiar Firebase por otra DB) sin afectar la lógica de negocio.

### Capas:
1.  **Dominio (`lib/src/01-domain`)**: 
    - Contiene los modelos base (`entities`).
    - Define interfaces para repositorios (`ports/output`).
    - Define interfaces para casos de uso (`ports/input`).
    - **No tiene dependencias externas.**

2.  **Aplicación (`lib/src/02-application`)**:
    - Implementa la lógica de los casos de uso.
    - Maneja la orquestación entre servicios.
    - Utiliza inyección de dependencias para recibir los repositorios.

3.  **Infraestructura (`lib/src/03-infrastructure`)**:
    - Implementaciones reales de Firebase (`adapters`).
    - Configuración del contenedor de dependencias (`config/di.dart`).
    - Transformación de datos (`mappers`).

4.  **Presentación (`lib/src/04-presentation`)**:
    - Manejo de estado con `Bloc`.
    - Rutas con `GoRouter` (`router/app_router.dart`).
    - Estilos con el sistema `Quantum UX`.

---

## 🧭 MAPA COMPLETO DE RUTAS

### Autenticación y Perfil
- `/login`: Pantalla de entrada.
- `/register`: Registro de nuevos atletas.
- `/profile`: Visualización de perfil.
- `/profile/edit`: Edición de datos personales.
- `/settings`: Ajustes generales de la aplicación.

### Cliente (Atleta)
| Ruta | Función |
|------|---------|
| `/client/home` | Dashboard principal con progreso de hoy y accesos rápidos. |
| `/client/routine` | Lista de rutinas asignadas por el gimnasio. |
| `/client/daily-workout` | Interfaz de ejecución de ejercicios en tiempo real. |
| `/client/workout-planning` | Calendario para programar futuras sesiones. |
| `/client/mesocycle` | Gestión de bloques de entrenamiento a largo plazo. |
| `/client/chatbot` | Asistente de IA para dudas técnicas. |
| `/client/analytics` | Gráficas detalladas de rendimiento y volumen. |
| `/client/recovery-form` | Check-in diario de estado físico/mental. |
| `/client/exercise-library` | Biblioteca técnica de ejercicios con videos/instrucciones. |

### Administrador (Dueño de Gym)
- `/owner/dashboard`: Visión general de ingresos y ocupación.
- `/owner/members`: Base de datos de clientes y estados de pago.
- `/owner/routine-builder`: Herramienta para crear y asignar rutinas a clientes.
- `/owner/pos`: Punto de venta para suplementos y mensualidades.
- `/owner/staff`: Gestión de entrenadores y personal.

---

## 💎 SISTEMA DE DISEÑO: QUANTUM
El lenguaje visual es **Oscuro Premium** enfocado en pantallas OLED para ahorrar batería durante el entrenamiento.

- **Fondo:** `#0F0F12` (Cosmic Black)
- **Acento 1:** `#00E0FF` (Quantum Blue)
- **Acento 2:** `#00FFE0` (Matrix Cyan)
- **Superficies:** `#1A1A21` (Void Gray)

**Tipografía:**
- Encabezados: `Inter` (Extra Light / Light para elegancia).
- Métricas: `JetBrains Mono` (Para legibilidad de datos técnicos).

---

## 📊 ENTIDADES DE DATOS PRINCIPALES
- **User**: Nombre, rol (admin/client/owner/staff), gymId, suscripción.
- **Gym**: Nombre, código único, config financiera, dueño.
- **PendingRegistration**: Cola de pre-aprobación (usuarios esperando ser aceptados).
- **AccessCode**: Códigos seguros CSPRNG para acceso, onboarding, invitaciones.
- **GymMembership**: Relación usuario-gym con historial de planes.
- **Workout Routine**: Nombre, ejercicios, duración, dificultad.
- **Exercise**: Músculo principal, técnica, sets realizados.
- **Nutrition Log**: Calorías, Macros (Proteína, Carbos, Grasas).
- **Measurement**: Peso, % grasa, perímetros musculares.
- **AuditLog**: Registro inmutable de acciones de seguridad.

---

## 🛠️ STACK TECNOLÓGICO
- **Framework:** Flutter (Multiplataforma - Android, iOS, Web, Desktop).
- **Backend/DB (actual):** Firebase (Firestore, Auth).
- **Backend/DB (futuro):** PostgreSQL en VPS + API REST (Supabase/Custom).
- **Local DI:** GetIt.
- **State:** Flutter BLoC.
- **Routing:** GoRouter.

---

## 🔐 SEGURIDAD
- **Códigos de Acceso:** CSPRNG via `Random.secure()`, prefijos por tipo, expiración configurable.
- **Multi-Tenancy:** Aislamiento por `gym_id` en todas las consultas.
- **Roles:** admin > owner > employee > client (permisos jerárquicos).
- **Pre-Aprobación:** Los usuarios registrados deben ser aceptados por un gym antes de acceder.
- **Firestore Rules:** RLS implementado con validación de permisos por rol.

---
*Este documento se actualiza periódicamente para reflejar el estado actual del desarrollo.*
