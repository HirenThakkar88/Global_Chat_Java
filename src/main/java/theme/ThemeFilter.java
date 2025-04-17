package theme;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class ThemeFilter implements Filter {
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
            
        HttpServletRequest req = (HttpServletRequest) request;
        HttpSession session = req.getSession(true);
        
        // Initialize theme if not set
        if(session.getAttribute("currentTheme") == null) {
            session.setAttribute("currentTheme", "light");
        }
        
        chain.doFilter(request, response);
    }
}
