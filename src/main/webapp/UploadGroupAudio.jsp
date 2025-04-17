<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.io.*, java.util.*, java.sql.*" %>
<%@ page import="utils.DBUtil, websocket.GroupChatEndpoint" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%!
    private String getFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return null;
        String[] tokens = header.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return null;
    }
%>

<%
    try {
        Integer senderId = (Integer) session.getAttribute("userId");
        if (senderId == null) throw new Exception("Not authenticated");

        String uploadPath = getServletContext().getRealPath("/audio");
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) uploadDir.mkdirs();

        String groupId = null;
        String text = null;
        String audioUrl = null;

        for (Part part : request.getParts()) {
            String partName = part.getName();
            
            if ("groupId".equals(partName)) {
                groupId = readPartValue(part);
            } else if ("text".equals(partName)) {
                text = readPartValue(part);
            } else if ("audio".equals(partName) && part.getSize() > 0) {
                String fileName = UUID.randomUUID() + "_" + getFileName(part);
                part.write(uploadPath + File.separator + fileName);
                audioUrl = "audio/" + fileName;
            }
        }

        // Validate group ID
        if (groupId == null || !groupId.matches("\\d+")) {
            throw new Exception("Invalid group ID");
        }
        int groupIdInt = Integer.parseInt(groupId);

        try (Connection conn = DBUtil.getConnection()) {
            // Verify group membership
            try (PreparedStatement checkStmt = conn.prepareStatement(
                    "SELECT 1 FROM group_members WHERE group_id=? AND user_id=?")) {
                checkStmt.setInt(1, groupIdInt);
                checkStmt.setInt(2, senderId);
                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (!rs.next()) {
                        throw new Exception("User not in group");
                    }
                }
            }

            // Insert message with group_id
            try (PreparedStatement stmt = conn.prepareStatement(
                    "INSERT INTO messages (sender_id, group_id, text, audio, created_at) VALUES (?, ?, ?, ?, ?)")) {
                
                stmt.setInt(1, senderId);
                stmt.setInt(2, groupIdInt);
                stmt.setString(3, text != null ? text : "");
                stmt.setString(4, audioUrl);
                stmt.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
                
                if (stmt.executeUpdate() > 0) {
                    // Get sender name
                    String senderName = "User";
                    try (PreparedStatement nameStmt = conn.prepareStatement(
                            "SELECT full_name FROM users WHERE id=?")) {
                        nameStmt.setInt(1, senderId);
                        try (ResultSet rs = nameStmt.executeQuery()) {
                            if (rs.next()) {
                                senderName = rs.getString("full_name");
                            }
                        }
                    }

                    // Prepare WebSocket message
                    String json = String.format(
                        "{\"senderId\":%d," +
                        "\"groupId\":%d," +
                        "\"senderName\":\"%s\"," +
                        "\"text\":\"%s\"," +
                        "\"audio\":\"%s\"," +
                        "\"timestamp\":\"%s\"}",
                        senderId,
                        groupIdInt,
                        senderName.replace("\"", "\\\""),
                        text != null ? text.replace("\"", "\\\"") : "",
                        audioUrl != null ? audioUrl : "",
                        new Timestamp(System.currentTimeMillis()).toInstant()
                    );
                    
                    GroupChatEndpoint.sendMessage(groupIdInt, json);
                    out.print("success");
                }
            }
        }
    } catch (Exception e) {
        response.sendError(500, "Error: " + e.getMessage());
        e.printStackTrace();
    }
%>

<%!
    private String readPartValue(Part part) throws IOException {
        try (InputStream is = part.getInputStream();
             ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[1024];
            int len;
            while ((len = is.read(buffer)) != -1) {
                os.write(buffer, 0, len);
            }
            return os.toString("UTF-8");
        }
    }
%>