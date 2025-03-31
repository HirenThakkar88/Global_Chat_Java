package websocket;

import jakarta.servlet.http.HttpSession;
import jakarta.websocket.*;
import jakarta.websocket.server.*;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@ServerEndpoint(value = "/chat", configurator = WebSocketConfigurator.class)
public class ChatEndpoint {
    private static final Map<Integer, Session> userSessions = Collections.synchronizedMap(new HashMap<>());

    @OnOpen
    public void onOpen(Session session, EndpointConfig config) {
        Integer userId = (Integer) config.getUserProperties().get("userId");
        if (userId != null) {
            userSessions.put(userId, session);
            System.out.println("WebSocket connected for user: " + userId);
        }
    }

    @OnClose
    public void onClose(Session session) {
        userSessions.values().remove(session);
        System.out.println("WebSocket closed");
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        System.err.println("WebSocket error: " + throwable.getMessage());
    }

    public static void sendMessage(int senderId, int receiverId, String message) {
        try {
            Session senderSession = userSessions.get(senderId);
            Session receiverSession = userSessions.get(receiverId);
            
            if (senderSession != null && senderSession.isOpen()) {
                senderSession.getBasicRemote().sendText(message);
            }
            if (receiverSession != null && receiverSession.isOpen()) {
                receiverSession.getBasicRemote().sendText(message);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}