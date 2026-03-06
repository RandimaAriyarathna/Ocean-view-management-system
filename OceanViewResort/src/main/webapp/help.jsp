<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is logged in
    javax.servlet.http.HttpSession userSession = request.getSession(false);
    if (userSession == null || userSession.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String user = (String) userSession.getAttribute("username");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Help & Support - Ocean View Resort</title>
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
            --purple: #6f42c1;
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

        /* ============ HERO SECTION ============ */
        .hero {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            padding: 35px 30px;
            border-radius: var(--border-radius);
            margin-bottom: 30px;
            box-shadow: var(--shadow);
            color: white;
        }

        .hero h1 {
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .hero h1 i {
            opacity: 0.9;
        }

        .hero p {
            color: rgba(255, 255, 255, 0.9);
            font-size: 16px;
            margin-bottom: 25px;
        }

        .search-box {
            max-width: 500px;
            position: relative;
        }

        .search-box input {
            width: 100%;
            padding: 14px 50px 14px 20px;
            border: none;
            border-radius: 40px;
            font-size: 15px;
            background: white;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }

        .search-box input:focus {
            outline: none;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
        }

        .search-box button {
            position: absolute;
            right: 8px;
            top: 50%;
            transform: translateY(-50%);
            background: var(--primary);
            color: white;
            border: none;
            width: 38px;
            height: 38px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }

        .search-box button:hover {
            background: var(--secondary);
            transform: translateY(-50%) scale(1.05);
        }

        .search-box button i {
            color: white;
            font-size: 14px;
        }

        /* ============ QUICK ACTIONS ============ */
        .quick-actions {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .quick-card {
            background: var(--white);
            padding: 25px 20px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid #e9ecef;
        }

        .quick-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 20px rgba(0, 119, 182, 0.15);
            border-color: var(--primary);
        }

        .quick-card i {
            font-size: 32px;
            color: var(--primary);
            margin-bottom: 15px;
        }

        .quick-card h3 {
            font-size: 16px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 8px;
        }

        .quick-card p {
            font-size: 13px;
            color: #666;
            line-height: 1.4;
        }

        /* ============ MAIN GRID ============ */
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 350px;
            gap: 25px;
            margin-bottom: 30px;
        }

        /* ============ GUIDES SECTION ============ */
        .guides-section {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            padding: 25px;
        }

        .section-title {
            font-size: 20px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 20px;
            padding-bottom: 12px;
            border-bottom: 2px solid #f0f0f0;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section-title i {
            color: var(--primary);
        }

        .guide-card {
            background: var(--light-bg);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            border-left: 4px solid var(--primary);
            transition: all 0.2s;
        }

        .guide-card:hover {
            box-shadow: 0 4px 12px rgba(0, 119, 182, 0.1);
        }

        .guide-card h3 {
            font-size: 16px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .guide-card p {
            font-size: 14px;
            color: #666;
            margin-bottom: 15px;
            line-height: 1.5;
        }

        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            background: var(--light-bg);
            border: 1px solid #e9ecef;
        }

        .badge-important {
            background: var(--danger);
            color: white;
            border-color: var(--danger);
        }

        .badge-updated {
            background: var(--warning);
            color: #333;
            border-color: var(--warning);
        }

        .steps {
            margin: 15px 0;
        }

        .step {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            margin-bottom: 10px;
            font-size: 14px;
            color: #495057;
        }

        .step-number {
            background: var(--primary);
            color: white;
            width: 22px;
            height: 22px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 600;
            flex-shrink: 0;
        }

        .step i {
            color: var(--primary);
            width: 18px;
            font-size: 13px;
        }

        .step strong {
            color: var(--dark);
        }

        .guide-note {
            font-size: 13px;
            color: #666;
            display: flex;
            align-items: center;
            gap: 6px;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px dashed #e9ecef;
        }

        .guide-note i {
            color: var(--primary);
        }

        /* ============ SHORTCUTS ============ */
        .shortcuts {
            background: linear-gradient(135deg, #f8f9fa, #ffffff);
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
            border: 1px solid #e9ecef;
        }

        .shortcuts h4 {
            font-size: 15px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .shortcuts h4 i {
            color: var(--primary);
        }

        .shortcut-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px dashed #e9ecef;
            font-size: 13px;
        }

        .shortcut-item:last-child {
            border-bottom: none;
        }

        .shortcut-key {
            background: var(--dark);
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-family: monospace;
        }

        /* ============ FAQ SECTION ============ */
        .faq-section {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            padding: 25px;
            margin-bottom: 25px;
        }

        .faq-item {
            border-bottom: 1px solid #e9ecef;
            margin-bottom: 15px;
            padding-bottom: 15px;
        }

        .faq-item:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
        }

        .faq-question {
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            color: var(--dark);
        }

        .faq-question i {
            color: var(--primary);
            font-size: 14px;
            transition: transform 0.2s;
        }

        .faq-answer {
            display: none;
            margin-top: 10px;
            font-size: 13px;
            color: #666;
            line-height: 1.6;
            padding-left: 15px;
            border-left: 3px solid var(--primary);
        }

        .faq-answer.show {
            display: block;
        }

        /* ============ CONTACT SECTION ============ */
        .contact-section {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            padding: 25px;
        }

        .contact-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            margin: 20px 0;
        }

        .contact-card {
            background: var(--light-bg);
            padding: 15px 12px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e9ecef;
            transition: all 0.2s;
        }

        .contact-card:hover {
            border-color: var(--primary);
            transform: translateY(-2px);
        }

        .contact-card i {
            color: var(--primary);
            font-size: 22px;
            margin-bottom: 8px;
        }

        .contact-card h3 {
            font-size: 13px;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 4px;
        }

        .contact-card p {
            font-size: 12px;
            color: #666;
        }

        .emergency {
            background: linear-gradient(135deg, #dc3545, #c82333);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
            text-align: center;
            box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
        }

        .emergency h3 {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .emergency h3 i {
            color: white;
        }

        .emergency p {
            font-size: 13px;
            opacity: 0.95;
            margin-bottom: 5px;
        }

        .emergency .phone {
            font-weight: 700;
            font-size: 16px;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid rgba(255, 255, 255, 0.3);
        }

        /* ============ FOOTER ============ */
        .footer {
            margin-top: 30px;
            padding: 20px 0;
            text-align: center;
            border-top: 1px solid #e9ecef;
            color: #666;
            font-size: 13px;
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
        @media (max-width: 1024px) {
            .quick-actions {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .main-grid {
                grid-template-columns: 1fr;
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
            
            .hero {
                padding: 25px 20px;
            }
            
            .hero h1 {
                font-size: 24px;
            }
            
            .quick-actions {
                grid-template-columns: 1fr;
                gap: 15px;
            }
            
            .contact-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 480px) {
            .search-box input {
                padding: 12px 45px 12px 15px;
                font-size: 14px;
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
                <p>Help & Support</p>
            </div>
        </div>
        
        <div class="user-section">
            <div class="user-info">
                <div class="user-details">
                    <div class="user-name"><%= user %></div>
                    <!-- REMOVED: <div class="user-badge">Staff</div> -->
                </div>
                <div class="user-avatar">
                    <%= user.substring(0, 1).toUpperCase() %>
                </div>
            </div>
            <a href="dashboard.jsp" class="logout-btn">
                <i class="fas fa-arrow-left"></i>
                <span>Dashboard</span>
            </a>
        </div>
    </nav>

    <!-- ============ MAIN CONTAINER ============ -->
    <div class="container">
        
        <!-- ============ HERO SECTION ============ -->
        <div class="hero">
            <h1>
                <i class="fas fa-headset"></i>
                Help & Support Center
            </h1>
            <p>Find guides, FAQs, and get support for the Reservation System</p>
            
            <div class="search-box">
                <input type="text" id="searchHelp" placeholder="Search for help topics...">
                <button onclick="searchHelp()">
                    <i class="fas fa-search"></i>
                </button>
            </div>
        </div>

        <!-- ============ QUICK ACTIONS ============ -->
        <div class="quick-actions">
            <div class="quick-card" onclick="scrollToSection('add-reservation')">
                <i class="fas fa-calendar-plus"></i>
                <h3>Add Reservation</h3>
                <p>Create new guest bookings with room assignments</p>
            </div>
            
            <div class="quick-card" onclick="scrollToSection('manage-reservations')">
                <i class="fas fa-list-alt"></i>
                <h3>Manage Reservations</h3>
                <p>View, search, edit, and delete bookings</p>
            </div>
            
            <div class="quick-card" onclick="scrollToSection('generate-bill')">
                <i class="fas fa-file-invoice-dollar"></i>
                <h3>Generate Bill</h3>
                <p>Create invoices with tax calculations</p>
            </div>
            
            <div class="quick-card" onclick="scrollToSection('room-assignment')">
                <i class="fas fa-door-closed"></i>
                <h3>Room Assignment</h3>
                <p>Assign and manage room allocations</p>
            </div>
        </div>

        <!-- ============ MAIN GRID ============ -->
        <div class="main-grid">
            <!-- LEFT: GUIDES SECTION -->
            <div class="guides-section">
                <h2 class="section-title">
                    <i class="fas fa-book-open"></i> Step-by-Step Guides
                </h2>

                <!-- Add Reservation Guide -->
                <div class="guide-card" id="add-reservation">
                    <h3>
                        How to Add a New Reservation
                        <span class="badge badge-important">IMPORTANT</span>
                    </h3>
                    <p>Complete guide to creating new guest reservations with room assignments.</p>
                    
                    <div class="steps">
                        <div class="step">
                            <span class="step-number">1</span>
                            <span>Navigate to <strong>Add Reservation</strong> from dashboard</span>
                        </div>
                        <div class="step">
                            <span class="step-number">2</span>
                            <span>Enter guest details: Name, Contact Number, Address</span>
                        </div>
                        <div class="step">
                            <span class="step-number">3</span>
                            <span>Select Room Type (Standard: Rs.25,600 | Deluxe: Rs.38,400 | Suite: Rs.64,000)</span>
                        </div>
                        <div class="step">
                            <span class="step-number">4</span>
                            <span>Choose check-in and check-out dates</span>
                        </div>
                        <div class="step">
                            <span class="step-number">5</span>
                            <span>Select a specific room or choose <strong>Auto-assign</strong></span>
                        </div>
                        <div class="step">
                            <span class="step-number">6</span>
                            <span>Review total and click <strong>Create Reservation</strong></span>
                        </div>
                    </div>
                    
                    <div class="guide-note">
                        <i class="fas fa-info-circle"></i>
                        <span>Reservation number is auto-generated. Contact number must be exactly 10 digits.</span>
                    </div>
                </div>

                <!-- Manage Reservations Guide -->
                <div class="guide-card" id="manage-reservations">
                    <h3>
                        Managing Reservations
                        <span class="badge badge-updated">UPDATED</span>
                    </h3>
                    <p>How to search, filter, edit, and delete reservations.</p>
                    
                    <div class="steps">
                        <div class="step">
                            <span class="step-number">1</span>
                            <span>Go to <strong>View Reservations</strong> to see all bookings</span>
                        </div>
                        <div class="step">
                            <span class="step-number">2</span>
                            <span>Use search bar to find by guest name, reservation #, or room number</span>
                        </div>
                        <div class="step">
                            <span class="step-number">3</span>
                            <span>Filter by status: Upcoming, Active, Completed, or Room Assignment</span>
                        </div>
                        <div class="step">
                            <span class="step-number">4</span>
                            <span>Click <i class="fas fa-eye"></i> to view full details</span>
                        </div>
                        <div class="step">
                            <span class="step-number">5</span>
                            <span>Click <i class="fas fa-edit"></i> to edit reservation (not available for completed)</span>
                        </div>
                        <div class="step">
                            <span class="step-number">6</span>
                            <span>Click <i class="fas fa-trash-alt"></i> to delete (requires confirmation)</span>
                        </div>
                    </div>
                    
                    <div class="guide-note">
                        <i class="fas fa-lightbulb"></i>
                        <span>Click anywhere on a table row to quickly view reservation details.</span>
                    </div>
                </div>

                <!-- Generate Bill Guide -->
                <div class="guide-card" id="generate-bill">
                    <h3>Generating Bills & Invoices</h3>
                    <p>Creating professional invoices for guest stays.</p>
                    
                    <div class="steps">
                        <div class="step">
                            <span class="step-number">1</span>
                            <span>From reservation list, click the <i class="fas fa-file-invoice-dollar"></i> bill icon</span>
                        </div>
                        <div class="step">
                            <span class="step-number">2</span>
                            <span>System automatically calculates: Room charges × Nights + 15% VAT</span>
                        </div>
                        <div class="step">
                            <span class="step-number">3</span>
                            <span>Review guest information, stay dates, and room details</span>
                        </div>
                        <div class="step">
                            <span class="step-number">4</span>
                            <span>Check tax calculation and total amount</span>
                        </div>
                        <div class="step">
                            <span class="step-number">5</span>
                            <span>Click <strong>Print Invoice</strong> for guest copy</span>
                        </div>
                    </div>
                    
                    <div class="guide-note">
                        <i class="fas fa-info-circle"></i>
                        <span>All amounts are in Sri Lankan Rupees (LKR) with 15% VAT included.</span>
                    </div>
                </div>

                <!-- Room Assignment Guide -->
                <div class="guide-card" id="room-assignment">
                    <h3>Room Assignment & Management</h3>
                    <p>How to assign, change, and manage room assignments.</p>
                    
                    <div class="steps">
                        <div class="step">
                            <span class="step-number">1</span>
                            <span>During reservation creation, select a specific room from dropdown</span>
                        </div>
                        <div class="step">
                            <span class="step-number">2</span>
                            <span>Or choose <strong>Auto-assign</strong> for system to select best available room</span>
                        </div>
                        <div class="step">
                            <span class="step-number">3</span>
                            <span>To change room, edit the reservation and select new room</span>
                        </div>
                        <div class="step">
                            <span class="step-number">4</span>
                            <span>Use <strong>Room Availability Calendar</strong> for visual overview</span>
                        </div>
                    </div>
                    
                    <div class="guide-note">
                        <i class="fas fa-exclamation-triangle"></i>
                        <span>Rooms cannot be double-booked for overlapping dates.</span>
                    </div>
                </div>

                <!-- Keyboard Shortcuts -->
                <div class="shortcuts">
                    <h4><i class="fas fa-keyboard"></i> Keyboard Shortcuts</h4>
                    <div class="shortcut-item">
                        <span>Search reservations</span>
                        <span class="shortcut-key">Ctrl+F</span>
                    </div>
                    <div class="shortcut-item">
                        <span>Clear all filters</span>
                        <span class="shortcut-key">Esc</span>
                    </div>
                    <div class="shortcut-item">
                        <span>Print invoice</span>
                        <span class="shortcut-key">Ctrl+P</span>
                    </div>
                    <div class="shortcut-item">
                        <span>Navigate back</span>
                        <span class="shortcut-key">Esc</span>
                    </div>
                    <div class="shortcut-item">
                        <span>Previous week (calendar)</span>
                        <span class="shortcut-key">←</span>
                    </div>
                    <div class="shortcut-item">
                        <span>Next week (calendar)</span>
                        <span class="shortcut-key">→</span>
                    </div>
                </div>
            </div>

            <!-- RIGHT: FAQ & CONTACT -->
            <div>
                <!-- FAQ Section -->
                <div class="faq-section">
                    <h2 class="section-title">
                        <i class="fas fa-question-circle"></i> Frequently Asked Questions
                    </h2>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(1)">
                            How do I check room availability for specific dates?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq1">
                            During reservation creation, after selecting room type and dates, the system automatically shows available rooms. You can also use the <strong>Room Availability Calendar</strong> for a visual 7-day view of all rooms.
                        </div>
                    </div>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(2)">
                            What if a guest wants to extend their stay?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq2">
                            Go to the reservation details, click <strong>Edit Reservation</strong>, and update the check-out date. The system will automatically recalculate the total amount based on the new duration.
                        </div>
                    </div>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(3)">
                            How do I handle cancellations?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq3">
                            Click the <strong>Delete</strong> button on the reservation and confirm. The room will immediately become available for other reservations. Note: This action cannot be undone.
                        </div>
                    </div>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(4)">
                            Can I modify completed reservations?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq4">
                            No. For data integrity, only upcoming and active reservations can be edited. Completed reservations are read-only for historical records.
                        </div>
                    </div>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(5)">
                            What does "Rooms Assigned" mean?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq5">
                            This shows how many reservations currently have a room number assigned. Click this stat card to filter and see all reservations with assigned rooms.
                        </div>
                    </div>

                    <div class="faq-item">
                        <div class="faq-question" onclick="toggleFAQ(6)">
                            How is the total amount calculated?
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="faq-answer" id="faq6">
                            Total = (Room Rate × Number of Nights) + 15% VAT. Room rates: Standard Rs.25,600/night, Deluxe Rs.38,400/night, Suite Rs.64,000/night.
                        </div>
                    </div>
                </div>

                <!-- Contact Section -->
                <div class="contact-section">
                    <h2 class="section-title">
                        <i class="fas fa-headset"></i> Contact Support
                    </h2>
                    
                    <div class="contact-grid">
                        <div class="contact-card">
                            <i class="fas fa-phone-alt"></i>
                            <h3>Phone Support</h3>
                            <p>Ext. 102</p>
                            <p style="font-size: 10px;">9 AM - 6 PM</p>
                        </div>
                        
                        <div class="contact-card">
                            <i class="fas fa-envelope"></i>
                            <h3>Email</h3>
                            <p>support@oceanview.lk</p>
                            <p style="font-size: 10px;">24hr response</p>
                        </div>
                        
                        <div class="contact-card">
                            <i class="fas fa-user-tie"></i>
                            <h3>In-Person</h3>
                            <p>Front Desk</p>
                            <p style="font-size: 10px;">Always available</p>
                        </div>
                        
                        <div class="contact-card">
                            <i class="fas fa-file-alt"></i>
                            <h3>Manual</h3>
                            <p>Staff Handbook</p>
                            <p style="font-size: 10px;">Pages 45-68</p>
                        </div>
                    </div>
                    
                    <!-- Emergency Contact -->
                    <div class="emergency">
                        <h3><i class="fas fa-exclamation-triangle"></i> Emergency</h3>
                        <p>System down or critical issues:</p>
                        <p><i class="fas fa-phone"></i> IT Department: Ext. 999</p>
                        <p><i class="fas fa-mobile-alt"></i> Mobile: 077-123-4567</p>
                        <p class="phone">Manual backup forms at front desk</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- ============ FOOTER ============ -->
        <div class="footer">
            <p>Ocean View Resort Help Center • Last Updated: December 2024 • Version 2.1</p>
            <p style="margin-top: 5px; font-size: 12px;">For training materials, contact HR department</p>
        </div>
    </div>

    <script>
        // Toggle FAQ answers
        function toggleFAQ(num) {
            const answer = document.getElementById('faq' + num);
            const icon = answer.previousElementSibling.querySelector('i');
            
            answer.classList.toggle('show');
            icon.classList.toggle('fa-chevron-down');
            icon.classList.toggle('fa-chevron-up');
        }

        // Search functionality
        function searchHelp() {
            const searchTerm = document.getElementById('searchHelp').value.toLowerCase().trim();
            if (!searchTerm) {
                alert('Please enter a search term');
                return;
            }
            
            const sections = {
                'add': 'add-reservation',
                'new': 'add-reservation',
                'create': 'add-reservation',
                'book': 'add-reservation',
                'reservation': 'add-reservation',
                'manage': 'manage-reservations',
                'view': 'manage-reservations',
                'search': 'manage-reservations',
                'filter': 'manage-reservations',
                'edit': 'manage-reservations',
                'delete': 'manage-reservations',
                'bill': 'generate-bill',
                'invoice': 'generate-bill',
                'payment': 'generate-bill',
                'cost': 'generate-bill',
                'room': 'room-assignment',
                'assign': 'room-assignment',
                'availability': 'room-assignment'
            };
            
            for (const [keyword, sectionId] of Object.entries(sections)) {
                if (searchTerm.includes(keyword)) {
                    scrollToSection(sectionId);
                    highlightSection(sectionId);
                    return;
                }
            }
            
            alert('No results found for: "' + searchTerm + '"\n\nTry searching for: add, manage, bill, room, FAQ');
        }

        // Scroll to section
        function scrollToSection(sectionId) {
            const element = document.getElementById(sectionId);
            if (element) {
                element.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }

        // Highlight section temporarily
        function highlightSection(sectionId) {
            const element = document.getElementById(sectionId);
            if (element) {
                element.style.transition = 'background-color 0.5s';
                element.style.backgroundColor = '#fff9e6';
                element.style.boxShadow = '0 0 0 3px #ffc107';
                
                setTimeout(() => {
                    element.style.backgroundColor = '';
                    element.style.boxShadow = '';
                }, 2000);
            }
        }

        // Enter key for search
        document.getElementById('searchHelp').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchHelp();
            }
        });

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            console.log('Help page loaded');
            
            // Add click effect to quick cards
            document.querySelectorAll('.quick-card').forEach(card => {
                card.addEventListener('click', function() {
                    this.style.transform = 'scale(0.98)';
                    setTimeout(() => {
                        this.style.transform = '';
                    }, 200);
                });
            });
        });
    </script>
</body>
</html>