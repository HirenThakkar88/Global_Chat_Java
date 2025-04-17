package servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.IOException;
import java.sql.*;
import utils.DBUtil;

@WebServlet("/CreateGroupServlet")
public class CreateGroupServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        int userId = (Integer) request.getSession().getAttribute("userId");
        String groupName = request.getParameter("groupName");
        String[] members = request.getParameterValues("members");
        
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);
            
            // Create group
            String groupSql = "INSERT INTO groups (group_name, created_by) VALUES (?, ?)";
            stmt = conn.prepareStatement(groupSql, Statement.RETURN_GENERATED_KEYS);
            stmt.setString(1, groupName);
            stmt.setInt(2, userId);
            stmt.executeUpdate();
            
            ResultSet generatedKeys = stmt.getGeneratedKeys();
            int groupId = generatedKeys.next() ? generatedKeys.getInt(1) : -1;
            
            // Add members
            String memberSql = "INSERT INTO group_members (group_id, user_id) VALUES (?, ?)";
            stmt = conn.prepareStatement(memberSql);
            
            // Add creator as member
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            stmt.executeUpdate();
            
            // Add selected members
            if(members != null) {
                for(String memberId : members) {
                    stmt.setInt(1, groupId);
                    stmt.setInt(2, Integer.parseInt(memberId));
                    stmt.executeUpdate();
                }
            }
            
            conn.commit();
            response.sendRedirect("GroupChatPage.jsp?groupId=" + groupId + "&groupName=" + 
                java.net.URLEncoder.encode(groupName, "UTF-8"));
            
        } catch (SQLException e) {
            try { conn.rollback(); } catch (SQLException ex) {}
            throw new ServletException("Database error: " + e.getMessage());
        } finally {
            DBUtil.close(conn, stmt, rs);
        }
    }
}