import {
  softDeleteExtintorService,
  softDeleteManyExtintoresService,
  restoreExtintorService,
} from "../../service/inspeccionD/delete.service.js";

export async function softDeleteExtintorController(req, res) {
  try {
    const id = Number(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({
        ok: false,
        message: "ID inválido",
      });
    }

    const extintor = await softDeleteExtintorService(id);

    return res.status(200).json({
      ok: true,
      data: extintor,
    });
  } catch (error) {
    return res.status(404).json({
      ok: false,
      message: error.message,
    });
  }
}

export async function softDeleteManyExtintoresController(req, res) {
  try {
    // El formato principal es [1, 2, 3]. También se admite { ids: [...] }.
    const rawIds = Array.isArray(req.body) ? req.body : req.body?.ids;
    const result = await softDeleteManyExtintoresService(rawIds);

    return res.status(200).json({
      ok: true,
      message: "Extintores eliminados lógicamente",
      data: result,
    });
  } catch (error) {
    return res.status(400).json({
      ok: false,
      message: error.message,
    });
  }
}

export async function restoreExtintorController(req, res) {
  try {
    const id = Number(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({
        ok: false,
        message: "ID inválido",
      });
    }

    const extintor = await restoreExtintorService(id);

    return res.status(200).json({
      ok: true,
      data: extintor,
    });
  } catch (error) {
    return res.status(404).json({
      ok: false,
      message: error.message,
    });
  }
}
