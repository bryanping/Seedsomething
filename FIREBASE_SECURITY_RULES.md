# Firebase Firestore 安全规则

## ⚠️ 重要：地图种草时出现 "missing or insufficient permissions" 错误

这个错误是因为 Firebase Firestore 的安全规则没有允许用户写入 `publicPlantRecords` 集合。

**必须设置此规则才能使用地图种草功能！**

## 🔧 解决方案

### 步骤 1：打开 Firebase Console
1. 访问 https://console.firebase.google.com/
2. 选择你的项目 `seedsomething-62361`
3. 进入 **Firestore Database** → **Rules**（左侧菜单）

### 步骤 2：复制并粘贴以下完整规则

### 1. 打开 Firebase Console
- 访问 https://console.firebase.google.com/
- 选择你的项目 `seedsomething-62361`
- 进入 **Firestore Database** → **Rules**

**⚠️ 重要：请替换整个规则文件内容，不要只添加部分规则！**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户数据规则
    match /users/{userId} {
      // 用户基本信息
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // 用户子集合（data, plantRecords, stores, tasks, achievements, friends, friendInteractions）
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ⚠️ 公共打卡记录集合（所有用户可见，但只能写入自己的记录）
    // 这是地图种草功能必需的规则！
    match /publicPlantRecords/{recordId} {
      // 所有已登录用户都可以读取（用于显示地图上的小草）
      allow read: if request.auth != null;
      
      // 只能创建自己的记录（检查 userId 字段必须等于当前用户ID）
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      
      // 只能更新自己的记录
      allow update: if request.auth != null 
                    && resource.data.userId == request.auth.uid
                    && request.resource.data.userId == request.auth.uid;
      
      // 只能删除自己的记录
      allow delete: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
    }
  }
}
```

### 步骤 3：发布规则
1. 点击 **发布** 按钮（右上角）
2. 等待几秒钟让规则生效
3. 重新运行 App 测试地图种草功能

### 步骤 4：验证规则
- 规则发布后，尝试在地图上种草
- 如果仍然出现权限错误，请检查：
  1. 用户是否已登录
  2. `userId` 字段是否正确包含在记录中
  3. 规则是否正确发布

## 规则说明

1. **publicPlantRecords 读取权限**：所有已登录用户都可以读取，这样地图上可以显示所有用户的打卡记录
2. **publicPlantRecords 写入权限**：用户只能创建、更新或删除自己的记录（通过检查 `userId` 字段）
3. **用户数据权限**：用户只能访问自己的数据

## 注意事项

- 确保用户已登录（`request.auth != null`）
- 确保记录中包含正确的 `userId` 字段
- 如果仍有权限问题，检查 Firebase Authentication 是否正常工作

