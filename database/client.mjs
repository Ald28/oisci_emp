import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis

export const prisma =
    globalForPrisma.prisma ??
    new PrismaClient({
        log: [{ level: 'query', emit: 'event' }],
    })

if (process.env.NODE_ENV !== 'production') {
    globalForPrisma.prisma = prisma
}

// Listener GLOBAL de queries
prisma.$on('query', (e) => {
    console.log(`
🧠 PRISMA QUERY
SQL: ${e.query}
Params: ${e.params}
Duration: ${e.duration} ms
`)
})