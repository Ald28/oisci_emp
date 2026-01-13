-- AlterTable
ALTER TABLE "ServicioExtintor" ADD COLUMN     "codeServ" TEXT NOT NULL DEFAULT '';

-- CreateTable
CREATE TABLE "InspeccionDetalle" (
    "id" SERIAL NOT NULL,
    "servicioExtintorId" INTEGER NOT NULL,
    "foto1Url" VARCHAR(45),
    "foto2Url" VARCHAR(45),
    "foto3Url" VARCHAR(45),
    "visibilidad" VARCHAR(45),
    "visualizacion" VARCHAR(45),
    "accesibilidad" VARCHAR(45),
    "altura" VARCHAR(45),
    "situacion" VARCHAR(45),
    "conservacion" VARCHAR(45),
    "inscripciones" VARCHAR(45),
    "recorrido" VARCHAR(45),
    "peso" VARCHAR(45),
    "observaciones" VARCHAR(255),
    "usuarioCreadorId" INTEGER NOT NULL,
    "usuarioActualizadorId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InspeccionDetalle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "InspeccionDetalle_servicioExtintorId_key" ON "InspeccionDetalle"("servicioExtintorId");

-- AddForeignKey
ALTER TABLE "InspeccionDetalle" ADD CONSTRAINT "InspeccionDetalle_servicioExtintorId_fkey" FOREIGN KEY ("servicioExtintorId") REFERENCES "ServicioExtintor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InspeccionDetalle" ADD CONSTRAINT "InspeccionDetalle_usuarioCreadorId_fkey" FOREIGN KEY ("usuarioCreadorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InspeccionDetalle" ADD CONSTRAINT "InspeccionDetalle_usuarioActualizadorId_fkey" FOREIGN KEY ("usuarioActualizadorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
