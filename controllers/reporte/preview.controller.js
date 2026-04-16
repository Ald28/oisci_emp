import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { listRepository } from "../../repository/reporte/list.repository.js";
import { obtenerKeyDesdeS3Url } from "../../service/inspeccionD/storage/keyS3.js";

const s3 = new S3Client({
  region: process.env.S3_REGION,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY,
    secretAccessKey: process.env.S3_SECRET_KEY,
  },
});

export const previewPdf = async (req, res) => {
  try {
    const { id } = req.params;

    const reporte = await listRepository.getPdfByReporteId(id);

    if (!reporte) {
      return res.status(404).json({
        ok: false,
        message: "Reporte no encontrado",
      });
    }

    if (!reporte.archivoPdfUrl) {
      return res.status(404).json({
        ok: false,
        message: "El reporte no tiene PDF",
      });
    }

    const key = obtenerKeyDesdeS3Url(reporte.archivoPdfUrl);

    const command = new GetObjectCommand({
      Bucket: process.env.S3_BUCKET,
      Key: key,
    });

    const response = await s3.send(command);

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", "inline");

    if (response.Body) {
      response.Body.pipe(res);
      return;
    }

    return res.status(404).json({
      ok: false,
      message: "PDF no encontrado en S3",
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: "Error obteniendo PDF",
      error: error.message,
    });
  }
};
