package websocket;
import jakarta.websocket.*;
import jakarta.websocket.server.*;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@ServerEndpoint("/group-chat/{groupId}")
public class GroupChatEndpoint {
    private static final Map<Integer, Set<Session>> groupSessions = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session, @PathParam("groupId") int groupId) {
        groupSessions
            .computeIfAbsent(groupId, k -> ConcurrentHashMap.newKeySet())
            .add(session);
        System.out.println("WebSocket opened for group " + groupId);
    }

    @OnClose
    public void onClose(Session session, @PathParam("groupId") int groupId) {
        Set<Session> sessions = groupSessions.get(groupId);
        if (sessions != null) {
            sessions.remove(session);
            System.out.println("WebSocket closed for group " + groupId);
        }
    }

    @OnMessage
    public void onMessage(String message, Session session, @PathParam("groupId") int groupId) {
        System.out.println("Received WebSocket message for group " + groupId + ": " + message);
        broadcast(message, groupId);
    }

    public static void sendMessage(int groupId, String message) {
        System.out.println("Broadcasting to group " + groupId + ": " + message);
        broadcast(message, groupId);
    }

    private static void broadcast(String message, int groupId) {
        Set<Session> sessions = groupSessions.get(groupId);
        if (sessions != null) {
            sessions.forEach(session -> {
                if (session.isOpen()) {
                    try {
                        session.getBasicRemote().sendText(message);
                        System.out.println("Sent message to session " + session.getId());
                    } catch (IOException e) {
                        System.err.println("Error sending message to session " + session.getId());
                        e.printStackTrace();
                    }
                }
            });
        }
    }
}