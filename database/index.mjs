import { prisma } from './client.mjs'
import { seedRoles } from './seed/roles.seed.mjs'
import { seedUsers } from './seed/users.seed.mjs'
import { seedClients } from './seed/clients.seed.mjs'

async function main() {
    const roles = await seedRoles()
    const clienteUser = await seedUsers(roles)
    await seedClients(clienteUser)

    console.log('Seed completado: Roles, Usuarios y Cliente creados')
}

main()
    .catch(e => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })