<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Signup - Global Chat</title>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <style>
        /* Include all animations and styles from login page */
        .navbar-space { margin-top: 80px; }
        
        body, button, input, textarea, h1, h2, h3, h4, h5, h6, p, span, div {
            font-family: 'Noto Sans', sans-serif !important;
        }

        @keyframes float { 0% { transform: translateY(0px) rotate(0deg); } 50% { transform: translateY(-20px) rotate(5deg); } 100% { transform: translateY(0px) rotate(0deg); } }
        @keyframes wave { 0% { transform: translateY(0) rotate(-3deg); } 50% { transform: translateY(-20px) rotate(3deg); } 100% { transform: translateY(0) rotate(-3deg); } }
        @keyframes zoomInOut { 0% { transform: scale(1); } 50% { transform: scale(1.2); } 100% { transform: scale(1); } }
        @keyframes gradientPulse { 0% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } 100% { background-position: 0% 50%; } }

        .chat-bubble {
            position: relative;
            border: 2px solid #8b5cf6;
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            animation: wave 4s ease-in-out infinite;
            background: rgba(17, 24, 39, 0.8);
            backdrop-filter: blur(12px);
        }

        .floating-icon {
            position: fixed;
            opacity: 0.1;
            animation: float 6s ease-in-out infinite;
            pointer-events: none;
            z-index: 8;
            font-size: 2rem;
        }

        .middle-icons {
            position: absolute;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            z-index: 5;
            display: flex;
            gap: 2rem;
        }

        .zoom-icon {
            animation: zoomInOut 3s ease-in-out infinite;
            font-size: 2.5rem;
            opacity: 0.8;
            transition: all 0.3s ease;
        }

        .gradient-text {
            background: linear-gradient(-45deg, #ff0000, #ff6b6b, #ffffff, #ff6b6b);
            background-size: 400% 400%;
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            animation: gradientPulse 8s ease infinite;
        }

        .form-container {
            background: rgba(17, 24, 39, 0.3);
            backdrop-filter: blur(1px);
            border: 2px solid rgba(139, 92, 246, 0.4);
            transition: border-color 0.3s ease;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .floating-icon, .chat-container, .middle-icons { display: none; }
            .form-container { width: 95% !important; margin: 1rem; }
        }
    </style>
    
     <style>
    /* Fixed Navbar */
    .navbar-container {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: 1000; /* Higher than floating icons */
    }

    /* Adjust spacing for fixed navbar */
    .navbar-space {
        height: 80px; /* Match navbar height */
        margin-top: 0;
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
            session.removeAttribute("successMessage");
        }
        if (errorMessage != null) {
    %>
    <script>
        alert("<%= errorMessage %>");
    </script>
    <%
        }
    %>
    <script>
        function togglePassword() {
            const passwordField = document.getElementById("password");
            const toggleIcon = document.getElementById("toggleIcon");
            
            if (passwordField.type === "password") {
                passwordField.type = "text";
                toggleIcon.innerHTML = `
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.477 0-8.268-2.943-9.542-7a10.05 10.05 0 012.387-4.243M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18" />
                    </svg>`;
            } else {
                passwordField.type = "password";
                toggleIcon.innerHTML = `
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>`;
            }
        }
    </script>
</head>
<body class="min-h-screen bg-gradient-to-br from-gray-900 to-black overflow-x-hidden">
    <!-- Background Floating Icons -->
    <div class="floating-icon" style="left:5%; top:15%; animation-delay: 0.2s">🚀</div>
    <div class="floating-icon" style="right:10%; top:25%; animation-delay: 1.5s">🔑</div>
    <div class="floating-icon" style="left:20%; top:70%; animation-delay: 2.8s">🌟</div>
    <div class="floating-icon" style="right:5%; top:65%; animation-delay: 3.5s">🎉</div>

  <div class="navbar-container">
        <jsp:include page="Navbar.jsp" />
    </div>
    <div class="navbar-space"></div>
    <div class="main-content flex justify-between items-center min-h-screen p-4 relative">
        <!-- Left Chat Section -->
        <div class="chat-container hidden md:block w-96 ml-8">
            <div class="chat-bubble p-6 rounded-2xl m-4" style="animation-delay: 0.2s">
                <p class="text-purple-300 text-lg font-medium">🌟 Start Your Journey</p>
            </div>
            <div class="chat-bubble p-6 rounded-2xl m-4" style="animation-delay: 0.4s">
                <p class="text-blue-300 text-lg font-medium">🔒 Secure Registration</p>
            </div>
            <div class="chat-bubble p-6 rounded-2xl m-4" style="animation-delay: 0.6s">
                <p class="text-green-300 text-lg font-medium">🌍 Join Global Community</p>
            </div>
        </div>

        <!-- Middle Icons -->
        <div class="middle-icons">
            <div class="zoom-icon" style="animation-delay: 0.2s">👤</div>
            <div class="zoom-icon" style="animation-delay: 0.4s">📝</div>
            <div class="zoom-icon" style="animation-delay: 0.6s">🔑</div>
            <div class="zoom-icon" style="animation-delay: 0.8s">✅</div>
        </div>

        <!-- Signup Form Container -->
        <div class="form-container relative w-full max-w-sm p-8 rounded-2xl shadow-3xl z-10 mr-8">
            <div class="mb-8 text-center">
                <h1 class="text-4xl font-bold gradient-text mb-2">Join Us</h1>
                <p class="text-sm text-gray-400 animate-pulse">Become part of our global community</p>
            </div>

            <form action="SignupServlet" method="post" class="space-y-5">
                <input type="text" name="full_name" placeholder="Full Name" 
                    class="w-full px-4 py-3 text-white bg-gray-800/50 border-2 border-gray-700 rounded-lg outline-none focus:border-purple-500 transition-all"
                    required>

                <input type="email" name="email" placeholder="Email" 
                    class="w-full px-4 py-3 text-white bg-gray-800/50 border-2 border-gray-700 rounded-lg outline-none focus:border-purple-500 transition-all"
                    required>

                <div class="relative">
                    <input type="password" id="password" name="password" placeholder="Password" 
                        class="w-full px-4 py-3 text-white bg-gray-800/50 border-2 border-gray-700 rounded-lg outline-none focus:border-purple-500 transition-all pr-12"
                        required>
                    <button type="button" class="absolute right-3 top-3.5 text-gray-400 hover:text-white" onclick="togglePassword()">
                        <span id="toggleIcon">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                        </span>
                    </button>
                </div>

                <input type="password" name="confirmPassword" placeholder="Confirm Password" 
                    class="w-full px-4 py-3 text-white bg-gray-800/50 border-2 border-gray-700 rounded-lg outline-none focus:border-purple-500 transition-all"
                    required>

                <button type="submit" 
                    class="w-full py-3.5 text-white rounded-lg font-semibold 
                           bg-gradient-to-r from-purple-600/40 to-blue-600/40
                           border border-purple-500/30
                           backdrop-blur-sm
                           hover:from-purple-600/60 hover:to-blue-600/60
                           hover:border-purple-500/50
                           transition-all shadow-lg hover:shadow-xl 
                           hover:shadow-purple-500/20
                           active:scale-95">
                    Create Account
                </button>
            </form>

            <!-- Social Login -->
            <div class="mt-8">
                <div class="flex items-center my-6">
                    <span class="flex-grow h-px bg-gray-700"></span>
                    <p class="px-4 text-sm text-gray-400">Or continue with</p>
                    <span class="flex-grow h-px bg-gray-700"></span>
                </div>
                <div class="flex justify-center gap-4">
                    <button class="social-btn flex items-center justify-center w-12 h-12 rounded-full bg-gray-800 hover:bg-gray-700 transition-all">
                        <img src="https://cdn-icons-png.flaticon.com/512/2991/2991148.png" alt="Google" class="w-6 h-6">
                    </button>
                    <button class="social-btn flex items-center justify-center w-12 h-12 rounded-full bg-gray-800 hover:bg-gray-700 transition-all">
                        <img src="https://cdn-icons-png.flaticon.com/512/733/733547.png" alt="Facebook" class="w-6 h-6">
                    </button>
                    <button class="social-btn flex items-center justify-center w-12 h-12 rounded-full bg-gray-800 hover:bg-gray-700 transition-all">
                        <img src="https://cdn-icons-png.flaticon.com/512/733/733553.png" alt="GitHub" class="w-6 h-6">
                    </button>
                </div>
            </div>

            <p class="mt-8 text-center text-sm text-gray-400">
                Already have an account? 
                <a href="LoginForm.jsp" class="text-purple-400 hover:text-purple-300 transition-colors font-semibold">
                    Login Here
                </a>
            </p>
        </div>
    </div>
</body>
</html>