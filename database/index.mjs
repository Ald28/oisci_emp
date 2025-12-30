import { prisma } from './client.mjs'
import { seedRoles } from './seed/roles.seed.mjs'
import { seedUsers } from './seed/users.seed.mjs'
import { seedClients } from './seed/clients.seed.mjs'
import { seedSedes } from './seed/sedes.seed.mjs'
import { seedExtintores } from './seed/extintores.seed.mjs'
import { seedServicios } from './seed/servicios.seed.mjs'

async function main() {
    const roles = await seedRoles()
    const clienteUser = await seedUsers(roles)
    await seedClients(clienteUser)

    await seedSedes()
    await seedExtintores()
    await seedServicios()

    console.log('Seed completado: Roles, Usuarios, Clientes, Sedes, Extintores y Servicios creados')
}

main()
    .catch(e => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })