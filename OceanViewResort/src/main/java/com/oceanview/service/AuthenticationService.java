package com.oceanview.service;

import com.oceanview.dao.UserDAO;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

public class AuthenticationService {
    
    private UserDAO userDAO;
    private Map<String, Integer> failedAttempts; // Track failed attempts for security
    
    public AuthenticationService() {
        this.userDAO = new UserDAO();
        this.failedAttempts = new HashMap<>();
        System.out.println("✅ AuthenticationService initialized");
    }
    
    /**
     * Authenticate user with username and password
     * @param username The username
     * @param password The password
     * @return true if authentication successful, false otherwise
     */
    public boolean authenticate(String username, String password) {
        System.out.println("🔐 Authentication attempt for user: " + username + " at " + LocalDateTime.now());
        
        // Check if account is locked due to too many failed attempts
        if (isAccountLocked(username)) {
            System.out.println("❌ Account locked for user: " + username + " - too many failed attempts");
            return false;
        }
        
        // Delegate to DAO for actual validation
        boolean isValid = userDAO.validateUser(username, password);
        
        if (isValid) {
            // Success - clear failed attempts
            clearFailedAttempts(username);
            System.out.println("✅ Authentication successful for user: " + username);
        } else {
            // Failure - increment failed attempts
            incrementFailedAttempts(username);
            System.out.println("❌ Authentication failed for user: " + username);
        }
        
        return isValid;
    }
    
    /**
     * Log failed login attempt for security monitoring
     * @param username The username that failed
     */
    public void logFailedAttempt(String username) {
        System.out.println("⚠️ Failed login attempt for user: " + username + " at " + LocalDateTime.now());
        incrementFailedAttempts(username);
    }
    
    /**
     * Get current user role (if needed for authorization)
     * @param username The username
     * @return The user role or "USER" as default
     */
    public String getUserRole(String username) {
        // You can extend this to get role from database
        return "STAFF"; // Default role
    }
    
    /**
     * Check if account is locked due to too many failed attempts
     * @param username The username
     * @return true if account is locked
     */
    private boolean isAccountLocked(String username) {
        Integer attempts = failedAttempts.get(username);
        return attempts != null && attempts >= 5; // Lock after 5 failed attempts
    }
    
    /**
     * Increment failed attempts counter for username
     * @param username The username
     */
    private void incrementFailedAttempts(String username) {
        Integer attempts = failedAttempts.getOrDefault(username, 0);
        failedAttempts.put(username, attempts + 1);
    }
    
    /**
     * Clear failed attempts for username after successful login
     * @param username The username
     */
    private void clearFailedAttempts(String username) {
        failedAttempts.remove(username);
    }
    
    /**
     * Get number of failed attempts for username
     * @param username The username
     * @return Number of failed attempts
     */
    public int getFailedAttempts(String username) {
        return failedAttempts.getOrDefault(username, 0);
    }
}