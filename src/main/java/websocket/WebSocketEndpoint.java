package websocket;

import jakarta.websocket.*;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.concurrent.ConcurrentHashMap;
import utils.DBUtil;

@ServerEndpoint("/status")
public class WebSocketEndpoint {
    private static final ConcurrentHashMap<Session, Integer> sessionUserMap = new ConcurrentHashMap<>();
    private static final ConcurrentHashMap<Integer, Integer> activeSessions = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session) {
        System.out.println("WebSocket opened: " + session.getId());
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        try (Connection conn = DBUtil.getConnection()) {
            String[] parts = message.split(":");
            if (parts.length == 2) {
                String action = parts[0];
                int userId = Integer.parseInt(parts[1]);

                if (action.equals("login")) {
                    sessionUserMap.put(session, userId);
                    activeSessions.put(userId, activeSessions.getOrDefault(userId, 0) + 1);

                    // Only mark online if this is the first active session
                    if (activeSessions.get(userId) == 1) {
                        updateUserStatus(conn, userId, 1);
                        broadcastStatus(userId, true);
                    }
                } else if (action.equals("logout")) {
                    updateUserStatus(conn, userId, 0);
                    sessionUserMap.remove(session);
                    activeSessions.remove(userId);
                    broadcastStatus(userId, false);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClose
    public void onClose(Session session) {
        Integer userId = sessionUserMap.remove(session);
        if (userId != null) {
            int sessionCount = activeSessions.getOrDefault(userId, 0);
            if (sessionCount > 1) {
                activeSessions.put(userId, sessionCount - 1);
            } else {
                activeSessions.remove(userId);
                try (Connection conn = DBUtil.getConnection()) {
                    updateUserStatus(conn, userId, 0); // Mark offline only if all sessions are closed
                    broadcastStatus(userId, false);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private void updateUserStatus(Connection conn, int userId, int isOnline) throws Exception {
        String sql = "UPDATE users SET is_online = ? WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, isOnline);
            stmt.setInt(2, userId);
            stmt.executeUpdate();
        }
    }

    private void broadcastStatus(int userId, boolean isOnline) {
        String message = "status:" + userId + ":" + (isOnline ? "Online" : "Offline");
        for (Session session : sessionUserMap.keySet()) {
            try {
                session.getBasicRemote().sendText(message);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
