/*
  Warnings:

  - You are about to drop the `extintor` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "extintor" DROP CONSTRAINT "extintor_sedeId_fkey";

-- DropTable
DROP TABLE "extintor";

-- CreateTable
CREATE TABLE "Extintor" (
    "id" SERIAL NOT NULL,
    "codigoNFC" VARCHAR(45),
    "numeroSerie" VARCHAR(45),
    "tipo" VARCHAR(45),
    "capacidad" VARCHAR(45),
    "agente" VARCHAR(45),
    "numeroCilindro" VARCHAR(45),
    "ubicacion" VARCHAR(45),
    "estado" "EstadoEnum",
    "historico" VARCHAR(45),
    "fechaBaja" VARCHAR(45),
    "foto" VARCHAR(45),
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3),
    "usuarioCreador" VARCHAR(45),
    "sedeId" INTEGER NOT NULL,

    CONSTRAINT "Extintor_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Extintor" ADD CONSTRAINT "Extintor_sedeId_fkey" FOREIGN KEY ("sedeId") REFERENCES "Sede"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
