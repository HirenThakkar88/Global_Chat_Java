package servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.IOException;
import java.sql.*;
import utils.DBUtil;

@WebServlet("/DeleteGroupServlet")
public class DeleteGroupServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
        
        int userId = (Integer) request.getSession().getAttribute("userId");
        int groupId = Integer.parseInt(request.getParameter("group_id"));
        
        try (Connection conn = DBUtil.getConnection()) {
            // Verify ownership
            String checkSql = "SELECT group_id FROM groups WHERE group_id = ? AND created_by = ?";
            PreparedStatement stmt = conn.prepareStatement(checkSql);
            stmt.setInt(1, groupId);
            stmt.setInt(2, userId);
            
            ResultSet rs = stmt.executeQuery();
            if (!rs.next()) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Not authorized");
                return;
            }
            
            // Delete group
            String deleteSql = "DELETE FROM groups WHERE group_id = ?";
            stmt = conn.prepareStatement(deleteSql);
            stmt.setInt(1, groupId);
            stmt.executeUpdate();
            
            response.sendRedirect("GroupList.jsp");
            
        } catch (SQLException e) {
            throw new ServletException("Delete group failed: " + e.getMessage());
        }
    }
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
            doPost(request, response);
        }
}
