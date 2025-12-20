import bcrypt from 'bcrypt'
import { RegisterRepository } from '../../repository/client/register.repository.js'
import { prisma } from '../../database/client.mjs'

export async function registerUserService(adminUser, userData) {

    if (adminUser.role !== 'admin') {
        throw new Error('No tienes permisos para registrar usuarios')
    }

    const existingUser = await RegisterRepository.findUserByEmail(userData.email)
    if (existingUser) {
        throw new Error('El email ya está registrado')
    }

    const role = await prisma.role.findUnique({
        where: { id: userData.roleId },
    })

    if (!role) {
        throw new Error('Rol inválido')
    }

    if (role.name === 'cliente') {
        if (!userData.ruc) {
            throw new Error('El RUC es obligatorio para usuarios cliente')
        }

        if (typeof userData.ruc !== 'string' || userData.ruc.length !== 11) {
            throw new Error('El RUC debe tener 11 caracteres')
        }

        const existingClient = await prisma.client.findUnique({
            where: { ruc: userData.ruc },
        })

        if (existingClient) {
            throw new Error('El RUC ya está registrado')
        }
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10)

    try {
        const user = await RegisterRepository.createUser({
            userCode: `USR-${Date.now()}`,
            name: userData.name,
            email: userData.email,
            password: hashedPassword,
            roleId: role.id,
            createdById: adminUser.sub,
            active: true,
        })

        if (role.name === 'cliente') {
            await RegisterRepository.createClient({
                clientCode: `CLI-${Date.now()}`,
                razonSocial: userData.razonSocial,
                ruc: userData.ruc,
                phone: userData.phone,
                address: userData.address,
                userId: user.id,
                active: true,
            })
        }

        return await prisma.user.findUnique({
            where: { id: user.id },
            include: {
                role: true,
                clients: true,
                createdBy: {
                    select: {
                        userCode: true,
                        name: true,
                        email: true,
                    },
                },
            },
        })

    } catch (error) {
        if (error.code === 'P2002') {
            if (error.meta?.target?.includes('email')) {
                throw new Error('El email ya está registrado')
            }
            if (error.meta?.target?.includes('ruc')) {
                throw new Error('El RUC ya está registrado')
            }
        }
        throw error
    }
}