package servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.IOException;
import java.sql.*;
import utils.DBUtil;

@WebServlet("/LeaveGroupServlet")
public class LeaveGroupServlet extends HttpServlet {
	protected void doPost(HttpServletRequest request, HttpServletResponse response) 
	        throws ServletException, IOException {
        
        int userId = (Integer) request.getSession().getAttribute("userId");
        int groupId = Integer.parseInt(request.getParameter("group_id"));
        
        try (Connection conn = DBUtil.getConnection()) {
            // Check if user is admin
            String adminCheck = "SELECT created_by FROM groups WHERE group_id = ?";
            PreparedStatement stmt = conn.prepareStatement(adminCheck);
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next() && rs.getInt("created_by") == userId) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Admins cannot leave their own group");
                return;
            }
            
            // Remove member
            String deleteSql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
            stmt = conn.prepareStatement(deleteSql);
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            stmt.executeUpdate();
            
            response.sendRedirect("GroupList.jsp");
            
        } catch (SQLException e) {
            throw new ServletException("Leave group failed: " + e.getMessage());
        }
    }
	protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
            doPost(request, response);
        }
}