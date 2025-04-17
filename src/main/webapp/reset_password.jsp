<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Reset Password</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100">
    <div class="container mx-auto mt-20 max-w-md">
        <div class="bg-white p-8 rounded-lg shadow-md">
            <h2 class="text-2xl font-bold mb-4">Reset Password</h2>
            <% if(request.getAttribute("errorMessage") != null) { %>
                <div class="text-red-500 mb-4"><%= request.getAttribute("errorMessage") %></div>
            <% } %>
            <form action="UpdatePasswordServlet" method="post">
                <input type="password" name="password" placeholder="New Password" 
                       class="w-full p-2 mb-4 border rounded" required>
                <input type="password" name="confirmPassword" placeholder="Confirm Password" 
                       class="w-full p-2 mb-4 border rounded" required>
                <button type="submit" 
                        class="w-full bg-green-500 text-white p-2 rounded hover:bg-green-600">
                    Reset Password
                </button>
            </form>
        </div>
    </div>
</body>
</html>