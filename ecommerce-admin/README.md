# 潮流好物后台管理

独立 Vue 3 管理端，使用 Element Plus 和 ECharts，复用 Django 的 `/api/admin/...` 接口。

## 本地启动

后端：

```bash
cd ecommerce_dj
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py runserver 0.0.0.0:8080
```

后台：

```bash
cd ecommerce-admin
npm install
npm run dev -- --port 5173
```

访问：`http://localhost:5173/`

默认本地管理员账号：`admin`
