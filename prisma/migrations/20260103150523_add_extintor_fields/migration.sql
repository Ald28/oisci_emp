/*
  Warnings:

  - The `historic` column on the `Extintor` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `dateLow` column on the `Extintor` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - Made the column `createdAt` on table `Extintor` required. This step will fail if there are existing NULL values in that column.
  - Made the column `updatedAt` on table `Extintor` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "Extintor" DROP COLUMN "historic",
ADD COLUMN     "historic" INTEGER,
DROP COLUMN "dateLow",
ADD COLUMN     "dateLow" TIMESTAMP(3),
ALTER COLUMN "createdAt" SET NOT NULL,
ALTER COLUMN "updatedAt" SET NOT NULL;
