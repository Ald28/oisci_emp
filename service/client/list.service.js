import { ListClients } from '../../repository/client/list.repository.js'

export async function listClientsService(search, page, pageSize, all = false) {
    try {
        return await ListClients.searchClients(search, page, pageSize, all)
    } catch (error) {
        throw new Error('Error al obtener la lista de clientes')
    }
}