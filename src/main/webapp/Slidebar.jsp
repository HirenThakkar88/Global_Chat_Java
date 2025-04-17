<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="utils.DBUtil" %>

<%
    Integer loggedInUserId = (Integer) session.getAttribute("userId");
    if (loggedInUserId == null) {
        response.sendRedirect("LoginForm.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            font-family: 'Noto Sans', sans-serif !important;
        }
        .sidebar {
            height: 100vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        .menu {
            max-height: 200px;
            overflow-y: auto;
        }
        #contactList {
            max-height: calc(100vh - 300px);
            overflow-y: auto;
        }
        .dropdown-container {
            position: relative;
            display: inline-block;
        }
        .dropdown-menu {
            display: none;
            position: absolute;
            right: 0;
            top: 100%;
            
            border: 1px solid #e5e7eb;
            border-radius: 0.5rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            min-width: 160px;
            z-index: 10;
            margin-top: 0.5rem;
        }
        .dropdown-menu.show {
            display: block;
        }
        .dropdown-item {
            padding: 0.5rem 1rem;
            cursor: pointer;
            
            font-size: 0.875rem;
        }
        .dropdown-item:hover {
            background-color: #f3f4f6;
        }
        .icon-btn {
            padding: 0.5rem;
            border-radius: 0.5rem;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            background: none;
            border: none;
        }
        .icon-btn:hover {
            background-color: #f3f4f6;
        }
    </style>
</head>
<body class="min-h-screen bg-base-100">
    <!-- Sidebar -->
    <div class="w-1/4 bg-transparent shadow-lg p-4 sidebar">
        <h2 class="text-lg font-semibold mb-4">Contacts</h2>

        <!-- Search and Menu -->
        <div class="flex items-center my-4 space-x-2">
            <input type="text" id="search" onkeyup="filterContacts()" placeholder="Search" class="p-2 border rounded-lg w-full bg-transparent">
            <div class="dropdown-container">
                <button class="icon-btn" onclick="toggleMenu()">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h.01M12 12h.01M19 12h.01" />
                    </svg>
                </button>
                <div id="actionMenu" class="dropdown-menu">
                   <div class="dropdown-item" onclick="window.location.href='CreateGroup.jsp'">Create Group</div>
<div class="dropdown-item" onclick="window.location.href='GroupList.jsp'">Your Groups</div>
                </div>
            </div>
        </div>

        <!-- Online Filter -->
        <label class="flex items-center space-x-2 mb-4">
            <input type="checkbox" id="onlineOnly" onchange="filterContacts()">
            <span>Show online only</span>
        </label>

        <!-- Contact List -->
        <div id="contactList" class="space-y-4">
            <%
                Connection conn = null;
                PreparedStatement stmt = null;
                ResultSet rs = null;

                try {
                    conn = DBUtil.getConnection();
                    String sql = "SELECT id, full_name, profile_pic, is_online FROM users WHERE id <> ? ORDER BY full_name";
                    stmt = conn.prepareStatement(sql);
                    stmt.setInt(1, loggedInUserId);
                    rs = stmt.executeQuery();

                    while (rs.next()) {
                        int userId = rs.getInt("id");
                        String fullName = rs.getString("full_name");
                        String profilePic = rs.getString("profile_pic");
                        boolean isOnline = rs.getBoolean("is_online");

                        if (profilePic == null || profilePic.trim().isEmpty() || profilePic.equals("images/default-profile.png")) {
                            profilePic = "images/default-profile.png";
                        } else if (!profilePic.startsWith("http") && !profilePic.startsWith("/")) {
                            profilePic = "images/" + profilePic;
                        }
            %>
            <div class="contact-item flex items-center space-x-3 cursor-pointer" 
                id="contact-<%= userId %>"
                data-userid="<%= userId %>"
                data-online="<%= isOnline %>"
                onclick="location.href='ChatPage.jsp?userId=<%= userId %>&user=<%= java.net.URLEncoder.encode(fullName, "UTF-8") %>&profile=<%= java.net.URLEncoder.encode(profilePic, "UTF-8") %>&status=<%= isOnline ? "Online" : "Offline" %>'">
                
                <img src="<%= profilePic %>" alt="User" class="w-10 h-10 rounded-full border border-gray-300">
                <div>
                    <p class="font-semibold"><%= fullName %></p>
                    <p id="status-<%= userId %>" class="text-sm <%= isOnline ? "text-green-500" : "text-gray-500" %>">
                        <%= isOnline ? "Online" : "Offline" %>
                    </p>
                </div>
            </div>
            <%
                    }
                } catch (SQLException e) {
                    out.println("<p>Error loading contacts: " + e.getMessage() + "</p>");
                } finally {
                    DBUtil.close(conn, stmt, rs);
                }
            %>
        </div>
    </div>

    <script>
        // Dropdown Menu Functions
        function toggleMenu() {
            const menu = document.getElementById('actionMenu');
            menu.classList.toggle('show');
        }

        function handleMenuClick(action) {
            switch(action) {
                case 'createGroup':
                    window.location.href = 'CreateGroup.jsp';
                    break;
                case 'yourGroups':
                    window.location.href = 'GroupList.jsp';
                    break;
            }
            toggleMenu();
        }

        document.addEventListener('click', function(event) {
            const menu = document.getElementById('actionMenu');
            const button = document.querySelector('.dropdown-container button');
            if (!button.contains(event.target) && !menu.contains(event.target)) {
                menu.classList.remove('show');
            }
        });

        // WebSocket Connection
        const userId = "<%= loggedInUserId %>";
        const ws = new WebSocket("ws://localhost:8080/Global_Chat_Java/status");

        ws.onopen = function () {
            ws.send("login:" + userId);
        };

        ws.onmessage = function (event) {
            const message = event.data;
            if (message.startsWith("status:")) {
                const parts = message.split(":");
                if (parts.length === 3) {
                    const userId = parts[1];
                    const status = parts[2];
                    const statusElement = document.getElementById("status-" + userId);
                    const contactItem = document.getElementById("contact-" + userId);

                    if (statusElement && contactItem) {
                        statusElement.textContent = status;
                        statusElement.className = "text-sm " + (status === "Online" ? "text-green-500" : "text-gray-500");
                        contactItem.setAttribute("data-online", status === "Online");
                        filterContacts();
                    }
                }
            }
        };

        window.addEventListener("beforeunload", function () {
            ws.send("logout:" + userId);
        });

        // Contact Filtering
        function filterContacts() {
            const searchInput = document.getElementById("search").value.toLowerCase();
            const showOnlineOnly = document.getElementById("onlineOnly").checked;
            const contacts = document.querySelectorAll(".contact-item");

            contacts.forEach(contact => {
                const name = contact.querySelector("p.font-semibold").textContent.toLowerCase();
                const isOnline = contact.getAttribute("data-online") === "true";

                if (name.includes(searchInput) && (!showOnlineOnly || isOnline)) {
                    contact.style.display = "flex";
                } else {
                    contact.style.display = "none";
                }
            });
        }
    </script>
</body>
</html>