import React from 'react'
import { createRoot } from 'react-dom/client'
import { App as AntdApp, ConfigProvider } from 'antd'
import zhCN from 'antd/locale/zh_CN'
import 'antd/dist/reset.css'
import './styles/main.css'
import App from './App.jsx'

const theme = {
  token: {
    colorPrimary: '#3f6588',
    colorInfo: '#3f6588',
    colorSuccess: '#55746b',
    colorWarning: '#9b7248',
    colorError: '#a75b54',
    colorText: '#202832',
    colorTextSecondary: '#697583',
    colorBorder: '#dbe2ea',
    colorBgLayout: '#f4f6f9',
    colorBgContainer: '#ffffff',
    borderRadius: 8,
    fontFamily: 'Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  },
  components: {
    Button: {
      borderRadius: 8,
      controlHeight: 36,
      primaryShadow: 'none',
    },
    Card: {
      borderRadiusLG: 10,
    },
    Table: {
      headerBg: '#f7f9fb',
      headerColor: '#516070',
      rowHoverBg: '#f7fafc',
    },
    Menu: {
      itemBorderRadius: 8,
      itemHeight: 42,
      itemSelectedBg: '#edf3f8',
      itemSelectedColor: '#294d6f',
    },
    Segmented: {
      itemSelectedBg: '#ffffff',
      trackBg: '#eef2f6',
    },
  },
}

createRoot(document.getElementById('app')).render(
  <React.StrictMode>
    <ConfigProvider locale={zhCN} theme={theme}>
      <AntdApp>
        <App />
      </AntdApp>
    </ConfigProvider>
  </React.StrictMode>,
)
