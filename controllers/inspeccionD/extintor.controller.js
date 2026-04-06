import {
  getExtintores,
  getExtintoresPDF,
} from "../../service/inspeccionD/extintor.service.js";

export const listExtintores = async (req, res) => {
  try {
    const extintores = await getExtintores();

    return res.status(200).json({
      ok: true,
      extintores,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      ok: false,
      message: "Error al obtener extintores",
    });
  }
};

export const getExtintor = async (req, res) => {
  try {
    const extintores = await getExtintoresPDF();

    return res.status(200).json({
      ok: true,
      extintores,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      ok: false,
      message: "Error generando data PDF",
    });
  }
};

export default {
  listExtintores,
  getExtintor,
};
