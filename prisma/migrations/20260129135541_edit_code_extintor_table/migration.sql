/*
  Warnings:

  - You are about to drop the column `codeNFC` on the `Extintor` table. All the data in the column will be lost.
  - You are about to drop the column `serialNumber` on the `Extintor` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[codeExtintor]` on the table `Extintor` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[serialNumberNFC]` on the table `Extintor` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "Extintor_codeNFC_key";

-- AlterTable
ALTER TABLE "Extintor" DROP COLUMN "codeNFC",
DROP COLUMN "serialNumber",
ADD COLUMN     "codeExtintor" VARCHAR(45),
ADD COLUMN     "serialNumberNFC" VARCHAR(45);

-- CreateIndex
CREATE UNIQUE INDEX "Extintor_codeExtintor_key" ON "Extintor"("codeExtintor");

-- CreateIndex
CREATE UNIQUE INDEX "Extintor_serialNumberNFC_key" ON "Extintor"("serialNumberNFC");
