import Foundation
import Socket

extension SwordRPC {
    func createSocket() {
        do {
            socket = try Socket.create(family: .unix, proto: .unix)
            try socket?.setBlocking(mode: false)
        } catch {
            guard let error = error as? Socket.Error else {
                print("[SwordRPC] Unable to create rpc socket")
                return
            }
            
            print("[SwordRPC] Error creating rpc socket: \(error)")
        }
    }
    
    func send(_ msg: String, _ op: OP) throws {
        let payload = msg.data(using: .utf8)!
        
        let alignment = MemoryLayout<UInt8>.alignment
        let byteCount = 8 + payload.count
        var buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: byteCount, alignment: alignment)
        
        defer {
            buffer.deallocate()
        }
        
        buffer.copyBytes(from: payload)
        buffer[8...] = buffer[..<payload.count]
        buffer.storeBytes(of: op.rawValue, as: UInt32.self)
        buffer.storeBytes(of: UInt32(payload.count), toByteOffset: 4, as: UInt32.self)
        
        try socket?.write(from: buffer.baseAddress!, bufSize: buffer.count)
    }
    
    func receive() {
        worker.asyncAfter(
            deadline: .now() + .milliseconds(handlerInterval)
        ) { [unowned self] in
            guard let isConnected = socket?.isConnected, isConnected else {
                disconnectHandler?(self, nil, nil)
                delegate?.swordRPCDidDisconnect(self, code: nil, message: nil)
                return
            }
            
            receive()
            
            do {
                let headerPtr = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
                let headerRawPtr = UnsafeRawPointer(headerPtr)
                
                defer {
                    free(headerPtr)
                }
                
                var response = try socket?.read(into: headerPtr, bufSize: 8, truncate: true)
                
                guard response! > 0 else {
                    return
                }
                
                let opValue = headerRawPtr.load(as: UInt32.self)
                let length = headerRawPtr.load(fromByteOffset: 4, as: UInt32.self)
                
                guard length > 0, let op = OP(rawValue: opValue) else {
                    return
                }
                
                let payloadPtr = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
                
                defer {
                    free(payloadPtr)
                }
                
                response = try socket?.read(into: payloadPtr, bufSize: Int(length), truncate: true)
                
                guard response! > 0 else {
                    return
                }
                
                let data = Data(bytes: UnsafeRawPointer(payloadPtr), count: Int(length))
                
                handlePayload(op, data)
                
            } catch {
                return
            }
        }
    }
    
    func handshake() {
        do {
            let json = """
      {
        "v": 1,
        "client_id": "\(appId)"
      }
      """
            
            try send(json, .handshake)
        } catch {
            print("[SwordRPC] Unable to handshake with Discord")
            socket?.close()
        }
    }
    
    func subscribe(_ event: String) {
        let json = """
    {
      "cmd": "SUBSCRIBE",
      "evt": "\(event)",
      "nonce": "\(UUID().uuidString)"
    }
    """
        
        try? send(json, .frame)
    }
    
    func handlePayload(_ op: OP, _ json: Data) {
        switch op {
        case .close:
            let data = decode(json)
            let code = data["code"] as! Int
            let message = data["message"] as! String
            socket?.close()
            disconnectHandler?(self, code, message)
            delegate?.swordRPCDidDisconnect(self, code: code, message: message)
            
        case .ping:
            try? send(String(data: json, encoding: .utf8)!, .pong)
            
        case .frame:
            handleEvent(decode(json))
            
        default:
            return
        }
    }
    
    func handleEvent(_ data: [String: Any]) {
        guard let evt = data["evt"] as? String,
              let event = Event(rawValue: evt) else {
            return
        }
        
        let data = data["data"] as! [String: Any]
        
        switch event {
        case.error:
            let code = data["code"] as! Int
            let message = data["message"] as! String
            errorHandler?(self, code, message)
            delegate?.swordRPCDidReceiveError(self, code: code, message: message)
            
        case .join:
            let secret = data["secret"] as! String
            joinGameHandler?(self, secret)
            delegate?.swordRPCDidJoinGame(self, secret: secret)
            
        case .joinRequest:
            let requestData = data["user"] as! [String: Any]
            
            let joinRequest = try! decoder.decode(
                JoinRequest.self, from: encode(requestData)
            )
            
            let secret = data["secret"] as! String
            joinRequestHandler?(self, joinRequest, secret)
            delegate?.swordRPCDidReceiveJoinRequest(self, request: joinRequest, secret: secret)
            
        case .ready:
            connectHandler?(self)
            delegate?.swordRPCDidConnect(self)
            updatePresence()
            
        case.spectate:
            let secret = data["secret"] as! String
            spectateGameHandler?(self, secret)
            delegate?.swordRPCDidSpectateGame(self, secret: secret)
        }
    }
    
    func updatePresence() {
        worker.asyncAfter(deadline: .now() + .seconds(15)) { [unowned self] in
            updatePresence()
            
            guard let presence else {
                return
            }
            
            self.presence = nil
            
            let json = """
          {
            "cmd": "SET_ACTIVITY",
            "args": {
              "pid": \(pid),
              "activity": \(String(data: try! encoder.encode(presence), encoding: .utf8)!)
            },
            "nonce": "\(UUID().uuidString)"
          }
          """
            
            try? send(json, .frame)
        }
    }
}
