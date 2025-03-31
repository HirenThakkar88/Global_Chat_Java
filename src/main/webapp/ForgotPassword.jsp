<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Forgot Password</title>
    <!-- Tailwind CSS via CDN -->
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
     <style>
        /* Add space after navbar */
        .navbar-space {
            margin-top: 80px; /* Adjust as needed */
        }
    </style>
</head>
<body class="bg-black font-noto-sans">
<jsp:include page="Navbar.jsp" />
  <div class="navbar-space"></div>
    <div class="flex flex-col-reverse items-center justify-between min-h-screen p-4 md:flex-row md:p-8">
        <!-- Left Section -->
        <div class="text-center md:text-left md:w-1/2 lg:w-1/3">
            <h1 class="text-3xl font-bold text-white sm:text-4xl md:text-5xl">
                No Worries<span class="text-purple-500">.!!</span>
            </h1>
            <a href="index.jsp" class="inline-block px-6 py-3 mt-4 text-sm text-black transition bg-white rounded-full shadow-md md:text-base hover:bg-gray-200">
                Take me back.!
            </a>
        </div>

        <!-- Right Section -->
        <div class="relative w-full max-w-sm p-6 border border-white rounded-lg shadow-lg sm:max-w-md md:w-1/2 lg:w-1/3 bg-gradient-to-br from-gray-900 to-black sm:p-8">
            <!-- Gradient Circle -->

            <h2 class="mb-2 text-xl font-bold text-white sm:text-2xl md:text-3xl">
                Forgot Password ?
            </h2>
            <p class="mb-6 text-sm text-gray-400 sm:text-base">
                Please enter your email
            </p>

            <!-- Form -->
            <!-- Adjust the form action to point to your password reset servlet/controller -->
            <form action="ResetPasswordServlet" method="post" class="space-y-4">
                <input
                    type="email"
                    name="email"
                    placeholder="example@mail.com"
                    class="w-full px-4 py-3 text-sm text-white bg-transparent border border-gray-600 rounded-md outline-none md:text-base focus:ring-2 focus:ring-purple-500"
                    required
                />
                <button
                    type="submit"
                    class="w-full py-3 text-sm text-white transition rounded-md shadow-lg md:text-base bg-gradient-to-r from-pink-500 to-purple-600 hover:opacity-90"
                >
                    Reset Password
                </button>
            </form>

            <!-- Divider -->
            <div class="flex items-center my-6">
                <span class="flex-grow h-px bg-gray-700"></span>
                <p class="px-4 text-sm text-gray-400 sm:text-base">Or</p>
                <span class="flex-grow h-px bg-gray-700"></span>
            </div>

            <!-- Signup Link -->
            <p class="mt-4 text-sm text-center text-gray-400 sm:text-base">
                Don’t have an account?
                <a href="SignupForm.jsp" class="text-purple-500 underline">
                    Signup
                </a>
            </p>

            <!-- Footer Links -->
            <div class="flex justify-between mt-6 text-xs text-gray-400 sm:text-sm">
                <a href="terms.jsp" class="transition hover:text-white">
                    Terms & Conditions
                </a>
                <a href="support.jsp" class="transition hover:text-white">
                    Support
                </a>
                <a href="customerCare.jsp" class="transition hover:text-white">
                    Customer Care
                </a>
            </div>
        </div>
    </div>
</body>
</html>
