-- CreateEnum
CREATE TYPE "ReporteTipo" AS ENUM ('FOTO', 'INSPECCION');

-- CreateEnum
CREATE TYPE "ReporteEmitido" AS ENUM ('SI', 'NO');

-- AlterTable
ALTER TABLE "Extintor" ALTER COLUMN "photo" SET DATA TYPE VARCHAR(255);

-- CreateTable
CREATE TABLE "Reporte" (
    "id" SERIAL NOT NULL,
    "servicioId" INTEGER NOT NULL,
    "tipo" "ReporteTipo" NOT NULL,
    "fechaEmision" TIMESTAMP(3),
    "emitido" "ReporteEmitido" NOT NULL DEFAULT 'NO',
    "frecuencia" VARCHAR(45),
    "aprobadoPorId" INTEGER,
    "archivoPdfUrl" VARCHAR(255),
    "usuarioCreadorId" INTEGER NOT NULL,
    "usuarioActualizadorId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Reporte_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Reporte_servicioId_idx" ON "Reporte"("servicioId");

-- AddForeignKey
ALTER TABLE "Reporte" ADD CONSTRAINT "Reporte_servicioId_fkey" FOREIGN KEY ("servicioId") REFERENCES "Servicio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reporte" ADD CONSTRAINT "Reporte_aprobadoPorId_fkey" FOREIGN KEY ("aprobadoPorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reporte" ADD CONSTRAINT "Reporte_usuarioCreadorId_fkey" FOREIGN KEY ("usuarioCreadorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reporte" ADD CONSTRAINT "Reporte_usuarioActualizadorId_fkey" FOREIGN KEY ("usuarioActualizadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
