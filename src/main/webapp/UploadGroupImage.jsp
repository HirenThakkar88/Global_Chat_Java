<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.io.*, java.util.*, java.sql.*" %>
<%@ page import="utils.DBUtil, websocket.GroupChatEndpoint" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%!
    // Secure filename extraction
    private String getFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return "unknown";
        return Arrays.stream(header.split(";"))
                    .filter(token -> token.trim().startsWith("filename"))
                    .map(token -> token.substring(token.indexOf('=') + 1).trim().replace("\"", ""))
                    .findFirst()
                    .orElse("unknown");
    }
%>

<%
    response.setHeader("X-Error-Msg", "clean-start");
    
    try {
        // Session verification
        Integer senderId = (Integer) session.getAttribute("userId");
        if (senderId == null) {
            response.sendError(401, "Not logged in");
            return;
        }

        // Configure upload directory
        String uploadPath = getServletContext().getRealPath("/images");
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            throw new IOException("Failed to create directory: " + uploadPath);
        }

        // Parse multipart data
        String groupId = null;
        String text = null;
        String imageUrl = null;

        for (Part part : request.getParts()) {
            String partName = part.getName();
            
            if ("groupId".equals(partName)) {
                groupId = readPartValue(part);
            } else if ("text".equals(partName)) {
                text = readPartValue(part);
            } else if ("image".equals(partName) && part.getSize() > 0) {
                String fileName = UUID.randomUUID() + "_" + getFileName(part);
                part.write(uploadPath + File.separator + fileName);
                imageUrl = "images/" + fileName;
            }
        }

        // Validate group ID
        if (groupId == null || !groupId.matches("\\d+")) {
            throw new IllegalArgumentException("Invalid group ID: " + groupId);
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
                        throw new SecurityException("User not in group");
                    }
                }
            }

            // Database insertion
            try (PreparedStatement stmt = conn.prepareStatement(
                    "INSERT INTO messages (sender_id, group_id, text, image, created_at) VALUES (?, ?, ?, ?, ?)")) {
                
                stmt.setInt(1, senderId);
                stmt.setInt(2, groupIdInt);
                stmt.setString(3, text != null ? text : "");
                stmt.setString(4, imageUrl);
                stmt.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
                
                if (stmt.executeUpdate() == 0) {
                    throw new SQLException("Failed to insert message");
                }

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
                    "\"image\":\"%s\"," +
                    "\"timestamp\":\"%s\"}",
                    senderId,
                    groupIdInt,
                    senderName.replace("\"", "\\\""),
                    text != null ? text.replace("\"", "\\\"") : "",
                    imageUrl != null ? imageUrl : "",
                    new Timestamp(System.currentTimeMillis()).toInstant()
                );
                
                GroupChatEndpoint.sendMessage(groupIdInt, json);
                out.print("success");
            }
        }
    } catch (Exception e) {
        response.setHeader("X-Error-Msg", e.getClass().getSimpleName());
        response.sendError(500, "Error: " + e.getMessage());
        e.printStackTrace(System.out);
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