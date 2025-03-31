<%@page import="websocket.ChatEndpoint"%>
<%@page import="java.time.Instant"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.Timestamp"%>
<%@ page import="utils.DBUtil" %>

<%
    Integer senderId = (Integer) session.getAttribute("userId");
    String receiverId = request.getParameter("receiver_id");
    String text = request.getParameter("text");

    if (senderId == null || receiverId == null || text == null) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        return;
    }

    // Database Insertion
    try (Connection conn = DBUtil.getConnection();
         PreparedStatement stmt = conn.prepareStatement(
             "INSERT INTO messages (sender_id, receiver_id, text, created_at) VALUES (?, ?, ?, ?)")) {
        
        stmt.setInt(1, senderId);
        stmt.setInt(2, Integer.parseInt(receiverId));
        stmt.setString(3, text);
        stmt.setTimestamp(4, new Timestamp(Instant.now().toEpochMilli()));
        
        if (stmt.executeUpdate() > 0) {
            // Broadcast via WebSocket
            String jsonMessage = String.format(
    "{\"senderId\":%d,\"receiverId\":%d,\"text\":\"%s\",\"timestamp\":\"%s\"}",
    senderId, 
    Integer.parseInt(receiverId), 
    text.replace("\"", "\\\"").replace("\n", "\\n"), 
    Instant.now().toString()
);
            ChatEndpoint.sendMessage(senderId, Integer.parseInt(receiverId), jsonMessage);
            out.print("success");
        }
    } catch(Exception e) {
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        e.printStackTrace();
    }
%>