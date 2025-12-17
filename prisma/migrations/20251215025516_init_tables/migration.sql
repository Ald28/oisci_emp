/*
  Warnings:

  - Made the column `userCode` on table `User` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "User" ALTER COLUMN "userCode" SET NOT NULL,
ALTER COLUMN "userCode" SET DATA TYPE TEXT;
