package utils;

import java.sql.*;

public class DBUtil {
    private static final String URL = "jdbc:mysql://localhost:3306/globalchat";
    private static final String USER = "root";
    private static final String PASSWORD = "";

    public static Connection getConnection() {
        Connection conn = null;
        try {
            // 1. Load the JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("✅ MySQL Driver loaded successfully.");

            // 2. Establish the connection
            conn = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("✅ Database connected successfully.");
        } catch (ClassNotFoundException e) {
            System.err.println("❌ Error loading MySQL Driver: " + e.getMessage());
        } catch (SQLException e) {
            System.err.println("❌ Error connecting to Database: " + e.getMessage());
        }
        return conn; // May return null if connection fails
    }

    // Method to close resources safely
    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        try {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
            System.out.println("✅ Database resources closed.");
        } catch (SQLException e) {
            System.err.println("❌ Error closing resources: " + e.getMessage());
        }
    }
}
