<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.dao.ReservationDao, 
                 com.oceanview.model.Reservation, 
                 java.util.List, 
                 java.time.LocalDate, 
                 java.util.ArrayList,
                 java.util.Map,
                 java.time.format.DateTimeFormatter" %>

<%
    // Check session
    HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String user = (String) userSession.getAttribute("username");
    
    // Get bills generated from session
    Map<String, Boolean> billsGenerated = (Map<String, Boolean>) userSession.getAttribute("billsGenerated");
    if (billsGenerated == null) {
        billsGenerated = new java.util.HashMap<>();
    }
    
    // Get check-outs from session
    Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) userSession.getAttribute("checkOuts");
    if (checkOuts == null) {
        checkOuts = new java.util.HashMap<>();
    }
    
    // Get all reservations from database
    ReservationDao reservationDao = new ReservationDao();
    List<Reservation> reservations = null;
    
    try {
        reservations = reservationDao.getAllReservations();
        System.out.println("✅ Loaded " + (reservations != null ? reservations.size() : 0) + " reservations for billing");
    } catch (Exception e) {
        System.err.println("❌ Error loading reservations: " + e.getMessage());
        e.printStackTrace();
    }
    
    // If reservations are null, create empty list to avoid null pointer
    if (reservations == null) {
        reservations = new ArrayList<>();
    }
    
    // Apply bill and check-out data to reservations
    for (Reservation r : reservations) {
        if (billsGenerated.containsKey(r.getReservationNumber())) {
            r.setBillingStatus("GENERATED");
        }
        LocalDate actualCheckOut = checkOuts.get(r.getReservationNumber());
        if (actualCheckOut != null) {
            r.setActualCheckOut(actualCheckOut);
        }
    }
    
    LocalDate today = LocalDate.now();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy");
    
    // ============ COMPREHENSIVE BILLING STATS ============
    long totalReservations = reservations.size();
    long activeCount = 0;        // In hotel, no bill
    long readyCount = 0;          // In hotel, bill ready
    long overdueCount = 0;        // Past checkout, no bill ⚠️
    long completedCount = 0;      // Checked out
    long dueTodayCount = 0;       // Checking out today (any status)
    long dueTodayNeedBillCount = 0; // Checking out today with no bill (urgent)
    
    for (Reservation r : reservations) {
        boolean hasBill = billsGenerated.containsKey(r.getReservationNumber());
        boolean hasCheckedOut = checkOuts.containsKey(r.getReservationNumber());
        
        if (hasCheckedOut) {
            completedCount++;
        } 
        else if (today.isBefore(r.getCheckIn())) {
            // Upcoming - ignore for billing stats
        }
        else if (today.isAfter(r.getCheckOut()) && !hasBill) {
            overdueCount++;  // Past checkout, no bill ⚠️
        }
        else {
            // Current stay
            if (hasBill) {
                readyCount++;
            } else {
                activeCount++;
            }
            
            // Check if checking out today
            if (r.getCheckOut().equals(today)) {
                dueTodayCount++;
                if (!hasBill) {
                    dueTodayNeedBillCount++;
                }
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Billing Center - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============ PROFESSIONAL THEME ============ */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: linear-gradient(135deg, #f0f8ff 0%, #e3f2fd 100%);
            min-height: 100vh;
            color: #2c3e50;
        }

        /* ============ COLOR PALETTE ============ */
        :root {
            --primary: #0077b6;
            --primary-dark: #023e8a;
            --primary-light: #00b4d8;
            --secondary: #00b4d8;
            --success: #28a745;
            --success-dark: #1e7e34;
            --warning: #ffc107;
            --warning-dark: #d39e00;
            --danger: #dc3545;
            --danger-dark: #bd2130;
            --info: #17a2b8;
            --info-dark: #117a8b;
            --light: #f8f9fa;
            --dark: #343a40;
            --white: #ffffff;
            --gray-100: #f8f9fa;
            --gray-200: #e9ecef;
            --gray-300: #dee2e6;
            --gray-600: #6c757d;
            --gray-700: #495057;
            --shadow-sm: 0 2px 4px rgba(0,0,0,0.05);
            --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.08);
            --shadow-lg: 0 8px 24px rgba(0, 119, 182, 0.15);
            --border-radius: 10px;
            --border-radius-sm: 6px;
        }

        /* ============ TOP NAVIGATION ============ */
        .top-nav {
            background: var(--white);
            padding: 0 30px;
            height: 70px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: var(--shadow-md);
            position: sticky;
            top: 0;
            z-index: 1000;
            border-bottom: 3px solid var(--primary);
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
            color: var(--primary-dark);
            font-weight: 600;
        }

        .logo-text p {
            font-size: 11px;
            color: var(--gray-600);
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
            color: var(--primary-dark);
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
            box-shadow: var(--shadow-sm);
        }

        .logout-btn {
            background: transparent;
            color: var(--gray-600);
            border: 1px solid var(--gray-300);
            padding: 8px 16px;
            border-radius: var(--border-radius-sm);
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
        .container {
            max-width: 1600px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* ============ PAGE HEADER ============ */
        .page-header {
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            color: white;
            padding: 20px 25px;
            border-radius: var(--border-radius);
            margin-bottom: 25px;
            box-shadow: var(--shadow-lg);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }

        .header-left h1 {
            font-size: 24px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 5px;
        }

        .header-left h1 i {
            opacity: 0.9;
        }

        .header-left p {
            color: rgba(255, 255, 255, 0.9);
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .header-right {
            display: flex;
            gap: 10px;
        }

        .header-btn {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: white;
            padding: 8px 16px;
            border-radius: var(--border-radius-sm);
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
            cursor: pointer;
        }

        .header-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }

        /* ============ STATS ROW ============ */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }

        .stat-card {
            background: var(--white);
            padding: 20px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-md);
            display: flex;
            align-items: center;
            gap: 15px;
            transition: all 0.3s;
            cursor: pointer;
            border: 1px solid var(--gray-200);
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-lg);
            border-color: var(--primary-light);
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 22px;
        }

        .stat-content h3 {
            font-size: 24px;
            font-weight: 600;
            color: var(--primary-dark);
            margin-bottom: 3px;
        }

        .stat-content p {
            color: var(--gray-600);
            font-size: 13px;
            font-weight: 500;
        }

        .stat-content small {
            color: var(--gray-600);
            font-size: 11px;
            display: block;
            margin-top: 2px;
        }

        /* Stat card specific colors */
        .stat-card.need-bill .stat-icon {
            background: linear-gradient(135deg, var(--success), #20c997);
        }

        .stat-card.ready .stat-icon {
            background: linear-gradient(135deg, #ff9800, #ffb74d);
        }

        .stat-card.due-today .stat-icon {
            background: linear-gradient(135deg, #fd7e14, #ffb74d);
        }

        .stat-card.overdue .stat-icon {
            background: linear-gradient(135deg, var(--danger), #ff6b6b);
        }

        .stat-card.completed .stat-icon {
            background: linear-gradient(135deg, var(--gray-600), #8f9bae);
        }

        /* ============ SEARCH AND FILTER SECTION ============ */
        .filter-section {
            background: var(--white);
            padding: 20px;
            border-radius: var(--border-radius);
            margin-bottom: 25px;
            box-shadow: var(--shadow-md);
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            align-items: center;
            border: 1px solid var(--gray-200);
        }

        .search-box {
            flex: 1;
            min-width: 300px;
            position: relative;
        }

        .search-box input {
            width: 100%;
            padding: 12px 45px 12px 15px;
            border: 2px solid var(--gray-200);
            border-radius: var(--border-radius-sm);
            font-size: 14px;
            transition: all 0.2s;
        }

        .search-box input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(0, 119, 182, 0.1);
        }

        .search-box i {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--gray-600);
        }

        .filter-buttons {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .filter-btn {
            padding: 8px 16px;
            border-radius: 30px;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 13px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 6px;
            border: 1px solid var(--gray-200);
            background: var(--white);
            color: var(--gray-700);
        }

        .filter-btn i {
            font-size: 12px;
        }

        .filter-btn:hover {
            background: var(--gray-100);
            border-color: var(--gray-300);
        }

        .filter-btn.active {
            border-width: 2px;
        }

        .filter-btn.active[data-filter="all"] {
            background: var(--gray-200);
            border-color: var(--gray-600);
            color: var(--dark);
        }

        .filter-btn.active[data-filter="need-bill"] {
            background: #d4edda;
            border-color: var(--success);
            color: var(--success-dark);
        }

        .filter-btn.active[data-filter="ready"] {
            background: #fff3e0;
            border-color: #ff9800;
            color: #e65100;
        }

        .filter-btn.active[data-filter="due-today"] {
            background: #fff3cd;
            border-color: #fd7e14;
            color: #856404;
        }

        .filter-btn.active[data-filter="overdue"] {
            background: #f8d7da;
            border-color: var(--danger);
            color: var(--danger-dark);
        }

        .filter-btn.active[data-filter="completed"] {
            background: #e2e3e5;
            border-color: var(--gray-600);
            color: var(--dark);
        }

        /* ============ TABLE CONTAINER ============ */
        .table-container {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-md);
            overflow: hidden;
            margin-bottom: 25px;
            border: 1px solid var(--gray-200);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1300px;
        }

        thead {
            background: var(--primary);
        }

        th {
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        tbody tr {
            border-bottom: 1px solid var(--gray-200);
            transition: background 0.2s;
        }

        tbody tr:hover {
            background: var(--gray-100);
        }

        td {
            padding: 15px;
            color: var(--gray-700);
            font-size: 14px;
        }

        .reservation-number {
            color: var(--primary-dark);
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .reservation-number i {
            color: var(--primary);
        }

        .guest-name {
            font-weight: 600;
            color: var(--primary-dark);
            font-size: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
            margin-bottom: 4px;
        }

        .guest-name i {
            color: var(--primary);
        }

        .guest-contact {
            font-size: 12px;
            color: var(--gray-600);
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .guest-contact i {
            color: var(--primary);
            width: 14px;
        }

        .date-info {
            font-size: 12px;
            color: var(--gray-600);
            display: flex;
            flex-direction: column;
            gap: 3px;
        }

        .date-info i {
            color: var(--primary);
            width: 16px;
        }

        .date-info .due-today {
            color: #fd7e14;
            font-weight: 600;
        }

        .date-info .overdue-date {
            color: var(--danger);
            font-weight: 600;
        }

        .room-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            border-radius: 30px;
            font-size: 12px;
            font-weight: 500;
            background: var(--gray-100);
            color: var(--gray-700);
            border: 1px solid var(--gray-300);
        }

        .room-badge i {
            color: var(--primary);
        }

        .room-number {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            background: #e3f2fd;
            border-radius: 30px;
            color: var(--primary-dark);
            font-weight: 500;
            font-size: 12px;
            margin-bottom: 5px;
        }

        .room-number i {
            color: var(--primary);
        }

        .no-room {
            color: var(--gray-600);
            font-style: italic;
            display: flex;
            align-items: center;
            gap: 5px;
            font-size: 12px;
        }

        .no-room i {
            color: var(--gray-400);
        }

        /* ============ STATUS BADGES ============ */
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            border-radius: 30px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-active {
            background: #d4edda;
            color: var(--success-dark);
        }

        .status-ready {
            background: #fff3e0;
            color: #e65100;
        }

        .status-overdue {
            background: #f8d7da;
            color: var(--danger-dark);
            animation: pulse 2s infinite;
        }

        .status-completed {
            background: #e2e3e5;
            color: var(--gray-700);
        }

        .status-upcoming {
            background: #e3f2fd;
            color: var(--primary-dark);
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.8; box-shadow: 0 0 0 3px rgba(220,53,69,0.2); }
            100% { opacity: 1; }
        }

        /* ============ SPECIAL BADGES ============ */
        .due-today-badge, .need-bill-badge, .billed-badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 10px;
            font-weight: 600;
            white-space: nowrap;
        }

        .due-today-badge {
            background: #fd7e14;
            color: white;
        }

        .need-bill-badge {
            background: var(--danger);
            color: white;
            animation: gentle-pulse 2s infinite;
        }

        .billed-badge {
            background: var(--success);
            color: white;
        }

        @keyframes gentle-pulse {
            0% { opacity: 1; }
            50% { opacity: 0.9; box-shadow: 0 0 5px rgba(220,53,69,0.3); }
            100% { opacity: 1; }
        }

        /* ============ ACTION BUTTONS ============ */
        .actions {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }

        .action-btn {
            padding: 6px 10px;
            border-radius: var(--border-radius-sm);
            display: inline-flex;
            align-items: center;
            gap: 4px;
            cursor: pointer;
            transition: all 0.2s;
            color: white;
            text-decoration: none;
            border: none;
            font-size: 11px;
            font-weight: 500;
        }

        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
        }

        .btn-generate {
            background: var(--success);
        }

        .btn-view {
            background: var(--primary);
        }

        .btn-checkout {
            background: var(--info);
        }

        .btn-print {
            background: #fd7e14;
        }

        .btn-disabled {
            background: var(--gray-600);
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
        }

        /* ============ BOTTOM NAVIGATION ============ */
        .bottom-nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 25px;
        }

        .nav-btn {
            padding: 12px 24px;
            border-radius: var(--border-radius-sm);
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s;
            border: none;
            cursor: pointer;
        }

        .nav-btn.primary {
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            color: white;
            box-shadow: var(--shadow-md);
        }

        .nav-btn.primary:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }

        .nav-btn.secondary {
            background: var(--white);
            color: var(--primary-dark);
            border: 1px solid var(--gray-300);
        }

        .nav-btn.secondary:hover {
            background: var(--gray-100);
        }

        .nav-right {
            display: flex;
            gap: 10px;
        }

        /* ============ NO DATA STATE ============ */
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: var(--gray-600);
        }

        .no-data i {
            font-size: 48px;
            color: var(--gray-400);
            margin-bottom: 15px;
        }

        .no-data h3 {
            color: var(--primary-dark);
            font-size: 20px;
            margin-bottom: 10px;
            font-weight: 500;
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 1400px) {
            .stats-row {
                grid-template-columns: repeat(3, 1fr);
            }
        }

        @media (max-width: 992px) {
            .stats-row {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .stats-row {
                grid-template-columns: 1fr;
            }
            
            .filter-section {
                flex-direction: column;
            }
            
            .search-box {
                min-width: 100%;
            }
            
            .bottom-nav {
                flex-direction: column;
                gap: 15px;
            }
            
            .nav-right {
                flex-direction: column;
                width: 100%;
            }
            
            .nav-btn {
                width: 100%;
                justify-content: center;
            }
            
            .actions {
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

    <!-- ============ TOP NAVIGATION ============ -->
    <nav class="top-nav">
        <div class="logo-section">
            <i class="fas fa-umbrella-beach logo-icon"></i>
            <div class="logo-text">
                <h1>Ocean View Resort</h1>
                <p>Billing Center</p>
            </div>
        </div>
        
        <div class="user-section">
            <div class="user-info">
                <div class="user-details">
                    <div class="user-name"><%= user %></div>
                </div>
                <div class="user-avatar">
                    <%= user.substring(0,1).toUpperCase() %>
                </div>
            </div>
            <a href="logout" class="logout-btn">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </div>
    </nav>

    <!-- ============ MAIN CONTAINER ============ -->
    <div class="container">
        
        <!-- ============ PAGE HEADER ============ -->
        <div class="page-header">
            <div class="header-left">
                <h1>
                    <i class="fas fa-file-invoice-dollar"></i>
                    Billing Center
                </h1>
                <p>
                    <i class="fas fa-sun"></i>
                    Generate bills and process check-outs
                </p>
            </div>
            <div class="header-right">
                <a href="view-reservations" class="header-btn">
                    <i class="fas fa-list"></i> Reservations
                </a>
                <a href="dashboard.jsp" class="header-btn">
                    <i class="fas fa-arrow-left"></i> Dashboard
                </a>
            </div>
        </div>

        <!-- ============ STATS ROW ============ -->
        <div class="stats-row">
            <div class="stat-card need-bill" onclick="filterByStat('need-bill')">
                <div class="stat-icon">
                    <i class="fas fa-sun"></i>
                </div>
                <div class="stat-content">
                    <h3><%= activeCount %></h3>
                    <p>Need Bill</p>
                    <small>Active stays</small>
                </div>
            </div>
            
            <div class="stat-card ready" onclick="filterByStat('ready')">
                <div class="stat-icon">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="stat-content">
                    <h3><%= readyCount %></h3>
                    <p>Ready</p>
                    <small>Bill generated</small>
                </div>
            </div>
            
            <div class="stat-card due-today" onclick="filterByStat('due-today')">
                <div class="stat-icon">
                    <i class="fas fa-calendar-day"></i>
                </div>
                <div class="stat-content">
                    <h3><%= dueTodayCount %></h3>
                    <p>Due Today</p>
                    <small><%= dueTodayNeedBillCount %> need bill</small>
                </div>
            </div>
            
            <div class="stat-card overdue" onclick="filterByStat('overdue')">
                <div class="stat-icon">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
                <div class="stat-content">
                    <h3><%= overdueCount %></h3>
                    <p>Overdue</p>
                    <small>Immediate action</small>
                </div>
            </div>
            
            <div class="stat-card completed" onclick="filterByStat('completed')">
                <div class="stat-icon">
                    <i class="fas fa-check-double"></i>
                </div>
                <div class="stat-content">
                    <h3><%= completedCount %></h3>
                    <p>Completed</p>
                    <small>Checked out</small>
                </div>
            </div>
        </div>

        <!-- ============ SEARCH AND FILTER SECTION ============ -->
        <div class="filter-section">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search by guest name, reservation #, room number...">
                <i class="fas fa-search"></i>
            </div>
            
            <div class="filter-buttons">
                <button class="filter-btn active" data-filter="all"><i class="fas fa-list-ul"></i> All</button>
                <button class="filter-btn" data-filter="need-bill"><i class="fas fa-sun"></i> Need Bill</button>
                <button class="filter-btn" data-filter="ready"><i class="fas fa-check-circle"></i> Ready</button>
                <button class="filter-btn" data-filter="due-today"><i class="fas fa-calendar-day"></i> Due Today</button>
                <button class="filter-btn" data-filter="overdue"><i class="fas fa-exclamation-triangle"></i> Overdue</button>
                <button class="filter-btn" data-filter="completed"><i class="fas fa-check-double"></i> Completed</button>
            </div>
        </div>

        <!-- ============ TABLE CONTAINER ============ -->
        <div class="table-container">
            <% if (reservations.isEmpty()) { %>
                <div class="no-data">
                    <i class="fas fa-calendar-times"></i>
                    <h3>No Reservations Found</h3>
                    <p>There are no reservations in the system yet.</p>
                </div>
            <% } else { %>
                <table id="billingTable">
                    <thead>
                        <tr>
                            <th>Reservation #</th>
                            <th>Guest Information</th>
                            <th>Room</th>
                            <th>Check-in/out</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                        for (Reservation r : reservations) {
                            boolean hasBill = billsGenerated.containsKey(r.getReservationNumber());
                            boolean hasCheckedOut = checkOuts.containsKey(r.getReservationNumber());
                            boolean isDueToday = r.getCheckOut().equals(today) && !hasCheckedOut;
                            
                            // Determine status
                            String status;
                            String statusClass;
                            String statusIcon;
                            String filterStatus;
                            
                            if (hasCheckedOut) {
                                status = "COMPLETED";
                                statusClass = "status-completed";
                                statusIcon = "check-double";
                                filterStatus = "completed";
                            }
                            else if (today.isBefore(r.getCheckIn())) {
                                status = "UPCOMING";
                                statusClass = "status-upcoming";
                                statusIcon = "clock";
                                filterStatus = "upcoming";
                            }
                            else if (today.isAfter(r.getCheckOut()) && !hasBill) {
                                status = "OVERDUE";
                                statusClass = "status-overdue";
                                statusIcon = "exclamation-triangle";
                                filterStatus = "overdue";
                            }
                            else {
                                if (hasBill) {
                                    status = "READY";
                                    statusClass = "status-ready";
                                    statusIcon = "check-circle";
                                    filterStatus = "ready";
                                } else {
                                    status = "ACTIVE";
                                    statusClass = "status-active";
                                    statusIcon = "sun";
                                    filterStatus = "need-bill";
                                }
                            }
                            
                            // Room badge class
                            String roomTypeDisplay = r.getRoomType() != null ? r.getRoomType() : "N/A";
                            String roomNumber = r.getRoomNumber();
                            
                            // Date styling
                            String checkOutClass = "";
                            if (isDueToday) {
                                checkOutClass = "due-today";
                            } else if (today.isAfter(r.getCheckOut()) && !hasCheckedOut) {
                                checkOutClass = "overdue-date";
                            }
                        %>
                        <tr data-status="<%= filterStatus %>" 
                            data-duetoday="<%= isDueToday ? "yes" : "no" %>">
                            
                            <!-- Reservation Number -->
                            <td>
                                <span class="reservation-number">
                                    <i class="fas fa-hashtag"></i> <%= r.getReservationNumber() %>
                                </span>
                                <% if (hasBill) { %>
                                    <span class="billed-badge" title="Bill generated">
                                        <i class="fas fa-check-circle"></i> Billed
                                    </span>
                                <% } %>
                            </td>
                            
                            <!-- Guest Information -->
                            <td>
                                <span class="guest-name">
                                    <i class="fas fa-user-circle"></i> <%= r.getGuestName() != null ? r.getGuestName() : "N/A" %>
                                    <% if (isDueToday && !hasBill) { %>
                                        <span class="need-bill-badge" title="Urgent: Due today with no bill">
                                            <i class="fas fa-exclamation-circle"></i> NEED BILL
                                        </span>
                                    <% } else if (isDueToday && hasBill) { %>
                                        <span class="due-today-badge" title="Ready to check-out today">
                                            <i class="fas fa-check-circle"></i> READY
                                        </span>
                                    <% } %>
                                </span>
                                <span class="guest-contact">
                                    <i class="fas fa-phone-alt"></i> <%= r.getContactNumber() != null ? r.getContactNumber() : "N/A" %>
                                </span>
                            </td>
                            
                            <!-- Room -->
                            <td>
                                <% if (roomNumber != null && !roomNumber.isEmpty()) { %>
                                    <span class="room-number">
                                        <i class="fas fa-door-closed"></i> <%= roomNumber %>
                                    </span>
                                <% } else { %>
                                    <span class="no-room">
                                        <i class="fas fa-question-circle"></i> Not Assigned
                                    </span>
                                <% } %>
                                <span class="room-badge" style="margin-top: 5px; display: inline-block;">
                                    <i class="fas fa-bed"></i> <%= roomTypeDisplay %>
                                </span>
                            </td>
                            
                            <!-- Check-in/out -->
                            <td>
                                <div class="date-info">
                                    <div>
                                        <i class="fas fa-calendar-alt"></i> In: <%= r.getCheckIn().format(formatter) %>
                                    </div>
                                    <div class="<%= checkOutClass %>">
                                        <i class="fas fa-calendar-check"></i> Out: <%= r.getCheckOut().format(formatter) %>
                                        <% if (isDueToday) { %>
                                            <i class="fas fa-exclamation-circle" style="margin-left: 5px;"></i> TODAY
                                        <% } %>
                                    </div>
                                </div>
                            </td>
                            
                            <!-- Status -->
                            <td>
                                <span class="status-badge <%= statusClass %>">
                                    <i class="fas fa-<%= statusIcon %>"></i>
                                    <%= status %>
                                </span>
                            </td>
                            
                            <!-- Actions -->
                            <td>
                                <div class="actions">
                                    <% if (hasCheckedOut) { %>
                                        <!-- Already checked out -->
                                        <% if (hasBill) { %>
                                            <a href="generate-bill?number=<%= r.getReservationNumber() %>" 
                                               class="action-btn btn-view" title="View Bill">
                                                <i class="fas fa-file-invoice"></i> View
                                            </a>
                                        <% } %>
                                        
                                    <% } else { %>
                                        <!-- Guest still in hotel -->
                                        
                                        <% if (!hasBill) { %>
                                            <!-- NEED BILL (Active, Due Today, or Overdue) -->
                                            <a href="generate-bill?number=<%= r.getReservationNumber() %>&action=generate" 
                                               class="action-btn btn-generate" 
                                               title="<%= isDueToday ? "URGENT: Due today - Generate Bill" : "Generate Bill" %>">
                                                <i class="fas fa-file-invoice-dollar"></i> Generate
                                            </a>
                                            
                                        <% } else { %>
                                            <!-- READY (Has bill) -->
                                            <a href="generate-bill?number=<%= r.getReservationNumber() %>" 
                                               class="action-btn btn-view" title="View Bill">
                                                <i class="fas fa-file-invoice"></i> View
                                            </a>
                                            <button onclick="checkoutGuest('<%= r.getReservationNumber() %>', '<%= r.getGuestName() %>', event)" 
                                                    class="action-btn btn-checkout" title="Check-out Guest">
                                                <i class="fas fa-sign-out-alt"></i> Check-out
                                            </button>
                                            <button onclick="printInvoice('<%= r.getReservationNumber() %>', event)" 
                                                    class="action-btn btn-print" title="Print Bill">
                                                <i class="fas fa-print"></i> Print
                                            </button>
                                        <% } %>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>

        <!-- ============ BOTTOM NAVIGATION ============ -->
        <div class="bottom-nav">
            <a href="dashboard.jsp" class="nav-btn secondary">
                <i class="fas fa-arrow-left"></i> Dashboard
            </a>
            <div class="nav-right">
                <a href="view-reservations" class="nav-btn primary">
                    <i class="fas fa-list"></i> View Reservations
                </a>
            </div>
        </div>
    </div>

    <script>
        // ============ BILLING FUNCTIONS ============
        
        function printInvoice(reservationNumber, event) {
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }
            
            const printWindow = window.open('generate-bill?number=' + reservationNumber, '_blank');
            if (printWindow) {
                printWindow.onload = function() {
                    setTimeout(() => {
                        printWindow.print();
                    }, 1000);
                };
            } else {
                alert('Please allow pop-ups to print invoices');
            }
        }
        
        function checkoutGuest(reservationNumber, guestName, event) {
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }
            
            if (confirm('Check out ' + guestName + '?\n\nMake sure bill has been generated first.')) {
                const btn = event.target.closest('button');
                if (btn) {
                    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
                    btn.disabled = true;
                }
                
                window.location.href = 'checkout-guest?number=' + encodeURIComponent(reservationNumber);
            }
        }

        // ============ SEARCH AND FILTER FUNCTIONS ============

        document.getElementById('searchInput').addEventListener('input', function(e) {
            filterTable(e.target.value.toLowerCase().trim());
        });

        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                this.classList.add('active');
                filterTable(null, this.getAttribute('data-filter'));
            });
        });

        function filterTable(searchTerm = null, filterType = 'all') {
            const rows = document.querySelectorAll('#billingTable tbody tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const rowText = row.textContent.toLowerCase();
                const rowStatus = row.getAttribute('data-status');
                const dueToday = row.getAttribute('data-duetoday') === 'yes';
                
                let show = true;
                
                // Apply search filter
                if (searchTerm && searchTerm !== '') {
                    if (!rowText.includes(searchTerm)) show = false;
                }
                
                // Apply status filter
                if (show && filterType !== 'all') {
                    if (filterType === 'due-today') {
                        show = dueToday;
                    } else {
                        show = (rowStatus === filterType);
                    }
                }
                
                row.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });
            
            updateNoResultsMessage(visibleCount);
        }

        function updateNoResultsMessage(visibleCount) {
            const tableBody = document.querySelector('#billingTable tbody');
            let noResultsRow = document.getElementById('noResultsRow');
            
            if (visibleCount === 0 && !noResultsRow) {
                noResultsRow = document.createElement('tr');
                noResultsRow.id = 'noResultsRow';
                noResultsRow.innerHTML = '<td colspan="6" style="text-align: center; padding: 40px;">' +
                    '<i class="fas fa-search" style="font-size: 36px; color: #ccc; margin-bottom: 10px;"></i>' +
                    '<h3 style="color: #666;">No reservations match your criteria</h3>' +
                    '<button onclick="clearFilters()" style="margin-top: 15px; padding: 8px 20px; background: #0077b6; color: white; border: none; border-radius: 6px; cursor: pointer;">Clear Filters</button>' +
                    '</td>';
                tableBody.appendChild(noResultsRow);
            } else if (visibleCount > 0 && noResultsRow) {
                noResultsRow.remove();
            }
        }

        function filterByStat(filter) {
            document.querySelectorAll('.filter-btn').forEach(btn => {
                btn.classList.remove('active');
                if (btn.getAttribute('data-filter') === filter) {
                    btn.classList.add('active');
                }
            });
            filterTable(null, filter);
        }

        function clearFilters() {
            document.getElementById('searchInput').value = '';
            document.querySelectorAll('.filter-btn').forEach(btn => {
                btn.classList.remove('active');
                if (btn.getAttribute('data-filter') === 'all') {
                    btn.classList.add('active');
                }
            });
            filterTable();
        }

        // ============ KEYBOARD SHORTCUTS ============

        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
                e.preventDefault();
                document.getElementById('searchInput').focus();
            }
            if (e.key === 'Escape') {
                clearFilters();
            }
        });

        // ============ HANDLE URL PARAMETERS FOR AUTO-SEARCH ============
        document.addEventListener('DOMContentLoaded', function() {
            // Check if there are search parameters in the URL
            const urlParams = new URLSearchParams(window.location.search);
            const searchType = urlParams.get('searchType');
            const searchValue = urlParams.get('searchValue');
            
            // If both parameters exist, trigger the search
            if (searchType && searchValue) {
                console.log('🔍 Auto-searching for:', searchType, searchValue);
                
                // Set the search input value
                const searchInput = document.getElementById('searchInput');
                if (searchInput) {
                    searchInput.value = searchValue;
                    
                    // Trigger the filter function after a short delay
                    setTimeout(() => {
                        filterTable(searchValue.toLowerCase().trim(), 'all');
                    }, 300);
                }
            }
        });

        // ============ INITIALIZATION ============

        document.addEventListener('DOMContentLoaded', function() {
            filterTable();
        });

        // ============ ALERT MESSAGES ============

        window.onload = function() {
            <% 
            String type = request.getParameter("type");
            String message = request.getParameter("message");
            
            if("success".equals(type) && message != null) { 
            %>
                setTimeout(() => alert("✅ " + decodeURIComponent("<%= message %>")), 300);
            <% 
            } else if("error".equals(type) && message != null) { 
            %>
                setTimeout(() => alert("❌ " + decodeURIComponent("<%= message %>")), 300);
            <% 
            } 
            %>
        };
    </script>
</body>
</html>