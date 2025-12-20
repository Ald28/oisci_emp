import { listClientsService } from '../../service/client/list.service.js'

export async function listClients(req, res) {
    try {
        const { search, page = 1 } = req.query

        const result = await listClientsService(
            search,
            Number(page),
            10
        )

        res.status(200).json(result)
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener la lista de clientes' })
    }
}