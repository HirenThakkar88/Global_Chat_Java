<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Verify OTP</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100">
    <div class="container mx-auto mt-20 max-w-md">
        <div class="bg-white p-8 rounded-lg shadow-md">
            <h2 class="text-2xl font-bold mb-4">Verify OTP</h2>
            <% if(request.getAttribute("errorMessage") != null) { %>
                <div class="text-red-500 mb-4"><%= request.getAttribute("errorMessage") %></div>
            <% } %>
            <form action="VerifyOTPServlet" method="post">
                <input type="text" name="otp" placeholder="Enter OTP" 
                       class="w-full p-2 mb-4 border rounded" required>
                <button type="submit" 
                        class="w-full bg-blue-500 text-white p-2 rounded hover:bg-blue-600">
                    Verify OTP
                </button>
            </form>
        </div>
    </div>
</body>
</html>