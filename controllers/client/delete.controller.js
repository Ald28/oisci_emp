import { deleteClientService, restoreClientService } from '../../service/client/delete.service.js'

export async function deleteClient(req, res) {
    try {
        const clientId = Number(req.params.id)

        if (isNaN(clientId)) {
            return res.status(400).json({ message: 'ID inválido' })
        }

        const deletedClient = await deleteClientService(clientId)

        return res.status(200).json({
            message: 'Cliente eliminado correctamente',
            data: deletedClient,
        })
    } catch (error) {
        return res.status(404).json({ message: error.message })
    }
}

export async function restoreClient(req, res) {
    try {
        const clientId = Number(req.params.id)

        if (isNaN(clientId)) {
            return res.status(400).json({ message: 'ID inválido' })
        }

        const restoredClient = await restoreClientService(clientId)

        return res.status(200).json({
            message: 'Cliente restaurado correctamente',
            data: restoredClient,
        })
    } catch (error) {
        return res.status(404).json({ message: error.message })
    }
}