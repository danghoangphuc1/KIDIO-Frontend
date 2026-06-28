function MSheet({ open, onClose, title, children }: { open: boolean; onClose: () => void; title: string; children: React.ReactNode }) {
  if (!open) return null;
  return (
    <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)", zIndex: 120, display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
      <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} transition={{ type: "spring", stiffness: 320, damping: 32 }}
        style={{ background: "#fff", borderRadius: "24px 24px 0 0", maxHeight: "82%", overflow: "auto", paddingBottom: 24 }}>
        <div style={{ width: 40, height: 4, borderRadius: 2, background: "#E5E7EB", margin: "12px auto 0" }} />
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px 12px" }}>
          <span style={{ fontWeight: 700, fontSize: 17, color: "#111827" }}>{title}</span>
          <button onClick={onClose} style={{ border: "none", background: "none", fontSize: 22, color: "#9CA3AF", cursor: "pointer", padding: 0, lineHeight: 1 }}>x</button>
        </div>
        <div style={{ padding: "0 20px" }}>{children}</div>
      </motion.div>
    </div>
  );
}
function MBadge({ text, color = "#7C3AED" }: { text: string; color?: string }) {
  return <span style={{ fontSize: 11, fontWeight: 700, color, background: color + "18", padding: "3px 9px", borderRadius: 20 }}>{text}</span>;
}
function MInput2({ label, value, onChange, placeholder = "", type = "text" }: { label?: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && <div style={{ fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 6 }}>{label}</div>}
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        style={{ width: "100%", padding: "11px 14px", border: "1.5px solid #E5E7EB", borderRadius: 12, fontSize: 14, color: "#111827", outline: "none", fontFamily: "'Inter',sans-serif", boxSizing: "border-box" }} />
    </div>
  );
}
function MSelect2({ label, value, onChange, options }: { label?: string; value: string; onChange: (v: string) => void; options: {value:string;label:string}[] }) {
  return (
    <div style={{ marginBottom: 14 }}>
      {label && <div style={{ fontSize: 13, fontWeight: 600, color: "#374151", marginBottom: 6 }}>{label}</div>}
      <select value={value} onChange={e => onChange(e.target.value)}
        style={{ width: "100%", padding: "11px 14px", border: "1.5px solid #E5E7EB", borderRadius: 12, fontSize: 14, color: "#111827", background: "#fff", fontFamily: "'Inter',sans-serif", boxSizing: "border-box" }}>
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  );
}
function MPrimaryBtn2({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button onClick={onClick}
      style={{ width: "100%", padding: "14px", background: "linear-gradient(135deg,#7C3AED,#6D28D9)", color: "#fff", border: "none", borderRadius: 14, fontSize: 15, fontWeight: 700, cursor: "pointer", fontFamily: "'Inter',sans-serif", marginTop: 8 }}>
      {label}
    </button>
  );
}
function MDelConfirm({ open, name, onClose, onConfirm }: { open: boolean; name: string; onClose: () => void; onConfirm: () => void }) {
  if (!open) return null;
  return (
    <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)", zIndex: 130, display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
      <motion.div initial={{ scale: 0.85, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        style={{ background: "#fff", borderRadius: 20, padding: "24px 20px", width: "100%", maxWidth: 320 }}>
        <div style={{ fontSize: 32, textAlign: "center", marginBottom: 12 }}>🗑️</div>
        <div style={{ fontWeight: 700, fontSize: 16, color: "#111827", textAlign: "center", marginBottom: 8 }}>Delete "{name}"?</div>
        <div style={{ fontSize: 13, color: "#6B7280", textAlign: "center", marginBottom: 20 }}>This action cannot be undone.</div>
        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, padding: "12px", border: "1.5px solid #E5E7EB", borderRadius: 12, background: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer", color: "#374151", fontFamily: "'Inter',sans-serif" }}>Cancel</button>
          <button onClick={() => { onConfirm(); onClose(); }} style={{ flex: 1, padding: "12px", border: "none", borderRadius: 12, background: "#EF4444", color: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer", fontFamily: "'Inter',sans-serif" }}>Delete</button>
        </div>
      </motion.div>
    </div>
  );
}
function MBottomNav({ tab, setTab }: { tab: MTab; setTab: (t: MTab) => void }) {
  const items: { id: MTab; label: string; icon: React.ReactNode }[] = [
    { id: "home",         label: "Home",    icon: <LayoutDashboard size={22} /> },
    { id: "content",      label: "Content", icon: <BookOpen size={22} /> },
    { id: "users",        label: "Users",   icon: <Users size={22} /> },
    { id: "achievements", label: "Awards",  icon: <Award size={22} /> },
    { id: "settings",     label: "Settings",icon: <Settings size={22} /> },
  ];
  return (
    <div style={{ display: "flex", background: "#fff", borderTop: "1px solid #F3F4F6", flexShrink: 0 }}>
      {items.map(t => {
        const active = tab === t.id;
        return (
          <button key={t.id} onClick={() => setTab(t.id)}
            style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 3, padding: "10px 4px 12px", border: "none", background: "none", cursor: "pointer", color: active ? MP2 : "#9CA3AF", fontFamily: "'Inter',sans-serif", transition: "color .15s" }}>
            {t.icon}
            <span style={{ fontSize: 10, fontWeight: active ? 700 : 500 }}>{t.label}</span>
            {active && <div style={{ width: 20, height: 3, borderRadius: 2, background: MP2 }} />}
          </button>
        );
      })}
    </div>
  );
}
function MHomeScreen({ goContent, goUsers }: { goContent: () => void; goUsers: () => void }) {
  const [notifOpen, setNotifOpen] = useState(false);
  const stats = [
    { label: "Parents",  value: "1,248", icon: <Users size={20} />,      grad: ["#7C3AED","#6D28D9"] },
    { label: "Children", value: "3,692", icon: <Baby size={20} />,        grad: ["#3B82F6","#1D4ED8"] },
    { label: "Lessons",  value: "45.2K", icon: <BookOpen size={20} />,    grad: ["#10B981","#059669"] },
    { label: "Daily",    value: "1,847", icon: <TrendingUp size={20} />,  grad: ["#F59E0B","#D97706"] },
    { label: "Topics",   value: "5",     icon: <FolderOpen size={20} />,  grad: ["#EC4899","#DB2777"] },
  ];
  return (
    <div style={{ flex: 1, overflowY: "auto", scrollbarWidth: "none" }}>
      <div style={{ background: "linear-gradient(135deg,#7C3AED 0%,#4C1D95 100%)", padding: "16px 20px 28px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: -40, right: -40, width: 160, height: 160, borderRadius: "50%", background: "rgba(255,255,255,0.07)" }} />
        <div style={{ position: "absolute", bottom: -30, left: -20, width: 120, height: 120, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
        <div style={{ display: "flex", alignItems: "center", gap: 12, position: "relative" }}>
          <div style={{ width: 44, height: 44, borderRadius: "50%", background: "rgba(255,255,255,0.22)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>🅐</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.7)", fontWeight: 500 }}>Welcome back,</div>
            <div style={{ fontSize: 20, color: "#fff", fontWeight: 800 }}>Admin 👋</div>
          </div>
          <button onClick={() => setNotifOpen(v => !v)}
            style={{ width: 40, height: 40, borderRadius: "50%", border: "none", background: "rgba(255,255,255,0.18)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
            <Bell size={18} color="#fff" />
            <span style={{ position: "absolute", top: 8, right: 9, width: 8, height: 8, borderRadius: "50%", background: "#EF4444", border: "2px solid transparent" }} />
          </button>
        </div>
        <div style={{ marginTop: 16, background: "rgba(255,255,255,0.15)", borderRadius: 14, padding: "10px 14px", display: "flex", alignItems: "center", gap: 8, position: "relative" }}>
          <Search size={16} color="rgba(255,255,255,0.7)" />
          <span style={{ fontSize: 14, color: "rgba(255,255,255,0.55)" }}>Search users, topics, lessons...</span>
        </div>
        {notifOpen && (
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }}
            style={{ position: "absolute", top: 96, right: 16, width: 260, background: "#fff", borderRadius: 16, boxShadow: "0 8px 32px rgba(0,0,0,0.2)", zIndex: 50, overflow: "hidden" }}>
            <div style={{ padding: "12px 16px", borderBottom: "1px solid #F3F4F6", fontWeight: 700, fontSize: 14, color: "#111827" }}>Notifications</div>
            {["New parent: Sarah L. registered","Emma J. earned 3-star rating!","Daily active users up +12%"].map((n, i) => (
              <div key={i} style={{ padding: "11px 16px", borderBottom: i < 2 ? "1px solid #F9FAFB" : "none", fontSize: 13, color: "#374151", display: "flex", gap: 8, alignItems: "flex-start" }}>
                <div style={{ width: 8, height: 8, borderRadius: "50%", background: MP2, flexShrink: 0, marginTop: 4 }} />{n}
              </div>
            ))}
          </motion.div>
        )}
      </div>
      <div style={{ padding: "0 0 24px" }}>
        <div style={{ padding: "16px 0 4px" }}>
          <div style={{ padding: "0 20px 10px", fontSize: 15, fontWeight: 700, color: "#111827" }}>Overview</div>
          <div style={{ display: "flex", gap: 12, overflowX: "auto", padding: "4px 20px 8px", scrollbarWidth: "none" }}>
            {stats.map((s, i) => (
              <div key={i} style={{ flexShrink: 0, width: 130, background: "linear-gradient(135deg," + s.grad[0] + "," + s.grad[1] + ")", borderRadius: 18, padding: "16px 14px", color: "#fff" }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: "rgba(255,255,255,0.22)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>{s.icon}</div>
                <div style={{ fontSize: 22, fontWeight: 800 }}>{s.value}</div>
                <div style={{ fontSize: 12, opacity: 0.8, marginTop: 2 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
        <div style={{ margin: "8px 20px 0", background: "#fff", borderRadius: 20, padding: "16px 12px 8px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: "#111827", marginBottom: 12, paddingLeft: 4 }}>Weekly Learning Activity</div>
          <ResponsiveContainer width="100%" height={140}>
            <AreaChart data={ACTIVITY_CHART_DATA} margin={{ top: 0, right: 4, left: -24, bottom: 0 }}>
              <defs>
                <linearGradient id="adminGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#7C3AED" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#7C3AED" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
              <XAxis dataKey="day" tick={{ fontSize: 11, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 10, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ borderRadius: 10, border: "1px solid #E5E7EB", fontSize: 12 }} />
              <Area type="monotone" dataKey="v" stroke="#7C3AED" fill="url(#adminGrad)" strokeWidth={2.5} dot={false} name="Sessions" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div style={{ margin: "14px 20px 0", background: "#fff", borderRadius: 20, padding: "16px 12px 12px", boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: "#111827", marginBottom: 12, paddingLeft: 4 }}>Children by Age Group</div>
          <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
            {AGE_CHART_DATA.map((d, i) => {
              const maxV = Math.max(...AGE_CHART_DATA.map(x => x.value));
              const h = Math.round((d.value / maxV) * 80);
              return (
                <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
                  <div style={{ width: "100%", height: h, background: d.fill, borderRadius: "6px 6px 0 0" }} />
                  <div style={{ fontSize: 11, color: "#9CA3AF", textAlign: "center" }}>{d.name}</div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: "#374151" }}>{d.value}</div>
                </div>
              );
            })}
          </div>
        </div>
        <div style={{ margin: "18px 20px 0" }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: "#111827", marginBottom: 12 }}>Recent Activities</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {RECENT_ACTS.map((a, i) => (
              <motion.div key={i} initial={{ x: -16, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={{ delay: i * 0.06 }}
                style={{ background: "#fff", borderRadius: 16, padding: "12px 14px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12, borderLeft: "4px solid " + a.color }}>
                <div style={{ width: 38, height: 38, borderRadius: "50%", background: a.color + "18", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, flexShrink: 0 }}>{a.avatar}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "#111827" }}>{a.name}</div>
                  <div style={{ fontSize: 12, color: "#6B7280", marginTop: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{a.action}</div>
                </div>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 2, flexShrink: 0 }}>
                  <span style={{ fontSize: 13 }}>{a.badge}</span>
                  <span style={{ fontSize: 11, color: "#9CA3AF" }}>{a.time}</span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
        <div style={{ margin: "18px 20px 0" }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: "#111827", marginBottom: 12 }}>Quick Actions</div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            {[
              { label: "Add Topic",    emoji: "🗂️", color: "#7C3AED", action: goContent },
              { label: "Add Lesson",   emoji: "📖", color: "#3B82F6", action: goContent },
              { label: "Add Vocab",    emoji: "✏️", color: "#10B981", action: goContent },
              { label: "Manage Users", emoji: "👥", color: "#F59E0B", action: goUsers  },
            ].map((q, i) => (
              <motion.button key={i} whileTap={{ scale: 0.95 }} onClick={q.action}
                style={{ background: "#fff", borderRadius: 18, padding: "18px 14px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", border: "none", cursor: "pointer", textAlign: "left", fontFamily: "'Inter',sans-serif" }}>
                <div style={{ width: 44, height: 44, borderRadius: 14, background: q.color + "16", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, marginBottom: 10 }}>{q.emoji}</div>
                <div style={{ fontSize: 14, fontWeight: 700, color: "#111827" }}>{q.label}</div>
                <div style={{ fontSize: 11, color: q.color, marginTop: 3, fontWeight: 600 }}>Tap to open</div>
              </motion.button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
function MContentScreen() {
  const [ctab, setCtab] = useState<CTab>("topics");
  const [topicsData, setTopicsData] = useState(ADMIN_TOPICS_DATA);
  const [lessonsData, setLessonsData] = useState(ADMIN_LESSONS_DATA);
  const [vocabData, setVocabData] = useState(ADMIN_VOCAB_DATA);
  const [addOpen, setAddOpen] = useState(false);
  const [deleteItem, setDeleteItem] = useState<any>(null);
  const [form, setForm] = useState<Record<string, string>>({ name: "", status: "Draft", topic: "Animals", difficulty: "Beginner", type: "Story", word: "", meaning: "", phonetic: "" });
  const diffColor: Record<string, string> = { Beginner: "#10B981", Elementary: "#3B82F6", "Pre-Intermediate": "#7C3AED" };
  const typeColor: Record<string, string>  = { Story: "#3B82F6", Dialogue: "#7C3AED", VideoShort: "#F59E0B", PronunciationDrill: "#EF4444" };
  const handleSave = () => {
    if (ctab === "topics")     setTopicsData(d => [...d, { id: Date.now(), name: form.name, lessons: 0, status: form.status, emoji: "📂" }]);
    if (ctab === "lessons")    setLessonsData(d => [...d, { id: Date.now(), name: form.name, topic: form.topic, difficulty: form.difficulty, type: form.type, status: "Draft" }]);
    if (ctab === "vocabulary") setVocabData(d => [...d, { id: Date.now(), word: form.word, meaning: form.meaning, phonetic: form.phonetic, emoji: "📝" }]);
    setAddOpen(false);
    setForm({ name: "", status: "Draft", topic: "Animals", difficulty: "Beginner", type: "Story", word: "", meaning: "", phonetic: "" });
  };
  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, overflow: "hidden" }}>
      <div style={{ background: "linear-gradient(135deg,#3B82F6 0%,#1D4ED8 100%)", padding: "16px 20px 20px" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ fontSize: 22, fontWeight: 800, color: "#fff" }}>Content</div>
          <motion.button whileTap={{ scale: 0.9 }} onClick={() => setAddOpen(true)}
            style={{ width: 40, height: 40, borderRadius: "50%", border: "none", background: "rgba(255,255,255,0.2)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Plus size={22} color="#fff" />
          </motion.button>
        </div>
        <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
          {(["topics","lessons","vocabulary"] as CTab[]).map(t => (
            <button key={t} onClick={() => setCtab(t)}
              style={{ flex: 1, padding: "8px 0", border: "none", borderRadius: 10, background: ctab === t ? "#fff" : "rgba(255,255,255,0.18)", color: ctab === t ? "#3B82F6" : "#fff", fontWeight: 700, fontSize: 12, cursor: "pointer", fontFamily: "'Inter',sans-serif", transition: "all .15s" }}>
              {t === "vocabulary" ? "Vocab" : t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>
      <div style={{ flex: 1, overflowY: "auto", padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10, scrollbarWidth: "none" }}>
        {ctab === "topics" && topicsData.map((t, i) => (
          <motion.div key={t.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
            style={{ background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 48, height: 48, borderRadius: 14, background: MPL2, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, flexShrink: 0 }}>{t.emoji}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 15, color: "#111827" }}>{t.name}</div>
              <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 2 }}>{t.lessons} lessons</div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 8 }}>
              <MBadge text={t.status} color={t.status === "Published" ? "#059669" : "#D97706"} />
              <button onClick={() => setDeleteItem({ ...t, _type: "topic" })} style={{ border: "none", background: "none", cursor: "pointer", padding: 4 }}><Trash2 size={15} color="#EF4444" /></button>
            </div>
          </motion.div>
        ))}
        {ctab === "lessons" && lessonsData.map((l, i) => (
          <motion.div key={l.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
            style={{ background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)" }}>
            <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
              <div style={{ width: 44, height: 44, borderRadius: 12, background: (diffColor[l.difficulty] || "#3B82F6") + "18", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, flexShrink: 0 }}>📖</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{l.name}</div>
                <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 2 }}>{l.topic}</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8, flexWrap: "wrap" }}>
                  <MBadge text={l.difficulty} color={diffColor[l.difficulty] || "#3B82F6"} />
                  <MBadge text={l.type}       color={typeColor[l.type]       || "#6B7280"} />
                  <MBadge text={l.status}     color={l.status === "Published" ? "#059669" : "#D97706"} />
                </div>
              </div>
              <button onClick={() => setDeleteItem({ ...l, _type: "lesson" })} style={{ border: "none", background: "none", cursor: "pointer", padding: 4, flexShrink: 0 }}><Trash2 size={15} color="#EF4444" /></button>
            </div>
          </motion.div>
        ))}
        {ctab === "vocabulary" && vocabData.map((v, i) => (
          <motion.div key={v.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
            style={{ background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 48, height: 48, borderRadius: 14, background: "#FEF3C7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 26, flexShrink: 0 }}>{v.emoji}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 16, color: "#111827" }}>{v.word}</div>
              <div style={{ fontSize: 12, color: "#3B82F6", fontFamily: "monospace", marginTop: 1 }}>{v.phonetic}</div>
              <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{v.meaning}</div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 8 }}>
              <button style={{ width: 34, height: 34, borderRadius: "50%", border: "none", background: MPL2, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><Play size={14} color={MP2} /></button>
              <button onClick={() => setDeleteItem({ ...v, _type: "vocab", name: v.word })} style={{ border: "none", background: "none", cursor: "pointer", padding: 4 }}><Trash2 size={15} color="#EF4444" /></button>
            </div>
          </motion.div>
        ))}
      </div>
      <MSheet open={addOpen} onClose={() => setAddOpen(false)} title={ctab === "topics" ? "Add Topic" : ctab === "lessons" ? "Add Lesson" : "Add Vocabulary"}>
        {ctab === "topics" && (<><MInput2 label="Topic Name" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="e.g. Animals" /><MSelect2 label="Status" value={form.status} onChange={v => setForm(f => ({ ...f, status: v }))} options={[{value:"Draft",label:"Draft"},{value:"Published",label:"Published"}]} /></>)}
        {ctab === "lessons" && (<><MInput2 label="Lesson Name" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="e.g. Farm Animals" /><MSelect2 label="Topic" value={form.topic} onChange={v => setForm(f => ({ ...f, topic: v }))} options={ADMIN_TOPICS_DATA.map(t => ({ value: t.name, label: t.name }))} /><MSelect2 label="Difficulty" value={form.difficulty} onChange={v => setForm(f => ({ ...f, difficulty: v }))} options={["Beginner","Elementary","Pre-Intermediate"].map(x => ({ value: x, label: x }))} /><MSelect2 label="Type" value={form.type} onChange={v => setForm(f => ({ ...f, type: v }))} options={["Story","Dialogue","VideoShort","PronunciationDrill"].map(x => ({ value: x, label: x }))} /></>)}
        {ctab === "vocabulary" && (<><MInput2 label="Word" value={form.word} onChange={v => setForm(f => ({ ...f, word: v }))} placeholder="e.g. Cat" /><MInput2 label="Meaning" value={form.meaning} onChange={v => setForm(f => ({ ...f, meaning: v }))} placeholder="e.g. A small furry animal" /><MInput2 label="Phonetic" value={form.phonetic} onChange={v => setForm(f => ({ ...f, phonetic: v }))} placeholder="e.g. /kæt/" /></>)}
        <MPrimaryBtn2 label="Save" onClick={handleSave} />
      </MSheet>
      <MDelConfirm open={!!deleteItem} name={deleteItem?.name ?? deleteItem?.word ?? ""} onClose={() => setDeleteItem(null)}
        onConfirm={() => {
          if (deleteItem?._type === "topic")  setTopicsData(d => d.filter(x => x.id !== deleteItem.id));
          if (deleteItem?._type === "lesson") setLessonsData(d => d.filter(x => x.id !== deleteItem.id));
          if (deleteItem?._type === "vocab")  setVocabData(d => d.filter(x => x.id !== deleteItem.id));
          setDeleteItem(null);
        }} />
    </div>
  );
}
function MUsersScreen() {
  const [utab, setUtab] = useState<UTab>("parents");
  const [search, setSearch] = useState("");
  const [parentsData] = useState(ADMIN_PARENTS_DATA);
  const [selectedParent, setSelectedParent] = useState<any>(null);
  const [selectedChild, setSelectedChild] = useState<any>(null);
  const fp = parentsData.filter(p => p.name.toLowerCase().includes(search.toLowerCase()) || p.email.toLowerCase().includes(search.toLowerCase()));
  const fc = ADMIN_CHILDREN_DATA.filter(c => c.name.toLowerCase().includes(search.toLowerCase()));
  if (selectedChild) {
    return (
      <div style={{ display: "flex", flexDirection: "column", flex: 1, overflow: "hidden" }}>
        <div style={{ background: "linear-gradient(135deg,#7C3AED 0%,#4C1D95 100%)", padding: "16px 20px 24px" }}>
          <button onClick={() => setSelectedChild(null)} style={{ display: "flex", alignItems: "center", gap: 6, border: "none", background: "none", color: "rgba(255,255,255,0.8)", cursor: "pointer", padding: 0, fontSize: 14, fontWeight: 600, fontFamily: "'Inter',sans-serif", marginBottom: 16 }}>
            <ArrowLeft size={16} /> Back
          </button>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ fontSize: 48 }}>{selectedChild.avatar}</div>
            <div><div style={{ fontSize: 20, fontWeight: 800, color: "#fff" }}>{selectedChild.name}</div><div style={{ fontSize: 13, color: "rgba(255,255,255,0.7)" }}>Age {selectedChild.age} — Level {selectedChild.level}</div></div>
          </div>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: 16, display: "flex", flexDirection: "column", gap: 12, scrollbarWidth: "none" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            {([["⭐ Stars", selectedChild.stars, "#F59E0B"],["🔥 Streak", selectedChild.streak+"d","#EF4444"],["📚 Lessons", selectedChild.lessons,"#3B82F6"],["🎤 Score", selectedChild.pronScore+"%","#7C3AED"]] as [string,any,string][]).map(([l,v,c]) => (
              <div key={l} style={{ background: "#fff", borderRadius: 16, padding: "16px 14px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
                <div style={{ fontSize: 22, fontWeight: 800, color: c }}>{v}</div>
                <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 3 }}>{l}</div>
              </div>
            ))}
          </div>
          <div style={{ background: "#fff", borderRadius: 18, padding: "16px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
            <div style={{ fontWeight: 700, fontSize: 14, color: "#111827", marginBottom: 12 }}>Achievement Progress</div>
            {ADMIN_ACHIEVEMENTS_DATA.slice(0, 4).map((a, i) => (
              <div key={a.id} style={{ display: "flex", alignItems: "center", gap: 10, padding: "9px 0", borderBottom: i < 3 ? "1px solid #F9FAFB" : "none" }}>
                <div style={{ width: 34, height: 34, borderRadius: 10, background: i < 3 ? MPL2 : "#F3F4F6", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>{a.emoji}</div>
                <div style={{ flex: 1 }}><div style={{ fontSize: 13, fontWeight: 600, color: i < 3 ? "#111827" : "#9CA3AF" }}>{a.name}</div></div>
                {i < 3 ? <Check size={16} color="#059669" /> : <Lock size={14} color="#D1D5DB" />}
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }
  if (selectedParent) {
    const kids = ADMIN_CHILDREN_DATA.filter(c => c.parentId === selectedParent.id);
    return (
      <div style={{ display: "flex", flexDirection: "column", flex: 1, overflow: "hidden" }}>
        <div style={{ background: "linear-gradient(135deg,#7C3AED 0%,#4C1D95 100%)", padding: "16px 20px 24px" }}>
          <button onClick={() => setSelectedParent(null)} style={{ display: "flex", alignItems: "center", gap: 6, border: "none", background: "none", color: "rgba(255,255,255,0.8)", cursor: "pointer", padding: 0, fontSize: 14, fontWeight: 600, fontFamily: "'Inter',sans-serif", marginBottom: 16 }}>
            <ArrowLeft size={16} /> Back
          </button>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 52, height: 52, borderRadius: "50%", background: "rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, fontWeight: 800, color: "#fff" }}>{selectedParent.name[0]}</div>
            <div><div style={{ fontSize: 18, fontWeight: 800, color: "#fff" }}>{selectedParent.name}</div><div style={{ fontSize: 12, color: "rgba(255,255,255,0.7)" }}>{selectedParent.email}</div></div>
          </div>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: 16, scrollbarWidth: "none" }}>
          <div style={{ background: "#fff", borderRadius: 18, padding: "16px", marginBottom: 14, boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
            {([["Status", selectedParent.status],["Registered", selectedParent.date],["Children", selectedParent.children]] as [string,any][]).map(([k,v]) => (
              <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "9px 0", borderBottom: "1px solid #F9FAFB" }}>
                <span style={{ fontSize: 13, color: "#9CA3AF" }}>{k}</span>
                <span style={{ fontSize: 13, fontWeight: 600, color: "#111827" }}>{v}</span>
              </div>
            ))}
          </div>
          <div style={{ fontSize: 15, fontWeight: 700, color: "#111827", marginBottom: 12 }}>Children ({kids.length})</div>
          {kids.map(c => (
            <motion.button key={c.id} whileTap={{ scale: 0.97 }} onClick={() => setSelectedChild(c)}
              style={{ width: "100%", background: "#fff", borderRadius: 16, padding: "14px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12, border: "none", cursor: "pointer", fontFamily: "'Inter',sans-serif", marginBottom: 10, textAlign: "left" }}>
              <div style={{ fontSize: 36, flexShrink: 0 }}>{c.avatar}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{c.name} · Age {c.age}</div>
                <div style={{ display: "flex", gap: 10, marginTop: 6 }}>
                  <span style={{ fontSize: 12, color: "#F59E0B", fontWeight: 700 }}>⭐ {c.stars}</span>
                  <span style={{ fontSize: 12, color: "#EF4444", fontWeight: 700 }}>🔥 {c.streak}d</span>
                  <span style={{ fontSize: 12, color: MP2, fontWeight: 700 }}>Lv {c.level}</span>
                </div>
              </div>
              <ChevronRight size={18} color="#D1D5DB" />
            </motion.button>
          ))}
        </div>
      </div>
    );
  }
  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, overflow: "hidden" }}>
      <div style={{ background: "linear-gradient(135deg,#7C3AED 0%,#4C1D95 100%)", padding: "16px 20px 20px" }}>
        <div style={{ fontSize: 22, fontWeight: 800, color: "#fff", marginBottom: 14 }}>Users</div>
        <div style={{ background: "rgba(255,255,255,0.18)", borderRadius: 14, padding: "10px 14px", display: "flex", alignItems: "center", gap: 8, marginBottom: 14 }}>
          <Search size={16} color="rgba(255,255,255,0.7)" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search by name or email..."
            style={{ flex: 1, border: "none", background: "none", color: "#fff", fontSize: 14, outline: "none", fontFamily: "'Inter',sans-serif" }} />
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          {(["parents","children"] as UTab[]).map(t => (
            <button key={t} onClick={() => setUtab(t)}
              style={{ flex: 1, padding: "8px 0", border: "none", borderRadius: 10, background: utab === t ? "#fff" : "rgba(255,255,255,0.18)", color: utab === t ? MP2 : "#fff", fontWeight: 700, fontSize: 13, cursor: "pointer", fontFamily: "'Inter',sans-serif", transition: "all .15s", textTransform: "capitalize" }}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>
      <div style={{ flex: 1, overflowY: "auto", padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10, scrollbarWidth: "none" }}>
        {utab === "parents" && fp.map((p, i) => (
          <motion.button key={p.id} whileTap={{ scale: 0.97 }} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
            onClick={() => setSelectedParent(p)}
            style={{ background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12, border: "none", cursor: "pointer", fontFamily: "'Inter',sans-serif", textAlign: "left", width: "100%" }}>
            <div style={{ width: 44, height: 44, borderRadius: "50%", background: "linear-gradient(135deg,#7C3AED,#6D28D9)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontWeight: 700, fontSize: 18, flexShrink: 0 }}>{p.name[0]}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{p.name}</div>
              <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{p.email}</div>
              <div style={{ display: "flex", gap: 8, marginTop: 4 }}>
                <MBadge text={p.status} color={p.status === "Active" ? "#059669" : "#EF4444"} />
                <span style={{ fontSize: 11, color: "#9CA3AF" }}>{p.children} children</span>
              </div>
            </div>
            <ChevronRight size={16} color="#D1D5DB" />
          </motion.button>
        ))}
        {utab === "children" && fc.map((c, i) => (
          <motion.button key={c.id} whileTap={{ scale: 0.97 }} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
            onClick={() => setSelectedChild(c)}
            style={{ background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)", display: "flex", alignItems: "center", gap: 12, border: "none", cursor: "pointer", fontFamily: "'Inter',sans-serif", textAlign: "left", width: "100%" }}>
            <div style={{ fontSize: 38, flexShrink: 0 }}>{c.avatar}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: "#111827" }}>{c.name} <span style={{ fontWeight: 500, color: "#9CA3AF" }}>Age {c.age}</span></div>
              <div style={{ display: "flex", gap: 10, marginTop: 6 }}>
                <span style={{ fontSize: 12, color: "#F59E0B", fontWeight: 700 }}>⭐ {c.stars}</span>
                <span style={{ fontSize: 12, color: "#EF4444", fontWeight: 700 }}>🔥 {c.streak}d</span>
                <span style={{ fontSize: 12, color: MP2, fontWeight: 700 }}>Lv {c.level}</span>
              </div>
            </div>
            <ChevronRight size={16} color="#D1D5DB" />
          </motion.button>
        ))}
      </div>
    </div>
  );
}
function MAchievementsScreen() {
  const [data, setData] = useState(ADMIN_ACHIEVEMENTS_DATA);
  const [addOpen, setAddOpen] = useState(false);
  const [deleteItem, setDeleteItem] = useState<any>(null);
  const [form, setForm] = useState({ name: "", desc: "", reqStars: "", reqStreak: "" });
  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, overflow: "hidden" }}>
      <div style={{ background: "linear-gradient(135deg,#F59E0B 0%,#D97706 100%)", padding: "16px 20px 24px" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ fontSize: 22, fontWeight: 800, color: "#fff" }}>Achievements</div>
          <motion.button whileTap={{ scale: 0.9 }} onClick={() => setAddOpen(true)}
            style={{ width: 40, height: 40, borderRadius: "50%", border: "none", background: "rgba(255,255,255,0.22)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Plus size={22} color="#fff" />
          </motion.button>
        </div>
        <div style={{ marginTop: 8, fontSize: 13, color: "rgba(255,255,255,0.8)" }}>{data.length} badges · {data.reduce((s, a) => s + a.unlocks, 0).toLocaleString()} total unlocks</div>
      </div>
      <div style={{ flex: 1, overflowY: "auto", padding: "14px 16px", display: "flex", flexDirection: "column", gap: 10, scrollbarWidth: "none" }}>
        {data.map((a, i) => (
          <motion.div key={a.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}
            style={{ background: "#fff", borderRadius: 18, padding: "16px", boxShadow: "0 2px 10px rgba(0,0,0,0.06)" }}>
            <div style={{ display: "flex", alignItems: "flex-start", gap: 14 }}>
              <div style={{ width: 52, height: 52, borderRadius: 16, background: "#FEF3C7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, flexShrink: 0 }}>{a.emoji}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: "#111827" }}>{a.name}</div>
                <div style={{ fontSize: 12, color: "#6B7280", marginTop: 2, lineHeight: 1.4 }}>{a.desc}</div>
                <div style={{ display: "flex", gap: 6, marginTop: 8, flexWrap: "wrap" }}>
                  {a.reqStars  > 0 && <MBadge text={"Stars: " + a.reqStars}   color="#D97706" />}
                  {a.reqStreak > 0 && <MBadge text={"Streak: " + a.reqStreak + "d"} color="#EF4444" />}
                </div>
              </div>
              <button onClick={() => setDeleteItem(a)} style={{ border: "none", background: "none", cursor: "pointer", padding: 4, flexShrink: 0 }}><Trash2 size={16} color="#EF4444" /></button>
            </div>
            <div style={{ marginTop: 12, paddingTop: 10, borderTop: "1px solid #F9FAFB", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={{ fontSize: 12, color: "#9CA3AF" }}>Unlocked by</span>
              <span style={{ fontSize: 14, fontWeight: 700, color: MP2 }}>{a.unlocks.toLocaleString()} children</span>
            </div>
          </motion.div>
        ))}
      </div>
      <MSheet open={addOpen} onClose={() => setAddOpen(false)} title="Add Achievement">
        <MInput2 label="Name" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="e.g. Super Reader" />
        <MInput2 label="Description" value={form.desc} onChange={v => setForm(f => ({ ...f, desc: v }))} placeholder="How to earn this badge?" />
        <MInput2 label="Required Stars" value={form.reqStars} onChange={v => setForm(f => ({ ...f, reqStars: v }))} type="number" placeholder="0" />
        <MInput2 label="Required Streak (days)" value={form.reqStreak} onChange={v => setForm(f => ({ ...f, reqStreak: v }))} type="number" placeholder="0" />
        <MPrimaryBtn2 label="Save Achievement" onClick={() => { setData(d => [...d, { id: Date.now(), name: form.name, desc: form.desc, emoji: "🎖️", unlocks: 0, reqStars: Number(form.reqStars||0), reqStreak: Number(form.reqStreak||0) }]); setAddOpen(false); setForm({ name: "", desc: "", reqStars: "", reqStreak: "" }); }} />
      </MSheet>
      <MDelConfirm open={!!deleteItem} name={deleteItem?.name ?? ""} onClose={() => setDeleteItem(null)} onConfirm={() => { setData(d => d.filter(a => a.id !== deleteItem?.id)); }} />
    </div>
  );
}
function MSettingsScreen({ onExit }: { onExit: () => void }) {
  const [saved, setSaved] = useState(false);
  return (
    <div style={{ flex: 1, overflowY: "auto", scrollbarWidth: "none" }}>
      <div style={{ background: "#fff", padding: "16px 20px 20px", borderBottom: "1px solid #F3F4F6" }}>
        <div style={{ fontSize: 22, fontWeight: 800, color: "#111827" }}>Settings</div>
        <div style={{ fontSize: 13, color: "#9CA3AF", marginTop: 4 }}>Configure your KIDIO platform</div>
      </div>
      <div style={{ padding: 16 }}>
        {[{title:"Platform",items:[{icon:"🎓",label:"App Name",value:"KIDIO"},{icon:"📧",label:"Support Email",value:"support@kidio.app"},{icon:"🔢",label:"Max Child Age",value:"10 years"},{icon:"🌐",label:"Language",value:"English"}]},{title:"Stats",items:[{icon:"👥",label:"Total Users",value:"4,940"},{icon:"⚡",label:"Active Today",value:"1,847"},{icon:"⏱",label:"Avg. Session",value:"18.4 min"},{icon:"🏆",label:"Top Topic",value:"Animals"}]}].map(sec => (
          <div key={sec.title} style={{ marginBottom: 20 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: "#9CA3AF", textTransform: "uppercase", letterSpacing: "0.8px", marginBottom: 8, paddingLeft: 4 }}>{sec.title}</div>
            <div style={{ background: "#fff", borderRadius: 18, boxShadow: "0 2px 10px rgba(0,0,0,0.06)", overflow: "hidden" }}>
              {sec.items.map((item, i) => (
                <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 16px", borderBottom: i < sec.items.length - 1 ? "1px solid #F9FAFB" : "none" }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: MPL2, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18, flexShrink: 0 }}>{item.icon}</div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, color: "#9CA3AF" }}>{item.label}</div>
                    <div style={{ fontSize: 15, fontWeight: 600, color: "#111827", marginTop: 1 }}>{item.value}</div>
                  </div>
                  <ChevronRight size={16} color="#D1D5DB" />
                </div>
              ))}
            </div>
          </div>
        ))}
        <motion.button whileTap={{ scale: 0.96 }} onClick={() => { setSaved(true); setTimeout(() => setSaved(false), 2000); }}
          style={{ width: "100%", padding: "14px", background: "linear-gradient(135deg,#7C3AED,#6D28D9)", color: "#fff", border: "none", borderRadius: 14, fontSize: 15, fontWeight: 700, cursor: "pointer", fontFamily: "'Inter',sans-serif", marginBottom: 12 }}>
          {saved ? "Saved!" : "Save Settings"}
        </motion.button>
        <button onClick={onExit}
          style={{ width: "100%", padding: "14px", background: "#fff", color: "#EF4444", border: "1.5px solid #FECACA", borderRadius: 14, fontSize: 15, fontWeight: 700, cursor: "pointer", fontFamily: "'Inter',sans-serif" }}>
          Exit to KIDIO App
        </button>
      </div>
    </div>
  );
}
function AdminDashboard({ onExit }: { onExit: () => void }) {
  const [tab, setTab] = useState<MTab>("home");
  const hdrColors: Record<MTab, string> = { home: "#7C3AED", content: "#3B82F6", users: "#7C3AED", achievements: "#F59E0B", settings: "#fff" };
  return (
    <div style={{ position: "fixed", inset: 0, background: "linear-gradient(135deg,#1E1B4B,#312E81)", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "'Inter',sans-serif" }}>
      <div style={{ width: "100%", maxWidth: 430, height: "100%", maxHeight: 932, background: "#F8F9FA", display: "flex", flexDirection: "column", overflow: "hidden", position: "relative" }}>
        <div style={{ height: 44, background: hdrColors[tab], display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 20px", flexShrink: 0, transition: "background .3s" }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: tab === "settings" ? "#111827" : "#fff" }}>9:41</span>
          <div style={{ width: 120, height: 4, borderRadius: 2, background: tab === "settings" ? "#111827" : "#fff", opacity: 0.4 }} />
          <div style={{ display: "flex", gap: 5 }}>
            {[14,10,6].map((w, i) => <div key={i} style={{ width: w, height: w + 2, borderRadius: 1, background: tab === "settings" ? "#111827" : "#fff", opacity: 1 - i * 0.3 }} />)}
          </div>
        </div>
        <div style={{ flex: 1, overflow: "hidden", display: "flex", flexDirection: "column" }}>
          {tab === "home"         && <MHomeScreen goContent={() => setTab("content")} goUsers={() => setTab("users")} />}
          {tab === "content"      && <MContentScreen />}
          {tab === "users"        && <MUsersScreen />}
          {tab === "achievements" && <MAchievementsScreen />}
          {tab === "settings"     && <MSettingsScreen onExit={onExit} />}
        </div>
        <MBottomNav tab={tab} setTab={setTab} />
      </div>
    </div>
  );
}
