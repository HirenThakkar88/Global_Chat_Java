import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;

@ServerEndpoint("/chat/{userId}")
public class ChatWebSocket {
    private static Map<Integer, Session> onlineUsers = new ConcurrentHashMap<>();
    
    @OnOpen
    public void onOpen(@PathParam("userId") int userId, Session session) {
        onlineUsers.put(userId, session);
    }

    @OnMessage
    public void onMessage(String message, Session senderSession) {
        for (Session session : onlineUsers.values()) {
            try {
                session.getBasicRemote().sendText(message);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    @OnClose
    public void onClose(@PathParam("userId") int userId, Session session) {
        onlineUsers.remove(userId);
    }
}
