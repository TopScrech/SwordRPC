enum OP: UInt32 {
    case handshake,
         frame,
         close,
         ping,
         pong
}

enum Event: String {
    case error = "ERROR",
         join = "ACTIVITY_JOIN",
         joinRequest = "ACTIVITY_JOIN_REQUEST",
         ready = "READY",
         spectate = "ACTIVITY_SPECTATE"
}

public enum JoinReply: Int {
    case no,
         yes,
         ignore
}
