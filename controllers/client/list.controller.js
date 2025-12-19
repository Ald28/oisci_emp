import { listClientsService } from '../../service/client/list.service.js'

export async function listClients(req, res) {
    try {
        const { search } = req.query
        const clients = await listClientsService(search)
        res.status(200).json(clients)
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener la lista de clientes' })
    }
}