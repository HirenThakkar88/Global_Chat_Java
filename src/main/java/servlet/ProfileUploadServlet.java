package servlet;
import utils.DBUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@MultipartConfig
public class ProfileUploadServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        String username = (String) session.getAttribute("userEmail");

        Part filePart = request.getPart("profilePic");
        String fileName = username + "_" + System.currentTimeMillis() + ".png";
        String uploadPath = getServletContext().getRealPath("/images") + File.separator + fileName;

        // Save image to server directory
        try (InputStream input = filePart.getInputStream();
             FileOutputStream output = new FileOutputStream(uploadPath)) {
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = input.read(buffer)) != -1) {
                output.write(buffer, 0, bytesRead);
            }
        }

        // Update profile picture in the database
        try (Connection conn = DBUtil.getConnection()) {
            PreparedStatement stmt = conn.prepareStatement("UPDATE users SET profile_pic = ? WHERE email = ?");
            stmt.setString(1, fileName);
            stmt.setString(2, username);
            int rowsUpdated = stmt.executeUpdate();

            if (rowsUpdated > 0) {
                // Update session with new profile picture
                session.setAttribute("profilePic", "images/" + fileName);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        response.sendRedirect("profile.jsp"); // Redirect back to Profile Page
    }
}
