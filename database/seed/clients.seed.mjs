import { prisma } from '../client.mjs'
import { generateClientCode } from './utils.mjs'

export async function seedClients(clienteUser) {
    if (clienteUser) {
        await prisma.client.upsert({
            where: { ruc: '12345678901' },
            update: {},
            create: {
                clientCode: generateClientCode(1),
                razonSocial: 'Cliente Ejemplo S.A.',
                ruc: '12345678901',
                phone: '987654321',
                address: 'Av. Ejemplo 123, Ciudad',
                userId: clienteUser.id,
            },
        })
    }
}