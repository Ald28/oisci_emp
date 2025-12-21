-- CreateTable
CREATE TABLE "Sede" (
    "id" SERIAL NOT NULL,
    "nombre_sede" TEXT NOT NULL,
    "direccion" TEXT NOT NULL,
    "gestor_nombre" TEXT NOT NULL,
    "gestor_telefono" TEXT NOT NULL,
    "gestor_correo" TEXT NOT NULL,
    "cuidad" TEXT NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "clientId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Sede_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Sede" ADD CONSTRAINT "Sede_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
