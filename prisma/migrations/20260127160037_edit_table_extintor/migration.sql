/*
  Warnings:

  - The `dateHydrostatic` column on the `Extintor` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `dateMaintenance` column on the `Extintor` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Extintor" DROP COLUMN "dateHydrostatic",
ADD COLUMN     "dateHydrostatic" TIMESTAMP(3),
DROP COLUMN "dateMaintenance",
ADD COLUMN     "dateMaintenance" TIMESTAMP(3);
