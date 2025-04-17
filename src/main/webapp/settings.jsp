<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpSession" %>
<%
HttpSession userSession = request.getSession(false);
if (userSession == null || userSession.getAttribute("userId") == null) {
    response.sendRedirect("LoginForm.jsp");
    return;
}
Integer loggedInUserId = (Integer) userSession.getAttribute("userId");

// Complete list of 32 Daisy UI themes
String[] themes = {
    "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
    "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
    "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
    "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
    "night", "coffee", "winter", "dim", "nord", "sunset"
};

// Get current theme from session
String currentTheme = (String) session.getAttribute("currentTheme");
if(currentTheme == null) {
    currentTheme = "light"; // Default theme
}

// Handle theme change
if(request.getParameter("theme") != null) {
    currentTheme = request.getParameter("theme");
    session.setAttribute("currentTheme", currentTheme);
    response.sendRedirect("settings.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en" data-theme="<%= currentTheme %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Theme Settings</title>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.6.0/dist/full.css" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        * {
            font-family: 'Noto Sans', sans-serif !important;
        }
        
    </style>
</head>
<body class="min-h-screen bg-base-100">
 <div class="navbar-container fixed top-0 w-full z-50">
        <jsp:include page="Navbar.jsp" />
    </div>

    <div class="container max-w-5xl px-4 pt-20 mx-auto mt-16">
        <div class="space-y-6">
            <div class="flex flex-col gap-1">
                <h2 class="text-lg font-semibold">Theme Settings</h2>
                <p class="text-sm text-base-content/70">Choose from 32 built-in themes</p>
            </div>

            <!-- Theme Selection Grid -->
            <div class="grid grid-cols-4 gap-2 sm:grid-cols-6 md:grid-cols-8">
                <% for(String theme : themes) { %>
                <form method="post" class="contents">
                    <button type="submit" 
                        name="theme" 
                        value="<%= theme %>"
                        class="group flex flex-col items-center gap-1.5 p-2 rounded-lg transition-colors 
                               <%= currentTheme.equals(theme) ? "bg-base-200" : "hover:bg-base-200/50" %>">
                        <div class="relative w-full h-8 overflow-hidden rounded-md" data-theme="<%= theme %>">
                            <div class="absolute inset-0 grid grid-cols-4 gap-px p-1">
                                <div class="rounded bg-primary"></div>
                                <div class="rounded bg-secondary"></div>
                                <div class="rounded bg-accent"></div>
                                <div class="rounded bg-neutral"></div>
                            </div>
                        </div>
                        <span class="text-[11px] font-medium truncate w-full text-center">
                            <%= theme.substring(0, 1).toUpperCase() + theme.substring(1) %>
                        </span>
                    </button>
                </form>
                <% } %>
            </div>

            <!-- Theme Preview Section -->
            <div class="space-y-3">
                <h3 class="text-lg font-semibold">Preview</h3>
                <div class="overflow-hidden border shadow-lg rounded-xl border-base-300 bg-base-100">
                    <div class="p-4 bg-base-200">
                        <div class="max-w-lg mx-auto">
                            <div class="overflow-hidden shadow-sm bg-base-100 rounded-xl">
                                <!-- Chat Header -->
                                <div class="px-4 py-3 border-b border-base-300 bg-base-100">
                                    <div class="flex items-center gap-3">
                                        <div class="avatar">
                                            <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center">
                                                J
                                            </div>
                                        </div>
                                        <div>
                                            <h3 class="text-sm font-medium">XYZ</h3>
                                            <p class="text-xs text-base-content/70">Online</p>
                                        </div>
                                    </div>
                                </div>

                                <!-- Chat Messages -->
                                <div class="p-4 space-y-4 min-h-[200px] max-h-[200px] overflow-y-auto">
                                    <div class="flex justify-start">
                                        <div class="max-w-[80%] rounded-xl p-3 bg-base-200 shadow-sm">
                                            <p class="text-sm">Hey! How are you?</p>
                                            <p class="text-[10px] mt-1.5 text-base-content/70">10:00 AM</p>
                                        </div>
                                    </div>
                                    <div class="flex justify-end">
                                        <div class="max-w-[80%] rounded-xl p-3 bg-primary text-primary-content shadow-sm">
                                            <p class="text-sm">I'm doing great, thanks!</p>
                                            <p class="text-[10px] mt-1.5 text-primary-content/70">10:01 AM</p>
                                        </div>
                                    </div>
                                </div>

                                <!-- Chat Input -->
                                <div class="p-4 border-t border-base-300">
                                    <div class="flex gap-2">
                                        <input type="text" 
                                               class="flex-1 h-10 text-sm input input-bordered" 
                                               placeholder="Type a message..." 
                                               value="Preview input" 
                                               readonly>
                                        <button class="h-10 min-h-0 btn btn-primary">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                                                <path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/>
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
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