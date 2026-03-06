package com.oceanview.controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.oceanview.dao.UserDAO;

public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        // Get username and password, trim whitespace
        String username = request.getParameter("username").trim();
        String password = request.getParameter("password").trim();

        UserDAO userDAO = new UserDAO();

        // Optional: log the login attempt (for demonstration)
        System.out.println("Login attempt for user: " + username);

        if (userDAO.validateUser(username, password)) {
            HttpSession session = request.getSession();
            session.setAttribute("username", username);

            response.sendRedirect("dashboard.jsp?type=success&message=Login%20Successful!%20Welcome,%20" + username);
        } else {
            response.sendRedirect("login.jsp?type=error&message=Invalid%20username%20or%20password!");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Redirect GET requests to login page
        response.sendRedirect("login.jsp");
    }
}package com.oceanview.controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.oceanview.dao.UserDAO;

public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        UserDAO userDAO = new UserDAO();

        if (userDAO.validateUser(username, password)) {
            HttpSession session = request.getSession();
            session.setAttribute("username", username);

            response.sendRedirect("dashboard.jsp?type=success&message=Login%20Successful!%20Welcome,%20" + username);
        } else {
            response.sendRedirect("login.jsp?type=error&message=Invalid%20username%20or%20password!");
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
    
   
}
