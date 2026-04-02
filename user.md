# 用户接口

## 验证密码

> 需要登录后访问。输入启动密码或解绑密码，返回密码类型及对应数据。

| 接口路径 | 请求方法 |
| :--- | :--- |
| `/x/user/verify-password` | `POST` |

### 请求参数

| 参数名 | 类型 | 必选 | 说明 |
| :--- | :--- | :--- | :--- |
| `password` | `string` | 是 | 明文密码（启动密码或解绑密码） |

### 响应数据

| 参数名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `type` | `string` | 密码类型：`start`-启动密码，`unbind`-解绑密码 |
| `deviceCode` | `string` | 加密后的设备编码，仅 `type=start` 时返回 |

> `deviceCode` 使用 AES 加密，内容为 JSON 结构：`{"messageType":"conn","content":{"type":"device","id":"<设备编码>"}}`

### 示例

**输入启动密码：**

```json
// 请求
{ "password": "123456" }

// 响应
{
  "type": "start",
  "deviceCode": "a1b2c3d4..."
}
```

**输入解绑密码：**

```json
// 请求
{ "password": "abcdef" }

// 响应
{
  "type": "unbind"
}
```
