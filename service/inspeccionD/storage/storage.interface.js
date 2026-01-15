export default class StorageProvider {
    async upload(buffer, options = {}) {
        throw new Error('upload() not implemented')
    }

    async delete(id) {
        throw new Error('delete() not implemented')
    }
}