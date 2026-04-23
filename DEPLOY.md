# SF Case Tracker — GitHub Pages Deployment Guide

## What you need
- A free GitHub account (github.com)
- 5 minutes

---

## Step 1 — Create a GitHub account
Go to https://github.com and sign up for free if you don't have one.

---

## Step 2 — Create a new repository
1. Click the **+** button (top right) → **New repository**
2. Name it: `sf-case-tracker`
3. Set it to **Public** (required for free GitHub Pages)
4. Check **"Add a README file"**
5. Click **Create repository**

---

## Step 3 — Upload the file
1. In your new repo, click **Add file** → **Upload files**
2. Drag and drop the `index.html` file from your computer
3. Scroll down, click **Commit changes**

---

## Step 4 — Enable GitHub Pages
1. Go to your repo **Settings** (top menu)
2. Click **Pages** (left sidebar)
3. Under **Source**, select **Deploy from a branch**
4. Branch: `main` | Folder: `/ (root)`
5. Click **Save**

---

## Step 5 — Get your URL
After 1–2 minutes, your tracker will be live at:
```
https://YOUR-USERNAME.github.io/sf-case-tracker/
```
Replace `YOUR-USERNAME` with your GitHub username.

---

## Bookmark it!
Save that URL as a bookmark in your browser for instant daily access.

---

## Important notes about data storage
- All your case data is saved in your **browser's localStorage**
- Data is tied to the browser + device you use
- Clearing browser data/cache will erase cases — **use Export CSV regularly as a backup**
- To move data to another device: Export CSV on old device, and we can build an import feature

---

## Updating the app in future
If you want to update the app with new features:
1. Come back to Claude, ask for the updated `index.html`
2. In your GitHub repo, click `index.html` → Edit (pencil icon)
3. Replace the content → Commit changes
4. GitHub Pages auto-updates within 1–2 minutes
