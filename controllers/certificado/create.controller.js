import { CertificadoService } from '../../service/certificado/create.service.js'

export const CertificadoController = {

    async create(req, res) {
        try {
            const usuarioId = req.user.sub
            console.log('Usuario ID:', usuarioId);
            console.log('USER:', req.user)

            const certificado = await CertificadoService.createCertificado({
                body: req.body,
                usuarioId
            })

            res.status(201).json({
                ok: true,
                certificado
            })
        } catch (error) {
            console.error(error)
            res.status(500).json({ ok: false, message: 'Error al crear certificado' })
        }
    },

    async subirPdf(req, res) {
        try {
            const { id } = req.params
            const { archivoPdfUrl } = req.body
            const usuarioId = req.user.sub

            await CertificadoService.subirPdf({
                certificadoId: Number(id),
                archivoPdfUrl,
                usuarioId
            })

            res.json({ ok: true, message: 'PDF guardado correctamente' })
        } catch (error) {
            console.error(error)
            res.status(500).json({ ok: false, message: 'Error al guardar PDF' })
        }
    },

    async obtenerReporte(req, res) {
        try {
            const { servicioId } = req.params
            const reporte = await CertificadoService.generarReporte(Number(servicioId))

            res.json({ ok: true, reporte })
        } catch (error) {
            console.error(error)
            res.status(500).json({ ok: false, message: 'Error al obtener reporte fotográfico' })
        }
    }

}