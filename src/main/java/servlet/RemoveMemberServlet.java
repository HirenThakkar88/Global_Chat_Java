package servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.IOException;
import java.sql.*;
import utils.DBUtil;

@WebServlet("/RemoveMemberServlet")
public class RemoveMemberServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        int userId = (Integer) request.getSession().getAttribute("userId");
        int groupId = Integer.parseInt(request.getParameter("group_id"));
        String[] members = request.getParameterValues("members");
        
        try (Connection conn = DBUtil.getConnection()) {
            // Verify admin rights
            String adminCheck = "SELECT created_by FROM groups WHERE group_id = ?";
            PreparedStatement stmt = conn.prepareStatement(adminCheck);
            stmt.setInt(1, groupId);
            ResultSet rs = stmt.executeQuery();
            
            if (!rs.next() || rs.getInt("created_by") != userId) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Not authorized");
                return;
            }
            
            // Remove members
            String sql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
            stmt = conn.prepareStatement(sql);
            
            for (String memberId : members) {
                stmt.setInt(1, groupId);
                stmt.setInt(2, Integer.parseInt(memberId));
                stmt.executeUpdate();
            }
            
            response.sendRedirect("GroupChatPage.jsp?groupId=" + groupId);
            
        } catch (SQLException e) {
            throw new ServletException("Remove member failed: " + e.getMessage());
        }
    }
}