import { RegisterService } from '../../service/services/register.service.js'

export const RegisterController = {

  async createServicio(req, res) {
    try {
      const usuarioId = req.user.id

      const servicio = await RegisterService.registerServicio(
        req.body,
        usuarioId
      )

      res.status(201).json({
        message: 'Servicio registrado correctamente',
        data: servicio
      })

    } catch (error) {
      res.status(400).json({
        message: error.message
      })
    }
  }

}