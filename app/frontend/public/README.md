# 📂 Frontend Static Assets

> Files Express serves directly at the web root.

---

## 📁 Project Structure

| Folder | Purpose |
|--------|---------|
| [`css/`](css/README.md) | `style.css` — all styling for the UI |
| [`images/`](images/README.md) | NTI and iVolve logos used by the EJS views |

Express registers this directory as a static folder in `server.js`, so `public/css/style.css` is
reachable at `/css/style.css` and the logos at `/images/<name>.png`.

---

## 🔗 Related

- [frontend overview](../README.md)
