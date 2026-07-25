# 潮流好物商城

一个本地可运行的全栈商城 Demo，包含 Django REST 后端、原生 H5 移动端和 SwiftUI iOS 客户端。

## 工程结构

```text
.
├── ecommerce_dj/        # Django REST API、数据库迁移、种子数据、媒体资源
├── ecommerce-mobile/    # 原生 HTML/CSS/JS H5 页面，无构建步骤
└── ecommerce-ios/       # SwiftUI iOS 客户端，使用 XcodeGen 管理工程
```

## 后端

```bash
cd ecommerce_dj
PYENV_VERSION=3.12.0 python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py migrate
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py seed_media
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py seed_data
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py runserver 0.0.0.0:8080
```

没有设置 `DATABASE_URL` 时，Django 使用本地 `ecommerce_dj/db.sqlite3`。该数据库文件不提交；数据库结构和初始数据由 migrations、`seed_media`、`seed_data` 和 `seed_data.json` 生成。

## H5

```bash
cd ecommerce-mobile
npx serve pages -l 3000
```

也可以直接在 `ecommerce-mobile/pages` 下使用：

```bash
python3 -m http.server 5173 --bind 127.0.0.1
```

## iOS

```bash
cd ecommerce-ios
xcodegen generate
cd ..
xcodebuild -project ecommerce-ios/ecommerce-ios.xcodeproj \
  -scheme ecommerce-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Debug 环境下 iOS 客户端访问 `http://localhost:8080/api/h5`，需要先启动后端。

## 测试

```bash
cd ecommerce_dj
DEBUG=true DJANGO_SECRET_KEY=local-dev SITE_URL=http://localhost:8080 .venv/bin/python manage.py test backend
```

前端页面是无构建原生页面，可用浏览器或 Playwright 进行交互回归。
