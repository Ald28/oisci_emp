# Backend OISCI

## 📋 Descripción
Backend para la gestión de servicios de mantenimiento e inspección mediante escáner NFC.  
Permite administrar checklists de servicios, realizar inspecciones actualizando el estado de los extintores y visualizar estadísticas por cliente sobre el estado de cada extintor.

---

## 🛠️ Tecnologías
- Node.js
- Express
- Prisma ORM
- PostgreSQL / MySQL / SQLite
- JWT (Autenticación)
- Swagger (Documentación API)
- Docker

---

## ✅ Requisitos
- Node.js >= 18
- npm / pnpm / yarn
- Base de datos configurada

---

## 🚀 Instalación

### Instalar dependencias
npm install

---

### 🗄️ Migraciones de Base de Datos (Prisma)

#### 🧪 Entorno local (desarrollo)

1. Asegúrate de que `DATABASE_URL` apunte a tu base de datos local.
2. Ejecuta las migraciones:

```bash
npx prisma migrate dev --name init

Esto:

Crea las tablas
...
Genera la carpeta prisma/migrations

Aplica los cambios a la base de datos local

(Opcional) Ejecutar seed de datos:

```bash
npx prisma db seed

#### 🚀 Entorno de producción

⚠️ Nunca ejecutar prisma migrate dev en producción

Configura DATABASE_URL apuntando a la base de datos de producción.

Aplica las migraciones ya existentes:

```bash
npx prisma migrate deploy

(Opcional) Ejecutar seed inicial:

npx prisma db seed

```md
> Las migraciones deben crearse únicamente en entorno local y luego desplegarse en producción usando `prisma migrate deploy`.

---

### Configurar variables de entorno

cp .env.example .env

---

### Ejemplo de .env:

API_URL=http://localhost:8000

DATABASE_URL="postgresql://postgres:contraseña@localhost:5432/nombre_base_de_datos"

JWT_EXPIRES=7d
JWT_REFRESH_SECRET=refreshsupersecret
JWT_SECRET=supersecret

PORT=8000

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

---

### Ejecutar migraciones:

npx prisma migrate dev

---

### Iniciar el proyecto:

npm run dev

---

### 📚 Documentación API

Swagger disponible en:
http://localhost:8000/api-docs

---

### Scripts
- npm run dev       # Desarrollo
- npm start         # Producción
- npx prisma studio # Ver base de datos

---

### Estructura
```plaintext
OISCI_EMP
├── controllers
│   ├── client
│   ├── inspeccionD
│   ├── mantenimientoD
│   ├── nfc
│   ├── sede
│   └── services
│
├── database
│   ├── seed
│   │   ├── clients.seed.mjs
│   │   ├── extintores.seed.mjs
│   │   ├── sedes.seed.mjs
│   │   ├── servicios.seed.mjs
│   │   ├── users.seed.mjs
│   │   ├── roles.seed.mjs
│   │   └── utils.mjs
│   ├── client.mjs
│   └── index.mjs
│
├── generated
├── middleware
│   ├── auth.middleware.js
│   └── upload.middleware.js
│
├── prisma
│   ├── migrations
│   └── schema.prisma
│
├── repository
│   ├── client
│   ├── inspeccionD
│   ├── mantenimientoD
│   ├── nfc
│   ├── sede
│   └── services
│
├── routes
│   ├── client
│   ├── inspeccionD
│   ├── mantenimientoD
│   ├── nfc
│   ├── sede
│   └── services
│
├── service
│   ├── client
│   ├── inspeccionD
│   │   ├── storage
│   │   │   ├── cloudinary.storage.js
│   │   │   ├── index.js
│   │   │   └── storage.interface.js
│   │   └── inspeccionDetalle.service.js
│   ├── mantenimientoD
│   ├── nfc
│   ├── sede
│   └── services
│
├── src
│   ├── config
│   ├── app.js
│   └── server.js
│
├── .env
├── .env.example
├── .gitignore
├── docker-compose.yml
└── Dockerfile