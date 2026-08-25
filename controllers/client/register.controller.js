import {
    registerTechnicianService,
    registerUserService,
} from '../../service/client/register.service.js'

export async function registerTechnician(req, res) {
    try {
        const technician = await registerTechnicianService(req.user, req.body)

        res.status(201).json({
            message: 'Técnico creado',
            technician,
        })
    } catch (error) {
        res.status(400).json({ message: error.message })
    }
}

export async function registerUser(req, res) {
    try {

        const adminUser = req.user

        const userData = req.body
        const user = await registerUserService(adminUser, userData)

        res.status(201).json({ message: 'Usuario creado', user })
    } catch (error) {
        res.status(400).json({ message: error.message })
    }
}
