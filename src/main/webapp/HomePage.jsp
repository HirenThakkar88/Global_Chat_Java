<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Global Chat</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Add space after navbar */
        .navbar-space {
            margin-top: 70px; /* Adjust as needed */
            
        }
    </style>
    <%@ page session="true" %>
<%
    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage = (String) request.getAttribute("errorMessage");
    if (successMessage != null) {
%>
    <script>
        alert("<%= successMessage %>");
    </script>
<%
        session.removeAttribute("successMessage"); // Clear after showing
    }
    if (errorMessage != null) {
%>
    <script>
        alert("<%= errorMessage %>");
    </script>
<%
    }
%>
</head>
<body class="min-h-screen bg-base-100">
<jsp:include page="Navbar.jsp" />
<div class="navbar-space"></div>

<div class="flex h-screen">
    <!-- Sidebar -->
    <jsp:include page="Slidebar.jsp" />

    <!-- Main Chat Area -->
    <div class="flex-1 flex items-center justify-center shadow-lg">
        <div class="text-center">
            <img src="https://cdn-icons-png.flaticon.com/512/1383/1383269.png" alt="Chat Illustration" class="rounded-lg mb-4 w-20 h-20 mx-auto">
            <h2 class="text-2xl font-semibold mt-4">Select a conversation to start chatting</h2>
        </div>
    </div>
</div>

</body>
</html>
