<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.Reservation, java.time.format.DateTimeFormatter" %>
<%
    Reservation reservation = (Reservation) request.getAttribute("reservation");
    
    System.out.println("=== EDIT RESERVATION JSP ===");
    
    if (reservation == null) {
        System.out.println("❌ ERROR: Reservation is null in edit JSP");
        response.sendRedirect("view-reservations");
        return;
    }
    
    System.out.println("Editing reservation: " + reservation.getReservationNumber());
    
    // Check session
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    String username = (String) userSession.getAttribute("username");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Reservation - Ocean View Resort</title>
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

        /* ============ COLOR VARIABLES ============ */
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
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
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

        .user-badge {
            font-size: 12px;
            color: var(--primary);
            background: #e8f4fd;
            padding: 2px 10px;
            border-radius: 20px;
            display: inline-block;
            font-weight: 500;
            margin-top: 2px;
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

        .back-btn {
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

        .back-btn:hover {
            background: #fff5f5;
            color: var(--danger);
            border-color: var(--danger);
        }

        /* ============ MAIN CONTAINER ============ */
        .container {
            max-width: 700px;
            margin: 90px auto 30px;
            padding: 0 20px;
        }

        /* ============ CARD ============ */
        .card {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        /* ============ CARD HEADER ============ */
        .card-header {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            padding: 25px 30px;
            color: white;
        }

        .card-header h1 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-header h1 i {
            opacity: 0.9;
        }

        .card-header p {
            font-size: 15px;
            opacity: 0.9;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* ============ INFO BOX ============ */
        .info-box {
            background: var(--light-bg);
            padding: 15px 25px;
            margin: 20px 25px;
            border-radius: 8px;
            border-left: 4px solid var(--primary);
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 14px;
            color: var(--dark);
        }

        .info-box i {
            color: var(--primary);
            font-size: 18px;
        }

        .info-box strong {
            color: var(--primary);
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

        /* ============ ROOM DETAILS CARD ============ */
        .room-details {
            background: var(--light-bg);
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            margin-top: 15px;
            display: none;
            animation: fadeIn 0.3s ease;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .room-details h4 {
            color: var(--dark);
            font-size: 15px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
            border-bottom: 1px solid #e9ecef;
            padding-bottom: 10px;
        }

        .room-details h4 i {
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
            gap: 4px;
        }

        .room-detail-item .label {
            font-size: 12px;
            color: #666;
            letter-spacing: 0.3px;
        }

        .room-detail-item .value {
            font-size: 15px;
            font-weight: 600;
            color: var(--dark);
        }

        .room-feature {
            background: var(--white);
            padding: 4px 12px;
            border-radius: 30px;
            font-size: 12px;
            color: #555;
            display: inline-block;
            margin: 2px;
            border: 1px solid #e9ecef;
        }

        .room-features-container {
            grid-column: span 2;
            margin-top: 8px;
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
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 10px;
        }

        .auto-assign-badge i {
            color: var(--primary);
        }

        /* ============ BUTTONS ============ */
        .btn-submit {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
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

        .btn-cancel {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #666;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            padding: 10px 20px;
            border-radius: 8px;
            background: var(--light-bg);
            border: 1px solid #e9ecef;
            transition: all 0.2s;
        }

        .btn-cancel:hover {
            background: #e9ecef;
            color: var(--primary);
            border-color: var(--primary);
        }

        .btn-cancel i {
            color: var(--primary);
        }

        .footer {
            text-align: center;
            padding: 0 30px 30px;
        }

        /* ============ SELECT OPTIONS ============ */
        select option {
            padding: 8px;
        }

        /* ============ CUSTOM SCROLLBAR ============ */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }

        ::-webkit-scrollbar-track {
            background: #f1f1f1;
        }

        ::-webkit-scrollbar-thumb {
            background: var(--primary);
            border-radius: 10px;
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
            
            .back-btn span {
                display: none;
            }
            
            .back-btn {
                padding: 8px;
                border-radius: 50%;
            }
            
            .user-details {
                display: none;
            }
            
            .container {
                margin: 80px auto 20px;
            }
            
            .card-header {
                padding: 20px;
            }
            
            .card-header h1 {
                font-size: 22px;
            }
            
            .info-box {
                margin: 15px 20px;
                padding: 12px 18px;
            }
            
            .form-container {
                padding: 0 20px 20px;
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
        }

        @media (max-width: 480px) {
            .user-avatar {
                width: 36px;
                height: 36px;
                font-size: 16px;
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
                    <div class="user-name"><%= username %></div>
                    <div class="user-badge">Staff</div>
                </div>
                <div class="user-avatar">
                    <%= username.substring(0, 1).toUpperCase() %>
                </div>
            </div>
            <a href="view-reservations" class="back-btn">
                <i class="fas fa-arrow-left"></i>
                <span>Back</span>
            </a>
        </div>
    </nav>

    <!-- ============ MAIN CONTAINER ============ -->
    <div class="container">
        <div class="card">

            <!-- ============ CARD HEADER ============ -->
            <div class="card-header">
                <h1>
                    <i class="fas fa-edit"></i>
                    Edit Reservation
                </h1>
                <p>
                    <i class="fas fa-hashtag"></i>
                    <%= reservation.getReservationNumber() %>
                </p>
            </div>

            <!-- ============ INFO BOX ============ -->
            <div class="info-box">
                <i class="fas fa-info-circle"></i>
                <div>
                    Editing reservation <strong><%= reservation.getReservationNumber() %></strong>. 
                    Reservation number cannot be changed.
                </div>
            </div>

            <!-- ============ EDIT FORM ============ -->
            <form action="edit-reservation" method="post" class="form-container">
                <!-- Hidden fields -->
                <input type="hidden" name="reservationNumber" value="<%= reservation.getReservationNumber() %>">
                <input type="hidden" name="guestId" value="<%= reservation.getGuestId() %>">

                <!-- Reservation Number (Read-only) -->
                <div class="form-group">
                    <label for="reservationNumber">
                        <i class="fas fa-hashtag"></i> Reservation Number
                    </label>
                    <input type="text" id="reservationNumber" value="<%= reservation.getReservationNumber() %>" readonly>
                    <small>
                        <i class="fas fa-lock"></i> Cannot be changed
                    </small>
                </div>

                <!-- Guest Name -->
                <div class="form-group">
                    <label for="guestName">
                        <i class="fas fa-user"></i> Guest Name *
                    </label>
                    <input type="text" id="guestName" name="guestName" value="<%= reservation.getGuestName() %>" required>
                </div>

                <!-- Contact Number & Room Type -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="contactNumber">
                            <i class="fas fa-phone"></i> Contact Number *
                        </label>
                        <input type="tel" id="contactNumber" name="contactNumber" 
                               value="<%= reservation.getContactNumber() %>" required 
                               pattern="[0-9]{10}" title="Please enter exactly 10 digits">
                    </div>
                    <div class="form-group">
                        <label for="roomType">
                            <i class="fas fa-bed"></i> Room Type *
                        </label>
                        <select id="roomType" name="roomType" required>
                            <option value="">Select room type</option>
                            <option value="Standard" <%= reservation.getRoomType().equals("Standard") ? "selected" : "" %>>Standard (Rs. 25,600/night)</option>
                            <option value="Deluxe" <%= reservation.getRoomType().equals("Deluxe") ? "selected" : "" %>>Deluxe (Rs. 38,400/night)</option>
                            <option value="Suite" <%= reservation.getRoomType().equals("Suite") ? "selected" : "" %>>Suite (Rs. 64,000/night)</option>
                        </select>
                    </div>
                </div>

                <!-- Check-in & Check-out Dates -->
                <div class="form-row">
                    <div class="form-group">
                        <label for="checkIn">
                            <i class="fas fa-sign-in-alt"></i> Check-in Date *
                        </label>
                        <input type="date" id="checkIn" name="checkIn" 
                               value="<%= reservation.getCheckIn().format(dateFormatter) %>" required>
                    </div>
                    <div class="form-group">
                        <label for="checkOut">
                            <i class="fas fa-sign-out-alt"></i> Check-out Date *
                        </label>
                        <input type="date" id="checkOut" name="checkOut" 
                               value="<%= reservation.getCheckOut().format(dateFormatter) %>" required>
                    </div>
                </div>

                <!-- Room Selection -->
                <div class="form-group">
                    <label for="roomNumber">
                        <i class="fas fa-door-closed"></i> Room Number *
                    </label>
                    <select id="roomNumber" name="roomNumber" required>
                        <option value="">-- Select room type and dates first --</option>
                    </select>
                    <div id="roomLoading" class="loading">
                        <i class="fas fa-spinner fa-spin"></i> Loading available rooms...
                    </div>
                    
                    <!-- Auto-assign info -->
                    <div class="auto-assign-badge" id="autoAssignInfo" style="display: none;">
                        <i class="fas fa-magic"></i>
                        <span>Room will be auto-assigned based on availability</span>
                    </div>

                    <!-- Room Details Card -->
                    <div id="roomDetails" class="room-details">
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
                    <small>
                        <i class="fas fa-info-circle"></i> Select a specific room or choose auto-assign
                    </small>
                </div>

                <!-- Address -->
                <div class="form-group">
                    <label for="address">
                        <i class="fas fa-map-marker-alt"></i> Address
                    </label>
                    <textarea id="address" name="address" rows="3"><%= reservation.getAddress() != null ? reservation.getAddress() : "" %></textarea>
                </div>

                <!-- Submit Button -->
                <button type="submit" class="btn-submit">
                    <i class="fas fa-save"></i> Update Reservation
                </button>
            </form>

            <!-- Footer / Cancel -->
            <div class="footer">
                <a href="view-reservation?number=<%= reservation.getReservationNumber() %>" class="btn-cancel">
                    <i class="fas fa-times"></i> Cancel
                </a>
            </div>
        </div>
    </div>

    <script>
        // Helper functions
        function formatNumber(num) {
            if (!num) return '0';
            return parseInt(num).toLocaleString('en-LK');
        }
        
        function formatRupees(amount) {
            return 'Rs. ' + formatNumber(amount);
        }

        // Get current reservation values
        const currentRoomNumber = '<%= reservation.getRoomNumber() != null ? reservation.getRoomNumber() : "" %>';
        const currentRoomType = '<%= reservation.getRoomType() %>';
        const currentCheckIn = '<%= reservation.getCheckIn().format(dateFormatter) %>';
        const currentCheckOut = '<%= reservation.getCheckOut().format(dateFormatter) %>';

        // Set minimum date to today for check-in
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('checkIn').min = today;
        
        // Update check-out min date when check-in changes
        document.getElementById('checkIn').addEventListener('change', function() {
            const checkInDate = new Date(this.value);
            const nextDay = new Date(checkInDate);
            nextDay.setDate(checkInDate.getDate() + 1);
            
            document.getElementById('checkOut').min = nextDay.toISOString().split('T')[0];
            
            // If current check-out is before new check-in, update it
            const checkOutDate = new Date(document.getElementById('checkOut').value);
            if (checkOutDate <= checkInDate) {
                document.getElementById('checkOut').value = nextDay.toISOString().split('T')[0];
            }
            
            // Reload rooms when dates change
            loadAvailableRooms();
        });
        
        // Check-out date change - reload rooms
        document.getElementById('checkOut').addEventListener('change', function() {
            loadAvailableRooms();
        });
        
        // Room type change - reload rooms
        document.getElementById('roomType').addEventListener('change', function() {
            loadAvailableRooms();
        });
        
        // Room number selection - show details
        document.getElementById('roomNumber').addEventListener('change', showRoomDetails);
        
        // Load available rooms via AJAX
        function loadAvailableRooms() {
            const roomType = document.getElementById('roomType').value;
            const checkIn = document.getElementById('checkIn').value;
            const checkOut = document.getElementById('checkOut').value;
            
            if (!roomType || roomType === '' || !checkIn || !checkOut) {
                document.getElementById('roomNumber').innerHTML = '<option value="">-- Select room type and dates first --</option>';
                document.getElementById('roomLoading').style.display = 'none';
                document.getElementById('autoAssignInfo').style.display = 'none';
                return;
            }
            
            // Show loading indicator
            document.getElementById('roomLoading').style.display = 'block';
            document.getElementById('roomDetails').style.display = 'none';
            document.getElementById('autoAssignInfo').style.display = 'none';
            
            // Construct URL
            const contextPath = '${pageContext.request.contextPath}' || '';
            let url;
            if (contextPath && contextPath !== '') {
                url = contextPath + '/available-rooms?roomType=' + encodeURIComponent(roomType) + 
                      '&checkIn=' + encodeURIComponent(checkIn) + 
                      '&checkOut=' + encodeURIComponent(checkOut);
            } else {
                url = '/available-rooms?roomType=' + encodeURIComponent(roomType) + 
                      '&checkIn=' + encodeURIComponent(checkIn) + 
                      '&checkOut=' + encodeURIComponent(checkOut);
            }
            
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
                    
                    if (!rooms || rooms.length === 0) {
                        select.innerHTML += '<option value="" disabled>No available rooms for selected dates</option>';
                    } else {
                        rooms.forEach(room => {
                            const option = document.createElement('option');
                            option.value = room.roomNumber;
                            option.textContent = 'Room ' + room.roomNumber + ' (Floor ' + room.floor + ') - ' + formatRupees(room.rate) + '/night';
                            option.setAttribute('data-floor', room.floor);
                            option.setAttribute('data-rate', room.rate);
                            option.setAttribute('data-status', room.status);
                            option.setAttribute('data-features', room.features || 'Queen bed, TV, WiFi, AC');
                            
                            // Select current room if it matches
                            if (room.roomNumber === currentRoomNumber) {
                                option.selected = true;
                            }
                            
                            select.appendChild(option);
                        });
                        
                        // Add auto-assign option
                        const autoOption = document.createElement('option');
                        autoOption.value = 'AUTO';
                        autoOption.textContent = 'Auto-assign best available room';
                        
                        // Select auto if no current room or current room not in list
                        if (!currentRoomNumber || !rooms.some(r => r.roomNumber === currentRoomNumber)) {
                            autoOption.selected = true;
                        }
                        
                        select.appendChild(autoOption);
                    }
                    
                    document.getElementById('roomLoading').style.display = 'none';
                    
                    // Show details for selected room
                    showRoomDetails();
                })
                .catch(error => {
                    console.error('Error loading rooms:', error);
                    
                    // Fallback: Show sample rooms
                    const select = document.getElementById('roomNumber');
                    select.innerHTML = '<option value="">-- Select a room --</option>';
                    
                    if (roomType === 'Standard') {
                        addTestRoom('101', 1, 25600, 'Queen bed, TV, WiFi, AC');
                        addTestRoom('102', 1, 25600, 'Two single beds, TV, WiFi, AC');
                        addTestRoom('103', 1, 25600, 'Queen bed, TV, WiFi, AC');
                    } else if (roomType === 'Deluxe') {
                        addTestRoom('201', 2, 38400, 'King bed, Sea view, Mini-bar, WiFi');
                        addTestRoom('202', 2, 38400, 'King bed, TV, WiFi, AC, Balcony');
                        addTestRoom('203', 2, 38400, 'Queen bed, Sea view, Mini-bar, WiFi');
                    } else if (roomType === 'Suite') {
                        addTestRoom('301', 3, 64000, 'King bed, Living room, Jacuzzi, Sea view');
                        addTestRoom('302', 3, 64000, 'King bed, Sea view, Mini-bar, Butler service');
                    }
                    
                    // Add auto-assign option
                    const autoOption = document.createElement('option');
                    autoOption.value = 'AUTO';
                    autoOption.textContent = 'Auto-assign best available room';
                    
                    // Select auto if no current room
                    if (!currentRoomNumber) {
                        autoOption.selected = true;
                    }
                    
                    select.appendChild(autoOption);
                    
                    // Try to select current room if it exists in test rooms
                    if (currentRoomNumber) {
                        for (let i = 0; i < select.options.length; i++) {
                            if (select.options[i].value === currentRoomNumber) {
                                select.options[i].selected = true;
                                break;
                            }
                        }
                    }
                    
                    document.getElementById('roomLoading').style.display = 'none';
                    showRoomDetails();
                });
        }
        
        // Helper to add test rooms
        function addTestRoom(number, floor, rate, features) {
            const select = document.getElementById('roomNumber');
            const option = document.createElement('option');
            option.value = number;
            option.textContent = 'Room ' + number + ' (Floor ' + floor + ') - ' + formatRupees(rate) + '/night';
            option.setAttribute('data-floor', floor);
            option.setAttribute('data-rate', rate);
            option.setAttribute('data-status', 'Available');
            option.setAttribute('data-features', features);
            
            // Select if matches current room
            if (number === currentRoomNumber) {
                option.selected = true;
            }
            
            select.appendChild(option);
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
                    featuresHtml += '<span class="room-feature">' + f.trim() + '</span> ';
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
        
        // Form validation
        document.querySelector('form').addEventListener('submit', function(e) {
            const checkIn = document.getElementById('checkIn').value;
            const checkOut = document.getElementById('checkOut').value;
            const guestName = document.getElementById('guestName').value.trim();
            const contactNumber = document.getElementById('contactNumber').value;
            const roomType = document.getElementById('roomType').value;
            const roomNumber = document.getElementById('roomNumber').value;
            
            // Date validation
            if (new Date(checkOut) <= new Date(checkIn)) {
                e.preventDefault();
                alert('❌ Check-out date must be after check-in date!');
                return false;
            }
            
            // Name validation
            if (guestName.length < 2) {
                e.preventDefault();
                alert('❌ Please enter a valid guest name!');
                return false;
            }
            
            // Contact validation
            if (!/^\d{10}$/.test(contactNumber)) {
                e.preventDefault();
                alert('❌ Please enter exactly 10 digits for contact number!');
                return false;
            }
            
            // Room type validation
            if (!roomType) {
                e.preventDefault();
                alert('❌ Please select a room type!');
                return false;
            }
            
            // Room number validation (AUTO is valid)
            if (!roomNumber) {
                e.preventDefault();
                alert('❌ Please select a room or choose auto-assign!');
                return false;
            }
            
            return true;
        });
        
        // Initialize date validation and load rooms
        window.onload = function() {
            const checkIn = document.getElementById('checkIn').value;
            const checkOut = document.getElementById('checkOut').value;
            
            if (checkIn && checkOut) {
                const checkInDate = new Date(checkIn);
                const nextDay = new Date(checkInDate);
                nextDay.setDate(checkInDate.getDate() + 1);
                document.getElementById('checkOut').min = nextDay.toISOString().split('T')[0];
            }
            
            // Load available rooms
            setTimeout(function() {
                loadAvailableRooms();
            }, 500);
        };
    </script>

</body>
</html>