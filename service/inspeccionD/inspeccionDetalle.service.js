import storage from './storage/index.js'
import inspeccionRepo from '../../repository/inpeccionD/inspeccionDetalle.repository.js'

async function uploadFotos({ servicioExtintorId, files, userId }) {
    if (!files || files.length === 0) {
        throw new Error('No se enviaron imágenes')
    }

    const fotos = {}

    for (let i = 0; i < files.length; i++) {
        const result = await storage.upload(files[i].buffer, {
            folder: 'inspecciones',
        })

        fotos[`foto${i + 1}Url`] = result.url
    }

    return inspeccionRepo.upsertFotos({
        servicioExtintorId,
        fotos,
        userId,
    })
}

async function saveInspeccion({ servicioExtintorId, userId, ...data }) {
    return inspeccionRepo.upsertDetalle({
        servicioExtintorId,
        data,
        userId,
    })
}

async function saveInspeccionWithFotos({ servicioExtintorId, files, userId, ...data }) {
    const fotos = {}
    let foto1Url = null

    if (files && files.length > 0) {
        for (let i = 0; i < files.length; i++) {
            const result = await storage.upload(files[i].buffer, {
                folder: 'inspecciones',
            })

            fotos[`foto${i + 1}Url`] = result.url

            // 👉 SOLO capturamos la primera
            if (i === 0) {
                foto1Url = result.url
            }
        }
    }

    return inspeccionRepo.upsertDetalle({
        servicioExtintorId,
        data: { ...data, ...fotos }, // 👈 siguen yendo las 3 fotos
        userId,
        foto1Url, // 👈 SOLO PARA extintor.photo
    })
}

async function getByServicioExtintorId(servicioExtintorId) {
    return inspeccionRepo.findByServicioExtintorId(servicioExtintorId)
}

export default {
    uploadFotos,
    saveInspeccion,
    saveInspeccionWithFotos,
    getByServicioExtintorId,
}