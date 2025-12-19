import { EditClients } from "../../repository/client/edit.repository.js"

export async function editClientAndUserService(clientId, payload, editorUser) {
    const { client, user } = payload

    if (!client && !user) {
        throw new Error('No hay datos para actualizar')
    }

    return EditClients.updateClientAndUser(
        clientId,
        client ?? {},
        user ?? {},
        editorUser.sub
    )
}