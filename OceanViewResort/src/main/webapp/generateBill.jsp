<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) userSession.getAttribute("username");
    
    String type = request.getParameter("type");
    String message = request.getParameter("message");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generate Bill - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #0077b6;
            --secondary: #00b4d8;
            --accent: #90e0ef;
            --dark: #023e8a;
            --light: #caf0f8;
            --light-bg: #f8f9fa;
            --white: #ffffff;
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
            --shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: linear-gradient(135deg, #f0f8ff 0%, #e3f2fd 100%);
            min-height: 100vh;
            color: #333;
        }

        /* Top Navigation */
        .top-nav {
            background: var(--white);
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: var(--shadow);
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logo-icon {
            color: var(--primary);
            font-size: 32px;
        }

        .logo-text h1 {
            font-size: 22px;
            color: var(--dark);
            font-weight: 700;
        }

        .user-section {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .user-info {
            text-align: right;
        }

        .user-name {
            font-weight: 600;
            color: var(--dark);
        }

        .user-role {
            font-size: 12px;
            color: #666;
            background: var(--light-bg);
            padding: 2px 8px;
            border-radius: 10px;
            display: inline-block;
            margin-top: 3px;
        }

        .user-avatar {
            width: 45px;
            height: 45px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 18px;
        }

        .back-btn {
            background: var(--white);
            color: var(--primary);
            border: 1px solid var(--primary);
            padding: 8px 20px;
            border-radius: 20px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }

        .back-btn:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-2px);
        }

        /* Main Container */
        .main-container {
            max-width: 1000px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* Hero Section */
        .hero-section {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 25px rgba(0, 119, 182, 0.2);
            text-align: center;
        }

        .hero-title {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .hero-subtitle {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 20px;
        }

        /* Bill Container */
        .bill-container {
            background: var(--white);
            border-radius: 15px;
            padding: 40px;
            box-shadow: var(--shadow);
            margin-bottom: 30px;
        }

        .section-title {
            color: var(--dark);
            font-size: 22px;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--light);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        /* Search Section */
        .search-section {
            background: var(--light-bg);
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
        }

        .search-bar {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }

        .search-bar input {
            flex: 1;
            padding: 12px 20px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
        }

        .search-bar input:focus {
            outline: none;
            border-color: var(--primary);
        }

        .search-btn {
            background: var(--primary);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .search-btn:hover {
            background: var(--dark);
        }

        /* Quick Options */
        .quick-options {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .option-card {
            background: var(--white);
            padding: 25px;
            border-radius: 10px;
            box-shadow: var(--shadow);
            text-align: center;
            border: 2px solid transparent;
            transition: all 0.3s;
            cursor: pointer;
        }

        .option-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 25px rgba(0, 119, 182, 0.15);
            border-color: var(--accent);
        }

        .option-icon {
            font-size: 40px;
            color: var(--primary);
            margin-bottom: 15px;
        }

        .option-card h3 {
            color: var(--dark);
            margin-bottom: 10px;
            font-size: 18px;
        }

        .option-card p {
            color: #666;
            font-size: 14px;
            line-height: 1.5;
        }

        /* Bill Preview Section */
        .bill-preview {
            background: #f9f9f9;
            border-radius: 10px;
            padding: 25px;
            border: 2px dashed #ddd;
            margin-top: 30px;
            display: none;
        }

        .bill-preview.show {
            display: block;
            animation: fadeIn 0.5s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .preview-title {
            color: var(--dark);
            margin-bottom: 20px;
            text-align: center;
        }

        .preview-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .info-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid var(--primary);
        }

        .info-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }

        .info-value {
            font-size: 16px;
            font-weight: 600;
            color: var(--dark);
        }

        .amount-breakdown {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
        }

        .amount-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }

        .amount-row:last-child {
            border-bottom: none;
            font-weight: 700;
            color: var(--primary);
            font-size: 18px;
        }

        /* Action Buttons */
        .action-buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
            flex-wrap: wrap;
        }

        .action-btn {
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 16px;
            transition: all 0.3s;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .btn-success {
            background: var(--success);
            color: white;
        }

        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
        }

        /* Instructions */
        .instructions {
            background: #fff9e6;
            border: 2px solid #ffc107;
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
        }

        .instructions h4 {
            color: #856404;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .instructions ul {
            margin-left: 20px;
            color: #666;
        }

        .instructions li {
            margin-bottom: 8px;
        }

        /* Recent Bills */
        .recent-bills {
            background: var(--white);
            border-radius: 15px;
            padding: 30px;
            box-shadow: var(--shadow);
            margin-top: 30px;
        }

        .bill-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        .bill-table th {
            background: var(--light-bg);
            color: var(--dark);
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }

        .bill-table td {
            padding: 12px;
            border-bottom: 1px solid #eee;
        }

        .bill-table tr:hover {
            background: var(--light-bg);
        }

        /* Message Box */
        .message-box {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: 500;
        }

        .message-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .message-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .top-nav {
                padding: 15px;
                flex-direction: column;
                gap: 15px;
            }
            
            .user-section {
                width: 100%;
                justify-content: space-between;
            }
            
            .main-container {
                padding: 0 15px;
            }
            
            .search-bar {
                flex-direction: column;
            }
            
            .action-buttons {
                flex-direction: column;
            }
            
            .action-btn {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>

    <!-- Top Navigation -->
    <nav class="top-nav">
        <div class="logo-section">
            <i class="fas fa-umbrella-beach logo-icon"></i>
            <div class="logo-text">
                <h1>Ocean View Resort</h1>
                <p style="font-size: 12px; color: #666; margin-top: 2px;">Bill Generation System</p>
            </div>
        </div>
        
        <div class="user-section">
            <div class="user-info">
                <div class="user-name"><%= user %></div>
                 <!-- REMOVED: <div class="user-badge">Staff</div> -->
            </div>
            
            <div class="user-avatar">
                <%= user.substring(0, 1).toUpperCase() %>
            </div>
            
            <a href="dashboard.jsp" class="back-btn">
                <i class="fas fa-arrow-left"></i> Back to Dashboard
            </a>
        </div>
    </nav>

    <!-- Main Container -->
    <div class="main-container">
        
        <!-- Hero Section -->
        <div class="hero-section">
            <h1 class="hero-title">Generate Guest Bill</h1>
            <p class="hero-subtitle">Create professional invoices for guest stays at Ocean View Resort</p>
        </div>

        <!-- Display Messages -->
        <% if ("success".equals(type) && message != null) { %>
            <div class="message-box message-success">
                <i class="fas fa-check-circle"></i> <%= java.net.URLDecoder.decode(message, "UTF-8") %>
            </div>
        <% } %>
        
        <% if ("error".equals(type) && message != null) { %>
            <div class="message-box message-error">
                <i class="fas fa-exclamation-circle"></i> <%= java.net.URLDecoder.decode(message, "UTF-8") %>
            </div>
        <% } %>

        <!-- Bill Container -->
        <div class="bill-container">
            <h2 class="section-title">
                <i class="fas fa-search"></i> Find Reservation to Bill
            </h2>

            <!-- Search Section -->
            <div class="search-section">
                <p style="margin-bottom: 20px; color: #666;">Enter reservation number to generate bill:</p>
                
                <form action="generate-bill" method="GET" onsubmit="return validateSearch()" id="searchForm">
                    <div class="search-bar">
                        <input type="text" 
                               id="reservationNumber" 
                               name="number" 
                               placeholder="Enter reservation number (e.g., RES20241225103045)"
                               required>
                        <button type="submit" class="search-btn">
                            <i class="fas fa-search"></i> Find & Generate Bill
                        </button>
                    </div>
                </form>

                <p style="margin-top: 15px; font-size: 14px; color: #666;">
                    <i class="fas fa-info-circle"></i> 
                    Need to find a reservation number? 
                    <a href="view-reservations" style="color: var(--primary); text-decoration: none; font-weight: 500;">
                        View all reservations here
                    </a>
                </p>
            </div>

            <!-- Quick Options -->
            <div class="quick-options">
                <div class="option-card" onclick="document.getElementById('reservationNumber').value = 'RES20241225103045'; document.getElementById('searchForm').submit();">
                    <i class="fas fa-bolt option-icon"></i>
                    <h3>Quick Demo</h3>
                    <p>Try with sample reservation to see bill preview</p>
                </div>
                
                <div class="option-card" onclick="window.location.href='view-reservations?filter=active'">
                    <i class="fas fa-users option-icon"></i>
                    <h3>Active Stays</h3>
                    <p>View all currently active reservations for billing</p>
                </div>
                
                <div class="option-card" onclick="window.location.href='view-reservations?filter=completed'">
                    <i class="fas fa-calendar-check option-icon"></i>
                    <h3>Completed Stays</h3>
                    <p>Generate bills for recently completed stays</p>
                </div>
                
                <div class="option-card" onclick="window.open('bill-sample.pdf', '_blank')">
                    <i class="fas fa-file-pdf option-icon"></i>
                    <h3>Sample Bill</h3>
                    <p>View a sample bill format and layout</p>
                </div>
            </div>

            <!-- Bill Instructions -->
            <div class="instructions">
                <h4><i class="fas fa-lightbulb"></i> How to Generate a Bill</h4>
                <ul>
                    <li>Enter the reservation number exactly as shown in the reservation details</li>
                    <li>Click "Find & Generate Bill" to create the invoice</li>
                    <li>Review the bill details including room charges and tax</li>
                    <li>Click "Print Invoice" to get a printable version</li>
                    <li>Click "Email to Guest" to send a digital copy (if email available)</li>
                    <li>Mark the bill as "Paid" once payment is received</li>
                </ul>
            </div>
        </div>

        <!-- Bill Preview (Initially Hidden) -->
        <div class="bill-preview" id="billPreview">
            <h3 class="preview-title">Bill Preview</h3>
            
            <div class="preview-info">
                <div class="info-item">
                    <div class="info-label">Reservation Number</div>
                    <div class="info-value" id="previewResNum">RES20241225103045</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Guest Name</div>
                    <div class="info-value" id="previewGuest">John Smith</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Room Type & Number</div>
                    <div class="info-value" id="previewRoom">Deluxe • Room 201</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Stay Period</div>
                    <div class="info-value" id="previewStay">Dec 25 - Dec 28, 2024 (3 nights)</div>
                </div>
            </div>

            <div class="amount-breakdown">
                <h4 style="color: var(--dark); margin-bottom: 15px;">Amount Breakdown</h4>
                
                <div class="amount-row">
                    <span>Room Charges (3 nights × Rs. 38,400)</span>
                    <span>Rs. 115,200</span>
                </div>
                <div class="amount-row">
                    <span>Additional Services</span>
                    <span>Rs. 0</span>
                </div>
                <div class="amount-row">
                    <span>VAT (15%)</span>
                    <span>Rs. 17,280</span>
                </div>
                <div class="amount-row">
                    <span>Service Charge (10%)</span>
                    <span>Rs. 11,520</span>
                </div>
                <div class="amount-row">
                    <span><strong>TOTAL AMOUNT PAYABLE</strong></span>
                    <span><strong>Rs. 144,000</strong></span>
                </div>
            </div>

            <div class="action-buttons">
                <button class="action-btn btn-success" onclick="printBill()">
                    <i class="fas fa-print"></i> Print Invoice
                </button>
                <button class="action-btn btn-primary" onclick="emailBill()">
                    <i class="fas fa-envelope"></i> Email to Guest
                </button>
                <button class="action-btn" style="background: #28a745; color: white;" onclick="markAsPaid()">
                    <i class="fas fa-check-circle"></i> Mark as Paid
                </button>
                <button class="action-btn btn-secondary" onclick="hidePreview()">
                    <i class="fas fa-times"></i> Close Preview
                </button>
            </div>
        </div>

        <!-- Recent Bills (Optional) -->
        <div class="recent-bills">
            <h2 class="section-title">
                <i class="fas fa-history"></i> Recently Generated Bills
            </h2>
            
            <table class="bill-table">
                <thead>
                    <tr>
                        <th>Bill #</th>
                        <th>Reservation #</th>
                        <th>Guest Name</th>
                        <th>Amount</th>
                        <th>Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr onclick="window.location.href='generate-bill?number=RES20241224183022'">
                        <td>INV-001</td>
                        <td>RES20241224183022</td>
                        <td>Sarah Johnson</td>
                        <td>Rs. 76,800</td>
                        <td>Dec 24, 2024</td>
                        <td><span style="color: #28a745; font-weight: 600;">PAID</span></td>
                    </tr>
                    <tr onclick="window.location.href='generate-bill?number=RES20241223154510'">
                        <td>INV-002</td>
                        <td>RES20241223154510</td>
                        <td>Robert Chen</td>
                        <td>Rs. 294,400</td>
                        <td>Dec 23, 2024</td>
                        <td><span style="color: #dc3545; font-weight: 600;">PENDING</span></td>
                    </tr>
                    <tr onclick="window.location.href='generate-bill?number=RES20241222112030'">
                        <td>INV-003</td>
                        <td>RES20241222112030</td>
                        <td>Maria Garcia</td>
                        <td>Rs. 115,200</td>
                        <td>Dec 22, 2024</td>
                        <td><span style="color: #28a745; font-weight: 600;">PAID</span></td>
                    </tr>
                </tbody>
            </table>
            
            <div style="text-align: center; margin-top: 20px;">
                <a href="view-reservations" style="color: var(--primary); text-decoration: none; font-weight: 500;">
                    <i class="fas fa-list"></i> View all reservations for billing
                </a>
            </div>
        </div>

        <!-- Footer -->
        <footer class="dashboard-footer" style="margin-top: 50px; text-align: center; padding: 20px; color: #666; border-top: 1px solid #e9ecef;">
            <p>Ocean View Resort Billing System • All amounts in Sri Lankan Rupees (LKR) • VAT 15% included</p>
            <p style="margin-top: 5px; font-size: 12px;">
                Room Rates: Standard - Rs. 25,600/night | Deluxe - Rs. 38,400/night | Suite - Rs. 64,000/night
            </p>
        </footer>
    </div>

    <script>
        // Form validation
        function validateSearch() {
            const reservationNumber = document.getElementById('reservationNumber').value.trim();
            
            if (!reservationNumber) {
                alert('Please enter a reservation number');
                return false;
            }
            
            if (!reservationNumber.startsWith('RES')) {
                alert('Reservation number should start with "RES"');
                return false;
            }
            
            // Show loading
            showLoading('Searching for reservation...');
            return true;
        }

        // Show loading message
        function showLoading(message) {
            const loadingDiv = document.createElement('div');
            loadingDiv.id = 'loadingMessage';
            loadingDiv.style.cssText = `
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: white;
                padding: 30px 40px;
                border-radius: 12px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                z-index: 4000;
                text-align: center;
                border: 2px solid var(--primary);
                min-width: 300px;
            `;
            loadingDiv.innerHTML = `
                <div style="color: var(--primary); font-size: 48px; margin-bottom: 15px;">
                    <i class="fas fa-spinner fa-spin"></i>
                </div>
                <h3 style="color: #333; margin-bottom: 10px;">Processing</h3>
                <p style="color: #666;">${message}</p>
            `;
            
            document.body.appendChild(loadingDiv);
        }

        // Remove loading message
        function removeLoading() {
            const loading = document.getElementById('loadingMessage');
            if (loading) {
                loading.remove();
            }
        }

        // Show bill preview (for demo purposes)
        function showPreview() {
            document.getElementById('billPreview').classList.add('show');
            window.scrollTo({
                top: document.getElementById('billPreview').offsetTop - 100,
                behavior: 'smooth'
            });
        }

        // Hide bill preview
        function hidePreview() {
            document.getElementById('billPreview').classList.remove('show');
        }

        // Print bill function
        function printBill() {
            alert('Print functionality would open the actual bill page for printing.');
            // In actual implementation, this would redirect to the print-ready bill page
            // window.location.href = 'generate-bill?number=' + reservationNumber + '&print=true';
        }

        // Email bill function
        function emailBill() {
            alert('Email functionality would send the bill to the guest\'s email address.');
            // This would typically call a backend service to send email
        }

        // Mark as paid function
        function markAsPaid() {
            if (confirm('Mark this bill as PAID?\n\nThis will update the reservation status.')) {
                alert('Bill marked as paid. Reservation status updated.');
                // This would call backend to update payment status
            }
        }

        // Quick demo functionality
        function quickDemo() {
            document.getElementById('reservationNumber').value = 'RES20241225103045';
            showPreview();
        }

        // Handle page load
        window.onload = function() {
            // Remove any loading messages
            removeLoading();
            
            // Check URL for reservation number
            const urlParams = new URLSearchParams(window.location.search);
            const reservationNumber = urlParams.get('number');
            
            if (reservationNumber) {
                document.getElementById('reservationNumber').value = reservationNumber;
                // Auto-submit if number is provided
                // document.getElementById('searchForm').submit();
            }
            
            // Show demo message for first-time users
            const hasVisited = localStorage.getItem('billPageVisited');
            if (!hasVisited) {
                setTimeout(function() {
                    alert('💡 Tip: Click "Quick Demo" to see a sample bill preview!');
                    localStorage.setItem('billPageVisited', 'true');
                }, 1000);
            }
        };

        // Handle form submission
        document.getElementById('searchForm').addEventListener('submit', function(e) {
            // This function already calls validateSearch()
            // Loading is shown in validateSearch()
        });
    </script>
</body>
</html>