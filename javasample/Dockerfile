# Multi-stage build for Java application
FROM eclipse-temurin:11-jdk AS builder

# Set working directory
WORKDIR /app

# Copy the Java source file
COPY HelloWorld.java .

# Compile the Java source file
RUN javac HelloWorld.java

# Final stage - use smaller runtime image
FROM eclipse-temurin:11-jre-alpine

# Install curl for health checks (optional)
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy compiled class from builder stage
COPY --from=builder /app/*.class .

# Create volume directories
RUN mkdir -p /app/logs /app/data /app/config

# Create non-root user for security
RUN addgroup -g 1001 appuser && \
    adduser -D -u 1001 -G appuser appuser

# Change ownership of app files
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port (if needed for future web service)
EXPOSE 8080

# Run the Java application
CMD ["java", "-cp", ".", "HelloWorld"]
