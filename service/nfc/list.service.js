import { ListRepository } from "../../repository/nfc/list.repository.js";

export async function listNFCService() {
    const nfcList =  await ListRepository.listAll();
    return nfcList;
}

export async function getNFCByIdService(codigoNFC) {
    const nfc = await ListRepository.findById(codigoNFC);
    return nfc;
}