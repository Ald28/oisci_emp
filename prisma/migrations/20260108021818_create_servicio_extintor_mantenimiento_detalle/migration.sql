-- CreateTable
CREATE TABLE "ServicioExtintor" (
    "id" SERIAL NOT NULL,
    "servicioId" INTEGER NOT NULL,
    "extintorId" INTEGER NOT NULL,
    "estadoInicial" "StatusEnum",
    "estadoFinal" "StatusEnum",
    "completado" BOOLEAN NOT NULL DEFAULT false,
    "observaciones" VARCHAR(255),
    "usuarioCreadorId" INTEGER NOT NULL,
    "usuarioActualizadorId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ServicioExtintor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MantenimientoDetalle" (
    "id" SERIAL NOT NULL,
    "servicioExtintorId" INTEGER NOT NULL,
    "mantenimiento" BOOLEAN NOT NULL DEFAULT false,
    "recarga" BOOLEAN NOT NULL DEFAULT false,
    "agenteCarga" VARCHAR(45),
    "pruebaHidrostatica" BOOLEAN NOT NULL DEFAULT false,
    "bajaExtintor" BOOLEAN NOT NULL DEFAULT false,
    "motivoBaja" VARCHAR(255),
    "pintura" BOOLEAN NOT NULL DEFAULT false,
    "recargaCartucho" BOOLEAN NOT NULL DEFAULT false,
    "cambioPartes" BOOLEAN NOT NULL DEFAULT false,
    "usuarioCreadorId" INTEGER NOT NULL,
    "usuarioActualizadorId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MantenimientoDetalle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ServicioExtintor_servicioId_extintorId_key" ON "ServicioExtintor"("servicioId", "extintorId");

-- CreateIndex
CREATE UNIQUE INDEX "MantenimientoDetalle_servicioExtintorId_key" ON "MantenimientoDetalle"("servicioExtintorId");

-- AddForeignKey
ALTER TABLE "ServicioExtintor" ADD CONSTRAINT "ServicioExtintor_servicioId_fkey" FOREIGN KEY ("servicioId") REFERENCES "Servicio"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicioExtintor" ADD CONSTRAINT "ServicioExtintor_extintorId_fkey" FOREIGN KEY ("extintorId") REFERENCES "Extintor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicioExtintor" ADD CONSTRAINT "ServicioExtintor_usuarioCreadorId_fkey" FOREIGN KEY ("usuarioCreadorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicioExtintor" ADD CONSTRAINT "ServicioExtintor_usuarioActualizadorId_fkey" FOREIGN KEY ("usuarioActualizadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MantenimientoDetalle" ADD CONSTRAINT "MantenimientoDetalle_servicioExtintorId_fkey" FOREIGN KEY ("servicioExtintorId") REFERENCES "ServicioExtintor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MantenimientoDetalle" ADD CONSTRAINT "MantenimientoDetalle_usuarioCreadorId_fkey" FOREIGN KEY ("usuarioCreadorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MantenimientoDetalle" ADD CONSTRAINT "MantenimientoDetalle_usuarioActualizadorId_fkey" FOREIGN KEY ("usuarioActualizadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
