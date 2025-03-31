<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Settings - Global Chat</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-black text-white min-h-screen flex justify-center items-start p-6">
<jsp:include page="Navbar.jsp" />
    <div class="w-full max-w-4xl">
        <!-- Page Title -->
        <h1 class="text-2xl font-semibold">Global Chat</h1>

        <!-- Theme Section -->
        <section class="mt-6">
            <h2 class="text-lg font-medium">Theme</h2>
            <p class="text-gray-400">Choose a theme for your chat interface</p>

            <!-- Theme Options Grid -->
            <div class="grid grid-cols-6 gap-4 mt-4">
                <%-- Theme Buttons --%>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-purple-400 to-blue-500 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gray-900 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-pink-400 to-red-500 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-yellow-400 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-green-500 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-blue-600 border-2 border-white"></button>

                <button class="w-16 h-10 rounded-lg bg-gray-800 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-purple-700 to-indigo-900 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-orange-400 to-yellow-500 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-black to-gray-700 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-green-700 to-teal-500 border-2 border-white"></button>
                <button class="w-16 h-10 rounded-lg bg-gradient-to-r from-blue-900 to-blue-400 border-2 border-white"></button>
            </div>
        </section>

        <!-- Preview Section -->
        <section class="mt-8">
            <h2 class="text-lg font-medium">Preview</h2>
            <div class="bg-gray-900 p-4 rounded-lg mt-4 max-w-lg mx-auto">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 bg-gray-700 rounded-full flex items-center justify-center text-white font-bold">J</div>
                    <div>
                        <p class="text-white font-medium">Hiren Thakkar</p>
                        <p class="text-green-400 text-sm">Online</p>
                    </div>
                </div>

                <!-- Chat Messages -->
                <div class="mt-4 space-y-3">
                    <div class="bg-gray-800 text-white p-3 rounded-lg max-w-xs">Hey! How’s it going?</div>
                    <div class="bg-gray-700 text-white p-3 rounded-lg max-w-xs self-end ml-auto">I'm doing great! Just working on some new features.</div>
                </div>

                <!-- Chat Input Box -->
                <div class="mt-4 border-t border-gray-600 pt-3">
                    <input type="text" placeholder="This is a preview" class="w-full bg-gray-800 text-white px-4 py-2 rounded-lg outline-none">
                </div>
            </div>
        </section>
    </div>
</body>
</html>
