import { Router } from "express";
import { CertificadoDataController } from "../../controllers/services/detail.controller.js";

const router = Router();

/**
 * @swagger
 * /services/{servicioId}/data/{tipo}:
 *   get:
 *     summary: Obtener datos para generar certificado por tipo
 *     description: Retorna los datos del cliente, sede, servicio y extintores relacionados para generar el certificado. Solo aplica a servicios de tipo MANTENIMIENTO y con estado FINALIZADO.
 *     tags:
 *       - Services
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
 *         example: 10
 *       - in: path
 *         name: tipo
 *         required: true
 *         schema:
 *           type: string
 *           enum: [OPER, HIDRO, BAJA]
 *         description: Tipo de certificado a generar
 *         example: OPER
 *     responses:
 *       200:
 *         description: Datos del certificado obtenidos correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                   example: Datos del certificado obtenidos correctamente
 *                 data:
 *                   type: object
 *                   properties:
 *                     certificadoTipo:
 *                       type: string
 *                       example: OPER
 *                     cliente:
 *                       type: object
 *                       nullable: true
 *                       properties:
 *                         id:
 *                           type: integer
 *                           example: 1
 *                         clientCode:
 *                           type: string
 *                           example: CLI-001
 *                         razonSocial:
 *                           type: string
 *                           example: Empresa ABC SAC
 *                         ruc:
 *                           type: string
 *                           example: "12345678901"
 *                         phone:
 *                           type: string
 *                           example: "999999999"
 *                         address:
 *                           type: string
 *                           example: Av. Principal 123
 *                     sede:
 *                       type: object
 *                       nullable: true
 *                       properties:
 *                         id:
 *                           type: integer
 *                           example: 2
 *                         name_sede:
 *                           type: string
 *                           example: Sede Central
 *                         address:
 *                           type: string
 *                           example: Av. Los Olivos 456
 *                         manager_name:
 *                           type: string
 *                           example: Juan Pérez
 *                         manager_phone:
 *                           type: string
 *                           example: "988777666"
 *                         manager_email:
 *                           type: string
 *                           example: jefe@sede.com
 *                         city:
 *                           type: string
 *                           example: Lima
 *                     servicio:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                           example: 10
 *                         type:
 *                           type: string
 *                           example: MANTENIMIENTO
 *                         status:
 *                           type: string
 *                           example: FINALIZADO
 *                         statusValid:
 *                           type: string
 *                           example: APROBADO
 *                         dateStart:
 *                           type: string
 *                           format: date-time
 *                           example: 2026-03-20T00:00:00.000Z
 *                         dateEnd:
 *                           type: string
 *                           nullable: true
 *                           format: date-time
 *                           example: 2026-03-21T00:00:00.000Z
 *                         createdAt:
 *                           type: string
 *                           format: date-time
 *                         updatedAt:
 *                           type: string
 *                           format: date-time
 *                         tecnicoAsignado:
 *                           type: object
 *                           nullable: true
 *                           properties:
 *                             id:
 *                               type: integer
 *                               example: 5
 *                             name:
 *                               type: string
 *                               example: Carlos Ruiz
 *                             email:
 *                               type: string
 *                               example: carlos@correo.com
 *                             userCode:
 *                               type: string
 *                               example: TEC-001
 *                     resumen:
 *                       type: object
 *                       properties:
 *                         totalExtintoresServicio:
 *                           type: integer
 *                           example: 5
 *                         totalExtintoresCertificado:
 *                           type: integer
 *                           example: 2
 *                     extintores:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           servicioExtintorId:
 *                             type: integer
 *                             example: 1
 *                           extintorId:
 *                             type: integer
 *                             example: 4
 *                           codigo:
 *                             type: string
 *                             example: ATE-001
 *                           capacidad:
 *                             type: string
 *                             example: 5kg
 *                           tipo:
 *                             type: string
 *                             example: Polvo Químico
 *                           marca:
 *                             type: string
 *                             example: Amerex
 *                           modelo:
 *                             type: string
 *                             example: ABC-123
 *                           numeroSerie:
 *                             type: string
 *                             example: SN-0001
 *                           anioFabricacion:
 *                             type: string
 *                             example: "2023"
 *                           ph:
 *                             type: string
 *                             example: 15/01/2025
 *                           proximoMantenimiento:
 *                             type: string
 *                             example: 15/01/2026
 *                           extintor:
 *                             type: object
 *                             nullable: true
 *                           mantenimientoDetalle:
 *                             type: object
 *                             nullable: true
 *       400:
 *         description: Parámetros inválidos o servicio no apto para generar certificado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: error
 *                 message:
 *                   type: string
 *                   example: Solo se puede generar certificado de servicios FINALIZADOS
 *       404:
 *         description: Servicio no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: error
 *                 message:
 *                   type: string
 *                   example: Servicio no encontrado
 *       500:
 *         description: Error interno del servidor
 */
router.get("/:servicioId/data/:tipo", CertificadoDataController.getData);

export default router;