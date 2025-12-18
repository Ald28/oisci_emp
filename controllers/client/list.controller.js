import { listClientsService } from '../../service/client/list.service.js'

export async function listClients(req, res) {
    try {
        const clients = await listClientsService()
        res.status(200).json({ clients })
    } catch (error) {
        res.status(500).json({ message: error.message })
    }
}