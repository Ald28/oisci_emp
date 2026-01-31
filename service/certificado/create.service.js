import { CreateCertificado } from '../../repository/certificado/crear.repository.js'
import { generarNumeroCertificado } from '../../utils/generarNumeroCertificado.js'

export const CertificadoService = {

    async createCertificado({ body, usuarioId }) {
        const numeroCertificado = await generarNumeroCertificado(body.tipo)

        return CreateCertificado.create({
            ...body,
            numeroCertificado,
            usuarioId
        })
    },

    async subirPdf({ certificadoId, archivoPdfUrl, usuarioId }) {
        return CreateCertificado.guardarPdf({
            id: certificadoId,
            archivoPdfUrl,
            usuarioId
        })
    },

    async generarReporte(servicioId) {
        const registros = await CreateCertificado.obtenerFotosPorServicio(servicioId)

        registros.sort((a, b) => {
            if (a.extintorId !== b.extintorId) {
                return a.extintorId - b.extintorId
            }
            const fechaA = a.inspeccionDetalle?.createdAt ? new Date(a.inspeccionDetalle.createdAt).getTime() : 0
            const fechaB = b.inspeccionDetalle?.createdAt ? new Date(b.inspeccionDetalle.createdAt).getTime() : 0
            return fechaA - fechaB
        })

        return registros.map(r => ({
            extintorId: r.extintorId,
            codeExtintor: r.extintor?.codeExtintor ?? null,
            serialNumberNFC: r.extintor?.serialNumberNFC ?? null,
            type: r.extintor?.type ?? null,
            location: r.extintor?.location ?? null,
            fotos: [
                r.inspeccionDetalle?.foto1Url,
                r.inspeccionDetalle?.foto2Url,
                r.inspeccionDetalle?.foto3Url
            ].filter(Boolean),
            comentarios: r.inspeccionDetalle?.observaciones ?? null,
            fechaHora: r.inspeccionDetalle?.createdAt ?? null
        }))
    }
}