<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.oceanview.model.Reservation, java.util.Map, java.time.LocalDate, java.time.format.DateTimeFormatter" %>
<%
    // Get the reservations from request
    List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
    
    // If reservations are null, show error
    if (reservations == null) {
        %>
        <div class="alert alert-danger">Error loading reservations. Please try again.</div>
        <%
        return;
    }
    
    // Get bills generated from session
    Map<String, Boolean> billsGenerated = (Map<String, Boolean>) session.getAttribute("billsGenerated");
    if (billsGenerated == null) {
        billsGenerated = new java.util.HashMap<>();
    }
    
    // Get check-outs from session
    Map<String, LocalDate> checkOuts = (Map<String, LocalDate>) session.getAttribute("checkOuts");
    if (checkOuts == null) {
        checkOuts = new java.util.HashMap<>();
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
    
    // Get stats from request
    Long roomsAssigned = (Long) request.getAttribute("roomsAssigned");
    if (roomsAssigned == null) {
        roomsAssigned = 0L;
        for (Reservation r : reservations) {
            if (r.getRoomNumber() != null && !r.getRoomNumber().isEmpty()) {
                roomsAssigned++;
            }
        }
    }
    
    Double totalRevenue = (Double) request.getAttribute("totalRevenue");
    if (totalRevenue == null) totalRevenue = 0.0;
    
    // ============ SIMPLE STATS FOR RESERVATION PAGE ============
    LocalDate today = LocalDate.now();
    
    long upcomingCount = 0;
    long activeCount = 0;        // In hotel, no bill
    long readyCount = 0;          // In hotel, bill ready
    long completedCount = 0;      // Checked out
    long inHouseCount = 0;
    
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM");
    
    for (Reservation r : reservations) {
        boolean hasBill = billsGenerated.containsKey(r.getReservationNumber());
        boolean hasCheckedOut = checkOuts.containsKey(r.getReservationNumber());
        
        if (hasCheckedOut) {
            completedCount++;
        } 
        else if (today.isBefore(r.getCheckIn())) {
            upcomingCount++;
        }
        else {
            inHouseCount++;  // Current stay
            if (hasBill) {
                readyCount++;
            } else {
                activeCount++;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Reservations - Ocean View Resort</title>
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
            --purple: #6f42c1;
            --orange: #fd7e14;
            --teal: #20c997;
            --ready: #ff9800;
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

        /* ============ MAIN CONTAINER ============ */
        .container {
            max-width: 1600px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* ============ PAGE HEADER ============ */
        .page-header {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            padding: 20px 25px;
            border-radius: var(--border-radius);
            margin-bottom: 25px;
            box-shadow: var(--shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }

        .header-left h1 {
            font-size: 24px;
            font-weight: 600;
            color: white;
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
            border-radius: 8px;
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
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }

        .stat-card {
            background: var(--white);
            padding: 20px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            display: flex;
            align-items: center;
            gap: 15px;
            transition: all 0.3s;
            cursor: pointer;
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 20px rgba(0, 119, 182, 0.15);
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
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
            color: var(--dark);
            margin-bottom: 3px;
        }

        .stat-content p {
            color: #666;
            font-size: 13px;
            font-weight: 500;
        }

        /* ============ SEARCH AND FILTER SECTION ============ */
        .filter-section {
            background: var(--white);
            padding: 20px;
            border-radius: var(--border-radius);
            margin-bottom: 25px;
            box-shadow: var(--shadow);
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            align-items: center;
        }

        .search-box {
            flex: 1;
            min-width: 300px;
            position: relative;
        }

        .search-box input {
            width: 100%;
            padding: 12px 45px 12px 15px;
            border: 1px solid #e9ecef;
            border-radius: 8px;
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
            color: var(--primary);
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
            border: 1px solid #e9ecef;
            background: white;
            color: #555;
        }

        .filter-btn i {
            font-size: 12px;
        }

        .filter-btn:hover {
            background: #f1f3f5;
        }

        .filter-btn.active {
            border-width: 2px;
        }

        .filter-btn.active[data-filter="all"] {
            background: #e9ecef;
            border-color: #6c757d;
        }

        .filter-btn.active[data-filter="upcoming"] {
            background: #e3f2fd;
            border-color: #2196f3;
        }

        .filter-btn.active[data-filter="active"] {
            background: #d4edda;
            border-color: #28a745;
        }

        .filter-btn.active[data-filter="ready"] {
            background: #fff3e0;
            border-color: #ff9800;
        }

        .filter-btn.active[data-filter="completed"] {
            background: #6c757d;
            border-color: #495057;
            color: white;
        }

        .filter-btn.active[data-filter="assigned"] {
            background: #e3f2fd;
            border-color: #0077b6;
        }

        .filter-btn.active[data-filter="unassigned"] {
            background: #ffebee;
            border-color: #dc3545;
        }

        /* ============ TABLE CONTAINER ============ */
        .table-container {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 25px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1200px;
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
            letter-spacing: 0.3px;
        }

        tbody tr {
            border-bottom: 1px solid #e9ecef;
            transition: background 0.2s;
            cursor: pointer;
        }

        tbody tr:hover {
            background: var(--light-bg);
        }

        td {
            padding: 15px;
            color: #333;
            font-size: 14px;
        }

        .reservation-number {
            color: var(--dark);
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
            color: var(--dark);
            font-size: 15px;
            display: block;
            margin-bottom: 3px;
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .guest-name i {
            color: var(--primary);
            margin-right: 5px;
        }

        .guest-contact {
            font-size: 12px;
            color: #666;
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .guest-contact i {
            color: var(--primary);
            width: 14px;
        }

        .date-range {
            display: flex;
            align-items: center;
            gap: 5px;
            color: #666;
            font-size: 12px;
            margin-top: 3px;
        }

        .date-range i {
            color: var(--primary);
        }

        .room-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            border-radius: 30px;
            font-size: 13px;
            font-weight: 500;
        }

        .room-standard {
            background: #e3f2fd;
            color: #1565c0;
        }

        .room-deluxe {
            background: #e8f5e9;
            color: #2e7d32;
        }

        .room-suite {
            background: #fff3e0;
            color: #e65100;
        }

        .room-number {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 12px;
            background: #e8f4fd;
            border-radius: 30px;
            color: var(--dark);
            font-weight: 500;
            font-size: 13px;
        }

        .room-number i {
            color: var(--primary);
        }

        .no-room {
            color: #999;
            font-style: italic;
            display: flex;
            align-items: center;
            gap: 5px;
            font-size: 13px;
        }

        .no-room i {
            color: #ccc;
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
            border-left: 4px solid;
        }

        .status-upcoming {
            background: #e3f2fd;
            color: #1565c0;
            border-left-color: #2196f3;
        }

        .status-active {
            background: #d4edda;
            color: #155724;
            border-left-color: #28a745;
        }

        .status-ready {
            background: #fff3e0;
            color: #e65100;
            border-left-color: #ff9800;
        }

        .status-completed {
            background: #6c757d;
            color: white;
            border-left-color: #495057;
        }

        /* ============ DUE TODAY HIGHLIGHT ============ */
        .due-today-highlight {
            background-color: #fff3cd;
            border-left: 3px solid #fd7e14;
            font-weight: 500;
        }

        .due-today-badge {
            background-color: #fd7e14;
            color: white;
            font-size: 10px;
            padding: 2px 8px;
            border-radius: 12px;
            margin-left: 8px;
            display: inline-flex;
            align-items: center;
            gap: 3px;
            font-weight: 600;
        }

        .due-today-badge i {
            font-size: 8px;
        }

        /* Bill indicator */
        .bill-indicator {
            display: inline-flex;
            align-items: center;
            gap: 3px;
            background: var(--primary);
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 10px;
            margin-left: 5px;
        }

        /* Check-out info */
        .checkout-info {
            font-size: 11px;
            color: #666;
            margin-top: 3px;
        }
        
        .checkout-info i {
            color: #17a2b8;
            margin-right: 3px;
        }
        
        .early-checkout {
            color: #28a745;
        }
        
        .late-checkout {
            color: #dc3545;
        }

        /* ============ ACTION BUTTONS ============ */
        .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .action-btn {
            width: 32px;
            height: 32px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
            color: white;
            text-decoration: none;
            border: none;
        }

        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
        }

        .btn-view {
            background: var(--primary);
        }

        .btn-edit {
            background: var(--warning);
            color: #333;
        }

        .btn-delete {
            background: var(--danger);
        }

        .btn-billing-link {
            background: var(--info);
        }

        .action-btn.disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
        }

        .action-btn[title] {
            position: relative;
        }

        .action-btn[title]:hover::after {
            content: attr(title);
            position: absolute;
            bottom: 100%;
            left: 50%;
            transform: translateX(-50%) translateY(-5px);
            padding: 5px 10px;
            background: var(--dark);
            color: white;
            font-size: 11px;
            border-radius: 4px;
            white-space: nowrap;
            z-index: 1000;
        }

        .bottom-nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 25px;
        }

        .nav-btn {
            padding: 12px 24px;
            border-radius: 8px;
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
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            box-shadow: 0 4px 10px rgba(0, 119, 182, 0.3);
        }

        .nav-btn.primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(0, 119, 182, 0.4);
        }

        .nav-btn.secondary {
            background: var(--light-bg);
            color: var(--dark);
            border: 1px solid #e9ecef;
        }

        .nav-btn.secondary:hover {
            background: #e9ecef;
        }

        .nav-right {
            display: flex;
            gap: 10px;
        }

        .export-btn {
            background: linear-gradient(135deg, #28a745, #20c997);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 4px 10px rgba(40, 167, 69, 0.3);
        }

        .export-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(40, 167, 69, 0.4);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }

        .empty-state i {
            font-size: 48px;
            color: #ccc;
            margin-bottom: 15px;
        }

        .empty-state h3 {
            color: var(--dark);
            font-size: 20px;
            margin-bottom: 10px;
            font-weight: 500;
        }

        .create-first-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 25px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 500;
            transition: all 0.2s;
        }

        #noResultsRow td {
            text-align: center;
            padding: 50px;
        }

        .no-results-content {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 15px;
            color: #666;
        }

        .no-results-content i {
            font-size: 36px;
            color: #ccc;
        }

        .no-results-content h3 {
            color: var(--dark);
            font-size: 18px;
            font-weight: 500;
        }

        .clear-filters-btn {
            padding: 8px 20px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.2s;
        }

        .clear-filters-btn:hover {
            background: var(--secondary);
        }

        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .alert-danger {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        @media (max-width: 1400px) {
            .stats-row {
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
            
            .user-details {
                display: none;
            }
            
            .container {
                margin: 20px auto;
            }
            
            .page-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
                padding: 20px;
            }
            
            .stats-row {
                grid-template-columns: 1fr;
            }
            
            .filter-section {
                flex-direction: column;
                align-items: stretch;
                padding: 20px;
            }
            
            .search-box {
                min-width: 100%;
            }
            
            .bottom-nav {
                flex-direction: column;
                gap: 15px;
                align-items: stretch;
            }
            
            .nav-right {
                flex-direction: column;
            }
            
            .actions {
                flex-direction: column;
                align-items: flex-start;
            }
        }

        @media (max-width: 480px) {
            .filter-buttons {
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
                <p>Reservation System</p>
            </div>
        </div>
        
        <div class="user-section">
            <div class="user-info">
                <div class="user-details">
                    <div class="user-name">admin</div>
                </div>
                <div class="user-avatar">
                    A
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
                    <i class="fas fa-list-alt"></i>
                    Reservations
                </h1>
                <p>
                    <i class="fas fa-sun"></i>
                    Manage all bookings
                </p>
            </div>
            <div class="header-right">
                <a href="addReservation.jsp" class="header-btn">
                    <i class="fas fa-plus-circle"></i> New
                </a>
                <a href="billing.jsp" class="header-btn" style="background: rgba(255,255,255,0.3);">
                    <i class="fas fa-file-invoice-dollar"></i> Billing Center
                </a>
                <button onclick="exportToExcel()" class="header-btn">
                    <i class="fas fa-file-excel"></i> Export
                </button>
            </div>
        </div>

        <!-- ============ STATS ROW ============ -->
        <div class="stats-row">
            <div class="stat-card" onclick="filterByStat('all')">
                <div class="stat-icon">
                    <i class="fas fa-calendar-check"></i>
                </div>
                <div class="stat-content">
                    <h3><%= reservations.size() %></h3>
                    <p>Total Reservations</p>
                </div>
            </div>
            
            <div class="stat-card" onclick="filterByStat('assigned')">
                <div class="stat-icon">
                    <i class="fas fa-door-closed"></i>
                </div>
                <div class="stat-content">
                    <h3><%= roomsAssigned %></h3>
                    <p>Rooms Assigned</p>
                </div>
            </div>
            
            <div class="stat-card" onclick="filterByStat('active')">
                <div class="stat-icon" style="background: linear-gradient(135deg, #28a745, #20c997);">
                    <i class="fas fa-sun"></i>
                </div>
                <div class="stat-content">
                    <h3><%= activeCount %></h3>
                    <p>Need Bill</p>
                </div>
            </div>
            
            <div class="stat-card" onclick="filterByStat('ready')">
                <div class="stat-icon" style="background: linear-gradient(135deg, #ff9800, #ffb74d);">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="stat-content">
                    <h3><%= readyCount %></h3>
                    <p>Ready</p>
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
                <button class="filter-btn" data-filter="upcoming"><i class="fas fa-clock"></i> Upcoming</button>
                <button class="filter-btn" data-filter="active"><i class="fas fa-sun"></i> Need Bill</button>
                <button class="filter-btn" data-filter="ready"><i class="fas fa-check-circle"></i> Ready</button>
                <button class="filter-btn" data-filter="completed"><i class="fas fa-check-double"></i> Completed</button>
                <button class="filter-btn" data-filter="assigned"><i class="fas fa-door-closed"></i> Assigned</button>
                <button class="filter-btn" data-filter="unassigned"><i class="fas fa-question-circle"></i> No Room</button>
            </div>
        </div>

        <!-- ============ TABLE CONTAINER ============ -->
        <div class="table-container">
            <% if (reservations.isEmpty()) { %>
                <div class="empty-state">
                    <i class="fas fa-calendar-times"></i>
                    <h3>No Reservations Found</h3>
                    <p>There are no reservations in the system yet.</p>
                    <a href="addReservation.jsp" class="create-first-btn">
                        <i class="fas fa-plus-circle"></i> Create First Reservation
                    </a>
                </div>
            <% } else { %>
                <table id="reservationsTable">
                    <thead>
                        <tr>
                            <th>Reservation #</th>
                            <th>Guest Information</th>
                            <th>Room Type</th>
                            <th>Room No</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                            for (Reservation r : reservations) { 
                            
                            boolean hasBill = billsGenerated.containsKey(r.getReservationNumber());
                            boolean hasCheckedOut = checkOuts.containsKey(r.getReservationNumber());
                            LocalDate actualCheckOut = checkOuts.get(r.getReservationNumber());
                            
                            // Check if this reservation is due today (check-out today) and no bill
                            boolean isDueTodayNoBill = r.getCheckOut().equals(today) && !hasBill && !hasCheckedOut;
                            
                            // ============ CONSISTENT STATUS LOGIC ============
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
                            else {
                                // Current stay
                                if (hasBill) {
                                    status = "READY";
                                    statusClass = "status-ready";
                                    statusIcon = "check-circle";
                                    filterStatus = "ready";
                                } else {
                                    status = "ACTIVE";
                                    statusClass = "status-active";
                                    statusIcon = "sun";
                                    filterStatus = "active";
                                }
                            }
                            
                            // Determine room badge class
                            String roomBadgeClass = "room-badge ";
                            if (r.getRoomType() != null) {
                                if (r.getRoomType().equalsIgnoreCase("Standard")) {
                                    roomBadgeClass += "room-standard";
                                } else if (r.getRoomType().equalsIgnoreCase("Deluxe")) {
                                    roomBadgeClass += "room-deluxe";
                                } else if (r.getRoomType().equalsIgnoreCase("Suite")) {
                                    roomBadgeClass += "room-suite";
                                }
                            }
                            
                            String roomNumber = r.getRoomNumber();
                            boolean isEarlyCheckOut = actualCheckOut != null && actualCheckOut.isBefore(r.getCheckOut());
                            boolean isLateCheckOut = actualCheckOut != null && actualCheckOut.isAfter(r.getCheckOut());
                        %>
                        <tr data-status="<%= filterStatus %>" 
                            data-room-assigned="<%= (roomNumber != null && !roomNumber.isEmpty()) ? "assigned" : "unassigned" %>"
                            <%= isDueTodayNoBill ? "class='due-today-highlight'" : "" %>>
                            
                            <!-- Reservation Number -->
                            <td>
                                <span class="reservation-number">
                                    <i class="fas fa-hashtag"></i> <%= r.getReservationNumber() %>
                                </span>
                                <% if (hasBill) { %>
                                    <span class="bill-indicator" title="Bill generated">
                                        <i class="fas fa-check-circle"></i> Billed
                                    </span>
                                <% } %>
                            </td>
                            
                            <!-- Guest Information -->
                            <td>
                                <span class="guest-name">
                                    <i class="fas fa-user-circle"></i> <%= r.getGuestName() != null ? r.getGuestName() : "N/A" %>
                                    <% if (isDueTodayNoBill) { %>
                                        <span class="due-today-badge" title="Checking out today - bill needed">
                                            <i class="fas fa-exclamation-circle"></i> DUE TODAY
                                        </span>
                                    <% } %>
                                </span>
                                <span class="guest-contact">
                                    <i class="fas fa-phone-alt"></i> <%= r.getContactNumber() != null ? r.getContactNumber() : "N/A" %>
                                </span>
                                <span class="date-range">
                                    <i class="fas fa-calendar-alt"></i> 
                                    <%= r.getCheckIn() != null ? r.getCheckIn().format(DateTimeFormatter.ofPattern("dd MMM")) : "N/A" %> 
                                    <i class="fas fa-arrow-right" style="margin: 0 2px;"></i>
                                    <%= r.getCheckOut() != null ? r.getCheckOut().format(DateTimeFormatter.ofPattern("dd MMM")) : "N/A" %>
                                    <% if (r.getCheckOut() != null && r.getCheckOut().equals(today)) { %>
                                        <span style="color: #fd7e14; font-weight: 600; margin-left: 5px;">(Today)</span>
                                    <% } %>
                                </span>
                                
                                <!-- Show actual checkout if available -->
                                <% if (hasCheckedOut && actualCheckOut != null) { %>
                                    <div class="checkout-info">
                                        <i class="fas fa-sign-out-alt"></i> 
                                        Left: <%= actualCheckOut.format(DateTimeFormatter.ofPattern("dd MMM")) %>
                                        <% if (isEarlyCheckOut) { %>
                                            <span class="early-checkout" title="Early check-out">
                                                <i class="fas fa-forward"></i> Early
                                            </span>
                                        <% } else if (isLateCheckOut) { %>
                                            <span class="late-checkout" title="Late check-out">
                                                <i class="fas fa-backward"></i> Late
                                            </span>
                                        <% } %>
                                    </div>
                                <% } %>
                            </td>
                            
                            <!-- Room Type -->
                            <td>
                                <span class="<%= roomBadgeClass %>">
                                    <i class="fas fa-bed"></i> <%= r.getRoomType() != null ? r.getRoomType() : "N/A" %>
                                </span>
                            </td>
                            
                            <!-- Room Number -->
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
                            </td>
                            
                            <!-- Status -->
                            <td>
                                <span class="status-badge <%= statusClass %>">
                                    <i class="fas fa-<%= statusIcon %>"></i>
                                    <%= status %>
                                </span>
                            </td>
                            
                            <!-- Actions - Pure Reservation Management -->
                            <td>
                                <div class="actions">
                                    <!-- View Details -->
                                    <a href="view-reservation?number=<%= r.getReservationNumber() %>" 
                                       class="action-btn btn-view" 
                                       title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                    
                                    <!-- Edit - Only if not completed -->
                                    <% if (!"COMPLETED".equals(status)) { %>
                                        <a href="edit-reservation?number=<%= r.getReservationNumber() %>" 
                                           class="action-btn btn-edit" 
                                           title="Edit Reservation">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                    <% } %>
                                    
                                    <!-- Quick link to Billing Center - Now links to specific reservation in billing.jsp -->
                                    <a href="billing.jsp?searchType=reservation&searchValue=<%= r.getReservationNumber() %>" 
                                       class="action-btn btn-billing-link" 
                                       title="Go to Billing Center for this reservation">
                                        <i class="fas fa-file-invoice-dollar"></i>
                                    </a>
                                    
                                    <!-- Delete -->
                                    <button onclick="deleteReservation('<%= r.getReservationNumber() %>', '<%= r.getGuestName() %>', event)" 
                                            class="action-btn btn-delete" 
                                            title="Delete Reservation">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
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
                <a href="addReservation.jsp" class="nav-btn primary">
                    <i class="fas fa-plus-circle"></i> New Reservation
                </a>
                <a href="billing.jsp" class="nav-btn primary" style="background: linear-gradient(135deg, #17a2b8, #20c997);">
                    <i class="fas fa-file-invoice-dollar"></i> Billing Center
                </a>
                <button onclick="exportToExcel()" class="export-btn">
                    <i class="fas fa-file-excel"></i> Export Excel
                </button>
            </div>
        </div>
    </div>

    <script>
        // ============ DELETE FUNCTION ONLY ============
        
        function deleteReservation(reservationNumber, guestName, event) {
            if (event) {
                event.preventDefault();
                event.stopPropagation();
            }
            
            if (confirm('Delete reservation ' + reservationNumber + ' for ' + guestName + '?\n\nThis action cannot be undone!')) {
                window.location.href = 'delete-reservation?number=' + encodeURIComponent(reservationNumber);
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
            const rows = document.querySelectorAll('#reservationsTable tbody tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const rowText = row.textContent.toLowerCase();
                const rowStatus = row.getAttribute('data-status');
                
                let show = true;
                
                // Apply search filter
                if (searchTerm && searchTerm !== '') {
                    if (!rowText.includes(searchTerm)) show = false;
                }
                
                // Apply status filter
                if (show && filterType !== 'all') {
                    switch(filterType) {
                        case 'upcoming':
                            show = (rowStatus === 'upcoming');
                            break;
                        case 'active':
                            show = (rowStatus === 'active');
                            break;
                        case 'ready':
                            show = (rowStatus === 'ready');
                            break;
                        case 'completed':
                            show = (rowStatus === 'completed');
                            break;
                        case 'assigned':
                            show = !row.cells[3].textContent.includes('Not Assigned');
                            break;
                        case 'unassigned':
                            show = row.cells[3].textContent.includes('Not Assigned');
                            break;
                    }
                }
                
                row.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });
            
            updateNoResultsMessage(visibleCount);
        }

        function updateNoResultsMessage(visibleCount) {
            const tableBody = document.querySelector('#reservationsTable tbody');
            let noResultsRow = document.getElementById('noResultsRow');
            
            if (visibleCount === 0 && !noResultsRow && document.querySelector('#reservationsTable tbody tr')) {
                noResultsRow = document.createElement('tr');
                noResultsRow.id = 'noResultsRow';
                noResultsRow.innerHTML = '<td colspan="6"><div class="no-results-content">' +
                    '<i class="fas fa-search"></i>' +
                    '<h3>No reservations found</h3>' +
                    '<button onclick="clearFilters()" class="clear-filters-btn">Clear Filters</button>' +
                    '</div></td>';
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

        // ============ EXPORT FUNCTION ============

        function exportToExcel() {
            const visibleRows = document.querySelectorAll('#reservationsTable tbody tr:not([style*="display: none"])');
            if (visibleRows.length === 0) {
                alert('No data to export.');
                return;
            }
            
            const today = new Date();
            const fileName = 'reservations_' + today.getFullYear() + '-' + 
                           String(today.getMonth() + 1).padStart(2, '0') + '-' + 
                           String(today.getDate()).padStart(2, '0') + '.csv';
            
            let csvContent = 'data:text/csv;charset=utf-8,';
            csvContent += ['Reservation #','Guest Name','Contact','Room Type','Room No','Status'].join(',') + '\r\n';
            
            visibleRows.forEach(row => {
                const rowData = [];
                for (let i = 0; i < 6; i++) {
                    let text = row.cells[i].textContent.trim().replace(/\n/g, ' ').replace(/\s+/g, ' ');
                    rowData.push('"' + text + '"');
                }
                csvContent += rowData.join(',') + '\r\n';
            });
            
            const link = document.createElement('a');
            link.setAttribute('href', encodeURI(csvContent));
            link.setAttribute('download', fileName);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // ============ ROW CLICK HANDLER ============

        document.querySelectorAll('#reservationsTable tbody tr').forEach(row => {
            row.addEventListener('click', function(e) {
                if (!e.target.closest('.action-btn') && !e.target.closest('button')) {
                    const reservationNumCell = this.querySelector('.reservation-number');
                    if (reservationNumCell) {
                        const reservationNum = reservationNumCell.textContent.replace(/[^A-Z0-9-]/gi, '');
                        if (reservationNum) {
                            window.location.href = 'view-reservation?number=' + encodeURIComponent(reservationNum);
                        }
                    }
                }
            });
        });

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