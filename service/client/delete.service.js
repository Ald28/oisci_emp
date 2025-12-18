import { DeleteClients } from '../../repository/client/delete.repository.js'

export async function deleteClientService(clientId) {
    try {
        const deletedClient = await DeleteClients.softDeleteClient(clientId)
        return deletedClient
    } catch (error) {
        throw new Error('Error al eliminar el cliente')
    }
}

export async function restoreClientService(clientId) {
    try {
        const restoredClient = await DeleteClients.restoreClient(clientId)
        return restoredClient
    } catch (error) {
        throw new Error('Error al restaurar el cliente')
    }
}