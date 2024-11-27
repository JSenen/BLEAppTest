//
//  BleToothManager.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager() // Singleton compartido
    
    @Published var devices: [BleData] = []
    @Published var isConnecting: Bool = false
    private var discoveredDeviceMACs: Set<String> = []
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    @Published var connectionStatus: String = "Desconectado"
    @Published var discoveredCharacteristics: [CBCharacteristic] = [] // Características descubiertas
    private var otaFile: Data?
    private var currentPacketIndex = 0
    @Published var progress: Float = 0.0
    @Published var firmwareVersion: String? // Version de firmware
    
    
    // Definición de comandos
        private let COMMAND_ID_START: UInt16 = 0x0001
        private let COMMAND_ID_END: UInt16 = 0x0002
        private let COMMAND_ID_ACK: UInt16 = 0x0003
        private let COMMAND_ID_VIDEO: UInt16 = 0x0003

        private let COMMAND_ACK_ACCEPT: UInt16 = 0x0000
        private let COMMAND_ACK_REFUSE: UInt16 = 0x0001

        private let BIN_ACK_SUCCESS: UInt16 = 0x0000
        private let BIN_ACK_CRC_ERROR: UInt16 = 0x0001
        private let BIN_ACK_SECTOR_INDEX_ERROR: UInt16 = 0x0002
        private let BIN_ACK_PAYLOAD_LENGTH_ERROR: UInt16 = 0x0003

        private let SERVICE_UUID = CBUUID(string: "00008018-0000-1000-8000-00805f9b34fb")
        private let CHAR_RECV_FW_UUID = CBUUID(string: "00008020-0000-1000-8000-00805f9b34fb")
        private let CHAR_PROGRESS_UUID = CBUUID(string: "00008021-0000-1000-8000-00805f9b34fb")
        private let CHAR_COMMAND_UUID = CBUUID(string: "00008022-0000-1000-8000-00805f9b34fb")
        private let CHAR_CUSTOMER_UUID = CBUUID(string: "00008023-0000-1000-8000-00805f9b34fb")
    
    private var otaPackets: [Data] = [] // Lista para almacenar los paquetes del archivo OTA

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // Estado del Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth no está disponible o no está activado.")
        }
    }

    
    // Descubrimiento de dispositivos
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        let mac = peripheral.identifier.uuidString
        let rssiValue = RSSI.intValue // Potencia de señal
        
        // Manufacturer Data (si está disponible)
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        
        // UUIDs de servicios
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        
        if !discoveredDeviceMACs.contains(mac) {
            discoveredDeviceMACs.insert(mac)
            let newDevice = BleData(
                id: devices.count + 1,
                mac: mac,
                name: name,
                imageName: "Ble",
                peripheral: peripheral,
                rssi: rssiValue,
                manufacturerData: manufacturerData,
                serviceUUIDs: serviceUUIDs ?? []
            )
            DispatchQueue.main.async {
                self.devices.append(newDevice)
            }
        }
    }

    
    // Conectar a un dispositivo
    func connectToDevice(_ peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            print("Central Manager no está listo.")
            return
        }
        
        isConnecting = true
        connectionStatus = "Intentando conectar..."
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }



    
    // Evento de conexión exitosa
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado a \(peripheral.name ?? "dispositivo desconocido")")
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        // Solicitar un tamaño de MTU mayor, similar al comportamiento de Android
        peripheral.discoverServices(nil)
        
        DispatchQueue.main.async {
            self.connectionStatus = "Conectado, buscando servicios..."
            self.isConnecting = false
        }
    }



    // Evento de desconexión
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Desconectado de \(peripheral.name ?? "dispositivo desconocido")")
        DispatchQueue.main.async {
            self.connectionStatus = "Desconectado"
            self.isConnecting = false
        }
    }

    
    // Fallo en la conexión
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error al conectar con \(peripheral.name ?? "dispositivo desconocido"): \(error?.localizedDescription ?? "Desconocido")")
        DispatchQueue.main.async {
            self.connectionStatus = "Error al conectar"
            self.isConnecting = false
        }
    }

    
    func restartScan() {
        centralManager.stopScan()
        devices.removeAll()
        discoveredDeviceMACs.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error al descubrir servicios: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionStatus = "Error al descubrir servicios"
            }
            return
        }
        
        guard let services = peripheral.services, !services.isEmpty else {
            print("No se encontraron servicios.")
            DispatchQueue.main.async {
                self.connectionStatus = "Conectado pero sin servicios"
            }
            return
        }
        
        for service in services {
            print("Servicio encontrado: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service) // Descubre características
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error al descubrir características: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionStatus = "Error al descubrir características"
            }
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No se encontraron características para el servicio \(service.uuid)")
            return
        }
        
        print("Características encontradas para el servicio \(service.uuid): \(characteristics.map { $0.uuid })")
        
        // Agrega las características descubiertas a la lista
        DispatchQueue.main.async {
            self.discoveredCharacteristics.append(contentsOf: characteristics)
            self.connectionStatus = "Características descubiertas"
        }
        
        // Habilitar notificaciones para las características de interés
        for characteristic in characteristics {
            enableNotifications(for: characteristic)
            
            // Leer la característica de versión del firmware si está disponible
                   if characteristic.uuid == CBUUID(string: "2A26") {
                       peripheral.readValue(for: characteristic)
                   }
        }
    }
    
    //método delegado que se llama cuando cambia el estado de las notificaciones de una característica:
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al habilitar notificaciones: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notificaciones habilitadas para: \(characteristic.uuid)")
        } else {
            print("Notificaciones deshabilitadas para: \(characteristic.uuid)")
        }
    }
    
    private func initPackets(for file: Data) {
        otaPackets.removeAll()
        currentPacketIndex = 0

        let sectorSize = 4096
        var offset = 0

        while offset < file.count {
            let end = min(offset + sectorSize, file.count)
            let sector = file.subdata(in: offset..<end)
            var sequence: UInt8 = 0

            var remainingSector = sector
            while !remainingSector.isEmpty {
                let packetSize = min(remainingSector.count, 20) // Ajusta el tamaño del paquete (máximo 20 bytes)
                let packetData = remainingSector.prefix(packetSize)
                remainingSector = remainingSector.dropFirst(packetSize)

                var packet = Data()
                packet.append(contentsOf: [UInt8(offset & 0xff), UInt8((offset >> 8) & 0xff)]) // Índice del sector
                packet.append(UInt8(sequence)) // Número de secuencia del paquete
                packet.append(packetData)

                if remainingSector.isEmpty {
                    // Añadir CRC si es el último paquete del sector
                    let crc = EspCRC16.crc([UInt8](sector))
                    packet.append(contentsOf: [UInt8(crc & 0xff), UInt8((crc >> 8) & 0xff)])
                }

                print("Generando paquete, secuencia: \(sequence), tamaño del paquete: \(packet.count)")
                otaPackets.append(packet)
                sequence += 1
            }
            offset += sectorSize
        }
        print("Total de paquetes generados: \(otaPackets.count)")
    }


    //comenzar la transferencia de firmware
    // Método para comenzar la OTA
    func startOTA(with file: Data) {
        guard let peripheral = connectedPeripheral,
              let commandChar = discoveredCharacteristics.first(where: { $0.uuid == CHAR_COMMAND_UUID }) else {
            print("Error: Características necesarias no encontradas.")
            return
        }

        otaFile = file
        initPackets(for: file)

        // Tamaño del archivo binario
        let binSize = UInt32(file.count)
        let payload: [UInt8] = [
            UInt8(binSize & 0xff),
            UInt8((binSize >> 8) & 0xff),
            UInt8((binSize >> 16) & 0xff),
            UInt8((binSize >> 24) & 0xff)
        ]

        // Generar el paquete del comando
        var packet: [UInt8] = [0x01, 0x00] // Comando de inicio
        packet.append(contentsOf: payload)

        // Añadir CRC usando la función de CRC16 de EspCRC16
        let crc = EspCRC16.crc(packet)
        packet.append(UInt8(crc & 0xff))
        packet.append(UInt8((crc >> 8) & 0xff))

        let commandData = Data(packet)

        // Enviar el comando de inicio
        print("Comando de inicio OTA, tamaño del archivo: \(binSize), comando: \(commandData as NSData)")
        peripheral.writeValue(commandData, for: commandChar, type: .withResponse)
        print("Enviando comando de inicio OTA: \(commandData as NSData)")
    }



        // Método para enviar el siguiente paquete de datos del archivo OTA
    func sendNextPacket() {
        guard currentPacketIndex < otaPackets.count,
              let recvFwChar = discoveredCharacteristics.first(where: { $0.uuid == CHAR_RECV_FW_UUID }),
              let peripheral = connectedPeripheral else {
            print("No hay más paquetes para enviar o no se encontró la característica de recepción.")
            return
        }

        // Calcular el tamaño del paquete según el MTU negociado
        let mtuSize = peripheral.maximumWriteValueLength(for: .withResponse)
        let packetSize = min(mtuSize, 512)

        // Obtener el paquete actual
        let packet = otaPackets[currentPacketIndex].prefix(packetSize)

        // Enviar el paquete actual
        peripheral.writeValue(packet, for: recvFwChar, type: .withResponse) // Cambiado a `.withResponse` para controlar la recepción

        print("Enviando paquete de OTA: Índice \(currentPacketIndex), Tamaño \(packet.count) bytes")
    }



    func generateCommandPacket(id: UInt16, payload: [UInt8]) -> Data {
        var packet = [UInt8](repeating: 0, count: 20)
        packet[0] = UInt8(id & 0xff)
        packet[1] = UInt8((id >> 8) & 0xff)
        
        for i in 0..<payload.count {
            packet[i + 2] = payload[i]
        }

        let crc = EspCRC16.crc(packet, offset: 0, length: 18)
        packet[18] = UInt8(crc & 0xff)
        packet[19] = UInt8((crc >> 8) & 0xff)

        return Data(packet)
    }

    func sendCommandEnd() {
        guard let peripheral = connectedPeripheral,
              let commandChar = discoveredCharacteristics.first(where: { $0.uuid == CHAR_COMMAND_UUID }) else {
            return
        }

        let commandEnd: [UInt8] = [0x02, 0x00] // Comando de fin de OTA
        let commandData = generateCommandPacket(id: COMMAND_ID_END, payload: [])
        peripheral.writeValue(commandData, for: commandChar, type: .withoutResponse)
        print("Comando de fin de OTA enviado.")
    }


    // Método delegado llamado cuando el periférico responde al valor de la característica
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al actualizar valor para característica: \(error.localizedDescription)")
            return
        }
        
        if let value = characteristic.value {
                    // Leer y guardar la versión de firmware si corresponde
                    if characteristic.uuid == CBUUID(string: "2A26") { // UUID estándar para la versión de firmware
                        firmwareVersion = String(data: value, encoding: .utf8) ?? "Versión desconocida"
                        print("Versión de firmware: \(firmwareVersion ?? "N/A")")
                    }
                }
        
        if characteristic.uuid == CHAR_RECV_FW_UUID {
            // Recibido ACK, enviar el siguiente paquete
            sendNextPacket()
        } else if characteristic.uuid == CHAR_COMMAND_UUID {
            let data = characteristic.value ?? Data()
            parseCommandAck(data: data)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al escribir valor para la característica: \(error.localizedDescription)")
            return
        }

        if characteristic.uuid == CHAR_RECV_FW_UUID {
            // ACK recibido, proceder con el siguiente paquete
            currentPacketIndex += 1

            // Actualizar progreso
            DispatchQueue.main.async {
                let progress = Float(self.currentPacketIndex) / Float(self.otaPackets.count) * 100.0
                self.connectionStatus = "Enviando OTA: \(Int(progress))% completado"
                self.progress = progress
                print("Progreso de OTA: \(progress)%")
            }

            // Enviar el siguiente paquete
            sendNextPacket()
        }
    }


    func parseCommandAck(data: Data) {
        guard data.count >= 6 else {
            print("Error: Datos del ACK incompletos.")
            return
        }

        // Extraer el ID del comando y el estado del ACK
        let id = (UInt16(data[0]) & 0xff) | (UInt16(data[1]) << 8)
        let ackId = (UInt16(data[2]) & 0xff) | (UInt16(data[3]) << 8)
        let ackStatus = (UInt16(data[4]) & 0xff) | (UInt16(data[5]) << 8)

        print("Recibido ACK del comando - id: \(ackId), estado: \(ackStatus)")

        if id == COMMAND_ID_ACK {
            if ackId == COMMAND_ID_START {
                if ackStatus == COMMAND_ACK_ACCEPT {
                    print("Comando START aceptado, comenzando transferencia de firmware.")
                    sendNextPacket() // Iniciar el envío de paquetes OTA solo después del ACK del START
                } else {
                    print("Comando START rechazado.")
                    connectionStatus = "Error al iniciar OTA"
                }
            } else if ackId == COMMAND_ID_END {
                if ackStatus == COMMAND_ACK_ACCEPT {
                    print("Comando END aceptado, OTA finalizada.")
                    connectionStatus = "OTA completada"
                } else {
                    print("Comando END rechazado.")
                    connectionStatus = "Error al finalizar OTA"
                }
            }
        }
    }

    
    //Habilitar las notificaciones para la OTA
    func enableNotifications(for characteristic: CBCharacteristic) {
        if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
            connectedPeripheral?.setNotifyValue(true, for: characteristic)
        }
    }
    
    //Reset de pantalla al regresar a listado
    func resetConnectionState() {
        self.connectionStatus = "Desconectado"
        self.isConnecting = false
        self.discoveredCharacteristics.removeAll()
    }

}


