#!/bin/bash

# NextRole Web Deployment Script
# This script helps deploy the web pages to various hosting services

echo "🚀 NextRole Web Deployment Script"
echo "================================"

# Check if required files exist
echo "📋 Checking required files..."

if [ ! -f "support.html" ]; then
    echo "❌ Error: support.html not found"
    exit 1
fi

if [ ! -f "privacy.html" ]; then
    echo "❌ Error: privacy.html not found"
    exit 1
fi

if [ ! -f "terms.html" ]; then
    echo "❌ Error: terms.html not found"
    exit 1
fi

if [ ! -f "index.html" ]; then
    echo "❌ Error: index.html not found"
    exit 1
fi

echo "✅ All required files found"

# Create a simple deployment package
echo "📦 Creating deployment package..."

mkdir -p deploy
cp support.html deploy/
cp privacy.html deploy/
cp terms.html deploy/
cp index.html deploy/

echo "✅ Deployment package created in 'deploy/' directory"

# Instructions for different hosting services
echo ""
echo "🌐 Deployment Instructions:"
echo "=========================="
echo ""
echo "1. For GitHub Pages:"
echo "   - Create a new repository"
echo "   - Upload the files from 'deploy/' to the repository"
echo "   - Enable GitHub Pages in repository settings"
echo "   - Your URL will be: https://username.github.io/repository-name"
echo ""
echo "2. For Netlify:"
echo "   - Drag and drop the 'deploy/' folder to netlify.com"
echo "   - Your URL will be provided by Netlify"
echo ""
echo "3. For Vercel:"
echo "   - Install Vercel CLI: npm i -g vercel"
echo "   - Run: vercel --prod in the 'deploy/' directory"
echo ""
echo "4. For Firebase Hosting:"
echo "   - Install Firebase CLI: npm install -g firebase-tools"
echo "   - Run: firebase init hosting"
echo "   - Copy files from 'deploy/' to 'public/' directory"
echo "   - Run: firebase deploy"
echo ""
echo "5. For local testing:"
echo "   - Run: python3 server.py"
echo "   - Visit: http://localhost:8000"
echo ""

# Test the local server
echo "🧪 Testing local server..."
echo "Starting local server on port 8000..."
echo "Visit http://localhost:8000 to test"
echo "Press Ctrl+C to stop the server"
echo ""

# Start the local server
python3 server.py 