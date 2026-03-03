<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.dao.ReservationDao, com.oceanview.dao.RoomDao, com.oceanview.model.Reservation, java.util.List, java.time.LocalDate, java.time.format.DateTimeFormatter, java.util.Map" %>

<%
    // ============ CHECK USER SESSION ============
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // ============ GET USERNAME FROM SESSION ============
    String user = (String) userSession.getAttribute("username");
    
    // ============ GET URL PARAMETERS ============
    String type = request.getParameter("type");
    String message = request.getParameter("message");
    
    // ============ CURRENT DATE ============
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("EEEE, MMMM dd, yyyy");
    String currentDate = LocalDate.now().format(dateFormatter);
    
    // ============ DASHBOARD STATISTICS ============
    ReservationDao reservationDao = new ReservationDao();
    RoomDao roomDao = new RoomDao();
    
    // Get all reservations for calculations
    List<Reservation> allReservations = reservationDao.getAllReservations();
    LocalDate today = LocalDate.now();
    
    // ============ FIXED: Get check-outs from session ============
    Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
    if (checkOuts == null) {
        checkOuts = new java.util.HashMap<>();
    }
    
    // Calculate occupied rooms considering check-outs
    int occupiedRooms = 0;
    for (Reservation r : allReservations) {
        if (r.getRoomNumber() != null && !r.getRoomNumber().isEmpty()) {
            // Check if guest has arrived (check-in <= today)
            boolean hasArrived = !today.isBefore(r.getCheckIn());
            
            // Check if guest has checked out (using session data)
            boolean isCheckedOut = checkOuts.containsKey(r.getReservationNumber());
            
            // Room is occupied if guest has arrived AND hasn't checked out
            if (hasArrived && !isCheckedOut) {
                occupiedRooms++;
            }
        }
    }
    
    // ============ FIXED: Calculate counts using session check-outs ============
    int totalReservations = allReservations.size();
    int upcomingCount = 0;
    int activeCount = 0;
    int completedCount = 0;
    int overdueCount = 0;
    
    for (Reservation r : allReservations) {
        // Check if this reservation has been checked out
        boolean isCheckedOut = checkOuts.containsKey(r.getReservationNumber());
        
        if (isCheckedOut) {
            // Guest has physically left - COMPLETED
            completedCount++;
        }
        else if (today.isBefore(r.getCheckIn())) {
            // Future booking - UPCOMING
            upcomingCount++;
        }
        else if (!today.isBefore(r.getCheckIn()) && !today.isAfter(r.getCheckOut())) {
            // Currently within stay dates and not checked out - ACTIVE
            activeCount++;
        }
        else {
            // Past check-out date but not checked out - OVERDUE
            activeCount++; // Still counts as an active stay because guest is still in hotel
            overdueCount++;
        }
    }
    
    // Room statistics
    int totalRooms = roomDao.getTotalRoomsCount();
    int availableRooms = roomDao.getAvailableRoomsCount();
    
    // Today's check-ins and check-outs
    List<Reservation> todaysCheckins = reservationDao.getTodaysCheckins();
    List<Reservation> todaysCheckouts = reservationDao.getTodaysCheckouts();
    
    // Recent reservations (last 5)
    List<Reservation> recentReservations = reservationDao.getRecentReservations(5);
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============ GLOBAL STYLES ============ */
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

        /* ============ TOP NAVIGATION ============ */
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

        /* ============ DASHBOARD LAYOUT ============ */
        .dashboard-container {
            display: grid;
            grid-template-columns: 250px 1fr;
            min-height: calc(100vh - 85px);
        }

        /* ============ SIDEBAR ============ */
        .sidebar {
            background: var(--white);
            padding: 25px 0;
            box-shadow: var(--shadow);
            border-right: 1px solid #e9ecef;
        }

        .sidebar-menu {
            list-style: none;
        }

        .menu-item {
            padding: 15px 25px;
            display: flex;
            align-items: center;
            gap: 15px;
            color: #555;
            text-decoration: none;
            transition: all 0.3s;
            border-left: 3px solid transparent;
        }

        .menu-item:hover {
            background: var(--light-bg);
            color: var(--primary);
            border-left-color: var(--primary);
        }

        .menu-item.active {
            background: var(--light);
            color: var(--primary);
            border-left-color: var(--primary);
            font-weight: 600;
        }

        .menu-icon {
            width: 24px;
            text-align: center;
            font-size: 18px;
        }

        .menu-text {
            font-size: 15px;
        }

        /* ============ MAIN CONTENT ============ */
        .main-content {
            padding: 30px;
        }

        /* ============ WELCOME SECTION ============ */
        .welcome-section {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 25px rgba(0, 119, 182, 0.2);
        }

        .welcome-title {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .welcome-subtitle {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 15px;
        }

        .date-time {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            background: rgba(255, 255, 255, 0.2);
            padding: 8px 15px;
            border-radius: 20px;
            width: fit-content;
        }

        /* ============ STATS CARDS ============ */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 15px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: var(--white);
            padding: 20px 15px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: transform 0.3s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-info h3 {
            font-size: 24px;
            color: var(--dark);
            margin-bottom: 5px;
        }

        .stat-info p {
            color: #666;
            font-size: 14px;
            font-weight: 500;
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: white;
            flex-shrink: 0;
        }

        .bg-primary { background: linear-gradient(135deg, var(--primary), var(--secondary)); }
        .bg-success { background: linear-gradient(135deg, var(--success), #20c997); }
        .bg-warning { background: linear-gradient(135deg, var(--warning), #fd7e14); }
        .bg-info { background: linear-gradient(135deg, var(--info), #0077b6); }
        .bg-danger { background: linear-gradient(135deg, var(--danger), #e4606d); }

        /* ============ SECTION TITLES ============ */
        .section-title {
            color: var(--dark);
            font-size: 20px;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--light);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        /* ============ RECENT RESERVATIONS TABLE ============ */
        .recent-table-container {
            background: var(--white);
            border-radius: var(--border-radius);
            overflow: hidden;
            box-shadow: var(--shadow);
            margin-bottom: 30px;
        }

        .recent-table {
            width: 100%;
            border-collapse: collapse;
        }

        .recent-table th {
            background: var(--primary);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }

        .recent-table td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
        }

        .recent-table tr {
            cursor: pointer;
            transition: background 0.2s;
        }

        .recent-table tr:hover {
            background: var(--light-bg);
        }

        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-upcoming { background: #fff3cd; color: #856404; }
        .status-active { background: #d4edda; color: #155724; }
        .status-completed { background: #f8d7da; color: #721c24; }
        .status-overdue { background: #f8d7da; color: #721c24; animation: pulse 2s infinite; }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.8; box-shadow: 0 0 5px rgba(220,53,69,0.5); }
            100% { opacity: 1; }
        }

        .view-all-link {
            display: block;
            text-align: center;
            padding: 15px;
            background: var(--light-bg);
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
            transition: background 0.3s;
        }

        .view-all-link:hover {
            background: var(--light);
        }

        /* ============ TODAY'S ACTIVITIES ============ */
        .activity-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }

        .activity-card {
            background: var(--white);
            padding: 20px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
        }

        .activity-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 15px;
            color: var(--dark);
            font-weight: 600;
        }

        .activity-list {
            list-style: none;
        }

        .activity-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px dashed #eee;
            cursor: pointer;
        }

        .activity-item:last-child {
            border-bottom: none;
        }

        .activity-item:hover {
            background: var(--light-bg);
        }

        .guest-name {
            font-weight: 600;
            color: var(--dark);
        }

        .room-number {
            color: var(--primary);
            font-weight: 600;
        }

        .no-data {
            color: #999;
            font-style: italic;
            text-align: center;
            padding: 15px;
        }

        /* ============ FEATURES GRID ============ */
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin-top: 30px;
        }

        .feature-card {
            background: var(--white);
            border-radius: 15px;
            padding: 30px;
            box-shadow: var(--shadow);
            transition: all 0.3s ease;
            text-align: center;
            border: 2px solid transparent;
        }

        .feature-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 30px rgba(0, 119, 182, 0.15);
            border-color: var(--accent);
        }

        .feature-icon {
            font-size: 40px;
            color: var(--primary);
            margin-bottom: 20px;
        }

        .feature-card h3 {
            color: var(--dark);
            margin-bottom: 15px;
            font-size: 20px;
        }

        .feature-card p {
            color: #666;
            line-height: 1.6;
            margin-bottom: 20px;
        }

        .feature-btn {
            background: linear-gradient(45deg, var(--primary), var(--secondary));
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 30px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            width: 100%;
            font-size: 15px;
            text-decoration: none;
            display: block;
        }

        .feature-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 180, 216, 0.3);
        }

        /* ============ FOOTER ============ */
        .dashboard-footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            font-size: 13px;
            border-top: 1px solid #e9ecef;
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 1400px) {
            .stats-grid {
                grid-template-columns: repeat(3, 1fr);
            }
        }

        @media (max-width: 1024px) {
            .dashboard-container {
                grid-template-columns: 1fr;
            }
            .sidebar {
                display: none;
            }
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }

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
            .main-content {
                padding: 20px;
            }
            .activity-grid {
                grid-template-columns: 1fr;
            }
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            .stat-card {
                padding: 15px;
            }
            .stat-info h3 {
                font-size: 22px;
            }
            .stat-info p {
                font-size: 13px;
            }
            .stat-icon {
                width: 45px;
                height: 45px;
                font-size: 22px;
            }
        }

        @media (max-width: 480px) {
            .user-details {
                display: none;
            }
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

    <!-- ============ TOP NAVIGATION ============ -->
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

    <!-- ============ DASHBOARD LAYOUT ============ -->
    <div class="dashboard-container">
        
        <!-- ============ SIDEBAR ============ -->
        <aside class="sidebar">
            <ul class="sidebar-menu">
                <li><a href="dashboard.jsp" class="menu-item active">
                    <i class="fas fa-tachometer-alt menu-icon"></i>
                    <span class="menu-text">Dashboard</span>
                </a></li>
                
                <li><a href="room-availability" class="menu-item">
                    <i class="fas fa-calendar-alt menu-icon"></i>
                    <span class="menu-text">Room Calendar</span>
                </a></li>
                
                <li><a href="addReservation.jsp" class="menu-item">
                    <i class="fas fa-calendar-plus menu-icon"></i>
                    <span class="menu-text">Add Reservation</span>
                </a></li>
                <li><a href="view-reservations" class="menu-item">
                    <i class="fas fa-list-alt menu-icon"></i>
                    <span class="menu-text">View Reservations</span>
                </a></li>
                <li><a href="billing.jsp" class="menu-item">
                    <i class="fas fa-file-invoice-dollar menu-icon"></i>
                    <span class="menu-text">Billing Center</span>
                </a></li>
                <li><a href="help.jsp" class="menu-item">
                    <i class="fas fa-question-circle menu-icon"></i>
                    <span class="menu-text">Help & Support</span>
                </a></li>
                <li><a href="logout" class="menu-item">
                    <i class="fas fa-sign-out-alt menu-icon"></i>
                    <span class="menu-text">Logout</span>
                </a></li>
            </ul>
        </aside>

        <!-- ============ MAIN CONTENT ============ -->
        <main class="main-content">

            <!-- ============ WELCOME SECTION ============ -->
            <div class="welcome-section">
                <h1 class="welcome-title">Welcome back, <%= user %>! 👋</h1>
                <p class="welcome-subtitle">Manage resort reservations and guest services efficiently.</p>
                <div class="date-time">
                    <i class="fas fa-calendar-alt"></i>
                    <span><%= currentDate %></span>
                    <i class="fas fa-clock"></i>
                    <span id="currentTime"></span>
                </div>
            </div>

            <!-- ============ STATISTICS CARDS ============ -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= totalReservations %></h3>
                        <p>Total Reservations</p>
                    </div>
                    <div class="stat-icon bg-primary">
                        <i class="fas fa-calendar-check"></i>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= activeCount %></h3>
                        <p>Active Stays</p>
                    </div>
                    <div class="stat-icon bg-success">
                        <i class="fas fa-door-open"></i>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= upcomingCount %></h3>
                        <p>Upcoming</p>
                    </div>
                    <div class="stat-icon bg-warning">
                        <i class="fas fa-clock"></i>
                    </div>
                </div>
                
                <%--
<div class="stat-card">
    <div class="stat-info">
        <h3><%= overdueCount %></h3>
        <p>Overdue Stays</p>
    </div>
    <div class="stat-icon bg-danger">
        <i class="fas fa-exclamation-triangle"></i>
    </div>
</div>
--%>
                
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= occupiedRooms %>/<%= totalRooms %></h3>
                        <p>Rooms Occupied</p>
                    </div>
                    <div class="stat-icon bg-info">
                        <i class="fas fa-bed"></i>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= todaysCheckins.size() %></h3>
                        <p>Check-ins Today</p>
                    </div>
                    <div class="stat-icon bg-success">
                        <i class="fas fa-sign-in-alt"></i>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-info">
                        <h3><%= todaysCheckouts.size() %></h3>
                        <p>Check-outs Today</p>
                    </div>
                    <div class="stat-icon bg-danger">
                        <i class="fas fa-sign-out-alt"></i>
                    </div>
                </div>
            </div>

            <!-- ============ TODAY'S ACTIVITIES ============ -->
            <div class="activity-grid">
                <!-- Today's Check-ins -->
                <div class="activity-card">
                    <div class="activity-header">
                        <i class="fas fa-sign-in-alt" style="color: var(--success);"></i>
                        <h3>Today's Check-ins</h3>
                        <span style="background: var(--success); color: white; padding: 2px 8px; border-radius: 20px; font-size: 12px;">
                            <%= todaysCheckins.size() %>
                        </span>
                    </div>
                    
                    <% if(todaysCheckins.isEmpty()) { %>
                        <div class="no-data">
                            <i class="fas fa-check-circle"></i> No check-ins scheduled for today
                        </div>
                    <% } else { %>
                        <ul class="activity-list">
                            <% for(Reservation r : todaysCheckins) { %>
                            <li class="activity-item" onclick="window.location.href='view-reservation?number=<%= r.getReservationNumber() %>'">
                                <span>
                                    <span class="guest-name"><%= r.getGuestName() %></span>
                                    <span style="color: #666; font-size: 12px; display: block;">
                                        <%= r.getReservationNumber() %>
                                    </span>
                                </span>
                                <span class="room-number">
                                    <i class="fas fa-door-closed"></i> <%= r.getRoomNumber() != null ? r.getRoomNumber() : "—" %>
                                </span>
                            </li>
                            <% } %>
                        </ul>
                    <% } %>
                </div>

                <!-- Today's Check-outs -->
                <div class="activity-card">
                    <div class="activity-header">
                        <i class="fas fa-sign-out-alt" style="color: var(--danger);"></i>
                        <h3>Today's Check-outs</h3>
                        <span style="background: var(--danger); color: white; padding: 2px 8px; border-radius: 20px; font-size: 12px;">
                            <%= todaysCheckouts.size() %>
                        </span>
                    </div>
                    
                    <% if(todaysCheckouts.isEmpty()) { %>
                        <div class="no-data">
                            <i class="fas fa-check-circle"></i> No check-outs scheduled for today
                        </div>
                    <% } else { %>
                        <ul class="activity-list">
                            <% for(Reservation r : todaysCheckouts) { %>
                            <li class="activity-item" onclick="window.location.href='view-reservation?number=<%= r.getReservationNumber() %>'">
                                <span>
                                    <span class="guest-name"><%= r.getGuestName() %></span>
                                    <span style="color: #666; font-size: 12px; display: block;">
                                        <%= r.getReservationNumber() %>
                                    </span>
                                </span>
                                <span class="room-number">
                                    <i class="fas fa-door-closed"></i> <%= r.getRoomNumber() != null ? r.getRoomNumber() : "—" %>
                                </span>
                            </li>
                            <% } %>
                        </ul>
                    <% } %>
                </div>
            </div>

            <!-- ============ RECENT RESERVATIONS ============ -->
            <div class="section-title">
                <i class="fas fa-history"></i>
                Recent Reservations
            </div>

            <div class="recent-table-container">
                <table class="recent-table">
                    <thead>
                        <tr>
                            <th>Reservation #</th>
                            <th>Guest Name</th>
                            <th>Room</th>
                            <th>Check-in</th>
                            <th>Check-out</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if(recentReservations.isEmpty()) { %>
                            <tr>
                                <td colspan="6" style="text-align: center; padding: 30px; color: #666;">
                                    <i class="fas fa-calendar-times" style="font-size: 24px; margin-bottom: 10px; display: block;"></i>
                                    No reservations found
                                </td>
                            </tr>
                        <% } else { %>
                            <% for(Reservation r : recentReservations) { 
                                boolean isCheckedOut = checkOuts.containsKey(r.getReservationNumber());
                                String status;
                                String statusClass;
                                
                                if (isCheckedOut) {
                                    status = "COMPLETED";
                                    statusClass = "status-completed";
                                } else if (today.isBefore(r.getCheckIn())) {
                                    status = "UPCOMING";
                                    statusClass = "status-upcoming";
                                } else if (!today.isBefore(r.getCheckIn()) && !today.isAfter(r.getCheckOut())) {
                                    status = "ACTIVE";
                                    statusClass = "status-active";
                                } else {
                                    status = "OVERDUE";
                                    statusClass = "status-overdue";
                                }
                            %>
                            <tr onclick="window.location.href='view-reservation?number=<%= r.getReservationNumber() %>'">
                                <td><strong><%= r.getReservationNumber() %></strong></td>
                                <td><%= r.getGuestName() %></td>
                                <td><%= r.getRoomNumber() != null ? r.getRoomNumber() : "—" %></td>
                                <td><%= r.getCheckIn().format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %></td>
                                <td><%= r.getCheckOut().format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %></td>
                                <td><span class="status-badge <%= statusClass %>"><%= status %></span></td>
                            </tr>
                            <% } %>
                        <% } %>
                    </tbody>
                </table>
                <a href="view-reservations" class="view-all-link">
                    <i class="fas fa-arrow-right"></i> View All Reservations
                </a>
            </div>

            <!-- ============ FEATURES GRID ============ -->
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-calendar-plus"></i>
                    </div>
                    <h3>Add New Reservation</h3>
                    <p>Create new guest bookings with room assignments, check-in/out dates, and complete guest details.</p>
                    <a href="addReservation.jsp" class="feature-btn">
                        <i class="fas fa-plus-circle"></i> Create Booking
                    </a>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-list-alt"></i>
                    </div>
                    <h3>View Reservations</h3>
                    <p>Search and view all current and past reservations with complete guest information and booking details.</p>
                    <a href="view-reservations" class="feature-btn">
                        <i class="fas fa-search"></i> View Bookings
                    </a>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-file-invoice-dollar"></i>
                    </div>
                    <h3>Billing Center</h3>
                    <p>Calculate stay costs based on room rates and number of nights. Print professional invoices for guests.</p>
                    <a href="billing.jsp" class="feature-btn">
                        <i class="fas fa-calculator"></i> Generate Bill
                    </a>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-question-circle"></i>
                    </div>
                    <h3>Help & Support</h3>
                    <p>Get step-by-step guides on using the reservation system. Contact support for technical assistance.</p>
                    <a href="help.jsp" class="feature-btn">
                        <i class="fas fa-life-ring"></i> Get Help
                    </a>
                </div>
            </div>

            <!-- ============ FOOTER ============ -->
            <footer class="dashboard-footer">
                <p>Ocean View Resort Reservation System • © 2024 • Academic Project</p>
                <p style="margin-top: 5px; font-size: 12px;">All required functionalities implemented ✓</p>
            </footer>
        </main>
    </div>

    <script>
        // ============ UPDATE CURRENT TIME ============
        function updateTime() {
            const now = new Date();
            const timeString = now.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
            document.getElementById('currentTime').textContent = timeString;
        }
        updateTime();
        setInterval(updateTime, 60000);

        // ============ FEATURE BUTTONS CLICK EFFECT ============
        document.querySelectorAll('.feature-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                this.style.transform = 'scale(0.95)';
                setTimeout(() => {
                    this.style.transform = '';
                }, 200);
            });
        });

        // ============ SIDEBAR ACTIVE MENU ============
        const currentPage = window.location.pathname.split('/').pop() || 'dashboard.jsp';
        document.querySelectorAll('.menu-item').forEach(item => {
            const href = item.getAttribute('href');
            if (href === currentPage || (currentPage === 'dashboard.jsp' && href.includes('dashboard'))) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });

        // ============ LOCAL HOST NOTIFICATIONS (ALERTS) ============
        window.onload = function() {
            <% if("success".equals(type) && message != null) { 
                String decodedMessage = java.net.URLDecoder.decode(message, "UTF-8").replace("'", "\\'");
            %>
                // Show success alert
                setTimeout(function() {
                    alert("✅ Success!\n\n<%= decodedMessage %>");
                }, 300);
                
                // Clean the URL
                const url = new URL(window.location);
                url.searchParams.delete('type');
                url.searchParams.delete('message');
                window.history.replaceState({}, document.title, url);
            <% } else if("error".equals(type) && message != null) { 
                String decodedMessage = java.net.URLDecoder.decode(message, "UTF-8").replace("'", "\\'");
            %>
                // Show error alert
                setTimeout(function() {
                    alert("❌ Error!\n\n<%= decodedMessage %>");
                }, 300);
                
                // Clean the URL
                const url = new URL(window.location);
                url.searchParams.delete('type');
                url.searchParams.delete('message');
                window.history.replaceState({}, document.title, url);
            <% } %>
        };
    </script>

</body>
</html>