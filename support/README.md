# Vāṇī Support Page

This is a simple support page for the Vāṇī app, designed to be hosted on GitHub Pages.

## How to Deploy to GitHub Pages

### Step 1: Create a GitHub Repository

1. Go to https://github.com/new
2. Create a new repository named `vani-support` (or any name you prefer)
3. Make it **public** (required for free GitHub Pages)
4. Don't initialize with README (we already have files)

### Step 2: Upload Files

1. Open Terminal
2. Navigate to this folder:
   ```bash
   cd /Users/shreyapatel/Desktop/Vani/support
   ```

3. Initialize git and push:
   ```bash
   git init
   git add .
   git commit -m "Initial commit - Support page"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/vani-support.git
   git push -u origin main
   ```
   (Replace `YOUR_USERNAME` with your GitHub username)

### Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Scroll down to **Pages** section (left sidebar)
4. Under **Source**, select **Deploy from a branch**
5. Select **main** branch and **/ (root)** folder
6. Click **Save**

### Step 4: Get Your URL

After a few minutes, your site will be available at:
```
https://YOUR_USERNAME.github.io/vani-support/
```

Or if you named the repository differently:
```
https://YOUR_USERNAME.github.io/REPOSITORY_NAME/
```

## Alternative: Quick Deploy with GitHub Desktop

1. Download GitHub Desktop: https://desktop.github.com/
2. Sign in with your GitHub account
3. File → Add Local Repository
4. Select the `support` folder
5. Publish repository
6. Enable GitHub Pages in repository settings

## Custom Domain (Optional)

If you have a custom domain, you can:
1. Add a `CNAME` file with your domain name
2. Configure DNS settings in your domain provider
3. Update GitHub Pages settings

## Notes

- The page is mobile-responsive
- Update the email address in `index.html` if needed
- You can customize colors, content, and styling as needed

