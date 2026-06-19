# Java Application Monitoring - Prometheus Metrics & Grafana Dashboard

## Exposed Metrics from Java Application

Your Java app exposes the following metrics at `/metrics` endpoint:

```
# Request Metrics
java_app_requests_total        - Total number of HTTP requests
java_app_requests_success      - Successful requests count
java_app_requests_errors       - Failed/error requests count
java_app_health_checks         - Health check endpoint calls

# Performance Metrics
java_app_uptime_ms             - Application uptime in milliseconds

# Memory Metrics
java_memory_used               - Currently used memory in bytes
java_memory_max                - Maximum memory available in bytes
java_memory_usage_percent      - Memory usage as percentage (0-100)
```

## Prometheus Scraping Configuration

Prometheus automatically scrapes Java app metrics through:
- Kubernetes service discovery (role: pod)
- Pod annotations:
  - `prometheus.io/scrape: "true"`
  - `prometheus.io/port: "8080"`
  - `prometheus.io/path: "/metrics"`

Scrape interval: 15 seconds

## Accessing Metrics Directly

```bash
# Via port-forward
kubectl port-forward svc/java-app-internal 8080:8080 -n java-app

# In another terminal
curl http://localhost:8080/metrics

# Or get LoadBalancer IP
kubectl get svc java-app-loadbalancer -n java-app
curl http://<EXTERNAL_IP>/metrics
```

## Grafana Dashboard Setup

### 1. Login to Grafana

- **URL:** http://localhost:3000 (after port-forward)
- **Username:** admin
- **Password:** admin123

### 2. Add Prometheus Datasource

1. Click: **Configuration** (gear icon) → **Data Sources**
2. Click: **Add data source**
3. Select: **Prometheus**
4. Configure:
   - **Name:** Prometheus
   - **URL:** http://prometheus:9090
   - **Scrape interval:** 15s
5. Click: **Save & Test**

Expected message: "Data source is working"

### 3. Create Dashboard

#### Option A: Create from Scratch

1. Go to: **Dashboards** → **Create** → **New Dashboard**
2. Click: **Add new panel**
3. Configure panel:
   - **Panel Title:** e.g., "Request Rate"
   - **Query:** `rate(java_app_requests_total[1m])`
   - **Legend:** `{{instance}}`
   - **Panel Type:** Graph
4. Click: **Apply**

#### Option B: Import Pre-built Dashboard

1. Go to: **Dashboards** → **Import**
2. Paste dashboard JSON or ID

### 4. Example Dashboard Panels

#### Panel 1: Total Requests
```
Title: Total Requests
Query: java_app_requests_total
Panel Type: Stat
Unit: short
Thresholds: Green (0), Red (1000)
```

#### Panel 2: Request Rate (RPS)
```
Title: Requests Per Second
Query: rate(java_app_requests_total[1m])
Panel Type: Graph
Unit: short
```

#### Panel 3: Success Rate
```
Title: Success Rate %
Query: 100 * (java_app_requests_success / java_app_requests_total)
Panel Type: Graph
Unit: percent (0-100)
```

#### Panel 4: Error Rate
```
Title: Error Rate %
Query: 100 * (java_app_requests_errors / java_app_requests_total)
Panel Type: Graph
Unit: percent (0-100)
```

#### Panel 5: Memory Usage
```
Title: Memory Usage %
Query: 100 * (java_memory_used / java_memory_max)
Panel Type: Graph or Gauge
Unit: percent (0-100)
```

#### Panel 6: Application Uptime
```
Title: Uptime (Hours)
Query: java_app_uptime_ms / 1000 / 3600
Panel Type: Stat
Unit: hours
```

#### Panel 7: Health Checks
```
Title: Health Checks (Total)
Query: java_app_health_checks
Panel Type: Stat
Unit: short
```

## PromQL Queries for Monitoring

### Request Metrics

```promql
# Total requests
java_app_requests_total

# Requests per second (last 1 minute)
rate(java_app_requests_total[1m])

# Requests per second (last 5 minutes)
rate(java_app_requests_total[5m])

# Success ratio
java_app_requests_success / java_app_requests_total

# Error ratio
java_app_requests_errors / java_app_requests_total

# Requests in last 5 minutes
increase(java_app_requests_total[5m])
```

### Memory Metrics

```promql
# Current memory usage
java_memory_used

# Maximum memory
java_memory_max

# Memory as percentage
100 * (java_memory_used / java_memory_max)

# Memory increase in last 5 minutes
increase(java_memory_used[5m])
```

### Health Metrics

```promql
# Total health checks
java_app_health_checks

# Health checks per second
rate(java_app_health_checks[1m])

# Application uptime in seconds
java_app_uptime_ms / 1000

# Application uptime in minutes
java_app_uptime_ms / 1000 / 60

# Application uptime in hours
java_app_uptime_ms / 1000 / 3600
```

## Create Alerts in Grafana

### Alert 1: High Request Error Rate

1. Create new dashboard panel
2. Go to **Alert** tab
3. Configure:
   - **Condition:** `java_app_requests_errors > 10`
   - **For:** 5m
   - **If no data:** No Data
   - **Alert State:** Alerting

### Alert 2: High Memory Usage

1. Create alert:
   - **Condition:** `100 * (java_memory_used / java_memory_max) > 90`
   - **For:** 5m

### Alert 3: Low Request Rate (App Down)

1. Create alert:
   - **Condition:** `rate(java_app_requests_total[1m]) == 0`
   - **For:** 2m

## Traffic Generation for Testing

### Using curl
```bash
# Single request
curl http://<EXTERNAL_IP>

# 100 requests
for i in {1..100}; do curl http://<EXTERNAL_IP>; done

# Continuous requests (every second)
while true; do curl http://<EXTERNAL_IP>; sleep 1; done
```

### Using PowerShell
```powershell
# 100 requests
for ($i=0; $i -lt 100; $i++) { curl http://<EXTERNAL_IP> }

# Continuous requests
while($true) { curl http://<EXTERNAL_IP>; Start-Sleep -Seconds 1 }
```

### Using Apache Bench
```bash
# 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://<EXTERNAL_IP>/
```

## Prometheus Targets

### Verify scraping

1. Go to: **Prometheus** → **Status** → **Targets**
2. Should see:
   - prometheus (localhost:9090)
   - java-application (java-app pods)

### Debug no metrics

```bash
# Check if metrics endpoint is accessible
kubectl exec -it <java-app-pod> -n java-app -- curl http://localhost:8080/metrics

# Check Prometheus scrape logs
kubectl logs -f deployment/prometheus -n monitoring | grep java

# Check scrape config
kubectl get cm prometheus-config -n monitoring -o yaml
```

## Useful Grafana Features

### Create Alert Notification Channel

1. Go to: **Alerting** → **Notification channels**
2. Create new channel:
   - Email
   - Slack
   - PagerDuty
   - etc.

### Dashboard Variables (Dynamic)

1. Edit dashboard: Click **Settings** → **Variables**
2. Add variable for namespace, pod name, etc.
3. Use in queries: `${variable_name}`

### Dashboard Refresh Intervals

1. Top right: Click refresh icon
2. Set to: 5s, 10s, 30s, 1m, etc.
3. Or enable **auto** refresh

### Export Dashboard

1. Edit dashboard → **Share** → **Export**
2. Save as JSON
3. Share with team or backup

## Troubleshooting

### No metrics appearing in Grafana

**Check 1:** Prometheus is scraping
```
kubectl logs -f deployment/prometheus -n monitoring
```

**Check 2:** Java app metrics endpoint works
```
kubectl port-forward svc/java-app-internal 8080:8080 -n java-app
curl http://localhost:8080/metrics
```

**Check 3:** Prometheus datasource is connected
- Go to Grafana → Configuration → Data Sources
- Click Prometheus and test

**Check 4:** Wait 1-2 minutes
- Prometheus needs time to scrape and store metrics

### High memory usage in Prometheus

Edit prometheus-stack.yaml:
```yaml
args:
  - '--storage.tsdb.retention.time=7d'  # Reduce from 30d
```

### Grafana login not working

Check credentials in monitoring-grafana.yaml:
```yaml
env:
- name: GF_SECURITY_ADMIN_PASSWORD
  value: "admin123"
```

## Next Steps

1. ✅ Deploy Prometheus and Grafana
2. ✅ Create monitoring dashboard
3. ✅ Generate traffic to Java app
4. ✅ Monitor metrics in Grafana
5. Create alerts for anomalies
6. Set up alert notifications
7. Export dashboard for team
8. Monitor long-term trends
