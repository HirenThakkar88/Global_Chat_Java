<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, utils.DBUtil, java.util.ArrayList, java.util.List" %>
<%
Integer loggedInUserId = (Integer) session.getAttribute("userId");
int groupId = Integer.parseInt(request.getParameter("group_id"));

try (Connection conn = DBUtil.getConnection()) {
    // Verify admin rights
    String adminCheck = "SELECT created_by FROM groups WHERE group_id = ?";
    PreparedStatement stmt = conn.prepareStatement(adminCheck);
    stmt.setInt(1, groupId);
    ResultSet rs = stmt.executeQuery();
    
    if (!rs.next() || rs.getInt("created_by") != loggedInUserId) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Not authorized");
        return;
    }

    // Get current members (excluding admin)
    String sql = "SELECT u.id, u.full_name, u.profile_pic FROM users u " +
                "JOIN group_members gm ON u.id = gm.user_id " +
                "WHERE gm.group_id = ? AND u.id != ?";
    stmt = conn.prepareStatement(sql);
    stmt.setInt(1, groupId);
    stmt.setInt(2, loggedInUserId);
    rs = stmt.executeQuery();
    
    List<String> members = new ArrayList<>();
    while(rs.next()) {
        members.add(rs.getInt("id") + ":" + 
                   rs.getString("full_name") + ":" + 
                   rs.getString("profile_pic"));
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Remove Members</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .user-item:hover {
            background-color: #f3f4f6;
        }
        .navbar-space {
            height: 10px;
            margin-top: 0;
        }
    </style>
    <script>
    function searchUsers() {
        const input = document.getElementById('userSearch').value.toLowerCase();
        const userList = document.getElementById('userList').children;
        
        for(let user of userList) {
            const name = user.querySelector('.user-name').textContent.toLowerCase();
            user.style.display = name.includes(input) ? 'flex' : 'none';
        }
    }
    </script>
</head>
<body class="bg-base-100">
<div class="navbar-container">
    <jsp:include page="Navbar.jsp" />
</div>
<div class="navbar-space"></div>

<div class="container min-h-screen p-4 bg-base-100">
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
        <h1 class="text-2xl font-bold mb-4">Remove Members from Group</h1>
        
        <form action="RemoveMemberServlet" method="post">
            <input type="hidden" name="group_id" value="<%= groupId %>">
            
            <div class="mb-4">
                <div class="flex justify-between items-center mb-2">
                    <label class="block text-gray-700">Search Members</label>
                    <input type="text" id="userSearch" placeholder="Search members..." 
                           class="bg-base-100 p-2 border rounded w-48 focus:outline-none focus:ring-2 focus:ring-blue-500"
                           onkeyup="searchUsers()">
                </div>
                
                <div id="userList" class="border rounded-lg p-2 h-64 overflow-y-auto">
                    <% for(String member : members) { 
                        String[] parts = member.split(":");
                        int userId = Integer.parseInt(parts[0]);
                        String fullName = parts[1];
                        String profilePic = parts.length > 2 ? parts[2] : "";
                        
                        if (profilePic == null || profilePic.trim().isEmpty()) {
                            profilePic = "images/default-profile.png";
                        } else if (!profilePic.startsWith("http") && !profilePic.startsWith("/") &&  !profilePic.startsWith("images/")) {
                            profilePic = "images/" + profilePic;
                        }
                    %>
                    <label class="user-item flex items-center justify-between p-3 rounded-lg cursor-pointer transition-colors">
                        <div class="flex items-center space-x-3">
                            <img src="<%= profilePic %>" alt="Profile" 
                                 class="w-10 h-10 rounded-full object-cover border border-gray-200">
                            <span class="user-name font-medium text-gray-700"><%= fullName %></span>
                        </div>
                        <input type="checkbox" name="members" value="<%= userId %>"
                               class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                    </label>
                    <% } %>
                </div>
            </div>
            
            <button type="submit" 
                    class="w-full bg-neutral text-neutral-content px-4 py-2 rounded-lg hover:bg-red-600 transition-colors">
                Remove Selected Members
            </button>
        </form>
    </div>
</div>

<script>
    var ws;

    function connectWebSocket() {
        ws = new WebSocket("ws://localhost:8080/Global_Chat_Java/status");

        ws.onopen = function() {
            console.log("WebSocket connected from Remove Member Page");
            ws.send("login:<%= loggedInUserId %>");
        };

        ws.onclose = function() {
            console.log("WebSocket disconnected");
        };

        ws.onerror = function(event) {
            console.error("WebSocket error:", event);
        };

        setInterval(function() {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send("keep-alive");
            }
        }, 30000);
    }

    window.onload = function() {
        connectWebSocket();
    };
</script>

</body>
</html>
<%
} catch (SQLException e) {
    throw new ServletException("Database error: " + e.getMessage());
}
%>