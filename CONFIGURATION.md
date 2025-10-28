# Trash2Cash App Configuration Guide

## Backend API Integration

The Trash2Cash mobile app requires a backend server (Wails Go application) to function properly. Follow these steps to configure the connection:

### 1. Server Requirements

Your Wails Go backend should implement the following REST API endpoints:

#### Authentication
- **POST** `/api/auth/qr-login`
  - Body: `{ "token": "qr_token_string" }`
  - Response: `{ "sessionToken": "...", "user": { ... } }`

#### User Management
- **GET** `/api/user/profile`
  - Headers: `Authorization: Bearer <sessionToken>`
  - Response: `{ "id": "...", "name": "...", "points": 1000, ... }`

- **GET** `/api/user/stats`
  - Headers: `Authorization: Bearer <sessionToken>`
  - Response: `{ "totalRecycled": 50.5, "totalTransactions": 25, "co2Saved": 30.2 }`

#### Transactions
- **GET** `/api/transactions?limit=50&offset=0`
  - Headers: `Authorization: Bearer <sessionToken>`
  - Response: `{ "transactions": [ ... ] }`

#### Redemption
- **GET** `/api/redemption/options`
  - Headers: `Authorization: Bearer <sessionToken>`
  - Response: `{ "options": [ { "id": "cash", "name": "Cash", ... } ] }`

- **POST** `/api/redemption/redeem`
  - Headers: `Authorization: Bearer <sessionToken>`
  - Body: `{ "userId": "...", "points": 500, "method": "cash" }`
  - Response: `{ "success": true, "transactionId": "..." }`

#### System
- **GET** `/api/health`
  - Response: `{ "status": "ok" }`

- **POST** `/api/auth/logout`
  - Headers: `Authorization: Bearer <sessionToken>`

#### WebSocket (Optional for Real-time Updates)
- **WS** `/ws?userId=<userId>&token=<sessionToken>`
  - Messages:
    - `{ "type": "transaction", "transaction": { ... } }`
    - `{ "type": "balance_update", "balance": 1500 }`
    - `{ "type": "stats_update", "stats": { ... } }`

### 2. QR Code Format

The QR codes displayed on the Trash2Cash station should contain a session token in one of these formats:

1. Simple token: `abc123def456...`
2. JSON format: `{ "token": "abc123...", "stationId": "station_001" }`
3. URL format: `trash2cash://login?token=abc123...`

The app will extract the token and send it to `/api/auth/qr-login`.

### 3. Network Configuration

#### Local Network (LAN)
For local testing with Raspberry Pi on the same network:

1. Find your Raspberry Pi's IP address:
   ```bash
   hostname -I
   ```

2. In the app, go to **Dashboard → Settings** and enter:
   ```
   http://192.168.1.XXX:8080
   ```

#### Internet Connection
For remote access:

1. Set up port forwarding on your router (port 8080)
2. Use your public IP or domain:
   ```
   http://your-domain.com:8080
   ```
   or
   ```
   https://your-domain.com
   ```

3. **Important**: Use HTTPS for production with proper SSL certificates

### 4. Testing the Connection

1. Open the app
2. Go to the welcome screen
3. Tap the menu icon → Settings
4. Enter your server URL
5. Tap "Test Connection"
6. You should see "✓ Connected" if successful

### 5. CORS Configuration

If your backend is on a different domain, configure CORS headers:

```go
// Example Go code
router.Use(cors.New(cors.Config{
    AllowOrigins:     []string{"*"},
    AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
    AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
    ExposeHeaders:    []string{"Content-Length"},
    AllowCredentials: true,
}))
```

### 6. Security Recommendations

#### Development
- Use HTTP with local IP addresses
- No authentication required for testing

#### Production
- **Always use HTTPS**
- Implement proper session token generation (JWT recommended)
- Token expiration (e.g., 24 hours)
- Rate limiting on API endpoints
- Input validation and sanitization
- Secure WebSocket connections (WSS)

### 7. Example Backend Response Formats

#### User Profile
```json
{
  "id": "user_12345",
  "name": "John Doe",
  "email": "john@example.com",
  "points": 1250,
  "sessionToken": "eyJhbGci...",
  "lastLogin": "2025-10-28T10:30:00Z"
}
```

#### Transaction
```json
{
  "id": "txn_67890",
  "userId": "user_12345",
  "type": "deposit",
  "amount": 50,
  "itemType": "plastic",
  "weight": 0.5,
  "stationId": "station_001",
  "timestamp": "2025-10-28T10:35:00Z",
  "status": "completed"
}
```

#### Redemption Request
```json
{
  "userId": "user_12345",
  "points": 500,
  "method": "cash",
  "additionalData": {
    "bankAccount": "1234567890",
    "notes": "Please transfer to main account"
  }
}
```

### 8. Troubleshooting

#### "Connection Failed"
- Check if the server is running
- Verify the URL is correct (include http:// or https://)
- Check firewall settings
- Ensure the device is on the same network (for LAN)

#### "Login Failed"
- Verify QR code contains valid token
- Check backend logs for authentication errors
- Ensure session token is being returned

#### "No Data Displayed"
- Check API endpoint responses
- Verify JSON format matches expected schema
- Check console logs in the app

### 9. Default Configuration

The app ships with these defaults:
- Base URL: `http://192.168.1.100:8080`
- Connection timeout: 5 seconds
- Points to cash ratio: 100 points = $1.00

You can modify these in the code:
- `lib/services/api_service.dart` - Base URL
- `lib/screens/dashboard_screen.dart` - Points calculation

### 10. Environment-Specific Builds

For different environments (dev/staging/prod), you can:

1. Create separate configuration files:
   ```dart
   // lib/config/environment.dart
   class Environment {
     static const String apiUrl = String.fromEnvironment(
       'API_URL',
       defaultValue: 'http://192.168.1.100:8080',
     );
   }
   ```

2. Build with environment variables:
   ```bash
   flutter build apk --dart-define=API_URL=https://api.trash2cash.com
   ```

## Need Help?

For backend implementation examples or additional support, refer to the main Trash2Cash documentation or contact the development team.
