# 🏋️‍♂️ Quantum: Plataforma de Gestión de Gimnasios

Quantum es una plataforma completa de gestión de gimnasios con **Training Forge** - un sistema avanzado para crear rutinas, programas y gestionar ejercicios con biblioteca visual de imágenes.

---

## 🚀 CARACTERÍSTICAS PRINCIPALES

### 🏗️ Training Forge System
- **Atlas de Ejercicios Visual**: Sube y almacena imágenes/GIFs para cada ejercicio
- **CRUD Completo**: Crea, edita y elimina ejercicios, rutinas y programas
- **Biblioteca Visual**: Galería de imágenes con filtros por músculo y estado
- **Integración Visual**: Las imágenes del Atlas se muestran automáticamente en las cards del Training Forge
- **Persistencia en Memoria**: Almacenamiento compartido durante la sesión de la app

### 🎨 Sistema de Diseño Quantum UX
- **Interfaz Oscura Premium**: Optimizada para pantallas OLED
- **Paleta Futurista**: Cosmic Black, Quantum Blue, Matrix Cyan
- **Componentes Reutilizables**: GymButton, QuantumCards, HolographicDividers

### 🏛️ Arquitectura Limpia
- **Clean Architecture + DDD**: Separación estricta por capas
- **Dominio Puro**: Sin dependencias externas
- **Inyección de Dependencias**: Gestión centralizada con GetIt
- **State Management**: BLoC pattern para manejo de estado reactivo

---

## �️ MAPA DE RUTAS PRINCIPALES

### 🏢 Owner/Admin (Gestión del Gimnasio)
| Ruta | Función | Componente |
|------|---------|------------|
| `/owner/forge` | **Training Forge** - Creación de rutinas y programas | `TrainingForgeScreen` |
| `/owner/atlas` | **Atlas Visual** - Biblioteca de imágenes de ejercicios | `ExerciseAtlasScreen` |
| `/owner/dashboard` | Dashboard principal con métricas del gimnasio | `OwnerDashboardScreen` |
| `/owner/members` | Gestión de miembros y suscripciones | `OwnerMembersScreen` |
| `/owner/pos` | Punto de venta y pagos | `PosScreen` |
| `/owner/staff` | Gestión de entrenadores y personal | `StaffManagementScreen` |

### 👤 Cliente (Atleta)
| Ruta | Función | Componente |
|------|---------|------------|
| `/client/home` | Dashboard de entrenamiento principal | `TrainingDashboardScreen` |
| `/client/routine` | Rutinas asignadas por el gimnasio | `ClientRoutineScreen` |
| `/client/daily-workout` | Ejecución de ejercicios en tiempo real | `DailyWorkoutScreen` |
| `/client/workout-planning` | Planificación de sesiones futuras | `WorkoutPlannerScreen` |
| `/client/analytics` | Análisis de rendimiento y volumen | `WorkoutAnalyticsScreen` |
| `/client/nutrition` | Seguimiento de nutrición y macros | `NutritionTrackingScreen` |
| `/client/recovery` | Monitor de recuperación y fatiga | `RecoveryScreen` |

---

## 🛠️ STACK TECNOLÓGICO

- **Frontend**: Flutter (Multiplataforma: Web, Android, iOS, Desktop)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Arquitectura**: Clean Architecture + Domain Driven Design
- **State Management**: BLoC Pattern
- **Routing**: GoRouter
- **Inyección de Dependencias**: GetIt
- **Upload de Archivos**: file_picker (compatible con Web)

---

## � Training Forge: Detalles Técnicos

### Atlas de Ejercicios
- **Upload de Imágenes**: Soporte para PNG, JPG, GIF
- **Almacenamiento**: Uint8List en memoria (persistencia de sesión)
- **Filtros**: Por músculo primario y estado de imagen
- **Preview**: Visualización en tiempo real con metadata
- **Integración**: Las imágenes se muestran en las cards del Training Forge

### Sistema de Entidades
- **ForgeExercise**: Con soporte para imageBytes, imageUrl, animationUrl, videoUrl
- **ForgeRoutine**: Colecciones de ejercicios con configuración
- **ForgeProgram**: Planes maestros de entrenamiento
- **TrainingForgeStore**: Singleton para persistencia compartida

---

## 🏗️ ESTRUCTURA DEL PROYECTO

```
lib/src/
├── 01-domain/           # Entidades y reglas de negocio
├── 02-application/      # Casos de uso y lógica de aplicación
├── 03-infrastructure/   # Adaptadores de Firebase y configuración
├── 04-presentation/     # UI, screens y componentes
│   ├── screens/
│   │   ├── owner/
│   │   │   ├── training_forge_screen.dart
│   │   │   ├── exercise_atlas_screen.dart
│   │   │   └── training_forge_store.dart
│   │   └── client/
│   ├── theme/           # Sistema Quantum UX
│   └── widgets/         # Componentes reutilizables
└── core/               # Utilidades y configuración global
```

---

## 🚀 INSTALACIÓN Y EJECUCIÓN

### Prerrequisitos
- Flutter SDK (>= 3.0)
- Node.js (para desarrollo futuro)
- Firebase project configurado

### Pasos
1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/LATINALU/Quantum.git
   cd Quantum
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Copiar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
   - Configurar variables en `.env`

4. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome    # Para web
   flutter run             # Para dispositivo/emulador
   ```

---

## 🔐 SEGURIDAD

- **Multi-Tenancy**: Aislamiento por `gymId` en todas las consultas
- **Roles Jerárquicos**: admin > owner > employee > client
- **Códigos de Acceso**: CSPRNG para invitaciones y verificación
- **Firestore Rules**: Validación de permisos por rol y gym

---

## � PLATAFORMAS SOPORTADAS

- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Desktop** (Windows, macOS, Linux)

---

## 🤝 CONTRIBUCIÓN

1. Fork del repositorio
2. Crear feature branch (`git checkout -b feature/amazing-feature`)
3. Commit con mensaje claro (`git commit -m 'feat: add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Abrir Pull Request

---

## 📄 LICENCIA

© 2026 Quantum Team. Todos los derechos reservados.

---

*Última actualización: Febrero 2026 - Training Forge v1.0*
