import { prisma } from '../client.mjs'
import { generateClientCode } from './utils.mjs'

export async function seedClients(clienteUser) {
    if (clienteUser) {
        await prisma.client.upsert({
            where: { ruc: '1234567890' },
            update: {},
            create: {
                clientCode: generateClientCode(1),
                razonSocial: 'Cliente Ejemplo S.A.',
                ruc: '1234567890',
                userId: clienteUser.id,
            },
        })
    }
}