import bcrypt from 'bcrypt'
import { ListClients } from '../repository/list.repository.js'
import { prisma } from '../database/client.mjs'

export async function listClientsService() {
    try {
        const clients = await ListClients.getAllClients()
        return clients
    } catch (error) {
        throw new Error('Error al obtener la lista de clientes')
    }
}