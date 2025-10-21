/**
 * PM2 Ecosystem Configuration
 * Manages all processes in the unified TappPlus container
 *
 * Processes:
 * 1. Nginx - Reverse proxy (port 80)
 * 2. Redis Server - Message queue for reminders
 * 3. API Server - NestJS backend (port 5550)
 * 4. Web Server - Next.js frontend (port 5500)
 * 5. Worker - Background job processor for reminders
 */

module.exports = {
  apps: [
    // ===================================
    // 1. Nginx Reverse Proxy
    // ===================================
    {
      name: 'nginx',
      script: 'nginx',
      args: '-g "daemon off;"',
      interpreter: 'none',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 3000,
      env: {
        NODE_ENV: 'production'
      },
      error_file: '/app/logs/nginx-pm2-error.log',
      out_file: '/app/logs/nginx-pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    },

    // ===================================
    // 2. Redis Server
    // ===================================
    {
      name: 'redis',
      script: 'redis-server',
      args: '--daemonize no --bind 127.0.0.1 --port 6379',
      interpreter: 'none',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 3000,
      env: {
        NODE_ENV: 'production'
      }
    },

    // ===================================
    // 3. API Server (NestJS)
    // ===================================
    {
      name: 'api',
      script: './apps/api/dist/main.js',
      cwd: '/app',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      kill_timeout: 5000,
      env: {
        NODE_ENV: 'production',
        DATABASE_URL: process.env.DATABASE_URL || 'file:/app/data/meditache.db',
        REDIS_URL: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
        JWT_SECRET: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
        JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key-change-in-production',
        TZ: process.env.TZ || 'Africa/Douala',
        API_PORT: process.env.API_PORT || '5550'
      },
      error_file: '/app/logs/api-error.log',
      out_file: '/app/logs/api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      // Wait for Redis to be ready
      wait_ready: true,
      listen_timeout: 15000
    },

    // ===================================
    // 4. Web Server (Next.js)
    // ===================================
    {
      name: 'web',
      script: './apps/web/server.js',
      cwd: '/app',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 5000,
      wait_ready: false,
      kill_timeout: 5000,
      env: {
        NODE_ENV: 'production',
        PORT: process.env.WEB_PORT || '5500',
        HOSTNAME: '0.0.0.0',
        NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || ''
      },
      error_file: '/app/logs/web-error.log',
      out_file: '/app/logs/web-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    },

    // ===================================
    // 5. Worker (Background Jobs)
    // ===================================
    {
      name: 'worker',
      script: './apps/api/dist/worker.js',
      cwd: '/app',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 5000,
      kill_timeout: 5000,
      env: {
        NODE_ENV: 'production',
        DATABASE_URL: process.env.DATABASE_URL || 'file:/app/data/meditache.db',
        REDIS_URL: process.env.REDIS_URL || 'redis://127.0.0.1:6379',
        JWT_SECRET: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
        JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'your-super-secret-refresh-key-change-in-production',
        TZ: process.env.TZ || 'Africa/Douala'
      },
      error_file: '/app/logs/worker-error.log',
      out_file: '/app/logs/worker-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      // Wait for Redis and API to be ready
      wait_ready: false
    }
  ],

  // ===================================
  // Deployment Configuration (optional)
  // ===================================
  deploy: {
    production: {
      user: 'node',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'git@github.com:your-org/tappplus.git',
      path: '/var/www/tappplus',
      'post-deploy': 'docker-compose up -d --build',
      env: {
        NODE_ENV: 'production'
      }
    }
  }
};
