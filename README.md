# 🔥 OISCI - Aplicación Móvil de Gestión de Extintores

[![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10.1-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

Aplicación móvil Flutter para la gestión integral de servicios de mantenimiento e inspección de extintores mediante tecnología NFC. Diseñada con arquitectura **offline-first** y sincronización bidireccional en tiempo real.

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Uso](#-uso)
- [Sincronización](#-sincronización)
- [Documentación](#-documentación)
- [Desarrollo](#-desarrollo)
- [Contribución](#-contribución)

---

## ✨ Características

### 🔐 Autenticación y Seguridad
- ✅ Autenticación JWT con tokens de acceso y refresh
- ✅ Almacenamiento seguro de credenciales con `flutter_secure_storage`
- ✅ Sesión persistente con soporte offline

### 🔄 Sincronización
- ✅ **Offline-First:** Funciona completamente sin conexión a internet
- ✅ **Sincronización Automática:** Sincroniza automáticamente cuando hay conexión
- ✅ **Sincronización Incremental:** Solo descarga cambios desde la última sincronización
- ✅ **Tiempo Real:** WebSocket para sincronización instantánea entre dispositivos
- ✅ **Cola de Sincronización:** Guarda cambios pendientes para sincronizar después

### 🎨 Interfaz de Usuario
- ✅ Material Design 3
- ✅ Soporte multi-idioma (Español/Inglés)
- ✅ Modo oscuro/claro
- ✅ Navegación intuitiva con Drawer
- ✅ Widgets reutilizables y personalizados

---

## 🛠️ Tecnologías

- **Flutter** 3.10.1 / **Dart** 3.10.1
- **Red:** `dio`, `socket_io_client`, `connectivity_plus`
- **Almacenamiento:** `sqflite`, `flutter_secure_storage`, `shared_preferences`
- **Funcionalidades:** `flutter_nfc_kit`, `image_picker`, `flutter_local_notifications`
- **UI:** `fl_chart`, `intl`, `flutter_dotenv`

---

## 🏗️ Arquitectura

La aplicación utiliza **Clean Architecture** con separación en 3 capas principales:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Pages, Widgets)                   │
└──────────────────┬──────────────────────┘
                   │ usa
                   ▼
┌─────────────────────────────────────────┐
│           DOMAIN LAYER                  │
│  (Entities, UseCases, Repository)       │
│  ← Lógica de negocio pura               │
└──────────────────┬──────────────────────┘
                   │ implementa
                   ▼
┌─────────────────────────────────────────┐
│            DATA LAYER                   │
│  (Models, DataSources, RepositoryImpl)  │
│  (HTTP, SQLite)                         │
└─────────────────────────────────────────┘
```

### Principios
- ✅ **Dependencias Unidireccionales:** `Presentation → Domain ← Data`
- ✅ **Inversión de Dependencias:** Domain define interfaces, Data las implementa
- ✅ **Separación de Responsabilidades:** Cada capa tiene una responsabilidad única

Para más detalles sobre la arquitectura, consulta:
- 📄 [ARQUITECTURA.md](ARQUITECTURA.md) - Explicación detallada de la arquitectura

---

## 📦 Instalación

### Requisitos Previos

- Flutter SDK >= 3.10.1
- Dart SDK >= 3.10.1
- Android Studio / Xcode (para desarrollo móvil)
- Git

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd oisci/oisci_fe
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**
   ```bash
   cp .env.example .env
   # Editar .env con tus configuraciones
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

---

## ⚙️ Configuración

### Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
# Backend API
API_BASE_URL=http://localhost:8000
```

---

## 📂 Estructura del Proyecto

```
oisci_fe/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   ├── app.dart                  # Configuración de la app
│   │
│   ├── core/                     # Infraestructura compartida
│   │   ├── auth/                 # Autenticación
│   │   ├── database/             # SQLite
│   │   ├── network/              # Cliente HTTP (Dio)
│   │   ├── nfc/                  # Servicio NFC
│   │   ├── notifications/        # Notificaciones
│   │   ├── sync/                 # Sincronización
│   │   ├── websocket/            # WebSocket
│   │   └── widgets/              # Widgets reutilizables
│   │
│   └── features/                 # Módulos de funcionalidad
│       ├── services/             # Gestión de servicios
│       │   ├── data/              # Capa de datos
│       │   ├── domain/           # Capa de dominio
│       │   └── presentation/      # Capa de presentación
│       ├── users/                 # Gestión de usuarios
│       ├── home/                  # Página principal
│       └── client_statistics/     # Estadísticas
│
├── assets/                       # Recursos
├── test/                          # Tests
├── .env                          # Variables de entorno
├── pubspec.yaml                  # Dependencias
├── ARQUITECTURA.md               # Documentación de arquitectura
└── README.md                     # Este archivo
```

---

## 🚀 Uso

La aplicación permite gestionar servicios de mantenimiento e inspección de extintores mediante NFC. Los datos se sincronizan automáticamente cuando hay conexión a internet, y funcionan completamente offline cuando no hay conexión.

---

## 🔄 Sincronización

La aplicación utiliza sincronización **offline-first** con las siguientes características:

- **Automática:** Se sincroniza cuando hay conexión a internet
- **Incremental:** Solo descarga cambios desde la última sincronización
- **Tiempo Real:** WebSocket para sincronización instantánea entre dispositivos (< 1 segundo)
- **Offline:** Funciona completamente sin conexión, guardando cambios en cola para sincronizar después

---

## 📚 Documentación

- 📄 [ARQUITECTURA.md](ARQUITECTURA.md) - Arquitectura detallada y explicación de capas

El código está documentado con comentarios explicativos en los archivos principales.

---

## 🧪 Desarrollo

```bash
# Desarrollo
flutter run --debug

# Tests
flutter test

# Análisis
flutter analyze

# Build
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android Bundle
flutter build ios --release        # iOS
```

El proyecto utiliza `flutter_lints` para mantener la calidad del código.

---

## 🔧 Troubleshooting

**Error: "Cannot find module"**
```bash
flutter clean && flutter pub get
```

**Error de conexión:** Verifica `API_BASE_URL` en `.env` y que el backend esté ejecutándose.

**Problemas con NFC:** Verifica que el dispositivo tenga NFC habilitado y los permisos necesarios.

**Problemas de sincronización:** Verifica la conexión a internet y revisa los logs en la consola.

---

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Abre un Pull Request

**Estándares:** Sigue Clean Architecture, mantén la separación de capas, escribe tests y documenta código complejo.

---

## 📝 Licencia

Este proyecto es de propiedad privada. Todos los derechos reservados.

---

**Desarrollado con ❤️ usando Flutter**
