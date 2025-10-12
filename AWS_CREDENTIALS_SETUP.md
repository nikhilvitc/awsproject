# AWS Credentials Setup Guide

## 🎯 What You Need to Do Next

Once you have your AWS Access Key ID and Secret Access Key from the IAM console, follow these steps:

### Option 1: Use the Setup Script (Recommended)
```bash
cd backend
./setup-credentials.sh
```

This interactive script will:
- Ask for your AWS credentials
- Create a secure `.env` file
- Set up all necessary environment variables

### Option 2: Manual Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Copy the example file:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file with your actual credentials:
   ```bash
   nano .env  # or use your preferred editor
   ```

4. Replace the placeholder values:
   ```
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=AKIA...your_actual_access_key
   AWS_SECRET_ACCESS_KEY=your_actual_secret_key
   ```

## 🔍 Testing Your Setup

After setting up your credentials, test the connection:

```bash
# Test DynamoDB connection
npm run test

# Check overall setup
npm run check-setup

# Create DynamoDB tables
npm run create-tables
```

## 🚀 Starting Development

Once everything is set up:
```bash
npm run dev
```

## ⚠️ Security Notes

- **Never commit your `.env` file** - it's already in `.gitignore`
- **Keep your credentials secure** - don't share them
- **Rotate keys regularly** for security
- **Use IAM roles in production** instead of access keys

## 🔧 Troubleshooting

### Common Issues:

1. **"Access Denied" errors**: Check your IAM permissions
2. **"Region not found"**: Verify your AWS region
3. **"Invalid credentials"**: Double-check your access key and secret

### Verify Your Setup:
```bash
# Check if .env file exists and has content
ls -la .env

# Test AWS CLI (if installed)
aws sts get-caller-identity
```

## 📋 Next Steps After Setup

1. ✅ Test AWS connection
2. ✅ Create DynamoDB tables
3. ✅ Start your development server
4. ✅ Test your application features
5. ✅ Deploy to production when ready

---

**Need Help?** Check the `DYNAMODB_SETUP_GUIDE.md` for detailed DynamoDB configuration.
