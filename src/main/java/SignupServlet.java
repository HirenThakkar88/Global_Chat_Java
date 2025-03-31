import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/SignupServlet")
public class SignupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public SignupServlet() {
        super();
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String fullName = request.getParameter("full_name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        // 1. Validate Input Fields
        if (fullName == null || fullName.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {

            request.setAttribute("errorMessage", "All fields are required!");
            request.getRequestDispatcher("SignupForm.jsp").forward(request, response);
            return;
        }

        Connection con = null;
        PreparedStatement checkEmailStmt = null;
        PreparedStatement insertUserStmt = null;

        try {
            // 2. Load JDBC Driver
            Class.forName("com.mysql.cj.jdbc.Driver");

            // 3. Establish Connection
            con = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");

            // 4. Check if Email Already Exists
            String checkEmailQuery = "SELECT email FROM users WHERE email = ?";
            checkEmailStmt = con.prepareStatement(checkEmailQuery);
            checkEmailStmt.setString(1, email);
            ResultSet rs = checkEmailStmt.executeQuery();

            if (rs.next()) {
                // ❌ Email already registered
            	
                request.setAttribute("errorMessage", "Email already exists. Please use another email.");
                request.getRequestDispatcher("SignupForm.jsp").forward(request, response);
                return;
            }

            // 5. Insert New User into Database
            String insertUserQuery = "INSERT INTO users (full_name, email, password) VALUES (?, ?, ?)";
            insertUserStmt = con.prepareStatement(insertUserQuery);
            insertUserStmt.setString(1, fullName);
            insertUserStmt.setString(2, email);
            insertUserStmt.setString(3, password); // TODO: Store hashed password instead!

            int rowsAffected = insertUserStmt.executeUpdate();
            if (rowsAffected == 1) {
                // ✅ Successful Registration: Start a session
                HttpSession session = request.getSession();
                session.setMaxInactiveInterval(30 * 60); 
                session.setAttribute("userEmail", email);
                session.setAttribute("userName", fullName);
                session.setAttribute("successMessage", "Signup successful!");
                response.sendRedirect("HomePage.jsp");
            } else {
                request.setAttribute("errorMessage", "Failed to register. Please try again.");
                request.getRequestDispatcher("SignupForm.jsp").forward(request, response);
            }

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Something went wrong. Please try again later.");
            request.getRequestDispatcher("SignupForm.jsp").forward(request, response);
        } finally {
            try {
                if (checkEmailStmt != null) checkEmailStmt.close();
                if (insertUserStmt != null) insertUserStmt.close();
                if (con != null) con.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
