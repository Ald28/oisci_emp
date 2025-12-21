/*
  Warnings:

  - You are about to drop the column `activo` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `cuidad` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `direccion` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `gestor_correo` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `gestor_nombre` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `gestor_telefono` on the `Sede` table. All the data in the column will be lost.
  - You are about to drop the column `nombre_sede` on the `Sede` table. All the data in the column will be lost.
  - Added the required column `address` to the `Sede` table without a default value. This is not possible if the table is not empty.
  - Added the required column `city` to the `Sede` table without a default value. This is not possible if the table is not empty.
  - Added the required column `manager_email` to the `Sede` table without a default value. This is not possible if the table is not empty.
  - Added the required column `manager_name` to the `Sede` table without a default value. This is not possible if the table is not empty.
  - Added the required column `manager_phone` to the `Sede` table without a default value. This is not possible if the table is not empty.
  - Added the required column `name_sede` to the `Sede` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Sede" DROP COLUMN "activo",
DROP COLUMN "cuidad",
DROP COLUMN "direccion",
DROP COLUMN "gestor_correo",
DROP COLUMN "gestor_nombre",
DROP COLUMN "gestor_telefono",
DROP COLUMN "nombre_sede",
ADD COLUMN     "active" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "address" TEXT NOT NULL,
ADD COLUMN     "city" TEXT NOT NULL,
ADD COLUMN     "manager_email" TEXT NOT NULL,
ADD COLUMN     "manager_name" TEXT NOT NULL,
ADD COLUMN     "manager_phone" TEXT NOT NULL,
ADD COLUMN     "name_sede" TEXT NOT NULL;
