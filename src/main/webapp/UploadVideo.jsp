<%@ page import="jakarta.servlet.http.Part" %>
<%@ page import="java.io.*, java.util.*, java.sql.*" %>
<%@ page import="utils.DBUtil, websocket.ChatEndpoint" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%!
    private boolean isValidVideo(Part part) {
        String contentType = part.getContentType();
        String fileName = getFileName(part);
        return contentType != null && 
               contentType.startsWith("video/") &&
               fileName.toLowerCase().endsWith(".mp4");
    }

    private String getFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return null;
        for (String token : header.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1)
                          .trim().replace("\"", "");
            }
        }
        return null;
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

        String receiverId = null;
        String text = null;
        String videoUrl = null;

        for (Part part : request.getParts()) {
            String partName = part.getName();
            
            if ("receiverId".equals(partName)) {
                receiverId = readPartValue(part);
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

        // Validate and store in database
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                 "INSERT INTO messages (sender_id, receiver_id, text, video, created_at) " +
                 "VALUES (?, ?, ?, ?, ?)")) {
            
            stmt.setInt(1, senderId);
            stmt.setInt(2, Integer.parseInt(receiverId));
            stmt.setString(3, text != null ? text : "");
            stmt.setString(4, videoUrl);
            stmt.setTimestamp(5, new Timestamp(System.currentTimeMillis()));
            
            if (stmt.executeUpdate() > 0) {
                String json = String.format(
                    "{\"senderId\":%d,\"receiverId\":%d,\"text\":\"%s\",\"video\":\"%s\",\"timestamp\":\"%s\"}",
                    senderId,
                    Integer.parseInt(receiverId),
                    text != null ? text.replace("\"", "\\\"") : "",
                    videoUrl != null ? videoUrl : "",
                    new Timestamp(System.currentTimeMillis()).toInstant()
                );
                ChatEndpoint.sendMessage(senderId, Integer.parseInt(receiverId), json);
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