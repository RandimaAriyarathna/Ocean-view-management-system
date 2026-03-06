<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.Map, java.util.HashMap, java.time.LocalDate, java.time.format.DateTimeFormatter, com.oceanview.model.Room, com.oceanview.model.Reservation, com.oceanview.dao.ReservationDao" %>
<%
    // ============ CHECK USER SESSION - IMPROVED ============
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String user = (String) userSession.getAttribute("username");
    
    // ============ GET CHECK-OUTS FROM SESSION ============
    Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
    if (checkOuts == null) {
        checkOuts = new java.util.HashMap<>();
    }
    
    // ============ GET DATA FROM SERVLET ============
    List<Room> allRooms = (List<Room>) request.getAttribute("rooms");
    LocalDate today = (LocalDate) request.getAttribute("today");
    LocalDate startDate = (LocalDate) request.getAttribute("startDate");
    
    // FIXED: Better handling when rooms is null
    if (allRooms == null || allRooms.isEmpty()) {
        allRooms = new java.util.ArrayList<>();
        System.out.println("Warning: No rooms data available at " + new java.util.Date());
    }
    
    if (today == null) {
        today = LocalDate.now();
    }
    
    if (startDate == null) {
        startDate = today;
    }
    
    // ============ GENERATE NEXT 7 DAYS ============
    LocalDate[] next7Days = new LocalDate[7];
    String[] dayNames = new String[7];
    String[] fullDates = new String[7];
    DateTimeFormatter dayFormatter = DateTimeFormatter.ofPattern("EEE");
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("MMM dd");
    DateTimeFormatter fullDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    
    for (int i = 0; i < 7; i++) {
        next7Days[i] = startDate.plusDays(i);
        dayNames[i] = next7Days[i].format(dayFormatter);
        fullDates[i] = next7Days[i].format(fullDateFormatter);
    }
    
    // ============ GET RESERVATIONS FOR EACH ROOM ============
    ReservationDao reservationDao = new ReservationDao();
    Map<String, Map<LocalDate, Boolean>> roomAvailability = new HashMap<>();
    Map<String, Map<LocalDate, String>> roomGuests = new HashMap<>();
    Map<String, Map<LocalDate, Boolean>> roomCheckedOut = new HashMap<>();
    
    // Initialize for ALL rooms first
    for (Room room : allRooms) {
        Map<LocalDate, Boolean> availability = new HashMap<>();
        Map<LocalDate, String> guestMap = new HashMap<>();
        Map<LocalDate, Boolean> checkedOutMap = new HashMap<>();
        
        // Initialize all dates as available (false = available)
        for (LocalDate date : next7Days) {
            availability.put(date, false);
            guestMap.put(date, "");
            checkedOutMap.put(date, false);
        }
        
        roomAvailability.put(room.getRoomNumber(), availability);
        roomGuests.put(room.getRoomNumber(), guestMap);
        roomCheckedOut.put(room.getRoomNumber(), checkedOutMap);
    }
    
    // Then populate with reservation data
    for (Room room : allRooms) {
        try {
            List<Reservation> reservations = reservationDao.getReservationsByRoom(room.getRoomNumber());
            
            if (reservations != null) {
                for (Reservation r : reservations) {
                    if (r != null && r.getCheckIn() != null && r.getCheckOut() != null) {
                        LocalDate checkIn = r.getCheckIn();
                        LocalDate checkOut = r.getCheckOut();
                        String reservationNumber = r.getReservationNumber();
                        
                        // Check if this reservation has been manually checked out
                        boolean isCheckedOut = checkOuts.containsKey(reservationNumber);
                        
                        // Mark occupied dates (from check-in to day BEFORE check-out)
                        for (LocalDate date : next7Days) {
                            // Room is occupied if:
                            // 1. Date is between check-in and check-out (not including check-out day)
                            // 2. Guest has NOT been manually checked out
                            if (!date.isBefore(checkIn) && date.isBefore(checkOut) && !isCheckedOut) {
                                Map<LocalDate, Boolean> availability = roomAvailability.get(room.getRoomNumber());
                                Map<LocalDate, String> guestMap = roomGuests.get(room.getRoomNumber());
                                Map<LocalDate, Boolean> checkedOutMap = roomCheckedOut.get(room.getRoomNumber());
                                
                                if (availability != null) {
                                    availability.put(date, true); // true = occupied
                                }
                                if (guestMap != null && r.getGuestName() != null) {
                                    guestMap.put(date, r.getGuestName());
                                }
                                if (checkedOutMap != null && isCheckedOut) {
                                    checkedOutMap.put(date, true);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error getting reservations for room " + room.getRoomNumber() + ": " + e.getMessage());
        }
    }
    
    // ============ GROUP ROOMS BY TYPE ============
    List<Room> standardRooms = new java.util.ArrayList<>();
    List<Room> deluxeRooms = new java.util.ArrayList<>();
    List<Room> suiteRooms = new java.util.ArrayList<>();
    
    for (Room room : allRooms) {
        if ("Standard".equals(room.getRoomType())) {
            standardRooms.add(room);
        } else if ("Deluxe".equals(room.getRoomType())) {
            deluxeRooms.add(room);
        } else if ("Suite".equals(room.getRoomType())) {
            suiteRooms.add(room);
        }
    }
    
    // ============ CALCULATE STATISTICS ============
    int availableToday = 0;
    int occupiedToday = 0;
    int occupancyRate = 0;
    
    for (Room room : allRooms) {
        try {
            Map<LocalDate, Boolean> availability = roomAvailability.get(room.getRoomNumber());
            if (availability != null) {
                Boolean isOccupied = availability.get(today);
                if (isOccupied != null && isOccupied) {
                    occupiedToday++;
                } else {
                    availableToday++;
                }
            } else {
                availableToday++;
            }
        } catch (Exception e) {
            availableToday++;
        }
    }
    
    if (allRooms.size() > 0) {
        occupancyRate = (occupiedToday * 100 / allRooms.size());
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Room Availability - Ocean View Resort</title>
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
            padding: 20px;
        }

        /* ============ TOP NAVIGATION (MATCHING DASHBOARD) ============ */
        .top-nav {
            background: white;
            padding: 0 30px;
            height: 70px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
            position: sticky;
            top: 0;
            z-index: 1000;
            margin-bottom: 25px;
            border-radius: 10px;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo-icon {
            color: #0077b6;
            font-size: 24px;
        }

        .logo-text h1 {
            font-size: 18px;
            color: #023e8a;
            font-weight: 600;
        }

        .logo-text p {
            font-size: 10px;
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
            color: #023e8a;
            font-size: 14px;
            line-height: 1.3;
        }

        .user-badge {
            font-size: 11px;
            color: #0077b6;
            background: #e8f4fd;
            padding: 2px 8px;
            border-radius: 20px;
            display: inline-block;
            font-weight: 500;
            margin-top: 2px;
        }

        .user-avatar {
            width: 38px;
            height: 38px;
            background: #0077b6;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 500;
            font-size: 16px;
            flex-shrink: 0;
        }

        .logout-btn {
            background: transparent;
            color: #6c757d;
            border: 1px solid #e9ecef;
            padding: 6px 14px;
            border-radius: 8px;
            font-size: 13px;
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
            color: #dc3545;
            border-color: #dc3545;
        }

        /* ============ MAIN CONTAINER ============ */
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        /* ============ HEADER ============ */
        .header {
            background: linear-gradient(135deg, #0077b6, #00b4d8);
            color: white;
            padding: 20px 25px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 12px rgba(0, 119, 182, 0.2);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }

        .header h1 {
            font-size: 22px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .header h1 i {
            font-size: 24px;
        }

        .date-navigation {
            display: flex;
            align-items: center;
            gap: 15px;
            background: rgba(255,255,255,0.2);
            padding: 8px 16px;
            border-radius: 30px;
        }

        .nav-btn {
            background: white;
            color: #0077b6;
            border: none;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 14px;
        }

        .nav-btn:hover {
            transform: scale(1.1);
            background: #f0f0f0;
        }

        /* ============ STATS SUMMARY ============ */
        .stats-summary {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-box {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            text-align: center;
            transition: transform 0.2s;
        }

        .stat-box:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 12px rgba(0, 119, 182, 0.15);
        }

        .stat-value {
            font-size: 26px;
            font-weight: 700;
            color: #0077b6;
            margin-bottom: 3px;
        }

        .stat-label {
            color: #666;
            font-size: 12px;
            letter-spacing: 0.3px;
        }

        /* ============ LEGEND ============ */
        .legend {
            background: white;
            padding: 12px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            gap: 25px;
            flex-wrap: wrap;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            font-size: 13px;
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .legend-color {
            width: 16px;
            height: 16px;
            border-radius: 4px;
        }

        .color-available { background: #d4edda; border: 1px solid #28a745; }
        .color-occupied { background: #f8d7da; border: 1px solid #dc3545; }
        .color-today { background: #fff3cd; border: 1px solid #ffc107; }
        .color-checkout { background: #cff4fc; border: 1px solid #0dcaf0; }

        /* ============ NO ROOMS MESSAGE ============ */
        .no-rooms-message {
            background: white;
            padding: 40px;
            text-align: center;
            border-radius: 10px;
            margin: 20px 0;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }

        .no-rooms-message i {
            font-size: 48px;
            color: #0077b6;
            margin-bottom: 15px;
        }

        .no-rooms-message h2 {
            color: #333;
            font-size: 20px;
            margin-bottom: 8px;
        }

        .no-rooms-message p {
            color: #666;
            font-size: 14px;
            margin-bottom: 20px;
        }

        /* ============ ROOM SECTIONS ============ */
        .room-section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }

        .section-title {
            color: #0077b6;
            font-size: 18px;
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 2px solid #e0f0ff;
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .room-type-badge {
            background: #0077b6;
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            margin-left: 10px;
        }

        /* ============ CALENDAR TABLE ============ */
        .calendar-container {
            overflow-x: auto;
        }

        .calendar-table {
            width: 100%;
            border-collapse: collapse;
            min-width: 800px;
            font-size: 13px;
        }

        .calendar-table th {
            padding: 12px 8px;
            text-align: center;
            background: #f8f9fa;
            color: #333;
            font-weight: 600;
            font-size: 12px;
            border-bottom: 2px solid #dee2e6;
        }

        .calendar-table td {
            padding: 10px 6px;
            text-align: center;
            border: 1px solid #e9ecef;
            position: relative;
            font-size: 12px;
        }

        .room-info {
            font-weight: 600;
            color: #023e8a;
            text-align: left;
            background: #f0f8ff;
            padding: 8px 10px;
            font-size: 13px;
        }

        .room-number {
            font-size: 14px;
            display: block;
        }

        .room-floor {
            font-size: 11px;
            color: #666;
            font-weight: normal;
        }

        /* ============ CELL STATUS ============ */
        .available-cell {
            background: #d4edda;
            color: #155724;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
        }

        .available-cell:hover {
            background: #c3e6cb;
        }

        .occupied-cell {
            background: #f8d7da;
            color: #721c24;
            cursor: pointer;
        }

        .occupied-cell:hover {
            background: #f5c6cb;
        }

        .today-cell {
            border: 2px solid #ffc107;
        }

        /* ============ TOOLTIPS ============ */
        .guest-tooltip {
            visibility: hidden;
            position: absolute;
            bottom: 100%;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0,0,0,0.85);
            color: white;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 11px;
            white-space: nowrap;
            z-index: 100;
            margin-bottom: 6px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
            pointer-events: none;
        }

        .guest-tooltip::after {
            content: '';
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -5px;
            border-width: 5px;
            border-style: solid;
            border-color: rgba(0,0,0,0.85) transparent transparent transparent;
        }

        .occupied-cell:hover .guest-tooltip,
        .available-cell:hover .guest-tooltip {
            visibility: visible;
        }

        .availability-icon {
            margin-right: 3px;
            font-size: 11px;
        }

        /* ============ ACTION BUTTONS ============ */
        .action-buttons {
            display: flex;
            gap: 12px;
            margin-top: 25px;
            justify-content: flex-end;
            flex-wrap: wrap;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-weight: 500;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s;
            font-size: 13px;
        }

        .btn-primary {
            background: #0077b6;
            color: white;
        }

        .btn-primary:hover {
            background: #005a8c;
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,119,182,0.3);
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .btn-secondary:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }

        .btn-success {
            background: #28a745;
            color: white;
        }

        .btn-success:hover {
            background: #218838;
            transform: translateY(-2px);
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
            background: #0077b6;
            border-radius: 10px;
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 1024px) {
            .stats-summary {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .top-nav {
                padding: 0 15px;
            }
            
            .user-section {
                gap: 15px;
            }
            
            .user-info {
                gap: 10px;
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
            
            .header {
                flex-direction: column;
                text-align: center;
                gap: 12px;
            }
            
            .legend {
                gap: 12px;
                font-size: 12px;
            }
            
            .action-buttons {
                justify-content: center;
            }
            
            .stats-summary {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 480px) {
            body {
                padding: 10px;
            }
            
            .room-type-badge {
                margin-left: 0;
                margin-top: 5px;
            }
        }

        /* ============ PRINT STYLES ============ */
        @media print {
            .no-print {
                display: none;
            }
            body {
                background: white;
                padding: 0;
            }
            .header {
                background: #0077b6;
                color: white;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            .available-cell, .occupied-cell {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
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

    <div class="container">
        <!-- ============ HEADER ============ -->
        <div class="header">
            <h1>
                <i class="fas fa-calendar-alt"></i>
                Room Availability
            </h1>
            <div class="date-navigation no-print">
                <button class="nav-btn" onclick="changeWeek(-7)">
                    <i class="fas fa-chevron-left"></i>
                </button>
                <span style="font-weight: 500; font-size: 14px;">
                    <%= startDate.format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %> - 
                    <%= next7Days[6].format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %>
                </span>
                <button class="nav-btn" onclick="changeWeek(7)">
                    <i class="fas fa-chevron-right"></i>
                </button>
            </div>
        </div>

        <!-- ============ STATS SUMMARY ============ -->
        <div class="stats-summary">
            <div class="stat-box">
                <div class="stat-value"><%= allRooms.size() %></div>
                <div class="stat-label">Total Rooms</div>
            </div>
            <div class="stat-box">
                <div class="stat-value"><%= availableToday %></div>
                <div class="stat-label">Available Today</div>
            </div>
            <div class="stat-box">
                <div class="stat-value"><%= occupiedToday %></div>
                <div class="stat-label">Occupied Today</div>
            </div>
            <div class="stat-box">
                <div class="stat-value"><%= occupancyRate %>%</div>
                <div class="stat-label">Occupancy Rate</div>
            </div>
        </div>

        <!-- ============ LEGEND ============ -->
        <div class="legend no-print">
            <div class="legend-item">
                <div class="legend-color color-available"></div>
                <span>Available (click to book)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color color-occupied"></div>
                <span>Occupied</span>
            </div>
            <div class="legend-item">
                <div class="legend-color color-today"></div>
                <span>Today</span>
            </div>
            <div class="legend-item">
                <i class="fas fa-info-circle" style="color: #0077b6;"></i>
                <span>Hover for details</span>
            </div>
        </div>

        <!-- FIXED: Handle empty rooms case -->
        <% if (allRooms.isEmpty()) { %>
            <div class="no-rooms-message">
                <i class="fas fa-door-open"></i>
                <h2>No Rooms Available</h2>
                <p>There are currently no rooms in the system. Please contact your administrator.</p>
                <a href="dashboard.jsp" class="btn btn-secondary">
                    <i class="fas fa-arrow-left"></i> Back to Dashboard
                </a>
            </div>
        <% } else { %>

            <!-- ============ STANDARD ROOMS ============ -->
            <% if (!standardRooms.isEmpty()) { %>
            <div class="room-section">
                <h2 class="section-title">
                    <i class="fas fa-bed"></i> Standard Rooms
                    <span class="room-type-badge">Rs. 25,600/night</span>
                </h2>
                <div class="calendar-container">
                    <table class="calendar-table">
                        <thead>
                            <tr>
                                <th style="width: 100px;">Room</th>
                                <% for (int i = 0; i < 7; i++) { %>
                                    <th>
                                        <%= dayNames[i] %><br>
                                        <span style="font-size: 10px; color: #666;">
                                            <%= next7Days[i].format(dateFormatter) %>
                                        </span>
                                    </th>
                                <% } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Room room : standardRooms) { 
                                String roomNum = room.getRoomNumber();
                                Map<LocalDate, Boolean> availability = roomAvailability.get(roomNum);
                                Map<LocalDate, String> guestMap = roomGuests.get(roomNum);
                            %>
                                <tr>
                                    <td class="room-info">
                                        <span class="room-number">
                                            <i class="fas fa-door-closed"></i> <%= roomNum %>
                                        </span>
                                        <span class="room-floor">F<%= room.getFloor() %></span>
                                    </td>
                                    <% for (int i = 0; i < 7; i++) { 
                                        LocalDate date = next7Days[i];
                                        boolean isOccupied = false;
                                        String guestName = "";
                                        
                                        if (availability != null) {
                                            Boolean occ = availability.get(date);
                                            isOccupied = (occ != null && occ);
                                        }
                                        
                                        if (guestMap != null) {
                                            String name = guestMap.get(date);
                                            guestName = (name != null) ? name : "";
                                        }
                                        
                                        boolean isToday = date.equals(today);
                                        
                                        String cellClass = isOccupied ? "occupied-cell" : "available-cell";
                                        if (isToday) {
                                            cellClass += " today-cell";
                                        }
                                    %>
                                        <td class="<%= cellClass %>"
                                            <%= !isOccupied ? "onclick=\"window.location.href='addReservation.jsp?room=" + roomNum + "&date=" + fullDates[i] + "'\"" : "" %>>
                                            <% if (isOccupied) { %>
                                                <i class="fas fa-user-check availability-icon"></i> Booked
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-user"></i> <%= guestName %><br>
                                                    <i class="fas fa-door-closed"></i> Room <%= roomNum %><br>
                                                    <i class="fas fa-calendar-check"></i> Check-out: <%= date.plusDays(1).format(dateFormatter) %>
                                                </span>
                                            <% } else { %>
                                                <i class="fas fa-check-circle availability-icon"></i> Free
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-plus-circle"></i> Click to book<br>
                                                    Rs. <%= String.format("%,d", (int)room.getRate()) %>/night
                                                </span>
                                            <% } %>
                                        </td>
                                    <% } %>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <!-- ============ DELUXE ROOMS ============ -->
            <% if (!deluxeRooms.isEmpty()) { %>
            <div class="room-section">
                <h2 class="section-title">
                    <i class="fas fa-star"></i> Deluxe Rooms
                    <span class="room-type-badge">Rs. 38,400/night</span>
                </h2>
                <div class="calendar-container">
                    <table class="calendar-table">
                        <thead>
                            <tr>
                                <th style="width: 100px;">Room</th>
                                <% for (int i = 0; i < 7; i++) { %>
                                    <th>
                                        <%= dayNames[i] %><br>
                                        <span style="font-size: 10px; color: #666;">
                                            <%= next7Days[i].format(dateFormatter) %>
                                        </span>
                                    </th>
                                <% } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Room room : deluxeRooms) { 
                                String roomNum = room.getRoomNumber();
                                Map<LocalDate, Boolean> availability = roomAvailability.get(roomNum);
                                Map<LocalDate, String> guestMap = roomGuests.get(roomNum);
                            %>
                                <tr>
                                    <td class="room-info">
                                        <span class="room-number">
                                            <i class="fas fa-door-closed"></i> <%= roomNum %>
                                        </span>
                                        <span class="room-floor">F<%= room.getFloor() %></span>
                                    </td>
                                    <% for (int i = 0; i < 7; i++) { 
                                        LocalDate date = next7Days[i];
                                        boolean isOccupied = false;
                                        String guestName = "";
                                        
                                        if (availability != null) {
                                            Boolean occ = availability.get(date);
                                            isOccupied = (occ != null && occ);
                                        }
                                        
                                        if (guestMap != null) {
                                            String name = guestMap.get(date);
                                            guestName = (name != null) ? name : "";
                                        }
                                        
                                        boolean isToday = date.equals(today);
                                        
                                        String cellClass = isOccupied ? "occupied-cell" : "available-cell";
                                        if (isToday) {
                                            cellClass += " today-cell";
                                        }
                                    %>
                                        <td class="<%= cellClass %>"
                                            <%= !isOccupied ? "onclick=\"window.location.href='addReservation.jsp?room=" + roomNum + "&date=" + fullDates[i] + "'\"" : "" %>>
                                            <% if (isOccupied) { %>
                                                <i class="fas fa-user-check availability-icon"></i> Booked
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-user"></i> <%= guestName %><br>
                                                    <i class="fas fa-door-closed"></i> Room <%= roomNum %><br>
                                                    <i class="fas fa-calendar-check"></i> Check-out: <%= date.plusDays(1).format(dateFormatter) %>
                                                </span>
                                            <% } else { %>
                                                <i class="fas fa-check-circle availability-icon"></i> Free
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-plus-circle"></i> Click to book<br>
                                                    Rs. <%= String.format("%,d", (int)room.getRate()) %>/night
                                                </span>
                                            <% } %>
                                        </td>
                                    <% } %>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <!-- ============ SUITES ============ -->
            <% if (!suiteRooms.isEmpty()) { %>
            <div class="room-section">
                <h2 class="section-title">
                    <i class="fas fa-crown"></i> Suites
                    <span class="room-type-badge">Rs. 64,000/night</span>
                </h2>
                <div class="calendar-container">
                    <table class="calendar-table">
                        <thead>
                            <tr>
                                <th style="width: 100px;">Room</th>
                                <% for (int i = 0; i < 7; i++) { %>
                                    <th>
                                        <%= dayNames[i] %><br>
                                        <span style="font-size: 10px; color: #666;">
                                            <%= next7Days[i].format(dateFormatter) %>
                                        </span>
                                    </th>
                                <% } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Room room : suiteRooms) { 
                                String roomNum = room.getRoomNumber();
                                Map<LocalDate, Boolean> availability = roomAvailability.get(roomNum);
                                Map<LocalDate, String> guestMap = roomGuests.get(roomNum);
                            %>
                                <tr>
                                    <td class="room-info">
                                        <span class="room-number">
                                            <i class="fas fa-door-closed"></i> <%= roomNum %>
                                        </span>
                                        <span class="room-floor">F<%= room.getFloor() %></span>
                                    </td>
                                    <% for (int i = 0; i < 7; i++) { 
                                        LocalDate date = next7Days[i];
                                        boolean isOccupied = false;
                                        String guestName = "";
                                        
                                        if (availability != null) {
                                            Boolean occ = availability.get(date);
                                            isOccupied = (occ != null && occ);
                                        }
                                        
                                        if (guestMap != null) {
                                            String name = guestMap.get(date);
                                            guestName = (name != null) ? name : "";
                                        }
                                        
                                        boolean isToday = date.equals(today);
                                        
                                        String cellClass = isOccupied ? "occupied-cell" : "available-cell";
                                        if (isToday) {
                                            cellClass += " today-cell";
                                        }
                                    %>
                                        <td class="<%= cellClass %>"
                                            <%= !isOccupied ? "onclick=\"window.location.href='addReservation.jsp?room=" + roomNum + "&date=" + fullDates[i] + "'\"" : "" %>>
                                            <% if (isOccupied) { %>
                                                <i class="fas fa-user-check availability-icon"></i> Booked
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-user"></i> <%= guestName %><br>
                                                    <i class="fas fa-door-closed"></i> Room <%= roomNum %><br>
                                                    <i class="fas fa-calendar-check"></i> Check-out: <%= date.plusDays(1).format(dateFormatter) %>
                                                </span>
                                            <% } else { %>
                                                <i class="fas fa-check-circle availability-icon"></i> Free
                                                <span class="guest-tooltip">
                                                    <i class="fas fa-plus-circle"></i> Click to book<br>
                                                    Rs. <%= String.format("%,d", (int)room.getRate()) %>/night
                                                </span>
                                            <% } %>
                                        </td>
                                    <% } %>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>
        <% } %>

        <!-- ============ ACTION BUTTONS ============ -->
        <div class="action-buttons no-print">
            <a href="dashboard.jsp" class="btn btn-secondary">
                <i class="fas fa-arrow-left"></i> Dashboard
            </a>
            <a href="addReservation.jsp" class="btn btn-primary">
                <i class="fas fa-plus-circle"></i> New Reservation
            </a>
            <button onclick="window.print()" class="btn btn-success">
                <i class="fas fa-print"></i> Print
            </button>
        </div>
    </div>

    <script>
        function changeWeek(days) {
            const urlParams = new URLSearchParams(window.location.search);
            let startDate = urlParams.get('startDate');
            
            if (!startDate) {
                const today = new Date();
                startDate = today.toISOString().split('T')[0];
            }
            
            const newDate = new Date(startDate);
            newDate.setDate(newDate.getDate() + days);
            
            window.location.href = 'room-availability?startDate=' + newDate.toISOString().split('T')[0];
        }

        document.addEventListener('keydown', function(e) {
            if (e.key === 'ArrowLeft') {
                e.preventDefault();
                changeWeek(-7);
            }
            if (e.key === 'ArrowRight') {
                e.preventDefault();
                changeWeek(7);
            }
            if (e.key === 'Escape') {
                window.location.href = 'dashboard.jsp';
            }
            if (e.ctrlKey && e.key === 'p') {
                e.preventDefault();
                window.print();
            }
        });
    </script>
</body>
</html>