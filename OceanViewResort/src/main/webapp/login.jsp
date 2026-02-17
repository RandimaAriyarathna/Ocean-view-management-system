<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Staff Login - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Segoe UI', sans-serif;
}

/* BODY */
body {
    background:
        linear-gradient(rgba(0,0,50,0.2), rgba(0,0,50,0.2)),
        url('images/login-bg.jpg');
    background-size: cover;
    background-position: center;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
}

/* GLASS CARD */
.login-card {
    width: 400px;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(18px);
    border-radius: 20px;
    padding: 40px 30px;
    box-shadow: 0 8px 30px rgba(0,0,50,0.4);
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: all 0.3s ease;
}

.login-card:hover {
    box-shadow: 0 15px 40px rgba(0,0,80,0.5);
    transform: translateY(-2px);
}

/* LOGO */
.logo {
    text-align: center;
    margin-bottom: 25px;
    color: white;
}

.logo i {
    font-size: 45px;
    margin-bottom: 10px;
    color: #00b4d8;
}

.logo h2 {
    color: white;
    font-weight: 600;
}

.logo p {
    color: #caf0f8;
}

/* FORM */
.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 6px;
    color: white;
    font-weight: 600;
}

.input-box {
    position: relative;
}

.input-box i {
    position: absolute;
    left: 14px;
    top: 50%;
    transform: translateY(-50%);
    color: #00b4d8;
}

.input-box input {
    width: 100%;
    padding: 14px 14px 14px 42px;
    border: 1px solid rgba(255, 255, 255, 0.5);
    border-radius: 12px;
    font-size: 15px;
    background: rgba(255, 255, 255, 0.1);
    color: white;
    outline: none;
    transition: .3s;
}

.input-box input::placeholder {
    color: rgba(255, 255, 255, 0.7);
}

.input-box input:focus {
    border-color: #00b4d8;
    box-shadow: 0 0 8px rgba(0,180,216,0.5);
}

/* Remember + Forgot */
.remember-forgot {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 14px;
    margin-bottom: 20px;
    color: white;
}

.remember-forgot label {
    display: flex;
    align-items: center;
    gap: 6px;
    cursor: pointer;
}

.remember-forgot input[type="checkbox"] {
    accent-color: #00b4d8;
}

.remember-forgot a {
    color: #00b4d8;
    text-decoration: none;
    font-weight: 500;
    transition: 0.3s;
}

.remember-forgot a:hover {
    text-decoration: underline;
}

/* BUTTON */
.login-btn {
    width: 100%;
    padding: 14px;
    border: none;
    border-radius: 12px;
    background: linear-gradient(45deg, #0077b6, #00b4d8);
    color: white;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    justify-content: center;
    align-items: center;
}

.login-btn i {
    margin-right: 8px;
}

.login-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 20px rgba(0,180,216,0.6);
}

/* FOOTER */
.footer {
    text-align: center;
    margin-top: 15px;
    font-size: 12px;
    color: white;
}

/* RESPONSIVE */
@media (max-width: 480px) {
    .login-card {
        width: 90%;
        padding: 30px 20px;
    }
}
</style>
</head>

<body>

<div class="login-card">

    <div class="logo">
        <i class="fas fa-umbrella-beach"></i>
        <h2>Ocean View Resort</h2>
        <p>Staff Portal</p>
    </div>

    <form action="login" method="post" id="loginForm">
        
        <div class="form-group">
            <label>Username</label>
            <div class="input-box">
                <i class="fas fa-user"></i>
                <input type="text" name="username" placeholder="Enter username" required autocomplete="username">
            </div>
        </div>
        
        <div class="form-group">
            <label>Password</label>
            <div class="input-box">
                <i class="fas fa-lock"></i>
                <input type="password" name="password" placeholder="Enter password" required autocomplete="current-password">
            </div>
        </div>
        
        <div class="remember-forgot">
            <label>
                <input type="checkbox" name="remember"> Remember Me
            </label>
            <a href="#" onclick="forgotPassword()">Forgot Password?</a>
        </div>
        
        <button type="submit" class="login-btn">
            <i class="fas fa-sign-in-alt"></i> Login to Dashboard
        </button>
        
    </form>
    
    <div class="footer">
        &copy; 2024 Ocean View Resort System
    </div>

</div>

<script>
// FIXED: Check for 'type' parameter (not 'error')
window.onload = function() {
    <%
    String type = request.getParameter("type");
    String message = request.getParameter("message");
    
    if("error".equals(type) && message != null) {
    %>
        // Show alert for error
        setTimeout(function() {
            alert("❌ " + "<%= message %>");
        }, 300);
    <%
    }
    %>
};

function forgotPassword() {
    alert("🔒 Password Reset Request\n\n" +
          "Please contact the system administrator:\n\n" +
          "📧 Email: support@oceanviewresort.lk\n" +
          "📞 Phone: +94 11 234 5678\n\n" +
          "Hours: Mon-Fri 8:00 AM - 6:00 PM");
    return false;
}

// Form validation
document.getElementById('loginForm').addEventListener('submit', function(e) {
    var username = document.querySelector('input[name="username"]').value.trim();
    var password = document.querySelector('input[name="password"]').value.trim();
    
    if(username === '' || password === '') {
        e.preventDefault(); // Stop form submission
        alert("⚠️ Please fill in both username and password fields!");
    }
});
</script>

</body>
</html>