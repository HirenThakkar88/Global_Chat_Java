<%@ page import="java.sql.*" %>
<%@ page import="jakarta.servlet.http.*, jakarta.servlet.*" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>

<%
    // Theme handling
    String currentTheme = (String) session.getAttribute("currentTheme");
    if(currentTheme == null) {
        currentTheme = "light"; // Default theme
        session.setAttribute("currentTheme", currentTheme);
    }

    // User session handling
    HttpSession sessionObj = request.getSession(false);
    String userEmail = (sessionObj != null) ? (String) sessionObj.getAttribute("userEmail") : null;
    String userName = null;

    if (userEmail != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/globalchat", "root", "");
            PreparedStatement ps = con.prepareStatement("SELECT full_name FROM users WHERE email = ?");
            ps.setString(1, userEmail);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                userName = rs.getString("full_name");
            }

            rs.close();
            ps.close();
            con.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html lang="en" data-theme="<%= currentTheme %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Navbar</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.6.0/dist/full.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            font-family: 'Noto Sans', sans-serif !important;
        }
    </style>
</head>
<body>

    <nav class="fixed top-0 w-full bg-white border-b shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Logo -->
                <% if (userEmail != null) { %>
                    <a href="HomePage.jsp" class="flex items-center text-xl font-bold text-gray-900">
                        <div class="bg-black p-2 rounded-full">
                            💬
                        </div>
                        <span class="ml-2 whitespace-nowrap">Global Chat</span>
                    </a>
                <% } else { %>
                    <span class="flex items-center text-xl font-bold text-gray-900">
                        <div class="bg-black p-2 rounded-full">
                            💬
                        </div>
                        <span class="ml-2 whitespace-nowrap">Global Chat</span>
                    </span>
                <% } %>

                <!-- Menu Items -->
                <div class="hidden md:flex items-center space-x-6">
                    <a href="settings.jsp" class="text-gray-700 hover:text-gray-900 font-medium">⚙️ Settings</a>
                    
                    <% if (userEmail != null) { %>
                        <a href="profile.jsp" class="text-gray-700 hover:text-gray-900 font-medium">👤 <%= userName %></a>
                        <a href="LogoutServlet" class="text-red-500 hover:text-red-700 font-medium">🚪 Logout</a>
                    <% } else { %>
                        <a href="LoginForm.jsp" class="text-blue-500 hover:text-blue-700 font-medium">🔑 Login</a>
                        <a href="SignupForm.jsp" class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600">📝 Sign Up</a>
                    <% } %>
                </div>

                <!-- Mobile Menu -->
                <div class="flex md:hidden items-center gap-x-4">
                    <a href="settings.jsp" class="text-gray-700 hover:text-gray-900 font-medium text-sm">⚙️</a>
                    
                    <% if (userEmail != null) { %>
                        <a href="profile.jsp" class="text-gray-700 hover:text-gray-900 font-medium text-sm">👤</a>
                        <a href="LogoutServlet" class="text-red-500 hover:text-red-700 font-medium text-sm">🚪</a>
                    <% } else { %>
                        <a href="LoginForm.jsp" class="text-blue-500 hover:text-blue-700 font-medium text-sm">🔑</a>
                        <a href="SignupForm.jsp" class="bg-blue-500 text-white px-3 py-1 rounded-md hover:bg-blue-600 text-sm">📝</a>
                    <% } %>
                </div>
            </div>
        </div>
    </nav>

    <!-- Spacer for navbar height -->
    <div class="h-16"></div>
</body>
</html>