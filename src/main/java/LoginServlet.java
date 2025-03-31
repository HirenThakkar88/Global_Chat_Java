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

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public LoginServlet() {
        super();
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        try {
            // Load the JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");

            // Establish connection
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");

            // Prepare SQL Query to fetch user details
            String query = "SELECT id, full_name, password FROM users WHERE email = ?";
            PreparedStatement stmt = con.prepareStatement(query);
            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                int userId = rs.getInt("id"); // Fetch user ID
                String storedPassword = rs.getString("password");
                String fullName = rs.getString("full_name");

                if (storedPassword.equals(password)) {
                    // ✅ Successful login: Create session and store user details
                    HttpSession session = request.getSession();
                    session.setAttribute("userId", userId);  // Store user ID
                    session.setAttribute("userEmail", email);
                    session.setAttribute("userName", fullName);
                    session.setAttribute("successMessage", "Login successful!"); // Toast message

                    response.sendRedirect("HomePage.jsp"); // Redirect to home page
                } else {
                    // ❌ Incorrect password
                    request.setAttribute("errorMessage", "Invalid password. Please try again.");
                    request.getRequestDispatcher("LoginForm.jsp").forward(request, response);
                }
            } else {
                // ❌ Email not found
                request.setAttribute("errorMessage", "Invalid credentials. Please try again.");
                request.getRequestDispatcher("LoginForm.jsp").forward(request, response);
            }

            // Close resources
            rs.close();
            stmt.close();
            con.close();

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Something went wrong. Please try again later.");
            request.getRequestDispatcher("LoginForm.jsp").forward(request, response);
        }
    }
}
