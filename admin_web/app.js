import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js";
import {
  getFirestore,
  collection,
  getDocs,
  query,
  where,
  orderBy,
  getCountFromServer,
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";

const ADMIN_EMAIL = "admin@fineye.com";

const firebaseConfig = {
  apiKey: "AIzaSyCPXlU6vBwcZnOb898mbhOZtDIcuYBc3ho",
  authDomain: "fineye-app.firebaseapp.com",
  projectId: "fineye-app",
  storageBucket: "fineye-app.firebasestorage.app",
  messagingSenderId: "236162384586",
  appId: "1:236162384586:web:fb8074e08f58118a2d6a33",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const authCard = document.getElementById("auth-card");
const dashboard = document.getElementById("dashboard");
const bootLoader = document.getElementById("boot-loader");
const loginForm = document.getElementById("login-form");
const authError = document.getElementById("auth-error");
const refreshBtn = document.getElementById("refresh-btn");
const logoutBtn = document.getElementById("logout-btn");
const signedInAs = document.getElementById("signed-in-as");
const dashboardError = document.getElementById("dashboard-error");
const userSearch = document.getElementById("user-search");
const metricButtons = [...document.querySelectorAll(".metric[data-metric]")];
const activeFilter = document.getElementById("active-filter");
const loadingRow = document.getElementById("loading-row");
const invoicePanel = document.getElementById("invoice-panel");
const invoicePanelTitle = document.getElementById("invoice-panel-title");
const invoicePanelSubtitle = document.getElementById("invoice-panel-subtitle");
const invoiceTable = document.getElementById("invoice-table");
const closeInvoicePanelBtn = document.getElementById("close-invoice-panel");

let allRows = [];
let currentMetric = "all";

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  hideAuthError();
  const email = document.getElementById("email").value.trim().toLowerCase();
  const password = document.getElementById("password").value;
  try {
    await signInWithEmailAndPassword(auth, email, password);
  } catch (err) {
    showAuthError(err?.message || "Login failed.");
  }
});

logoutBtn.addEventListener("click", async () => {
  await signOut(auth);
});

refreshBtn.addEventListener("click", async () => {
  await loadDashboard();
});

userSearch?.addEventListener("input", () => {
  applyFilters();
});

metricButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    currentMetric = btn.dataset.metric || "all";
    updateMetricButtonState();
    applyFilters();
  });
});

closeInvoicePanelBtn?.addEventListener("click", () => {
  invoicePanel?.classList.add("hidden");
  if (invoiceTable) invoiceTable.innerHTML = "";
});

onAuthStateChanged(auth, async (user) => {
  if (bootLoader) bootLoader.classList.add("hidden");

  if (!user) {
    authCard.classList.remove("hidden");
    dashboard.classList.add("hidden");
    hideAuthError();
    hideDashboardError();
    allRows = [];
    currentMetric = "all";
    updateMetricButtonState();
    applyFilters();
    invoicePanel?.classList.add("hidden");
    return;
  }

  const email = (user.email || "").toLowerCase();
  if (email !== ADMIN_EMAIL.toLowerCase()) {
    await signOut(auth);
    showAuthError("This account is not allowed for admin dashboard.");
    return;
  }

  authCard.classList.add("hidden");
  dashboard.classList.remove("hidden");
  signedInAs.textContent = `Signed in as ${email}`;
  await loadDashboard();
});

async function loadDashboard() {
  setLoading(true);
  try {
    hideDashboardError();

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const usersSnap = await getDocs(collection(db, "users"));
    const activitySnap = await getDocs(collection(db, "user_activity"));
    const totalInvoicesAgg = await getCountFromServer(collection(db, "user_invoices"));

    document.getElementById("m-users").textContent = String(usersSnap.size);
    document.getElementById("m-invoices").textContent = String(totalInvoicesAgg.data().count || 0);

    let activeToday = 0;
    let activeWeek = 0;
    let totalOpens = 0;
    let totalViews = 0;

    const activityByUid = new Map();
    for (const doc of activitySnap.docs) {
      const data = doc.data();
      activityByUid.set(doc.id, data);

      const lastActive = toDateOrNull(data.lastActiveAt);
      if (lastActive) {
        if (lastActive >= todayStart) activeToday += 1;
        if (lastActive >= sevenDaysAgo) activeWeek += 1;
      }

      totalOpens += toNumber(data.appOpenCount);
      totalViews += toNumber(data.screenViewCount);
    }

    document.getElementById("m-active-today").textContent = String(activeToday);
    document.getElementById("m-active-week").textContent = String(activeWeek);
    document.getElementById("m-opens").textContent = String(totalOpens);
    document.getElementById("m-views").textContent = String(totalViews);

    const rows = await Promise.all(
      usersSnap.docs.map(async (doc) => {
        const uid = doc.id;
        const data = doc.data() || {};
        const activity = activityByUid.get(uid) || {};

        let invoices = 0;
        try {
          const perUserInv = await getCountFromServer(
            query(collection(db, "user_invoices"), where("userId", "==", uid))
          );
          invoices = toNumber(perUserInv.data().count);
        } catch (_) {
          invoices = 0;
        }

        return {
          company: toSafeString(data.companyName, "Unnamed Company"),
          email: toSafeString(data.email, "-"),
          uid,
          createdAt: formatDate(toDateOrNull(data.createdAt)),
          invoices,
          lastActive: formatDate(toDateOrNull(activity.lastActiveAt)),
          lastRoute: toSafeString(activity.lastRoute, "-"),
          appOpens: toNumber(activity.appOpenCount),
          views: toNumber(activity.screenViewCount),
        };
      })
    );

    rows.sort((a, b) => b.invoices - a.invoices);
    allRows = rows;
    applyFilters();
  } catch (err) {
    showDashboardError(
      "Unable to load dashboard data. Check Firestore access for admin account and activity documents."
    );
    console.error(err);
  } finally {
    setLoading(false);
  }
}

function applyFilters() {
  const q = (userSearch?.value || "").trim().toLowerCase();
  const filtered = allRows
    .filter((r) => passesMetricFilter(r, currentMetric))
    .filter((r) => {
      if (!q) return true;
    return (
      r.company.toLowerCase().includes(q) ||
      r.email.toLowerCase().includes(q) ||
      r.uid.toLowerCase().includes(q)
    );
  });

  activeFilter.textContent = `Filter: ${metricLabel(currentMetric)}${
    q ? ` + Search "${q}"` : ""
  }`;
  renderRows(filtered);
}

function passesMetricFilter(row, metric) {
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const lastActive = parseDateOrNull(row.lastActive);

  switch (metric) {
    case "active_today":
      return !!lastActive && lastActive >= todayStart;
    case "active_7d":
      return !!lastActive && lastActive >= sevenDaysAgo;
    case "has_invoices":
      return row.invoices > 0;
    case "has_app_opens":
      return row.appOpens > 0;
    case "has_views":
      return row.views > 0;
    case "all":
    default:
      return true;
  }
}

function updateMetricButtonState() {
  metricButtons.forEach((btn) => {
    const isActive = (btn.dataset.metric || "all") === currentMetric;
    btn.classList.toggle("active", isActive);
  });
}

function metricLabel(metric) {
  switch (metric) {
    case "active_today":
      return "Active Today";
    case "active_7d":
      return "Active 7 Days";
    case "has_invoices":
      return "Users With Invoices";
    case "has_app_opens":
      return "Users With App Opens";
    case "has_views":
      return "Users With Screen Views";
    case "all":
    default:
      return "All users";
  }
}

function renderRows(items) {
  const tbody = document.getElementById("user-table");
  tbody.innerHTML = "";

  if (!items.length) {
    const tr = document.createElement("tr");
    tr.innerHTML =
      '<td colspan="10" style="text-align:center;color:#61708b;">No users found.</td>';
    tbody.appendChild(tr);
    return;
  }

  for (const item of items) {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td><button type="button" class="row-btn" data-open-invoices="${escapeHtml(item.uid)}">View</button></td>
      <td>${escapeHtml(item.company)}</td>
      <td>${escapeHtml(item.email)}</td>
      <td>${escapeHtml(item.uid)}</td>
      <td>${escapeHtml(item.createdAt)}</td>
      <td>${item.invoices}</td>
      <td>${escapeHtml(item.lastActive)}</td>
      <td>${escapeHtml(item.lastRoute)}</td>
      <td>${item.appOpens}</td>
      <td>${item.views}</td>
    `;
    tbody.appendChild(tr);
  }

  tbody.querySelectorAll("[data-open-invoices]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const uid = btn.getAttribute("data-open-invoices");
      const row = allRows.find((r) => r.uid === uid);
      await openUserInvoices(uid, row);
    });
  });
}

async function openUserInvoices(uid, row) {
  if (!uid || !invoiceTable || !invoicePanel) return;

  invoicePanelTitle.textContent = "User Invoices";
  invoicePanelSubtitle.textContent = `${row?.company || ""} (${row?.email || uid})`;
  invoiceTable.innerHTML =
    '<tr><td colspan="10" style="text-align:center;color:#61708b;">Loading invoices...</td></tr>';
  invoicePanel.classList.remove("hidden");

  try {
    let snap;
    try {
      const q = query(
        collection(db, "user_invoices"),
        where("userId", "==", uid),
        orderBy("date", "desc")
      );
      snap = await getDocs(q);
    } catch (_) {
      const qFallback = query(collection(db, "user_invoices"), where("userId", "==", uid));
      snap = await getDocs(qFallback);
    }
    if (snap.empty) {
      invoiceTable.innerHTML =
        '<tr><td colspan="10" style="text-align:center;color:#61708b;">No invoices uploaded by this user.</td></tr>';
      return;
    }

    const docs = [...snap.docs].sort((a, b) => {
      const ad = toDateOrNull(a.data()?.date);
      const bd = toDateOrNull(b.data()?.date);
      return (bd?.getTime() || 0) - (ad?.getTime() || 0);
    });

    const rows = docs.map((d) => {
      const data = d.data() || {};
      const invoiceId = toSafeString(data.id, d.id);
      const party = toSafeString(data.supplierName, "-");
      const type = toSafeString(data.invoiceType, "-");
      const category = toSafeString(data.category, "-");
      const date = formatDate(toDateOrNull(data.date));
      const net = formatMoney(toNumber(data.netAmount));
      const vat = formatMoney(toNumber(data.vatAmount));
      const gross = formatMoney(toNumber(data.grossAmount));
      const status = toSafeString(data.status, "-");
      const imageUrl = toSafeString(data.imageUrl, "");
      const imageCell = imageUrl
        ? `<a href="${escapeHtml(imageUrl)}" target="_blank" rel="noopener noreferrer">Open</a>`
        : "-";

      return `
        <tr>
          <td>${escapeHtml(invoiceId)}</td>
          <td>${escapeHtml(party)}</td>
          <td>${escapeHtml(type)}</td>
          <td>${escapeHtml(category)}</td>
          <td>${escapeHtml(date)}</td>
          <td class="money">${net}</td>
          <td class="money">${vat}</td>
          <td class="money">${gross}</td>
          <td>${escapeHtml(status)}</td>
          <td>${imageCell}</td>
        </tr>
      `;
    });

    invoiceTable.innerHTML = rows.join("");
  } catch (err) {
    invoiceTable.innerHTML =
      '<tr><td colspan="10" style="text-align:center;color:#b91c1c;">Failed to load invoices.</td></tr>';
    console.error(err);
  }
}

function showAuthError(message) {
  if (!authError) return;
  authError.textContent = message;
  authError.classList.remove("hidden");
}

function hideAuthError() {
  if (!authError) return;
  authError.textContent = "";
  authError.classList.add("hidden");
}

function showDashboardError(message) {
  if (!dashboardError) return;
  dashboardError.textContent = message;
  dashboardError.classList.remove("hidden");
}

function hideDashboardError() {
  if (!dashboardError) return;
  dashboardError.textContent = "";
  dashboardError.classList.add("hidden");
}

function setLoading(isLoading) {
  if (loadingRow) {
    loadingRow.classList.toggle("hidden", !isLoading);
  }
  dashboard.classList.toggle("is-loading", isLoading);
  refreshBtn.disabled = isLoading;
  logoutBtn.disabled = isLoading;
  if (userSearch) userSearch.disabled = isLoading;
  metricButtons.forEach((btn) => {
    btn.disabled = isLoading;
  });
}

function toDateOrNull(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function parseDateOrNull(value) {
  if (!value || value === "-") return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatDate(value) {
  if (!value) return "-";
  const y = value.getFullYear();
  const m = String(value.getMonth() + 1).padStart(2, "0");
  const d = String(value.getDate()).padStart(2, "0");
  const hh = String(value.getHours()).padStart(2, "0");
  const mm = String(value.getMinutes()).padStart(2, "0");
  return `${y}-${m}-${d} ${hh}:${mm}`;
}

function toSafeString(value, fallback = "") {
  if (value == null) return fallback;
  return String(value).trim() || fallback;
}

function toNumber(value) {
  if (value == null) return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function formatMoney(value) {
  return `AED ${toNumber(value).toFixed(2)}`;
}

function escapeHtml(str) {
  return String(str)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
