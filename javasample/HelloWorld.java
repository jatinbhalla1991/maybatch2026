import java.io.*;
import java.net.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

public class HelloWorld {
    private static BufferedWriter logWriter;
    
    public static void main(String[] args) {
        try {
            // Create logs directory if it doesn't exist
            new File("/app/logs").mkdirs();
            
            // Setup log file
            String logFile = "/app/logs/app.log";
            FileWriter fw = new FileWriter(logFile, true);
            logWriter = new BufferedWriter(fw);
            
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            
            log(timestamp + " - Application Starting");
            log(timestamp + " - Java Version: " + System.getProperty("java.version"));
            log(timestamp + " - OS Name: " + System.getProperty("os.name"));
            log(timestamp + " - Starting HTTP Server on port 8080");
            
            // Start HTTP server on port 8080
            HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
            server.createContext("/", exchange -> handleRequest(exchange));
            server.createContext("/health", exchange -> handleHealth(exchange));
            server.setExecutor(null);
            server.start();
            
            log(timestamp + " - HTTP Server started successfully!");
            System.out.println("Server is running on http://localhost:8080");
            System.out.println("Health check available at http://localhost:8080/health");
            
        } catch (Exception e) {
            try {
                log("ERROR: " + e.getMessage());
                e.printStackTrace();
            } catch (IOException ioException) {
                ioException.printStackTrace();
            }
        }
    }
    
    private static void handleRequest(HttpExchange exchange) throws IOException {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        
        String response = "<!DOCTYPE html>\n" +
                "<html>\n" +
                "<head>\n" +
                "    <title>Java Application</title>\n" +
                "    <style>\n" +
                "        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }\n" +
                "        .container { background-color: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }\n" +
                "        h1 { color: #333; }\n" +
                "        .info { background-color: #e3f2fd; padding: 10px; border-radius: 3px; margin: 10px 0; }\n" +
                "    </style>\n" +
                "</head>\n" +
                "<body>\n" +
                "    <div class='container'>\n" +
                "        <h1>Java Application - Running in Docker</h1>\n" +
                "        <div class='info'>\n" +
                "            <p><strong>Welcome!</strong></p>\n" +
                "            <p>Application is running successfully on localhost:8080</p>\n" +
                "            <p><strong>Timestamp:</strong> " + timestamp + "</p>\n" +
                "            <p><strong>Java Version:</strong> " + System.getProperty("java.version") + "</p>\n" +
                "            <p><strong>OS Name:</strong> " + System.getProperty("os.name") + "</p>\n" +
                "            <p><strong>Available Memory:</strong> " + Runtime.getRuntime().totalMemory() / (1024 * 1024) + " MB</p>\n" +
                "        </div>\n" +
                "        <p><a href='/health'>Check Health Status</a></p>\n" +
                "    </div>\n" +
                "</body>\n" +
                "</html>";
        
        exchange.getResponseHeaders().set("Content-Type", "text/html; charset=UTF-8");
        exchange.sendResponseHeaders(200, response.getBytes().length);
        OutputStream os = exchange.getResponseBody();
        os.write(response.getBytes());
        os.close();
        
        log(timestamp + " - Request received from " + exchange.getRemoteAddress().getAddress().getHostAddress());
    }
    
    private static void handleHealth(HttpExchange exchange) throws IOException {
        String response = "{\"status\": \"UP\", \"timestamp\": \"" + 
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) + "\"}";
        
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.getBytes().length);
        OutputStream os = exchange.getResponseBody();
        os.write(response.getBytes());
        os.close();
    }
    
    private static void log(String message) throws IOException {
        System.out.println(message);
        logWriter.write(message);
        logWriter.newLine();
        logWriter.flush();
    }
}
