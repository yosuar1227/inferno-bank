# 🏦 Inferno Bank

Proyecto de ejemplo basado en **arquitectura de microservicios en Node.js (TypeScript)**, con despliegue mediante **Terraform en AWS**.  
Cada microservicio está diseñado para ser **independiente**, manteniendo su propio código, dependencias y configuración de infraestructura.

---

## 📁 Estructura del proyecto

```bash
micro-services/
├── card-service/                # Servicio encargado de la gestión de tarjetas
│   ├── app/                     # Código fuente del servicio (lógica de negocio, handlers, db, etc.)
│   └── terraform/               # Configuración de infraestructura específica para el servicio
│
├── notification-service/        # Servicio responsable del envío de notificaciones (SQS, SNS, email, etc.)
│   ├── app/
│   └── terraform/
│
└── user-service/                # Servicio de usuarios (registro, login, autenticación, etc.)
    ├── app/
    └── terraform/

.gitignore                       # Archivos y carpetas ignoradas por Git
README.md                        # Documentación del proyecto
