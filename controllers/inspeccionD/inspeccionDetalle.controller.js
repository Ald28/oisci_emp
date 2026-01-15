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

export default {
    uploadFotosInspeccion,
    createOrUpdateInspeccion,
}