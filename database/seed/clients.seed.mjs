import { prisma } from '../client.mjs'
import { generateClientCode } from './utils.mjs'

export async function seedClients(clienteUsers) {
    for (let i = 0; i < clienteUsers.length; i++) {
        const user = clienteUsers[i]

        await prisma.client.upsert({
            where: { ruc: `1234567890${i + 1}` },
            update: {},
            create: {
                clientCode: generateClientCode(i + 1),
                razonSocial: `Cliente Ejemplo ${i + 1} S.A.`,
                ruc: `1234567890${i + 1}`,
                phone: '987654321',
                address: 'Av. Ejemplo 123, Ciudad',
                userId: user.id,
            },
        })
    }

    console.log('Clientes creados')
}