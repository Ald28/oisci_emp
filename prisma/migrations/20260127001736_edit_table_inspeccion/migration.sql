/*
  Warnings:

  - You are about to drop the column `acceso` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `altura` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `cilindro` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `clase` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `conservacion` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `fijacion` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `hidrostatica` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `inscripciones` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `manija` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `peso` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `precinto` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `recorrido` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `situacion` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `tobera` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `uso` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `visibilidad` on the `InspeccionDetalle` table. All the data in the column will be lost.
  - You are about to drop the column `visualizacion` on the `InspeccionDetalle` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Extintor" ADD COLUMN     "rechargeDate" VARCHAR(255);

-- AlterTable
ALTER TABLE "InspeccionDetalle" DROP COLUMN "acceso",
DROP COLUMN "altura",
DROP COLUMN "cilindro",
DROP COLUMN "clase",
DROP COLUMN "conservacion",
DROP COLUMN "fijacion",
DROP COLUMN "hidrostatica",
DROP COLUMN "inscripciones",
DROP COLUMN "manija",
DROP COLUMN "peso",
DROP COLUMN "precinto",
DROP COLUMN "recorrido",
DROP COLUMN "situacion",
DROP COLUMN "tobera",
DROP COLUMN "uso",
DROP COLUMN "visibilidad",
DROP COLUMN "visualizacion",
ADD COLUMN     "activacion" VARCHAR(255),
ADD COLUMN     "boquilla" VARCHAR(255),
ADD COLUMN     "certificacion" VARCHAR(255),
ADD COLUMN     "clasificacion" VARCHAR(255),
ADD COLUMN     "estado" VARCHAR(255),
ADD COLUMN     "instalacion" VARCHAR(255),
ADD COLUMN     "instrucciones" VARCHAR(255),
ADD COLUMN     "seguridad" VARCHAR(255),
ALTER COLUMN "accesibilidad" SET DATA TYPE VARCHAR(255);
