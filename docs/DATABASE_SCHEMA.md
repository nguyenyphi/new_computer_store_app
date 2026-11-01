# 📚 TÀI LIỆU CSDL NGUYENYPHI_1669_DB (SQL SERVER)

### 📌 THÔNG TIN KẾT NỐI
- **Server:** `127.0.0.1,1434` (Docker Container: `ltdd-sql`)
- **Database:** `nguyenyphi_1669_DB`
- **Username:** `sa`
- **Password:** `SqlServer@123456`
- **ORM:** Entity Framework Core 8.0 Code First

---

## 🗄️ DANH SÁCH 17 BẢNG DỮ LIỆU ĐÃ TẠO VÀ SEED

1. **`Users`**: Tài khoản người dùng (FullName, Email, Username, PasswordHash BCrypt, PhoneNumber, IsActive, EmailConfirmed, RoleId).
2. **`Roles`**: Phân quyền (`Admin`, `Teacher`, `Student`).
3. **`Students`**: Hồ sơ sinh viên (`StudentCode` ví dụ `2380601669`, Faculty, AcademicYear).
4. **`Teachers`**: Hồ sơ giảng viên (`TeacherCode` ví dụ `GV001`, Department, AcademicDegree).
5. **`Subjects`**: Môn học (`SubjectCode`, `SubjectName`, `Credits`, Description, IsActive).
6. **`ClassRooms`**: Lớp học phần (`ClassCode` ví dụ `23DTH01`, RoomName, Latitude, Longitude, AllowedRadiusMeters = 50m).
7. **`Enrollments`**: Ghi danh sinh viên vào lớp học (`ClassRoomId`, `StudentId`, EnrolledAt).
8. **`TeacherAssignments`**: Phân công giảng dạy (`TeacherId`, `ClassRoomId`).
9. **`AttendanceSessions`**: Buổi điểm danh (`ClassRoomId`, StartTime, EndTime, IsOpen, CurrentQrToken, QrRotateIntervalSeconds = 15s, Latitude, Longitude, AllowedRadiusMeters, RequireGps).
10. **`AttendanceRecords`**: Bản ghi điểm danh (`AttendanceSessionId`, `StudentId`, CheckedInAt, Status = Present/Late/Excused/Absent, VerificationMethod, DistanceMeters, DeviceId, IsModifiedByTeacher, EditReason).
11. **`OtpCodes`**: Mã OTP 6 chữ số lưu băm SHA-256 (`UserId`, CodeHash, Purpose, ExpiresAt, IsUsed, FailedAttempts).
12. **`RefreshTokens`**: Quản lý phiên JWT (`UserId`, Token, ExpiresAt, IsRevoked).
13. **`Notifications`**: Thông báo người dùng (`UserId`, Title, Content, Type, IsRead).
14. **`AuditLogs`**: Lịch sử kiểm toán bảo mật (`UserId`, Username, Action, EntityName, Details, IpAddress, Timestamp).
15. **`DeviceRegistrations`**: Đăng ký thiết bị di động (`UserId`, DeviceIdentifier, DeviceModel, BiometricEnabled, LastUsedAt).
16. **`VideoMeetings`**: Phòng họp video WebRTC / Jitsi (`ClassRoomId`, RoomName, MeetingCode, HostUserId, IsActive).
17. **`AttendanceAlerts`**: Cảnh báo điểm danh gian lận Smart Attendance Guard (`AttendanceSessionId`, `StudentId`, AlertType, Description, AttemptedDistanceMeters, DeviceId, IsReviewedByTeacher, ReviewDecision).

---

## 💾 HƯỚNG DẪN BACKUP VÀ RESTORE CSDL

### 1. Xuất file SQL DDL:
File SQL hoàn chỉnh đã được xuất tại:
`nguyenyphi_1669/database/nguyenyphi_1669_DB.sql`

### 2. Backup bằng lệnh `sqlcmd`:
```bash
docker exec ltdd-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'SqlServer@123456' -C -Q "BACKUP DATABASE [nguyenyphi_1669_DB] TO DISK = '/var/opt/mssql/data/nguyenyphi_1669_DB.bak';"
```

### 3. Restore CSDL:
```bash
docker exec ltdd-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'SqlServer@123456' -C -Q "RESTORE DATABASE [nguyenyphi_1669_DB] FROM DISK = '/var/opt/mssql/data/nguyenyphi_1669_DB.bak' WITH REPLACE;"
```
