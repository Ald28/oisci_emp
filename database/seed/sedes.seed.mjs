import { prisma } from '../client.mjs'

export async function seedSedes() {
    const client = await prisma.client.findFirst()

    if (!client) {
        throw new Error('No existe cliente para crear sedes')
    }

    const sedes = [
        {
            name_sede: 'Sede Central',
            address: 'Av. Principal 123',
            manager_name: 'Juan Pérez',
            manager_phone: '987654321',
            manager_email: 'juan@empresa.com',
            city: 'Lima',
            clientId: client.id,
        },
        {
            name_sede: 'Sede Norte',
            address: 'Av. Norte 456',
            manager_name: 'Ana Gómez',
            manager_phone: '987654322',
            manager_email: 'ana@empresa.com',
            city: 'Lima',
            clientId: client.id,
        }
    ]

    for (const sede of sedes) {
        await prisma.sede.createMany({
            data: sedes,
            skipDuplicates: true,
        })
    }

    console.log('Sedes creadas')
}