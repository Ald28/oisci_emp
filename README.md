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

### Framework y Lenguaje
- **Flutter** 3.10.1
- **Dart** 3.10.1

### Dependencias Principales

#### Red y Sincronización
- `dio` ^5.9.0 - Cliente HTTP para comunicación con el backend
- `socket_io_client` ^2.0.3+1 - WebSocket para sincronización en tiempo real
- `connectivity_plus` ^7.0.0 - Detección de conectividad
- `internet_connection_checker` ^1.0.0 - Verificación de conexión a internet

#### Almacenamiento Local
- `sqflite` ^2.3.0 - Base de datos SQLite
- `shared_preferences` ^2.5.3 - Almacenamiento de preferencias
- `flutter_secure_storage` ^9.2.4 - Almacenamiento seguro de tokens

#### Funcionalidades Específicas
- `flutter_nfc_kit` ^3.6.1 - Lectura de tags NFC
- `image_picker` ^1.0.0 - Selección y captura de imágenes
- `flutter_local_notifications` ^17.0.0 - Notificaciones locales
- `workmanager` ^0.9.0+3 - Tareas en background

#### UI y Utilidades
- `fl_chart` ^0.69.0 - Gráficos y visualización de datos
- `intl` ^0.20.2 - Internacionalización y formateo
- `flutter_dotenv` ^5.1.0 - Variables de entorno

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
   # Android
   flutter run

   # iOS
   flutter run

   # Específico
   flutter run -d <device-id>
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
├── assets/                       # Recursos (imágenes, iconos)
├── test/                         # Tests
├── .env                          # Variables de entorno
├── pubspec.yaml                  # Dependencias
├── ARQUITECTURA.md               # Documentación de arquitectura
├── FLUJO_DATOS.md                # Diagramas de flujo
└── README.md                     # Este archivo
```

---

## 🚀 Uso

### Inicio de Sesión

1. Abre la aplicación
2. Ingresa tus credenciales (email y contraseña)
3. La aplicación verificará tu sesión y te redirigirá al home

### Crear un Servicio

1. Desde el menú principal, selecciona "Servicios"
2. Elige el tipo de servicio (Mantenimiento o Inspección)
3. Selecciona la sede
4. Escanea o busca el extintor mediante NFC
5. Completa el checklist correspondiente
6. Guarda el servicio

### Sincronización Manual

1. Abre el menú lateral (Drawer)
2. Selecciona "Sincronizar"
3. Elige el tipo de datos a sincronizar
4. Espera a que se complete la sincronización

---

## 🔄 Sincronización

### Sincronización Automática

La aplicación sincroniza automáticamente cuando:
- Se detecta conexión a internet
- Se completa una acción que requiere sincronización
- Cada 2 minutos cuando está online (fallback)

### Sincronización Incremental

La aplicación utiliza sincronización incremental para optimizar el uso de datos:
- Solo descarga cambios desde la última sincronización
- Utiliza timestamps (`updatedAt`) para filtrar cambios
- Reduce significativamente el consumo de ancho de banda

### Sincronización en Tiempo Real (WebSocket)

Cuando múltiples dispositivos están conectados:
- Los cambios se propagan instantáneamente (< 1 segundo)
- Similar a WhatsApp: cuando un dispositivo crea/edita algo, los demás lo ven inmediatamente
- Funciona como fallback si WebSocket falla: polling cada 2 minutos

### Modo Offline

La aplicación funciona completamente offline:
- Todos los datos se guardan localmente en SQLite
- Los cambios pendientes se agregan a una cola de sincronización
- Cuando se restablece la conexión, se sincronizan automáticamente

---

## 📚 Documentación

### Documentación Adicional

- 📄 [ARQUITECTURA.md](ARQUITECTURA.md) - Arquitectura detallada y explicación de capas

### Documentación del Código

El código está documentado con comentarios explicativos. Los archivos principales incluyen:
- Descripción de clases y métodos
- Ejemplos de uso
- Notas sobre decisiones de diseño

---

## 🧪 Desarrollo

### Ejecutar en Modo Desarrollo

```bash
flutter run --debug
```

### Ejecutar Tests

```bash
flutter test
```

### Análisis de Código

```bash
flutter analyze
```

### Generar Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Linting

El proyecto utiliza `flutter_lints` para mantener la calidad del código. Se ejecuta automáticamente en el IDE.

---

## 🔧 Troubleshooting

### Problemas Comunes

#### Error: "Cannot find module"
```bash
flutter clean
flutter pub get
```

#### Error de conexión con el backend
- Verifica que `API_BASE_URL` en `.env` sea correcta
- Asegúrate de que el backend esté ejecutándose
- Verifica la conectividad de red

#### Problemas con NFC
- Verifica que el dispositivo tenga NFC habilitado
- Asegúrate de tener los permisos necesarios
- En Android, verifica `AndroidManifest.xml`

#### Problemas de sincronización
- Verifica la conexión a internet
- Revisa los logs en la consola para errores específicos
- Intenta una sincronización manual desde el menú

---

## 🤝 Contribución

### Guías de Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código

- Sigue la arquitectura Clean Architecture
- Mantén la separación de capas (Domain, Data, Presentation)
- Escribe tests para nuevas funcionalidades
- Documenta código complejo
- Sigue las convenciones de Dart/Flutter

---

## 📝 Licencia

Este proyecto es de propiedad privada. Todos los derechos reservados.

---

## 👥 Autores

- **Equipo de Desarrollo OISCI**

---

## 🙏 Agradecimientos

- Flutter Team por el excelente framework
- Comunidad de Flutter por las librerías y recursos
- Todos los contribuidores del proyecto

---

## 📞 Soporte

Para soporte, contacta al equipo de desarrollo o abre un issue en el repositorio.

---

**Desarrollado con ❤️ usando Flutter**
