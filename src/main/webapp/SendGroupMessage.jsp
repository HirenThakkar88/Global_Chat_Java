<%@page import="websocket.GroupChatEndpoint"%>
<%@page import="java.time.Instant"%>
<%@page import="java.sql.*"%>
<%@ page import="utils.DBUtil" %>

<%
    response.setContentType("text/plain");
    response.setCharacterEncoding("UTF-8");

    Integer senderId = (Integer) session.getAttribute("userId");
    String groupIdParam = request.getParameter("group_id");
    String text = request.getParameter("text");

    System.out.println("DEBUG: Starting SendGroupMessage - senderId: " + senderId 
        + ", groupId: " + groupIdParam 
        + ", text: " + text);

    if (senderId == null) {
        System.out.println("ERROR: User not logged in");
        response.sendError(401, "Not logged in");
        return;
    }
    
    if (groupIdParam == null || text == null) {
        System.out.println("ERROR: Missing parameters");
        response.sendError(400, "Missing group_id or text");
        return;
    }

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        int groupId = Integer.parseInt(groupIdParam);
        System.out.println("DEBUG: Parsed groupId: " + groupId);

        conn = DBUtil.getConnection();
        System.out.println("DEBUG: Database connection established");

        // 1. Verify group membership
        String checkSql = "SELECT 1 FROM group_members WHERE group_id=? AND user_id=?";
        System.out.println("DEBUG: Checking membership with SQL: " + checkSql);
        
        stmt = conn.prepareStatement(checkSql);
        stmt.setInt(1, groupId);
        stmt.setInt(2, senderId);
        rs = stmt.executeQuery();
        
        if (!rs.next()) {
            System.out.println("ERROR: User " + senderId + " not in group " + groupId);
            response.sendError(403, "Not a group member");
            return;
        }
        System.out.println("DEBUG: Membership verified");

        // 2. Insert message
        String insertSql = "INSERT INTO messages (sender_id, group_id, text, created_at) VALUES (?, ?, ?, ?)";
        System.out.println("DEBUG: Inserting message with SQL: " + insertSql);
        
        stmt = conn.prepareStatement(insertSql);
        stmt.setInt(1, senderId);
        stmt.setInt(2, groupId);
        stmt.setString(3, text);
        stmt.setTimestamp(4, new Timestamp(Instant.now().toEpochMilli()));
        stmt.executeUpdate();
        System.out.println("DEBUG: Message inserted successfully");

        // 3. Get sender name
        String senderName = "Unknown";
        String nameSql = "SELECT full_name FROM users WHERE id=?";
        stmt = conn.prepareStatement(nameSql);
        stmt.setInt(1, senderId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            senderName = rs.getString("full_name");
        }
        System.out.println("DEBUG: Retrieved sender name: " + senderName);

        // 4. Prepare JSON response
        String jsonMessage = String.format(
            "{\"senderId\":%d," +
            "\"groupId\":%d," +
            "\"senderName\":\"%s\"," +
            "\"text\":\"%s\"," +
            "\"timestamp\":\"%s\"}",
            senderId,
            groupId,
            senderName.replace("\"", "\\\""),
            text.replace("\"", "\\\""),
            Instant.now().toString()
        );
        System.out.println("DEBUG: JSON message: " + jsonMessage);

        // 5. Send via WebSocket
        GroupChatEndpoint.sendMessage(groupId, jsonMessage);
        System.out.println("DEBUG: Message sent via WebSocket");
        
        out.print("success");

    } catch(NumberFormatException e) {
        System.out.println("ERROR: Invalid group ID format: " + e.getMessage());
        response.sendError(400, "Invalid group ID");
    } catch(SQLException e) {
        System.out.println("SQL ERROR: " + e.getMessage());
        e.printStackTrace();
        response.sendError(500, "Database error: " + e.getMessage());
    } catch(Exception e) {
        System.out.println("GENERAL ERROR: " + e.getMessage());
        e.printStackTrace();
        response.sendError(500, "Unexpected error: " + e.getMessage());
    } finally {
        DBUtil.close(conn, stmt, rs);
    }
%>