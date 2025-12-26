/*
  Warnings:

  - You are about to drop the column `agente` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `capacidad` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `codigoNFC` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `estado` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `fechaBaja` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `foto` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `historico` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `numeroCilindro` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `numeroSerie` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `tipo` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `ubicacion` on the `Extintor` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[codeNFC]` on the table `Extintor` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "StatusEnum" AS ENUM ('OPERATIVO', 'INOPERATIVO');

-- DropIndex
DROP INDEX "Extintor_codigoNFC_key";

-- AlterTable
ALTER TABLE "Extintor" DROP COLUMN "agente",
DROP COLUMN "capacidad",
DROP COLUMN "codigoNFC",
DROP COLUMN "estado",
DROP COLUMN "fechaBaja",
DROP COLUMN "foto",
DROP COLUMN "historico",
DROP COLUMN "numeroCilindro",
DROP COLUMN "numeroSerie",
DROP COLUMN "tipo",
DROP COLUMN "ubicacion",
ADD COLUMN     "agent" VARCHAR(45),
ADD COLUMN     "capacity" VARCHAR(45),
ADD COLUMN     "codeNFC" VARCHAR(45),
ADD COLUMN     "cylinderNumber" VARCHAR(45),
ADD COLUMN     "dateLow" VARCHAR(45),
ADD COLUMN     "historic" VARCHAR(45),
ADD COLUMN     "location" VARCHAR(45),
ADD COLUMN     "photo" VARCHAR(45),
ADD COLUMN     "serialNumber" VARCHAR(45),
ADD COLUMN     "status" "StatusEnum",
ADD COLUMN     "type" VARCHAR(45);

-- DropEnum
DROP TYPE "EstadoEnum";

-- CreateIndex
CREATE UNIQUE INDEX "Extintor_codeNFC_key" ON "Extintor"("codeNFC");
