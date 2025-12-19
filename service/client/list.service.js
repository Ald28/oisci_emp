import { ListClients } from '../../repository/client/list.repository.js'

export async function listClientsService(search) {
    try {
        return await ListClients.searchClients(search)
    } catch (error) {
        throw new Error('Error al obtener la lista de clientes')
    }
}