import { loginService } from '../../service/client/auth.service.js'

export async function login(req, res) {
    try {
        const { email, password } = req.body
        const result = await loginService({ email, password })
        res.json(result)
    } catch (error) {
        res.status(401).json({ message: error.message })
    }
}