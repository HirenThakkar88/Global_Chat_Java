<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="jakarta.servlet.http.HttpSession" %>

<%
    HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("userEmail") == null) {
        response.sendRedirect("LoginForm.jsp");
        return;
    }

    // Retrieve user attributes from session
    String userEmail = (String) userSession.getAttribute("userEmail");
    String userName = (String) userSession.getAttribute("userName");
    String profilePic = (String) userSession.getAttribute("profilePic");
    Integer loggedInUserId = (Integer) userSession.getAttribute("userId");

    if (loggedInUserId == null) {
        response.sendRedirect("LoginForm.jsp");
        return;
    }

    // Fetch profile picture if not available in session
    if (profilePic == null || profilePic.trim().isEmpty()) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");
            PreparedStatement ps = con.prepareStatement("SELECT profile_pic FROM users WHERE id = ?");
            ps.setInt(1, loggedInUserId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                profilePic = rs.getString("profile_pic");
                if (profilePic != null && !profilePic.trim().isEmpty()) {
                    userSession.setAttribute("profilePic", profilePic); // Store in session
                }
            }
            con.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    // Set default profile picture if none exists
    if (profilePic == null || profilePic.trim().isEmpty() || profilePic.equals("images/default-profile.png")) {
        profilePic = "images/default-profile.png";
    } else if (!profilePic.startsWith("http") && !profilePic.startsWith("/")) {
        profilePic = "images/" + profilePic;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Profile Page</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { font-family: 'Noto Sans', sans-serif !important; }
    </style>

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
</head>
<body class="min-h-screen bg-base-100 flex justify-center items-center">
    <jsp:include page="Navbar.jsp" />

    <div class="bg-gray-100 p-8 rounded-lg shadow-lg w-full max-w-md">
        <h2 class="text-2xl font-semibold text-center mb-2">Profile</h2>
        <p class="text-center text-gray-500">Your profile information</p>

        <div class="flex justify-center mt-4">
            <div class="relative">
                <img src="<%= profilePic %>?t=<%= System.currentTimeMillis() %>" 
                     alt="Profile Picture" class="w-24 h-24 rounded-full border-4 border-gray-400">
                <form action="ProfileUploadServlet" method="post" enctype="multipart/form-data">
                    <label for="profilePicInput" onclick="triggerFileInput()" 
                           class="absolute bottom-1 right-1 bg-gray-600 p-2 rounded-full cursor-pointer text-white">
                        📷
                    </label>
                    <input type="file" id="profilePicInput" name="profilePic" class="hidden" onchange="this.form.submit(); refreshPage();">
                </form>
            </div>
        </div>

        <div class="mt-6">
            <label class="block text-gray-600 font-medium">Full Name</label>
            <input type="text" value="<%= userName != null ? userName : "Unknown" %>" class="w-full bg-white border border-gray-300 px-4 py-2 rounded-lg" readonly>
        </div>

        <div class="mt-4">
            <label class="block text-gray-600 font-medium">Email Address</label>
            <input type="email" value="<%= userEmail %>" class="w-full bg-white border border-gray-300 px-4 py-2 rounded-lg" readonly>
        </div>
  
        <!-- Account Information -->
        <div class="mt-6 border-t border-gray-300 pt-4">
            <h3 class="text-lg font-semibold text-gray-700">Account Information</h3>
            <p class="text-gray-600">Member Since: <span class="font-medium">2025-01-29</span></p>
            <p class="text-gray-600">Account Status: 
                <span class="text-green-500 font-semibold">Active</span>
            </p>
        </div>
    </div>
</body>
</html>
