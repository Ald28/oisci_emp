import { DeleteExtintores } from "../../repository/inpeccionD/delete.repository.js";

export async function softDeleteExtintorService(id) {
  try {
    const extintor = await DeleteExtintores.softDeleteExtintor(id);
    return extintor;
  } catch (error) {
    throw new Error("Error al eliminar el extintor");
  }
}

export async function softDeleteManyExtintoresService(rawIds) {
  if (!Array.isArray(rawIds) || rawIds.length === 0) {
    throw new Error("Debe enviar un arreglo no vacío de IDs de extintores");
  }

  const ids = rawIds.map(Number);
  if (ids.some((id) => !Number.isInteger(id) || id <= 0)) {
    throw new Error("Todos los IDs deben ser enteros mayores a 0");
  }

  const uniqueIds = [...new Set(ids)];
  return DeleteExtintores.softDeleteManyExtintores(uniqueIds);
}

export async function restoreExtintorService(id) {
  try {
    const extintor = await DeleteExtintores.restoreExtintor(id);
    return extintor;
  } catch (error) {
    throw new Error("Error al restaurar el extintor");
  }
}
