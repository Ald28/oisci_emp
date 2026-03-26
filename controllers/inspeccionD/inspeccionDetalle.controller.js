import inspeccionService from '../../service/inspeccionD/inspeccionDetalle.service.js'

export async function uploadFotosInspeccion(req, res) {
    try {
        const { id } = req.params

        const inspeccion = await inspeccionService.uploadFotos({
            servicioExtintorId: Number(id),
            files: req.files,
            userId: req.user.sub,
        })

        res.json(inspeccion)
    } catch (error) {
        console.error(error)
        res.status(500).json({ message: error.message })
    }
}

export async function createOrUpdateInspeccion(req, res) {
    try {
        const inspeccion = await inspeccionService.saveInspeccion({
            ...req.body,
            userId: req.user.sub,
        })

        res.json(inspeccion)
    } catch (error) {
        res.status(500).json({ message: error.message })
    }
}

export async function createOrUpdateInspeccionWithFotos(req, res) {
    try {
        // Obtener servicioExtintorId desde params o body
        const servicioExtintorId = req.params.servicioExtintorId 
            ? Number(req.params.servicioExtintorId)
            : Number(req.body.servicioExtintorId)

        if (!servicioExtintorId) {
            return res.status(400).json({ message: 'servicioExtintorId es requerido' })
        }

        // Obtener archivos (pueden venir como objeto con foto1, foto2, foto3 o como array)
        const files = []
        if (req.files) {
            if (Array.isArray(req.files)) {
                files.push(...req.files)
            } else if (req.files.foto1) {
                files.push(req.files.foto1[0])
            }
            if (req.files.foto2) {
                files.push(req.files.foto2[0])
            }
            if (req.files.foto3) {
                files.push(req.files.foto3[0])
            }
            if (req.files.foto4) {
                files.push(req.files.foto4[0])
            }
        }

        // Parsear datos del checklist desde el campo 'data' si existe
        let checklistData = {}
        if (req.body.data) {
            try {
                checklistData = typeof req.body.data === 'string' 
                    ? JSON.parse(req.body.data) 
                    : req.body.data
            } catch (e) {
                // Si no se puede parsear, usar req.body directamente
                checklistData = req.body
            }
        } else {
            // Si no hay campo 'data', usar req.body directamente (sin servicioExtintorId)
            const { servicioExtintorId: _, ...rest } = req.body
            checklistData = rest
        }

        const inspeccion = await inspeccionService.saveInspeccionWithFotos({
            servicioExtintorId: servicioExtintorId,
            files: files,
            userId: req.user.sub,
            ...checklistData,
        })

        // Emitir evento WebSocket para notificar a otros dispositivos
        const { emitInspectionDetailChange } = await import('../../utils/socket.helper.js');
        emitInspectionDetailChange('created', inspeccion);

        res.json({ data: inspeccion })
    } catch (error) {
        console.error(error)
        res.status(500).json({ message: error.message })
    }
}

export async function getInspeccionByServicioExtintorId(req, res) {
    try {
        const { servicioExtintorId } = req.params

        if (!servicioExtintorId) {
            return res.status(400).json({
                ok: false,
                message: 'servicioExtintorId es requerido'
            })
        }

        const inspeccion = await inspeccionService.getByServicioExtintorId(
            Number(servicioExtintorId)
        )

        if (!inspeccion) {
            return res.status(404).json({
                ok: false,
                message: 'Inspección no encontrada'
            })
        }

        const response = {
            extintorId: inspeccion.servicioExtintorId,
            codeExtintor: null,
            serialNumberNFC: null,
            type: null,
            location: null,
            fotos: [
                inspeccion.foto1Url,
                inspeccion.foto2Url,
                inspeccion.foto3Url,
                inspeccion.foto4Url,
            ].filter(Boolean), // elimina nulls
            comentarios: inspeccion.observaciones,
            fechaHora: inspeccion.updatedAt
        }

        return res.json({
            ok: true,
            reporte: [response] // 👈 siempre array
        })

    } catch (error) {
        console.error(error)
        res.status(500).json({
            ok: false,
            message: error.message
        })
    }
}

export default {
    uploadFotosInspeccion,
    createOrUpdateInspeccion,
    createOrUpdateInspeccionWithFotos,
    getInspeccionByServicioExtintorId,
}