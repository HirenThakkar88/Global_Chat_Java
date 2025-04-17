package websocket;



import jakarta.websocket.*;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@ServerEndpoint("/call")
public class CallEndpoint {
    private static final ConcurrentHashMap<Integer, Session> userSessions = new ConcurrentHashMap<>();
    
    @OnOpen
    public void onOpen(Session session) {
        Integer userId = getUserIdFromSession(session);
        if(userId != null) {
            userSessions.put(userId, session);
        }
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        String[] parts = message.split("\\|");
        if(parts.length < 2) return;

        String action = parts[0];
        Integer senderId = getUserIdFromSession(session);

        switch(action) {
            case "INITIATE_CALL":
                handleCallInitiation(senderId, parts);
                break;
            case "ACCEPT_CALL":
                handleCallAcceptance(senderId, parts);
                break;
            case "REJECT_CALL":
                handleCallRejection(senderId, parts);
                break;
            case "END_CALL":
                handleCallEnd(senderId, parts);
                break;
        }
    }

    private void handleCallInitiation(Integer callerId, String[] parts) {
        if(parts.length < 3) return;
        
        int receiverId = Integer.parseInt(parts[1]);
        String callType = parts[2];
        
        Session receiverSession = userSessions.get(receiverId);
        if(receiverSession != null) {
            sendMessage(receiverSession, "INCOMING_CALL|" + callerId + "|" + callType);
        }
    }

    private void handleCallAcceptance(Integer receiverId, String[] parts) {
        if(parts.length < 2) return;
        
        int callerId = Integer.parseInt(parts[1]);
        Session callerSession = userSessions.get(callerId);
        if(callerSession != null) {
            sendMessage(callerSession, "CALL_ACCEPTED|" + receiverId);
        }
    }

    private void handleCallRejection(Integer receiverId, String[] parts) {
        if(parts.length < 2) return;
        
        int callerId = Integer.parseInt(parts[1]);
        Session callerSession = userSessions.get(callerId);
        if(callerSession != null) {
            sendMessage(callerSession, "CALL_REJECTED|" + receiverId);
        }
    }

    private void handleCallEnd(Integer userId, String[] parts) {
        if(parts.length < 2) return;
        
        int otherUserId = Integer.parseInt(parts[1]);
        Session otherUserSession = userSessions.get(otherUserId);
        if(otherUserSession != null) {
            sendMessage(otherUserSession, "CALL_ENDED|" + userId);
        }
    }

    @OnClose
    public void onClose(Session session) {
        Integer userId = getUserIdFromSession(session);
        if(userId != null) {
            userSessions.remove(userId);
        }
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        // Handle error
    }

    private Integer getUserIdFromSession(Session session) {
        try {
            return Integer.parseInt(session.getRequestParameterMap().get("userId").get(0));
        } catch (Exception e) {
            return null;
        }
    }

    private void sendMessage(Session session, String message) {
        if(session.isOpen()) {
            try {
                session.getBasicRemote().sendText(message);
            } catch (IOException e) {
                // Handle exception
            }
        }
    }
}