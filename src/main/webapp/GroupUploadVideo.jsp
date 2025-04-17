<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.io.*, java.util.*, java.sql.*" %>
<%@ page import="utils.DBUtil, websocket.GroupChatEndpoint" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%!
    private boolean isValidVideo(Part part) {
        String contentType = part.getContentType();
        String fileName = getFileName(part).toLowerCase();
        return contentType != null && 
               contentType.startsWith("video/") &&
               fileName.endsWith(".mp4");
    }

    private String getFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return "";
        return Arrays.stream(header.split(";"))
                    .filter(t -> t.trim().startsWith("filename"))
                    .findFirst()
                    .map(t -> t.substring(t.indexOf('=')+1).trim().replace("\"", ""))
                    .orElse("");
    }
%>

<%
    try {
        Integer senderId = (Integer) session.getAttribute("userId");
        if (senderId == null) {
            response.sendError(401, "Authentication required");
            return;
        }

        String uploadPath = getServletContext().getRealPath("/videos");
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            response.sendError(500, "Couldn't create video directory");
            return;
        }

        String groupId = null;
        String text = null;
        String videoUrl = null;

        for (Part part : request.getParts()) {
            String partName = part.getName();
            
            if ("groupId".equals(partName)) {
                groupId = readPartValue(part);
            } else if ("text".equals(partName)) {
                text = readPartValue(part);
            } else if ("video".equals(partName) && part.getSize() > 0) {
                if (!isValidVideo(part)) {
                    response.sendError(400, "Only MP4 videos are allowed");
                    return;
                }
                String fileName = UUID.randomUUID() + ".mp4";
                part.write(uploadPath + File.separator + fileName);
                videoUrl = "videos/" + fileName;
            }
        }

        // Validate group ID
        if (groupId == null || !groupId.matches("\\d+")) {
            response.sendError(400, "Invalid group ID format");
            return;
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
                        response.sendError(403, "User not in group");
                        return;
                    }
                }
            }

            // Database insertion
            try (PreparedStatement stmt = conn.prepareStatement(
                    "INSERT INTO messages (sender_id, group_id, text, video, created_at) " +
                    "VALUES (?, ?, ?, ?, ?)")) {
                
                stmt.setInt(1, senderId);
                stmt.setInt(2, groupIdInt);
                stmt.setString(3, text != null ? text : "");
                stmt.setString(4, videoUrl);
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
                    "\"video\":\"%s\"," +
                    "\"timestamp\":\"%s\"}",
                    senderId,
                    groupIdInt,
                    senderName.replace("\"", "\\\""),
                    text != null ? text.replace("\"", "\\\"") : "",
                    videoUrl != null ? videoUrl : "",
                    new Timestamp(System.currentTimeMillis()).toInstant()
                );
                
                GroupChatEndpoint.sendMessage(groupIdInt, json);
                out.print("success");
            }
        }
    } catch (Exception e) {
        response.sendError(500, "Video Error: " + e.getMessage());
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