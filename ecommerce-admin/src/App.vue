<template>
  <section v-if="!isAuthed" class="login-page">
    <div class="login-card">
      <div class="brand-block">
        <div class="brand-mark">潮</div>
        <div>
          <p class="eyebrow">管理后台</p>
          <h1>潮流好物后台</h1>
          <p>商品、订单、内容和会员在这里处理。</p>
        </div>
      </div>

      <el-form :model="loginForm" label-position="top" @submit.prevent="login">
        <el-form-item label="管理员账号">
          <el-input v-model="loginForm.username" size="large" autocomplete="username" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="loginForm.password" size="large" type="password" autocomplete="current-password" show-password />
        </el-form-item>
        <el-button class="login-button" type="primary" size="large" :loading="loading" @click="login">进入后台</el-button>
      </el-form>
    </div>
  </section>

  <el-container v-else class="admin-layout" :class="{ 'sidebar-collapsed': isSidebarCollapsed, 'compact-viewport': isCompactViewport }">
    <el-aside
      :width="isSidebarCollapsed ? '84px' : '248px'"
      class="admin-aside"
      :class="{ collapsed: isSidebarCollapsed }"
      :inert="isCompactViewport && isSidebarCollapsed"
      :aria-hidden="isCompactViewport && isSidebarCollapsed"
    >
      <div class="aside-brand">
        <div class="brand-mark">潮</div>
        <div class="brand-copy">
          <strong>潮流好物</strong>
          <span>管理台</span>
        </div>
        <el-button
          class="aside-collapse-button"
          :icon="isSidebarCollapsed ? Expand : Fold"
          circle
          text
          :aria-label="isSidebarCollapsed ? '展开侧边栏' : '收起侧边栏'"
          @click="toggleSidebar"
        />
      </div>

      <el-menu
        :default-active="activeView"
        :collapse="isSidebarCollapsed"
        :collapse-transition="false"
        class="admin-menu"
        @select="switchView"
      >
        <el-menu-item v-for="item in navItems" :key="item.index" :index="item.index" :title="item.label">
          <el-icon><component :is="item.icon" /></el-icon>
          <span class="menu-label">{{ item.label }}</span>
        </el-menu-item>
      </el-menu>

      <a class="front-link" href="http://localhost:3000/index.html" target="_blank" rel="noreferrer" title="打开商城前台">
        <el-icon><Shop /></el-icon>
        <span>打开商城前台</span>
      </a>
    </el-aside>
    <button
      v-if="isCompactViewport && !isSidebarCollapsed"
      class="aside-scrim"
      type="button"
      aria-label="关闭侧边栏"
      @click="isSidebarCollapsed = true"
    ></button>

    <el-container>
      <el-header height="82px" class="admin-header">
        <div class="header-title-row">
          <el-button
            class="header-collapse-button"
            :icon="isSidebarCollapsed ? Expand : Fold"
            circle
            :aria-label="isSidebarCollapsed ? '展开侧边栏' : '收起侧边栏'"
            @click="toggleSidebar"
          />
          <div>
            <p class="eyebrow">{{ currentMeta.kicker }}</p>
            <h2>{{ currentMeta.title }}</h2>
          </div>
        </div>
        <div class="header-actions">
          <el-input
            v-if="searchable"
            v-model="keyword"
            clearable
            class="global-search"
            placeholder="搜索当前模块"
            @keyup.enter="loadCurrentView"
            @clear="loadCurrentView"
          >
            <template #prefix><el-icon><Search /></el-icon></template>
          </el-input>
          <el-tag v-if="formattedLastSynced" class="sync-tag" type="info" effect="plain">已同步 {{ formattedLastSynced }}</el-tag>
          <el-dropdown trigger="click" @command="handleQuickCreate">
            <el-button type="primary">
              快速新建
              <el-icon class="el-icon--right"><ArrowDown /></el-icon>
            </el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="product">新增商品</el-dropdown-item>
                <el-dropdown-item command="banner">新增 Banner</el-dropdown-item>
                <el-dropdown-item command="coupon">发放优惠券</el-dropdown-item>
                <el-dropdown-item command="media">上传素材</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-button :icon="Refresh" :loading="loading" circle @click="loadCurrentView" />
          <el-button @click="logout">退出</el-button>
        </div>
      </el-header>

      <el-main class="admin-main" v-loading="loading">
        <section v-show="activeView === 'dashboard'" class="view-stack">
          <div class="dashboard-brief">
            <div class="dashboard-copy">
              <p class="eyebrow">经营中台</p>
              <h3>今日重点</h3>
              <span>先处理待发货、售后和低库存，再维护首页内容。</span>
            </div>
            <div class="brief-actions">
              <button v-for="item in dashboardQuickActions" :key="item.label" class="brief-action" type="button" @click="item.action">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>

          <div class="metric-grid">
            <el-card v-for="metric in metrics" :key="metric.label" shadow="never" class="metric-card" :class="`tone-${metric.tone}`">
              <div class="metric-top">
                <span>{{ metric.label }}</span>
                <el-icon><component :is="metric.icon" /></el-icon>
              </div>
              <strong>{{ metric.value }}</strong>
              <em>{{ metric.tag }}</em>
            </el-card>
          </div>

          <div class="operations-grid">
            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>7 天销售趋势</span>
                  <el-tag type="success" effect="plain">订单 / GMV</el-tag>
                </div>
              </template>
              <div ref="salesChartRef" class="chart-box compact"></div>
            </el-card>

            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>运营待办</span>
                  <el-button text type="primary" @click="loadDashboard">刷新</el-button>
                </div>
              </template>
              <div class="todo-grid">
                <button v-for="item in todoCards" :key="item.label" class="todo-card" :class="`tone-${item.tone}`" type="button" @click="item.action">
                  <span>{{ item.label }}</span>
                  <strong>{{ item.value }}</strong>
                  <em>{{ item.hint }}</em>
                </button>
              </div>
            </el-card>
          </div>

          <div class="dashboard-grid">
            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>订单状态</span>
                  <el-tag type="info" effect="plain">实时</el-tag>
                </div>
              </template>
              <div ref="orderChartRef" class="chart-box"></div>
            </el-card>

            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>热卖商品</span>
                  <el-button text type="primary" @click="switchView('products')">管理商品</el-button>
                </div>
              </template>
              <div class="rank-list">
                <div v-for="item in dashboard.topProducts" :key="item.id" class="rank-item">
                  <el-image :src="item.image" fit="cover" class="rank-image">
                    <template #error><div class="image-fallback">IMG</div></template>
                  </el-image>
                  <div>
                    <strong>{{ item.name }}</strong>
                    <span>{{ item.category_name || item.subcategory_name || '未分类' }} · {{ item.sales_count }} 销量</span>
                  </div>
                </div>
              </div>
            </el-card>
          </div>

          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>最近订单</span>
                <el-button text type="primary" @click="switchView('orders')">查看全部</el-button>
              </div>
            </template>
            <el-table :data="dashboard.recentOrders" stripe>
              <el-table-column prop="id" label="订单号" min-width="180" />
              <el-table-column label="用户" min-width="120">
                <template #default="{ row }">{{ row.user?.username || '-' }}</template>
              </el-table-column>
              <el-table-column label="金额" width="120">
                <template #default="{ row }">{{ money(row.payment || row.total_amount) }}</template>
              </el-table-column>
              <el-table-column label="状态" width="110">
                <template #default="{ row }"><el-tag :type="statusType(row.status)">{{ statusText(row.status) }}</el-tag></template>
              </el-table-column>
              <el-table-column prop="created_display" label="创建时间" width="170" />
            </el-table>
          </el-card>

          <div class="dashboard-grid">
            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>库存预警</span>
                  <el-button text type="primary" @click="openInventoryRisk">查看低库存</el-button>
                </div>
              </template>
              <div class="rank-list">
                <div v-for="item in dashboard.lowStockProducts" :key="item.id" class="rank-item warning-rank">
                  <el-image :src="item.image" fit="cover" class="rank-image">
                    <template #error><div class="image-fallback">IMG</div></template>
                  </el-image>
                  <div>
                    <strong>{{ item.name }}</strong>
                    <span>{{ item.category_name || item.subcategory_name || '未分类' }} · 库存 {{ item.stock_total }}</span>
                  </div>
                  <el-button link type="primary" @click="openProductFromDashboard(item)">补货</el-button>
                </div>
                <el-empty v-if="!dashboard.lowStockProducts.length" description="暂无低库存商品" :image-size="72" />
              </div>
            </el-card>

            <el-card shadow="never" class="panel-card">
              <template #header>
                <div class="panel-head">
                  <span>内容健康度</span>
                  <el-button text type="primary" @click="openContentHealth">管理首页</el-button>
                </div>
              </template>
              <div class="health-grid">
                <button v-for="item in contentHealthCards" :key="item.label" class="health-card" type="button" @click="item.action">
                  <span>{{ item.label }}</span>
                  <strong>{{ item.value }}</strong>
                </button>
              </div>
            </el-card>
          </div>
        </section>

        <section v-show="activeView === 'products'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>商品库</h3>
              <span>上下架、库存和规格维护</span>
            </div>
            <div class="module-stats">
              <button v-for="item in productSummaryCards" :key="item.label" class="module-stat" type="button" :disabled="!item.action" @click="item.action?.()">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <div class="toolbar">
            <div class="toolbar-left">
              <el-segmented v-model="productStatus" :options="productStatusOptions" @change="loadProducts" />
              <el-select v-model="productCategory" clearable class="category-filter" placeholder="按分类筛选" @change="loadProducts">
                <el-option v-for="item in categories" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
              <el-select v-model="productStock" clearable class="stock-filter" placeholder="库存筛选" @change="loadProducts">
                <el-option v-for="item in productStockOptions" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
            </div>
            <div class="toolbar-actions">
              <el-button-group>
                <el-button :disabled="!selectedProducts.length" @click="bulkSetProductStatus(true)">批量上架</el-button>
                <el-button :disabled="!selectedProducts.length" @click="bulkSetProductStatus(false)">批量下架</el-button>
              </el-button-group>
              <el-button type="primary" :icon="Plus" @click="openProduct()">新增商品</el-button>
            </div>
          </div>
          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>商品列表</span>
                <el-tag type="info" effect="plain">{{ productFilterLabel }}</el-tag>
              </div>
            </template>
            <el-table :data="products" stripe max-height="calc(100vh - 420px)" @selection-change="selectedProducts = $event">
              <template #empty><el-empty description="暂无商品，先新增一个商品" /></template>
              <el-table-column type="selection" width="46" fixed />
              <el-table-column label="商品" min-width="300" fixed>
                <template #default="{ row }">
                  <div class="goods-cell">
                    <el-image :src="row.image" fit="cover" class="goods-image">
                      <template #error><div class="image-fallback">IMG</div></template>
                    </el-image>
                    <div>
                      <strong>{{ row.name }}</strong>
                      <span>{{ row.tag || '无标签' }} · {{ row.sku_count || 0 }} SKU · 库存 {{ row.stock_total }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="分类" min-width="150">
                <template #default="{ row }">{{ row.category_name || '-' }} / {{ row.subcategory_name || '-' }}</template>
              </el-table-column>
              <el-table-column label="价格" width="140">
                <template #default="{ row }">{{ money(row.price) }}</template>
              </el-table-column>
              <el-table-column prop="sales_count" label="销量" width="100" sortable />
              <el-table-column label="库存" width="120" sortable>
                <template #default="{ row }">
                  <span :class="{ danger: row.low_stock_count > 0 }">{{ row.stock_total }}</span>
                  <span v-if="row.low_stock_count > 0" class="subtext danger">{{ row.low_stock_count }} 个低库存</span>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }"><el-tag :type="row.is_in_stock ? 'success' : 'danger'">{{ row.is_in_stock ? '上架' : '下架' }}</el-tag></template>
              </el-table-column>
              <el-table-column label="操作" width="180" fixed="right">
                <template #default="{ row }">
                  <el-button link type="primary" @click="openProduct(row)">编辑</el-button>
                  <el-button link :type="row.is_in_stock ? 'danger' : 'success'" @click="toggleProduct(row)">{{ row.is_in_stock ? '下架' : '上架' }}</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-card>
        </section>

        <section v-show="activeView === 'orders'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>履约队列</h3>
              <span>付款、发货和售后按状态处理</span>
            </div>
            <div class="module-stats">
              <button v-for="item in orderSummaryCards" :key="item.label" class="module-stat" type="button" :disabled="!item.action" @click="item.action?.()">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <div class="toolbar">
            <el-segmented v-model="orderStatus" :options="orderStatusOptions" @change="loadOrders" />
          </div>
          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>订单列表</span>
                <el-tag type="info" effect="plain">{{ orderFilterLabel }}</el-tag>
              </div>
            </template>
            <el-table :data="orders" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无订单" /></template>
              <el-table-column prop="id" label="订单号" min-width="190" fixed />
              <el-table-column label="用户" width="130">
                <template #default="{ row }">{{ row.user?.username || '-' }}</template>
              </el-table-column>
              <el-table-column label="商品" min-width="220">
                <template #default="{ row }">
                  <strong>{{ row.products?.[0]?.name || '无商品' }}</strong>
                  <span class="subtext">共 {{ row.item_count || 0 }} 件</span>
                </template>
              </el-table-column>
              <el-table-column label="金额" width="120">
                <template #default="{ row }">{{ money(row.payment || row.total_amount) }}</template>
              </el-table-column>
              <el-table-column label="状态" width="112">
                <template #default="{ row }"><el-tag :type="statusType(row.status)">{{ statusText(row.status) }}</el-tag></template>
              </el-table-column>
              <el-table-column label="履约" min-width="180">
                <template #default="{ row }">
                  {{ row.carrier || '-' }}
                  <span class="subtext">{{ row.tracking_number || row.after_sale_status_text || '' }}</span>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="300" fixed="right">
                <template #default="{ row }">
                  <el-button link type="primary" @click="openOrderDetail(row)">详情</el-button>
                  <el-button v-if="row.status === 'pending'" link type="success" @click="markPaid(row)">标记支付</el-button>
                  <el-button v-if="row.status === 'paid'" link type="primary" @click="openShip(row)">发货</el-button>
                  <el-button link type="primary" @click="openOrderStatus(row)">改状态</el-button>
                  <el-button link type="warning" @click="openAfterSale(row)">售后</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-card>
        </section>

        <section v-show="activeView === 'users'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>会员列表</h3>
              <span>账号状态、会员等级、积分和消费</span>
            </div>
            <div class="module-stats">
              <button v-for="item in userSummaryCards" :key="item.label" class="module-stat" type="button" disabled>
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>用户列表</span>
                <el-tag type="info" effect="plain">{{ users.length }} 位用户</el-tag>
              </div>
            </template>
            <el-table :data="users" stripe max-height="calc(100vh - 360px)">
              <template #empty><el-empty description="暂无用户" /></template>
              <el-table-column prop="username" label="用户" min-width="150" fixed />
              <el-table-column prop="phone" label="手机号" width="150" />
              <el-table-column prop="email" label="邮箱" min-width="210" />
              <el-table-column label="会员" width="130">
                <template #default="{ row }">{{ row.vip_level_name }}</template>
              </el-table-column>
              <el-table-column label="订单" width="150">
                <template #default="{ row }">{{ row.order_count }} 单 / {{ money(row.total_spent) }}</template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }"><el-tag :type="row.is_active ? 'success' : 'danger'">{{ row.is_active ? '启用' : '停用' }}</el-tag></template>
              </el-table-column>
              <el-table-column label="操作" width="100">
                <template #default="{ row }"><el-button link type="primary" @click="openUser(row)">编辑</el-button></template>
              </el-table-column>
            </el-table>
          </el-card>
        </section>

        <section v-show="activeView === 'content'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>前台内容</h3>
              <span>分类、Banner、栏目和素材统一维护</span>
            </div>
            <div class="module-stats">
              <button v-for="item in contentSummaryCards" :key="item.label" class="module-stat" type="button" :disabled="!item.action" @click="item.action?.()">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <div class="toolbar">
            <el-segmented v-model="contentKind" :options="contentKindOptions" />
            <div class="toolbar-actions">
              <input ref="mediaInput" class="hidden-file-input" type="file" accept="image/*" @change="uploadMediaFromInput" />
              <el-button type="primary" :icon="Plus" @click="openContent()">{{ contentPrimaryLabel }}</el-button>
            </div>
          </div>
          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>{{ currentContentLabel }}</span>
                <el-tag type="info" effect="plain">{{ currentContentRows.length }} 条内容</el-tag>
              </div>
            </template>
            <el-table v-if="contentKind === 'categories'" :data="categories" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无一级分类" /></template>
              <el-table-column label="分类" min-width="240">
                <template #default="{ row }">
                  <div class="goods-cell">
                    <el-image :src="row.icon" fit="cover" class="goods-image small"><template #error><div class="image-fallback">IMG</div></template></el-image>
                    <strong>{{ row.name }}</strong>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="sort_order" label="排序" width="100" />
              <el-table-column label="内容" width="150">
                <template #default="{ row }">{{ row.subcategory_count }} 子类 / {{ row.product_count }} 商品</template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }"><el-tag :type="row.is_enabled ? 'success' : 'danger'">{{ row.is_enabled ? '启用' : '停用' }}</el-tag></template>
              </el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openCategory(row)">编辑</el-button></template></el-table-column>
            </el-table>

            <el-table v-else-if="contentKind === 'subcategories'" :data="subcategories" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无二级分类" /></template>
              <el-table-column prop="name" label="子分类" min-width="180" />
              <el-table-column prop="category_name" label="所属分类" width="160" />
              <el-table-column prop="sort_order" label="排序" width="100" />
              <el-table-column prop="product_count" label="商品" width="100" />
              <el-table-column label="状态" width="100"><template #default="{ row }"><el-tag :type="row.is_enabled ? 'success' : 'danger'">{{ row.is_enabled ? '启用' : '停用' }}</el-tag></template></el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openSubcategory(row)">编辑</el-button></template></el-table-column>
            </el-table>

            <el-table v-else-if="contentKind === 'banners'" :data="banners" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无首页 Banner" /></template>
              <el-table-column label="Banner" min-width="280">
                <template #default="{ row }">
                  <div class="goods-cell">
                    <el-image :src="row.image" fit="cover" class="banner-image"><template #error><div class="image-fallback">IMG</div></template></el-image>
                    <div><strong>{{ row.title || row.tag || 'Banner' }}</strong><span>{{ row.tag || '-' }}</span></div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="link" label="跳转" min-width="180" />
              <el-table-column prop="product_count" label="关联商品" width="110" />
              <el-table-column prop="sort_order" label="排序" width="100" />
              <el-table-column label="状态" width="100"><template #default="{ row }"><el-tag :type="row.is_enabled ? 'success' : 'danger'">{{ row.is_enabled ? '启用' : '停用' }}</el-tag></template></el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openBanner(row)">编辑</el-button></template></el-table-column>
            </el-table>

            <el-table v-else-if="isHomeProductSection" :data="currentHomeSections" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty :description="`暂无${currentContentLabel}`" /></template>
              <el-table-column prop="title" label="栏目" min-width="180" fixed />
              <el-table-column v-if="contentKind === 'flashSales'" prop="subtitle" label="副标题" min-width="160" />
              <el-table-column label="商品" min-width="260">
                <template #default="{ row }">
                  <div class="section-products">
                    <el-avatar
                      v-for="item in row.products_preview"
                      :key="item.id"
                      :size="34"
                      :src="item.image"
                      shape="square"
                    />
                    <span>{{ row.product_count }} 个商品</span>
                  </div>
                </template>
              </el-table-column>
              <el-table-column v-if="contentKind === 'flashSales'" label="时间" min-width="220">
                <template #default="{ row }">
                  <span>{{ row.start_time || '-' }}</span>
                  <span class="subtext">{{ row.end_time || '' }}</span>
                </template>
              </el-table-column>
              <el-table-column prop="sort_order" label="排序" width="100" />
              <el-table-column label="状态" width="100"><template #default="{ row }"><el-tag :type="row.is_enabled ? 'success' : 'danger'">{{ row.is_enabled ? '启用' : '停用' }}</el-tag></template></el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openHomeSection(row)">编辑</el-button></template></el-table-column>
            </el-table>

            <el-table v-else-if="contentKind === 'promotions'" :data="promotions" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无促销位" /></template>
              <el-table-column label="促销位" min-width="280">
                <template #default="{ row }">
                  <div class="goods-cell">
                    <el-image :src="row.image" fit="cover" class="banner-image"><template #error><div class="image-fallback">IMG</div></template></el-image>
                    <div><strong>{{ row.title }}</strong><span>{{ row.subtitle || '-' }}</span></div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="link" label="跳转" min-width="180" />
              <el-table-column prop="sort_order" label="排序" width="100" />
              <el-table-column label="状态" width="100"><template #default="{ row }"><el-tag :type="row.is_enabled ? 'success' : 'danger'">{{ row.is_enabled ? '启用' : '停用' }}</el-tag></template></el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openPromotion(row)">编辑</el-button></template></el-table-column>
            </el-table>

            <el-table v-else :data="media" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无素材，上传一张图片" /></template>
              <el-table-column label="素材" min-width="320">
                <template #default="{ row }">
                  <div class="goods-cell">
                    <el-image :src="row.url" fit="cover" class="goods-image"><template #error><div class="image-fallback">IMG</div></template></el-image>
                    <div><strong>{{ row.name }}</strong><span>{{ row.mime_type || '-' }}</span></div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="大小" width="120"><template #default="{ row }">{{ fileSize(row.size) }}</template></el-table-column>
              <el-table-column prop="uploaded_at" label="上传时间" width="170" />
              <el-table-column label="地址" min-width="260"><template #default="{ row }"><el-link :href="row.url" target="_blank" type="primary">打开素材</el-link></template></el-table-column>
            </el-table>
          </el-card>
        </section>

        <section v-show="activeView === 'coupons'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>优惠券</h3>
              <span>发放、核销和有效期</span>
            </div>
            <div class="module-stats">
              <button v-for="item in couponSummaryCards" :key="item.label" class="module-stat" type="button" :disabled="!item.action" @click="item.action?.()">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <div class="toolbar">
            <el-segmented v-model="couponStatus" :options="couponStatusOptions" @change="loadCoupons" />
            <el-button type="primary" :icon="Plus" @click="openCoupon()">发放优惠券</el-button>
          </div>
          <el-card shadow="never" class="panel-card">
            <template #header>
              <div class="panel-head">
                <span>优惠券列表</span>
                <el-tag type="info" effect="plain">{{ couponFilterLabel }}</el-tag>
              </div>
            </template>
            <el-table :data="coupons" stripe max-height="calc(100vh - 420px)">
              <template #empty><el-empty description="暂无优惠券" /></template>
              <el-table-column prop="name" label="优惠券" min-width="180" />
              <el-table-column prop="username" label="用户" width="130" />
              <el-table-column label="优惠" width="110"><template #default="{ row }">减 {{ row.value }}</template></el-table-column>
              <el-table-column prop="threshold" label="门槛" min-width="150" />
              <el-table-column prop="time" label="有效期" width="140" />
              <el-table-column label="状态" width="100"><template #default="{ row }"><el-tag :type="couponType(row.status)">{{ statusText(row.status) }}</el-tag></template></el-table-column>
              <el-table-column label="操作" width="100"><template #default="{ row }"><el-button link type="primary" @click="openCoupon(row)">编辑</el-button></template></el-table-column>
            </el-table>
          </el-card>
        </section>

        <section v-show="activeView === 'shop'" class="view-stack">
          <div class="module-hero">
            <div class="module-copy">
              <h3>店铺资料</h3>
              <span>前台展示信息</span>
            </div>
            <div class="module-stats">
              <button v-for="item in shopSummaryCards" :key="item.label" class="module-stat" type="button" disabled>
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}</strong>
                <em>{{ item.hint }}</em>
              </button>
            </div>
          </div>
          <el-card shadow="never" class="panel-card shop-card">
            <template #header>
              <div class="panel-head">
                <span>店铺资料</span>
                <el-button type="primary" @click="saveShop">保存店铺</el-button>
              </div>
            </template>
            <el-form :model="shopForm" label-position="top" class="shop-form">
              <el-form-item label="店铺名称"><el-input v-model="shopForm.name" /></el-form-item>
              <el-form-item label="评分"><el-input-number v-model="shopForm.score" :min="0" :max="5" :step="0.1" /></el-form-item>
              <el-form-item label="商品数"><el-input-number v-model="shopForm.product_count" :min="0" /></el-form-item>
              <el-form-item label="销售额展示"><el-input v-model="shopForm.sales" /></el-form-item>
              <el-form-item label="粉丝数展示"><el-input v-model="shopForm.fans_count" /></el-form-item>
              <el-form-item label="店铺简介" class="full"><el-input v-model="shopForm.description" type="textarea" :rows="4" /></el-form-item>
            </el-form>
          </el-card>
        </section>
      </el-main>
    </el-container>
  </el-container>

  <el-drawer v-model="productDrawer" :title="productForm.id ? '编辑商品' : '新增商品'" size="720px">
    <el-form :model="productForm" label-position="top">
      <el-form-item label="商品名称"><el-input v-model="productForm.name" /></el-form-item>
      <el-form-item label="标签"><el-input v-model="productForm.tag" /></el-form-item>
      <el-form-item label="售价"><el-input-number v-model="productForm.price" :min="0" :precision="2" /></el-form-item>
      <el-form-item label="划线价"><el-input-number v-model="productForm.original_price" :min="0" :precision="2" /></el-form-item>
      <el-form-item label="销量"><el-input-number v-model="productForm.sales_count" :min="0" /></el-form-item>
      <el-form-item label="评分"><el-input-number v-model="productForm.rating" :min="0" :max="5" :step="0.1" /></el-form-item>
      <el-form-item label="所属子分类">
        <el-select v-model="productForm.subcategory_id" filterable clearable>
          <el-option v-for="item in subcategories" :key="item.id" :label="`${item.category_name} / ${item.name}`" :value="item.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="商品图片">
        <el-select v-model="productForm.image_id" filterable clearable>
          <el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="上架状态"><el-switch v-model="productForm.is_in_stock" active-text="上架" inactive-text="下架" /></el-form-item>
      <div class="form-section">
        <div class="section-title">
          <div>
            <strong>规格与库存</strong>
            <span>用于商品详情页、购物车和订单价格库存联动</span>
          </div>
          <el-button size="small" @click="addSpecGroup">新增规格组</el-button>
        </div>

        <div v-if="productForm.spec_groups?.length" class="spec-stack">
          <div v-for="(group, groupIndex) in productForm.spec_groups" :key="group.local_id || group.id" class="spec-editor">
            <div class="spec-row">
              <el-input v-model="group.name" placeholder="规格名，例如 尺码 / 颜色" @input="rebuildSkuRows" />
              <el-button link type="danger" @click="removeSpecGroup(groupIndex)">删除</el-button>
            </div>
            <div class="spec-value-row">
              <el-tag
                v-for="(value, valueIndex) in group.values"
                :key="value.local_id || value.id"
                closable
                effect="plain"
                @close="removeSpecValue(groupIndex, valueIndex)"
              >
                {{ value.value }}
              </el-tag>
              <el-input
                v-model="group.draft"
                class="spec-value-input"
                size="small"
                placeholder="输入规格值"
                @keyup.enter="addSpecValue(groupIndex)"
              />
              <el-button size="small" @click="addSpecValue(groupIndex)">添加</el-button>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无规格，单规格商品可不配置" :image-size="70" />

        <el-table v-if="productForm.skus?.length" :data="productForm.skus" border size="small" class="sku-table">
          <el-table-column prop="spec_text" label="SKU" min-width="150" />
          <el-table-column label="售价" width="130">
            <template #default="{ row }"><el-input-number v-model="row.price" :min="0" :precision="2" controls-position="right" /></template>
          </el-table-column>
          <el-table-column label="划线价" width="130">
            <template #default="{ row }"><el-input-number v-model="row.original_price" :min="0" :precision="2" controls-position="right" /></template>
          </el-table-column>
          <el-table-column label="库存" width="120">
            <template #default="{ row }"><el-input-number v-model="row.stock" :min="0" controls-position="right" /></template>
          </el-table-column>
          <el-table-column label="图片" min-width="150">
            <template #default="{ row }">
              <el-select v-model="row.image_id" filterable clearable placeholder="默认商品图">
                <el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <el-form-item label="商品描述"><el-input v-model="productForm.description" type="textarea" :rows="4" /></el-form-item>
      <div class="drawer-actions"><el-button @click="productDrawer = false">取消</el-button><el-button type="primary" @click="saveProduct">保存商品</el-button></div>
    </el-form>
  </el-drawer>

  <el-drawer v-model="contentDrawer" :title="contentDrawerTitle" size="560px">
    <el-form v-if="contentKind === 'categories'" :model="categoryForm" label-position="top">
      <el-form-item label="分类名称"><el-input v-model="categoryForm.name" /></el-form-item>
      <el-form-item label="排序"><el-input-number v-model="categoryForm.sort_order" :min="0" /></el-form-item>
      <el-form-item label="图标"><el-select v-model="categoryForm.icon_id" filterable clearable><el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="Banner"><el-select v-model="categoryForm.banner_id" filterable clearable><el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="启用"><el-switch v-model="categoryForm.is_enabled" /></el-form-item>
    </el-form>
    <el-form v-else-if="contentKind === 'subcategories'" :model="subcategoryForm" label-position="top">
      <el-form-item label="子分类名称"><el-input v-model="subcategoryForm.name" /></el-form-item>
      <el-form-item label="所属分类"><el-select v-model="subcategoryForm.category_id"><el-option v-for="item in categories" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="排序"><el-input-number v-model="subcategoryForm.sort_order" :min="0" /></el-form-item>
      <el-form-item label="图标"><el-select v-model="subcategoryForm.icon_id" filterable clearable><el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="启用"><el-switch v-model="subcategoryForm.is_enabled" /></el-form-item>
    </el-form>
    <el-form v-else-if="contentKind === 'banners'" :model="bannerForm" label-position="top">
      <el-form-item label="角标"><el-input v-model="bannerForm.tag" /></el-form-item>
      <el-form-item label="主标题"><el-input v-model="bannerForm.title" /></el-form-item>
      <el-form-item label="按钮文案"><el-input v-model="bannerForm.action_title" /></el-form-item>
      <el-form-item label="跳转链接"><el-input v-model="bannerForm.link" /></el-form-item>
      <el-form-item label="会场标识"><el-input v-model="bannerForm.landing_badge" /></el-form-item>
      <el-form-item label="会场副标题"><el-input v-model="bannerForm.landing_subtitle" /></el-form-item>
      <el-form-item label="色彩序号"><el-input-number v-model="bannerForm.gradient_type" :min="0" /></el-form-item>
      <el-form-item label="排序"><el-input-number v-model="bannerForm.sort_order" :min="0" /></el-form-item>
      <el-form-item label="图片"><el-select v-model="bannerForm.image_id" filterable clearable><el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="关联商品"><el-select v-model="bannerForm.product_ids" multiple filterable><el-option v-for="item in products" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="会场描述"><el-input v-model="bannerForm.landing_description" type="textarea" :rows="4" /></el-form-item>
      <el-form-item label="启用"><el-switch v-model="bannerForm.is_enabled" /></el-form-item>
    </el-form>
    <el-form v-else-if="isHomeProductSection" :model="homeSectionForm" label-position="top">
      <el-form-item label="栏目标题"><el-input v-model="homeSectionForm.title" /></el-form-item>
      <el-form-item v-if="contentKind === 'flashSales'" label="副标题"><el-input v-model="homeSectionForm.subtitle" /></el-form-item>
      <el-form-item v-if="contentKind === 'flashSales'" label="开始时间"><el-input v-model="homeSectionForm.start_time" type="datetime-local" /></el-form-item>
      <el-form-item v-if="contentKind === 'flashSales'" label="结束时间"><el-input v-model="homeSectionForm.end_time" type="datetime-local" /></el-form-item>
      <el-form-item label="排序"><el-input-number v-model="homeSectionForm.sort_order" :min="0" /></el-form-item>
      <el-form-item label="关联商品">
        <el-select v-model="homeSectionForm.product_ids" multiple filterable collapse-tags collapse-tags-tooltip>
          <el-option v-for="item in products" :key="item.id" :label="item.name" :value="item.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="启用"><el-switch v-model="homeSectionForm.is_enabled" /></el-form-item>
    </el-form>
    <el-form v-else-if="contentKind === 'promotions'" :model="promotionForm" label-position="top">
      <el-form-item label="标题"><el-input v-model="promotionForm.title" /></el-form-item>
      <el-form-item label="副标题"><el-input v-model="promotionForm.subtitle" /></el-form-item>
      <el-form-item label="跳转链接"><el-input v-model="promotionForm.link" /></el-form-item>
      <el-form-item label="图片"><el-select v-model="promotionForm.image_id" filterable clearable><el-option v-for="item in media" :key="item.id" :label="item.name" :value="item.id" /></el-select></el-form-item>
      <el-form-item label="排序"><el-input-number v-model="promotionForm.sort_order" :min="0" /></el-form-item>
      <el-form-item label="启用"><el-switch v-model="promotionForm.is_enabled" /></el-form-item>
    </el-form>
    <div class="drawer-actions"><el-button @click="contentDrawer = false">取消</el-button><el-button type="primary" @click="saveContent">保存内容</el-button></div>
  </el-drawer>

  <el-drawer v-model="orderDrawer" :title="orderDrawerTitle" size="460px">
    <el-form :model="orderForm" label-position="top">
      <template v-if="orderAction === 'ship'">
        <el-form-item label="物流公司"><el-input v-model="orderForm.carrier" /></el-form-item>
        <el-form-item label="运单号"><el-input v-model="orderForm.tracking_number" /></el-form-item>
      </template>
      <template v-else-if="orderAction === 'status'">
        <el-form-item label="订单状态">
          <el-select v-model="orderForm.status">
            <el-option v-for="item in orderRawStatuses" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
      </template>
      <template v-else>
        <el-form-item label="售后状态">
          <el-select v-model="orderForm.after_sale_status">
            <el-option v-for="item in afterSaleStatuses" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理备注"><el-input v-model="orderForm.after_sale_reason" type="textarea" :rows="4" /></el-form-item>
      </template>
      <div class="drawer-actions"><el-button @click="orderDrawer = false">取消</el-button><el-button type="primary" @click="saveOrderAction">保存</el-button></div>
    </el-form>
  </el-drawer>

  <el-drawer v-model="orderDetailDrawer" title="订单详情" size="620px">
    <div v-if="orderDetail" class="order-detail">
      <div class="detail-summary">
        <div>
          <span>订单号</span>
          <strong>{{ orderDetail.id }}</strong>
        </div>
        <el-tag :type="statusType(orderDetail.status)">{{ statusText(orderDetail.status) }}</el-tag>
      </div>

      <el-descriptions :column="2" border>
        <el-descriptions-item label="用户">{{ orderDetail.user?.username || '-' }}</el-descriptions-item>
        <el-descriptions-item label="实付金额">{{ money(orderDetail.payment || orderDetail.total_amount) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ orderDetail.created_display || '-' }}</el-descriptions-item>
        <el-descriptions-item label="支付时间">{{ orderDetail.pay_display || '-' }}</el-descriptions-item>
        <el-descriptions-item label="物流公司">{{ orderDetail.carrier || '-' }}</el-descriptions-item>
        <el-descriptions-item label="运单号">{{ orderDetail.tracking_number || '-' }}</el-descriptions-item>
      </el-descriptions>

      <section class="detail-section">
        <h3>收货地址</h3>
        <p>{{ orderDetail.address_name || '-' }} {{ orderDetail.address_phone || '' }}</p>
        <p>{{ addressText(orderDetail) || '-' }}</p>
      </section>

      <section class="detail-section">
        <h3>商品明细</h3>
        <div v-for="item in orderDetail.products" :key="item.id" class="order-product">
          <el-image :src="item.image" fit="cover" class="goods-image">
            <template #error><div class="image-fallback">IMG</div></template>
          </el-image>
          <div>
            <strong>{{ item.name }}</strong>
            <span>{{ item.spec || '默认规格' }} · x{{ item.quantity }}</span>
          </div>
          <b>{{ money(item.price) }}</b>
        </div>
      </section>

      <section v-if="orderDetail.after_sale_status && orderDetail.after_sale_status !== 'none'" class="detail-section warning-section">
        <h3>售后记录</h3>
        <p>{{ statusText(orderDetail.after_sale_status) }}</p>
        <p>{{ orderDetail.after_sale_reason || '暂无备注' }}</p>
      </section>

      <div class="drawer-actions">
        <el-button v-if="orderDetail.status === 'pending'" type="success" @click="markPaid(orderDetail)">标记支付</el-button>
        <el-button v-if="orderDetail.status === 'paid'" type="primary" @click="openShip(orderDetail)">发货</el-button>
        <el-button @click="openAfterSale(orderDetail)">处理售后</el-button>
      </div>
    </div>
  </el-drawer>

  <el-drawer v-model="userDrawer" title="编辑用户" size="460px">
    <el-form :model="userForm" label-position="top">
      <el-form-item label="邮箱"><el-input v-model="userForm.email" /></el-form-item>
      <el-form-item label="手机号"><el-input v-model="userForm.phone" /></el-form-item>
      <el-form-item label="会员等级"><el-select v-model="userForm.vip_level"><el-option v-for="item in vipLevels" :key="item.value" :label="item.label" :value="item.value" /></el-select></el-form-item>
      <el-form-item label="积分"><el-input-number v-model="userForm.points" :min="0" /></el-form-item>
      <el-form-item label="账号启用"><el-switch v-model="userForm.is_active" /></el-form-item>
      <div class="drawer-actions"><el-button @click="userDrawer = false">取消</el-button><el-button type="primary" @click="saveUser">保存用户</el-button></div>
    </el-form>
  </el-drawer>

  <el-drawer v-model="couponDrawer" :title="couponForm.id ? '编辑优惠券' : '发放优惠券'" size="460px">
    <el-form :model="couponForm" label-position="top">
      <el-form-item v-if="!couponForm.id" label="用户名"><el-input v-model="couponForm.username" /></el-form-item>
      <el-form-item label="优惠券名称"><el-input v-model="couponForm.name" /></el-form-item>
      <el-form-item label="优惠金额"><el-input-number v-model="couponForm.value" :min="0" /></el-form-item>
      <el-form-item label="使用门槛"><el-input v-model="couponForm.threshold" /></el-form-item>
      <el-form-item label="有效期"><el-input v-model="couponForm.time" /></el-form-item>
      <el-form-item label="状态"><el-select v-model="couponForm.status"><el-option v-for="item in couponRawStatuses" :key="item.value" :label="item.label" :value="item.value" /></el-select></el-form-item>
      <el-form-item label="说明"><el-input v-model="couponForm.description" type="textarea" :rows="4" /></el-form-item>
      <div class="drawer-actions"><el-button @click="couponDrawer = false">取消</el-button><el-button type="primary" @click="saveCoupon">保存优惠券</el-button></div>
    </el-form>
  </el-drawer>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import * as echarts from 'echarts'
import {
  ArrowDown,
  DataBoard,
  Expand,
  Fold,
  Goods,
  Grid,
  Plus,
  Refresh,
  Search,
  Shop,
  Ticket,
  Tickets,
  User,
} from '@element-plus/icons-vue'
import { adminApi, clearToken, getToken, setToken } from './api/admin'

const ACTIVE_VIEW_KEY = 'ecommerce_admin_active_view'
const SIDEBAR_COLLAPSED_KEY = 'ecommerce_admin_sidebar_collapsed'

const loading = ref(false)
const isAuthed = ref(Boolean(getToken()))
const activeView = ref(localStorage.getItem(ACTIVE_VIEW_KEY) || 'dashboard')
const isSidebarCollapsed = ref(localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true')
const isCompactViewport = ref(false)
const lastSyncedAt = ref(null)
const keyword = ref('')
const productStatus = ref('')
const productCategory = ref('')
const productStock = ref('')
const orderStatus = ref('')
const couponStatus = ref('')
const contentKind = ref('categories')
const orderChartRef = ref(null)
const salesChartRef = ref(null)
const mediaInput = ref(null)
let orderChart = null
let salesChart = null

const loginForm = reactive({ username: 'admin', password: 'iole' })
const dashboard = reactive({
  metrics: {},
  orderStatus: {},
  salesTrend: [],
  contentHealth: {},
  recentOrders: [],
  topProducts: [],
  lowStockProducts: [],
})
const products = ref([])
const orders = ref([])
const users = ref([])
const coupons = ref([])
const categories = ref([])
const subcategories = ref([])
const banners = ref([])
const homeFlashSales = ref([])
const homeHotRanks = ref([])
const homeRecommends = ref([])
const homeNewArrivals = ref([])
const promotions = ref([])
const media = ref([])
const shopForm = reactive({})

const productDrawer = ref(false)
const contentDrawer = ref(false)
const orderDrawer = ref(false)
const orderDetailDrawer = ref(false)
const userDrawer = ref(false)
const couponDrawer = ref(false)

const productForm = reactive({})
const categoryForm = reactive({})
const subcategoryForm = reactive({})
const bannerForm = reactive({})
const homeSectionForm = reactive({})
const promotionForm = reactive({})
const orderForm = reactive({})
const userForm = reactive({})
const couponForm = reactive({})
const orderAction = ref('')
const editingOrderId = ref('')
const selectedProducts = ref([])
const orderDetail = ref(null)

const viewMeta = {
  dashboard: { kicker: '后台 / 概览', title: '经营概览' },
  products: { kicker: '后台 / 商品', title: '商品管理' },
  orders: { kicker: '后台 / 订单', title: '订单履约' },
  users: { kicker: '后台 / 会员', title: '用户会员' },
  content: { kicker: '后台 / 内容', title: '首页内容' },
  coupons: { kicker: '后台 / 权益', title: '优惠券' },
  shop: { kicker: '后台 / 店铺', title: '店铺设置' },
}

const navItems = [
  { index: 'dashboard', label: '经营概览', icon: DataBoard },
  { index: 'products', label: '商品管理', icon: Goods },
  { index: 'orders', label: '订单履约', icon: Tickets },
  { index: 'users', label: '用户会员', icon: User },
  { index: 'content', label: '首页内容', icon: Grid },
  { index: 'coupons', label: '优惠券', icon: Ticket },
  { index: 'shop', label: '店铺设置', icon: Shop },
]

const currentMeta = computed(() => viewMeta[activeView.value] || viewMeta.dashboard)
const searchable = computed(() => ['products', 'orders', 'users', 'coupons'].includes(activeView.value))
const formattedLastSynced = computed(() => {
  if (!lastSyncedAt.value) return ''
  return lastSyncedAt.value.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
})
const homeProductSectionKinds = ['flashSales', 'hotRanks', 'recommends', 'newArrivals']
const isHomeProductSection = computed(() => homeProductSectionKinds.includes(contentKind.value))
const currentContentLabel = computed(() => contentKindOptions.find(item => item.value === contentKind.value)?.label || '内容')
const contentPrimaryLabel = computed(() => contentKind.value === 'media' ? '上传素材' : `新增${currentContentLabel.value}`)
const currentHomeSections = computed(() => ({
  flashSales: homeFlashSales.value,
  hotRanks: homeHotRanks.value,
  recommends: homeRecommends.value,
  newArrivals: homeNewArrivals.value,
}[contentKind.value] || []))
const contentDrawerTitle = computed(() => ({
  categories: categoryForm.id ? '编辑一级分类' : '新增一级分类',
  subcategories: subcategoryForm.id ? '编辑二级分类' : '新增二级分类',
  banners: bannerForm.id ? '编辑 Banner' : '新增 Banner',
  flashSales: homeSectionForm.id ? '编辑限时秒杀' : '新增限时秒杀',
  hotRanks: homeSectionForm.id ? '编辑热销榜' : '新增热销榜',
  recommends: homeSectionForm.id ? '编辑推荐栏目' : '新增推荐栏目',
  newArrivals: homeSectionForm.id ? '编辑新品栏目' : '新增新品栏目',
  promotions: promotionForm.id ? '编辑促销位' : '新增促销位',
}[contentKind.value]))
const orderDrawerTitle = computed(() => ({
  ship: '订单发货',
  status: '修改订单状态',
  afterSale: '售后处理',
}[orderAction.value] || '订单处理'))
const metrics = computed(() => [
  { label: '营业额', value: money(dashboard.metrics.revenue), tag: 'GMV', icon: DataBoard, tone: 'revenue' },
  { label: '订单数', value: formatNumber(dashboard.metrics.orders || 0), tag: `${dashboard.metrics.paid_orders || 0} 待发货`, icon: Tickets, tone: 'orders' },
  { label: '上架商品', value: formatNumber(dashboard.metrics.active_products || 0), tag: `${dashboard.metrics.products || 0} 总商品`, icon: Goods, tone: 'goods' },
  { label: '会员用户', value: formatNumber(dashboard.metrics.users || 0), tag: `${dashboard.metrics.coupons || 0} 张券`, icon: User, tone: 'users' },
])
const dashboardQuickActions = computed(() => [
  { label: '待发货', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '进入履约队列', action: () => openOrderQueue('paid') },
  { label: '售后', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '处理退款/拒绝', action: () => openOrderQueue('after_sale') },
  { label: '低库存', value: formatNumber(dashboard.metrics.low_stock_products || 0), hint: '补库存', action: openInventoryRisk },
  { label: '内容项', value: formatNumber((dashboard.contentHealth.enabled_banners || 0) + (dashboard.contentHealth.enabled_home_sections || 0)), hint: '维护首页展示', action: () => openContentHealth('banners') },
])
const todoCards = computed(() => [
  { label: '待付款订单', value: formatNumber(dashboard.metrics.pending_orders || 0), hint: '催付或取消', tone: 'neutral', action: () => openOrderQueue('pending') },
  { label: '待发货订单', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '尽快履约', tone: 'primary', action: () => openOrderQueue('paid') },
  { label: '售后处理', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '退款/拒绝', tone: 'warning', action: () => openOrderQueue('after_sale') },
  { label: '低库存商品', value: formatNumber(dashboard.metrics.low_stock_products || 0), hint: '补库存', tone: 'danger', action: openInventoryRisk },
])
const contentHealthCards = computed(() => [
  { label: '启用 Banner', value: dashboard.contentHealth.enabled_banners || 0, action: () => openContentHealth('banners') },
  { label: '启用分类', value: dashboard.contentHealth.enabled_categories || 0, action: () => openContentHealth('categories') },
  { label: '首页栏目', value: dashboard.contentHealth.enabled_home_sections || 0, action: () => openContentHealth('flashSales') },
  { label: '素材文件', value: dashboard.contentHealth.media_files || 0, action: () => openContentHealth('media') },
])
const currentContentRows = computed(() => {
  if (contentKind.value === 'categories') return categories.value
  if (contentKind.value === 'subcategories') return subcategories.value
  if (contentKind.value === 'banners') return banners.value
  if (contentKind.value === 'flashSales') return homeFlashSales.value
  if (contentKind.value === 'hotRanks') return homeHotRanks.value
  if (contentKind.value === 'recommends') return homeRecommends.value
  if (contentKind.value === 'newArrivals') return homeNewArrivals.value
  if (contentKind.value === 'promotions') return promotions.value
  return media.value
})
const currentContentEnabledCount = computed(() => {
  if (contentKind.value === 'media') return media.value.length
  return currentContentRows.value.filter(item => item.is_enabled !== false).length
})
const currentContentProductCount = computed(() => sumBy(currentContentRows.value, item => item.product_count))
const productFilterLabel = computed(() => {
  const parts = []
  const status = optionLabel(productStatusOptions, productStatus.value)
  if (status && status !== '全部') parts.push(status)
  const category = categories.value.find(item => item.id === productCategory.value)?.name
  if (category) parts.push(category)
  const stock = optionLabel(productStockOptions, productStock.value)
  if (stock) parts.push(stock)
  return parts.length ? parts.join(' / ') : '全部商品'
})
const orderFilterLabel = computed(() => optionLabel(orderStatusOptions, orderStatus.value) || '全部订单')
const couponFilterLabel = computed(() => optionLabel(couponStatusOptions, couponStatus.value) || '全部优惠券')
const productSummaryCards = computed(() => [
  { label: '当前结果', value: formatNumber(products.value.length), hint: productFilterLabel.value },
  { label: '上架商品', value: formatNumber(products.value.filter(item => item.is_in_stock).length), hint: '可售状态', action: () => openProductFilter({ status: 'active' }) },
  { label: '低库存', value: formatNumber(products.value.filter(isLowStockProduct).length), hint: '需要补货', action: openInventoryRisk },
  { label: '库存合计', value: formatNumber(sumBy(products.value, item => item.stock_total)), hint: '当前结果' },
])
const orderSummaryCards = computed(() => [
  { label: '当前订单', value: formatNumber(orders.value.length), hint: orderFilterLabel.value },
  { label: '待付款', value: formatNumber(dashboard.metrics.pending_orders || 0), hint: '需要催付', action: () => openOrderQueue('pending') },
  { label: '待发货', value: formatNumber(dashboard.metrics.paid_orders || 0), hint: '尽快履约', action: () => openOrderQueue('paid') },
  { label: '售后', value: formatNumber(dashboard.metrics.after_sale_orders || 0), hint: '需要处理', action: () => openOrderQueue('after_sale') },
])
const userSummaryCards = computed(() => [
  { label: '当前用户', value: formatNumber(users.value.length), hint: '列表结果' },
  { label: '启用账号', value: formatNumber(users.value.filter(item => item.is_active).length), hint: '可登录' },
  { label: '会员用户', value: formatNumber(users.value.filter(item => item.vip_level && item.vip_level !== 'none').length), hint: '非普通等级' },
  { label: '消费合计', value: money(sumBy(users.value, item => item.total_spent)), hint: '累计贡献' },
])
const contentSummaryCards = computed(() => [
  { label: '当前模块', value: currentContentLabel.value, hint: '正在维护' },
  { label: '当前内容', value: formatNumber(currentContentRows.value.length), hint: '列表结果' },
  { label: '已启用', value: formatNumber(currentContentEnabledCount.value), hint: contentKind.value === 'media' ? '素材总量' : '前台可见' },
  { label: contentKind.value === 'media' ? '素材文件' : '关联商品', value: formatNumber(contentKind.value === 'media' ? media.value.length : currentContentProductCount.value), hint: contentKind.value === 'media' ? '图片资源' : '内容绑定' },
])
const couponSummaryCards = computed(() => [
  { label: '当前优惠券', value: formatNumber(coupons.value.length), hint: couponFilterLabel.value },
  { label: '可用', value: formatNumber(coupons.value.filter(item => item.status === 'available').length), hint: '可核销', action: () => openCouponQueue('available') },
  { label: '已使用', value: formatNumber(coupons.value.filter(item => item.status === 'used').length), hint: '已核销', action: () => openCouponQueue('used') },
  { label: '面额合计', value: `¥${formatNumber(sumBy(coupons.value, item => item.value))}`, hint: '当前结果' },
])
const shopSummaryCards = computed(() => [
  { label: '店铺评分', value: shopForm.score || '-', hint: '前台展示' },
  { label: '商品数', value: formatNumber(shopForm.product_count || 0), hint: '展示口径' },
  { label: '销售额', value: shopForm.sales || '-', hint: '展示文本' },
  { label: '粉丝数', value: shopForm.fans_count || '-', hint: '展示文本' },
])

const productStatusOptions = [
  { label: '全部', value: '' },
  { label: '上架', value: 'active' },
  { label: '下架', value: 'inactive' },
]
const productStockOptions = [
  { label: '低库存', value: 'low' },
]
const orderStatusOptions = [
  { label: '全部', value: '' },
  { label: '待付款', value: 'pending' },
  { label: '待发货', value: 'paid' },
  { label: '待收货', value: 'shipped' },
  { label: '已完成', value: 'completed' },
  { label: '售后', value: 'after_sale' },
]
const contentKindOptions = [
  { label: '一级分类', value: 'categories' },
  { label: '二级分类', value: 'subcategories' },
  { label: '首页 Banner', value: 'banners' },
  { label: '限时秒杀', value: 'flashSales' },
  { label: '热销榜', value: 'hotRanks' },
  { label: '新品上市', value: 'newArrivals' },
  { label: '为你推荐', value: 'recommends' },
  { label: '促销位', value: 'promotions' },
  { label: '素材库', value: 'media' },
]
const couponStatusOptions = [
  { label: '全部', value: '' },
  { label: '可用', value: 'available' },
  { label: '已使用', value: 'used' },
  { label: '已失效', value: 'expired' },
]
const orderRawStatuses = [
  { label: '待付款', value: 'pending' },
  { label: '待发货', value: 'paid' },
  { label: '待收货', value: 'shipped' },
  { label: '已完成', value: 'completed' },
  { label: '已取消', value: 'cancelled' },
]
const afterSaleStatuses = [
  { label: '未申请', value: 'none' },
  { label: '已申请', value: 'requested' },
  { label: '处理中', value: 'processing' },
  { label: '已退款', value: 'refunded' },
  { label: '已拒绝', value: 'rejected' },
]
const couponRawStatuses = [
  { label: '可用', value: 'available' },
  { label: '已使用', value: 'used' },
  { label: '已失效', value: 'expired' },
]
const vipLevels = [
  { label: '普通会员', value: 'none' },
  { label: '铜牌会员', value: 'bronze' },
  { label: '银牌会员', value: 'silver' },
  { label: '黄金会员', value: 'gold' },
  { label: '钻石会员', value: 'diamond' },
]

watch(contentKind, () => {
  if (activeView.value === 'content') loadContent()
})

watch(isSidebarCollapsed, (value) => {
  localStorage.setItem(SIDEBAR_COLLAPSED_KEY, value ? 'true' : 'false')
  window.setTimeout(() => {
    orderChart?.resize()
    salesChart?.resize()
  }, 180)
})

onMounted(async () => {
  window.addEventListener('resize', syncViewport)
  syncViewport()
  if (isAuthed.value) await bootstrap()
})

onUnmounted(() => {
  window.removeEventListener('resize', syncViewport)
})

async function run(task) {
  loading.value = true
  try {
    return await task()
  } catch (error) {
    ElMessage.error(error.message || '操作失败')
    if (error.message?.includes('登录')) {
      isAuthed.value = false
    }
  } finally {
    loading.value = false
  }
}

async function login() {
  if (!loginForm.username || !loginForm.password) {
    ElMessage.warning('请输入管理员账号和密码')
    return
  }
  await run(async () => {
    const data = await adminApi.login(loginForm.username, loginForm.password)
    setToken(data.token)
    isAuthed.value = true
    await bootstrap()
    ElMessage.success('已进入后台')
  })
}

function logout() {
  clearToken()
  isAuthed.value = false
}

async function bootstrap() {
  await loadMeta()
  await loadCurrentView()
}

async function loadMeta() {
  const [categoryData, subcategoryData, mediaData, productData] = await Promise.all([
    adminApi.categories(),
    adminApi.subcategories(),
    adminApi.media(),
    adminApi.products(),
  ])
  categories.value = categoryData || []
  subcategories.value = subcategoryData || []
  media.value = mediaData || []
  products.value = productData.items || []
}

async function switchView(view) {
  activeView.value = view
  localStorage.setItem(ACTIVE_VIEW_KEY, view)
  keyword.value = ''
  await loadCurrentView()
  if (isCompactViewport.value) isSidebarCollapsed.value = true
}

async function loadCurrentView() {
  const loaders = {
    dashboard: loadDashboard,
    products: loadProducts,
    orders: loadOrders,
    users: loadUsers,
    content: loadContent,
    coupons: loadCoupons,
    shop: loadShop,
  }
  const loader = loaders[activeView.value] || loadDashboard
  const result = await run(loader)
  lastSyncedAt.value = new Date()
  return result
}

function toggleSidebar() {
  isSidebarCollapsed.value = !isSidebarCollapsed.value
}

function syncViewport() {
  if (typeof window === 'undefined') return
  const nextCompact = window.innerWidth <= 900
  const enteredCompact = nextCompact && !isCompactViewport.value
  isCompactViewport.value = nextCompact
  if (enteredCompact) isSidebarCollapsed.value = true
  window.setTimeout(() => {
    orderChart?.resize()
    salesChart?.resize()
  }, 180)
}

async function handleQuickCreate(command) {
  if (command === 'product') {
    await switchView('products')
    openProduct()
  } else if (command === 'banner') {
    contentKind.value = 'banners'
    await switchView('content')
    openBanner()
  } else if (command === 'coupon') {
    await switchView('coupons')
    openCoupon()
  } else if (command === 'media') {
    contentKind.value = 'media'
    await switchView('content')
    await nextTick()
    mediaInput.value?.click()
  }
}

async function loadDashboard() {
  const data = await adminApi.overview()
  dashboard.metrics = data.metrics || {}
  dashboard.orderStatus = data.order_status || {}
  dashboard.salesTrend = data.sales_trend || []
  dashboard.contentHealth = data.content_health || {}
  dashboard.recentOrders = data.recent_orders || []
  dashboard.topProducts = data.top_products || []
  dashboard.lowStockProducts = data.low_stock_products || []
  await nextTick()
  renderOrderChart()
  renderSalesChart()
  window.setTimeout(() => {
    renderOrderChart()
    renderSalesChart()
    orderChart?.resize()
    salesChart?.resize()
  }, 160)
}

function renderOrderChart() {
  if (!canRenderChart(orderChartRef.value)) return
  orderChart ||= echarts.init(orderChartRef.value)
  const compact = orderChartRef.value.clientWidth < 520
  const data = orderRawStatuses.map(item => ({
    name: item.label,
    value: dashboard.orderStatus[item.value] || 0,
  }))
  orderChart.setOption({
    color: ['#2563EB', '#16975B', '#C98212', '#69717F', '#D43D35'],
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, icon: 'circle', itemWidth: compact ? 8 : 10, itemHeight: compact ? 8 : 10 },
    series: [{
      type: 'pie',
      radius: compact ? ['48%', '70%'] : ['48%', '72%'],
      center: compact ? ['50%', '42%'] : ['50%', '44%'],
      avoidLabelOverlap: true,
      minAngle: 6,
      label: compact ? { show: false } : { formatter: '{b} {c}' },
      data,
    }],
  })
  orderChart.resize()
}

function renderSalesChart() {
  if (!canRenderChart(salesChartRef.value)) return
  salesChart ||= echarts.init(salesChartRef.value)
  const compact = salesChartRef.value.clientWidth < 520
  const rows = dashboard.salesTrend || []
  salesChart.setOption({
    color: ['#2563EB', '#FF6B4A'],
    tooltip: { trigger: 'axis' },
    grid: { left: compact ? 34 : 44, right: compact ? 8 : 18, top: compact ? 34 : 28, bottom: 34 },
    legend: { top: 0, right: compact ? 0 : 4, itemWidth: compact ? 12 : 18 },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: rows.map(item => item.label),
      axisLine: { lineStyle: { color: '#E1E6EF' } },
      axisTick: { show: false },
      axisLabel: { interval: compact ? 1 : 0 },
    },
    yAxis: [
      { type: 'value', name: 'GMV', axisLabel: { formatter: value => `${value}` }, splitLine: { lineStyle: { color: '#EDF0F5' } } },
      { type: 'value', name: '订单', splitLine: { show: false } },
    ],
    series: [
      {
        name: 'GMV',
        type: 'line',
        smooth: true,
        areaStyle: { color: 'rgba(37, 99, 235, 0.08)' },
        data: rows.map(item => Number(item.revenue || 0)),
      },
      {
        name: '订单',
        type: 'bar',
        yAxisIndex: 1,
        barWidth: compact ? 10 : 16,
        data: rows.map(item => Number(item.orders || 0)),
      },
    ],
  })
  salesChart.resize()
}

function canRenderChart(element) {
  return activeView.value === 'dashboard' && element && element.clientWidth > 0 && element.clientHeight > 0
}

async function loadProducts() {
  const data = await adminApi.products({
    q: keyword.value,
    status: productStatus.value,
    category: productCategory.value,
    stock: productStock.value,
  })
  products.value = data.items || []
  selectedProducts.value = []
}

async function loadOrders() {
  const data = await adminApi.orders({ q: keyword.value, status: orderStatus.value })
  orders.value = data.items || []
}

async function loadUsers() {
  const data = await adminApi.users({ q: keyword.value })
  users.value = data.items || []
}

async function loadContent() {
  if (contentKind.value === 'categories') categories.value = await adminApi.categories()
  else if (contentKind.value === 'subcategories') subcategories.value = await adminApi.subcategories()
  else if (contentKind.value === 'banners') banners.value = await adminApi.banners()
  else if (contentKind.value === 'flashSales') homeFlashSales.value = await adminApi.homeFlashSales()
  else if (contentKind.value === 'hotRanks') homeHotRanks.value = await adminApi.homeHotRanks()
  else if (contentKind.value === 'recommends') homeRecommends.value = await adminApi.homeRecommends()
  else if (contentKind.value === 'newArrivals') homeNewArrivals.value = await adminApi.homeNewArrivals()
  else if (contentKind.value === 'promotions') promotions.value = await adminApi.homePromotions()
  else if (contentKind.value === 'media') media.value = await adminApi.media()
}

async function loadCoupons() {
  const data = await adminApi.coupons({ q: keyword.value, status: couponStatus.value })
  coupons.value = data.items || []
}

async function loadShop() {
  const data = await adminApi.shop()
  Object.assign(shopForm, {
    ...data,
    score: Number(data?.score || 0),
    product_count: Number(data?.product_count || 0),
  })
}

async function openOrderQueue(status) {
  orderStatus.value = status
  await switchView('orders')
}

async function openProductFilter({ status = '', stock = '', category = '' } = {}) {
  productStatus.value = status
  productStock.value = stock
  productCategory.value = category
  await switchView('products')
}

async function openInventoryRisk() {
  await openProductFilter({ status: 'active', stock: 'low' })
}

async function openCouponQueue(status) {
  couponStatus.value = status
  await switchView('coupons')
}

async function openContentHealth(kind = 'banners') {
  contentKind.value = kind
  await switchView('content')
}

async function openProductFromDashboard(row) {
  await switchView('products')
  const fresh = products.value.find(item => item.id === row.id) || row
  openProduct(fresh)
}

function openProduct(row = null) {
  Object.assign(productForm, {
    id: row?.id || '',
    name: row?.name || '',
    description: row?.description || '',
    tag: row?.tag || '',
    price: Number(row?.price || 0),
    original_price: Number(row?.original_price || 0),
    sales_count: Number(row?.sales_count || 0),
    rating: Number(row?.rating || 5),
    subcategory_id: row?.subcategory_id || '',
    image_id: row?.image_id || '',
    is_in_stock: row ? Boolean(row.is_in_stock) : true,
    spec_groups: cloneSpecGroups(row?.spec_groups || []),
    skus: cloneSkus(row?.skus || [], row || {}),
  })
  productDrawer.value = true
}

async function saveProduct() {
  await run(async () => {
    if (!productForm.name) throw new Error('商品名称不能为空')
    const payload = buildProductPayload()
    if (!payload.original_price) payload.original_price = ''
    if (productForm.id) {
      await adminApi.updateProduct(productForm.id, payload)
    } else {
      await adminApi.createProduct(payload)
    }
    productDrawer.value = false
    await loadProducts()
    ElMessage.success('商品已保存')
  })
}

async function bulkSetProductStatus(isInStock) {
  const actionText = isInStock ? '上架' : '下架'
  await ElMessageBox.confirm(`确认${actionText}选中的 ${selectedProducts.value.length} 个商品？`, '批量操作', { type: 'warning' })
  await run(async () => {
    await adminApi.bulkProductStatus(selectedProducts.value.map(item => item.id), isInStock)
    await loadProducts()
    await loadDashboard()
    ElMessage.success(`已批量${actionText}`)
  })
}

async function toggleProduct(row) {
  await run(async () => {
    await adminApi.toggleProduct(row.id)
    await loadProducts()
    ElMessage.success(row.is_in_stock ? '商品已下架' : '商品已上架')
  })
}

function cloneSpecGroups(groups) {
  return groups.map((group, groupIndex) => ({
    id: group.id || '',
    local_id: group.id || makeTempId('group'),
    name: group.name || '',
    sort_order: Number(group.sort_order ?? groupIndex),
    draft: '',
    values: (group.values || []).map((value, valueIndex) => ({
      id: value.id || '',
      client_id: value.client_id || value.id || makeTempId('value'),
      local_id: value.id || value.client_id || makeTempId('value'),
      value: value.value || '',
      image_id: value.image_id || '',
      sort_order: Number(value.sort_order ?? valueIndex),
    })),
  }))
}

function cloneSkus(skus, product = {}) {
  return skus.map(sku => ({
    id: sku.id || '',
    spec_value_ids: [...(sku.spec_value_ids || [])],
    spec_text: sku.spec_text || '',
    price: Number(sku.price || product.price || 0),
    original_price: Number(sku.original_price || product.original_price || 0),
    stock: Number(sku.stock || 0),
    image_id: sku.image_id || '',
  }))
}

function addSpecGroup() {
  productForm.spec_groups ||= []
  productForm.spec_groups.push({
    id: '',
    local_id: makeTempId('group'),
    name: '',
    sort_order: productForm.spec_groups.length,
    draft: '',
    values: [],
  })
}

function removeSpecGroup(index) {
  productForm.spec_groups.splice(index, 1)
  rebuildSkuRows()
}

function addSpecValue(groupIndex) {
  const group = productForm.spec_groups[groupIndex]
  const text = (group?.draft || '').trim()
  if (!text) return
  if (group.values.some(item => item.value === text)) {
    group.draft = ''
    return
  }
  const clientId = makeTempId('value')
  group.values.push({
    id: clientId,
    client_id: clientId,
    local_id: clientId,
    value: text,
    image_id: '',
    sort_order: group.values.length,
  })
  group.draft = ''
  rebuildSkuRows()
}

function removeSpecValue(groupIndex, valueIndex) {
  productForm.spec_groups[groupIndex].values.splice(valueIndex, 1)
  rebuildSkuRows()
}

function rebuildSkuRows() {
  const groups = (productForm.spec_groups || []).filter(group => group.name?.trim() && group.values?.length)
  if (!groups.length || groups.some(group => !group.values.length)) {
    productForm.skus = []
    return
  }

  const existing = new Map((productForm.skus || []).map(sku => [skuKey(sku.spec_value_ids), sku]))
  const combinations = buildCombinations(groups)
  productForm.skus = combinations.map(combo => {
    const old = existing.get(skuKey(combo.ids))
    return {
      id: old?.id || '',
      spec_value_ids: combo.ids,
      spec_text: combo.text,
      price: Number(old?.price ?? productForm.price ?? 0),
      original_price: Number(old?.original_price ?? productForm.original_price ?? 0),
      stock: Number(old?.stock ?? 99),
      image_id: old?.image_id || '',
    }
  })
}

function buildCombinations(groups) {
  return groups.reduce((rows, group) => {
    const values = group.values.filter(item => item.value?.trim())
    return rows.flatMap(row => values.map(value => ({
      ids: [...row.ids, value.id || value.client_id],
      labels: [...row.labels, value.value],
    })))
  }, [{ ids: [], labels: [] }]).map(row => ({ ...row, text: row.labels.join(' / ') }))
}

function skuKey(ids) {
  return (ids || []).join('|')
}

function makeTempId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(16).slice(2)}`
}

function buildProductPayload() {
  return {
    id: productForm.id,
    name: productForm.name,
    description: productForm.description,
    tag: productForm.tag,
    price: productForm.price,
    original_price: productForm.original_price,
    sales_count: productForm.sales_count,
    rating: productForm.rating,
    subcategory_id: productForm.subcategory_id,
    image_id: productForm.image_id,
    is_in_stock: productForm.is_in_stock,
    spec_groups: (productForm.spec_groups || []).map((group, groupIndex) => ({
      id: group.id || '',
      name: group.name,
      sort_order: groupIndex,
      values: (group.values || []).map((value, valueIndex) => ({
        id: value.id || '',
        client_id: value.client_id || value.id || '',
        value: value.value,
        image_id: value.image_id || '',
        sort_order: valueIndex,
      })),
    })),
    skus: (productForm.skus || []).map(sku => ({
      id: sku.id || '',
      spec_value_ids: sku.spec_value_ids || [],
      price: sku.price,
      original_price: sku.original_price || '',
      stock: sku.stock,
      image_id: sku.image_id || '',
    })),
  }
}

function openContent() {
  if (contentKind.value === 'media') {
    mediaInput.value?.click()
  } else if (contentKind.value === 'categories') openCategory()
  else if (contentKind.value === 'subcategories') openSubcategory()
  else if (contentKind.value === 'banners') openBanner()
  else if (isHomeProductSection.value) openHomeSection()
  else if (contentKind.value === 'promotions') openPromotion()
}

function openCategory(row = null) {
  Object.assign(categoryForm, {
    id: row?.id || '',
    name: row?.name || '',
    sort_order: Number(row?.sort_order || 0),
    icon_id: row?.icon_id || '',
    banner_id: row?.banner_id || '',
    is_enabled: row ? Boolean(row.is_enabled) : true,
  })
  contentDrawer.value = true
}

function openSubcategory(row = null) {
  Object.assign(subcategoryForm, {
    id: row?.id || '',
    name: row?.name || '',
    category_id: row?.category_id || categories.value[0]?.id || '',
    sort_order: Number(row?.sort_order || 0),
    icon_id: row?.icon_id || '',
    is_enabled: row ? Boolean(row.is_enabled) : true,
  })
  contentDrawer.value = true
}

function openBanner(row = null) {
  Object.assign(bannerForm, {
    id: row?.id || '',
    tag: row?.tag || '',
    title: row?.title || '',
    action_title: row?.action_title || '',
    link: row?.link || 'category.html',
    landing_badge: row?.landing_badge || '',
    landing_subtitle: row?.landing_subtitle || '',
    landing_description: row?.landing_description || '',
    gradient_type: Number(row?.gradient_type || 0),
    sort_order: Number(row?.sort_order || 0),
    image_id: row?.image_id || '',
    product_ids: row?.product_ids || [],
    is_enabled: row ? Boolean(row.is_enabled) : true,
  })
  contentDrawer.value = true
}

function openHomeSection(row = null) {
  const defaultTitles = {
    flashSales: '限时秒杀',
    hotRanks: '热销榜单',
    recommends: '为你推荐',
    newArrivals: '新品上市',
  }
  Object.assign(homeSectionForm, {
    id: row?.id || '',
    title: row?.title || defaultTitles[contentKind.value] || '',
    subtitle: row?.subtitle || '',
    start_time: row?.start_time || '',
    end_time: row?.end_time || '',
    sort_order: Number(row?.sort_order || 0),
    product_ids: row?.product_ids || [],
    is_enabled: row ? Boolean(row.is_enabled) : true,
  })
  contentDrawer.value = true
}

function openPromotion(row = null) {
  Object.assign(promotionForm, {
    id: row?.id || '',
    title: row?.title || '优惠活动',
    subtitle: row?.subtitle || '',
    link: row?.link || 'category.html',
    image_id: row?.image_id || '',
    sort_order: Number(row?.sort_order || 0),
    is_enabled: row ? Boolean(row.is_enabled) : true,
  })
  contentDrawer.value = true
}

async function saveContent() {
  await run(async () => {
    if (contentKind.value === 'categories') {
      if (!categoryForm.name) throw new Error('分类名称不能为空')
      categoryForm.id ? await adminApi.updateCategory(categoryForm.id, categoryForm) : await adminApi.createCategory(categoryForm)
    } else if (contentKind.value === 'subcategories') {
      if (!subcategoryForm.name || !subcategoryForm.category_id) throw new Error('子分类名称和所属分类不能为空')
      subcategoryForm.id ? await adminApi.updateSubcategory(subcategoryForm.id, subcategoryForm) : await adminApi.createSubcategory(subcategoryForm)
    } else if (contentKind.value === 'banners') {
      bannerForm.id ? await adminApi.updateBanner(bannerForm.id, bannerForm) : await adminApi.createBanner(bannerForm)
    } else if (isHomeProductSection.value) {
      await saveHomeSection()
    } else if (contentKind.value === 'promotions') {
      if (!promotionForm.title) throw new Error('促销位标题不能为空')
      promotionForm.id ? await adminApi.updateHomePromotion(promotionForm.id, promotionForm) : await adminApi.createHomePromotion(promotionForm)
    }
    contentDrawer.value = false
    await loadContent()
    ElMessage.success('内容已保存')
  })
}

async function saveHomeSection() {
  if (!homeSectionForm.title) throw new Error('栏目标题不能为空')
  const apiMap = {
    flashSales: [adminApi.createHomeFlashSale, adminApi.updateHomeFlashSale],
    hotRanks: [adminApi.createHomeHotRank, adminApi.updateHomeHotRank],
    recommends: [adminApi.createHomeRecommend, adminApi.updateHomeRecommend],
    newArrivals: [adminApi.createHomeNewArrival, adminApi.updateHomeNewArrival],
  }
  const [createFn, updateFn] = apiMap[contentKind.value]
  homeSectionForm.id ? await updateFn(homeSectionForm.id, homeSectionForm) : await createFn(homeSectionForm)
}

async function uploadMediaFromInput(event) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file) return
  await run(async () => {
    const dataUrl = await fileToDataUrl(file)
    await adminApi.uploadMedia({ file: dataUrl, name: file.name })
    media.value = await adminApi.media()
    ElMessage.success('素材已上传')
  })
}

function fileToDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = () => reject(new Error('素材读取失败'))
    reader.readAsDataURL(file)
  })
}

async function markPaid(row) {
  await run(async () => {
    await adminApi.markPaid(row.id)
    await loadOrders()
    await refreshOrderDetail(row.id)
    await loadDashboard()
    ElMessage.success('订单已标记支付')
  })
}

function openShip(row) {
  editingOrderId.value = row.id
  orderAction.value = 'ship'
  Object.assign(orderForm, { carrier: row.carrier || '顺丰速运', tracking_number: row.tracking_number || '' })
  orderDrawer.value = true
}

function openOrderStatus(row) {
  editingOrderId.value = row.id
  orderAction.value = 'status'
  Object.assign(orderForm, { status: row.status })
  orderDrawer.value = true
}

function openAfterSale(row) {
  editingOrderId.value = row.id
  orderAction.value = 'afterSale'
  Object.assign(orderForm, {
    after_sale_status: row.after_sale_status || 'none',
    after_sale_reason: row.after_sale_reason || '',
  })
  orderDrawer.value = true
}

async function saveOrderAction() {
  await run(async () => {
    if (orderAction.value === 'ship') await adminApi.shipOrder(editingOrderId.value, orderForm)
    else if (orderAction.value === 'status') await adminApi.setOrderStatus(editingOrderId.value, orderForm)
    else await adminApi.updateAfterSale(editingOrderId.value, orderForm)
    orderDrawer.value = false
    await loadOrders()
    await refreshOrderDetail(editingOrderId.value)
    await loadDashboard()
    ElMessage.success('订单已更新')
  })
}

async function openOrderDetail(row) {
  await run(async () => {
    orderDetail.value = await adminApi.order(row.id)
    orderDetailDrawer.value = true
  })
}

async function refreshOrderDetail(id) {
  if (orderDetailDrawer.value && orderDetail.value?.id === id) {
    orderDetail.value = await adminApi.order(id)
  }
}

function openUser(row) {
  Object.assign(userForm, {
    id: row.id,
    email: row.email || '',
    phone: row.phone || '',
    vip_level: row.vip_level || 'none',
    points: Number(row.points || 0),
    is_active: Boolean(row.is_active),
  })
  userDrawer.value = true
}

async function saveUser() {
  await run(async () => {
    await adminApi.updateUser(userForm.id, userForm)
    userDrawer.value = false
    await loadUsers()
    ElMessage.success('用户已保存')
  })
}

function openCoupon(row = null) {
  Object.assign(couponForm, {
    id: row?.id || '',
    username: row?.username || '',
    name: row?.name || '专属优惠券',
    value: Number(row?.value || 20),
    threshold: row?.threshold || '满100可用',
    time: row?.time || '2026-12-31',
    status: row?.status || 'available',
    description: row?.description || '',
  })
  couponDrawer.value = true
}

async function saveCoupon() {
  await run(async () => {
    if (!couponForm.id && !couponForm.username) throw new Error('请输入发券用户名')
    couponForm.id ? await adminApi.updateCoupon(couponForm.id, couponForm) : await adminApi.createCoupon(couponForm)
    couponDrawer.value = false
    await loadCoupons()
    ElMessage.success(couponForm.id ? '优惠券已保存' : '优惠券已发放')
  })
}

async function saveShop() {
  await run(async () => {
    await adminApi.saveShop(shopForm)
    ElMessage.success('店铺资料已保存')
  })
}

function money(value) {
  const number = Number(value || 0)
  return `¥${Number.isFinite(number) ? number.toFixed(2) : '0.00'}`
}

function formatNumber(value) {
  const number = Number(value || 0)
  return Number.isFinite(number) ? number.toLocaleString('zh-CN') : '0'
}

function sumBy(rows, getter) {
  return (rows || []).reduce((total, item) => total + Number(getter(item) || 0), 0)
}

function optionLabel(options, value) {
  return options.find(item => item.value === value)?.label || ''
}

function isLowStockProduct(item) {
  return Number(item.low_stock_count || 0) > 0 || Number(item.stock_total || 0) <= 200
}

function fileSize(value) {
  const size = Number(value || 0)
  if (!Number.isFinite(size) || size <= 0) return '-'
  if (size >= 1024 * 1024) return `${(size / 1024 / 1024).toFixed(1)} MB`
  return `${Math.ceil(size / 1024)} KB`
}

function addressText(order) {
  return [order.address_province, order.address_city, order.address_district, order.address_detail]
    .filter(Boolean)
    .join('')
}

function statusText(status) {
  return {
    pending: '待付款',
    paid: '待发货',
    shipped: '待收货',
    completed: '已完成',
    cancelled: '已取消',
    none: '未申请',
    requested: '已申请',
    processing: '处理中',
    refunded: '已退款',
    rejected: '已拒绝',
    available: '可用',
    used: '已使用',
    expired: '已失效',
  }[status] || status || '-'
}

function statusType(status) {
  return {
    pending: 'warning',
    paid: 'success',
    shipped: 'primary',
    completed: 'info',
    cancelled: 'danger',
  }[status] || 'info'
}

function couponType(status) {
  return {
    available: 'success',
    used: 'info',
    expired: 'danger',
  }[status] || 'info'
}
</script>
