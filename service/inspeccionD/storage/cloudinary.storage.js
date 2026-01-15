import { v2 as cloudinary } from 'cloudinary'
import StorageProvider from './storage.interface.js'

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
})

export default class CloudinaryStorage extends StorageProvider {
    upload(buffer, options = {}) {
        return new Promise((resolve, reject) => {
            cloudinary.uploader
                .upload_stream(
                    { folder: options.folder || 'inspecciones' },
                    (error, result) => {
                        if (error) return reject(error)

                        resolve({
                            url: result.secure_url,
                            id: result.public_id,
                        })
                    }
                )
                .end(buffer)
        })
    }

    async delete(id) {
        await cloudinary.uploader.destroy(id)
    }
}