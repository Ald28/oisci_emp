import { DeleteExtintores } from "../../repository/inpeccionD/delete.repository.js";

export async function softDeleteExtintorService(id) {
  try {
    const extintor = await DeleteExtintores.softDeleteExtintor(id);
    return extintor;
  } catch (error) {
    throw new Error("Error al eliminar el extintor");
  }
}

export async function restoreExtintorService(id) {
  try {
    const extintor = await DeleteExtintores.restoreExtintor(id);
    return extintor;
  } catch (error) {
    throw new Error("Error al restaurar el extintor");
  }
}
