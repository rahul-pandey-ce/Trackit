// Firebase Web Config
const firebaseConfig = {
  apiKey: "AIzaSyB_tPJWryz6s2W51SOigS03RdEH9N5lH24",
  appId: "1:999680168118:web:a662a927f931dfb6641617",
  messagingSenderId: "999680168118",
  projectId: "trackit-db05a",
  authDomain: "trackit-db05a.firebaseapp.com",
  storageBucket: "trackit-db05a.firebasestorage.app",
  databaseURL: "https://trackit-db05a-default-rtdb.firebaseio.com"
};

// Initialize Firebase compat
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.database();

// App State
let currentUser = null;
let currentRole = 'student'; // 'student' or 'viewer'
let isLoginMode = true;
let activeScreen = '';

// Live timers/listeners database handles
let dbListeners = [];
let localStopwatchInterval = null;
let localCountdownInterval = null;
let chartInstance = null;
let viewerChartInstance = null;

// Active state caches
let studentState = {
  uid: '',
  userName: 'Focus Master',
  running: false,
  isCountingDown: false,
  countdownValue: 5,
  startTime: 0,
  elapsedBefore: 0,
  displaySeconds: 0,
  dailyTargetMinutes: 30,
  weeklyStats: {},
  statsView: 'Week'
};

let viewerState = {
  studentUid: '',
  studentName: 'Student',
  running: false,
  isCountingDown: false,
  countdownValue: 5,
  startTime: 0,
  elapsedBefore: 0,
  displaySeconds: 0,
  dailyTargetMinutes: 30,
  weeklyStats: {},
  statsView: 'Week'
};

// Utilities
function getTodayDateString() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function showLoading(show) {
  document.getElementById('app-loading').classList.toggle('hide', !show);
}

function showToast(message) {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.classList.remove('hide');
  setTimeout(() => toast.classList.add('hide'), 3000);
}

function clearAllListeners() {
  dbListeners.forEach(ref => ref.off());
  dbListeners = [];
  if (localStopwatchInterval) clearInterval(localStopwatchInterval);
  if (localCountdownInterval) clearInterval(localCountdownInterval);
  localStopwatchInterval = null;
  localCountdownInterval = null;
}

// Router
function showScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.add('hide'));
  document.getElementById(screenId).classList.remove('hide');
  activeScreen = screenId;
}

function handleRouting() {
  clearAllListeners();
  
  const path = window.location.pathname;
  const parts = path.split('/').filter(Boolean);
  
  if (parts.length === 2 && parts[0] === 'viewer') {
    const studentUid = parts[1];
    showScreen('viewer-dashboard-screen');
    initViewerDashboard(studentUid);
    showLoading(false);
  } else {
    // If not a viewer path, check Auth
    const user = auth.currentUser;
    if (user) {
      showLoading(true);
      db.ref(`users/${user.uid}/role`).once('value').then(snap => {
        showLoading(false);
        const role = snap.val() || 'student';
        if (role === 'viewer') {
          showScreen('viewer-search-screen');
          initViewerSearch();
        } else {
          showScreen('student-screen');
          initStudentDashboard(user.uid);
        }
      }).catch(err => {
        showLoading(false);
        showToast("Database error: " + err.message);
        showScreen('auth-screen');
      });
    } else {
      showScreen('auth-screen');
      showLoading(false);
    }
  }
}

// Window popstate navigation wrapper
window.onpopstate = () => {
  handleRouting();
};

function navigateTo(path) {
  window.history.pushState({}, '', path);
  handleRouting();
}

// Init Application
window.addEventListener('DOMContentLoaded', () => {
  // Bind Auth actions
  const authForm = document.getElementById('auth-form');
  const roleStudent = document.getElementById('role-student');
  const roleViewer = document.getElementById('role-viewer');
  const authToggle = document.getElementById('auth-toggle-btn');

  roleStudent.addEventListener('click', () => {
    roleStudent.classList.add('active');
    roleViewer.classList.remove('active');
    currentRole = 'student';
  });

  roleViewer.addEventListener('click', () => {
    roleViewer.classList.add('active');
    roleStudent.classList.remove('active');
    currentRole = 'viewer';
  });

  authToggle.addEventListener('click', () => {
    isLoginMode = !isLoginMode;
    document.getElementById('auth-title').textContent = isLoginMode ? "Welcome Back" : "Join TrackIt";
    document.getElementById('auth-subtitle').textContent = isLoginMode ? "Sign in to continue your focus" : "Start your focus journey today";
    document.getElementById('auth-submit-btn').textContent = isLoginMode ? "SIGN IN" : "CREATE ACCOUNT";
    document.getElementById('name-group').classList.toggle('hide', isLoginMode);
    authToggle.innerHTML = isLoginMode ? 'New here? <span class="text-primary font-bold">Create an account</span>' : 'Already have an account? <span class="text-primary font-bold">Login</span>';
  });

  authForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const name = document.getElementById('reg-name').value.trim();

    if (!email || !password || (!isLoginMode && !name)) {
      showToast("Please fill in all fields");
      return;
    }

    showLoading(true);
    try {
      if (isLoginMode) {
        const cred = await auth.signInWithEmailAndPassword(email, password);
        await db.ref(`users/${cred.user.uid}`).update({
          email: email,
          role: currentRole
        });
      } else {
        const cred = await auth.createUserWithEmailAndPassword(email, password);
        await db.ref(`users/${cred.user.uid}`).update({
          email: email,
          role: currentRole,
          name: name
        });
      }
      showLoading(false);
      navigateTo('/');
    } catch (err) {
      showLoading(false);
      showToast("Auth failed: " + err.message);
    }
  });

  // Common Logouts
  document.getElementById('student-logout-btn').addEventListener('click', () => auth.signOut().then(() => navigateTo('/')));
  document.getElementById('viewer-logout-btn').addEventListener('click', () => auth.signOut().then(() => navigateTo('/')));

  // Listen to Auth State
  auth.onAuthStateChanged((user) => {
    currentUser = user;
    if (activeScreen === '' || activeScreen === 'auth-screen') {
      handleRouting();
    }
  });
});

// STAGE 1: STUDENT DASHBOARD
function initStudentDashboard(uid) {
  studentState.uid = uid;
  studentState.statsView = 'Week';
  
  // UI bindings
  document.getElementById('display-uid').textContent = `${uid.substring(0, 6)}...`;
  
  // Clipboard UID Copy
  const copyBtn = document.getElementById('copy-uid-btn');
  copyBtn.onclick = () => {
    navigator.clipboard.writeText(uid).then(() => {
      showToast("ID Copied!");
    });
  };

  // Sync Name
  const nameRef = db.ref(`users/${uid}/name`);
  nameRef.on('value', snap => {
    studentState.userName = snap.val() || "Focus Master";
    document.getElementById('student-name').textContent = studentState.userName;
  });
  dbListeners.push(nameRef);

  // Sync Daily Target
  const targetRef = db.ref(`users/${uid}/dailyTarget`);
  targetRef.on('value', snap => {
    studentState.dailyTargetMinutes = snap.val() || 30;
    updateStudentProgressDisplay();
  });
  dbListeners.push(targetRef);

  // Sync Stats
  const historyRef = db.ref(`history/${uid}`);
  historyRef.on('value', snap => {
    studentState.weeklyStats = {};
    if (snap.exists()) {
      snap.forEach(child => {
        studentState.weeklyStats[child.key] = child.val().seconds || 0;
      });
    }
    updateStudentChart();
  });
  dbListeners.push(historyRef);

  // Sync Session State
  const sessionRef = db.ref(`sessions/${uid}`);
  sessionRef.on('value', snap => {
    const today = getTodayDateString();
    
    if (!snap.exists()) {
      sessionRef.set({
        isRunning: false,
        startTime: 0,
        elapsedBefore: 0,
        lastDate: today
      });
      return;
    }

    const data = snap.val();
    const lastDate = data.lastDate || '';

    if (lastDate !== today) {
      studentState.elapsedBefore = 0;
      studentState.displaySeconds = 0;
      sessionRef.update({
        elapsedBefore: 0,
        lastDate: today,
        isRunning: false,
        startTime: 0,
        isCountingDown: false
      });
    } else {
      studentState.elapsedBefore = data.elapsedBefore || 0;
    }

    studentState.running = data.isRunning || false;
    studentState.isCountingDown = data.isCountingDown || false;
    studentState.countdownValue = data.countdownValue ?? 5;
    studentState.startTime = data.startTime || 0;
    
    updateStudentTimerUI();
  });
  dbListeners.push(sessionRef);

  // Stopwatch ticking interval
  if (localStopwatchInterval) clearInterval(localStopwatchInterval);
  localStopwatchInterval = setInterval(() => {
    if (!studentState.running) {
      studentState.displaySeconds = 0;
      return;
    }

    const now = Date.now();
    const delta = Math.floor((now - studentState.startTime) / 1000);
    studentState.displaySeconds = delta > 0 ? delta : 0;

    // Auto-stop check
    if (!processingStop && (studentState.elapsedBefore + studentState.displaySeconds) >= studentState.dailyTargetMinutes * 60) {
      stopStudentTimer();
    }

    updateStudentTimerUI();
    updateStudentProgressDisplay();
  }, 200);

  // Focus Button handler
  const focusBtn = document.getElementById('focus-btn');
  focusBtn.onclick = () => {
    if (studentState.isCountingDown) {
      cancelCountdown(uid);
    } else if (studentState.running) {
      stopStudentTimer();
    } else {
      startCountdown(uid);
    }
  };

  // Modify Name Modal Bindings
  const editNameBtn = document.getElementById('edit-name-btn');
  const nameModal = document.getElementById('name-modal');
  const nameInput = document.getElementById('name-input');
  
  editNameBtn.onclick = () => {
    nameInput.value = studentState.userName === "Focus Master" ? '' : studentState.userName;
    nameModal.classList.remove('hide');
  };

  document.getElementById('cancel-name-btn').onclick = () => nameModal.classList.add('hide');
  document.getElementById('save-name-btn').onclick = () => {
    const val = nameInput.value.trim();
    if (val) {
      db.ref(`users/${uid}/name`).set(val).then(() => {
        nameModal.classList.add('hide');
      });
    }
  };

  // Modify Target Bottom Sheet/Modal Bindings
  const openTargetBtn = document.getElementById('open-target-btn');
  const targetModal = document.getElementById('target-modal');
  const targetSlider = document.getElementById('target-slider');
  const targetModalVal = document.getElementById('target-modal-val');

  openTargetBtn.onclick = () => {
    targetSlider.value = studentState.dailyTargetMinutes;
    targetModalVal.textContent = `${studentState.dailyTargetMinutes} min`;
    targetModal.classList.remove('hide');
  };

  targetSlider.oninput = (e) => {
    targetModalVal.textContent = `${e.target.value} min`;
  };

  document.getElementById('save-target-btn').onclick = () => {
    const minVal = parseInt(targetSlider.value);
    db.ref(`users/${uid}/dailyTarget`).set(minVal).then(() => {
      targetModal.classList.add('hide');
    });
  };

  // Bind Statistics range toggles
  document.querySelectorAll('#student-screen .toggle-btn').forEach(btn => {
    btn.onclick = (e) => {
      document.querySelectorAll('#student-screen .toggle-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      studentState.statsView = e.target.dataset.view;
      updateStudentChart();
    };
  });
}

// Timer Controls
function startCountdown(uid) {
  db.ref(`sessions/${uid}`).update({
    isCountingDown: true,
    countdownValue: 5,
    isRunning: false
  });

  let val = 5;
  if (localCountdownInterval) clearInterval(localCountdownInterval);
  
  localCountdownInterval = setInterval(() => {
    db.ref(`sessions/${uid}`).once('value').then(snap => {
      const data = snap.val();
      if (!data || !data.isCountingDown) {
        clearInterval(localCountdownInterval);
        return;
      }

      if (val > 1) {
        val--;
        db.ref(`sessions/${uid}`).update({ countdownValue: val });
      } else {
        clearInterval(localCountdownInterval);
        db.ref(`sessions/${uid}`).update({
          isCountingDown: false,
          isRunning: true,
          startTime: firebase.database.ServerValue.TIMESTAMP
        });
      }
    });
  }, 1000);
}

function cancelCountdown(uid) {
  if (localCountdownInterval) clearInterval(localCountdownInterval);
  db.ref(`sessions/${uid}`).update({
    isCountingDown: false,
    countdownValue: 5,
    isRunning: false
  });
}

let processingStop = false;
async function stopStudentTimer() {
  if (processingStop) return;
  processingStop = true;

  const uid = studentState.uid;
  if (localCountdownInterval) clearInterval(localCountdownInterval);

  const now = Date.now();
  const sessionSeconds = Math.max(0, Math.floor((now - studentState.startTime) / 1000));
  const totalTodaySeconds = studentState.elapsedBefore + sessionSeconds;
  const todayStr = getTodayDateString();

  try {
    await db.ref(`sessions/${uid}`).set({
      isRunning: false,
      isCountingDown: false,
      countdownValue: 5,
      startTime: 0,
      elapsedBefore: totalTodaySeconds,
      lastDate: todayStr
    });

    // Save session logs in history
    const historyRef = db.ref(`history/${uid}/${todayStr}`);
    const snap = await historyRef.once('value');
    let prevSec = 0;
    if (snap.exists()) {
      prevSec = snap.val().seconds || 0;
    }
    
    await historyRef.set({
      date: todayStr,
      seconds: prevSec + sessionSeconds,
      targetMinutes: studentState.dailyTargetMinutes
    });

    // Show feedback popup alert
    showFeedbackAlert(totalTodaySeconds, studentState.dailyTargetMinutes * 60);

  } catch (err) {
    showToast("Failed to save session: " + err.message);
  } finally {
    processingStop = false;
  }
}

function showFeedbackAlert(totalTodaySeconds, targetSeconds) {
  const isGoalCrushed = totalTodaySeconds >= targetSeconds;
  const title = "Session Summary";
  const desc = isGoalCrushed 
    ? "Amazing! You've officially crushed your goal for today. 🚀"
    : "Good effort! You've logged some valuable study time. 📈";

  const feedbackDiv = document.createElement('div');
  feedbackDiv.className = 'modal-overlay';
  feedbackDiv.innerHTML = `
    <div class="dialog-box">
      <h3>${title}</h3>
      <p style="color: var(--text-dark); font-size: 15px; margin-bottom: 24px; line-height: 1.5;">${desc}</p>
      <div class="dialog-actions">
        <button id="close-feedback-btn" class="btn btn-primary">DONE</button>
      </div>
    </div>
  `;
  document.body.appendChild(feedbackDiv);
  document.getElementById('close-feedback-btn').onclick = () => {
    feedbackDiv.remove();
  };
}

// Student UI Updates
function updateStudentTimerUI() {
  const display = document.getElementById('timer-display');
  const status = document.getElementById('timer-status');
  const btnIcon = document.getElementById('focus-btn-icon');
  const btnText = document.getElementById('focus-btn-text');
  const focusBtn = document.getElementById('focus-btn');
  const pulse = document.getElementById('timer-pulse');

  if (studentState.isCountingDown) {
    display.textContent = `${studentState.countdownValue}`;
    display.style.fontSize = "100px";
    status.textContent = "PREPARING...";
    btnIcon.textContent = "close";
    btnText.textContent = "CANCEL FOCUS";
    focusBtn.className = "btn-focus active";
    pulse.classList.add('hide');
  } else {
    display.style.fontSize = "64px";
    const minutes = Math.floor(studentState.displaySeconds / 60);
    const secs = studentState.displaySeconds % 60;
    display.textContent = `${minutes}:${String(secs).padStart(2, '0')}`;

    if (studentState.running) {
      status.textContent = "FOCUS ON";
      btnIcon.textContent = "stop_circle";
      btnText.textContent = "END SESSION";
      focusBtn.className = "btn-focus active";
      pulse.classList.remove('hide');
    } else {
      status.textContent = "READY?";
      btnIcon.textContent = "play_circle_filled";
      btnText.textContent = "START FOCUS";
      focusBtn.className = "btn-focus";
      pulse.classList.add('hide');
    }
  }

  // Quote Cards
  const totalMins = Math.floor(studentState.displaySeconds / 60);
  const quote = document.getElementById('motivational-quote');
  if (totalMins < 30) {
    quote.textContent = "Every big journey begins with small steps. Keep pushing!";
  } else if (totalMins < 60) {
    quote.textContent = "You're building momentum! Half an hour of pure focus.";
  } else if (totalMins < 120) {
    quote.textContent = "Incredible! You've crossed the one-hour mark. Stay in the zone.";
  } else if (totalMins < 240) {
    quote.textContent = "Legendary Focus! 2+ hours and still going strong.";
  } else {
    quote.textContent = "God-tier productivity! You are a master of your time.";
  }
}

function updateStudentProgressDisplay() {
  const dailyTargetSec = studentState.dailyTargetMinutes * 60;
  const progressRatio = Math.min(1.0, studentState.displaySeconds / dailyTargetSec);
  const progressPercent = Math.round(progressRatio * 100);
  
  const fill = document.getElementById('progress-fill');
  const percentText = document.getElementById('progress-percent');
  const statusText = document.getElementById('progress-status-text');
  const footerIcon = document.getElementById('progress-icon');
  
  fill.style.width = `${progressPercent}%`;
  percentText.textContent = `${progressPercent}%`;

  const isComplete = progressPercent >= 100;
  fill.classList.toggle('target-met', isComplete);
  percentText.classList.toggle('target-met', isComplete);
  footerIcon.parentElement.classList.toggle('target-met', isComplete);

  if (isComplete) {
    statusText.textContent = "Goal Smashed! 🌟";
  } else {
    const minsLeft = Math.max(0, studentState.dailyTargetMinutes - Math.floor(studentState.displaySeconds / 60));
    statusText.textContent = `${minsLeft}m more to reach goal.`;
  }
}

function updateStudentChart() {
  const isMonth = studentState.statsView === 'Month';
  document.getElementById('chart-container').classList.toggle('hide', isMonth);
  document.getElementById('monthly-summary').classList.toggle('hide', !isMonth);

  if (isMonth) {
    // Metric summaries calculations
    let totalSec = 0;
    let maxSec = 0;
    let bestDayStr = "N/A";
    let activeDays = 0;

    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (let i = 0; i < 30; i++) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      
      const sec = studentState.weeklyStats[key] || 0;
      totalSec += sec;
      
      if (sec > maxSec) {
        maxSec = sec;
        bestDayStr = `${months[d.getMonth()]} ${d.getDate()}`;
      }
      
      if (sec > 0) activeDays++;
    }

    const totalHrs = Math.floor(totalSec / 3600);
    const totalMins = Math.floor((totalSec % 3600) / 60);
    const avgMins = activeDays > 0 ? Math.floor((totalSec / 60) / activeDays) : 0;

    document.getElementById('summary-total').textContent = `${totalHrs} h ${totalMins} m`;
    document.getElementById('summary-avg').textContent = `${avgMins} min`;
    document.getElementById('summary-best').textContent = bestDayStr;
    document.getElementById('summary-active').textContent = `${activeDays}/30`;

  } else {
    // Graph labels and arrays
    const chartLabels = [];
    const chartData = [];
    const now = new Date();

    if (studentState.statsView === 'Day') {
      chartLabels.push("Today");
      const key = getTodayDateString();
      const mins = Math.floor((studentState.weeklyStats[key] || 0) / 60);
      chartData.push(mins);
    } else {
      // Week
      const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      for (let i = 0; i < 7; i++) {
        const d = new Date();
        d.setDate(now.getDate() - (6 - i));
        chartLabels.push(weekdays[d.getDay()]);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const mins = Math.floor((studentState.weeklyStats[key] || 0) / 60);
        chartData.push(mins);
      }
    }

    if (chartInstance) {
      chartInstance.data.labels = chartLabels;
      chartInstance.data.datasets[0].data = chartData;
      chartInstance.update();
    } else {
      const ctx = document.getElementById('stats-chart').getContext('2d');
      chartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: chartLabels,
          datasets: [{
            label: 'Minutes',
            data: chartData,
            backgroundColor: 'rgba(108, 99, 255, 0.4)',
            borderColor: '#6C63FF',
            borderWidth: 2,
            borderRadius: 6,
            borderSkipped: false
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                label: function(context) { return context.raw + ' min'; }
              }
            }
          },
          scales: {
            x: { grid: { display: false }, ticks: { color: 'rgba(255, 255, 255, 0.7)', font: { family: 'Outfit', weight: 'bold' } } },
            y: { display: false }
          }
        }
      });
    }
  }
}


// STAGE 2: VIEWER SEARCH SCREEN
function initViewerSearch() {
  const uidInput = document.getElementById('search-uid-input');
  const searchBtn = document.getElementById('search-uid-btn');

  searchBtn.onclick = () => {
    const uidVal = uidInput.value.trim();
    if (uidVal) {
      navigateTo(`/viewer/${uidVal}`);
    } else {
      showToast("Please enter a Student UID");
    }
  };
}


// STAGE 3: VIEWER MONITORED DASHBOARD
function initViewerDashboard(studentUid) {
  viewerState.studentUid = studentUid;
  viewerState.statsView = 'Week';

  // Setup Back navigation
  const backBtn = document.getElementById('viewer-back-btn');
  backBtn.onclick = () => {
    navigateTo('/');
  };

  // Setup shareable link button
  const shareBtn = document.getElementById('copy-access-link-btn');
  shareBtn.onclick = () => {
    const url = `${window.location.origin}/viewer/${studentUid}`;
    navigator.clipboard.writeText(url).then(() => {
      showToast("Access link copied!");
    });
  };

  // Sync Student Name
  const nameRef = db.ref(`users/${studentUid}/name`);
  nameRef.on('value', snap => {
    viewerState.studentName = snap.val() || "Student";
    document.getElementById('viewer-title').textContent = `${viewerState.studentName}'s Focus`;
    updateViewerStatusDisplay();
  });
  dbListeners.push(nameRef);

  // Sync Student Target
  const targetRef = db.ref(`users/${studentUid}/dailyTarget`);
  targetRef.on('value', snap => {
    viewerState.dailyTargetMinutes = snap.val() || 30;
    document.getElementById('info-target').textContent = `${viewerState.dailyTargetMinutes} Min`;
    updateViewerProgressDisplay();
  });
  dbListeners.push(targetRef);

  // Sync Student History
  const historyRef = db.ref(`history/${studentUid}`);
  historyRef.on('value', snap => {
    viewerState.weeklyStats = {};
    if (snap.exists()) {
      snap.forEach(child => {
        viewerState.weeklyStats[child.key] = child.val().seconds || 0;
      });
    }
    updateViewerChart();
  });
  dbListeners.push(historyRef);

  // Sync Live Student Session state
  const sessionRef = db.ref(`sessions/${studentUid}`);
  sessionRef.on('value', snap => {
    if (!snap.exists()) return;
    const data = snap.val();

    viewerState.running = data.isRunning || false;
    viewerState.isCountingDown = data.isCountingDown || false;
    viewerState.countdownValue = data.countdownValue ?? 5;
    viewerState.startTime = data.startTime || 0;
    viewerState.elapsedBefore = data.elapsedBefore || 0;
    
    updateViewerStatusDisplay();
    updateViewerProgressDisplay();
  });
  dbListeners.push(sessionRef);

  // UI interval checking delta
  if (localStopwatchInterval) clearInterval(localStopwatchInterval);
  localStopwatchInterval = setInterval(() => {
    if (!viewerState.running) {
      viewerState.displaySeconds = 0;
    } else {
      const now = Date.now();
      const delta = Math.floor((now - viewerState.startTime) / 1000);
      viewerState.displaySeconds = delta > 0 ? delta : 0;
    }
    updateViewerTimerDisplay();
  }, 500);

  // Bind Statistics toggles on viewer view
  document.querySelectorAll('#viewer-stats-toggle .toggle-btn').forEach(btn => {
    btn.onclick = (e) => {
      document.querySelectorAll('#viewer-stats-toggle .toggle-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      viewerState.statsView = e.target.dataset.view;
      updateViewerChart();
    };
  });
}

function updateViewerStatusDisplay() {
  const liveCard = document.getElementById('live-card');
  const iconContainer = document.getElementById('live-status-icon-container');
  const icon = document.getElementById('live-status-icon');
  const statusSub = document.getElementById('live-status-sub');
  const statusTitle = document.getElementById('live-status-title');
  const infoStatus = document.getElementById('info-status');

  iconContainer.className = "live-icon";

  if (viewerState.isCountingDown) {
    iconContainer.classList.add("bg-status-preparing");
    icon.textContent = "timer";
    statusSub.textContent = "PREPARING";
    statusTitle.textContent = `${viewerState.studentName} is Ready`;
    infoStatus.textContent = "PREPARING";
    infoStatus.className = "info-val text-primary";
  } else if (viewerState.running) {
    iconContainer.classList.add("bg-status-active");
    icon.textContent = "bolt";
    statusSub.textContent = "WORKING HARD";
    statusTitle.textContent = `${viewerState.studentName} is Active`;
    infoStatus.textContent = "ACTIVE";
    infoStatus.className = "info-val text-primary";
  } else {
    // Idle
    iconContainer.classList.add("bg-status-idle");
    icon.textContent = "pause";
    statusSub.textContent = "TAKING A BREAK";
    statusTitle.textContent = `${viewerState.studentName} is Idle`;
    infoStatus.textContent = "IDLE";
    infoStatus.className = "info-val text-muted";
  }
}

function updateViewerTimerDisplay() {
  const timerDisp = document.getElementById('viewer-timer-display');
  const timerSub = document.getElementById('viewer-timer-sub');

  if (viewerState.isCountingDown) {
    timerDisp.textContent = `${viewerState.countdownValue}`;
    timerDisp.className = "circle-timer preparing";
    timerSub.textContent = "READY IN...";
  } else {
    timerDisp.className = "circle-timer";
    timerSub.textContent = "FOCUS TIME";
    const min = Math.floor(viewerState.displaySeconds / 60);
    const sec = viewerState.displaySeconds % 60;
    timerDisp.textContent = `${min}:${String(sec).padStart(2, '0')}`;
  }
}

function updateViewerProgressDisplay() {
  const dailyTargetSec = viewerState.dailyTargetMinutes * 60;
  const progressRatio = Math.min(1.0, viewerState.displaySeconds / dailyTargetSec);
  const progressPercent = Math.round(progressRatio * 100);

  // SVG dash offset
  const maxDash = 596.9; // 2 * PI * r (r=95)
  const strokeOffset = maxDash - (progressRatio * maxDash);
  const fillCurve = document.getElementById('viewer-svg-fill');
  fillCurve.style.strokeDashoffset = strokeOffset;

  const isMet = progressPercent >= 100;
  fillCurve.classList.toggle('target-met', isMet);

  document.getElementById('viewer-progress-header').textContent = `${progressPercent}% of Daily Goal`;
  document.getElementById('viewer-progress-sub').textContent = `${Math.floor(viewerState.displaySeconds / 60)} / ${viewerState.dailyTargetMinutes} Minutes`;
}

function updateViewerChart() {
  const isMonth = viewerState.statsView === 'Month';
  document.getElementById('viewer-chart-container').classList.toggle('hide', isMonth);
  document.getElementById('viewer-monthly-summary').classList.toggle('hide', !isMonth);

  if (isMonth) {
    let totalSec = 0;
    let maxSec = 0;
    let bestDayStr = "N/A";
    let activeDays = 0;

    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (let i = 0; i < 30; i++) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      
      const sec = viewerState.weeklyStats[key] || 0;
      totalSec += sec;
      
      if (sec > maxSec) {
        maxSec = sec;
        bestDayStr = `${months[d.getMonth()]} ${d.getDate()}`;
      }
      if (sec > 0) activeDays++;
    }

    const totalHrs = Math.floor(totalSec / 3600);
    const totalMins = Math.floor((totalSec % 3600) / 60);
    const avgMins = activeDays > 0 ? Math.floor((totalSec / 60) / activeDays) : 0;

    document.getElementById('viewer-summary-total').textContent = `${totalHrs} h ${totalMins} m`;
    document.getElementById('viewer-summary-avg').textContent = `${avgMins} min`;
    document.getElementById('viewer-summary-best').textContent = bestDayStr;
    document.getElementById('viewer-summary-active').textContent = `${activeDays}/30`;

  } else {
    const chartLabels = [];
    const chartData = [];
    const now = new Date();

    if (viewerState.statsView === 'Day') {
      chartLabels.push("Today");
      const key = getTodayDateString();
      const mins = Math.floor((viewerState.weeklyStats[key] || 0) / 60);
      chartData.push(mins);
    } else {
      const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      for (let i = 0; i < 7; i++) {
        const d = new Date();
        d.setDate(now.getDate() - (6 - i));
        chartLabels.push(weekdays[d.getDay()]);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const mins = Math.floor((viewerState.weeklyStats[key] || 0) / 60);
        chartData.push(mins);
      }
    }

    if (viewerChartInstance) {
      viewerChartInstance.data.labels = chartLabels;
      viewerChartInstance.data.datasets[0].data = chartData;
      viewerChartInstance.update();
    } else {
      const ctx = document.getElementById('viewer-stats-chart').getContext('2d');
      viewerChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: chartLabels,
          datasets: [{
            label: 'Minutes',
            data: chartData,
            backgroundColor: 'rgba(108, 99, 255, 0.15)',
            borderColor: '#6C63FF',
            borderWidth: 2,
            borderRadius: 6,
            borderSkipped: false
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                label: function(context) { return context.raw + ' min'; }
              }
            }
          },
          scales: {
            x: { grid: { display: false }, ticks: { color: '#2D3250', font: { family: 'Outfit', weight: 'bold' } } },
            y: { display: false }
          }
        }
      });
    }
  }
}
