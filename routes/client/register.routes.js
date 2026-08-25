import { Router } from 'express'
import {
    registerTechnician,
    registerUser,
} from '../../controllers/client/register.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /users/technicians:
 *   post:
 *     summary: Crear un técnico sin enviar el ID del rol
 *     tags: [Technicians]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *                 example: Juan Pérez
 *               email:
 *                 type: string
 *                 format: email
 *                 example: juan.perez@empresa.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: "123456"
 *     responses:
 *       201:
 *         description: Técnico creado correctamente
 *       400:
 *         description: Datos inválidos o email ya registrado
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: Solo un administrador puede crear técnicos
 */
router.post(
    '/technicians',
    authenticate,
    authorize(['admin']),
    registerTechnician,
)

/**
 * @swagger
 * /users/register:
 *   post:
 *     summary: Registrar usuario o cliente
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *               - roleId
 *             properties:
 *               name:
 *                 type: string
 *                 example: Empresa SAC 
 *               email:
 *                 type: string
 *                 example: contacto6@empresa.com
 *               password:
 *                 type: string
 *                 example: 123456
 *               roleId:
 *                 type: integer
 *                 example: 3 // ROL 2=TECNICO, ROL 3=CLIENTE
 *               razonSocial:
 *                 type: string
 *                 example: Empresa SAC //SOLO PARA CLIENTE
 *               ruc:
 *                 type: string
 *                 example: 20123456786 //SOLO PARA CLIENTE
 *               phone:
 *                 type: string
 *                 example: 999888777 //SOLO PARA CLIENTE
 *               address:
 *                 type: string
 *                 example: Av. Principal 123 //SOLO PARA CLIENTE
 *     responses:
 *       201:
 *         description: Usuario o cliente registrado correctamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: No tiene permisos de administrador
 *       409:
 *         description: Usuario, email o RUC ya existe
 */
router.post('/register', authenticate, authorize(['admin']), registerUser)

export default router
