# 🚀 TrackIt: Professional DevOps & Monitoring Stack

This project is a complete automated CI/CD and Monitoring infrastructure for the **TrackIt** Web Application. It uses industry-standard tools to ensure the app is built, deployed, and monitored automatically.

---

## 🛠️ Architecture Components
1.  **TrackIt Web App:** The core application served via NGINX.
2.  **Jenkins:** The CI/CD "Brain" that automates builds and deployments.
3.  **Prometheus:** Collects performance metrics from all services.
4.  **Grafana:** Visualizes metrics in beautiful, real-time dashboards.
5.  **cAdvisor:** Monitors container-level resource usage (CPU/RAM).
6.  **Node Exporter:** Monitors host-level system metrics.

---

## 🚦 How to Start Everything

### 1. Prerequisites
*   **Docker Desktop:** Must be running.
*   **Git:** Installed and configured.
*   **Ngrok:** Needed for automatic GitHub Webhooks.

### 2. Launch the Stack
From the project root (`d:\TrackIt\trackit`), run:
```bash
docker compose up -d
```
*Wait 2-3 minutes for all services to wake up.*

### 3. Access Your Services
| Service | URL | Credentials |
| :--- | :--- | :--- |
| **🌍 Web App** | [http://localhost:8080](http://localhost:8080) | - |
| **🏗️ Jenkins** | [http://localhost:8082](http://localhost:8082) | `admin` / `admin123` |
| **📊 Grafana** | [http://localhost:3000](http://localhost:3000) | `admin` / `admin` |
| **🔥 Prometheus** | [http://localhost:9090](http://localhost:9090) | - |
| **📦 cAdvisor** | [http://localhost:8081](http://localhost:8081) | - |

---

## 🔄 How to Deploy Changes

### Step 1: Automatic Deployment (The Pro Way)
1.  Open a terminal and start Ngrok: `ngrok http 8082`.
2.  Update your GitHub Repo Webhook with the NEW Ngrok URL + `/github-webhook/`.
3.  Simply push your code:
    ```bash
    git add .
    git commit -m "Your changes"
    git push origin main
    ```
4.  **Jenkins will build and deploy automatically.**

### Step 2: Manual Deployment
If Ngrok is closed, you can always trigger a build manually:
1.  Go to **Jenkins** -> **TrackIt-Deploy**.
2.  Click **"Build Now"**.

---

## 📈 Monitoring & Analytics
1.  **CPU/RAM Usage:** Open Grafana and import/view the **"Node Exporter Full"** dashboard (ID: 1860).
2.  **Container Health:** Use the Prometheus targets page to ensure all services are "UP".

---

## 🔧 Troubleshooting
*   **Changes not visible?** Browsers cache heavily. Use `Ctrl + F5` or Incognito mode.
*   **Jenkins build failing?** Check "Console Output" for specific errors.
*   **Containers not starting?** Run `docker compose ps` to see which one is failing.

---
**Maintained by:** Rahul Pandey (DevOps Engineer)
