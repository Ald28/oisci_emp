import {
  getExtintores,
  getExtintoresPDF,
  getExtintoresExcel,
  getExtintoresPdfBuffer,
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

export const exportExtintoresExcel = async (req, res) => {
  try {
    const extintorId = req.query.extintorId ? Number(req.query.extintorId) : undefined;
    const serviceId = req.query.serviceId ? Number(req.query.serviceId) : undefined;
    const format = String(req.query.format || "excel").toLowerCase();

    if (format === "pdf") {
      const buffer = await getExtintoresPdfBuffer(extintorId, serviceId);

      res.setHeader("Content-Type", "application/pdf");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="extintores-${new Date().toISOString().slice(0, 10)}.pdf"`,
      );

      return res.status(200).send(buffer);
    }

    const result = await getExtintoresExcel(extintorId, serviceId);

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${result.fileName}"`,
    );

    return res.status(200).send(result.buffer);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      ok: false,
      message: "Error generando archivo",
    });
  }
};

export default {
  listExtintores,
  getExtintor,
  exportExtintoresExcel,
};
