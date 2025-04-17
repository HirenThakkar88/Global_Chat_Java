import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.*;
import java.sql.*;

@WebServlet("/UpdatePasswordServlet")
public class UpdatePasswordServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String newPassword = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        HttpSession session = request.getSession();
        String email = (String) session.getAttribute("resetEmail");
        Connection conn = null;
        
        if(!newPassword.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "Passwords do not match");
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
            return;
        }
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");
            
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE users SET password = ? WHERE email = ?");
            ps.setString(1, newPassword);
            ps.setString(2, email);
            int updated = ps.executeUpdate();
            
            if(updated > 0) {
                session.removeAttribute("resetEmail");
                session.setAttribute("successMessage", "Password reset successfully");
                response.sendRedirect("LoginForm.jsp");
            } else {
                request.setAttribute("errorMessage", "Password update failed");
                request.getRequestDispatcher("reset_password.jsp").forward(request, response);
            }
            
        } catch(Exception e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error updating password");
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
        } finally {
            try { if(conn != null) conn.close(); } catch(SQLException e) {}
        }
    }
}