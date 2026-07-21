// Configuración PM2. Deploy: pm2 restart btop-rentals --update-env (relee el entorno).
module.exports = {
  apps: [
    {
      name: 'btop-rentals',
      script: 'deploy/server.mjs',
      cwd: '/opt/btop',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
    },
  ],
};
