-- CreateEnum
CREATE TYPE "CertificadoTipo" AS ENUM ('OPER', 'HIDRO', 'BAJA');

-- CreateEnum
CREATE TYPE "CertificadoEmitido" AS ENUM ('SI', 'NO');

-- CreateTable
CREATE TABLE "ServicioReporte" (
    "id" SERIAL NOT NULL,
    "estado" "StatusEnum",
    "checklist" JSONB NOT NULL,
    "reporteId" INTEGER NOT NULL,
    "extintorId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ServicioReporte_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Certificado" (
    "id" SERIAL NOT NULL,
    "tipo" "CertificadoTipo" NOT NULL,
    "numeroCertificado" VARCHAR(45) NOT NULL,
    "fechaEmision" TIMESTAMP(3),
    "emitido" "CertificadoEmitido" NOT NULL DEFAULT 'NO',
    "frecuencia" VARCHAR(45),
    "archivoPdfUrl" VARCHAR(255),
    "clientId" INTEGER NOT NULL,
    "sedeId" INTEGER NOT NULL,
    "servicioId" INTEGER NOT NULL,
    "aprobadorId" INTEGER,
    "usuarioCreadorId" INTEGER NOT NULL,
    "usuarioActualizadorId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Certificado_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CertificadoDetalle" (
    "id" SERIAL NOT NULL,
    "estado" "StatusEnum",
    "checklist" JSONB NOT NULL,
    "certificadoId" INTEGER NOT NULL,
    "extintorId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CertificadoDetalle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ServicioReporte_reporteId_idx" ON "ServicioReporte"("reporteId");

-- CreateIndex
CREATE INDEX "ServicioReporte_extintorId_idx" ON "ServicioReporte"("extintorId");

-- CreateIndex
CREATE UNIQUE INDEX "ServicioReporte_reporteId_extintorId_key" ON "ServicioReporte"("reporteId", "extintorId");

-- CreateIndex
CREATE INDEX "Certificado_clientId_idx" ON "Certificado"("clientId");

-- CreateIndex
CREATE INDEX "Certificado_sedeId_idx" ON "Certificado"("sedeId");

-- CreateIndex
CREATE INDEX "Certificado_servicioId_idx" ON "Certificado"("servicioId");

-- CreateIndex
CREATE INDEX "Certificado_aprobadorId_idx" ON "Certificado"("aprobadorId");

-- CreateIndex
CREATE INDEX "CertificadoDetalle_certificadoId_idx" ON "CertificadoDetalle"("certificadoId");

-- CreateIndex
CREATE INDEX "CertificadoDetalle_extintorId_idx" ON "CertificadoDetalle"("extintorId");

-- CreateIndex
CREATE UNIQUE INDEX "CertificadoDetalle_certificadoId_extintorId_key" ON "CertificadoDetalle"("certificadoId", "extintorId");

-- AddForeignKey
ALTER TABLE "ServicioReporte" ADD CONSTRAINT "ServicioReporte_reporteId_fkey" FOREIGN KEY ("reporteId") REFERENCES "Reporte"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicioReporte" ADD CONSTRAINT "ServicioReporte_extintorId_fkey" FOREIGN KEY ("extintorId") REFERENCES "Extintor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "Client"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_sedeId_fkey" FOREIGN KEY ("sedeId") REFERENCES "Sede"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_servicioId_fkey" FOREIGN KEY ("servicioId") REFERENCES "Servicio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_aprobadorId_fkey" FOREIGN KEY ("aprobadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_usuarioCreadorId_fkey" FOREIGN KEY ("usuarioCreadorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Certificado" ADD CONSTRAINT "Certificado_usuarioActualizadorId_fkey" FOREIGN KEY ("usuarioActualizadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CertificadoDetalle" ADD CONSTRAINT "CertificadoDetalle_certificadoId_fkey" FOREIGN KEY ("certificadoId") REFERENCES "Certificado"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CertificadoDetalle" ADD CONSTRAINT "CertificadoDetalle_extintorId_fkey" FOREIGN KEY ("extintorId") REFERENCES "Extintor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
