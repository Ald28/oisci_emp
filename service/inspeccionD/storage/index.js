import CloudinaryStorage from './cloudinary.storage.js'
// import S3Storage from './s3.storage.js'

let storage

switch (process.env.STORAGE_PROVIDER) {
    case 's3':
        // storage = new S3Storage()
        throw new Error('S3 storage no implementado')
    default:
        storage = new CloudinaryStorage()
}

export default storage