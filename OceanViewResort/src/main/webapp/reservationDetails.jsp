<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.Reservation, java.time.format.DateTimeFormatter, java.time.LocalDate, java.text.NumberFormat, java.util.Locale, java.util.Map" %>

<%
    Reservation reservation = (Reservation) request.getAttribute("reservation");
    Long nights = (Long) request.getAttribute("nights");
    Boolean hasBill = (Boolean) request.getAttribute("hasBill");
    Boolean hasCheckedOut = (Boolean) request.getAttribute("hasCheckedOut");
    
    if (hasBill == null) hasBill = false;
    if (hasCheckedOut == null) hasCheckedOut = false;
    
    // Debug
    System.out.println("=== RESERVATION DETAILS JSP ===");
    System.out.println("Reservation object: " + reservation);
    
    if (reservation == null) {
        System.out.println("❌ Reservation is null in JSP!");
        response.sendRedirect("view-reservations");
        return;
    }
    
    System.out.println("Reservation Number: " + reservation.getReservationNumber());
    System.out.println("Has Bill: " + hasBill);
    System.out.println("Has Checked Out: " + hasCheckedOut);
    
    // Check session
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy");
    DateTimeFormatter shortDateFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy");
    String username = (String) userSession.getAttribute("username");
    
    // Calculate status with bill and check-out consideration
    LocalDate today = LocalDate.now();
    String currentStatus;
    String statusColor;
    String statusBgColor;
    String statusIcon;
    
    if (hasCheckedOut) {
        // Guest has physically left
        currentStatus = "COMPLETED";
        statusColor = "#383d41";
        statusBgColor = "#e2e3e5";
        statusIcon = "fa-check-double";
    } 
    else if (today.isBefore(reservation.getCheckIn())) {
        // Future booking
        currentStatus = "UPCOMING";
        statusColor = "#856404";
        statusBgColor = "#fff3cd";
        statusIcon = "fa-clock";
    } 
    else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) {
        // Current stay (including check-out day)
        if (hasBill) {
            currentStatus = "READY TO CHECK-OUT";
            statusColor = "#e65100";
            statusBgColor = "#fff3e0";
            statusIcon = "fa-check-circle";
        } else {
            currentStatus = "ACTIVE";
            statusColor = "#155724";
            statusBgColor = "#d4edda";
            statusIcon = "fa-sun";
        }
    } 
    else {
        // Past check-out date
        if (hasBill) {
            currentStatus = "COMPLETED";
            statusColor = "#383d41";
            statusBgColor = "#e2e3e5";
            statusIcon = "fa-check-double";
        } else {
            currentStatus = "OVERDUE";
            statusColor = "#721c24";
            statusBgColor = "#f8d7da";
            statusIcon = "fa-exclamation-triangle";
        }
    }
    
    // Format currency
    NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(new Locale("en", "LK"));
    String roomRateFormatted = currencyFormat.format(reservation.getRoomRate());
    String totalAmountFormatted = currencyFormat.format(reservation.getTotalAmount());
    
    // Calculate days
    long daysUntilCheckin = 0;
    long daysStayed = 0;
    long daysRemaining = 0;
    
    if (today.isBefore(reservation.getCheckIn())) {
        daysUntilCheckin = java.time.temporal.ChronoUnit.DAYS.between(today, reservation.getCheckIn());
    } else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) {
        daysStayed = java.time.temporal.ChronoUnit.DAYS.between(reservation.getCheckIn(), today);
        daysRemaining = java.time.temporal.ChronoUnit.DAYS.between(today, reservation.getCheckOut());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reservation <%= reservation.getReservationNumber() %> - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
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
            --purple: #6f42c1;
            --orange: #fd7e14;
            --shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
            --border-radius: 10px;
        }

        /* ============ TOP NAVIGATION (ORIGINAL ALIGNMENT) ============ */
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
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }

        /* ============ PAGE HEADER ============ */
        .page-header {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            padding: 25px 30px;
            border-radius: var(--border-radius);
            margin-bottom: 25px;
            box-shadow: var(--shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }

        .header-left h1 {
            font-size: 26px;
            font-weight: 600;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .header-left h1 i {
            opacity: 0.9;
        }

        .header-left p {
            font-size: 15px;
            opacity: 0.9;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .status-badge {
            padding: 10px 20px;
            border-radius: 40px;
            font-size: 15px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
            background: <%= statusBgColor %>;
            color: <%= statusColor %>;
            border: 1px solid <%= statusColor %>20;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        /* ============ MAIN LAYOUT WITH SIDEBAR ============ */
        .main-layout {
            display: flex;
            gap: 25px;
        }

        /* ============ VERTICAL QUICK ACTIONS SIDEBAR ============ */
        .quick-actions-sidebar {
            width: 200px;
            flex-shrink: 0;
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            padding: 20px 0;
            border: 1px solid #e9ecef;
            align-self: flex-start;
            position: sticky;
            top: 100px;
        }

        .quick-actions-header {
            padding: 0 20px 15px 20px;
            border-bottom: 2px solid #f0f0f0;
            margin-bottom: 15px;
        }

        .quick-actions-header h3 {
            font-size: 16px;
            font-weight: 600;
            color: var(--dark);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .quick-actions-header h3 i {
            color: var(--primary);
            font-size: 18px;
        }

        .quick-actions-header p {
            font-size: 12px;
            color: #888;
            margin-top: 5px;
        }

        .quick-actions-vertical {
            display: flex;
            flex-direction: column;
            gap: 5px;
            padding: 0 10px;
        }

        .quick-action-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 15px;
            border-radius: 8px;
            transition: all 0.2s;
            cursor: pointer;
            text-decoration: none;
            color: var(--dark);
            border: none;
            background: transparent;
            width: 100%;
            text-align: left;
            font-size: 14px;
        }

        .quick-action-item:hover {
            background: var(--light-bg);
            transform: translateX(5px);
        }

        .quick-action-item.disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
            background: #f5f5f5;
        }

        .quick-action-item.disabled:hover {
            transform: none;
            background: #f5f5f5;
        }

        /* Colorful vertical action icons */
        .quick-action-item:nth-child(1) .quick-action-icon { color: var(--primary); }
        .quick-action-item:nth-child(2) .quick-action-icon { color: #28a745; }
        .quick-action-item:nth-child(3) .quick-action-icon { color: #17a2b8; }
        .quick-action-item:nth-child(4) .quick-action-icon { color: #dc3545; }
        .quick-action-item:nth-child(5) .quick-action-icon { color: #6c757d; }
        .quick-action-item:nth-child(6) .quick-action-icon { color: #fd7e14; }

        .quick-action-icon {
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }

        .quick-action-text {
            flex: 1;
        }

        .quick-action-text h4 {
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 2px;
        }

        .quick-action-text p {
            font-size: 11px;
            color: #888;
        }

        /* Divider in sidebar */
        .sidebar-divider {
            height: 1px;
            background: #e9ecef;
            margin: 15px 20px;
        }

        /* Shortcut hints in sidebar */
        .sidebar-shortcuts {
            padding: 15px 20px 5px 20px;
            font-size: 11px;
            color: #888;
        }

        .sidebar-shortcut-item {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 10px;
        }

        .sidebar-shortcut-item kbd {
            background: var(--dark);
            color: white;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 10px;
            font-family: monospace;
        }

        /* ============ MAIN CONTENT AREA ============ */
        .main-content {
            flex: 1;
            min-width: 0;
        }

        /* ============ DATES CARD ============ */
        .dates-card {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 25px;
        }

        .dates-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0;
        }

        .date-block {
            padding: 25px;
            text-align: center;
            border-right: 1px solid #f1f3f5;
        }

        .date-block:last-child {
            border-right: none;
        }

        .date-icon {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            font-size: 22px;
        }

        .checkin-icon {
            background: #e8f5e9;
            color: var(--success);
        }

        .stay-icon {
            background: #e3f2fd;
            color: var(--primary);
        }

        .checkout-icon {
            background: #ffebee;
            color: var(--danger);
        }

        .date-label {
            font-size: 14px;
            color: #666;
            margin-bottom: 5px;
        }

        .date-value {
            font-size: 18px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 5px;
        }

        .date-sub {
            font-size: 13px;
            color: #888;
        }

        /* ============ CONTENT GRID ============ */
        .content-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 25px;
            margin-bottom: 25px;
        }

        /* ============ INFO CARDS ============ */
        .info-card {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            transition: all 0.2s;
        }

        .info-card:hover {
            box-shadow: 0 8px 20px rgba(0,119,182,0.15);
        }

        .card-header {
            background: linear-gradient(135deg, #f8f9fa, #ffffff);
            padding: 18px 22px;
            border-bottom: 1px solid #e9ecef;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-header i {
            color: var(--primary);
            font-size: 20px;
        }

        .card-header h2 {
            font-size: 18px;
            font-weight: 600;
            color: var(--dark);
        }

        .card-body {
            padding: 22px;
        }

        /* ============ INFO ROWS ============ */
        .info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #f1f3f5;
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .info-label {
            color: #666;
            font-size: 14px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Colorful icons in info rows - keeping blue theme */
        .info-row:nth-child(1) .info-label i { color: var(--primary); }
        .info-row:nth-child(2) .info-label i { color: #ffc107; }
        .info-row:nth-child(3) .info-label i { color: #28a745; }
        .info-row:nth-child(4) .info-label i { color: #17a2b8; }
        .info-row:nth-child(5) .info-label i { color: #6f42c1; }

        .info-value {
            color: var(--dark);
            font-weight: 600;
            font-size: 15px;
        }

        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 30px;
            font-size: 12px;
            font-weight: 600;
        }

        .badge-primary {
            background: #e3f2fd;
            color: #1565c0;
        }

        .badge-success {
            background: #d4edda;
            color: #155724;
        }

        .badge-warning {
            background: #fff3cd;
            color: #856404;
        }

        .badge-secondary {
            background: #e2e3e5;
            color: #383d41;
        }

        .badge-ready {
            background: #fff3e0;
            color: #e65100;
        }

        .badge-overdue {
            background: #f8d7da;
            color: #721c24;
            animation: gentle-pulse 2s infinite;
        }

        @keyframes gentle-pulse {
            0% { opacity: 1; }
            50% { opacity: 0.9; box-shadow: 0 0 5px rgba(220,53,69,0.3); }
            100% { opacity: 1; }
        }

        .room-number-badge {
            background: #e8f4fd;
            color: var(--primary);
            padding: 5px 15px;
            border-radius: 30px;
            font-weight: 600;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        /* ============ FINANCIAL CARD ============ */
        .financial-card {
            background: linear-gradient(135deg, #f8f9fa, #ffffff);
            border-radius: var(--border-radius);
            padding: 22px;
            box-shadow: var(--shadow);
        }

        .financial-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px dashed #e9ecef;
            font-size: 15px;
        }

        /* Colorful financial row icons */
        .financial-row:nth-child(1) i { color: var(--primary); }
        .financial-row:nth-child(2) i { color: #28a745; }
        .financial-row:nth-child(3) i { color: #17a2b8; }
        .financial-row:nth-child(4) i { color: #6f42c1; }

        .financial-total {
            display: flex;
            justify-content: space-between;
            padding: 15px 0 0;
            margin-top: 10px;
            border-top: 2px solid var(--primary);
            font-weight: 700;
            font-size: 18px;
            color: var(--dark);
        }

        /* ============ STATS GRID ============ */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-top: 15px;
        }

        .stat-item {
            background: var(--light-bg);
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            border-top: 3px solid transparent;
        }

        .stat-item:nth-child(1) { border-top-color: var(--primary); }
        .stat-item:nth-child(2) { border-top-color: #28a745; }
        .stat-item:nth-child(3) { border-top-color: #fd7e14; }

        .stat-number {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 5px;
        }

        .stat-item:nth-child(1) .stat-number { color: var(--primary); }
        .stat-item:nth-child(2) .stat-number { color: #28a745; }
        .stat-item:nth-child(3) .stat-number { color: #fd7e14; }

        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        /* ============ BILL INFO BADGE ============ */
        .bill-info-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background: var(--primary);
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            margin-left: 10px;
        }

        /* ============ FOOTER ============ */
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px 0;
            color: #666;
            font-size: 13px;
            border-top: 1px solid #e9ecef;
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 992px) {
            .main-layout {
                flex-direction: column;
            }
            
            .quick-actions-sidebar {
                width: 100%;
                position: static;
                margin-bottom: 20px;
            }
            
            .quick-actions-vertical {
                flex-direction: row;
                flex-wrap: wrap;
            }
            
            .quick-action-item {
                width: calc(33.333% - 10px);
            }
            
            .content-grid {
                grid-template-columns: 1fr;
            }
            
            .dates-grid {
                grid-template-columns: 1fr;
            }
            
            .date-block {
                border-right: none;
                border-bottom: 1px solid #f1f3f5;
            }
            
            .date-block:last-child {
                border-bottom: none;
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
            
            .page-header {
                flex-direction: column;
                gap: 15px;
                align-items: flex-start;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .quick-action-item {
                width: 100%;
            }
        }

        /* Print styles */
        @media print {
            .top-nav, .quick-actions-sidebar, .footer, .logout-btn, .status-badge {
                display: none;
            }
            
            body {
                background: white;
            }
            
            .container {
                margin: 0;
                padding: 0;
            }
            
            .page-header {
                background: #f8f9fa !important;
                color: black !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
</head>
<body>

    <!-- ============ TOP NAVIGATION (ORIGINAL ALIGNMENT) ============ -->
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
                </div>
                <div class="user-avatar">
                    <%= username.substring(0, 1).toUpperCase() %>
                </div>
            </div>
            <a href="logout" class="logout-btn">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </div>
    </nav>

    <div class="container">
        
        <!-- ============ PAGE HEADER ============ -->
        <div class="page-header">
            <div class="header-left">
                <h1>
                    <i class="fas fa-file-alt"></i>
                    Reservation Details
                </h1>
                <p>
                    <i class="fas fa-hashtag"></i> <%= reservation.getReservationNumber() %>
                    <i class="fas fa-user" style="margin-left: 15px;"></i> <%= reservation.getGuestName() %>
                    <% if (hasBill) { %>
                        <span class="bill-info-badge">
                            <i class="fas fa-file-invoice"></i> Bill Generated
                        </span>
                    <% } %>
                </p>
            </div>
            <div class="status-badge">
                <i class="fas <%= statusIcon %>"></i>
                <%= currentStatus %>
            </div>
        </div>

        <!-- ============ MAIN LAYOUT WITH SIDEBAR ============ -->
        <div class="main-layout">
            
            <!-- ============ VERTICAL QUICK ACTIONS SIDEBAR (LEFT SIDE) ============ -->
            <aside class="quick-actions-sidebar">
                <div class="quick-actions-header">
                    <h3>
                        <i class="fas fa-bolt"></i>
                        Quick Actions
                    </h3>
                    <p>Reservation #<%= reservation.getReservationNumber() %></p>
                </div>
                
                <div class="quick-actions-vertical">
                    <!-- Edit Reservation - DISABLED for completed -->
                    <% if ("COMPLETED".equals(currentStatus)) { %>
                        <div class="quick-action-item disabled" title="Cannot edit completed reservations">
                            <span class="quick-action-icon"><i class="fas fa-edit"></i></span>
                            <span class="quick-action-text">
                                <h4>Edit</h4>
                                <p>Modify details</p>
                            </span>
                        </div>
                    <% } else { %>
                        <a href="edit-reservation?number=<%= reservation.getReservationNumber() %>" class="quick-action-item">
                            <span class="quick-action-icon"><i class="fas fa-edit"></i></span>
                            <span class="quick-action-text">
                                <h4>Edit</h4>
                                <p>Modify details</p>
                            </span>
                        </a>
                    <% } %>
                    
                    <!-- View Bill - Only if bill exists -->
                    <% if (hasBill) { %>
                        <a href="generate-bill?number=<%= reservation.getReservationNumber() %>" class="quick-action-item">
                            <span class="quick-action-icon"><i class="fas fa-file-invoice"></i></span>
                            <span class="quick-action-text">
                                <h4>View Bill</h4>
                                <p>See invoice</p>
                            </span>
                        </a>
                    <% } else { %>
                        <!-- Generate Bill - Only if not completed and no bill -->
                        <% if (!"COMPLETED".equals(currentStatus) && !"OVERDUE".equals(currentStatus)) { %>
                            <a href="generate-bill?number=<%= reservation.getReservationNumber() %>" class="quick-action-item">
                                <span class="quick-action-icon"><i class="fas fa-file-invoice-dollar"></i></span>
                                <span class="quick-action-text">
                                    <h4>Generate Bill</h4>
                                    <p>Create invoice</p>
                                </span>
                            </a>
                        <% } %>
                    <% } %>
                    
                    <!-- Print Details -->
                    <button onclick="window.print()" class="quick-action-item" style="border: none; background: transparent;">
                        <span class="quick-action-icon"><i class="fas fa-print"></i></span>
                        <span class="quick-action-text">
                            <h4>Print</h4>
                            <p>Print summary</p>
                        </span>
                    </button>
                    
                    <!-- Delete Reservation -->
                    <button onclick="deleteReservation('<%= reservation.getReservationNumber() %>')" class="quick-action-item" style="border: none; background: transparent;">
                        <span class="quick-action-icon"><i class="fas fa-trash-alt"></i></span>
                        <span class="quick-action-text">
                            <h4>Delete</h4>
                            <p>Remove permanently</p>
                        </span>
                    </button>
                    
                    <!-- Back to List -->
                    <a href="view-reservations" class="quick-action-item">
                        <span class="quick-action-icon"><i class="fas fa-arrow-left"></i></span>
                        <span class="quick-action-text">
                            <h4>Back</h4>
                            <p>To reservations list</p>
                        </span>
                    </a>
                    
                    <!-- Dashboard -->
                    <a href="dashboard.jsp" class="quick-action-item">
                        <span class="quick-action-icon"><i class="fas fa-tachometer-alt"></i></span>
                        <span class="quick-action-text">
                            <h4>Dashboard</h4>
                            <p>Main overview</p>
                        </span>
                    </a>
                </div>

                <div class="sidebar-divider"></div>

                <div class="sidebar-shortcuts">
                    <div class="sidebar-shortcut-item">
                        <kbd>Esc</kbd>
                        <span>Back to list</span>
                    </div>
                    <div class="sidebar-shortcut-item">
                        <kbd>Ctrl</kbd>+<kbd>P</kbd>
                        <span>Print page</span>
                    </div>
                </div>
            </aside>

            <!-- ============ MAIN CONTENT AREA ============ -->
            <main class="main-content">
                
                <!-- ============ DATES SECTION ============ -->
                <div class="dates-card">
                    <div class="dates-grid">
                        <div class="date-block">
                            <div class="date-icon checkin-icon">
                                <i class="fas fa-sign-in-alt"></i>
                            </div>
                            <div class="date-label">Check-in</div>
                            <div class="date-value"><%= reservation.getCheckIn().format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %></div>
                            <div class="date-sub"><%= reservation.getCheckIn().format(DateTimeFormatter.ofPattern("EEEE")) %></div>
                        </div>
                        
                        <div class="date-block">
                            <div class="date-icon stay-icon">
                                <i class="fas fa-moon"></i>
                            </div>
                            <div class="date-label">Duration</div>
                            <div class="date-value"><%= nights %> Night<%= nights > 1 ? "s" : "" %></div>
                            <div class="date-sub">
                                <% if (today.isBefore(reservation.getCheckIn())) { %>
                                    Check-in in <%= daysUntilCheckin %> day<%= daysUntilCheckin > 1 ? "s" : "" %>
                                <% } else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) { %>
                                    Day <%= daysStayed + 1 %> of <%= nights %>
                                <% } else { %>
                                    Stay completed
                                <% } %>
                            </div>
                        </div>
                        
                        <div class="date-block">
                            <div class="date-icon checkout-icon">
                                <i class="fas fa-sign-out-alt"></i>
                            </div>
                            <div class="date-label">Check-out</div>
                            <div class="date-value"><%= reservation.getCheckOut().format(DateTimeFormatter.ofPattern("MMM dd, yyyy")) %></div>
                            <div class="date-sub"><%= reservation.getCheckOut().format(DateTimeFormatter.ofPattern("EEEE")) %></div>
                        </div>
                    </div>
                </div>

                <!-- ============ CONTENT GRID ============ -->
                <div class="content-grid">
                    
                    <!-- LEFT COLUMN - Reservation Info -->
                    <div class="info-card">
                        <div class="card-header">
                            <i class="fas fa-info-circle"></i>
                            <h2>Reservation Information</h2>
                        </div>
                        <div class="card-body">
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-hashtag"></i> Reservation #</span>
                                <span class="info-value"><%= reservation.getReservationNumber() %></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-tag"></i> Status</span>
                                <span class="badge 
                                    <%= "UPCOMING".equals(currentStatus) ? "badge-warning" : 
                                       "ACTIVE".equals(currentStatus) ? "badge-success" :
                                       "READY TO CHECK-OUT".equals(currentStatus) ? "badge-ready" :
                                       "OVERDUE".equals(currentStatus) ? "badge-overdue" : "badge-secondary" %>">
                                    <%= currentStatus %>
                                </span>
                            </div>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-bed"></i> Room Type</span>
                                <span class="badge badge-primary"><%= reservation.getRoomType() %></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-door-closed"></i> Room Number</span>
                                <span class="info-value">
                                    <% if (reservation.getRoomNumber() != null && !reservation.getRoomNumber().isEmpty()) { %>
                                        <span class="room-number-badge">
                                            <i class="fas fa-door-closed"></i> <%= reservation.getRoomNumber() %>
                                        </span>
                                    <% } else { %>
                                        <span style="color: #999; font-style: italic;">Not Assigned</span>
                                    <% } %>
                                </span>
                            </div>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-clock"></i> Booking Date</span>
                                <span class="info-value"><%= LocalDate.now().format(dateFormatter) %></span>
                            </div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN - Guest Information -->
                    <div class="info-card">
                        <div class="card-header">
                            <i class="fas fa-user-tie"></i>
                            <h2>Guest Information</h2>
                        </div>
                        <div class="card-body">
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-user-circle"></i> Full Name</span>
                                <span class="info-value"><%= reservation.getGuestName() %></span>
                            </div>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-phone-alt"></i> Contact Number</span>
                                <span class="info-value"><%= reservation.getContactNumber() %></span>
                            </div>
                            <% if (reservation.getAddress() != null && !reservation.getAddress().isEmpty()) { %>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-map-marker-alt"></i> Address</span>
                                <span class="info-value"><%= reservation.getAddress() %></span>
                            </div>
                            <% } %>
                            <div class="info-row">
                                <span class="info-label"><i class="fas fa-id-card"></i> Guest ID</span>
                                <span class="info-value">#<%= reservation.getGuestId() %></span>
                            </div>
                        </div>
                    </div>

                    <!-- LEFT COLUMN BOTTOM - Financial Summary -->
                    <div class="info-card">
                        <div class="card-header">
                            <i class="fas fa-money-bill-wave"></i>
                            <h2>Financial Summary</h2>
                        </div>
                        <div class="card-body">
                            <div class="financial-card">
                                <div class="financial-row">
                                    <span><i class="fas fa-tag" style="margin-right: 8px;"></i> Room Rate (per night)</span>
                                    <span><%= roomRateFormatted %></span>
                                </div>
                                <div class="financial-row">
                                    <span><i class="fas fa-moon" style="margin-right: 8px;"></i> Number of Nights</span>
                                    <span><%= nights %></span>
                                </div>
                                <div class="financial-row">
                                    <span><i class="fas fa-calculator" style="margin-right: 8px;"></i> Room Charges</span>
                                    <span><%= totalAmountFormatted %></span>
                                </div>
                                <div class="financial-row">
                                    <span><i class="fas fa-percent" style="margin-right: 8px;"></i> Tax (15% VAT)</span>
                                    <span><%= currencyFormat.format(reservation.getTotalAmount() * 0.15) %></span>
                                </div>
                                <div class="financial-total">
                                    <span><i class="fas fa-wallet" style="margin-right: 10px;"></i> Total Amount</span>
                                    <span><%= currencyFormat.format(reservation.getTotalAmount() * 1.15) %></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN BOTTOM - Stay Statistics -->
                    <div class="info-card">
                        <div class="card-header">
                            <i class="fas fa-chart-line"></i>
                            <h2>Stay Statistics</h2>
                        </div>
                        <div class="card-body">
                            <div class="stats-grid">
                                <div class="stat-item">
                                    <i class="fas fa-calendar-week" style="font-size: 20px; margin-bottom: 8px; color: var(--primary);"></i>
                                    <div class="stat-number"><%= nights %></div>
                                    <div class="stat-label">Total Nights</div>
                                </div>
                                <div class="stat-item">
                                    <i class="fas fa-clock" style="font-size: 20px; margin-bottom: 8px; color: #28a745;"></i>
                                    <div class="stat-number">
                                        <% if (today.isBefore(reservation.getCheckIn())) { %>
                                            <%= daysUntilCheckin %>
                                        <% } else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) { %>
                                            <%= daysStayed %>
                                        <% } else { %>
                                            <%= nights %>
                                        <% } %>
                                    </div>
                                    <div class="stat-label">
                                        <% if (today.isBefore(reservation.getCheckIn())) { %>
                                            Until Check-in
                                        <% } else if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) { %>
                                            Days Stayed
                                        <% } else { %>
                                            Completed
                                        <% } %>
                                    </div>
                                </div>
                                <div class="stat-item">
                                    <i class="fas fa-hourglass-half" style="font-size: 20px; margin-bottom: 8px; color: #fd7e14;"></i>
                                    <div class="stat-number">
                                        <% if (!today.isBefore(reservation.getCheckIn()) && !today.isAfter(reservation.getCheckOut())) { %>
                                            <%= daysRemaining %>
                                        <% } else { %>
                                            0
                                        <% } %>
                                    </div>
                                    <div class="stat-label">Days Left</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>

        <!-- ============ FOOTER ============ -->
        <div class="footer">
            <p>Ocean View Resort • Reservation #<%= reservation.getReservationNumber() %> • Viewed by: <%= username %> • <%= LocalDate.now().format(dateFormatter) %></p>
        </div>
    </div>
    
    <script>
    function deleteReservation(reservationNumber) {
        Swal.fire({
            title: 'Delete Reservation?',
            html: '<strong>#' + reservationNumber + '</strong> will be permanently deleted!<br><br>' +
                  '<span style="color: #dc3545;"><i class="fas fa-exclamation-triangle"></i> This action cannot be undone.</span>',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Yes, Delete',
            cancelButtonText: 'Cancel',
            width: 500
        }).then((result) => {
            if (result.isConfirmed) {
                Swal.fire({
                    title: 'Deleting...',
                    text: 'Please wait',
                    allowOutsideClick: false,
                    didOpen: () => {
                        Swal.showLoading();
                    }
                });
                window.location.href = 'delete-reservation?number=' + reservationNumber;
            }
        });
    }
    
    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // Escape key to go back
        if (e.key === 'Escape') {
            window.location.href = 'view-reservations';
        }
        // Ctrl+P to print
        if (e.ctrlKey && e.key === 'p') {
            e.preventDefault();
            window.print();
        }
    });
    
    // Show success/error alerts from URL parameters
    window.onload = function() {
        <%
        String type = request.getParameter("type");
        String message = request.getParameter("message");
        
        if ("success".equals(type) && message != null) {
            String decodedMessage = java.net.URLDecoder.decode(message, "UTF-8").replace("'", "\\'");
        %>
            // Show success alert
            setTimeout(function() {
                alert("✅ Success!\n\n<%= decodedMessage %>");
            }, 300);
            
            // Clean URL
            const url = new URL(window.location);
            url.searchParams.delete('type');
            url.searchParams.delete('message');
            window.history.replaceState({}, document.title, url);
        <%
        } else if ("error".equals(type) && message != null) {
            String decodedMessage = java.net.URLDecoder.decode(message, "UTF-8").replace("'", "\\'");
        %>
            // Show error alert
            setTimeout(function() {
                alert("❌ Error!\n\n<%= decodedMessage %>");
            }, 300);
            
            // Clean URL
            const url = new URL(window.location);
            url.searchParams.delete('type');
            url.searchParams.delete('message');
            window.history.replaceState({}, document.title, url);
        <%
        }
        %>
    };
    </script>
</body>
</html>