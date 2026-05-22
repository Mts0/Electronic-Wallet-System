# Electronic Wallet System

## Overview

The Electronic Wallet System is a secure digital payment platform that enables users to manage their financial transactions online through a web or mobile application. The system allows users to create accounts, store wallet balances, transfer money, pay bills, and monitor transaction history in real time.

The project is designed to provide a fast, reliable, and user-friendly financial solution while maintaining high security standards for digital transactions.

---

# Features

## User Features

- User registration and authentication
- Secure login and logout system
- Wallet balance management
- Deposit and withdrawal operations
- Send and receive money between users
- Transaction history tracking
- Profile management
- Password reset and account recovery
- Real-time transaction updates
- QR code payment support (optional)
- Notifications for transactions and activities

## Admin Features

- Admin dashboard
- User management
- Transaction monitoring
- Wallet activity tracking
- System analytics and reports
- Fraud detection and monitoring
- Account suspension and verification

---

# System Architecture

The system follows a modular architecture that separates the frontend, backend, database, and security layers.

## Main Components

### Frontend
Responsible for the user interface and user experience.

### Backend
Handles business logic, authentication, APIs, and transaction processing.

### Database
Stores user accounts, wallet balances, transactions, and system logs.

### Security Layer
Provides encryption, authentication, authorization, and transaction protection.

---

# Technologies Used

## Frontend
- HTML5
- CSS3
- JavaScript
- Flutter (for mobile application)

## Backend
- Python
- FastAPI
## Database
- PostgreSQL

## Security
- JWT Authentication
- Password Hashing
- OTP Verification

## Tools & Services
- Git & GitHub
- Postman

---

# Project Structure

```bash
ElectronicWalletSystem/
│
├── backend/
│   ├── api/
│   ├── models/
│   ├── services/
│   ├── database/
│   ├── auth/
│   └── main.py
│
├── frontend/
│   ├── assets/
│   ├── pages/
│   ├── components/
│   └── app.js
│
├── mobile_app/
│   ├── lib/
│   ├── screens/
│   └── main.dart
│
├── docs/
├── requirements.txt
├── README.md
```

---

# Database Design

## Main Tables

### Users Table
| Field | Type | Description |
|------|------|-------------|
| id | INT | Unique user ID |
| full_name | VARCHAR | User full name |
| email | VARCHAR | User email |
| password | VARCHAR | Encrypted password |
| created_at | DATETIME | Account creation date |

### Wallets Table
| Field | Type | Description |
|------|------|-------------|
| wallet_id | INT | Wallet ID |
| user_id | INT | Owner user ID |
| balance | DECIMAL | Current balance |

### Transactions Table
| Field | Type | Description |
|------|------|-------------|
| transaction_id | INT | Transaction ID |
| sender_id | INT | Sender user |
| receiver_id | INT | Receiver user |
| amount | DECIMAL | Transaction amount |
| status | VARCHAR | Transaction status |
| created_at | DATETIME | Transaction date |

---

# API Endpoints

## Authentication

| Method | Endpoint | Description |
|--------|-----------|-------------|
| POST | /register | Create new account |
| POST | /login | User login |
| POST | /logout | User logout |

## Wallet Operations

| Method | Endpoint | Description |
|--------|-----------|-------------|
| GET | /wallet | Get wallet balance |
| POST | /deposit | Deposit money |
| POST | /withdraw | Withdraw money |
| POST | /transfer | Transfer money |

## Transactions

| Method | Endpoint | Description |
|--------|-----------|-------------|
| GET | /transactions | Get transaction history |
| GET | /transaction/{id} | Get transaction details |

---

# Security Features

- JWT-based authentication
- Password hashing with bcrypt
- HTTPS encryption
- OTP verification for sensitive operations
- Role-based access control
- Secure API validation
- Protection against SQL Injection and XSS
- Transaction logging and monitoring

---

# Installation

## Clone the Repository

```bash
git clone https://github.com/Mts0/electronic-wallet-system.git
cd electronic-wallet-system
```

## Create Virtual Environment

```bash
python -m venv venv
```

## Activate Virtual Environment

### Windows

```bash
venv\Scripts\activate
```

### Linux / macOS

```bash
source venv/bin/activate
```

## Install Dependencies

```bash
pip install -r requirements.txt
```

## Run the Application

```bash
uvicorn backend/main:app --reload
```

---

# Future Improvements

- Cryptocurrency integration
- AI-based fraud detection
- NFC payments
- Multi-currency support
- Mobile biometric authentication
- Payment gateway integration
- Blockchain support
- Advanced analytics dashboard


---

# Project Goals

- Simplify digital financial transactions
- Provide a secure electronic payment environment
- Improve accessibility to online banking services
- Build a scalable and maintainable wallet infrastructure

---

# Author

**Mostafa Nabil Mattash**

Computer Science | Web Developer | AI & Automation Enthusiast

---

# License

This project is licensed under the MIT License.

