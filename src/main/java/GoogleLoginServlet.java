import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.net.URLEncoder;
import java.sql.*;
import java.util.Base64;
import java.util.regex.*;

@WebServlet("/GoogleLogin")
public class GoogleLoginServlet extends HttpServlet {
    private static final String CLIENT_ID = "994421752501-qnms9c822gvoe2dg4fah0fb3ge4ej6il.apps.googleusercontent.com";
    private static final String DB_URL = "jdbc:mysql://localhost:3306/globalchat?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";

    static {
        try {
            // Explicitly load MySQL driver
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL JDBC Driver not found", e);
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        doGet(request, response);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String credential = request.getParameter("credential");
        if (credential == null || credential.isEmpty()) {
            response.sendRedirect("LoginForm.jsp?error=Missing Google credential");
            return;
        }

        try {
            // Basic JWT validation
            String[] jwtParts = credential.split("\\.");
            String payload = new String(Base64.getUrlDecoder().decode(jwtParts[1]));
            
            if (!payload.contains("\"aud\":\"" + CLIENT_ID + "\"") || 
                !payload.contains("\"iss\":\"https://accounts.google.com\"")) {
                response.sendRedirect("LoginForm.jsp?error=Invalid token");
                return;
            }

            String email = extractValue(payload, "email");
            String name = extractValue(payload, "name");

            // Database operations
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
                int userId = findOrCreateUser(conn, email, name);
                
                HttpSession session = request.getSession();
                session.setAttribute("userId", userId);
                session.setAttribute("userEmail", email);
                session.setAttribute("userName", name);
                
                response.sendRedirect("HomePage.jsp");
            }

        } catch (Exception e) {
            response.sendRedirect("LoginForm.jsp?error=" + URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private String extractValue(String payload, String key) {
        Matcher matcher = Pattern.compile("\"" + key + "\":\"([^\"]+)\"").matcher(payload);
        return matcher.find() ? matcher.group(1) : "Unknown";
    }

    private int findOrCreateUser(Connection conn, String email, String name) throws SQLException {
        // Check existing user
        try (PreparedStatement stmt = conn.prepareStatement(
            "SELECT id FROM users WHERE email = ?")) {
            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) return rs.getInt("id");
        }

        // Create new user
        try (PreparedStatement stmt = conn.prepareStatement(
            "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)", 
            Statement.RETURN_GENERATED_KEYS)) {
            
            stmt.setString(1, name);
            stmt.setString(2, email);
            stmt.setString(3, email); // Password = email
            stmt.executeUpdate();

            try (ResultSet rs = stmt.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
            throw new SQLException("User creation failed");
        }
    }
}