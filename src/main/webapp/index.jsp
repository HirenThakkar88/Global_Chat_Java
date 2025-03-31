<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Global Chat Portal</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;500;600&display=swap');
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Poppins', sans-serif;
        }

        body {
            background: linear-gradient(135deg, #0a0a2e, #1a1a4a);
            min-height: 100vh;
            color: #fff;
            overflow-x: hidden;
        }

       .stellar-bg {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%); /* Center the image */
    
    z-index: -1;
    filter: blur(4px);
    opacity: 0.4;

    width: auto;  /* Ensures the image scales naturally */
    height: auto;
    max-width: 100%;
    max-height: 100%;
}

        .content {
            position: relative;
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
            text-align: center;
        }

        .header {
            margin-top: 4rem;
            margin-bottom: 3rem;
        }

        .header h1 {
            font-size: 3.5rem;
            background: linear-gradient(45deg, #00b4d8, #90e0ef);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 1.5rem;
            letter-spacing: 1.5px;
        }

        .auth-container {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(12px);
            border-radius: 20px;
            padding: 3rem 4rem;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.1);
            display: inline-block;
            margin-top: 2rem;
        }

        .auth-buttons {
            display: flex;
            gap: 2rem;
            margin-top: 2.5rem;
            justify-content: center;
        }

        .auth-button {
            padding: 1.2rem 2.5rem;
            border: none;
            border-radius: 12px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .login-btn {
            background: linear-gradient(45deg, #00b4d8, #0077b6);
            color: white;
        }

        .signup-btn {
            background: linear-gradient(45deg, #90e0ef, #00b4d8);
            color: white;
        }

        .auth-button:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(0, 180, 216, 0.4);
        }

        .welcome-message {
            font-size: 1.4rem;
            margin-bottom: 2rem;
            color: #90e0ef;
        }

        .features {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 2rem;
            margin: 4rem 0;
        }

        .feature-card {
            background: rgba(255, 255, 255, 0.05);
            padding: 2rem;
            border-radius: 15px;
            transition: transform 0.3s ease;
        }

        .feature-card:hover {
            transform: translateY(-5px);
        }

        @media (max-width: 768px) {
            .auth-buttons {
                flex-direction: column;
            }
            
            .features {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2.5rem;
            }
        }
    </style>
</head>
<body>
    <img src="images/Rotating_earth_animated_transparent.gif" class="stellar-bg" alt="Stellar background">

    <div class="content">
        <div class="header">
            <h1>Global Chat</h1>
            <p class="welcome-message">
                <% String user = (String) session.getAttribute("username");
                if(user != null) { %>
                    Welcome back, <span style="color: #90e0ef;"><%= user %></span>!
                <% } else { %>
                    Connect with the world in real-time
                <% } %>
            </p>
        </div>

        <div class="auth-container">
            <% if(user == null) { %>
                <div class="auth-buttons">
                    <button class="auth-button login-btn" onclick="location.href='LoginForm.jsp'">
                        <i class="fas fa-sign-in-alt"></i> Login
                    </button>
                    <button class="auth-button signup-btn" onclick="location.href='SignupForm.jsp'">
                        <i class="fas fa-user-plus"></i> Sign Up
                    </button>
                </div>
            <% } else { %>
                <div class="auth-buttons">
                    <button class="auth-button login-btn" onclick="location.href='home.jsp'">
                        <i class="fas fa-comments"></i> Enter Chat
                    </button>
                </div>
            <% } %>
        </div>

        <div class="features">
            <div class="feature-card">
                <h3>🌍 Real-time Translation</h3>
                <p>Seamless communication across languages</p>
            </div>
            <div class="feature-card">
                <h3>🔒 End-to-End Encryption</h3>
                <p>Military-grade security for your conversations</p>
            </div>
            <div class="feature-card">
                <h3>⚡ Instant Connectivity</h3>
                <p>Zero latency global network</p>
            </div>
        </div>
    </div>

    <!-- Font Awesome for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</body>
</html>