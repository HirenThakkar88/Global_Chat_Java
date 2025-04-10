<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.io.*, java.util.*, java.sql.*" %>
<%@ page import="utils.DBUtil, websocket.ChatEndpoint" %>
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
    response.setHeader("X-Error-Msg", "clean-start"); // Debug header
    
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
        String receiverId = null;
        String text = null;
        String imageUrl = null;

        for (Part part : request.getParts()) {
            String partName = part.getName();
            
            if ("receiverId".equals(partName)) {
                receiverId = readPartValue(part);
            } else if ("text".equals(partName)) {
                text = readPartValue(part);
            } else if ("image".equals(partName) && part.getSize() > 0) {
                String fileName = UUID.randomUUID() + "_" + getFileName(part);
                part.write(uploadPath + File.separator + fileName);
                imageUrl = "images/" + fileName;
            }
        }

        // Validate receiver ID
        if (receiverId == null || !receiverId.matches("\\d+")) {
            throw new IllegalArgumentException("Invalid receiver ID: " + receiverId);
        }

        // Database insertion
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                 "INSERT INTO messages (sender_id, receiver_id, text, image, created_at) VALUES (?, ?, ?, ?, ?)")) {
            
            stmt.setInt(1, senderId);
            stmt.setInt(2, Integer.parseInt(receiverId));
            stmt.setString(3, text != null ? text : "");
            stmt.setString(4, imageUrl);
            stmt.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
            
            if (stmt.executeUpdate() == 0) {
                throw new SQLException("Failed to insert message");
            }

            // Prepare WebSocket message
            String json = String.format(
                "{\"senderId\":%d,\"receiverId\":%d,\"text\":\"%s\",\"image\":\"%s\",\"timestamp\":\"%s\"}",
                senderId,
                Integer.parseInt(receiverId),
                text != null ? text.replace("\"", "\\\"") : "",
                imageUrl != null ? imageUrl : "",
                new Timestamp(System.currentTimeMillis()).toInstant()
            );
            
            ChatEndpoint.sendMessage(senderId, Integer.parseInt(receiverId), json);
            out.print("success");
        }
    } catch (Exception e) {
        response.setHeader("X-Error-Msg", e.getClass().getSimpleName()); // Debug header
        response.sendError(500, "Error: " + e.getMessage());
        e.printStackTrace(System.out); // Critical: Print to Tomcat console
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