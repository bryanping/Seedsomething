# Firebase Firestore 复合索引设置

## ⚠️ 重要：地图查询需要创建复合索引

当你在控制台看到以下错误时：
```
The query requires an index. You can create it here: [URL]
```

这表示 Firestore 需要为地理位置查询创建复合索引。

## 🔧 解决方案

### 方法 1：点击错误信息中的链接（推荐）

1. 在 Xcode 控制台中，找到包含 `create_composite` 的 URL
2. 复制完整的 URL
3. 在浏览器中打开该 URL
4. Firebase Console 会自动打开并显示需要创建的索引
5. 点击 **创建索引** 按钮
6. 等待索引创建完成（通常需要几分钟）

### 方法 2：手动在 Firebase Console 创建

1. 访问 Firebase Console：https://console.firebase.google.com/
2. 选择项目：`seedsomething-62361`
3. 进入 **Firestore Database** → **Indexes**（索引）
4. 点击 **创建索引**
5. 设置以下字段：
   - **集合 ID**: `publicPlantRecords`
   - **字段 1**: `coordinate.latitude` - 升序 (Ascending)
   - **字段 2**: `coordinate.longitude` - 升序 (Ascending)
   - **查询范围**: 集合
6. 点击 **创建**

### 方法 3：使用 firestore.indexes.json（如果项目中有）

如果项目根目录有 `firestore.indexes.json` 文件，可以添加以下配置：

```json
{
  "indexes": [
    {
      "collectionGroup": "publicPlantRecords",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "coordinate.latitude",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "coordinate.longitude",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

然后运行：
```bash
firebase deploy --only firestore:indexes
```

## 📋 索引说明

这个复合索引允许 Firestore 高效地查询：
- `coordinate.latitude` 在某个范围内
- `coordinate.longitude` 在某个范围内

这对于地图上的地理位置查询是必需的。

## ⏱️ 索引创建时间

- 索引创建通常需要 **1-5 分钟**
- 创建完成后，地图查询将正常工作
- 在索引创建期间，地图可能无法显示打卡记录

## ✅ 验证索引

索引创建完成后：
1. 重新运行 App
2. 打开地图页面
3. 应该能看到附近的打卡记录图标（绿色叶子图标）

## 🔍 调试提示

如果索引已创建但仍无法看到图标，检查：
1. 控制台是否有其他错误信息
2. `allUsersPlantRecords` 数组是否有数据（查看控制台日志）
3. 坐标是否有效（不是 0,0）
4. 地图中心是否在数据范围内




