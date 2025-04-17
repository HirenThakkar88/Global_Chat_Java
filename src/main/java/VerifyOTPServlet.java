import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.*;
import java.sql.*;

@WebServlet("/VerifyOTPServlet")
public class VerifyOTPServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String userOTP = request.getParameter("otp");
        HttpSession session = request.getSession();
        String email = (String) session.getAttribute("resetEmail");
        Connection conn = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");
            
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM otp WHERE email = ? AND otp_code = ? AND created_at >= NOW() - INTERVAL 5 MINUTE");
            ps.setString(1, email);
            ps.setString(2, userOTP);
            ResultSet rs = ps.executeQuery();
            
            if(rs.next()) {
                response.sendRedirect("reset_password.jsp");
            } else {
                request.setAttribute("errorMessage", "Invalid OTP");
                request.getRequestDispatcher("verify_otp.jsp").forward(request, response);
            }
            
        } catch(Exception e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error verifying OTP");
            request.getRequestDispatcher("verify_otp.jsp").forward(request, response);
        } finally {
            try { if(conn != null) conn.close(); } catch(SQLException e) {}
        }
    }
}