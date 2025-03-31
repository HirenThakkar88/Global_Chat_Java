<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="utils.DBUtil" %>

<%
    Integer loggedInUserId = (Integer) session.getAttribute("userId");
    if (loggedInUserId == null) {
        response.sendRedirect("LoginForm.jsp");
        return;
    }

    String selectedUserIdParam = request.getParameter("userId");
    String user = request.getParameter("user");
    String profilePic = request.getParameter("profile");
    String status = request.getParameter("status");

    if (selectedUserIdParam == null || user == null) {
        response.sendRedirect("HomePage.jsp");
        return;
    }

    int selectedUserId = 0;
    try {
        selectedUserId = Integer.parseInt(selectedUserIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("HomePage.jsp");
        return;
    }

    user = java.net.URLDecoder.decode(user, "UTF-8");
    profilePic = (profilePic != null) ? java.net.URLDecoder.decode(profilePic, "UTF-8") : "default.jpg";
    status = (status != null) ? java.net.URLDecoder.decode(status, "UTF-8") : "Offline";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat - Global Chat</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            font-family: 'Noto Sans', sans-serif !important;
        }
        .navbar-space {
            height: 70px;
            margin-top: 0;
        }
        .attachment-menu {
            position: absolute;
            bottom: 70px;
            left: 20px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            padding: 12px;
            display: none;
            z-index: 1000;
        }
        .attachment-item {
            display: flex;
            align-items: center;
            padding: 8px 16px;
            border-radius: 8px;
            transition: all 0.2s;
            cursor: pointer;
        }
        .attachment-item:hover {
            background: #f3f4f6;
        }
        .attachment-item:hover .attachment-icon {
            color: #1f2937;
        }
        .attachment-item:hover .attachment-text {
            color: #111827;
        }
    </style>
</head>
<body class="bg-gray-100 font-sans">
    <div class="navbar-container">
        <jsp:include page="Navbar.jsp" />
    </div>
    <div class="navbar-space"></div>

    <div class="flex h-screen">
        <jsp:include page="Slidebar.jsp" />

        <div class="flex-1 flex flex-col bg-white shadow-lg">
            <!-- Chat Header -->
            <div class="p-4 border-b flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <img src="<%= profilePic %>" alt="User" class="w-12 h-12 rounded-full">
                    <div>
                        <p class="text-lg font-semibold"><%= user %></p>
                        <p class="text-sm <%= "Online".equals(status) ? "text-green-500" : "text-gray-500" %>">
                            <%= status %>
                        </p>
                    </div>
                </div>
                <!-- Call Icons -->
<div class="flex items-center gap-3">
    <button class="p-2 rounded-full hover:bg-gray-100 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
        </svg>
    </button>
    
    <button class="p-2 rounded-full hover:bg-gray-100 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
        </svg>
    </button>
    
    <!-- Three-dot menu button -->
    <button class="p-2 rounded-full hover:bg-gray-100 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" viewBox="0 0 24 24" fill="currentColor">
            <circle cx="12" cy="6" r="2"/>
            <circle cx="12" cy="12" r="2"/>
            <circle cx="12" cy="18" r="2"/>
        </svg>
    </button>
</div>
            </div>
<!-- Chat Messages -->
            <div class="flex-1 p-4 overflow-y-auto" id="chatWindow">
                <%
                    Connection conn = null;
                    PreparedStatement stmt = null;
                    ResultSet rs = null;

                    try {
                        conn = DBUtil.getConnection();
                        String sql = "SELECT * FROM messages " +
                                     "WHERE (sender_id = ? AND receiver_id = ?) " +
                                     "OR (sender_id = ? AND receiver_id = ?) " +
                                     "ORDER BY created_at ASC";
                        stmt = conn.prepareStatement(sql);
                        stmt.setInt(1, loggedInUserId);
                        stmt.setInt(2, selectedUserId);
                        stmt.setInt(3, selectedUserId);
                        stmt.setInt(4, loggedInUserId);
                        rs = stmt.executeQuery();

                        while (rs.next()) {
                            int senderId = rs.getInt("sender_id");
                            String text = rs.getString("text");
                            String image = rs.getString("image");
                            Timestamp createdAt = rs.getTimestamp("created_at");

                            boolean isSender = (senderId == loggedInUserId);
                %>
                <div class="flex <%= isSender ? "justify-end" : "justify-start" %> mb-4">
                    <div class="<%= isSender ? "bg-blue-500 text-white" : "bg-gray-200" %> p-3 rounded-lg max-w-xs">
                        <% if (image != null && !image.isEmpty()) { %>
                            <img src="<%= image %>" alt="Attachment" class="mb-2 rounded-lg">
                        <% } %>
                        <p><%= text %></p>
                        <p class="text-xs mt-1 <%= isSender ? "text-blue-100" : "text-gray-500" %>">
                            <%= createdAt.toLocalDateTime().toLocalTime().toString().substring(0, 5) %>
                        </p>
                    </div>
                </div>
                <%
                        }
                    } catch (SQLException e) {
                        out.println("<p>Error loading messages: " + e.getMessage() + "</p>");
                    } finally {
                        DBUtil.close(conn, stmt, rs);
                    }
                %>
            </div>

            <!-- Chat Input -->
            <div class="p-4 border-t flex items-center gap-2 relative">
                <div class="relative">
                    <button id="plusButton" class="p-2 rounded-full bg-white border border-gray-300 hover:bg-gray-100 transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                        </svg>
                    </button>
                    
                    <!-- Attachment Menu -->
                    <div id="attachmentMenu" class="attachment-menu">
                        <div class="attachment-item" onclick="handleAttachment('audio')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-gray-600 attachment-icon" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                            </svg>
                            <span class="text-gray-700 attachment-text">Audio</span>
                        </div>
                        
                        <div class="attachment-item" onclick="handleAttachment('photo')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-gray-600 attachment-icon" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <span class="text-gray-700 attachment-text">Photo</span>
                        </div>
                        
                        <div class="attachment-item" onclick="handleAttachment('video')">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-gray-600 attachment-icon" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 01221 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                            <span class="text-gray-700 attachment-text">Video</span>
                        </div>
                    </div>
                </div>

                <input type="text" id="messageInput" 
                       class="flex-1 p-2 border rounded-full px-4 focus:outline-none focus:border-blue-500" 
                       placeholder="Type a message..."
                       onkeypress="if(event.keyCode === 13) sendMessage()">

                <button class="p-2 rounded-full bg-white border border-gray-300 hover:bg-gray-100 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                              d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </button>

                <button onclick="sendMessage()" class="p-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 12L3 21l18-9-18-9-3 9zM11 12l8-4-8-4v8z"/>
                    </svg>
                </button>
            </div>
        </div>
    </div>

    <script>
 // Establish WebSocket connection
   // WebSocket Connection with proper context path
   const websocket = new WebSocket('ws://localhost:8080/Global_Chat_Java/chat');

    // Connection handlers
    websocket.onopen = function(event) {
        console.log('WebSocket connected:', event);
    };

    websocket.onmessage = function(event) {
        const message = JSON.parse(event.data);
        if ((message.senderId === <%= loggedInUserId %> && message.receiverId === <%= selectedUserId %>) ||
            (message.senderId === <%= selectedUserId %> && message.receiverId === <%= loggedInUserId %>)) {
            appendMessage(message);
        }
    };

    websocket.onerror = function(error) {
        console.error('WebSocket error:', error);
    };

    websocket.onclose = function(event) {
        console.log('WebSocket connection closed:', event);
    };

    // Handle WebSocket close
    websocket.onclose = function(event) {
        console.log('WebSocket connection closed:', event);
    };

    // Message appending function
   function appendMessage(message) {
    const chatWindow = document.getElementById("chatWindow");
    // Convert both IDs to numbers for strict comparison
    const isSender = parseInt(message.senderId) === <%= loggedInUserId %>;
    
    const messageDiv = document.createElement("div");
    messageDiv.className = isSender ? "flex justify-end mb-4" : "flex justify-start mb-4";

    const contentDiv = document.createElement("div");
    contentDiv.className = isSender 
        ? "bg-blue-500 text-white p-3 rounded-lg max-w-xs" 
        : "bg-gray-200 p-3 rounded-lg max-w-xs";

    const textElement = document.createElement("p");
    textElement.textContent = message.text;

    const timeElement = document.createElement("p");
    timeElement.className = isSender 
        ? "text-xs mt-1 text-blue-100" 
        : "text-xs mt-1 text-gray-500";
    timeElement.textContent = new Date(message.timestamp).toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit'
    });

    contentDiv.appendChild(textElement);
    contentDiv.appendChild(timeElement);
    messageDiv.appendChild(contentDiv);
    chatWindow.appendChild(messageDiv);
    
    // Scroll to bottom
    #chatWindow.scrollTop = chatWindow.scrollHeight;
}

    // Send message function
    function sendMessage() {
        const messageInput = document.getElementById("messageInput");
        const messageText = messageInput.value.trim();
        
        if (messageText) {
            fetch("SendMessage.jsp", {
                method: "POST",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body: new URLSearchParams({
                    receiver_id: "<%= selectedUserId %>",
                    text: messageText
                })
            }).then(response => {
                if (response.ok) {
                    messageInput.value = "";
                }
            }).catch(error => console.error('Error:', error));
        }
    }

        document.getElementById('plusButton').addEventListener('click', function(e) {
            const menu = document.getElementById('attachmentMenu');
            menu.style.display = menu.style.display === 'block' ? 'none' : 'block';
            e.stopPropagation();
        });

        document.addEventListener('click', function(e) {
            if (!e.target.closest('#attachmentMenu') && !e.target.closest('#plusButton')) {
                document.getElementById('attachmentMenu').style.display = 'none';
            }
        });

        function handleAttachment(type) {
            console.log(`Selected: ${type}`);
            document.getElementById('attachmentMenu').style.display = 'none';
        }
    </script>
</body>
</html>