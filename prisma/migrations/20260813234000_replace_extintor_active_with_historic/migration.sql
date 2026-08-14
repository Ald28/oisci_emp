-- Normaliza el estado histórico antes de retirar la columna booleana.
-- 0 = activo/restaurado, 1 = eliminado lógicamente.
UPDATE "Extintor"
SET "historic" = CASE
    WHEN "active" = false THEN 1
    ELSE 0
END;

ALTER TABLE "Extintor"
    ALTER COLUMN "historic" SET DEFAULT 0,
    ALTER COLUMN "historic" SET NOT NULL,
    DROP COLUMN "active";
