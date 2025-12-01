# Dev Environment Boilerplates (D.E.B.)

> **Project Goal:** To establish a scalable, local development environment (DevOps) using Docker and Traefik for the automated deployment of web applications (WordPress, Next.js, React, etc.) with HTTPS support.

## Features

* **Automated Deployment:** Launch a new site with a single command.
* **Dynamic Routing (Traefik):** All projects are accessible via secure HTTPS (SSL) on `.localhost` subdomains.
* **Project Isolation:** Each project utilizes its own isolated Docker network (`wp_network`).
* **Zero Port Conflicts:** No project binds directly to host ports, eliminating conflicts (except for Traefik itself on 80/443).
* **Database Management:** Automatic MariaDB setup and access to PhpMyAdmin via a dedicated dynamic subdomain (e.g., `https://pma.project.localhost`).

---

## Repository Structure
```
.
├── projects/
│ ├── wp-template/ # WordPress Boilerplate (Current Implementation)
│ ├── create_wp_site.sh # Automation script for WP
│ └── ... (Future projects)
├── traefik/ # Global Traefik configuration
│ ├── config/
│ └── certs/
└── README.md
```

---

## I. Global Environment Setup

The primary Traefik proxy service must be running for all project templates to work.

### 1. Prerequisites

Ensure you have the following installed:

* **Docker** and **Docker Compose** (v2).
* **`mkcert`** (recommended for local HTTPS certificates).

### 2. Launching Traefik

Navigate to the `traefik/` directory and start the proxy:

```bash
cd traefik/
docker-compose up -d
```

Access Points:

Traefik Dashboard: https://traefik.localhost/dashboard/

## II. WordPress Boilerplate (wp-template)

This template sets up a complete WordPress environment (Nginx + PHP-FPM + MariaDB + PhpMyAdmin).

### 1. Template Files

* `wp-template/docker-compose.yml`: Uses neutral names (`wordpress_db`, `wordpress.localhost`) and connects to the global Traefik network.

* `wp-template/config/nginx/default.conf`: Nginx configuration for correct operation with PHP-FPM and Traefik.

* `projects/create_wp_site.sh`: The main automation script.

### 2. Creating a New Site (Script)

The `create_wp_site.sh` script fully automates the process: it copies the template, generates unique passwords, creates unique container/volume names, and sets up Traefik labels.

Usage:
```
# Syntax: ./create_wp_site.sh <new_project_name>
# Supports both hyphens (-) and underscores (_) in the name
cd projects/
./create_wp_site.sh my-new-blog
```

### 3. Running the Project

After creating the project folder (e.g., `my-new-blog`):
```
cd my-new-blog/
docker-compose up -d
```

### 4. Access

Once launched, the project is automatically registered with Traefik:

| Service    | Address                                                                | Notes                                      |
| ---------- | ---------------------------------------------------------------------- | ------------------------------------------ |
| WP Site    | [https://my-new-blog.localhost](https://my-new-blog.localhost)         | Main site domain.                          |
| PhpMyAdmin | [https://pma.my-new-blog.localhost](https://pma.my-new-blog.localhost) | Dynamic subdomain for database management. |

