<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, utils.DBUtil" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>

<%
Integer loggedInUserId = (Integer) session.getAttribute("userId");
if (loggedInUserId == null) {
    response.sendRedirect("LoginForm.jsp");
    return;
}

List<String> errors = new ArrayList<>();
List<String> users = new ArrayList<>();

try {
    Connection conn = DBUtil.getConnection();
    String sql = "SELECT id, full_name, profile_pic FROM users WHERE id != ?";
    PreparedStatement stmt = conn.prepareStatement(sql);
    stmt.setInt(1, loggedInUserId);
    ResultSet rs = stmt.executeQuery();
    
    while(rs.next()) {
        users.add(rs.getInt("id") + ":" + rs.getString("full_name") + ":" + rs.getString("profile_pic"));
    }
    DBUtil.close(conn, stmt, rs);
} catch (SQLException e) {
    errors.add("Error loading users: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Create Group</title>
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
            <h1 class="text-2xl font-bold mb-4">Create New Group</h1>
            
            <form action="CreateGroupServlet" method="post">
                <div class="mb-4">
                    <label class="block text-gray-700 mb-2 bg-r">Group Name</label>
                    <input type="text" name="groupName" required 
                           class="bg-base-100 w-full p-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500">
                </div>
                
                <div class="mb-4">
                    <div class="flex justify-between items-center mb-2">
                        <label class="block text-gray-700">Add Members</label>
                        <input type="text" id="userSearch" placeholder="Search users..." 
                               class=" bg-base-100 p-2 border rounded w-48 focus:outline-none focus:ring-2 focus:ring-blue-500"
                               onkeyup="searchUsers()">
                    </div>
                    <div id="userList" class="border rounded-lg p-2 h-64 overflow-y-auto">
                        <% for(String user : users) { 
                            String[] parts = user.split(":");
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
                        class="w-full bg-base-100 text-white px-4 py-2 rounded-lg hover:bg-black transition-colors">
                    Create Group
                </button>
            </form>
        </div>
    </div>
    <script>
        var ws;

        function connectWebSocket() {
            ws = new WebSocket("ws://localhost:8080/Global_Chat_Java/status"); // Change to your WebSocket URL

            ws.onopen = function() {
                console.log("WebSocket connected from Profile Page");
                ws.send("login:<%= loggedInUserId %>"); // Keep user online
            };

            ws.onclose = function() {
                console.log("WebSocket disconnected from Profile Page");
            };

            ws.onerror = function(event) {
                console.error("WebSocket error observed:", event);
            };

            // Keep sending a keep-alive signal every 30 seconds
            setInterval(function() {
                if (ws.readyState === WebSocket.OPEN) {
                    ws.send("keep-alive");
                }
            }, 30000);
        }

        window.onload = function() {
            connectWebSocket();
        };

        function triggerFileInput() {
            document.getElementById("profilePicInput").click();
        }

        function refreshPage() {
            setTimeout(() => { window.location.reload(); }, 500);
        }
    </script>
    
</body>
</html>