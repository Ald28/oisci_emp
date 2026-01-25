-- AlterTable
ALTER TABLE "Extintor" ADD COLUMN     "brand" VARCHAR(255),
ADD COLUMN     "dateHydrostatic" VARCHAR(255),
ADD COLUMN     "dateMaintenance" VARCHAR(255),
ADD COLUMN     "model" VARCHAR(255),
ADD COLUMN     "pressure" VARCHAR(255),
ADD COLUMN     "rating" VARCHAR(255),
ADD COLUMN     "yearManufacture" VARCHAR(255);

-- AlterTable
ALTER TABLE "InspeccionDetalle" ADD COLUMN     "abrazadera" VARCHAR(255),
ADD COLUMN     "acceso" VARCHAR(255),
ADD COLUMN     "carga" VARCHAR(255),
ADD COLUMN     "cilindro" VARCHAR(255),
ADD COLUMN     "clase" VARCHAR(255),
ADD COLUMN     "fijacion" VARCHAR(255),
ADD COLUMN     "hidrostatica" VARCHAR(255),
ADD COLUMN     "manguera" VARCHAR(255),
ADD COLUMN     "manija" VARCHAR(255),
ADD COLUMN     "precinto" VARCHAR(255),
ADD COLUMN     "presion" VARCHAR(255),
ADD COLUMN     "recarga" VARCHAR(255),
ADD COLUMN     "soporte" VARCHAR(255),
ADD COLUMN     "tobera" VARCHAR(255),
ADD COLUMN     "ubicacion" VARCHAR(255),
ADD COLUMN     "uso" VARCHAR(255);
