<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) userSession.getAttribute("username");
    
    // Get error/success messages from URL
    String type = request.getParameter("type");
    String message = request.getParameter("message");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New Reservation - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============ GLOBAL STYLES (MATCHING DASHBOARD) ============ */
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

        /* ============ COLOR VARIABLES (MATCHING DASHBOARD) ============ */
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
            --info: #17a2b8;
            --shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
            --border-radius: 10px;
        }

        /* ============ TOP NAVIGATION (MATCHING DASHBOARD) ============ */
        .top-nav {
            background: var(--white);
            padding: 0 30px;
            height: 70px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo-icon {
            color: var(--primary);
            font-size: 28px;
        }

        .logo-text h1 {
            font-size: 20px;
            color: var(--dark);
            font-weight: 600;
        }

        .logo-text p {
            font-size: 11px;
            color: #888;
            margin-top: 2px;
        }

        .user-section {
            display: flex;
            align-items: center;
            gap: 25px;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .user-details {
            text-align: right;
        }

        .user-name {
            font-weight: 600;
            color: var(--dark);
            font-size: 15px;
            line-height: 1.3;
        }

        .user-avatar {
            width: 42px;
            height: 42px;
            background: var(--primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 500;
            font-size: 18px;
            flex-shrink: 0;
        }

        .logout-btn {
            background: transparent;
            color: #6c757d;
            border: 1px solid #e9ecef;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
            white-space: nowrap;
        }

        .logout-btn:hover {
            background: #fff5f5;
            color: var(--danger);
            border-color: var(--danger);
        }

        /* ============ MAIN CONTAINER ============ */
        .page-wrapper {
            max-width: 700px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* ============ PAGE CARD ============ */
        .page-card {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        /* ============ PAGE HEADER ============ */
        .page-header {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 25px 30px;
        }

        .page-header h1 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .page-header h1 i {
            opacity: 0.9;
        }

        .page-header p {
            font-size: 14px;
            opacity: 0.9;
            display: flex;
            align-items: center;
            gap: 5px;
        }

        /* ============ MESSAGE STYLES ============ */
        .message-container {
            padding: 20px 30px 0;
        }

        .message {
            padding: 15px 20px;
            border-radius: 8px;
            display: flex;
            align-items: flex-start;
            gap: 12px;
            font-size: 14px;
            margin-bottom: 15px;
            border-left: 4px solid transparent;
        }

        .message.success {
            background: #d4edda;
            color: #155724;
            border-left-color: var(--success);
        }

        .message.error {
            background: #f8d7da;
            color: #721c24;
            border-left-color: var(--danger);
        }

        .message i {
            font-size: 18px;
            margin-top: 2px;
        }

        .message-tip {
            margin-top: 10px;
            font-size: 12px;
            background: rgba(0,0,0,0.05);
            padding: 8px 12px;
            border-radius: 6px;
        }

        /* ============ INFO BOX ============ */
        .info-box {
            background: var(--light-bg);
            border: 1px solid #e9ecef;
            border-left: 4px solid var(--primary);
            border-radius: 8px;
            padding: 15px 20px;
            margin: 20px 30px;
            display: flex;
            align-items: flex-start;
            gap: 15px;
        }

        .info-box i {
            color: var(--primary);
            font-size: 20px;
            margin-top: 2px;
        }

        .info-content strong {
            color: var(--dark);
            font-size: 14px;
            display: block;
            margin-bottom: 5px;
        }

        .info-content span {
            color: #666;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        .info-content span i {
            color: var(--primary);
            font-size: 13px;
        }

        /* ============ FORM CONTAINER ============ */
        .form-container {
            padding: 0 30px 30px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 6px;
            color: var(--dark);
            font-weight: 600;
            font-size: 14px;
        }

        .form-group label i {
            color: var(--primary);
            width: 18px;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px 15px;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            color: #333;
            background: var(--white);
            transition: all 0.2s;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 119, 182, 0.1);
        }

        .form-group input[readonly] {
            background: var(--light-bg);
            color: #666;
            cursor: not-allowed;
            border-color: #e9ecef;
        }

        .form-group small {
            display: block;
            margin-top: 5px;
            color: #888;
            font-size: 12px;
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .form-group small i {
            color: var(--primary);
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        /* ============ ROOM SELECTION CONTROLS ============ */
        .room-controls {
            display: flex;
            gap: 10px;
            align-items: center;
            margin-top: 10px;
        }

        .refresh-btn {
            background: var(--light-bg);
            border: 1px solid var(--primary);
            color: var(--primary);
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.2s;
        }

        .refresh-btn:hover {
            background: var(--primary);
            color: white;
        }

        .availability-warning {
            color: var(--danger);
            font-size: 12px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        /* ============ NO ROOMS WARNING ============ */
        .no-rooms-warning {
            margin-top: 10px;
            padding: 12px 15px;
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 6px;
            color: #856404;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
        }

        .no-rooms-warning i {
            font-size: 16px;
            color: #ffc107;
        }

        /* ============ ROOM DETAILS CARD ============ */
        .room-details-card {
            background: var(--light-bg);
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            margin-top: 15px;
            display: none;
        }

        .room-details-card h4 {
            color: var(--dark);
            font-size: 15px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
            border-bottom: 1px solid #e9ecef;
            padding-bottom: 10px;
        }

        .room-details-card h4 i {
            color: var(--primary);
        }

        .room-details-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
        }

        .room-detail-item {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }

        .room-detail-item .label {
            font-size: 12px;
            color: #666;
        }

        .room-detail-item .value {
            font-size: 15px;
            font-weight: 600;
            color: var(--dark);
        }

        .room-feature-tag {
            background: var(--white);
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            color: #555;
            display: inline-block;
            margin: 2px;
            border: 1px solid #e9ecef;
        }

        .room-features-container {
            grid-column: span 2;
            margin-top: 5px;
        }

        /* ============ LOADING INDICATOR ============ */
        .loading {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 14px;
            display: none;
        }

        .loading i {
            color: var(--primary);
            margin-right: 8px;
        }

        /* ============ AUTO-ASSIGN BADGE ============ */
        .auto-assign-badge {
            background: #e8f4fd;
            border: 1px dashed var(--primary);
            color: var(--dark);
            padding: 10px 15px;
            border-radius: 8px;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 10px;
        }

        .auto-assign-badge i {
            color: var(--primary);
        }

        /* ============ FRESHNESS NOTE ============ */
        .freshness-note {
            display: block;
            margin-top: 5px;
            color: #888;
            font-size: 11px;
        }

        .freshness-note i {
            color: var(--primary);
        }

        /* ============ SUBMIT BUTTON ============ */
        .btn-submit {
            background: linear-gradient(45deg, var(--primary), var(--secondary));
            color: white;
            border: none;
            padding: 14px 20px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            margin-top: 25px;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }

        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 119, 182, 0.3);
        }

        .btn-submit i {
            font-size: 18px;
        }

        /* ============ BACK LINK ============ */
        .back-link-container {
            text-align: center;
            padding: 20px 30px 30px;
        }

        .back-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #666;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            padding: 8px 20px;
            border-radius: 8px;
            background: var(--light-bg);
            border: 1px solid #e9ecef;
            transition: all 0.2s;
        }

        .back-btn:hover {
            background: #e9ecef;
            color: var(--primary);
            border-color: var(--primary);
        }

        .back-btn i {
            color: var(--primary);
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 768px) {
            .top-nav {
                padding: 0 20px;
            }
            
            .user-section {
                gap: 20px;
            }
            
            .user-info {
                gap: 12px;
            }
            
            .logout-btn span {
                display: none;
            }
            
            .logout-btn {
                padding: 8px;
                border-radius: 50%;
            }
            
            .user-details {
                display: none;
            }
            
            .page-wrapper {
                margin: 20px auto;
            }
            
            .page-header {
                padding: 20px;
            }
            
            .page-header h1 {
                font-size: 22px;
            }
            
            .form-container {
                padding: 0 20px 20px;
            }
            
            .info-box {
                margin: 15px 20px;
                flex-direction: column;
                gap: 8px;
            }
            
            .info-content span {
                gap: 8px;
            }
            
            .form-row {
                grid-template-columns: 1fr;
                gap: 0;
            }
            
            .room-details-grid {
                grid-template-columns: 1fr;
            }
            
            .room-features-container {
                grid-column: span 1;
            }
            
            .back-link-container {
                padding: 15px 20px 20px;
            }
        }
    </style>
</head>
<body>

    <!-- ============ TOP NAVIGATION (MATCHING DASHBOARD) ============ -->
    <nav class="top-nav">
        <div class="logo-section">
            <i class="fas fa-umbrella-beach logo-icon"></i>
            <div class="logo-text">
                <h1>Ocean View Resort</h1>
                <p>Reservation System</p>
            </div>
        </div>
        
        <div class="user-section">
            <div class="user-info">
                <div class="user-details">
                    <div class="user-name"><%= user %></div>
                </div>
                <div class="user-avatar">
                    <%= user.substring(0, 1).toUpperCase() %>
                </div>
            </div>
            <a href="logout" class="logout-btn">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </div>
    </nav>

    <!-- ============ PAGE WRAPPER ============ -->
    <div class="page-wrapper">
        <div class="page-card">
            
            <!-- ============ PAGE HEADER ============ -->
            <div class="page-header">
                <h1>
                    <i class="fas fa-calendar-plus"></i>
                    New Reservation
                </h1>
                <p>
                    <i class="fas fa-sun"></i>
                    Create a new booking for your guests
                </p>
            </div>

            <!-- ============ MESSAGES ============ -->
            <% if ("error".equals(type) && message != null) { 
                String errorMsg = java.net.URLDecoder.decode(message, "UTF-8");
            %>
                <div class="message-container">
                    <div class="message error">
                        <i class="fas fa-exclamation-circle"></i>
                        <%= errorMsg %>
                    </div>
                </div>
            <% } %>

            <!-- ============ INFO BOX ============ -->
            <div class="info-box">
                <i class="fas fa-info-circle"></i>
                <div class="info-content">
                    <strong>Reservation Information</strong>
                    <span>
                        <i class="fas fa-hashtag"></i> Auto-generated number
                        <i class="fas fa-door-closed"></i> Only available rooms shown
                        <i class="fas fa-star"></i> * Required fields
                    </span>
                </div>
            </div>

            <!-- ============ FORM ============ -->
            <form action="${pageContext.request.contextPath}/add-reservation" method="post" class="form-container" id="reservationForm">
                
                <!-- Reservation Number (Auto-generated) -->
                <div class="form-group">
                    <label for="reservationNumber">
                        <i class="fas fa-hashtag"></i> Reservation Number
                    </label>
                    <input type="text" id="reservationNumber" name="reservationNumber" readonly required>
                    <small>
                        <i class="fas fa-sync-alt fa-spin"></i> Auto-generated unique number
                    </small>
                </div>

                <!-- Guest Name -->
                <div class="form-group">
                    <label for="guestName">
                        <i class="fas fa-user"></i> Guest Name *
                    </label>
                    <input type="text" id="guestName" name="guestName" 
                           placeholder="e.g., John Smith" required>
                </div>

                <!-- Contact Info Row -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="contactNumber">
                            <i class="fas fa-phone"></i> Contact Number *
                        </label>
                        <input type="tel" id="contactNumber" name="contactNumber" 
                               placeholder="0771234567" required pattern="[0-9]{10}" 
                               title="Please enter exactly 10 digits">
                    </div>

                    <div class="form-group">
                        <label for="roomType">
                            <i class="fas fa-bed"></i> Room Type *
                        </label>
                        <select id="roomType" name="roomType" required>
                            <option value="">Select room type</option>
                            <option value="Standard" data-rate="25600">Standard (Rs. 25,600/night)</option>
                            <option value="Deluxe" data-rate="38400">Deluxe (Rs. 38,400/night)</option>
                            <option value="Suite" data-rate="64000">Suite (Rs. 64,000/night)</option>
                        </select>
                    </div>
                </div>

                <!-- Dates Row -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="checkIn">
                            <i class="fas fa-sign-in-alt"></i> Check-in Date *
                        </label>
                        <input type="date" id="checkIn" name="checkIn" required>
                    </div>

                    <div class="form-group">
                        <label for="checkOut">
                            <i class="fas fa-sign-out-alt"></i> Check-out Date *
                        </label>
                        <input type="date" id="checkOut" name="checkOut" required>
                    </div>
                </div>

                <!-- Room Selection -->
                <div class="form-group">
                    <label for="roomNumber">
                        <i class="fas fa-door-closed"></i> Room Assignment
                    </label>
                    <select id="roomNumber" name="roomNumber">
                        <option value="">-- Select room type and dates first --</option>
                    </select>
                    
                    <!-- Room controls -->
                    <div class="room-controls">
                        <button type="button" id="refreshRoomsBtn" class="refresh-btn" style="display: none;">
                            <i class="fas fa-sync-alt"></i> Refresh Availability
                        </button>
                        <span id="availabilityWarning" class="availability-warning" style="display: none;">
                            <i class="fas fa-exclamation-triangle"></i> Data may be outdated
                        </span>
                    </div>

                    <div id="roomLoading" class="loading">
                        <i class="fas fa-spinner fa-spin"></i> Loading available rooms...
                    </div>
                    
                    <!-- Auto-assign info -->
                    <div class="auto-assign-badge" id="autoAssignInfo" style="display: none;">
                        <i class="fas fa-magic"></i>
                        <span>Room will be auto-assigned based on availability</span>
                    </div>

                    <!-- No rooms warning (shown when no rooms available) -->
                    <div id="noRoomsWarning" class="no-rooms-warning" style="display: none;">
                        <i class="fas fa-exclamation-triangle"></i>
                        <span>No rooms available for selected dates. Please try different dates or room type.</span>
                    </div>

                    <!-- Room Details Card -->
                    <div id="roomDetails" class="room-details-card">
                        <h4><i class="fas fa-info-circle"></i> Selected Room Details</h4>
                        <div class="room-details-grid">
                            <div class="room-detail-item">
                                <span class="label">Room Number</span>
                                <span class="value" id="detailRoomNumber">-</span>
                            </div>
                            <div class="room-detail-item">
                                <span class="label">Floor</span>
                                <span class="value" id="detailFloor">-</span>
                            </div>
                            <div class="room-detail-item">
                                <span class="label">Status</span>
                                <span class="value" id="detailStatus">-</span>
                            </div>
                            <div class="room-detail-item">
                                <span class="label">Rate per Night</span>
                                <span class="value" id="detailRate">-</span>
                            </div>
                            <div class="room-features-container">
                                <span class="label">Features</span>
                                <div id="detailFeatures" style="margin-top: 8px;"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Calculation Row -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="nights">
                            <i class="fas fa-moon"></i> Number of Nights
                        </label>
                        <input type="text" id="nights" readonly>
                    </div>

                    <div class="form-group">
                        <label for="estimatedTotal">
                            <i class="fas fa-coins"></i> Estimated Total
                        </label>
                        <input type="text" id="estimatedTotal" readonly>
                    </div>
                </div>

                <!-- Address -->
                <div class="form-group">
                    <label for="address">
                        <i class="fas fa-map-marker-alt"></i> Address
                    </label>
                    <textarea id="address" name="address" rows="3" 
                              placeholder="Guest's permanent address..."></textarea>
                </div>

                <!-- Hidden field for form token to prevent duplicate submissions -->
                <input type="hidden" name="formToken" id="formToken" value="">

                <!-- Submit Button -->
                <button type="submit" class="btn-submit">
                    <i class="fas fa-save"></i> Create Reservation
                </button>
            </form>

            <!-- Back Link -->
            <div class="back-link-container">
                <a href="dashboard.jsp" class="back-btn">
                    <i class="fas fa-arrow-left"></i> Back to Dashboard
                </a>
            </div>
        </div>
    </div>

    <script>
    // ============ GLOBAL VARIABLES ============
    let lastRoomLoadTime = null;
    const ROOM_DATA_EXPIRY = 30000; // 30 seconds

    // ============ HELPER FUNCTIONS ============
    function formatNumber(num) {
        if (!num) return '0';
        return parseInt(num).toLocaleString('en-LK');
    }
    
    function formatRupees(amount) {
        return 'Rs. ' + formatNumber(amount);
    }

    function generateFormToken() {
        return 'token_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    // ============ INITIAL SETUP ============
    // Set minimum date to today for check-in
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('checkIn').min = today;
    document.getElementById('checkIn').value = today;
    
    // Set check-out to tomorrow by default
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];
    document.getElementById('checkOut').min = tomorrowStr;
    document.getElementById('checkOut').value = tomorrowStr;
    
    // Generate unique reservation number
    function generateReservationNumber() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        return 'RES' + year + month + day + hours + minutes + seconds;
    }
    
    // Set reservation number
    document.getElementById('reservationNumber').value = generateReservationNumber();
    
    // Set form token
    document.getElementById('formToken').value = generateFormToken();
    
    // ============ CALCULATION FUNCTIONS ============
    function calculateNights() {
        const checkIn = document.getElementById('checkIn').value;
        const checkOut = document.getElementById('checkOut').value;
        
        if (!checkIn || !checkOut) return 0;
        
        const checkInDate = new Date(checkIn);
        const checkOutDate = new Date(checkOut);
        const diffTime = Math.abs(checkOutDate - checkInDate);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        document.getElementById('nights').value = diffDays + ' night' + (diffDays > 1 ? 's' : '');
        return diffDays;
    }
    
    function updateRoomRate() {
        const roomType = document.getElementById('roomType');
        const selectedOption = roomType.options[roomType.selectedIndex];
        const rate = selectedOption ? selectedOption.getAttribute('data-rate') : null;
        
        if (rate) {
            const nights = calculateNights();
            const total = nights * parseInt(rate);
            document.getElementById('estimatedTotal').value = formatRupees(total);
        } else {
            document.getElementById('estimatedTotal').value = '';
        }
    }
    
    // ============ ROOM AVAILABILITY FUNCTIONS ============
    function checkRoomDataFreshness() {
        const refreshBtn = document.getElementById('refreshRoomsBtn');
        const warning = document.getElementById('availabilityWarning');
        
        if (lastRoomLoadTime && (Date.now() - lastRoomLoadTime > ROOM_DATA_EXPIRY)) {
            refreshBtn.style.display = 'inline-flex';
            warning.style.display = 'inline';
        } else {
            refreshBtn.style.display = 'none';
            warning.style.display = 'none';
        }
    }
    
    function validateRoomAvailability() {
        const roomSelect = document.getElementById('roomNumber');
        const selectedOption = roomSelect.options[roomSelect.selectedIndex];
        
        if (!selectedOption || !selectedOption.value) {
            return true; // No room selected, will use AUTO
        }
        
        if (selectedOption.value === 'AUTO') {
            return true; // AUTO selection is fine
        }
        
        // Check if data is too old
        if (lastRoomLoadTime && (Date.now() - lastRoomLoadTime > ROOM_DATA_EXPIRY)) {
            if (!confirm('Room availability data is more than 30 seconds old. Would you like to refresh before submitting?')) {
                return false;
            } else {
                loadAvailableRooms();
                return false;
            }
        }
        
        return true;
    }
    
    function loadAvailableRooms() {
        const roomType = document.getElementById('roomType').value;
        const checkIn = document.getElementById('checkIn').value;
        const checkOut = document.getElementById('checkOut').value;
        
        if (!roomType || roomType === '' || !checkIn || !checkOut) {
            document.getElementById('roomNumber').innerHTML = '<option value="">-- Select room type and dates first --</option>';
            document.getElementById('roomLoading').style.display = 'none';
            document.getElementById('autoAssignInfo').style.display = 'none';
            document.getElementById('noRoomsWarning').style.display = 'none';
            return;
        }
        
        // Show loading indicator
        document.getElementById('roomLoading').style.display = 'block';
        document.getElementById('roomDetails').style.display = 'none';
        document.getElementById('autoAssignInfo').style.display = 'none';
        document.getElementById('noRoomsWarning').style.display = 'none';
        
        // Record load time
        lastRoomLoadTime = Date.now();
        
        // Construct URL to fetch available rooms
        const contextPath = '${pageContext.request.contextPath}' || '';
        const url = (contextPath ? contextPath : '') + '/available-rooms?roomType=' + 
                    encodeURIComponent(roomType) + '&checkIn=' + encodeURIComponent(checkIn) + 
                    '&checkOut=' + encodeURIComponent(checkOut);
        
        // Fetch available rooms
        fetch(url)
            .then(response => {
                if (!response.ok) {
                    throw new Error('Server error: ' + response.status);
                }
                return response.json();
            })
            .then(rooms => {
                const select = document.getElementById('roomNumber');
                select.innerHTML = '<option value="">-- Select a room --</option>';
                
                // Hide no rooms warning by default
                document.getElementById('noRoomsWarning').style.display = 'none';
                
                if (!rooms || rooms.length === 0) {
                    // No rooms available - show warning
                    select.innerHTML += '<option value="" disabled>No rooms available</option>';
                    document.getElementById('noRoomsWarning').style.display = 'flex';
                    document.getElementById('autoAssignInfo').style.display = 'none';
                } else {
                    // Add available rooms to dropdown
                    rooms.forEach(room => {
                        const option = document.createElement('option');
                        option.value = room.roomNumber;
                        option.textContent = 'Room ' + room.roomNumber + ' (Floor ' + room.floor + ') - ' + formatRupees(room.rate) + '/night';
                        option.setAttribute('data-floor', room.floor);
                        option.setAttribute('data-rate', room.rate);
                        option.setAttribute('data-status', room.status);
                        option.setAttribute('data-features', room.features || 'Standard amenities');
                        option.setAttribute('data-load-time', Date.now());
                        select.appendChild(option);
                    });
                    
                    // Add auto-assign option
                    const autoOption = document.createElement('option');
                    autoOption.value = 'AUTO';
                    autoOption.textContent = '✨ Auto-assign best available room';
                    select.appendChild(autoOption);
                    
                    // Show auto-assign info
                    document.getElementById('autoAssignInfo').style.display = 'flex';
                }
                
                // Add freshness note
                const selectParent = select.parentNode;
                const oldNote = document.getElementById('freshness-note');
                if (oldNote) oldNote.remove();
                
                const note = document.createElement('small');
                note.id = 'freshness-note';
                note.className = 'freshness-note';
                note.innerHTML = '<i class="fas fa-clock"></i> Showing only available rooms as of ' + new Date().toLocaleTimeString();
                selectParent.appendChild(note);
                
                document.getElementById('roomLoading').style.display = 'none';
                checkRoomDataFreshness();
            })
            .catch(error => {
                console.error('Error loading rooms:', error);
                
                // Show error message to user
                document.getElementById('roomLoading').style.display = 'none';
                document.getElementById('noRoomsWarning').style.display = 'flex';
                document.getElementById('noRoomsWarning').innerHTML = '<i class="fas fa-exclamation-triangle"></i>' +
                    '<span>Error loading room data. Please try again or use auto-assign.</span>';
            });
    }
    
    // Show room details when a room is selected
    function showRoomDetails() {
        const select = document.getElementById('roomNumber');
        const selectedOption = select.options[select.selectedIndex];
        const detailsDiv = document.getElementById('roomDetails');
        const autoAssignInfo = document.getElementById('autoAssignInfo');
        
        if (selectedOption && selectedOption.value && selectedOption.value !== 'AUTO') {
            // Show room details
            document.getElementById('detailRoomNumber').textContent = selectedOption.value;
            document.getElementById('detailFloor').textContent = selectedOption.getAttribute('data-floor') || '-';
            document.getElementById('detailStatus').textContent = selectedOption.getAttribute('data-status') || 'Available';
            
            const rate = selectedOption.getAttribute('data-rate');
            document.getElementById('detailRate').textContent = rate ? formatRupees(rate) : '-';
            
            const features = selectedOption.getAttribute('data-features') || 'Standard amenities';
            const featuresArray = features.split(',').filter(f => f.trim());
            let featuresHtml = '';
            featuresArray.forEach(f => {
                featuresHtml += '<span class="room-feature-tag">' + f.trim() + '</span> ';
            });
            document.getElementById('detailFeatures').innerHTML = featuresHtml;
            
            detailsDiv.style.display = 'block';
            autoAssignInfo.style.display = 'none';
        } else if (selectedOption && selectedOption.value === 'AUTO') {
            // Show auto-assign info
            detailsDiv.style.display = 'none';
            autoAssignInfo.style.display = 'flex';
        } else {
            detailsDiv.style.display = 'none';
            autoAssignInfo.style.display = 'none';
        }
    }
    
    // Update dates and validate
    function updateDates() {
        const checkInInput = document.getElementById('checkIn');
        const checkOutInput = document.getElementById('checkOut');
        const checkInDate = new Date(checkInInput.value);
        const checkOutDate = new Date(checkOutInput.value);
        
        // Ensure check-out is at least one day after check-in
        const minCheckOut = new Date(checkInDate);
        minCheckOut.setDate(minCheckOut.getDate() + 1);
        const minCheckOutStr = minCheckOut.toISOString().split('T')[0];
        
        checkOutInput.min = minCheckOutStr;
        
        if (checkOutDate <= checkInDate) {
            checkOutInput.value = minCheckOutStr;
        }
        
        calculateNights();
        updateRoomRate();
    }
    
    // ============ SETUP EVENT LISTENERS ============
    function setupEventListeners() {
        // Room type change
        document.getElementById('roomType').addEventListener('change', function() {
            updateRoomRate();
            loadAvailableRooms();
        });
        
        // Check-in date change
        document.getElementById('checkIn').addEventListener('change', function() {
            updateDates();
            loadAvailableRooms();
        });
        
        // Check-out date change  
        document.getElementById('checkOut').addEventListener('change', function() {
            updateDates();
            loadAvailableRooms();
        });
        
        // Room number selection
        document.getElementById('roomNumber').addEventListener('change', showRoomDetails);
        
        // Refresh button
        document.getElementById('refreshRoomsBtn').addEventListener('click', function() {
            loadAvailableRooms();
        });
        
        // Form validation and submission
        document.getElementById('reservationForm').addEventListener('submit', function(e) {
            const checkIn = document.getElementById('checkIn').value;
            const checkOut = document.getElementById('checkOut').value;
            const guestName = document.getElementById('guestName').value.trim();
            const contactNumber = document.getElementById('contactNumber').value;
            const roomType = document.getElementById('roomType').value;
            
            // Date validation
            if (new Date(checkOut) <= new Date(checkIn)) {
                e.preventDefault();
                alert('Check-out date must be after check-in date!');
                return false;
            }
            
            // Name validation
            if (guestName.length < 2) {
                e.preventDefault();
                alert('Please enter a valid guest name!');
                return false;
            }
            
            // Room type validation
            if (!roomType) {
                e.preventDefault();
                alert('Please select a room type!');
                return false;
            }
            
            // Contact number validation
            if (!/^[0-9]{10}$/.test(contactNumber)) {
                e.preventDefault();
                alert('Please enter exactly 10 digits for contact number!');
                return false;
            }
            
            // Room availability validation
            if (!validateRoomAvailability()) {
                e.preventDefault();
                return false;
            }
            
            // Generate new token for this submission
            document.getElementById('formToken').value = generateFormToken();
            
            return true;
        });
    }
    
    // ============ INITIALIZATION ============
    window.onload = function() {
        // Calculate initial values
        calculateNights();
        updateRoomRate();
        
        // Setup event listeners
        setupEventListeners();
        
        // Check room data freshness periodically
        setInterval(checkRoomDataFreshness, 5000);
        
        // Load available rooms after a short delay
        setTimeout(function() {
            const roomType = document.getElementById('roomType').value;
            const checkIn = document.getElementById('checkIn').value;
            const checkOut = document.getElementById('checkOut').value;
            
            if (roomType && checkIn && checkOut) {
                loadAvailableRooms();
            }
        }, 500);
    };
    </script>
</body>
</html>