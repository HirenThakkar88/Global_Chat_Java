<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, utils.DBUtil, java.util.List, java.util.ArrayList" %>
<%@ page import="java.net.URLEncoder" %>

<%
// Security check and initialization
Integer loggedInUserId = (Integer) session.getAttribute("userId");
if (loggedInUserId == null) {
    response.sendRedirect("LoginForm.jsp");
    return;
}

List<String> groups = new ArrayList<>(); // Initialize empty list

try {
    // Database operation
    Connection conn = DBUtil.getConnection();
    String sql = "SELECT g.group_id, g.group_name FROM groups g " +
                 "JOIN group_members gm ON g.group_id = gm.group_id " +
                 "WHERE gm.user_id = ?";
    PreparedStatement stmt = conn.prepareStatement(sql);
    stmt.setInt(1, loggedInUserId);
    ResultSet rs = stmt.executeQuery();
    
    while(rs.next()) {
        groups.add(rs.getInt("group_id") + ":" + rs.getString("group_name"));
    }
    DBUtil.close(conn, stmt, rs);
} catch (SQLException e) {
    out.println("<div class='text-red-500 p-4'>Error loading groups: " + e.getMessage() + "</div>");
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>Your Groups</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .navbar-space { height: 70px; }
        .group-card:hover { transform: translateY(-2px); }
    </style>
</head>
<body class="min-h-screen bg-base-100">
<div class="navbar-container">
    <jsp:include page="Navbar.jsp" />
</div>
<div class="navbar-space"></div>

<div class="container mx-auto px-4 py-8">
    <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold ">
                <i class="fas fa-users  mr-2 "></i>
                Your Groups
            </h1>
            <a href="CreateGroup.jsp" 
               class="bg-primary hover:bg-primary-focus text-primary-content px-4 py-2 rounded-lg transition-all">
                <i class="fas fa-plus mr-2"></i>Create Group
            </a>
        </div>

        <!-- Groups List -->
        <% if(groups.isEmpty()) { %>
            <div class="text-center p-8 bg-primary rounded-lg">
                <i class="fas fa-comments text-4xl  mb-4"></i>
                <p class="text-primary-content">You haven't joined any groups yet!</p>
            </div>
        <% } else { %>
            <div class="grid gap-4 md:grid-cols-2">
                <% for(String group : groups) { 
                    String[] parts = group.split(":");
                    int groupId = Integer.parseInt(parts[0]);
                    String groupName = parts[1];
                %>
                <a href="GroupChatPage.jsp?groupId=<%= groupId %>&groupName=<%= URLEncoder.encode(groupName, "UTF-8") %>"
                   class="group-card bg-primary p-4 rounded-xl shadow-sm hover:shadow-md transition-all">
                    <div class="flex items-center space-x-4">
                        <div class="bg-blue-100 p-3 rounded-lg bg-primary">
                            <i class="fas fa-users text-primary-content text-xl"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-primary-content"><%= groupName %></h3>
                            <p class="text-sm text-primary-content">Active now</p>
                        </div>
                    </div>
                </a>
                <% } %>
            </div>
        <% } %>
    </div>
</div>
<script>
        var ws;

        function connectWebSocket() {
            ws = new WebSocket("ws://localhost:8080/Global_Chat_Java/status"); // Change to your WebSocket URL

            ws.onopen = function() {
                console.log("WebSocket connected from group list Page");
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