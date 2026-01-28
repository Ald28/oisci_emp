/*
  Warnings:

  - The `rechargeDate` column on the `Extintor` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Extintor" DROP COLUMN "rechargeDate",
ADD COLUMN     "rechargeDate" TIMESTAMP(3);
