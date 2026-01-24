# 📱 Arquitectura de la Aplicación Móvil Flutter

## 🎯 Visión General

Esta aplicación Flutter utiliza **Clean Architecture** con separación en 3 capas principales:
- **Domain** (Lógica de negocio pura)
- **Data** (Fuentes de datos: HTTP y SQLite)
- **Presentation** (Interfaz de usuario)

---

## 📂 Estructura de Directorios

```
oisci_fe/lib/
├── main.dart                    # 🚀 PUNTO DE ENTRADA
├── app.dart                     # ⚙️ CONFIGURACIÓN DE LA APP
│
├── core/                        # 🔧 INFRAESTRUCTURA COMPARTIDA
│   ├── auth/                    # Autenticación y sesión
│   ├── database/                 # SQLite (app_database.dart)
│   ├── network/                  # Cliente HTTP (Dio)
│   ├── nfc/                      # Servicio NFC
│   ├── notifications/            # Notificaciones push
│   ├── sync/                     # Sincronización offline/online
│   ├── websocket/                # WebSocket para tiempo real
│   └── widgets/                  # Widgets reutilizables
│
└── features/                     # 🎨 MÓDULOS DE FUNCIONALIDAD
    ├── services/                 # Módulo de Servicios (ejemplo completo)
    │   ├── data/                 # Capa de Datos
    │   │   ├── datasources/      # Fuentes de datos (HTTP y Local)
    │   │   ├── models/           # Modelos (mapean JSON/SQLite)
    │   │   └── repositories/    # Implementación de repositorios
    │   ├── domain/               # Capa de Dominio
    │   │   ├── entities/         # Entidades (objetos de negocio)
    │   │   ├── repositories/    # Contratos/interfaces
    │   │   └── usecases/        # Casos de uso (lógica de negocio)
    │   └── presentation/         # Capa de Presentación
    │       ├── pages/            # Pantallas (páginas completas)
    │       └── widgets/          # Widgets específicos del módulo
    ├── users/                     # Módulo de Usuarios
    ├── home/                      # Módulo de Home
    └── client_statistics/         # Módulo de Estadísticas
```

---

## 🔄 Flujo Secuencial

### **1. main.dart** → Punto de Entrada

**Función:**
- Inicializa Flutter (`WidgetsFlutterBinding.ensureInitialized()`)
- Carga variables de entorno (`.env`)
- Inicializa SQLite
- Inicializa notificaciones
- Ejecuta `runApp(App())` → Lanza la aplicación

**Flujo:**
```
main() → Carga .env → Inicializa DB → Inicializa Notificaciones → runApp(App())
```

---

### **2. app.dart** → Configuración de la App

**Función:**
- Configura `MaterialApp` (tema, idioma, navegación)
- Verifica sesión del usuario
- Decide si mostrar `LoginPage` o `HomePage`
- Inicia servicios de sincronización en background

**Flujo:**
```
App() → Verifica sesión → Si hay token → HomePage | Si no → LoginPage
       → Inicia ConnectivitySyncService (monitorea internet)
```

---

### **3. Presentation Layer** → Interfaz de Usuario

**Ejemplo:** `service_register_page.dart`

**Función:**
- Muestra la UI al usuario
- Captura interacciones (botones, formularios)
- Llama a **UseCases** para ejecutar acciones
- Muestra resultados/errores

**Flujo:**
```
Page (UI) → Usuario interactúa → Llama UseCase → Espera resultado → Muestra en UI
```

**Código ejemplo:**
```dart
// En service_register_page.dart
late final CreateExtinguisherUseCase _createUseCase = 
    CreateExtinguisherUseCase(ExtinguisherRepositoryImpl());

// Cuando el usuario presiona "Guardar"
await _createUseCase.call(...);  // ← Llama al UseCase
```

---

### **4. Domain Layer** → Lógica de Negocio

#### **4.1. Entities** (Entidades)

**Función:**
- Define la estructura de datos del negocio
- **NO** tiene dependencias de frameworks
- Representa objetos puros del dominio

**Ejemplo:** `service_entity.dart`
```dart
class ServiceEntity {
  final int id;
  final String type;
  final DateTime dateStart;
  // ... propiedades puras
}
```

---

#### **4.2. Repositories (Interfaces)** → Contratos

**Función:**
- Define **QUÉ** se puede hacer (métodos abstractos)
- **NO** define **CÓMO** se hace (eso lo hace la implementación)
- Es un contrato que debe cumplir la capa Data

**Ejemplo:** `service_repository.dart`
```dart
abstract class ServiceRepository {
  Future<ServiceEntity> createService({...});
  Future<ServiceEntity?> getServiceById(int id);
  // ... métodos abstractos
}
```

---

#### **4.3. UseCases** → Casos de Uso

**Función:**
- Contiene la **lógica de negocio** específica
- Usa el **Repository** para obtener/guardar datos
- Es independiente de la UI y de las fuentes de datos

**Ejemplo:** `create_service_usecase.dart`
```dart
class CreateServiceUseCase {
  final ServiceRepository repository;  // ← Usa el contrato
  
  Future<ServiceEntity> call({...}) async {
    return await repository.createService(...);  // ← Delega al repository
  }
}
```

**Flujo:**
```
UseCase → Llama Repository → Repository devuelve Entity → UseCase retorna Entity
```

---

### **5. Data Layer** → Fuentes de Datos

#### **5.1. Models** → Modelos de Datos

**Función:**
- Extiende las **Entities** del Domain
- Agrega métodos `fromJson()` y `toJson()` para serialización
- Mapea datos de JSON (HTTP) o SQLite a objetos

**Ejemplo:** `service_model.dart`
```dart
class ServiceModel extends ServiceEntity {  // ← Extiende Entity
  ServiceModel({...}) : super(...);
  
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Convierte JSON → ServiceModel
  }
  
  Map<String, dynamic> toJson() {
    // Convierte ServiceModel → JSON
  }
}
```

**Flujo:**
```
JSON/SQLite → fromJson() → ServiceModel → Se usa como ServiceEntity
```

---

#### **5.2. DataSources** → Fuentes de Datos

**Función:**
- **HttpDataSource:** Hace peticiones HTTP al backend
- **LocalDataSource:** Guarda/lee de SQLite
- Convierte JSON/SQLite a **Models**

**Ejemplo:** `http_service_datasource.dart`
```dart
class HttpServiceDataSource {
  final Dio _dio = DioClient().dio;  // ← Cliente HTTP
  
  Future<ServiceModel> createService(Map<String, dynamic> data) async {
    final response = await _dio.post('/services/create', data: data);
    // Convierte respuesta JSON → ServiceModel
    return ServiceModel.fromJson(response.data);
  }
}
```

**Ejemplo:** `local_service_datasource.dart`
```dart
class LocalServiceDataSource {
  Future<ServiceModel> createService({...}) async {
    final db = await AppDatabase.database;  // ← SQLite
    await db.insert('servicio', {...});
    // Convierte SQLite → ServiceModel
    return ServiceModel(...);
  }
}
```

**Flujo:**
```
HttpDataSource: HTTP Request → JSON → ServiceModel
LocalDataSource: SQLite Query → Map → ServiceModel
```

---

#### **5.3. Repository Implementation** → Implementación del Repository

**Función:**
- **Implementa** el contrato del `ServiceRepository` (Domain)
- Decide si usar **HttpDataSource** o **LocalDataSource** según conectividad
- Convierte **Models** a **Entities** (retorna Entities al Domain)

**Ejemplo:** `service_repository_impl.dart`
```dart
class ServiceRepositoryImpl implements ServiceRepository {
  final LocalServiceDataSource _localDataSource;
  final HttpServiceDataSource _httpDataSource;
  
  @override
  Future<ServiceEntity> createService({...}) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    
    if (hasInternet) {
      try {
        // Intentar crear en servidor
        final service = await _httpDataSource.createService(data);
        // Guardar también localmente
        await _localDataSource.saveService(service);
        return service;  // ← Retorna Entity
      } catch (e) {
        // Si falla, guardar solo localmente
        return await _localDataSource.createService(...);
      }
    } else {
      // Sin internet, guardar solo localmente
      return await _localDataSource.createService(...);
    }
  }
}
```

**Flujo:**
```
RepositoryImpl → Verifica internet → HttpDataSource O LocalDataSource
              → Convierte Model → Entity → Retorna Entity
```

---

## 🔄 Flujo Completo de un Ejemplo: Crear Servicio

### **Secuencia de Ejecución:**

```
1. Usuario presiona botón "Crear Servicio" en ServiceRegisterPage
   ↓
2. ServiceRegisterPage llama: CreateServiceUseCase.call(...)
   ↓
3. CreateServiceUseCase llama: ServiceRepository.createService(...)
   ↓
4. ServiceRepositoryImpl (implementación) verifica internet:
   ├─ Si hay internet → HttpServiceDataSource.createService()
   │                    → POST /services/create
   │                    → Backend responde JSON
   │                    → ServiceModel.fromJson(json)
   │                    → Guarda también en LocalDataSource
   │
   └─ Si no hay internet → LocalServiceDataSource.createService()
                         → INSERT INTO servicio (SQLite)
                         → Agrega a sync_queue (para sincronizar después)
   ↓
5. ServiceRepositoryImpl retorna ServiceEntity
   ↓
6. CreateServiceUseCase retorna ServiceEntity
   ↓
7. ServiceRegisterPage recibe ServiceEntity
   ↓
8. ServiceRegisterPage muestra mensaje de éxito y navega a siguiente pantalla
```

---

## 🔧 Core - Infraestructura Compartida

### **core/database/app_database.dart**
- Gestiona SQLite
- Crea tablas y migraciones
- Singleton para acceso global

### **core/network/dio_client.dart**
- Cliente HTTP (Dio)
- Configuración base (URL, headers, interceptores)

### **core/auth/auth_service.dart**
- Guarda/carga sesión del usuario
- Maneja tokens (accessToken, refreshToken)

### **core/sync/**
- **connectivity_sync_service.dart:** Monitorea internet y sincroniza automáticamente
- **incremental_sync_service.dart:** Sincronización incremental (solo cambios)
- **service_sync_service.dart:** Sincroniza servicios pendientes
- **extinguisher_sync_service.dart:** Sincroniza extintores pendientes

### **core/websocket/realtime_sync_service.dart**
- Conexión WebSocket para sincronización en tiempo real
- Recibe notificaciones cuando otros dispositivos hacen cambios

---

## 📊 Principios de Clean Architecture

### **1. Dependencias Unidireccionales:**
```
Presentation → Domain ← Data
```
- **Presentation** depende de **Domain**
- **Data** depende de **Domain**
- **Domain** NO depende de nadie (es puro)

### **2. Inversión de Dependencias:**
- **Domain** define interfaces (Repository)
- **Data** implementa esas interfaces
- **Presentation** usa las interfaces (no conoce la implementación)

### **3. Separación de Responsabilidades:**
- **Domain:** Lógica de negocio pura
- **Data:** Acceso a datos (HTTP, SQLite)
- **Presentation:** UI y interacción con usuario

---

## 🎓 Resumen Ejecutivo

**Flujo de desarrollo:**

1. **Entity** (Domain) → Define estructura de datos
2. **Repository Interface** (Domain) → Define qué se puede hacer
3. **Model** (Data) → Extiende Entity, agrega serialización
4. **DataSource** (Data) → Implementa acceso HTTP/SQLite
5. **RepositoryImpl** (Data) → Implementa Repository usando DataSources
6. **UseCase** (Domain) → Lógica de negocio usando Repository
7. **Page** (Presentation) → UI que llama UseCases

**Cada capa usa la anterior, pero Domain es independiente.**

---

## 🚀 Ventajas de esta Arquitectura

✅ **Testeable:** Cada capa se puede testear independientemente  
✅ **Mantenible:** Cambios en una capa no afectan otras  
✅ **Escalable:** Fácil agregar nuevas features  
✅ **Offline-First:** Data layer maneja HTTP y SQLite automáticamente  
✅ **Reutilizable:** UseCases se pueden usar desde diferentes Pages  
