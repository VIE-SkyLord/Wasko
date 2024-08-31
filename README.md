# Wasko
Web application to sell online courses
1. Functions
   -  Data privacy
      + Authentication and Authorization
        * Use Strong Authentication: two-factor authentication (2FA), OAuth
        * Proper Authorization: role-based access control (RBAC)
      + Password Security
        * Store Passwords Securely: bcrypt, Argon2, PBKDF2 to encrypt passwords
        * Enforce Strong Passwords:Require strong passwords from users, including factors such as length, special characters, uppercase and lowercase letters.
      + Protect Against SQL Injection
        * Use Prepared Statements: Use prepared statements to interact with the database instead of constructing SQL queries directly from user input.
        * Validate and Sanitize Input: Always validate and sanitize user input to avoid the inclusion of malicious code.
      + Protect Against XSS
        * Implement Encoding: Escape and encode input data when displaying it on the user interface to prevent the injection of malicious JavaScript code.
        * Use Content Security Policy (CSP): Configure CSP to limit the sources from which the website can load and execute resources.
      + Protect Against CSRF
        * Use CSRF Tokens: Add CSRF tokens to POST, PUT, DELETE requests to ensure that the request originates from your application and not from other sources.
        * Check Referrer: Verify the Referer or Origin headers in requests to confirm the source of the request.
      + Session Management
        * Use Secure Cookies: Set HttpOnly, Secure, and SameSite attributes for session cookies to prevent unauthorized access and protect session data.
        * Limit Session Duration: Set expiration times for user sessions and require re-login after periods of inactivity.
      + API Protection
        * Authenticate APIs: Use authentication methods such as API keys or OAuth to protect APIs from unauthorized access.
        * Restrict Access: Ensure API endpoints provide only the necessary access required for users or applications.
      + Data Security
        * Encrypt Data: Encrypt sensitive data such as credit card information and personal data both at rest and in transit.
        * Regular Backups: Perform regular data backups to be able to restore data in case of incidents or attacks.
      + Monitoring and Detection
        * Log Activities: Log important activities and monitor logs to detect suspicious behavior or attacks.
        * Use Monitoring Tools: Implement security monitoring tools to track and respond to security events.
      + Secure Development Practices
        * Conduct Security Testing: Perform regular security tests and code scans to identify vulnerabilities and weaknesses.
        * Educate and Train: Ensure all members of the development team are trained in security practices and aware of potential threats.
      + Use Security Libraries and Tools
        * Utilize Secure Libraries: Choose security libraries and tools that are regularly tested and updated.
        * Monitor Security Alerts: Subscribe to security alerts for vulnerabilities in the libraries and tools you use.
      + Secure File Uploads
        * Validate Uploaded Files: Check and filter uploaded files to ensure they do not contain malicious code or other threats.
        * Limit File Types and Sizes: Restrict the types and sizes of uploaded files to reduce the risk of attacks.
   -  Sign in
        + Use Email or Phone Number for Login
        + Enable Social Login Options
        + Implement Two-Factor Authentication (2FA)
        + Password Recovery Feature
        + Encourage Strong Passwords and Password Management
        + User-Friendly Login Interface
        + Security Notifications and Alerts
        + Regular Security Audits
   -  Sign up
        + Register with Email or Phone Number
        + Offer Social Sign-Up Options
        + Simplify the Registration Form
        + Use Strong Passwords and Password Security Checks
        + Privacy Policy and Terms of Service
        + CAPTCHA or Bot Detection
        + Post-Registration Two-Factor Authentication (2FA)
        + Send a Welcome Email/SMS
        + Support Features When Needed
        + Monitoring and Analytics
   -  Edit personal profile
        + Simple and Intuitive User Interface
        + Edit and Save Changes
        + Validation and Feedback
        + Profile Picture Upload
        + Security Settings
        + Privacy Controls
        + Change Email or Phone Number
        + Data Backup and Restore
        + Accessibility and Localization
        + Audit Logs and History
   -  Account recovery
        + Email or Phone Number Recovery
        + Security Questions (Optional)
        + Two-Factor Authentication (2FA)
        + Recovery via Backup Codes
        + Account Recovery via Social Accounts
        + Self-Service Password Reset
        + Alternate Email Address or Recovery Contact
        + Verification of Identity for High-Security Accounts
        + Notification of Account Recovery Attempts
        + User Support and Help Desk
        + Clear Recovery Instructions
   -  Create & sell courses
        + Identify Your Niche and Target Audience
        + Plan Your Course Content
        + Choose the Right Course Format
        + Create High-Quality Content
        + Choose a Platform to Host Your Course
        + Price Your Course
        + Market Your Course
        + Engage with Your Students
        + Collect Feedback and Improve
        + Scale Your Efforts
   -  Purchasing course
   -  Q&A
   -  Course review
   -  Course recommendation using AI
