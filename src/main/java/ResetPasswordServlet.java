import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;

import java.io.IOException;
import java.sql.*;
import java.util.Properties;
import java.util.Random;
import jakarta.mail.*;
import jakarta.mail.internet.*;

@WebServlet("/ResetPasswordServlet")
public class ResetPasswordServlet extends HttpServlet {
    
    // Database configuration
    private static final String DB_URL = "jdbc:mysql://localhost:3306/globalchat";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "";
    
    // Email configuration
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";
    private static final String EMAIL_USER = "global.chat2025@gmail.com";
    private static final String EMAIL_PASSWORD = "syol dsto fmky nwwq";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String email = request.getParameter("email").trim();
        Connection conn = null;
        
        try {
            // Validate email format
            if(!isValidEmail(email)) {
                setErrorAndRedirect(request, response, "Invalid email format");
                return;
            }
            
            // Database operations
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            if(!isEmailRegistered(conn, email)) {
                setErrorAndRedirect(request, response, "Email not registered");
                return;
            }
            
            String otp = generateOTP();
            storeOTP(conn, email, otp);
            
            // Send email in background thread
            new Thread(() -> sendEmailWithOTP(email, otp)).start();
            
            // Set session and redirect
            request.getSession().setAttribute("resetEmail", email);
            response.sendRedirect("verify_otp.jsp");
            
        } catch (SQLException | ClassNotFoundException e) {
            handleError(request, response, "Database error: " + e.getMessage());
        } catch (Exception e) {
            handleError(request, response, "System error: " + e.getMessage());
        } finally {
            closeDatabaseConnection(conn);
        }
    }

    private boolean isValidEmail(String email) {
        return email.matches("^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}$");
    }

    private boolean isEmailRegistered(Connection conn, String email) throws SQLException {
        String sql = "SELECT email FROM users WHERE email = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, email);
            return stmt.executeQuery().next();
        }
    }

    private String generateOTP() {
        return String.format("%06d", new Random().nextInt(999999));
    }

    private void storeOTP(Connection conn, String email, String otp) throws SQLException {
        String deleteSQL = "DELETE FROM otp WHERE email = ?";
        String insertSQL = "INSERT INTO otp (email, otp_code) VALUES (?, ?)";
        
        try (PreparedStatement delStmt = conn.prepareStatement(deleteSQL);
             PreparedStatement insStmt = conn.prepareStatement(insertSQL)) {
            
            // Delete existing OTP
            delStmt.setString(1, email);
            delStmt.executeUpdate();
            
            // Insert new OTP
            insStmt.setString(1, email);
            insStmt.setString(2, otp);
            insStmt.executeUpdate();
        }
    }

    private void sendEmailWithOTP(String recipientEmail, String otp) {
        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", SMTP_HOST);
            props.put("mail.smtp.port", SMTP_PORT);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");
            props.put("mail.debug", "true");

            Session session = Session.getInstance(props, new Authenticator() {
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(EMAIL_USER, EMAIL_PASSWORD);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(EMAIL_USER));
            message.addRecipient(Message.RecipientType.TO, new InternetAddress(recipientEmail));
            message.setSubject("Password Reset OTP - GlobalChat");
            message.setText(
                "Your password reset OTP is: " + otp + "\n\n" +
                "This code is valid for 5 minutes.\n" +
                "If you didn't request this, please ignore this email."
            );

            Transport.send(message);
            System.out.println("OTP email successfully sent to " + recipientEmail);
        } catch (AddressException e) {
            System.err.println("Invalid email address: " + recipientEmail);
        } catch (MessagingException e) {
            System.err.println("Email sending failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void setErrorAndRedirect(HttpServletRequest request, HttpServletResponse response, String error) 
            throws ServletException, IOException {
        request.setAttribute("errorMessage", error);
        request.getRequestDispatcher("ForgotPassword.jsp").forward(request, response);
    }

    private void handleError(HttpServletRequest request, HttpServletResponse response, String error) 
            throws ServletException, IOException {
        System.err.println("System Error: " + error);
        request.setAttribute("errorMessage", "A system error occurred. Please try again later.");
        request.getRequestDispatcher("ForgotPassword.jsp").forward(request, response);
    }

    private void closeDatabaseConnection(Connection conn) {
        try {
            if (conn != null && !conn.isClosed()) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error closing database connection: " + e.getMessage());
        }
    }

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError("MySQL JDBC Driver not found");
        }
    }
}