import { ListClients } from '../../repository/client/list.repository.js'

export async function listClientsService(search) {
    try {
        const clients = await ListClients.searchClients(search)
        return clients
    } catch (error) {
        throw new Error('Error al obtener la lista de clientes')
    }
}