import { useState, useRef } from "react";
import { motion } from "motion/react";
import {
  Star, Flame, Mic, Volume2, ChevronLeft, ChevronRight,
  Check, Lock, Map, Zap, Trophy, User, Eye, EyeOff, Plus, X
} from "lucide-react";
import {
  BarChart, Bar, XAxis, Cell, ResponsiveContainer
} from "recharts";

type Screen =
  | "welcome" | "profiles" | "createProfile" | "map" | "lessonHub" | "vocab"
  | "listening" | "pronunciation" | "quiz" | "achievements" | "quest" | "boss" | "parent";

// ─── DATA ────────────────────────────────────────────────────────────────────

const VOCAB = [
  { word: "CAT",    emoji: "🐱", meaning: "A fluffy pet animal", color: "#ff8c00" },
  { word: "DOG",    emoji: "🐶", meaning: "Man's best friend",   color: "#ff5c9f" },
  { word: "BIRD",   emoji: "🐦", meaning: "It can fly in the sky", color: "#0877f2" },
  { word: "FISH",   emoji: "🐟", meaning: "Lives in the water",  color: "#03a566" },
  { word: "RABBIT", emoji: "🐰", meaning: "Has long ears",       color: "#9b59b6" },
];

const ISLANDS = [
  { id: 1, name: "Animals Island",  emoji: "🦁", color: "#03a566", bgColor: "#d4f5e7", unlocked: true,  stars: 3, total: 5 },
  { id: 2, name: "Food Island",     emoji: "🍎", color: "#ff8c00", bgColor: "#ffe8cc", unlocked: true,  stars: 2, total: 5 },
  { id: 3, name: "Family Island",   emoji: "👨‍👩‍👧", color: "#ff5c9f", bgColor: "#ffe0f0", unlocked: true,  stars: 1, total: 5 },
  { id: 4, name: "School Island",   emoji: "📚", color: "#0877f2", bgColor: "#e0f0ff", unlocked: false, stars: 0, total: 5 },
  { id: 5, name: "Space Island",    emoji: "🚀", color: "#9b59b6", bgColor: "#f0e0ff", unlocked: false, stars: 0, total: 5 },
];

const ACHIEVEMENTS = [
  { id: 1, title: "First Lesson",          emoji: "📖", desc: "Completed your very first lesson",  unlocked: true,  color: "#fde047", stars: 10  },
  { id: 2, title: "10 Lessons Done",       emoji: "🎯", desc: "Completed 10 full lessons",          unlocked: true,  color: "#ff8c00", stars: 50  },
  { id: 3, title: "100 Stars Earned",      emoji: "⭐", desc: "Collected 100 shining stars",        unlocked: true,  color: "#fde047", stars: 100 },
  { id: 4, title: "7 Day Streak",          emoji: "🔥", desc: "Learned 7 days in a row",            unlocked: true,  color: "#ef4444", stars: 70  },
  { id: 5, title: "Pronunciation Master",  emoji: "🎤", desc: "Perfect score 5 times in a row",    unlocked: false, color: "#ff5c9f", stars: 150 },
  { id: 6, title: "Quiz Champion",         emoji: "🏆", desc: "Scored 5/5 on a quiz",              unlocked: false, color: "#d4890a", stars: 200 },
  { id: 7, title: "Island Explorer",       emoji: "🗺️", desc: "Completed 3 islands",               unlocked: false, color: "#03a566", stars: 120 },
  { id: 8, title: "Boss Slayer",           emoji: "⚔️", desc: "Defeated the island boss",          unlocked: false, color: "#9b59b6", stars: 300 },
];

const QUESTS = [
  { id: 1, title: "Complete 2 Lessons",        emoji: "📖", progress: 2, total: 2,  done: true,  reward: 10, color: "#03a566" },
  { id: 2, title: "Practice Pronunciation ×3", emoji: "🎤", progress: 1, total: 3,  done: false, reward: 20, color: "#ff5c9f" },
  { id: 3, title: "Earn 5 Stars",              emoji: "⭐", progress: 3, total: 5,  done: false, reward: 15, color: "#fde047" },
  { id: 4, title: "Learn for 15 Minutes",      emoji: "⏱️", progress: 8, total: 15, done: false, reward: 25, color: "#0877f2" },
];

const QUIZ_QUESTIONS = [
  {
    id: 1,
    question: 'Which animal says "Meow"?',
    hint: "🔊 Listen to the sound clue!",
    bg: "linear-gradient(135deg, #9b59b6, #6c3483)",
    options: [
      { text: "Dog",    emoji: "🐶", color: "#0877f2", bg: "#deeeff" },
      { text: "Cat",    emoji: "🐱", color: "#ff5c9f", bg: "#ffe0f0" },
      { text: "Lion",   emoji: "🦁", color: "#ff8c00", bg: "#ffe8cc" },
      { text: "Rabbit", emoji: "🐰", color: "#9b59b6", bg: "#f0e0ff" },
    ],
    correct: 1,
  },
  {
    id: 2,
    question: "Which animal has a very long neck?",
    hint: "🌴 It eats leaves from tall trees!",
    bg: "linear-gradient(135deg, #0877f2, #0452b8)",
    options: [
      { text: "Elephant", emoji: "🐘", color: "#9b59b6", bg: "#f0e0ff" },
      { text: "Giraffe",  emoji: "🦒", color: "#ff8c00", bg: "#ffe8cc" },
      { text: "Hippo",    emoji: "🦛", color: "#0877f2", bg: "#deeeff" },
      { text: "Bear",     emoji: "🐻", color: "#03a566", bg: "#d4f5e7" },
    ],
    correct: 1,
  },
  {
    id: 3,
    question: "Which animal swims in the ocean?",
    hint: "🌊 It lives deep in the sea!",
    bg: "linear-gradient(135deg, #03a566, #016e42)",
    options: [
      { text: "Cat",   emoji: "🐱", color: "#ff5c9f", bg: "#ffe0f0" },
      { text: "Eagle", emoji: "🦅", color: "#ff8c00", bg: "#ffe8cc" },
      { text: "Whale", emoji: "🐋", color: "#0877f2", bg: "#deeeff" },
      { text: "Fox",   emoji: "🦊", color: "#9b59b6", bg: "#f0e0ff" },
    ],
    correct: 2,
  },
  {
    id: 4,
    question: "Which animal can fly in the sky?",
    hint: "🌤️ It has beautiful wings!",
    bg: "linear-gradient(135deg, #ff8c00, #c46000)",
    options: [
      { text: "Eagle",  emoji: "🦅", color: "#ff8c00", bg: "#ffe8cc" },
      { text: "Horse",  emoji: "🐴", color: "#9b59b6", bg: "#f0e0ff" },
      { text: "Pig",    emoji: "🐷", color: "#ff5c9f", bg: "#ffe0f0" },
      { text: "Cow",    emoji: "🐄", color: "#03a566", bg: "#d4f5e7" },
    ],
    correct: 0,
  },
  {
    id: 5,
    question: "Which is the largest land animal?",
    hint: "🏆 It has a big trunk and ears!",
    bg: "linear-gradient(135deg, #ff5c9f, #cc0f5a)",
    options: [
      { text: "Mouse",    emoji: "🐭", color: "#9b59b6", bg: "#f0e0ff" },
      { text: "Rabbit",   emoji: "🐰", color: "#ff5c9f", bg: "#ffe0f0" },
      { text: "Cat",      emoji: "🐱", color: "#ff8c00", bg: "#ffe8cc" },
      { text: "Elephant", emoji: "🐘", color: "#0877f2", bg: "#deeeff" },
    ],
    correct: 3,
  },
];

const BOSS_QS = [
  { word: "CAT",    correct: 1, options: ["🐶","🐱","🐟","🐰"] },
  { word: "APPLE",  correct: 2, options: ["🍕","🍰","🍎","🍌"] },
  { word: "ROCKET", correct: 0, options: ["🚀","🌙","⭐","👽"] },
  { word: "BOOK",   correct: 2, options: ["✏️","📐","📚","🎒"] },
];

const PROFILES = [
  { id: 1, name: "Emma", avatar: "👧", color: "#ff5c9f", level: 5, stars: 120, isNew: false },
  { id: 2, name: "Liam", avatar: "👦", color: "#0877f2", level: 3, stars: 75,  isNew: false },
  { id: 3, name: "Add Profile", avatar: "➕", color: "#c5d8e8", level: 0, stars: 0, isNew: true },
];

const AVATARS = [
  { emoji: "👧", label: "Girl",      color: "#ff5c9f", bg: "#ffe0f0" },
  { emoji: "👦", label: "Boy",       color: "#0877f2", bg: "#deeeff" },
  { emoji: "🐼", label: "Panda",     color: "#9b59b6", bg: "#f0e0ff" },
  { emoji: "🐰", label: "Rabbit",    color: "#ff8c00", bg: "#ffe8cc" },
  { emoji: "🐻", label: "Bear",      color: "#8b5a14", bg: "#f5e6cc" },
  { emoji: "🦊", label: "Fox",       color: "#e8541a", bg: "#ffe5d9" },
  { emoji: "🦁", label: "Lion",      color: "#d4890a", bg: "#fff0c0" },
  { emoji: "🐱", label: "Cat",       color: "#ff5c9f", bg: "#fff0f7" },
  { emoji: "🐨", label: "Koala",     color: "#5e7a8c", bg: "#e8eef3" },
  { emoji: "🐸", label: "Frog",      color: "#03a566", bg: "#d4f5e7" },
  { emoji: "🦋", label: "Butterfly", color: "#9b59b6", bg: "#f5e8ff" },
  { emoji: "🐧", label: "Penguin",   color: "#0877f2", bg: "#e0eeff" },
];

const AGE_PALETTE = ["#ff5c9f","#ff8c00","#d4890a","#03a566","#0877f2","#9b59b6","#e8541a"];

const LESSON_ACTIVITIES = [
  {
    id: 1, icon: "📖", title: "Learn Vocabulary",
    desc: "Learn 10 animal names with fun pictures!",
    gradFrom: "#03a566", gradTo: "#017a48", color: "#03a566",
    stars: 3, maxStars: 3, progress: 100, status: "done",
    reward: 10, scene: ["🐱","🐶","🐘","🌿","🌸"],
    navTo: "vocab",
  },
  {
    id: 2, icon: "🎧", title: "Listening Game",
    desc: "Hear the word, find the right animal!",
    gradFrom: "#0877f2", gradTo: "#0452b8", color: "#0877f2",
    stars: 2, maxStars: 3, progress: 66, status: "active",
    reward: 8, scene: ["🎧","🎵","🎶","🌤️","✨"],
    navTo: "listening",
  },
  {
    id: 3, icon: "🎤", title: "Pronunciation Challenge",
    desc: "Say the animal names out loud!",
    gradFrom: "#ff5c9f", gradTo: "#cc0f5a", color: "#ff5c9f",
    stars: 0, maxStars: 3, progress: 0, status: "ready",
    reward: 12, scene: ["🎤","🌟","💫","🎀","✨"],
    navTo: "pronunciation",
  },
  {
    id: 4, icon: "📝", title: "Quiz Challenge",
    desc: "Test everything you have learned!",
    gradFrom: "#ff8c00", gradTo: "#c46000", color: "#ff8c00",
    stars: 0, maxStars: 3, progress: 0, status: "ready",
    reward: 15, scene: ["📝","❓","🎯","⚡","🌟"],
    navTo: "quiz",
  },
  {
    id: 5, icon: "👑", title: "Boss Battle",
    desc: "Face the Animal King! Can you defeat it?",
    gradFrom: "#7b3fa8", gradTo: "#3d1260", color: "#9b59b6",
    stars: 0, maxStars: 5, progress: 0, status: "locked",
    reward: 30, scene: ["👑","⚔️","🔥","💎","🌟"],
    navTo: "boss", isBoss: true,
  },
] as const;

const WEEK_DATA = [
  { day: "Mon", mins: 12 },
  { day: "Tue", mins: 18 },
  { day: "Wed", mins: 8  },
  { day: "Thu", mins: 22 },
  { day: "Fri", mins: 15 },
  { day: "Sat", mins: 25 },
  { day: "Sun", mins: 10 },
];

// ─── PANDA MASCOT ─────────────────────────────────────────────────────────────

function KikiPanda({ size = 120, mood = "happy" }: {
  size?: number;
  mood?: "happy" | "listening" | "excited" | "celebrating" | "smart";
}) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" fill="none">
      {/* shadow */}
      <ellipse cx="60" cy="116" rx="26" ry="5" fill="rgba(0,0,0,0.09)" />
      {/* body */}
      <ellipse cx="60" cy="82" rx="31" ry="29" fill="white" stroke="#222" strokeWidth="1.5" />
      <ellipse cx="60" cy="85" rx="19" ry="17" fill="#f5f5f5" />
      {/* arms */}
      <ellipse cx="28" cy="78" rx="10" ry="13" fill="white" stroke="#222" strokeWidth="1.5" transform="rotate(-20 28 78)" />
      <ellipse cx="92" cy="78" rx="10" ry="13" fill="white" stroke="#222" strokeWidth="1.5" transform="rotate(20 92 78)" />
      {/* legs */}
      <ellipse cx="46" cy="106" rx="10" ry="7" fill="white" stroke="#222" strokeWidth="1.5" />
      <ellipse cx="74" cy="106" rx="10" ry="7" fill="white" stroke="#222" strokeWidth="1.5" />
      {/* head */}
      <circle cx="60" cy="46" r="29" fill="white" stroke="#222" strokeWidth="1.5" />
      {/* ears */}
      <circle cx="36" cy="20" r="12" fill="#2d2d2d" />
      <circle cx="84" cy="20" r="12" fill="#2d2d2d" />
      <circle cx="36" cy="20" r="7"  fill="#4a4a4a" />
      <circle cx="84" cy="20" r="7"  fill="#4a4a4a" />
      {/* eye patches */}
      <ellipse cx="49" cy="43" rx="10" ry="10" fill="#2d2d2d" />
      <ellipse cx="71" cy="43" rx="10" ry="10" fill="#2d2d2d" />
      {/* eyes */}
      <circle cx="49" cy="43" r="5.5" fill="white" />
      <circle cx="71" cy="43" r="5.5" fill="white" />
      <circle cx="50" cy="42" r="3"   fill="#1a1a1a" />
      <circle cx="72" cy="42" r="3"   fill="#1a1a1a" />
      {/* shine */}
      <circle cx="51.5" cy="40.5" r="1.2" fill="white" />
      <circle cx="73.5" cy="40.5" r="1.2" fill="white" />
      {/* nose */}
      <ellipse cx="60" cy="51" rx="4.5" ry="3" fill="#ffb3c6" />
      {/* cheeks */}
      <circle cx="43" cy="54" r="5.5" fill="#ffb3c6" opacity="0.65" />
      <circle cx="77" cy="54" r="5.5" fill="#ffb3c6" opacity="0.65" />
      {/* mouth */}
      {(mood === "happy" || mood === "smart") && <path d="M53 57 Q60 65 67 57" stroke="#222" strokeWidth="2" strokeLinecap="round" />}
      {mood === "listening"  && <ellipse cx="60" cy="58" rx="4" ry="2.5" fill="#222" />}
      {mood === "excited"    && <path d="M50 56 Q60 68 70 56" stroke="#222" strokeWidth="2" strokeLinecap="round" />}
      {mood === "celebrating" && (
        <>
          <path d="M50 56 Q60 68 70 56" stroke="#222" strokeWidth="2" strokeLinecap="round" />
          <path d="M8 30 L14 18 L18 30 Z" fill="#fde047" />
          <path d="M99 28 L107 16 L110 30 Z" fill="#ff5c9f" />
          <path d="M55 2 L60 -7 L65 2 Z" fill="#0877f2" />
          <circle cx="25" cy="70" r="4" fill="#fde047" opacity="0.8" />
          <circle cx="95" cy="72" r="3" fill="#ff5c9f" opacity="0.8" />
        </>
      )}
      {/* Smart mode: glasses + book */}
      {mood === "smart" && (
        <>
          {/* Left lens */}
          <rect x="35" y="33" width="26" height="18" rx="9" fill="rgba(100,200,255,0.18)" stroke="#3a3a3a" strokeWidth="2.5" />
          {/* Right lens */}
          <rect x="59" y="33" width="26" height="18" rx="9" fill="rgba(100,200,255,0.18)" stroke="#3a3a3a" strokeWidth="2.5" />
          {/* Bridge */}
          <path d="M61 42 L59 42" stroke="#3a3a3a" strokeWidth="2.5" strokeLinecap="round" />
          {/* Temple arms */}
          <path d="M35 41 L28 40" stroke="#3a3a3a" strokeWidth="2" strokeLinecap="round" />
          <path d="M85 41 L92 40" stroke="#3a3a3a" strokeWidth="2" strokeLinecap="round" />
          {/* Lens shine */}
          <ellipse cx="43" cy="38" rx="4" ry="2.5" fill="rgba(255,255,255,0.4)" transform="rotate(-25 43 38)" />
          {/* Book held in left arm */}
          <rect x="7" y="73" width="27" height="24" rx="4" fill="#ff8c00" stroke="#c46000" strokeWidth="1.5" />
          <line x1="20" y1="73" x2="20" y2="97" stroke="#c46000" strokeWidth="1.3" />
          <rect x="7" y="73" width="13" height="24" rx="3" fill="#ffaa40" />
          <line x1="10" y1="80" x2="17" y2="80" stroke="white" strokeWidth="1" opacity="0.75" />
          <line x1="10" y1="85" x2="17" y2="85" stroke="white" strokeWidth="1" opacity="0.75" />
          <line x1="10" y1="90" x2="17" y2="90" stroke="white" strokeWidth="1" opacity="0.75" />
        </>
      )}
    </svg>
  );
}

// ─── SHARED DECORATIONS ────────────────────────────────────────────────────────

function Cloud({ x, y, scale = 1, delay = 0 }: { x: string; y: string; scale?: number; delay?: number }) {
  return (
    <motion.div
      className="absolute pointer-events-none"
      style={{ left: x, top: y }}
      animate={{ x: [0, 8, 0], y: [0, -5, 0] }}
      transition={{ duration: 4 + delay, repeat: Infinity, ease: "easeInOut", delay }}
    >
      <svg width={84 * scale} height={50 * scale} viewBox="0 0 84 50" fill="none">
        <circle cx="22" cy="34" r="17" fill="white" opacity="0.92" />
        <circle cx="42" cy="24" r="23" fill="white" opacity="0.92" />
        <circle cx="62" cy="32" r="16" fill="white" opacity="0.92" />
        <rect x="10" y="34" width="64" height="16" rx="8" fill="white" opacity="0.92" />
      </svg>
    </motion.div>
  );
}

function Sparkle({ x, y, color = "#fde047" }: { x: string; y: string; color?: string }) {
  return (
    <motion.div
      className="absolute pointer-events-none select-none text-lg"
      style={{ left: x, top: y, color }}
      animate={{ rotate: [0, 180, 360], scale: [1, 1.35, 1] }}
      transition={{ duration: 3.2, repeat: Infinity, ease: "easeInOut" }}
    >✨</motion.div>
  );
}

// ─── TOP BAR ──────────────────────────────────────────────────────────────────

function TopBar({ stars, streak, onProfile }: { stars: number; streak: number; onProfile: () => void }) {
  return (
    <div className="flex-none h-14 flex items-center px-4 gap-3"
      style={{ background: "rgba(255,255,255,0.88)", backdropFilter: "blur(12px)", borderBottom: "1.5px solid rgba(16,45,84,0.07)" }}>
      <button onClick={onProfile}
        className="w-10 h-10 rounded-2xl flex items-center justify-center text-xl shadow-md"
        style={{ background: "linear-gradient(135deg, #ff5c9f, #ff1f6e)" }}>
        👧
      </button>
      <div className="flex items-center gap-2">
        <div className="flex items-center gap-1.5 px-3 py-1 rounded-2xl"
          style={{ background: "rgba(253,224,71,0.18)", border: "1.5px solid #fde047" }}>
          <Star size={13} fill="#fde047" stroke="#fde047" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b07800", fontSize: "14px" }}>{stars}</span>
        </div>
        <div className="flex items-center gap-1.5 px-3 py-1 rounded-2xl"
          style={{ background: "rgba(255,140,0,0.12)", border: "1.5px solid #ff8c00" }}>
          <Flame size={13} fill="#ff8c00" stroke="#ff8c00" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b04a00", fontSize: "14px" }}>{streak}</span>
        </div>
      </div>
      <div className="ml-auto text-xl font-black" style={{ fontFamily: "'Fredoka One', cursive", color: "#0877f2", letterSpacing: "2px" }}>
        KIDIO
      </div>
    </div>
  );
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────

function BottomNav({ current, onNav }: { current: Screen; onNav: (s: Screen) => void }) {
  const tabs = [
    { screen: "map" as Screen,          icon: <Map size={22} />,     label: "Map"    },
    { screen: "quest" as Screen,        icon: <Zap size={22} />,     label: "Quests" },
    { screen: "achievements" as Screen, icon: <Trophy size={22} />,  label: "Awards" },
    { screen: "parent" as Screen,       icon: <User size={22} />,    label: "Parent" },
  ];
  return (
    <div className="flex-none h-16 flex items-stretch border-t"
      style={{ background: "white", borderColor: "rgba(16,45,84,0.08)" }}>
      {tabs.map(t => {
        const active = current === t.screen;
        return (
          <button key={t.screen} onClick={() => onNav(t.screen)}
            className="flex-1 flex flex-col items-center justify-center gap-0.5 transition-colors"
            style={{ color: active ? "#ff5c9f" : "#b0c4d8" }}>
            {t.icon}
            <span className="text-xs font-black"
              style={{ fontFamily: "'Nunito', sans-serif", fontSize: "10px" }}>
              {t.label}
            </span>
            {active && (
              <motion.div className="w-1.5 h-1.5 rounded-full mt-0.5" layoutId="navdot"
                style={{ background: "#ff5c9f" }} />
            )}
          </button>
        );
      })}
    </div>
  );
}

// ─── SCREEN A — LOGIN ─────────────────────────────────────────────────────────

function WelcomeScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [showPw, setShowPw]     = useState(false);
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");

  return (
    <div className="relative w-full h-full overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>

      {/* ── Fixed decorative background (clouds + rainbow + sparkles) ── */}
      <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        {/* rainbow sits behind logo */}
        <div className="absolute" style={{ top: "2%", left: 0, right: 0, display: "flex", justifyContent: "center", opacity: 0.24 }}>
          <svg width="360" height="96" viewBox="0 0 360 96">
            {["#ff0000","#ff8c00","#fde047","#03a566","#0877f2","#9b59b6"].map((c, i) => (
              <path key={i} d={`M${6+i*7},96 Q180,${-38+i*13} ${354-i*7},96`}
                fill="none" stroke={c} strokeWidth="9" strokeLinecap="round" />
            ))}
          </svg>
        </div>
        <Cloud x="-14px" y="3%"  scale={1.1}  delay={0}   />
        <Cloud x="60%"   y="5%"  scale={0.72} delay={1.1} />
        <Sparkle x="7%"  y="12%" color="#fde047" />
        <Sparkle x="82%" y="9%"  color="#ff5c9f" />
        <Sparkle x="88%" y="52%" color="#a78bfa" />
      </div>

      {/* ── Scrollable content ── */}
      <div className="relative h-full overflow-y-auto flex flex-col" style={{ zIndex: 1 }}>

        {/* ── Logo block ── */}
        <motion.div className="flex flex-col items-center pt-9 pb-1 px-6"
          initial={{ y: -28, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.6 }}>
          <div style={{
            fontFamily: "'Fredoka One', cursive", fontSize: "70px", color: "white",
            letterSpacing: "6px", textShadow: "0 5px 0 #0566c5, 0 9px 26px rgba(5,102,197,0.44)", lineHeight: 1,
          }}>KIDIO</div>
          <div className="mt-1.5 font-black tracking-wide"
            style={{ fontFamily: "'Nunito', sans-serif", fontSize: "14px", color: "#102d54", opacity: 0.88 }}>
            🌍 Learn English Through Adventures
          </div>
        </motion.div>

        {/* ── Kiki + speech bubble (side-by-side, no overlap with logo) ── */}
        <motion.div className="flex items-center gap-3 px-5 pt-1 pb-3"
          initial={{ x: -20, opacity: 0 }} animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.28, duration: 0.55 }}>
          <motion.div className="flex-shrink-0"
            animate={{ y: [0, -9, 0] }} transition={{ duration: 2.8, repeat: Infinity, ease: "easeInOut" }}>
            <KikiPanda size={112} mood="happy" />
          </motion.div>
          <motion.div className="flex-1 rounded-3xl rounded-tl-sm px-4 py-3"
            style={{ background: "white", boxShadow: "0 8px 24px rgba(8,119,242,0.16)" }}
            initial={{ scale: 0 }} animate={{ scale: 1 }}
            transition={{ delay: 0.72, type: "spring", stiffness: 210 }}>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#102d54", fontSize: "13px", lineHeight: 1.45 }}>
              Hi friend! 👋
            </div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#0877f2", fontSize: "13px", lineHeight: 1.45 }}>
              Let's learn English together!
            </div>
            <div className="mt-1" style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 600, color: "#9ab0c8", fontSize: "11px" }}>
              Your adventure is waiting 🚀
            </div>
          </motion.div>
        </motion.div>

        {/* ── Auth form card ── */}
        <motion.div className="mx-4 rounded-3xl px-5 py-4 flex flex-col gap-3.5"
          style={{
            background: "rgba(255,255,255,0.93)",
            boxShadow: "0 14px 44px rgba(8,119,242,0.17)",
            backdropFilter: "blur(14px)",
          }}
          initial={{ y: 24, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.42, duration: 0.55 }}>

          {/* Email */}
          <div className="flex flex-col gap-1.5">
            <label style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#102d54", fontSize: "13px" }}>
              📧 Email Address
            </label>
            <input
              type="email" value={email} onChange={e => setEmail(e.target.value)}
              placeholder="your@email.com"
              className="w-full py-3 px-4 rounded-2xl outline-none"
              style={{
                fontFamily: "'Nunito', sans-serif", fontSize: "14px", color: "#102d54",
                background: "#f0f8ff", border: "2px solid #c8dff5",
                transition: "border-color 0.2s",
              }}
            />
          </div>

          {/* Password */}
          <div className="flex flex-col gap-1.5">
            <label style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#102d54", fontSize: "13px" }}>
              🔒 Password
            </label>
            <div className="relative">
              <input
                type={showPw ? "text" : "password"}
                value={password} onChange={e => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full py-3 pl-4 pr-11 rounded-2xl outline-none"
                style={{
                  fontFamily: "'Nunito', sans-serif", fontSize: "14px", color: "#102d54",
                  background: "#f0f8ff", border: "2px solid #c8dff5",
                  transition: "border-color 0.2s",
                }}
              />
              <button onClick={() => setShowPw(v => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center justify-center"
                style={{ color: "#9ab0c8" }}>
                {showPw ? <EyeOff size={19} /> : <Eye size={19} />}
              </button>
            </div>
            <div className="flex justify-end mt-0.5">
              <button style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#0877f2", fontSize: "12px" }}>
                Forgot Password?
              </button>
            </div>
          </div>

          {/* Login button */}
          <motion.button whileTap={{ scale: 0.95 }} onClick={() => onNav("profiles")}
            className="w-full py-3.5 rounded-2xl text-white"
            style={{
              fontFamily: "'Fredoka One', cursive", fontSize: "21px",
              background: "linear-gradient(135deg, #ff5c9f, #ff1f6e)",
              boxShadow: "0 6px 0 #b8154e, 0 10px 26px rgba(255,31,110,0.38)",
            }}>
            🚀 Login & Play!
          </motion.button>

          {/* Divider */}
          <div className="flex items-center gap-3">
            <div className="flex-1 h-px" style={{ background: "#e0eaf4" }} />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "12px" }}>or</span>
            <div className="flex-1 h-px" style={{ background: "#e0eaf4" }} />
          </div>

          {/* Google button */}
          <motion.button whileTap={{ scale: 0.95 }} onClick={() => onNav("profiles")}
            className="w-full py-3 rounded-2xl flex items-center justify-center gap-2.5"
            style={{
              fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "14px", color: "#102d54",
              background: "white", border: "2px solid #e0eaf4",
              boxShadow: "0 4px 14px rgba(0,0,0,0.07)",
            }}>
            <svg width="20" height="20" viewBox="0 0 48 48">
              <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
              <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
              <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
              <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
            </svg>
            Continue with Google
          </motion.button>
        </motion.div>

        {/* Register link */}
        <div className="text-center mt-3">
          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 600, fontSize: "13px", color: "#102d54", opacity: 0.72 }}>
            New here?{" "}
          </span>
          <button style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, fontSize: "13px", color: "#0877f2" }}>
            Create Account ✨
          </button>
        </div>

        {/* Bottom decoration strip */}
        <div className="flex justify-center items-end gap-1 pt-4 pb-2 mt-auto">
          {["🌸","⭐","🌺","✨","🌷","🌸","⭐","🌼","🌺","✨","🌸"].map((f, i) => (
            <motion.span key={i}
              animate={{ y: [0, i % 3 === 0 ? -4 : -2, 0] }}
              transition={{ duration: 1.8 + i * 0.2, repeat: Infinity, delay: i * 0.1 }}
              style={{ fontSize: i % 3 === 1 ? "13px" : "20px" }}>{f}</motion.span>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── SCREEN B — PROFILES ──────────────────────────────────────────────────────

function ProfilesScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [selected, setSelected] = useState<number | null>(null);

  const profileCards = [
    { id: 1, name: "Emma", avatar: "👧", avatarBg: "linear-gradient(135deg, #ffe0f0, #ffc8e0)", avatarBorder: "#ff5c9f40", color: "#ff5c9f", level: 5, stars: 120 },
    { id: 2, name: "Liam", avatar: "👦", avatarBg: "linear-gradient(135deg, #deeeff, #c0dcff)", avatarBorder: "#0877f240", color: "#0877f2", level: 3, stars: 75  },
  ];

  return (
    <div className="w-full h-full flex flex-col overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 55%, #c0ecff 100%)" }}>

      {/* ── Title header — clear band, no cloud overlap ── */}
      <motion.div className="flex-none pt-6 pb-4 px-5"
        style={{ zIndex: 10 }}
        initial={{ y: -22, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.55 }}>
        <div className="text-center">
          <div style={{
            fontFamily: "'Fredoka One', cursive", fontSize: "26px",
            color: "#102d54",
            textShadow: "0 1px 0 rgba(255,255,255,0.5)",
          }}>
            Who is playing today? 👋
          </div>
          <div className="mt-1" style={{
            fontFamily: "'Nunito', sans-serif", fontWeight: 700,
            fontSize: "13px", color: "#102d54", opacity: 0.7,
          }}>
            Choose your profile to continue your adventure
          </div>
        </div>
      </motion.div>

      {/* ── Scrollable body ── */}
      <div className="flex-1 overflow-y-auto px-4 pb-4" style={{ zIndex: 5 }}>

        {/* Profile grid — 2 cards side by side */}
        <div className="grid grid-cols-2 gap-3.5">
          {profileCards.map((p, i) => (
            <motion.button key={p.id}
              initial={{ y: 24, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.1 + i * 0.08 }}
              whileTap={{ scale: 0.94 }}
              onClick={() => { setSelected(p.id); setTimeout(() => onNav("map"), 280); }}
              className="rounded-3xl p-4 flex flex-col items-center gap-2.5 relative"
              style={{
                background: selected === p.id
                  ? `linear-gradient(145deg, ${p.color}0f, white)`
                  : "white",
                border: `3px solid ${selected === p.id ? p.color : "rgba(255,255,255,0.6)"}`,
                boxShadow: selected === p.id
                  ? `0 10px 28px ${p.color}35`
                  : "0 6px 20px rgba(8,119,242,0.11)",
              }}>
              {/* star badge */}
              <div className="absolute top-2.5 right-2.5 flex items-center gap-0.5 px-1.5 py-0.5 rounded-xl"
                style={{ background: "rgba(253,224,71,0.28)", border: "1.5px solid #fde047" }}>
                <Star size={9} fill="#fde047" stroke="#fde047" />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#b07800", fontSize: "10px" }}>
                  {p.stars}
                </span>
              </div>
              {/* avatar circle */}
              <div className="w-16 h-16 rounded-3xl flex items-center justify-center text-4xl"
                style={{ background: p.avatarBg, border: `3px solid ${p.avatarBorder}` }}>
                {p.avatar}
              </div>
              <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "19px" }}>
                {p.name}
              </div>
              <div className="px-3 py-1 rounded-2xl text-xs font-black text-white"
                style={{ background: p.color, fontFamily: "'Nunito', sans-serif" }}>
                ⭐ Level {p.level}
              </div>
              {/* selected ring glow */}
              {selected === p.id && (
                <motion.div className="absolute inset-0 rounded-3xl pointer-events-none"
                  initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                  style={{ boxShadow: `inset 0 0 0 2px ${p.color}60` }} />
              )}
            </motion.button>
          ))}
        </div>

        {/* Add / Create new profile — full-width card */}
        <motion.button
          initial={{ y: 24, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.26 }}
          whileTap={{ scale: 0.97 }}
          onClick={() => onNav("createProfile")}
          className="mt-3.5 w-full rounded-3xl p-4 flex items-center gap-4"
          style={{
            background: "rgba(255,255,255,0.78)",
            border: "2.5px dashed rgba(8,119,242,0.36)",
            backdropFilter: "blur(10px)",
            boxShadow: "0 4px 18px rgba(8,119,242,0.09)",
          }}>
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0"
            style={{
              background: "linear-gradient(135deg, #0877f2, #0566c5)",
              boxShadow: "0 5px 14px rgba(8,119,242,0.42)",
            }}>
            <Plus size={28} color="white" strokeWidth={2.5} />
          </div>
          <div className="text-left">
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "17px" }}>
              Create New Profile
            </div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "12px" }}>
              Add a child account to get started
            </div>
          </div>
          <ChevronRight size={20} color="#0877f2" className="ml-auto flex-shrink-0" />
        </motion.button>

        {/* ── Bottom section: Kiki + clouds + flowers ── */}
        <div className="relative mt-5 rounded-3xl overflow-hidden"
          style={{ background: "rgba(255,255,255,0.22)", backdropFilter: "blur(6px)", padding: "0 0 16px" }}>
          {/* clouds inside this container only */}
          <div className="absolute inset-0 pointer-events-none overflow-hidden rounded-3xl">
            <Cloud x="-5%"  y="8%"  scale={0.65} delay={0.3} />
            <Cloud x="55%"  y="0%"  scale={0.55} delay={1.1} />
            <Sparkle x="10%" y="60%" color="#fde047" />
            <Sparkle x="78%" y="55%" color="#ff5c9f" />
          </div>

          {/* Kiki + speech bubble */}
          <div className="relative z-10 flex items-end justify-center gap-3 pt-3 px-4">
            <motion.div className="flex-shrink-0"
              animate={{ y: [0, -9, 0] }} transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}>
              <KikiPanda size={112} mood="excited" />
            </motion.div>
            <motion.div className="mb-8 rounded-3xl rounded-tl-sm px-4 py-3"
              style={{ background: "white", boxShadow: "0 6px 18px rgba(8,119,242,0.14)", maxWidth: "148px" }}
              initial={{ scale: 0 }} animate={{ scale: 1 }}
              transition={{ delay: 0.6, type: "spring", stiffness: 200 }}>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#0877f2", fontSize: "12px", lineHeight: 1.45 }}>
                Choose your profile and let's go! 🌟
              </div>
            </motion.div>
          </div>

          {/* flowers + stars row */}
          <div className="relative z-10 flex justify-center items-center gap-1.5">
            {["🌸","⭐","🌺","✨","🌷","🌸","⭐","🌼","🌺"].map((f, i) => (
              <motion.span key={i}
                animate={{ y: [0, i % 2 === 0 ? -3 : -5, 0] }}
                transition={{ duration: 1.6 + i * 0.18, repeat: Infinity, delay: i * 0.08 }}
                style={{ fontSize: i % 3 === 1 ? "13px" : "19px" }}>{f}</motion.span>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}

// ─── SCREEN CREATE-PROFILE ────────────────────────────────────────────────────

function CreateProfileScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [selAvatar, setSelAvatar] = useState(0);
  const [name, setName]           = useState("");
  const [selAge, setSelAge]       = useState<number | null>(null);

  const av          = AVATARS[selAvatar];
  const displayName = name.trim() || "Your Name";
  const displayAge  = selAge ? `Age ${selAge}` : "Age ?";
  const canCreate   = name.trim().length > 0 && selAge !== null;

  return (
    <div className="w-full h-full flex flex-col relative"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 55%, #c0ecff 100%)" }}>

      {/* ── Decorative bg (cloud + sparkles, top-right only) ── */}
      <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <Cloud x="58%" y="1%" scale={0.65} delay={1.1} />
        <Sparkle x="5%"  y="42%" color="#fde047" />
        <Sparkle x="88%" y="58%" color="#ff5c9f" />
        <Sparkle x="80%" y="22%" color="#a78bfa" />
      </div>

      {/* ── Header ── */}
      <div className="flex-none px-4 pt-3 pb-3 flex items-center gap-3"
        style={{ background: "rgba(255,255,255,0.18)", backdropFilter: "blur(10px)", zIndex: 10 }}>
        <button onClick={() => onNav("profiles")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0"
          style={{ background: "rgba(255,255,255,0.82)", boxShadow: "0 3px 10px rgba(0,0,0,0.09)" }}>
          <ChevronLeft size={20} color="#102d54" />
        </button>
        <div className="flex-1 min-w-0">
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: "#102d54", lineHeight: 1.2 }}>
            Create Your Adventure Buddy! 🌟
          </div>
          <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 600, fontSize: "11px", color: "#102d54", opacity: 0.68 }}>
            Let's set up your profile and start learning English
          </div>
        </div>
      </div>

      {/* ── Scrollable form body ── */}
      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-4" style={{ zIndex: 5 }}>

        {/* ── Avatar selection ── */}
        <motion.div className="rounded-3xl p-4"
          style={{ background: "rgba(255,255,255,0.9)", boxShadow: "0 8px 28px rgba(8,119,242,0.13)" }}
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.08 }}>
          <div className="flex items-center gap-2 mb-3">
            <span style={{ fontSize: "20px" }}>🎭</span>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
              Choose Your Avatar
            </div>
          </div>
          <div className="grid grid-cols-4 gap-2.5">
            {AVATARS.map((a, i) => (
              <motion.button key={i} whileTap={{ scale: 0.88 }}
                onClick={() => setSelAvatar(i)}
                className="relative rounded-2xl flex flex-col items-center justify-center py-2.5 gap-0.5"
                style={{
                  background: selAvatar === i ? a.bg : "#f4f9ff",
                  border: `2.5px solid ${selAvatar === i ? a.color : "transparent"}`,
                  boxShadow: selAvatar === i ? `0 4px 16px ${a.color}40, 0 0 0 3px ${a.color}1a` : "none",
                  transition: "all 0.18s",
                }}>
                {selAvatar === i && (
                  <motion.div
                    className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full flex items-center justify-center"
                    initial={{ scale: 0 }} animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 320 }}
                    style={{ background: a.color, boxShadow: `0 2px 6px ${a.color}55` }}>
                    <Check size={11} color="white" strokeWidth={3} />
                  </motion.div>
                )}
                <span style={{ fontSize: "30px", lineHeight: 1 }}>{a.emoji}</span>
                <span style={{
                  fontFamily: "'Nunito', sans-serif", fontWeight: 700,
                  color: selAvatar === i ? a.color : "#b0c4d8", fontSize: "9px",
                }}>{a.label}</span>
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* ── Name input ── */}
        <motion.div className="rounded-3xl p-4"
          style={{ background: "rgba(255,255,255,0.9)", boxShadow: "0 8px 28px rgba(8,119,242,0.13)" }}
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.14 }}>
          <div className="flex items-center gap-2 mb-3">
            <span style={{ fontSize: "20px" }}>✍️</span>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
              What's your name?
            </div>
          </div>
          <input
            type="text" value={name} onChange={e => setName(e.target.value)}
            placeholder="Enter your name" maxLength={20}
            className="w-full py-3.5 px-4 rounded-2xl outline-none"
            style={{
              fontFamily: "'Nunito', sans-serif", fontWeight: 700,
              fontSize: "15px", color: "#102d54",
              background: "#f0f8ff", border: "2px solid #c8dff5",
              letterSpacing: "0.2px", transition: "border-color 0.2s",
            }}
          />
        </motion.div>

        {/* ── Age chips ── */}
        <motion.div className="rounded-3xl p-4"
          style={{ background: "rgba(255,255,255,0.9)", boxShadow: "0 8px 28px rgba(8,119,242,0.13)" }}
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.2 }}>
          <div className="flex items-center gap-2 mb-3">
            <span style={{ fontSize: "20px" }}>🎂</span>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
              How old are you?
            </div>
          </div>
          <div className="flex gap-2 justify-between">
            {[4, 5, 6, 7, 8, 9, 10].map((age, i) => {
              const c      = AGE_PALETTE[i];
              const active = selAge === age;
              return (
                <motion.button key={age} whileTap={{ scale: 0.84 }}
                  onClick={() => setSelAge(age)}
                  className="flex-1 rounded-2xl flex items-center justify-center"
                  style={{
                    paddingTop: "10px", paddingBottom: "10px",
                    background: active ? c : "#f0f8ff",
                    border: `2px solid ${active ? c : "#dde8f0"}`,
                    boxShadow: active ? `0 5px 14px ${c}44` : "none",
                    transition: "background 0.18s, border 0.18s, box-shadow 0.18s",
                  }}
                  animate={active ? { y: [0, -3, 0] } : { y: 0 }}
                  transition={{ duration: 0.3 }}>
                  <span style={{
                    fontFamily: "'Fredoka One', cursive", fontSize: "17px",
                    color: active ? "white" : "#9ab0c8",
                  }}>{age}</span>
                </motion.button>
              );
            })}
          </div>
        </motion.div>

        {/* ── Live preview card ── */}
        <motion.div className="rounded-3xl p-4"
          style={{ background: "rgba(255,255,255,0.9)", boxShadow: "0 8px 28px rgba(8,119,242,0.13)" }}
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.26 }}>
          <div className="flex items-center gap-2 mb-3">
            <span style={{ fontSize: "20px" }}>✨</span>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
              Your Profile Preview
            </div>
          </div>

          {/* card */}
          <div className="rounded-2xl p-4 flex items-center gap-4"
            style={{
              background: `linear-gradient(135deg, ${av.bg}, ${av.bg}88)`,
              border: `2px solid ${av.color}30`,
            }}>
            {/* animated avatar */}
            <motion.div
              key={selAvatar}
              className="w-16 h-16 rounded-2xl flex items-center justify-center flex-shrink-0"
              initial={{ scale: 0.55, rotate: -12 }} animate={{ scale: 1, rotate: 0 }}
              transition={{ type: "spring", stiffness: 260 }}
              style={{ background: "white", boxShadow: `0 5px 16px ${av.color}38` }}>
              <span style={{ fontSize: "34px" }}>{av.emoji}</span>
            </motion.div>

            {/* info */}
            <div className="flex-1 min-w-0">
              <motion.div key={name}
                initial={{ x: 8, opacity: 0 }} animate={{ x: 0, opacity: 1 }}
                style={{
                  fontFamily: "'Fredoka One', cursive", fontSize: "20px",
                  color: "#102d54", lineHeight: 1.2,
                  whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
                }}>
                {displayName}
              </motion.div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "13px", color: "#9ab0c8", marginTop: "2px" }}>
                {displayAge}
              </div>
              <div className="mt-2 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl"
                style={{ background: av.color }}>
                <Star size={11} fill="white" stroke="white" />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "white", fontSize: "10px" }}>
                  Level 1 · Starter
                </span>
              </div>
            </div>

            {/* decorative stars */}
            <div className="flex flex-col gap-1 items-center flex-shrink-0">
              {["⭐","🌟","✨"].map((s, i) => (
                <motion.span key={i} style={{ fontSize: "14px" }}
                  animate={{ scale: [1, 1.25, 1], rotate: [0, 10, 0] }}
                  transition={{ duration: 1.6 + i * 0.4, repeat: Infinity, delay: i * 0.3 }}>
                  {s}
                </motion.span>
              ))}
            </div>
          </div>
        </motion.div>

        {/* ── Kiki mascot + speech bubble ── */}
        <motion.div className="flex items-end gap-3 px-1"
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.32 }}>
          <motion.div className="flex-shrink-0"
            animate={{ y: [0, -9, 0] }} transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}>
            <KikiPanda size={104} mood="excited" />
          </motion.div>
          <motion.div className="mb-8 rounded-3xl rounded-tl-sm px-4 py-3 flex-1"
            style={{ background: "white", boxShadow: "0 6px 20px rgba(8,119,242,0.13)" }}
            initial={{ scale: 0 }} animate={{ scale: 1 }}
            transition={{ delay: 0.55, type: "spring", stiffness: 200 }}>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#ff5c9f", fontSize: "13px" }}>
              Great choice! 🎉
            </div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "12px", lineHeight: 1.45, marginTop: "3px" }}>
              Let's begin our adventure together! 🌟
            </div>
          </motion.div>
        </motion.div>

        {/* bottom spacer for fixed button */}
        <div style={{ height: "6px" }} />
      </div>

      {/* ── Fixed bottom create button ── */}
      <div className="flex-none px-4 py-3"
        style={{
          background: "rgba(255,255,255,0.72)",
          backdropFilter: "blur(12px)",
          borderTop: "1.5px solid rgba(16,45,84,0.07)",
          zIndex: 10,
        }}>
        <motion.button whileTap={{ scale: canCreate ? 0.95 : 1 }}
          onClick={() => canCreate && onNav("profiles")}
          className="w-full py-4 rounded-2xl text-white relative overflow-hidden"
          style={{
            fontFamily: "'Fredoka One', cursive", fontSize: "21px",
            background: canCreate
              ? "linear-gradient(135deg, #ff5c9f, #ff1f6e)"
              : "linear-gradient(135deg, #c8d8e8, #a8b8c8)",
            boxShadow: canCreate
              ? "0 6px 0 #b8154e, 0 10px 28px rgba(255,31,110,0.36)"
              : "none",
            transition: "all 0.3s",
            cursor: canCreate ? "pointer" : "default",
          }}>
          {canCreate ? "✨ Create Profile!" : "Fill in your details first 👆"}
        </motion.button>
        {!canCreate && (
          <div className="text-center mt-2"
            style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "11px", color: "#9ab0c8" }}>
            {!name.trim() && !selAge && "Choose avatar, name & age"}
            {name.trim() && !selAge && "Now choose your age!"}
            {!name.trim() && selAge && "Enter your name to continue!"}
          </div>
        )}
      </div>
    </div>
  );
}

// ─── SCREEN LESSON HUB ────────────────────────────────────────────────────────

/* ── helper to decide nav target for a card ── */
function actNavTarget(id: number): Screen | null {
  if (id === 1) return "vocab";
  if (id === 2) return "listening";
  if (id === 3) return "pronunciation";
  if (id === 4) return "quiz";
  if (id === 5) return "boss";
  return null;
}

function LessonHubScreen({ onNav }: { onNav: (s: Screen) => void }) {
  return (
    <div className="w-full h-full flex flex-col overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 50%, #c0ecff 100%)" }}>

      {/* ── Header ── */}
      <div className="flex-none flex items-center gap-3 px-4 py-3"
        style={{ background: "rgba(255,255,255,0.2)", backdropFilter: "blur(12px)", borderBottom: "1.5px solid rgba(255,255,255,0.3)" }}>
        <button onClick={() => onNav("map")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0"
          style={{ background: "rgba(255,255,255,0.82)", boxShadow: "0 3px 10px rgba(0,0,0,0.1)" }}>
          <ChevronLeft size={20} color="#102d54" />
        </button>
        <div className="flex-1 min-w-0">
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "19px", color: "#102d54", lineHeight: 1.1 }}>
            🦁 Animal Adventure
          </div>
          <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "11px", color: "#102d54", opacity: 0.65 }}>
            Choose your next challenge!
          </div>
        </div>
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl flex-shrink-0"
          style={{ background: "rgba(253,224,71,0.28)", border: "1.5px solid #fde047" }}>
          <Star size={13} fill="#fde047" stroke="#fde047" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b07800", fontSize: "13px" }}>5 / 15</span>
        </div>
      </div>

      {/* ── Scrollable body ── */}
      <div className="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-3">

        {/* ── Island welcome banner ── */}
        <motion.div className="rounded-3xl overflow-hidden"
          style={{ boxShadow: "0 10px 32px rgba(3,165,102,0.28)" }}
          initial={{ y: -16, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.5 }}>

          {/* scene strip */}
          <div className="relative px-4 pt-3 pb-2 overflow-hidden"
            style={{ background: "linear-gradient(135deg, #03a566 0%, #027a48 60%, #01603a 100%)", minHeight: "120px" }}>
            {/* floating background animals */}
            {[
              { e: "🦁", x: "12%",  y: "8px",  size: "28px" },
              { e: "🐘", x: "32%",  y: "6px",  size: "24px" },
              { e: "🐯", x: "60%",  y: "10px", size: "26px" },
              { e: "🌴", x: "76%",  y: "4px",  size: "28px" },
              { e: "🌸", x: "90%",  y: "12px", size: "20px" },
              { e: "🌿", x: "4%",   y: "55px", size: "20px" },
              { e: "🌺", x: "46%",  y: "58px", size: "18px" },
              { e: "🍃", x: "84%",  y: "54px", size: "18px" },
            ].map((d, i) => (
              <motion.span key={i}
                className="absolute pointer-events-none select-none"
                style={{ left: d.x, top: d.y, fontSize: d.size, opacity: 0.72 }}
                animate={{ y: [0, i % 2 === 0 ? -5 : -3, 0] }}
                transition={{ duration: 2.2 + i * 0.3, repeat: Infinity, delay: i * 0.18, ease: "easeInOut" }}>
                {d.e}
              </motion.span>
            ))}

            {/* Kiki + speech bubble */}
            <div className="relative z-10 flex items-end gap-3 mt-4">
              <motion.div className="flex-shrink-0"
                animate={{ y: [0, -9, 0] }} transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}>
                <KikiPanda size={92} mood="excited" />
              </motion.div>
              <motion.div className="mb-7 flex-1 rounded-3xl rounded-tl-sm px-3.5 py-2.5"
                style={{ background: "rgba(255,255,255,0.96)", boxShadow: "0 4px 14px rgba(0,0,0,0.16)" }}
                initial={{ scale: 0 }} animate={{ scale: 1 }}
                transition={{ delay: 0.4, type: "spring", stiffness: 210 }}>
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#03a566", fontSize: "12px" }}>
                  Welcome to Animals! 🎉
                </div>
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "11px", lineHeight: 1.42 }}>
                  Complete all 5 challenges to master animal names! I know you can do it! 🐾
                </div>
              </motion.div>
            </div>
          </div>

          {/* island progress strip */}
          <div className="px-4 py-2.5 flex items-center gap-3"
            style={{ background: "white" }}>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#102d54", fontSize: "12px", whiteSpace: "nowrap" }}>
              Island Progress
            </div>
            <div className="flex-1 h-2.5 rounded-full overflow-hidden" style={{ background: "#e0eaf4" }}>
              <motion.div className="h-full rounded-full"
                initial={{ width: 0 }} animate={{ width: "40%" }}
                transition={{ duration: 1, delay: 0.3 }}
                style={{ background: "linear-gradient(90deg, #03a566, #fde047)" }} />
            </div>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#03a566", fontSize: "13px", whiteSpace: "nowrap" }}>
              2 / 5 ✓
            </div>
          </div>
        </motion.div>

        {/* ── Section divider ── */}
        <div className="flex items-center gap-3 px-1">
          <div className="flex-1 h-px" style={{ background: "rgba(255,255,255,0.55)" }} />
          <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "13px", textShadow: "0 2px 6px rgba(8,119,242,0.35)" }}>
            ⚡ Activities
          </div>
          <div className="flex-1 h-px" style={{ background: "rgba(255,255,255,0.55)" }} />
        </div>

        {/* ── Activity cards ── */}
        {LESSON_ACTIVITIES.map((act, i) => {
          const isLocked   = act.status === "locked";
          const isDone     = act.status === "done";
          const isActive   = act.status === "active";
          const isPronunc  = act.id === 3;
          const isBossCard = (act as any).isBoss === true;
          const navTarget  = actNavTarget(act.id);

          return (
            <motion.div key={act.id}
              initial={{ x: i % 2 === 0 ? -32 : 32, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.06 + i * 0.09, duration: 0.45 }}
              whileTap={!isLocked ? { scale: 0.97 } : {}}
              onClick={() => {
                if (isLocked) return;
                const t = actNavTarget(act.id);
                if (t) onNav(t);
              }}
              className="rounded-3xl overflow-hidden"
              style={{
                cursor: !isLocked ? "pointer" : "default",
                boxShadow: isLocked
                  ? "0 4px 14px rgba(0,0,0,0.07)"
                  : isPronunc
                    ? "0 12px 38px rgba(255,92,159,0.40)"
                    : isBossCard
                      ? "0 10px 32px rgba(123,63,168,0.38)"
                      : `0 8px 24px ${act.color}2e`,
                opacity: isLocked ? 0.7 : 1,
                cursor: isPronunc && !isLocked ? "pointer" : "default",
              }}>

              {/* ── Scene banner ── */}
              <div className="relative flex items-center px-5 gap-4 overflow-hidden"
                style={{
                  height: isPronunc ? "124px" : "90px",
                  background: isLocked
                    ? "linear-gradient(135deg, #b8c8d8, #9ab0c8)"
                    : isPronunc
                      ? "linear-gradient(135deg, #ff5c9f 0%, #cc0f5a 55%, #8b0036 100%)"
                      : isBossCard
                        ? "linear-gradient(135deg, #7b3fa8 0%, #4a1a7a 55%, #2d0a50 100%)"
                        : `linear-gradient(135deg, ${act.gradFrom}, ${act.gradTo})`,
                }}>

                {/* pronunciation ambient glow */}
                {isPronunc && !isLocked && (
                  <div className="absolute inset-0 pointer-events-none"
                    style={{ background: "radial-gradient(ellipse at 35% 55%, rgba(255,255,255,0.18) 0%, transparent 65%)" }} />
                )}

                {/* boss ambient glow */}
                {isBossCard && !isLocked && (
                  <div className="absolute inset-0 pointer-events-none"
                    style={{ background: "radial-gradient(ellipse at 25% 60%, rgba(253,224,71,0.22) 0%, transparent 65%)" }} />
                )}

                {/* main icon */}
                <motion.div className="flex-shrink-0 relative z-10"
                  animate={!isLocked ? { y: [0, -5, 0] } : {}}
                  transition={{ duration: 2.2, repeat: Infinity, ease: "easeInOut" }}
                  style={{
                    fontSize: isPronunc ? "60px" : isBossCard ? "54px" : "46px",
                    filter: isLocked ? "grayscale(1) brightness(1.1)" : "none",
                  }}>
                  {isLocked ? "🔒" : act.icon}
                </motion.div>

                {/* pronunciation floating music notes */}
                {isPronunc && !isLocked && ["🎵","✨","🎶","💫"].map((s, si) => (
                  <motion.span key={si} className="absolute pointer-events-none select-none"
                    style={{
                      right:  `${si * 14 + 8}%`,
                      top:    si % 2 === 0 ? "10px" : "auto",
                      bottom: si % 2 !== 0 ? "32px" : "auto",
                      fontSize: "18px", opacity: 0.85,
                    }}
                    animate={{ y: [0, -5, 0], rotate: [0, si % 2 === 0 ? 12 : -12, 0] }}
                    transition={{ duration: 1.8 + si * 0.3, repeat: Infinity, delay: si * 0.2 }}>
                    {s}
                  </motion.span>
                ))}

                {/* regular floating scene decorations */}
                {!isLocked && !isPronunc && act.scene.slice(1).map((s, si) => (
                  <motion.span key={si}
                    className="absolute pointer-events-none select-none"
                    style={{
                      right: `${si * 13 + 5}%`,
                      top:   si % 2 === 0 ? "10px" : "auto",
                      bottom: si % 2 !== 0 ? "8px" : "auto",
                      fontSize: si === 0 ? "22px" : "17px",
                      opacity: 0.82,
                    }}
                    animate={{ y: [0, -4, 0], rotate: [0, si % 2 === 0 ? 10 : -10, 0] }}
                    transition={{ duration: 1.9 + si * 0.28, repeat: Infinity, delay: si * 0.18 }}>
                    {s}
                  </motion.span>
                ))}

                {/* star cluster */}
                <div className="absolute top-3 right-4 flex items-center gap-0.5">
                  {Array.from({ length: act.maxStars }).map((_, si) => (
                    <Star key={si} size={si < act.stars ? 15 : 12}
                      fill={si < act.stars ? "#fde047" : "rgba(255,255,255,0.32)"}
                      stroke="none" />
                  ))}
                </div>

                {/* ✓ completed badge */}
                {isDone && (
                  <motion.div
                    className="absolute top-2.5 left-2.5 w-6 h-6 rounded-full flex items-center justify-center"
                    initial={{ scale: 0 }} animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 260, delay: 0.2 + i * 0.1 }}
                    style={{ background: "#fde047", boxShadow: "0 2px 8px rgba(0,0,0,0.2)" }}>
                    <Check size={13} color="#102d54" strokeWidth={3} />
                  </motion.div>
                )}

                {/* CHALLENGE badge for pronunciation */}
                {isPronunc && !isLocked && (
                  <div className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-lg"
                    style={{ background: "rgba(255,255,255,0.22)", border: "1.5px solid rgba(255,255,255,0.52)" }}>
                    <span style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "9px", letterSpacing: "2px" }}>
                      CHALLENGE
                    </span>
                  </div>
                )}

                {/* boss label */}
                {isBossCard && !isLocked && (
                  <div className="absolute bottom-2.5 left-[76px]"
                    style={{
                      background: "rgba(253,224,71,0.22)",
                      border: "1.5px solid rgba(253,224,71,0.65)",
                      borderRadius: "8px", padding: "2px 8px",
                    }}>
                    <span style={{ fontFamily: "'Fredoka One', cursive", color: "#fde047", fontSize: "10px", letterSpacing: "2.5px" }}>
                      BOSS
                    </span>
                  </div>
                )}

                {/* reward bubble for non-boss non-pronunciation */}
                {!isBossCard && !isPronunc && !isLocked && (
                  <div className="absolute bottom-2.5 left-[72px] flex items-center gap-1 px-2 py-0.5 rounded-xl"
                    style={{ background: "rgba(0,0,0,0.18)" }}>
                    <Star size={10} fill="#fde047" stroke="#fde047" />
                    <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "white", fontSize: "10px" }}>
                      +{act.reward} stars
                    </span>
                  </div>
                )}

                {/* Title name overlay for non-pronunciation cards */}
                {!isPronunc && !isBossCard && !isLocked && (
                  <div className="absolute bottom-0 left-0 right-0 pointer-events-none"
                    style={{ background: "linear-gradient(0deg, rgba(0,0,0,0.30) 0%, transparent 100%)", padding: "22px 16px 8px" }}>
                    <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "15px", textShadow: "0 1px 5px rgba(0,0,0,0.38)" }}>
                      {act.title}
                    </div>
                  </div>
                )}

                {/* pronunciation phase flow indicator */}
                {isPronunc && !isLocked && (
                  <div className="absolute bottom-3 left-0 right-0 flex justify-center">
                    <div className="flex items-center gap-2 px-3 py-1.5 rounded-2xl"
                      style={{ background: "rgba(0,0,0,0.26)" }}>
                      {[
                        { icon: "🎙️", label: "Idle"   },
                        { icon: "🔴",  label: "Record" },
                        { icon: "🏆",  label: "Score"  },
                      ].map((s, si) => (
                        <div key={si} className="flex items-center gap-1">
                          <span style={{ fontSize: "13px" }}>{s.icon}</span>
                          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "rgba(255,255,255,0.92)", fontSize: "9px" }}>
                            {s.label}
                          </span>
                          {si < 2 && (
                            <span style={{ color: "rgba(255,255,255,0.45)", fontSize: "9px", margin: "0 1px" }}>→</span>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* ── Info row ── */}
              <div className="px-4 py-3 flex flex-col gap-0"
                style={{
                  background: isBossCard && !isLocked
                    ? "linear-gradient(135deg, #1c0a40, #0e1a48)"
                    : "white",
                }}>
                <div className="flex items-center gap-3">
                  <div className="flex-1 min-w-0">
                    <div style={{
                      fontFamily: "'Fredoka One', cursive",
                      fontSize: isPronunc ? "17px" : "16px", lineHeight: 1.2,
                      color: isLocked ? "#9ab0c8" : isBossCard ? "#fde047" : "#102d54",
                    }}>
                      {act.title}
                    </div>
                    <div className="mt-0.5" style={{
                      fontFamily: "'Nunito', sans-serif", fontWeight: 600, fontSize: "11px", lineHeight: 1.35,
                      color: isLocked ? "#b0c4d8" : isBossCard ? "rgba(255,255,255,0.58)" : "#9ab0c8",
                    }}>
                      {isLocked ? "🔒 Complete previous activities first" : act.desc}
                    </div>

                    {isActive && (
                      <div className="mt-1.5 flex items-center gap-2">
                        <div className="rounded-full overflow-hidden" style={{ background: "#e0eaf4", width: "110px", height: "5px" }}>
                          <motion.div className="h-full rounded-full"
                            initial={{ width: 0 }} animate={{ width: `${act.progress}%` }}
                            transition={{ duration: 0.85, delay: 0.25 + i * 0.1 }}
                            style={{ background: act.color }} />
                        </div>
                        <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: act.color, fontSize: "10px" }}>
                          {act.progress}%
                        </span>
                      </div>
                    )}

                    {isBossCard && !isLocked && (
                      <div className="mt-1 flex items-center gap-1">
                        <Star size={11} fill="#fde047" stroke="#fde047" />
                        <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#fde047", fontSize: "11px" }}>
                          +{act.reward} stars reward!
                        </span>
                      </div>
                    )}

                    {!isPronunc && !isBossCard && !isLocked && (
                      <div className="mt-1 flex items-center gap-1">
                        <Star size={10} fill="#fde047" stroke="#fde047" />
                        <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#b07800", fontSize: "10px" }}>
                          +{act.reward} stars
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Inline button for non-pronunciation unlocked cards */}
                  {!isPronunc && !isLocked && (
                    <motion.button whileTap={{ scale: 0.88 }}
                      onClick={() => navTarget && onNav(navTarget)}
                      className="flex-shrink-0 rounded-2xl"
                      style={{
                        padding: "10px 16px",
                        fontFamily: "'Fredoka One', cursive", fontSize: "14px",
                        background: isBossCard
                          ? "linear-gradient(135deg, #fde047, #ffb700)"
                          : `linear-gradient(135deg, ${act.gradFrom}, ${act.gradTo})`,
                        color: isBossCard ? "#102d54" : "white",
                        boxShadow: isBossCard
                          ? "0 4px 0 #c08000, 0 6px 16px rgba(253,224,71,0.42)"
                          : `0 4px 0 ${act.gradTo}, 0 6px 16px ${act.color}3a`,
                      }}>
                      {isDone ? "Again!" : isActive ? "Continue" : "Start →"}
                    </motion.button>
                  )}

                  {/* Lock icon for non-pronunciation locked */}
                  {!isPronunc && isLocked && (
                    <div className="w-10 h-10 rounded-2xl flex items-center justify-center flex-shrink-0"
                      style={{ background: "#e8f0f8" }}>
                      <Lock size={18} color="#9ab0c8" />
                    </div>
                  )}
                </div>

                {/* Pronunciation unlocked: full-width Start Challenge CTA */}
                {isPronunc && !isLocked && (
                  <motion.button whileTap={{ scale: 0.95 }}
                    onClick={() => onNav("pronunciation")}
                    className="mt-3 w-full py-3.5 rounded-2xl flex items-center justify-center gap-2"
                    style={{
                      background: "linear-gradient(135deg, #ff5c9f, #cc0f5a)",
                      boxShadow: "0 6px 0 #8b0036, 0 10px 26px rgba(255,92,159,0.44)",
                    }}>
                    <Mic size={20} color="white" />
                    <span style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "18px" }}>
                      Start Challenge
                    </span>
                    <ChevronRight size={20} color="white" />
                  </motion.button>
                )}

                {/* Pronunciation locked */}
                {isPronunc && isLocked && (
                  <div className="mt-2 flex items-center justify-center gap-2 py-2">
                    <Lock size={18} color="#9ab0c8" />
                    <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "12px" }}>
                      Complete previous activities to unlock
                    </span>
                  </div>
                )}
              </div>
            </motion.div>
          );
        })}

        {/* bottom spacer */}
        <div style={{ height: "6px" }} />
      </div>
    </div>
  );
}

// ─── SCREEN C — ADVENTURE MAP ─────────────────────────────────────────────────

function MapScreen({ onNav }: { onNav: (s: Screen) => void }) {
  return (
    <div className="w-full h-full flex flex-col overflow-hidden">
      <TopBar stars={120} streak={7} onProfile={() => onNav("profiles")} />
      <div className="flex-1 overflow-y-auto relative"
        style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 45%, #a8d8ff 75%, #c2eeff 100%)" }}>
        <Cloud x="4%" y="3%" scale={0.72} delay={0} />
        <Cloud x="53%" y="9%" scale={0.6} delay={1.1} />
        <Sparkle x="78%" y="16%" color="#fde047" />
        <Sparkle x="8%"  y="19%" color="#ff5c9f" />

        <div className="relative px-4 pt-3 pb-6">
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "20px", color: "white", textShadow: "0 2px 0 #0566c5" }}>
            🌍 Your Adventure Map
          </div>
          <div className="text-xs mt-0.5 mb-4" style={{ fontFamily: "'Nunito', sans-serif", color: "#102d54", opacity: 0.72 }}>
            Explore magical islands and learn English!
          </div>

          {/* daily quest banner */}
          <motion.button whileTap={{ scale: 0.97 }} onClick={() => onNav("quest")}
            className="w-full mb-5 rounded-3xl p-4 flex items-center gap-3"
            style={{ background: "linear-gradient(135deg, #fde047, #ffb700)", boxShadow: "0 6px 16px rgba(255,183,0,0.38)" }}>
            <span className="text-3xl">⚡</span>
            <div className="text-left">
              <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px" }}>Daily Quest</div>
              <div className="text-xs" style={{ fontFamily: "'Nunito', sans-serif", color: "#102d54", opacity: 0.68 }}>2 / 4 missions done!</div>
            </div>
            <div className="ml-auto w-10 h-10 rounded-2xl flex items-center justify-center text-xl"
              style={{ background: "rgba(255,255,255,0.38)" }}>🎁</div>
          </motion.button>

          {/* dashed path line */}
          <div className="absolute left-1/2 -translate-x-0.5 top-36" style={{ width: "2px", height: "calc(100% - 160px)", zIndex: 0 }}>
            <svg width="4" height="100%" preserveAspectRatio="none">
              <line x1="2" y1="0" x2="2" y2="10000" stroke="rgba(255,255,255,0.5)" strokeWidth="3" strokeDasharray="12 9" />
            </svg>
          </div>

          {/* islands */}
          <div className="relative z-10 flex flex-col gap-5">
            {ISLANDS.map((island, i) => (
              <motion.div key={island.id}
                initial={{ x: i % 2 === 0 ? -38 : 38, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.1 }}
                className={`flex ${i % 2 === 0 ? "justify-start pl-3" : "justify-end pr-3"}`}>
                <motion.button whileTap={island.unlocked ? { scale: 0.95 } : {}}
                  onClick={() => island.unlocked && onNav("lessonHub")}
                  className="relative rounded-3xl p-4 flex flex-col items-center gap-1.5"
                  style={{
                    width: "63%",
                    background: island.unlocked ? `linear-gradient(135deg, white, ${island.bgColor})` : "rgba(255,255,255,0.38)",
                    boxShadow: island.unlocked ? `0 8px 24px ${island.color}30` : "0 4px 12px rgba(0,0,0,0.08)",
                    border: `3px solid ${island.unlocked ? island.color : "rgba(255,255,255,0.46)"}`,
                    opacity: island.unlocked ? 1 : 0.72,
                  }}>
                  {!island.unlocked && (
                    <div className="absolute inset-0 rounded-3xl flex items-center justify-center"
                      style={{ background: "rgba(255,255,255,0.5)" }}>
                      <Lock size={28} color="#9ab0c8" />
                    </div>
                  )}
                  <span className="text-4xl">{island.emoji}</span>
                  <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "14px" }}>
                    {island.name}
                  </div>
                  {island.unlocked && (
                    <div className="flex gap-1">
                      {Array.from({ length: island.total }).map((_, si) => (
                        <Star key={si} size={13} fill={si < island.stars ? "#fde047" : "#dde8f0"} stroke="none" />
                      ))}
                    </div>
                  )}
                  {island.unlocked && (
                    <div className="mt-1 px-4 py-1 rounded-2xl text-xs font-black text-white"
                      style={{ background: island.color, fontFamily: "'Nunito', sans-serif" }}>
                      {i === 0 ? "Continue!" : i === 1 ? "In Progress" : "Start!"}
                    </div>
                  )}
                </motion.button>
              </motion.div>
            ))}

            {/* dragon egg */}
            <div className="flex justify-center mt-4 mb-2">
              <motion.div className="text-center"
                animate={{ y: [0, -7, 0] }} transition={{ duration: 2.2, repeat: Infinity }}>
                <div className="text-5xl mb-1">🥚</div>
                <div className="text-xs font-bold"
                  style={{ fontFamily: "'Nunito', sans-serif", color: "#102d54", opacity: 0.62 }}>
                  Mystery Egg…
                </div>
              </motion.div>
            </div>
          </div>
        </div>
      </div>
      <BottomNav current="map" onNav={onNav} />
    </div>
  );
}

// ─── SCREEN D — VOCABULARY ────────────────────────────────────────────────────

function VocabScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [idx, setIdx] = useState(0);
  const [showReward, setShowReward] = useState(false);
  const word = VOCAB[idx];

  const next = () => {
    if (idx < VOCAB.length - 1) setIdx(i => i + 1);
    else setShowReward(true);
  };
  const prev = () => idx > 0 && setIdx(i => i - 1);

  return (
    <div className="relative w-full h-full flex flex-col" style={{ background: "#eef7ff" }}>
      {/* header */}
      <div className="flex-none flex items-center gap-3 px-4 py-3"
        style={{ background: "white", borderBottom: "1.5px solid rgba(16,45,84,0.07)" }}>
        <button onClick={() => onNav("map")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center"
          style={{ background: "#eef7ff" }}>
          <ChevronLeft size={20} color="#102d54" />
        </button>
        <div className="flex-1">
          <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
            🦁 Animals Island
          </div>
          <div className="text-xs" style={{ fontFamily: "'Nunito', sans-serif", color: "#9ab0c8" }}>
            Word {idx + 1} of {VOCAB.length}
          </div>
        </div>
        <div className="flex gap-1.5">
          {VOCAB.map((_, i) => (
            <div key={i} className="h-2 rounded-full transition-all"
              style={{ width: i === idx ? "24px" : "8px", background: i <= idx ? "#ff5c9f" : "#dde8f0" }} />
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto flex flex-col items-center px-5 py-4 gap-4">
        {/* word card */}
        <motion.div key={idx} className="w-full rounded-3xl p-6 flex flex-col items-center gap-3"
          initial={{ x: 60, opacity: 0 }} animate={{ x: 0, opacity: 1 }}
          style={{ background: "white", boxShadow: `0 12px 32px ${word.color}20` }}>
          <div className="w-36 h-36 rounded-3xl flex items-center justify-center text-8xl"
            style={{ background: `${word.color}14` }}>
            {word.emoji}
          </div>
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "52px", color: word.color, letterSpacing: "3px" }}>
            {word.word}
          </div>
          <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "17px" }}>
            {word.meaning}
          </div>
          <motion.button whileTap={{ scale: 0.9 }}
            className="flex items-center gap-2 px-5 py-2 rounded-2xl"
            style={{ background: `${word.color}18`, color: word.color }}>
            <Volume2 size={18} />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "14px" }}>Hear it! 🔊</span>
          </motion.button>
        </motion.div>

        {/* pronunciation shortcut */}
        <motion.button whileTap={{ scale: 0.97 }} onClick={() => onNav("pronunciation")}
          className="w-full py-3 rounded-3xl flex items-center justify-center gap-2"
          style={{
            background: "linear-gradient(135deg, #0877f2, #0566c5)", color: "white",
            fontFamily: "'Fredoka One', cursive", fontSize: "17px",
            boxShadow: "0 6px 0 #0440a0, 0 8px 20px rgba(8,119,242,0.32)",
          }}>
          <Mic size={20} /> Practice Saying It! 🎤
        </motion.button>

        {/* nav buttons */}
        <div className="flex gap-3 w-full">
          <motion.button whileTap={{ scale: 0.95 }} onClick={prev} disabled={idx === 0}
            className="flex-1 py-3 rounded-2xl flex items-center justify-center gap-1 font-bold"
            style={{ background: "#dde8f0", color: "#9ab0c8", fontFamily: "'Nunito', sans-serif", opacity: idx === 0 ? 0.38 : 1 }}>
            <ChevronLeft size={18} /> Back
          </motion.button>
          <motion.button whileTap={{ scale: 0.95 }} onClick={next}
            className="flex-1 py-3 px-4 rounded-2xl flex items-center justify-center gap-1 text-white"
            style={{
              background: "linear-gradient(135deg, #03a566, #02834f)",
              fontFamily: "'Fredoka One', cursive", fontSize: "17px",
              boxShadow: "0 4px 0 #016e42, 0 6px 16px rgba(3,165,102,0.32)",
            }}>
            {idx < VOCAB.length - 1 ? "Next" : "Finish! 🎉"} <ChevronRight size={18} />
          </motion.button>
        </div>

        {/* kiki guide */}
        <motion.div className="flex items-end gap-3 mt-1"
          animate={{ y: [0, -7, 0] }} transition={{ duration: 2.6, repeat: Infinity }}>
          <KikiPanda size={82} mood="happy" />
          <div className="mb-4 bg-white rounded-2xl rounded-bl-sm px-3 py-2 shadow-md">
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#0877f2", fontSize: "12px" }}>
              Great job! 🌟 Keep going!
            </span>
          </div>
        </motion.div>
      </div>

      {/* reward overlay */}
      {showReward && (
        <motion.div className="absolute inset-0 z-50 flex flex-col items-center justify-center"
          initial={{ opacity: 0 }} animate={{ opacity: 1 }}
          style={{ background: "rgba(0,0,0,0.72)" }}>
          <motion.div className="bg-white rounded-3xl p-8 mx-6 flex flex-col items-center gap-4"
            initial={{ scale: 0.4 }} animate={{ scale: 1 }} transition={{ type: "spring", stiffness: 220 }}>
            <div className="text-6xl">🎉</div>
            <KikiPanda size={100} mood="celebrating" />
            <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "28px", color: "#ff5c9f" }}>Lesson Complete!</div>
            <div className="flex items-center gap-2">
              <Star size={22} fill="#fde047" stroke="#fde047" />
              <span style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "18px" }}>+15 Stars Earned!</span>
              <Star size={22} fill="#fde047" stroke="#fde047" />
            </div>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => { setShowReward(false); onNav("map"); }}
              className="w-full py-3 rounded-3xl text-white"
              style={{
                fontFamily: "'Fredoka One', cursive", fontSize: "18px",
                background: "linear-gradient(135deg, #ff5c9f, #ff1f6e)",
                boxShadow: "0 5px 0 #b8154e",
              }}>
              Back to Map 🗺️
            </motion.button>
          </motion.div>
        </motion.div>
      )}
    </div>
  );
}

// ─── PRONUNCIATION HELPERS ────────────────────────────────────────────────────

const FW_DOTS = Array.from({ length: 38 }, (_, i) => ({
  angle: (i / 38) * 360 + (i % 4) * 4,
  dist:  68 + (i % 6) * 19,
  color: ["#ff5c9f","#fde047","#0877f2","#03a566","#ff8c00","#9b59b6","#ffffff","#ffb3c6"][i % 8],
  size:  5 + (i % 4) * 2.2,
  delay: (i % 9) * 0.045,
}));

function FireworksBurst() {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden" style={{ zIndex: 45 }}>
      {FW_DOTS.map((p, i) => {
        const rad = (p.angle * Math.PI) / 180;
        return (
          <motion.div key={i} className="absolute rounded-full"
            style={{
              width: p.size, height: p.size, background: p.color,
              left: "50%", top: "36%",
              marginLeft: -p.size / 2, marginTop: -p.size / 2,
            }}
            initial={{ x: 0, y: 0, opacity: 1, scale: 1 }}
            animate={{ x: Math.cos(rad) * p.dist, y: Math.sin(rad) * p.dist, opacity: 0, scale: 0.1 }}
            transition={{ duration: 0.88, delay: p.delay, ease: "easeOut" }} />
        );
      })}
      {FW_DOTS.slice(0, 20).map((p, i) => {
        const rad = ((p.angle + 24) * Math.PI) / 180;
        return (
          <motion.div key={`s${i}`} className="absolute rounded-full"
            style={{
              width: p.size * 0.6, height: p.size * 0.6, background: p.color,
              left: "50%", top: "36%",
              marginLeft: -p.size * 0.3, marginTop: -p.size * 0.3,
            }}
            initial={{ x: 0, y: 0, opacity: 1 }}
            animate={{ x: Math.cos(rad) * p.dist * 0.68, y: Math.sin(rad) * p.dist * 0.68, opacity: 0 }}
            transition={{ duration: 0.78, delay: 0.16 + p.delay, ease: "easeOut" }} />
        );
      })}
      {["🎉","⭐","🌟","🎊","✨","💫","🎆","⭐","🎉","🌟"].map((e, i) => (
        <motion.span key={`e${i}`} className="absolute select-none"
          style={{ fontSize: i % 3 === 0 ? "26px" : "18px", left: `${5 + i * 9}%` }}
          initial={{ y: "-12%", opacity: 0, rotate: 0 }}
          animate={{ y: "112%", opacity: [0, 1, 1, 0.5, 0], rotate: (i % 2 === 0 ? 1 : -1) * 540 }}
          transition={{ duration: 2 + i * 0.13, delay: 0.06 + i * 0.09, ease: "easeIn" }} />
      ))}
    </div>
  );
}

function ScoreRing({ value, color, size = 60, delay = 0 }: {
  value: number; color: string; size?: number; delay?: number;
}) {
  const r    = (size - 12) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} style={{ transform: "rotate(-90deg)", display: "block", flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#e8f0f8" strokeWidth="6" />
      <motion.circle
        cx={size / 2} cy={size / 2} r={r}
        fill="none" stroke={color} strokeWidth="6" strokeLinecap="round"
        strokeDasharray={circ}
        initial={{ strokeDashoffset: circ }}
        animate={{ strokeDashoffset: circ * (1 - value / 100) }}
        transition={{ duration: 1.2, delay, ease: "easeOut" }} />
    </svg>
  );
}

// ─── SCREEN E — PRONUNCIATION ─────────────────────────────────────────────────

function PronunciationScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [phase, setPhase]   = useState<"idle" | "recording" | "done">("idle");
  const [showFW, setShowFW] = useState(false);
  const timerRef            = useRef<ReturnType<typeof setTimeout> | null>(null);

  const SCORES    = { accuracy: 94, fluency: 88, completeness: 96, overall: 93 };
  const excellent = SCORES.overall >= 90;

  // Direct phase select (used by state-selector tabs)
  const selectPhase = (p: "idle" | "recording" | "done") => {
    if (timerRef.current) clearTimeout(timerRef.current);
    setShowFW(false);
    setPhase(p);
    if (p === "done" && excellent) {
      setShowFW(true);
      timerRef.current = setTimeout(() => setShowFW(false), 2500);
    }
  };

  // Natural mic interaction (starts the 2.8 s simulation)
  const handleMic = () => {
    if (phase !== "idle") return;
    setPhase("recording");
    timerRef.current = setTimeout(() => {
      setPhase("done");
      if (excellent) {
        setShowFW(true);
        timerRef.current = setTimeout(() => setShowFW(false), 2500);
      }
    }, 2800);
  };

  const kikiMood =
    phase === "recording"           ? "listening"   :
    phase === "done" && excellent   ? "celebrating" : "happy";

  const kikiLine =
    phase === "idle"      ? "Tap the big mic and say: 'DOG' 🐶" :
    phase === "recording" ? "I'm listening very carefully... 🎧" :
    excellent             ? "WOW! You sound perfect! You're a star! 🌟" :
                            "Great effort! Keep practicing! 💪";

  return (
    <div className="relative w-full h-full flex flex-col overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>

      {showFW && <FireworksBurst />}

      {/* Bg decorations */}
      <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <Cloud x="-12px" y="4%"  scale={0.75} delay={0}   />
        <Cloud x="60%"   y="9%"  scale={0.55} delay={1.1} />
        <Sparkle x="7%"  y="20%" color="#fde047" />
        <Sparkle x="84%" y="16%" color="#ff5c9f" />
        <Sparkle x="82%" y="75%" color="#a78bfa" />
      </div>

      {/* ── Header + breadcrumb + state selector ── */}
      <div className="flex-none z-10"
        style={{ background: "rgba(255,255,255,0.22)", backdropFilter: "blur(12px)", borderBottom: "1.5px solid rgba(255,255,255,0.3)" }}>

        {/* Top row: back + breadcrumb + attempt pips */}
        <div className="flex items-center gap-3 px-4 pt-3 pb-1">
          <button onClick={() => onNav("lessonHub")}
            className="w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0"
            style={{ background: "rgba(255,255,255,0.82)", boxShadow: "0 3px 10px rgba(0,0,0,0.1)" }}>
            <ChevronLeft size={20} color="#102d54" />
          </button>
          <div className="flex-1 min-w-0">
            {/* Breadcrumb */}
            <div className="flex items-center gap-1 flex-wrap">
              <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "10px", color: "#102d54", opacity: 0.52 }}>
                Lesson Hub
              </span>
              <ChevronRight size={10} color="rgba(16,45,84,0.38)" />
              <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "10px", color: "#ff5c9f" }}>
                Pronunciation Challenge
              </span>
            </div>
            <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: "#102d54", lineHeight: 1.1 }}>
              🎤 Pronunciation Practice
            </div>
          </div>
          <div className="flex gap-1.5 flex-shrink-0">
            {[0, 1, 2].map(ix => (
              <div key={ix} className="w-2.5 h-2.5 rounded-full"
                style={{ background: ix === 0 ? "#ff5c9f" : "rgba(255,255,255,0.45)" }} />
            ))}
          </div>
        </div>

        {/* State-selector tabs */}
        <div className="flex gap-2 px-4 pb-2.5 pt-1">
          {([
            { key: "idle",      label: "🎙️ Idle",     active: "#0877f2",  tc: "white"   },
            { key: "recording", label: "🔴 Recording", active: "#ff5c9f",  tc: "white"   },
            { key: "done",      label: "🏆 Result",    active: "#fde047",  tc: "#102d54" },
          ] as const).map(tab => {
            const on = phase === tab.key;
            return (
              <motion.button key={tab.key} whileTap={{ scale: 0.92 }}
                onClick={() => selectPhase(tab.key)}
                className="flex-1 py-1.5 rounded-2xl text-xs font-black"
                style={{
                  fontFamily: "'Nunito', sans-serif",
                  background: on ? tab.active : "rgba(255,255,255,0.30)",
                  color:      on ? tab.tc    : "rgba(255,255,255,0.72)",
                  boxShadow:  on ? `0 3px 10px ${tab.active}44` : "none",
                  transition: "all 0.18s",
                }}>
                {tab.label}
              </motion.button>
            );
          })}
        </div>
      </div>

      {/* ── Scrollable body ── */}
      <div className="flex-1 overflow-y-auto z-10" style={{ scrollbarWidth: "none" }}>
        <div className="flex flex-col items-center px-4 py-4 gap-4">

          {/* ── VOCABULARY CARD ── */}
          <motion.div className="w-full rounded-3xl overflow-hidden"
            style={{ boxShadow: "0 14px 38px rgba(255,140,0,0.30)" }}
            initial={{ y: -18, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.48 }}>

            {/* Illustrated scene */}
            <div className="relative flex items-center justify-center overflow-hidden"
              style={{ background: "linear-gradient(135deg, #ff9e20 0%, #e86000 100%)", height: "148px" }}>
              {[
                { x: "6%",  y: "12px", b: undefined, op: 0.18 },
                { x: "30%", y: undefined, b: "10px", op: 0.14 },
                { x: "68%", y: "14px", b: undefined, op: 0.16 },
                { x: "88%", y: undefined, b: "8px",  op: 0.12 },
              ].map((d, i) => (
                <span key={i} className="absolute select-none"
                  style={{ fontSize: "26px", left: d.x, top: d.y, bottom: d.b, opacity: d.op }}>🐾</span>
              ))}
              {["✨","🌟","✨"].map((s, i) => (
                <motion.span key={i} className="absolute select-none"
                  style={{ fontSize: "17px", right: `${i * 15 + 6}%`, top: `${i * 20 + 8}%`, opacity: 0.9 }}
                  animate={{ rotate: [0, 22, 0], scale: [1, 1.3, 1] }}
                  transition={{ duration: 2.2 + i * 0.4, repeat: Infinity, delay: i * 0.35 }}>
                  {s}
                </motion.span>
              ))}
              <motion.div
                animate={{ y: [0, -7, 0] }}
                transition={{ duration: 2.6, repeat: Infinity, ease: "easeInOut" }}
                style={{ fontSize: "86px", filter: "drop-shadow(0 8px 22px rgba(0,0,0,0.22))" }}>
                🐶
              </motion.div>
              <motion.button whileTap={{ scale: 0.86 }}
                className="absolute top-3 right-3 w-10 h-10 rounded-2xl flex items-center justify-center"
                style={{ background: "rgba(255,255,255,0.22)", backdropFilter: "blur(6px)", border: "1.5px solid rgba(255,255,255,0.38)" }}>
                <Volume2 size={20} color="white" />
              </motion.button>
            </div>

            {/* Word row */}
            <div className="px-5 py-3.5 flex items-center justify-between" style={{ background: "white" }}>
              <div>
                <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "42px", color: "#ff8c00", letterSpacing: "3px", lineHeight: 1 }}>
                  DOG
                </div>
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "13px" }}>
                  /dɒɡ/ · Animal 🦴
                </div>
              </div>
              <motion.button whileTap={{ scale: 0.9 }}
                className="flex items-center gap-2 px-4 py-2.5 rounded-2xl"
                style={{ background: "linear-gradient(135deg, #ff8c00, #e06000)", boxShadow: "0 5px 0 #b04500, 0 7px 16px rgba(255,140,0,0.4)" }}>
                <Volume2 size={18} color="white" />
                <span style={{ fontFamily: "'Fredoka One', cursive", fontSize: "15px", color: "white" }}>Listen!</span>
              </motion.button>
            </div>
          </motion.div>

          {/* ─── PRE / RECORDING ─── */}
          {phase !== "done" && (
            <motion.div className="w-full flex flex-col items-center gap-3"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }}>

              <div className="text-center px-4">
                <motion.div key={phase}
                  initial={{ y: -10, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
                  style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "19px", textShadow: "0 2px 8px rgba(5,102,197,0.4)" }}>
                  {phase === "idle" ? "🎤 Tap the mic & say the word!" : "🎧 Listening carefully…"}
                </motion.div>
              </div>

              {/* Giant mic with rings */}
              <div className="relative flex items-center justify-center" style={{ width: "210px", height: "210px" }}>
                {phase === "recording" && [1, 2, 3].map(ring => (
                  <motion.div key={ring} className="absolute rounded-full pointer-events-none"
                    style={{
                      width: 124 + ring * 30, height: 124 + ring * 30,
                      border: `3px solid rgba(255,92,159,${0.52 - ring * 0.14})`,
                    }}
                    animate={{ scale: [1, 1.15, 1], opacity: [1, 0.22, 1] }}
                    transition={{ duration: 1.1, repeat: Infinity, delay: ring * 0.24, ease: "easeInOut" }} />
                ))}
                {phase === "idle" && (
                  <motion.div className="absolute rounded-full pointer-events-none"
                    style={{ width: "168px", height: "168px", background: "rgba(8,119,242,0.13)" }}
                    animate={{ scale: [1, 1.12, 1], opacity: [0.8, 0.32, 0.8] }}
                    transition={{ duration: 2.4, repeat: Infinity, ease: "easeInOut" }} />
                )}
                <motion.button onClick={handleMic} whileTap={{ scale: 0.88 }}
                  className="relative z-10 rounded-full flex items-center justify-center"
                  style={{
                    width: "124px", height: "124px",
                    background: phase === "recording"
                      ? "linear-gradient(135deg, #ff5c9f, #ff1f6e)"
                      : "linear-gradient(135deg, #0877f2, #0452b8)",
                    boxShadow: phase === "recording"
                      ? "0 0 0 7px rgba(255,92,159,0.22), 0 9px 0 #b8154e, 0 14px 36px rgba(255,31,110,0.46)"
                      : "0 9px 0 #0440a0, 0 14px 34px rgba(8,119,242,0.44)",
                  }}
                  animate={phase === "recording" ? { scale: [1, 1.06, 1] } : {}}
                  transition={{ duration: 0.55, repeat: Infinity }}>
                  <Mic size={54} color="white" />
                </motion.button>
              </div>

              {/* Waveform bars */}
              {phase === "recording" && (
                <motion.div className="flex items-center gap-1.5"
                  initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }}>
                  {[0.45,0.72,1,0.82,0.55,0.9,0.48,0.78,0.42,0.88,0.62,0.75].map((h, i) => (
                    <motion.div key={i} className="rounded-full"
                      style={{ width: "5px", background: "linear-gradient(180deg,#ff5c9f,#ff1f6e)" }}
                      animate={{ height: [`${h*14+4}px`, `${(1.1-h)*26+6}px`, `${h*14+4}px`] }}
                      transition={{ duration: 0.38 + i * 0.05, repeat: Infinity, delay: i * 0.04, ease: "easeInOut" }} />
                  ))}
                </motion.div>
              )}

              {/* Kiki */}
              <div className="flex items-end gap-3 w-full px-1">
                <motion.div className="flex-shrink-0"
                  animate={{ y: [0, -8, 0] }} transition={{ duration: 2.4, repeat: Infinity }}>
                  <KikiPanda size={96} mood={kikiMood} />
                </motion.div>
                <motion.div className="mb-8 flex-1 rounded-3xl rounded-tl-sm px-3.5 py-2.5"
                  style={{ background: "rgba(255,255,255,0.92)", boxShadow: "0 6px 18px rgba(8,119,242,0.14)" }}>
                  <div style={{
                    fontFamily: "'Nunito', sans-serif", fontWeight: 900, fontSize: "12px",
                    color: phase === "recording" ? "#ff5c9f" : "#0877f2",
                  }}>
                    {phase === "recording" ? "🎧 Listening..." : "Ready? You can do it! 🐾"}
                  </div>
                  <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "12px", lineHeight: 1.42 }}>
                    {kikiLine}
                  </div>
                </motion.div>
              </div>
            </motion.div>
          )}

          {/* ─── RESULTS ─── */}
          {phase === "done" && (
            <motion.div className="w-full flex flex-col gap-3"
              initial={{ y: 44, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.52, type: "spring", stiffness: 175 }}>

              {/* Overall hero card */}
              <div className="w-full rounded-3xl p-5 flex items-center gap-4"
                style={{
                  background: excellent
                    ? "linear-gradient(135deg, #fde047, #ffb700)"
                    : "linear-gradient(135deg, #e0f0ff, #c8e4ff)",
                  boxShadow: excellent
                    ? "0 12px 36px rgba(253,224,71,0.48)"
                    : "0 10px 28px rgba(8,119,242,0.22)",
                }}>
                <div className="relative flex-shrink-0" style={{ width: "96px", height: "96px" }}>
                  <ScoreRing value={SCORES.overall} color={excellent ? "#e06000" : "#0877f2"} size={96} delay={0.15} />
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <motion.div
                      initial={{ scale: 0 }} animate={{ scale: 1 }}
                      transition={{ type: "spring", stiffness: 260, delay: 0.5 }}
                      style={{ fontFamily: "'Fredoka One', cursive", fontSize: "28px", color: excellent ? "#c04500" : "#0877f2", lineHeight: 1 }}>
                      {SCORES.overall}
                    </motion.div>
                    <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: excellent ? "#c04500" : "#0566c5", fontSize: "9px" }}>
                      / 100
                    </div>
                  </div>
                </div>
                <div className="flex-1">
                  <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "23px", color: "#102d54", lineHeight: 1 }}>
                    {excellent ? "🌟 Amazing!" : SCORES.overall >= 70 ? "👍 Good Job!" : "💪 Keep Going!"}
                  </div>
                  <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "12px", color: excellent ? "#8b4500" : "#5a8ab0", lineHeight: 1.42, marginTop: "4px" }}>
                    {excellent ? "You nailed it! Keep up the great work! 🎉" : "Keep practicing to reach a perfect score!"}
                  </div>
                  <div className="mt-2 flex gap-0.5">
                    {[0, 1, 2, 3, 4].map(i => (
                      <Star key={i} size={17}
                        fill={i < Math.round(SCORES.overall / 20) ? (excellent ? "#c04500" : "#fde047") : "rgba(0,0,0,0.15)"}
                        stroke="none" />
                    ))}
                  </div>
                </div>
              </div>

              {/* 3 sub-score cards */}
              <div className="grid grid-cols-3 gap-2.5">
                {[
                  { label: "Accuracy",     value: SCORES.accuracy,     color: "#03a566", icon: "🎯", d: 0.28 },
                  { label: "Fluency",      value: SCORES.fluency,      color: "#0877f2", icon: "🎵", d: 0.38 },
                  { label: "Completeness", value: SCORES.completeness, color: "#9b59b6", icon: "✅", d: 0.48 },
                ].map(s => (
                  <motion.div key={s.label}
                    initial={{ y: 22, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: s.d }}
                    className="rounded-3xl p-3 flex flex-col items-center gap-1.5"
                    style={{ background: "white", boxShadow: `0 6px 20px ${s.color}20` }}>
                    <span style={{ fontSize: "18px" }}>{s.icon}</span>
                    <div className="relative" style={{ width: "56px", height: "56px" }}>
                      <ScoreRing value={s.value} color={s.color} size={56} delay={s.d + 0.1} />
                      <div className="absolute inset-0 flex items-center justify-center">
                        <span style={{ fontFamily: "'Fredoka One', cursive", fontSize: "15px", color: s.color }}>
                          {s.value}
                        </span>
                      </div>
                    </div>
                    <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#9ab0c8", fontSize: "10px", textAlign: "center" }}>
                      {s.label}
                    </div>
                    <div className="w-full h-1.5 rounded-full overflow-hidden" style={{ background: "#e8f0f8" }}>
                      <motion.div className="h-full rounded-full"
                        initial={{ width: 0 }} animate={{ width: `${s.value}%` }}
                        transition={{ duration: 0.85, delay: s.d + 0.15 }}
                        style={{ background: s.color }} />
                    </div>
                  </motion.div>
                ))}
              </div>

              {/* Kiki celebrating */}
              <motion.div className="flex items-end gap-3 px-1"
                initial={{ y: 18, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.55 }}>
                <motion.div className="flex-shrink-0"
                  animate={{ y: [0, -10, 0] }} transition={{ duration: 2, repeat: Infinity }}>
                  <KikiPanda size={96} mood={kikiMood} />
                </motion.div>
                <motion.div className="mb-8 flex-1 rounded-3xl rounded-tl-sm px-3.5 py-3"
                  style={{ background: "white", boxShadow: "0 6px 18px rgba(8,119,242,0.12)" }}
                  initial={{ scale: 0 }} animate={{ scale: 1 }}
                  transition={{ delay: 0.7, type: "spring", stiffness: 200 }}>
                  <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, fontSize: "13px", color: excellent ? "#ff5c9f" : "#03a566" }}>
                    {excellent ? "Incredible work! 🌟" : "You did great! 👏"}
                  </div>
                  <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "12px", lineHeight: 1.45, marginTop: "2px" }}>
                    {kikiLine}
                  </div>
                </motion.div>
              </motion.div>

              {/* Buttons */}
              <motion.div className="flex gap-3"
                initial={{ y: 16, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.62 }}>
                <motion.button whileTap={{ scale: 0.93 }}
                  onClick={() => selectPhase("idle")}
                  className="flex-1 py-3.5 rounded-2xl flex items-center justify-center gap-2"
                  style={{ background: "white", fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: "#102d54", boxShadow: "0 5px 14px rgba(0,0,0,0.1)", border: "2px solid #e0eaf4" }}>
                  <Mic size={18} color="#ff5c9f" /> Try Again
                </motion.button>
                <motion.button whileTap={{ scale: 0.93 }}
                  onClick={() => onNav("lessonHub")}
                  className="flex-1 py-3.5 rounded-2xl flex items-center justify-center gap-2"
                  style={{ background: "linear-gradient(135deg, #ff5c9f, #ff1f6e)", color: "white", fontFamily: "'Fredoka One', cursive", fontSize: "16px", boxShadow: "0 6px 0 #b8154e, 0 10px 24px rgba(255,31,110,0.34)" }}>
                  Keep Going! <ChevronRight size={18} />
                </motion.button>
              </motion.div>

              <div style={{ height: "8px" }} />
            </motion.div>
          )}

        </div>
      </div>
    </div>
  );
}

// ─── LISTENING DATA ───────────────────────────────────────────────────────────

const LISTEN_ROUNDS = [
  { word: "CAT",      phonetic: "/kæt/",        emoji: "🐱", options: ["🐶","🐱","🐟","🐰"], correct: 1 },
  { word: "DOG",      phonetic: "/dɒɡ/",        emoji: "🐶", options: ["🐱","🦁","🐶","🐰"], correct: 2 },
  { word: "BIRD",     phonetic: "/bɜːrd/",       emoji: "🐦", options: ["🐸","🐦","🐟","🦋"], correct: 1 },
  { word: "ELEPHANT", phonetic: "/ˈelɪfənt/",   emoji: "🐘", options: ["🦒","🐯","🦁","🐘"], correct: 3 },
  { word: "LION",     phonetic: "/ˈlaɪən/",     emoji: "🦁", options: ["🦁","🐯","🐻","🦊"], correct: 0 },
];

// ─── SCREEN LISTENING GAME ────────────────────────────────────────────────────

function ListeningScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [rIdx, setRIdx]         = useState(0);
  const [played, setPlayed]     = useState(false);
  const [selected, setSelected] = useState<number | null>(null);
  const [score, setScore]       = useState(0);
  const [done, setDone]         = useState(false);
  const [showFW, setShowFW]     = useState(false);
  const timerRef                = useRef<ReturnType<typeof setTimeout> | null>(null);

  const round   = LISTEN_ROUNDS[rIdx];
  const total   = LISTEN_ROUNDS.length;
  const correct = selected !== null && selected === round.correct;

  const playWord = () => {
    setPlayed(true);
  };

  const pick = (i: number) => {
    if (!played || selected !== null) return;
    setSelected(i);
    const ok = i === round.correct;
    if (ok) {
      setScore(s => s + 1);
      setShowFW(true);
      timerRef.current = setTimeout(() => setShowFW(false), 1600);
    }
    timerRef.current = setTimeout(() => {
      if (rIdx < total - 1) { setRIdx(r => r + 1); setSelected(null); setPlayed(false); }
      else setDone(true);
    }, ok ? 1700 : 2100);
  };

  const restart = () => { setRIdx(0); setSelected(null); setPlayed(false); setScore(0); setDone(false); setShowFW(false); };

  /* ── Results ── */
  if (done) {
    const perfect = score === total;
    return (
      <div className="relative w-full h-full flex flex-col overflow-hidden"
        style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>
        {perfect && <FireworksBurst />}
        <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
          <Cloud x="-10px" y="4%" scale={0.7} delay={0} />
          <Cloud x="58%" y="8%" scale={0.55} delay={1.1} />
          <Sparkle x="8%"  y="20%" color="#fde047" />
          <Sparkle x="84%" y="15%" color="#0877f2" />
        </div>
        <div className="flex-1 flex flex-col items-center justify-center px-6 gap-4 z-10">
          <motion.div className="text-7xl"
            animate={{ rotate: [0, 15, -15, 0], scale: [1, 1.2, 1] }}
            transition={{ duration: 0.55, repeat: 3 }}>
            {perfect ? "🏆" : score >= 3 ? "🎧" : "💪"}
          </motion.div>
          <KikiPanda size={110} mood={perfect ? "celebrating" : "happy"} />
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "28px", color: "white", textAlign: "center", textShadow: "0 4px 0 #0566c5" }}>
            {perfect ? "Perfect Listener! 🌟" : score >= 3 ? "Great Ears! 👂" : "Keep Listening! 💪"}
          </div>
          <div className="rounded-3xl px-6 py-5 flex flex-col items-center gap-3"
            style={{ background: "rgba(255,255,255,0.92)", boxShadow: "0 12px 32px rgba(0,0,0,0.1)", width: "100%" }}>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "24px" }}>
              {score} / {total} Correct!
            </div>
            <div className="flex gap-2">
              {Array.from({ length: total }).map((_, i) => (
                <Star key={i} size={26} fill={i < score ? "#fde047" : "#e0eaf4"} stroke="none" />
              ))}
            </div>
          </div>
          <div className="flex gap-3 w-full">
            <motion.button whileTap={{ scale: 0.94 }} onClick={restart}
              className="flex-1 py-3.5 rounded-2xl"
              style={{ background: "rgba(255,255,255,0.8)", fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: "#102d54", boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}>
              Try Again 🔄
            </motion.button>
            <motion.button whileTap={{ scale: 0.94 }} onClick={() => onNav("lessonHub")}
              className="flex-1 py-3.5 rounded-2xl text-white"
              style={{ background: "linear-gradient(135deg, #0877f2, #0452b8)", fontFamily: "'Fredoka One', cursive", fontSize: "16px", boxShadow: "0 5px 0 #0340a0" }}>
              Keep Going! 🚀
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative w-full h-full flex flex-col overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>
      {showFW && <FireworksBurst />}
      <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <Cloud x="-10px" y="4%" scale={0.7} delay={0} />
        <Cloud x="60%"   y="8%" scale={0.55} delay={1.1} />
        <Sparkle x="8%"  y="16%" color="#fde047" />
        <Sparkle x="84%" y="13%" color="#0877f2" />
      </div>

      {/* Header */}
      <div className="flex-none flex items-center gap-3 px-4 py-3 z-10"
        style={{ background: "rgba(255,255,255,0.22)", backdropFilter: "blur(12px)", borderBottom: "1.5px solid rgba(255,255,255,0.3)" }}>
        <button onClick={() => onNav("lessonHub")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0"
          style={{ background: "rgba(255,255,255,0.82)", boxShadow: "0 3px 10px rgba(0,0,0,0.1)" }}>
          <ChevronLeft size={20} color="#102d54" />
        </button>
        <div className="flex-1">
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "17px", color: "#102d54" }}>🎧 Listening Game</div>
          <div className="flex items-center gap-1">
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "10px", color: "#102d54", opacity: 0.5 }}>Lesson Hub</span>
            <ChevronRight size={10} color="rgba(16,45,84,0.36)" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "10px", color: "#0877f2" }}>Listening Game</span>
          </div>
        </div>
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl flex-shrink-0"
          style={{ background: "rgba(253,224,71,0.28)", border: "1.5px solid #fde047" }}>
          <Star size={13} fill="#fde047" stroke="#fde047" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b07800", fontSize: "13px" }}>{score * 5}</span>
        </div>
      </div>

      {/* Progress strip */}
      <div className="flex-none px-4 py-2 z-10" style={{ background: "rgba(255,255,255,0.15)" }}>
        <div className="flex items-center justify-between mb-1.5">
          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "white", fontSize: "12px" }}>
            Round {rIdx + 1} of {total}
          </span>
          <div className="flex gap-1.5">
            {LISTEN_ROUNDS.map((_, i) => (
              <div key={i} className="w-5 h-5 rounded-full flex items-center justify-center"
                style={{ background: i < rIdx ? "#03a566" : i === rIdx ? "rgba(255,255,255,0.9)" : "rgba(255,255,255,0.28)" }}>
                {i < rIdx && <Check size={11} color="white" strokeWidth={3} />}
                {i === rIdx && <div className="w-2 h-2 rounded-full" style={{ background: "#0877f2" }} />}
              </div>
            ))}
          </div>
        </div>
        <div className="h-2.5 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.28)" }}>
          <motion.div className="h-full rounded-full"
            animate={{ width: `${(rIdx / total) * 100}%` }}
            transition={{ duration: 0.5 }}
            style={{ background: "linear-gradient(90deg, #0877f2, #00d4ff)" }} />
        </div>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-4 z-10" style={{ scrollbarWidth: "none" }}>

        {/* Audio card */}
        <motion.div key={rIdx} className="w-full rounded-3xl overflow-hidden"
          style={{ boxShadow: "0 12px 32px rgba(8,119,242,0.25)" }}
          initial={{ y: -18, opacity: 0, scale: 0.95 }}
          animate={{ y: 0, opacity: 1, scale: 1 }}
          transition={{ duration: 0.38, type: "spring", stiffness: 220 }}>
          {/* Blue gradient banner */}
          <div className="relative flex flex-col items-center justify-center py-6 px-5 overflow-hidden"
            style={{ background: "linear-gradient(135deg, #0877f2 0%, #0452b8 100%)", minHeight: "140px" }}>
            {["🎵","🎶","🎵","♪"].map((n, i) => (
              <motion.span key={i} className="absolute select-none pointer-events-none"
                style={{ fontSize: "16px", left: `${i * 24 + 4}%`, top: i % 2 === 0 ? "10px" : "auto", bottom: i % 2 !== 0 ? "10px" : "auto", opacity: played ? 0.6 : 0.25 }}
                animate={played ? { y: [0, -8, 0], opacity: [0.6, 1, 0.6] } : {}}
                transition={{ duration: 1.2 + i * 0.3, repeat: Infinity, delay: i * 0.2 }}>
                {n}
              </motion.span>
            ))}

            {/* Speaker button or revealed word */}
            {!played ? (
              <div className="flex flex-col items-center gap-3">
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "rgba(255,255,255,0.72)", fontSize: "12px" }}>
                  👂 LISTEN & FIND THE ANIMAL
                </div>
                <motion.button onClick={playWord} whileTap={{ scale: 0.88 }}
                  className="w-20 h-20 rounded-full flex items-center justify-center relative"
                  animate={{ scale: [1, 1.06, 1] }}
                  transition={{ duration: 1.8, repeat: Infinity, ease: "easeInOut" }}
                  style={{
                    background: "rgba(255,255,255,0.22)",
                    border: "3px solid rgba(255,255,255,0.55)",
                    boxShadow: "0 0 0 12px rgba(255,255,255,0.08)",
                    backdropFilter: "blur(6px)",
                  }}>
                  <Volume2 size={36} color="white" />
                </motion.button>
                <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "16px" }}>
                  Tap to listen! 👆
                </div>
              </div>
            ) : (
              <motion.div className="flex flex-col items-center gap-2"
                initial={{ scale: 0, rotate: -10 }} animate={{ scale: 1, rotate: 0 }}
                transition={{ type: "spring", stiffness: 240 }}>
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "rgba(255,255,255,0.7)", fontSize: "11px", letterSpacing: "1.5px" }}>
                  🔊 THE WORD IS...
                </div>
                <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "44px", textShadow: "0 3px 12px rgba(0,0,0,0.22)", letterSpacing: "3px" }}>
                  {round.word}
                </div>
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "rgba(255,255,255,0.68)", fontSize: "14px" }}>
                  {round.phonetic}
                </div>
              </motion.div>
            )}
          </div>
          {/* Instruction row */}
          <div className="px-4 py-3 text-center" style={{ background: "white" }}>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "16px" }}>
              {!played ? "Tap the speaker to hear the word!" : "Now pick the right animal! 👇"}
            </div>
          </div>
        </motion.div>

        {/* 2×2 emoji options — no text labels (true listening exercise) */}
        <div className="grid grid-cols-2 gap-3">
          {round.options.map((opt, i) => {
            let cardBg  = "white";
            let border  = "2.5px solid rgba(8,119,242,0.2)";
            let shadow  = "0 4px 14px rgba(8,119,242,0.1)";
            let showOk  = false;
            let showBad = false;
            const answered = selected !== null;

            if (answered) {
              if (i === round.correct) {
                cardBg = "linear-gradient(135deg, #03a566, #017a48)"; border = "2.5px solid #03a566";
                shadow = "0 6px 20px rgba(3,165,102,0.42)"; showOk = true;
              } else if (i === selected) {
                cardBg = "linear-gradient(135deg, #ff2d55, #cc1133)"; border = "2.5px solid #ff2d55";
                shadow = "0 6px 20px rgba(255,45,85,0.38)"; showBad = true;
              } else {
                cardBg = "#f4f7fb"; border = "2.5px solid transparent"; shadow = "none";
              }
            } else if (!played) {
              cardBg = "#f4f7fb"; border = "2.5px solid transparent"; shadow = "none";
            }

            return (
              <motion.button key={i}
                whileTap={played && !answered ? { scale: 0.9 } : {}}
                onClick={() => pick(i)}
                animate={showBad ? { x: [0, -9, 9, -6, 6, 0] } : {}}
                transition={showBad ? { duration: 0.38 } : {}}
                className="rounded-3xl flex flex-col items-center justify-center gap-2 py-7 relative"
                style={{ background: cardBg, border, boxShadow: shadow, cursor: played && !answered ? "pointer" : "default", transition: "all 0.2s" }}>
                {showOk && (
                  <motion.div className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
                    initial={{ scale: 0 }} animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 300 }}
                    style={{ background: "rgba(255,255,255,0.3)" }}>
                    <Check size={13} color="white" strokeWidth={3} />
                  </motion.div>
                )}
                {showBad && (
                  <div className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
                    style={{ background: "rgba(255,255,255,0.3)" }}>
                    <X size={13} color="white" strokeWidth={3} />
                  </div>
                )}
                <motion.div
                  animate={showOk ? { scale: [1, 1.3, 1], rotate: [0, 12, 0] } : {}}
                  transition={{ duration: 0.35 }}
                  style={{ fontSize: "56px", lineHeight: 1, filter: !played && !answered ? "blur(1px) grayscale(0.5)" : "none", transition: "filter 0.3s" }}>
                  {opt}
                </motion.div>
              </motion.button>
            );
          })}
        </div>

        {/* Kiki */}
        {selected !== null ? (
          <motion.div className="flex items-end gap-3 px-1"
            initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
            <KikiPanda size={88} mood={correct ? "celebrating" : "happy"} />
            <motion.div className="mb-8 flex-1 rounded-3xl rounded-tl-sm px-3.5 py-2.5"
              style={{ background: "white", boxShadow: `0 6px 18px ${correct ? "rgba(3,165,102,0.15)" : "rgba(255,45,85,0.12)"}` }}
              initial={{ scale: 0 }} animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, delay: 0.1 }}>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, fontSize: "13px", color: correct ? "#03a566" : "#ff2d55" }}>
                {correct ? "🎉 Correct! Great listening! +5 ⭐" : "❌ Oops! Try listening again!"}
              </div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "12px", marginTop: "2px" }}>
                {correct ? "Your ears are amazing! 👂🌟" : `It was ${round.emoji} ${round.word}! You've got this! 💪`}
              </div>
            </motion.div>
          </motion.div>
        ) : (
          <motion.div className="flex items-end gap-3 px-1"
            animate={{ y: [0, -7, 0] }} transition={{ duration: 2.5, repeat: Infinity }}>
            <KikiPanda size={84} mood={played ? "listening" : "happy"} />
            <div className="mb-6 rounded-3xl rounded-tl-sm px-3.5 py-2"
              style={{ background: "rgba(255,255,255,0.85)", boxShadow: "0 4px 12px rgba(8,119,242,0.1)" }}>
              <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#0877f2", fontSize: "12px" }}>
                {played ? "Pick the animal you heard! 👆" : "Tap the speaker first! 🔊"}
              </span>
            </div>
          </motion.div>
        )}

        <div style={{ height: "8px" }} />
      </div>
    </div>
  );
}

// ─── SCREEN QUIZ ──────────────────────────────────────────────────────────────

function QuizScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [qIdx, setQIdx]         = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [score, setScore]       = useState(0);
  const [done, setDone]         = useState(false);
  const [showFW, setShowFW]     = useState(false);
  const timerRef                = useRef<ReturnType<typeof setTimeout> | null>(null);

  const q        = QUIZ_QUESTIONS[qIdx];
  const total    = QUIZ_QUESTIONS.length;
  const answered = selected !== null;
  const correct  = answered && selected === q.correct;

  const pick = (i: number) => {
    if (selected !== null) return;
    setSelected(i);
    const ok = i === q.correct;
    if (ok) {
      setScore(s => s + 1);
      setShowFW(true);
      timerRef.current = setTimeout(() => setShowFW(false), 1600);
    }
    timerRef.current = setTimeout(() => {
      if (qIdx < total - 1) { setQIdx(qi => qi + 1); setSelected(null); }
      else setDone(true);
    }, ok ? 1700 : 2100);
  };

  const restart = () => { setQIdx(0); setSelected(null); setScore(0); setDone(false); setShowFW(false); };

  /* ── Results ── */
  if (done) {
    const perfect = score === total;
    return (
      <div className="relative w-full h-full flex flex-col overflow-hidden"
        style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>
        {perfect && <FireworksBurst />}
        <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
          <Cloud x="-10px" y="4%" scale={0.7} delay={0} />
          <Cloud x="58%" y="8%" scale={0.55} delay={1.1} />
          <Sparkle x="8%"  y="20%" color="#fde047" />
          <Sparkle x="84%" y="15%" color="#ff5c9f" />
        </div>
        <div className="flex-1 flex flex-col items-center justify-center px-6 gap-4 z-10">
          <motion.div className="text-7xl"
            animate={{ rotate: [0, 15, -15, 0], scale: [1, 1.2, 1] }}
            transition={{ duration: 0.55, repeat: 3 }}>
            {perfect ? "🏆" : score >= 3 ? "⭐" : "💪"}
          </motion.div>
          <KikiPanda size={110} mood={perfect ? "celebrating" : "happy"} />
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "28px", color: "white", textAlign: "center", textShadow: "0 4px 0 #0566c5" }}>
            {perfect ? "Perfect Score! 🌟" : score >= 3 ? "Great Job! 👏" : "Keep Practicing! 💪"}
          </div>
          <div className="rounded-3xl px-6 py-5 flex flex-col items-center gap-3"
            style={{ background: "rgba(255,255,255,0.92)", boxShadow: "0 12px 32px rgba(0,0,0,0.1)", width: "100%" }}>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "24px" }}>
              {score} / {total} Correct!
            </div>
            <div className="flex gap-2">
              {Array.from({ length: total }).map((_, i) => (
                <Star key={i} size={26} fill={i < score ? "#fde047" : "#e0eaf4"} stroke="none" />
              ))}
            </div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "13px" }}>
              You earned {score * 5} ⭐ stars!
            </div>
          </div>
          <div className="flex gap-3 w-full">
            <motion.button whileTap={{ scale: 0.94 }} onClick={restart}
              className="flex-1 py-3.5 rounded-2xl"
              style={{ background: "rgba(255,255,255,0.8)", fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: "#102d54", boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}>
              Try Again 🔄
            </motion.button>
            <motion.button whileTap={{ scale: 0.94 }} onClick={() => onNav("lessonHub")}
              className="flex-1 py-3.5 rounded-2xl text-white"
              style={{ background: "linear-gradient(135deg, #ff5c9f, #ff1f6e)", fontFamily: "'Fredoka One', cursive", fontSize: "16px", boxShadow: "0 5px 0 #b8154e" }}>
              Keep Going! 🚀
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  /* ── Quiz screen ── */
  return (
    <div className="relative w-full h-full flex flex-col overflow-hidden"
      style={{ background: "linear-gradient(172deg, #3ea5ff 0%, #8ed8ff 52%, #c4f0ff 100%)" }}>
      {showFW && <FireworksBurst />}
      <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 0 }}>
        <Cloud x="-10px" y="4%" scale={0.7} delay={0} />
        <Cloud x="60%"   y="8%" scale={0.55} delay={1.1} />
        <Sparkle x="8%"  y="16%" color="#fde047" />
        <Sparkle x="84%" y="13%" color="#ff5c9f" />
      </div>

      {/* Header */}
      <div className="flex-none flex items-center gap-3 px-4 py-3 z-10"
        style={{ background: "rgba(255,255,255,0.22)", backdropFilter: "blur(12px)", borderBottom: "1.5px solid rgba(255,255,255,0.3)" }}>
        <button onClick={() => onNav("lessonHub")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0"
          style={{ background: "rgba(255,255,255,0.82)", boxShadow: "0 3px 10px rgba(0,0,0,0.1)" }}>
          <ChevronLeft size={20} color="#102d54" />
        </button>
        <div className="flex-1">
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "17px", color: "#102d54" }}>📝 Quiz Challenge</div>
          <div className="flex items-center gap-1">
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, fontSize: "10px", color: "#102d54", opacity: 0.5 }}>Lesson Hub</span>
            <ChevronRight size={10} color="rgba(16,45,84,0.36)" />
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, fontSize: "10px", color: "#ff8c00" }}>Quiz Challenge</span>
          </div>
        </div>
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl flex-shrink-0"
          style={{ background: "rgba(253,224,71,0.28)", border: "1.5px solid #fde047" }}>
          <Star size={13} fill="#fde047" stroke="#fde047" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b07800", fontSize: "13px" }}>{score * 5}</span>
        </div>
      </div>

      {/* Progress strip */}
      <div className="flex-none px-4 py-2 z-10" style={{ background: "rgba(255,255,255,0.15)" }}>
        <div className="flex items-center justify-between mb-1.5">
          <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "white", fontSize: "12px" }}>
            Question {qIdx + 1} of {total}
          </span>
          <div className="flex gap-1.5">
            {QUIZ_QUESTIONS.map((_, i) => (
              <div key={i} className="w-5 h-5 rounded-full flex items-center justify-center"
                style={{ background: i < qIdx ? "#03a566" : i === qIdx ? "rgba(255,255,255,0.9)" : "rgba(255,255,255,0.28)" }}>
                {i < qIdx && <Check size={11} color="white" strokeWidth={3} />}
                {i === qIdx && <div className="w-2 h-2 rounded-full" style={{ background: "#ff8c00" }} />}
              </div>
            ))}
          </div>
        </div>
        <div className="h-2.5 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.28)" }}>
          <motion.div className="h-full rounded-full"
            animate={{ width: `${(qIdx / total) * 100}%` }}
            transition={{ duration: 0.5 }}
            style={{ background: "linear-gradient(90deg, #fde047, #ff8c00)" }} />
        </div>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-3 z-10" style={{ scrollbarWidth: "none" }}>

        {/* Question card */}
        <motion.div key={qIdx} className="w-full rounded-3xl overflow-hidden"
          style={{ boxShadow: "0 12px 32px rgba(0,0,0,0.2)" }}
          initial={{ y: -18, opacity: 0, scale: 0.95 }}
          animate={{ y: 0, opacity: 1, scale: 1 }}
          transition={{ duration: 0.38, type: "spring", stiffness: 220 }}>
          <div className="relative flex flex-col items-center justify-center py-5 px-5 overflow-hidden"
            style={{ background: q.bg, minHeight: "118px" }}>
            {["✨","⭐","💫","🌟"].map((e, i) => (
              <motion.span key={i} className="absolute select-none pointer-events-none"
                style={{ fontSize: "14px", left: `${i * 24 + 4}%`, top: i % 2 === 0 ? "8px" : "auto", bottom: i % 2 !== 0 ? "8px" : "auto", opacity: 0.4 }}
                animate={{ rotate: [0, i % 2 === 0 ? 20 : -20, 0], scale: [1, 1.2, 1] }}
                transition={{ duration: 2.5 + i * 0.4, repeat: Infinity }}>
                {e}
              </motion.span>
            ))}
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "rgba(255,255,255,0.65)", fontSize: "10px", letterSpacing: "1.5px", marginBottom: "4px" }}>
              ❓ QUESTION {qIdx + 1}
            </div>
            <div className="text-center z-10"
              style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "21px", lineHeight: 1.25, textShadow: "0 2px 8px rgba(0,0,0,0.22)" }}>
              {q.question}
            </div>
            <div className="mt-1.5"
              style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "rgba(255,255,255,0.72)", fontSize: "11px" }}>
              {q.hint}
            </div>
          </div>
        </motion.div>

        {/* 2×2 answer grid */}
        <div className="grid grid-cols-2 gap-3">
          {q.options.map((opt, i) => {
            let cardBg  = "white";
            let shadow  = `0 4px 14px ${opt.color}1a`;
            let border  = `2.5px solid ${opt.color}28`;
            let textCol = "#102d54";
            let showOk  = false;
            let showBad = false;

            if (answered) {
              if (i === q.correct) {
                cardBg  = "linear-gradient(135deg, #03a566, #017a48)";
                border  = "2.5px solid #03a566";
                shadow  = "0 6px 20px rgba(3,165,102,0.42)";
                textCol = "white";
                showOk  = true;
              } else if (i === selected) {
                cardBg  = "linear-gradient(135deg, #ff2d55, #cc1133)";
                border  = "2.5px solid #ff2d55";
                shadow  = "0 6px 20px rgba(255,45,85,0.38)";
                textCol = "white";
                showBad = true;
              } else {
                cardBg  = "#f4f7fb";
                border  = "2.5px solid transparent";
                shadow  = "none";
                textCol = "#b0c4d8";
              }
            }

            return (
              <motion.button key={i}
                whileTap={!answered ? { scale: 0.9 } : {}}
                onClick={() => pick(i)}
                animate={showBad ? { x: [0, -9, 9, -6, 6, 0] } : {}}
                transition={showBad ? { duration: 0.38 } : {}}
                className="rounded-3xl flex flex-col items-center justify-center gap-2 py-5 relative"
                style={{ background: cardBg, border, boxShadow: shadow, cursor: answered ? "default" : "pointer", transition: "all 0.2s" }}>
                {showOk && (
                  <motion.div className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
                    initial={{ scale: 0 }} animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 300 }}
                    style={{ background: "rgba(255,255,255,0.3)" }}>
                    <Check size={13} color="white" strokeWidth={3} />
                  </motion.div>
                )}
                {showBad && (
                  <div className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center"
                    style={{ background: "rgba(255,255,255,0.3)" }}>
                    <X size={13} color="white" strokeWidth={3} />
                  </div>
                )}
                <motion.div
                  animate={showOk ? { scale: [1, 1.28, 1], rotate: [0, 12, 0] } : {}}
                  transition={{ duration: 0.35 }}
                  style={{ fontSize: "52px", lineHeight: 1 }}>
                  {opt.emoji}
                </motion.div>
                <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "16px", color: textCol }}>
                  {opt.text}
                </div>
              </motion.button>
            );
          })}
        </div>

        {/* Kiki feedback */}
        {answered ? (
          <motion.div className="flex items-end gap-3 px-1"
            initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
            <KikiPanda size={88} mood={correct ? "celebrating" : "happy"} />
            <motion.div className="mb-8 flex-1 rounded-3xl rounded-tl-sm px-3.5 py-2.5"
              style={{ background: "white", boxShadow: `0 6px 18px ${correct ? "rgba(3,165,102,0.15)" : "rgba(255,45,85,0.12)"}` }}
              initial={{ scale: 0 }} animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, delay: 0.1 }}>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, fontSize: "13px", color: correct ? "#03a566" : "#ff2d55" }}>
                {correct ? "🎉 Correct! +5 ⭐" : "❌ Oops! Almost there!"}
              </div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", fontSize: "12px", marginTop: "2px" }}>
                {correct
                  ? "Amazing! You're a quiz superstar! 🌟"
                  : `The answer is ${q.options[q.correct].text} ${q.options[q.correct].emoji}! You've got this! 💪`}
              </div>
            </motion.div>
          </motion.div>
        ) : (
          <motion.div className="flex items-end gap-3 px-1"
            animate={{ y: [0, -7, 0] }} transition={{ duration: 2.5, repeat: Infinity }}>
            <KikiPanda size={84} mood="excited" />
            <div className="mb-6 rounded-3xl rounded-tl-sm px-3.5 py-2"
              style={{ background: "rgba(255,255,255,0.85)", boxShadow: "0 4px 12px rgba(8,119,242,0.1)" }}>
              <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#0877f2", fontSize: "12px" }}>
                Tap the right answer! 👆
              </span>
            </div>
          </motion.div>
        )}

        <div style={{ height: "8px" }} />
      </div>
    </div>
  );
}

// ─── SCREEN F — ACHIEVEMENTS ──────────────────────────────────────────────────

function AchievementsScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const unlocked   = ACHIEVEMENTS.filter(a => a.unlocked).length;
  const totalStars = 120;

  return (
    <div className="w-full h-full flex flex-col">
      <TopBar stars={totalStars} streak={7} onProfile={() => onNav("profiles")} />

      <div className="flex-1 overflow-y-auto" style={{ scrollbarWidth: "none" }}>

        {/* ── Treasure Room header ── */}
        <div className="relative flex flex-col items-center px-4 pt-5 pb-0 overflow-hidden"
          style={{ background: "linear-gradient(160deg, #1a0a3c 0%, #3d1080 55%, #6b3fa8 100%)", minHeight: "180px" }}>
          {/* Star field */}
          {["✨","⭐","🌟","💫","✨","⭐","🌟"].map((s, i) => (
            <motion.span key={i} className="absolute select-none pointer-events-none"
              style={{ fontSize: i % 2 === 0 ? "14px" : "10px", left: `${i * 14 + 1}%`, top: `${(i % 3) * 22 + 6}px`, opacity: 0.65 }}
              animate={{ y: [0, -7, 0], opacity: [0.65, 1, 0.65] }}
              transition={{ duration: 2.2 + i * 0.35, repeat: Infinity, delay: i * 0.28 }}>
              {s}
            </motion.span>
          ))}

          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "20px", color: "#fde047", textShadow: "0 0 24px rgba(253,224,71,0.55)", zIndex: 1 }}>
            🏆 Treasure Room
          </div>

          {/* Animated chest */}
          <motion.div className="z-10 mt-1"
            animate={{ y: [0, -10, 0], rotate: [-2, 2, -2] }}
            transition={{ duration: 2.6, repeat: Infinity, ease: "easeInOut" }}>
            <div style={{ fontSize: "72px", filter: "drop-shadow(0 8px 24px rgba(253,224,71,0.45))" }}>💰</div>
          </motion.div>

          {/* Stars counter pill */}
          <motion.div className="z-10 mt-2 flex items-center gap-3 px-5 py-2 rounded-3xl mb-5"
            style={{ background: "rgba(253,224,71,0.18)", border: "2px solid rgba(253,224,71,0.48)" }}
            initial={{ scale: 0 }} animate={{ scale: 1 }}
            transition={{ delay: 0.4, type: "spring", stiffness: 200 }}>
            <Star size={22} fill="#fde047" stroke="#fde047" />
            <span style={{ fontFamily: "'Fredoka One', cursive", color: "#fde047", fontSize: "28px" }}>{totalStars}</span>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "rgba(253,224,71,0.8)", fontSize: "13px" }}>Total Stars</span>
          </motion.div>
        </div>

        {/* ── Main content card ── */}
        <div className="mx-3 -mt-4 rounded-3xl px-4 py-4 flex flex-col gap-4 mb-4"
          style={{ background: "white", boxShadow: "0 -6px 32px rgba(0,0,0,0.12)" }}>

          {/* Badge count header */}
          <div className="flex items-center justify-between">
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "18px" }}>🏅 My Badges</div>
            <div className="px-3 py-1 rounded-2xl"
              style={{ background: "rgba(253,224,71,0.18)", border: "1.5px solid #fde047" }}>
              <span style={{ fontFamily: "'Fredoka One', cursive", color: "#b07800", fontSize: "13px" }}>
                {unlocked} / {ACHIEVEMENTS.length} ✓
              </span>
            </div>
          </div>

          {/* Badge grid */}
          <div className="grid grid-cols-2 gap-3">
            {ACHIEVEMENTS.map((ach, i) => (
              <motion.div key={ach.id}
                initial={{ y: 18, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
                transition={{ delay: i * 0.06 }}
                className="rounded-2xl p-3 flex items-center gap-3 relative"
                style={{
                  background: ach.unlocked ? "white" : "rgba(240,244,248,0.8)",
                  border: `2px solid ${ach.unlocked ? ach.color + "38" : "rgba(154,176,200,0.18)"}`,
                  boxShadow: ach.unlocked ? `0 4px 16px ${ach.color}1e` : "none",
                  opacity: ach.unlocked ? 1 : 0.58,
                  filter: ach.unlocked ? "none" : "grayscale(0.6)",
                }}>
                {/* Badge circle */}
                <div className="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 relative"
                  style={{
                    background: ach.unlocked ? `linear-gradient(135deg, ${ach.color}22, ${ach.color}44)` : "#e8f0f8",
                    border: `2px solid ${ach.unlocked ? ach.color + "55" : "transparent"}`,
                    boxShadow: ach.unlocked ? `0 4px 12px ${ach.color}28` : "none",
                  }}>
                  <span style={{ fontSize: "24px" }}>{ach.emoji}</span>
                  {ach.unlocked && (
                    <motion.div className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full flex items-center justify-center"
                      initial={{ scale: 0 }} animate={{ scale: 1 }}
                      transition={{ delay: i * 0.06 + 0.25, type: "spring" }}
                      style={{ background: "#03a566" }}>
                      <Check size={11} color="white" strokeWidth={3} />
                    </motion.div>
                  )}
                  {!ach.unlocked && (
                    <div className="absolute -top-1.5 -right-1.5"><Lock size={12} color="#9ab0c8" /></div>
                  )}
                </div>
                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "13px", color: ach.unlocked ? "#102d54" : "#9ab0c8", lineHeight: 1.2 }}>
                    {ach.title}
                  </div>
                  {ach.unlocked && (
                    <div className="flex items-center gap-1 mt-0.5">
                      <Star size={10} fill="#fde047" stroke="#fde047" />
                      <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#b07800", fontSize: "10px" }}>
                        +{ach.stars} stars
                      </span>
                    </div>
                  )}
                  {!ach.unlocked && (
                    <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 600, color: "#b0c4d8", fontSize: "10px" }}>
                      Keep playing to unlock!
                    </div>
                  )}
                </div>
              </motion.div>
            ))}
          </div>

          {/* Kiki celebrating */}
          <div className="flex justify-center py-2">
            <motion.div animate={{ y: [0, -10, 0] }} transition={{ duration: 2, repeat: Infinity }}>
              <KikiPanda size={100} mood="celebrating" />
            </motion.div>
          </div>
          <div className="text-center pb-1"
            style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "12px" }}>
            Keep learning to unlock more badges! 🌟
          </div>
        </div>
      </div>

      <BottomNav current="achievements" onNav={onNav} />
    </div>
  );
}

// ─── SCREEN G — DAILY QUEST ───────────────────────────────────────────────────

function QuestScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const completed = QUESTS.filter(q => q.done).length;
  const allDone   = completed === QUESTS.length;

  return (
    <div className="w-full h-full flex flex-col">
      <TopBar stars={120} streak={7} onProfile={() => onNav("profiles")} />

      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3"
        style={{ background: "linear-gradient(172deg, #fff8e8 0%, #fff3cc 45%, #fffae8 100%)", scrollbarWidth: "none" }}>

        {/* ── Header banner ── */}
        <motion.div className="rounded-3xl overflow-hidden"
          style={{ boxShadow: "0 10px 28px rgba(255,183,0,0.30)" }}
          initial={{ y: -14, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
          <div className="px-4 py-4 flex items-center gap-3"
            style={{ background: "linear-gradient(135deg, #fde047, #ffb700)" }}>
            <div>
              <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "22px", color: "#102d54" }}>⚡ Daily Quests</div>
              <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#102d54", opacity: 0.68, fontSize: "12px" }}>
                Complete all missions to win the treasure!
              </div>
            </div>
            <div className="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-2xl"
              style={{ background: "rgba(0,0,0,0.14)" }}>
              <Flame size={16} fill="#ff6b00" stroke="#ff6b00" />
              <span style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "16px" }}>7</span>
            </div>
          </div>
          <div className="px-4 py-2.5 flex items-center gap-3" style={{ background: "white" }}>
            <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#102d54", fontSize: "12px" }}>
              Today's Progress
            </span>
            <div className="flex-1 h-2.5 rounded-full overflow-hidden" style={{ background: "#e0eaf4" }}>
              <motion.div className="h-full rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${(completed / QUESTS.length) * 100}%` }}
                transition={{ duration: 0.8 }}
                style={{ background: "linear-gradient(90deg, #03a566, #fde047)" }} />
            </div>
            <span style={{ fontFamily: "'Fredoka One', cursive", color: "#03a566", fontSize: "13px" }}>
              {completed} / {QUESTS.length}
            </span>
          </div>
        </motion.div>

        {/* ── Quest items ── */}
        {QUESTS.map((quest, i) => (
          <motion.div key={quest.id}
            initial={{ x: i % 2 === 0 ? -22 : 22, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.1 + i * 0.08 }}
            className="rounded-3xl px-4 py-3 flex items-center gap-3"
            style={{
              background: "white",
              boxShadow: quest.done ? `0 6px 20px ${quest.color}20` : "0 4px 12px rgba(0,0,0,0.06)",
              border: `2px solid ${quest.done ? quest.color + "28" : "transparent"}`,
            }}>
            {/* Icon */}
            <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl flex-shrink-0"
              style={{ background: quest.done ? `${quest.color}14` : "#f5f9ff" }}>
              {quest.emoji}
            </div>
            {/* Info */}
            <div className="flex-1 min-w-0">
              <div style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px", lineHeight: 1.2 }}>
                {quest.title}
              </div>
              {!quest.done ? (
                <div className="mt-1.5 flex items-center gap-2">
                  <div className="h-2 rounded-full overflow-hidden flex-1" style={{ background: "#e0eaf4" }}>
                    <motion.div className="h-full rounded-full"
                      initial={{ width: 0 }}
                      animate={{ width: `${(quest.progress / quest.total) * 100}%` }}
                      transition={{ duration: 0.8, delay: 0.2 + i * 0.1 }}
                      style={{ background: quest.color }} />
                  </div>
                  <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: quest.color, fontSize: "10px" }}>
                    {quest.progress}/{quest.total}
                  </span>
                </div>
              ) : (
                <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#03a566", fontSize: "11px", marginTop: "2px" }}>
                  ✅ Completed!
                </div>
              )}
            </div>
            {/* Reward + status */}
            <div className="flex flex-col items-end gap-1.5 flex-shrink-0">
              <div className="flex items-center gap-0.5 px-2 py-0.5 rounded-xl"
                style={{ background: "rgba(253,224,71,0.2)", border: "1px solid #fde047" }}>
                <Star size={11} fill="#fde047" stroke="#fde047" />
                <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#b07800", fontSize: "11px" }}>
                  +{quest.reward}
                </span>
              </div>
              <div className="w-9 h-9 rounded-2xl flex items-center justify-center"
                style={{ background: quest.done ? "#03a566" : "#e8f0f8" }}>
                {quest.done
                  ? <Check size={18} color="white" strokeWidth={3} />
                  : <div className="w-2 h-2 rounded-full" style={{ background: "#b0c4d8" }} />}
              </div>
            </div>
          </motion.div>
        ))}

        {/* ── Treasure chest ── */}
        <motion.div className="rounded-3xl overflow-hidden relative"
          style={{ boxShadow: allDone ? "0 14px 40px rgba(155,89,182,0.45)" : "0 8px 24px rgba(0,0,0,0.1)" }}
          initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5 }}>
          {allDone && <FireworksBurst />}
          <div className="px-5 py-7 flex flex-col items-center gap-3 text-center relative"
            style={{ background: allDone ? "linear-gradient(135deg, #9b59b6, #6b3fa8)" : "linear-gradient(135deg, #b07ac8, #8b55a8)" }}>
            {/* Chest decoration */}
            {["💎","✨","🌟","💎"].map((d, i) => (
              <motion.span key={i} className="absolute select-none pointer-events-none"
                style={{ fontSize: "14px", left: `${i * 24 + 4}%`, top: i % 2 === 0 ? "10px" : "auto", bottom: i % 2 !== 0 ? "10px" : "auto", opacity: 0.5 }}
                animate={{ rotate: [0, 20, 0], scale: [1, 1.3, 1] }}
                transition={{ duration: 2 + i * 0.3, repeat: Infinity, delay: i * 0.2 }}>
                {d}
              </motion.span>
            ))}

            <motion.div
              animate={allDone
                ? { scale: [1, 1.25, 1], rotate: [-8, 8, 0] }
                : { y: [0, -7, 0], rotate: [-3, 3, -3] }}
              transition={allDone
                ? { duration: 0.5, repeat: 3 }
                : { duration: 2.2, repeat: Infinity }}>
              <div style={{ fontSize: "68px", filter: "drop-shadow(0 6px 18px rgba(0,0,0,0.32))" }}>
                {allDone ? "🎁" : "🪙"}
              </div>
            </motion.div>

            <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "21px", zIndex: 1 }}>
              {allDone ? "Reward Unlocked! 🎉" : "Quest Reward Chest"}
            </div>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "rgba(255,255,255,0.78)", fontSize: "12px", zIndex: 1 }}>
              {allDone
                ? "Amazing! You completed all of today's quests!"
                : `Complete all ${QUESTS.length} quests to open the chest!`}
            </div>

            {!allDone && (
              <div className="flex items-center gap-2 z-10">
                {QUESTS.map((q, i) => (
                  <div key={i} className="w-6 h-6 rounded-full flex items-center justify-center"
                    style={{ background: q.done ? "#fde047" : "rgba(255,255,255,0.22)" }}>
                    {q.done && <Check size={13} color="#102d54" strokeWidth={3} />}
                  </div>
                ))}
                <span style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "rgba(255,255,255,0.8)", fontSize: "12px" }}>
                  {completed}/{QUESTS.length} done
                </span>
              </div>
            )}

            {allDone && (
              <motion.button whileTap={{ scale: 0.95 }}
                className="px-8 py-3 rounded-2xl z-10"
                style={{ background: "linear-gradient(135deg, #fde047, #ffb700)", fontFamily: "'Fredoka One', cursive", fontSize: "18px", color: "#102d54", boxShadow: "0 5px 0 #c08000" }}>
                Collect Reward! ⭐
              </motion.button>
            )}
          </div>
        </motion.div>

        {/* Kiki at bottom */}
        <div className="flex justify-center py-2">
          <motion.div animate={{ y: [0, -8, 0] }} transition={{ duration: 2.2, repeat: Infinity }}>
            <KikiPanda size={90} mood={allDone ? "celebrating" : "excited"} />
          </motion.div>
        </div>

        <div style={{ height: "8px" }} />
      </div>

      <BottomNav current="quest" onNav={onNav} />
    </div>
  );
}

// ─── SCREEN H — BOSS STAGE ────────────────────────────────────────────────────

function BossScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const [qIdx, setQIdx] = useState(0);
  const [score, setScore] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [done, setDone] = useState(false);
  const q = BOSS_QS[qIdx];

  const pick = (i: number) => {
    if (selected !== null) return;
    setSelected(i);
    if (i === q.correct) setScore(s => s + 1);
    setTimeout(() => {
      if (qIdx < BOSS_QS.length - 1) { setQIdx(qi => qi + 1); setSelected(null); }
      else setDone(true);
    }, 900);
  };

  return (
    <div className="w-full h-full flex flex-col" style={{ background: "#0d1b4b" }}>
      {/* header */}
      <div className="flex-none flex items-center gap-3 px-4 py-3">
        <button onClick={() => onNav("quest")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center"
          style={{ background: "rgba(255,255,255,0.1)" }}>
          <ChevronLeft size={20} color="white" />
        </button>
        <div className="flex-1 text-center font-black"
          style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "18px" }}>
          ⚔️ Boss Stage!
        </div>
        <div className="flex items-center gap-1.5 px-3 py-1 rounded-2xl"
          style={{ background: "rgba(253,224,71,0.14)" }}>
          <Star size={14} fill="#fde047" stroke="#fde047" />
          <span style={{ fontFamily: "'Fredoka One', cursive", color: "#fde047", fontSize: "14px" }}>
            {score}/{BOSS_QS.length}
          </span>
        </div>
      </div>

      {!done ? (
        <div className="flex-1 overflow-y-auto flex flex-col items-center px-4 py-3 gap-5">
          {/* progress pips */}
          <div className="w-full flex gap-2">
            {BOSS_QS.map((_, i) => (
              <div key={i} className="flex-1 h-2 rounded-full transition-all"
                style={{ background: i <= qIdx ? "#fde047" : "rgba(255,255,255,0.14)" }} />
            ))}
          </div>

          {/* boss */}
          <motion.div className="text-center"
            animate={{ y: [0, -10, 0] }} transition={{ duration: 1.6, repeat: Infinity }}>
            <div className="text-7xl">👾</div>
            <div className="text-sm font-bold mt-1"
              style={{ fontFamily: "'Nunito', sans-serif", color: "rgba(255,255,255,0.52)" }}>
              Vocab Dragon Boss
            </div>
          </motion.div>

          {/* question */}
          <div className="w-full rounded-3xl p-5 flex flex-col items-center gap-2"
            style={{ background: "rgba(255,255,255,0.07)", border: "2px solid rgba(255,255,255,0.14)" }}>
            <div className="text-xs font-bold"
              style={{ fontFamily: "'Nunito', sans-serif", color: "rgba(255,255,255,0.48)" }}>
              Which image shows…
            </div>
            <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "40px" }}>{q.word}</div>
          </div>

          {/* options */}
          <div className="grid grid-cols-2 gap-3 w-full">
            {q.options.map((opt, i) => {
              let bg = "rgba(255,255,255,0.07)";
              let border = "2px solid rgba(255,255,255,0.14)";
              if (selected !== null) {
                if (i === q.correct)                         { bg = "rgba(3,165,102,0.3)";  border = "2px solid #03a566"; }
                else if (i === selected && i !== q.correct) { bg = "rgba(255,92,159,0.3)"; border = "2px solid #ff5c9f"; }
              }
              return (
                <motion.button key={i} whileTap={{ scale: 0.9 }} onClick={() => pick(i)}
                  className="rounded-3xl py-6 flex items-center justify-center text-5xl"
                  style={{ background: bg, border, transition: "background 0.2s, border 0.2s" }}>
                  {opt}
                </motion.button>
              );
            })}
          </div>

          <div className="text-sm"
            style={{ fontFamily: "'Nunito', sans-serif", color: "rgba(255,255,255,0.45)" }}>
            Question {qIdx + 1} of {BOSS_QS.length}
          </div>
        </div>
      ) : (
        <div className="flex-1 flex flex-col items-center justify-center px-6 gap-4">
          <motion.div className="text-7xl"
            animate={{ rotate: [0, 16, -16, 0], scale: [1, 1.2, 1] }}
            transition={{ duration: 0.6, repeat: 3 }}>🏆</motion.div>
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "30px", color: "white", textAlign: "center" }}>
            Boss Defeated! 🎉
          </div>
          <KikiPanda size={100} mood="celebrating" />
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "22px", color: "#fde047" }}>
            Score: {score} / {BOSS_QS.length}
          </div>
          <div className="flex gap-3">
            {Array.from({ length: BOSS_QS.length }).map((_, i) => (
              <Star key={i} size={34} fill={i < score ? "#fde047" : "rgba(255,255,255,0.18)"} stroke="none" />
            ))}
          </div>
          <motion.button whileTap={{ scale: 0.95 }} onClick={() => onNav("map")}
            className="w-full py-3 rounded-3xl"
            style={{
              fontFamily: "'Fredoka One', cursive", fontSize: "19px",
              background: "linear-gradient(135deg, #fde047, #ffb700)", color: "#102d54",
              boxShadow: "0 6px 0 #c08000",
            }}>
            🗺️ Back to Map!
          </motion.button>
        </div>
      )}
    </div>
  );
}

// ─── SCREEN I — PARENT DASHBOARD ─────────────────────────────────────────────

function ParentScreen({ onNav }: { onNav: (s: Screen) => void }) {
  const topics = [
    { topic: "Animals", pct: 80, color: "#03a566" },
    { topic: "Food",    pct: 45, color: "#ff8c00" },
    { topic: "Family",  pct: 30, color: "#ff5c9f" },
    { topic: "School",  pct:  0, color: "#0877f2"  },
    { topic: "Space",   pct:  0, color: "#9b59b6"  },
  ];

  return (
    <div className="w-full h-full flex flex-col">
      {/* header */}
      <div className="flex-none flex items-center gap-3 px-4 py-3"
        style={{ background: "#102d54", borderBottom: "1px solid rgba(255,255,255,0.08)" }}>
        <button onClick={() => onNav("welcome")}
          className="w-9 h-9 rounded-2xl flex items-center justify-center"
          style={{ background: "rgba(255,255,255,0.1)" }}>
          <ChevronLeft size={20} color="white" />
        </button>
        <div style={{ fontFamily: "'Fredoka One', cursive", color: "white", fontSize: "18px" }}>
          👨‍👩‍👧 Parent Dashboard
        </div>
        <div className="ml-auto text-sm font-bold" style={{ fontFamily: "'Nunito', sans-serif", color: "rgba(255,255,255,0.5)" }}>
          Emma
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-4"
        style={{ background: "#f0f6ff" }}>

        {/* stat cards */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: "Lessons Done",   value: "24",      emoji: "📖", color: "#0877f2", bg: "#e0f0ff" },
            { label: "Learning Time",  value: "3.2 hrs", emoji: "⏰", color: "#03a566", bg: "#d4f5e7" },
            { label: "Avg. Score",     value: "91%",     emoji: "🎯", color: "#ff5c9f", bg: "#ffe0f0" },
            { label: "Day Streak",     value: "7 🔥",    emoji: "🔥", color: "#ff8c00", bg: "#ffe8cc" },
          ].map((s, i) => (
            <motion.div key={i}
              initial={{ y: 18, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
              transition={{ delay: i * 0.07 }}
              className="rounded-3xl p-4"
              style={{ background: "white", boxShadow: `0 4px 16px ${s.color}18` }}>
              <div className="text-2xl mb-1">{s.emoji}</div>
              <div style={{ fontFamily: "'Fredoka One', cursive", color: s.color, fontSize: "24px" }}>{s.value}</div>
              <div className="text-xs font-bold mt-0.5"
                style={{ fontFamily: "'Nunito', sans-serif", color: "#9ab0c8" }}>{s.label}</div>
            </motion.div>
          ))}
        </div>

        {/* weekly bar chart */}
        <div className="rounded-3xl p-4 bg-white" style={{ boxShadow: "0 4px 16px rgba(0,0,0,0.05)" }}>
          <div className="font-black mb-3" style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px" }}>
            📅 This Week's Learning
          </div>
          <ResponsiveContainer width="100%" height={118}>
            <BarChart data={WEEK_DATA} barSize={26} margin={{ top: 0, right: 0, left: -28, bottom: 0 }}>
              <XAxis dataKey="day"
                tick={{ fontSize: 11, fontFamily: "'Nunito', sans-serif", fill: "#9ab0c8" }}
                axisLine={false} tickLine={false} />
              <Bar dataKey="mins" radius={[6, 6, 0, 0]}>
                {WEEK_DATA.map((_, i) => (
                  <Cell key={i} fill={i === 5 ? "#0877f2" : "#8ed8ff"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="text-xs text-center mt-1"
            style={{ fontFamily: "'Nunito', sans-serif", color: "#9ab0c8" }}>
            Minutes per day · Best: Saturday (25 min)
          </div>
        </div>

        {/* topic progress */}
        <div className="rounded-3xl p-4 bg-white" style={{ boxShadow: "0 4px 16px rgba(0,0,0,0.05)" }}>
          <div className="font-black mb-3" style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px" }}>
            🗺️ Topic Progress
          </div>
          <div className="flex flex-col gap-2.5">
            {topics.map((p, i) => (
              <div key={i} className="flex items-center gap-3">
                <div className="w-18 text-sm font-bold"
                  style={{ fontFamily: "'Nunito', sans-serif", color: "#102d54", minWidth: "60px" }}>{p.topic}</div>
                <div className="flex-1 h-2.5 rounded-full overflow-hidden" style={{ background: "#e0eaf4" }}>
                  <motion.div className="h-full rounded-full"
                    initial={{ width: 0 }} animate={{ width: `${p.pct}%` }}
                    transition={{ duration: 0.8, delay: 0.1 + i * 0.1 }}
                    style={{ background: p.pct > 0 ? `linear-gradient(90deg, ${p.color}, ${p.color}99)` : "#e0eaf4" }} />
                </div>
                <div className="w-10 text-right text-xs font-black"
                  style={{ fontFamily: "'Fredoka One', cursive", color: p.pct > 0 ? p.color : "#c8d8e8" }}>
                  {p.pct}%
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* pronunciation */}
        <div className="rounded-3xl p-4 bg-white" style={{ boxShadow: "0 4px 16px rgba(0,0,0,0.05)" }}>
          <div className="font-black mb-3" style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px" }}>
            🎤 Pronunciation Averages
          </div>
          <div className="grid grid-cols-3 gap-2">
            {[
              { label: "Accuracy",     value: 91, color: "#03a566" },
              { label: "Fluency",      value: 85, color: "#0877f2" },
              { label: "Overall",      value: 89, color: "#ff5c9f" },
            ].map(s => (
              <div key={s.label} className="flex flex-col items-center gap-1 p-3 rounded-2xl"
                style={{ background: `${s.color}0f` }}>
                <div style={{ fontFamily: "'Fredoka One', cursive", color: s.color, fontSize: "24px" }}>{s.value}%</div>
                <div className="text-xs font-bold"
                  style={{ fontFamily: "'Nunito', sans-serif", color: "#9ab0c8" }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* achievements */}
        <div className="rounded-3xl p-4 bg-white" style={{ boxShadow: "0 4px 16px rgba(0,0,0,0.05)" }}>
          <div className="font-black mb-3" style={{ fontFamily: "'Fredoka One', cursive", color: "#102d54", fontSize: "15px" }}>
            🏆 Achievements (4 / 6)
          </div>
          <div className="flex gap-3 flex-wrap">
            {ACHIEVEMENTS.filter(a => a.unlocked).map(a => (
              <div key={a.id} className="flex flex-col items-center gap-1">
                <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl"
                  style={{ background: `${a.color}1c`, border: `2px solid ${a.color}36` }}>
                  {a.emoji}
                </div>
                <div className="text-xs text-center font-bold"
                  style={{ fontFamily: "'Nunito', sans-serif", color: "#9ab0c8", maxWidth: "52px", lineHeight: 1.2 }}>
                  {a.title}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── BG STARS (stable positions) ──────────────────────────────────────────────

// ─── PARENT GATE ─────────────────────────────────────────────────────────────

const PARENT_CODE = "1234";

function ParentGateModal({ onSuccess, onCancel }: {
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [digits, setDigits] = useState<string[]>([]);
  const [shake, setShake]   = useState(false);
  const [wrong, setWrong]   = useState(false);

  const addDigit = (d: string) => {
    if (digits.length >= 4) return;
    const next = [...digits, d];
    setDigits(next);
    if (next.length === 4) {
      if (next.join("") === PARENT_CODE) {
        onSuccess();
      } else {
        setShake(true); setWrong(true);
        setTimeout(() => { setShake(false); setWrong(false); setDigits([]); }, 900);
      }
    }
  };

  const del = () => setDigits(d => d.slice(0, -1));

  const canVerify = digits.length === 4;

  return (
    <motion.div
      className="absolute inset-0 z-50 flex items-center justify-center px-4"
      style={{ background: "rgba(5,30,90,0.72)", backdropFilter: "blur(10px)" }}
      initial={{ opacity: 0 }} animate={{ opacity: 1 }}
      transition={{ duration: 0.22 }}>

      <motion.div className="w-full rounded-3xl overflow-hidden"
        style={{ maxWidth: "334px", background: "white", boxShadow: "0 28px 72px rgba(0,0,0,0.4)" }}
        initial={{ scale: 0.72, y: 36, opacity: 0 }}
        animate={{ scale: 1, y: 0, opacity: 1 }}
        transition={{ type: "spring", stiffness: 220, damping: 22, delay: 0.06 }}>

        {/* ── Header ── */}
        <div className="px-5 pt-5 pb-4 text-center"
          style={{ background: "linear-gradient(160deg, #eef7ff 0%, #e0efff 100%)" }}>
          {/* lock icon row */}
          <motion.div className="text-5xl mb-2"
            animate={{ rotate: [0, -8, 8, 0] }}
            transition={{ duration: 0.6, delay: 0.3, repeat: 0 }}>
            🔐
          </motion.div>
          <div style={{ fontFamily: "'Fredoka One', cursive", fontSize: "24px", color: "#102d54" }}>
            Parents Only!
          </div>
          <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "12px", marginTop: "4px", lineHeight: 1.4 }}>
            Please enter your secret 4-digit Parent Code to continue
          </div>
        </div>

        {/* ── Kiki (smart) + speech bubble ── */}
        <div className="flex items-end gap-2 px-4 pt-3 pb-1">
          <motion.div className="flex-shrink-0"
            animate={{ y: [0, -5, 0] }} transition={{ duration: 2.4, repeat: Infinity }}>
            <KikiPanda size={72} mood="smart" />
          </motion.div>
          <motion.div className="mb-5 flex-1 rounded-2xl rounded-tl-sm px-3 py-2.5"
            style={{ background: "#f0f8ff", border: "1.5px solid #c8dff5" }}
            initial={{ scale: 0 }} animate={{ scale: 1 }}
            transition={{ delay: 0.5, type: "spring", stiffness: 200 }}>
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 900, color: "#102d54", fontSize: "11.5px", lineHeight: 1.45 }}>
              Hi there! 🐼<br />
              <span style={{ color: "#0877f2" }}>Ask your mom or dad for help!</span>
            </div>
          </motion.div>
        </div>

        {/* ── 4-digit dot slots ── */}
        <motion.div className="flex justify-center gap-3 px-5 py-2"
          animate={shake ? { x: [0, -11, 11, -8, 8, -4, 4, 0] } : {}}
          transition={{ duration: 0.42 }}>
          {[0, 1, 2, 3].map(i => {
            const filled = i < digits.length;
            return (
              <div key={i}
                className="w-14 h-14 rounded-2xl flex items-center justify-center"
                style={{
                  background: filled ? (wrong ? "#fff0f0" : "#f0fdf4") : "white",
                  border: `2.5px solid ${filled ? (wrong ? "#ff2d55" : "#03a566") : "#c8dff5"}`,
                  boxShadow: filled
                    ? (wrong ? "0 4px 14px rgba(255,45,85,0.22)" : "0 4px 14px rgba(3,165,102,0.22)")
                    : "0 2px 8px rgba(0,0,0,0.06)",
                  transition: "all 0.2s",
                }}>
                {filled && (
                  <motion.div
                    initial={{ scale: 0 }} animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 350 }}>
                    <div style={{
                      width: "18px", height: "18px", borderRadius: "50%",
                      background: wrong ? "#ff2d55" : "#03a566",
                      boxShadow: wrong ? "0 2px 8px rgba(255,45,85,0.5)" : "0 2px 8px rgba(3,165,102,0.5)",
                    }} />
                  </motion.div>
                )}
              </div>
            );
          })}
        </motion.div>

        {/* wrong message / demo hint */}
        <div className="text-center px-4 mb-1" style={{ minHeight: "20px" }}>
          {wrong ? (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}
              style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 800, color: "#ff2d55", fontSize: "11px" }}>
              ❌ Wrong code! Try again.
            </motion.div>
          ) : (
            <div style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 600, color: "#b0c4d8", fontSize: "10px" }}>
              🔑 Demo code: 1 · 2 · 3 · 4
            </div>
          )}
        </div>

        {/* ── Custom numeric keypad ── */}
        <div className="px-4 pb-2">
          <div className="grid grid-cols-3 gap-2">
            {/* 1-9 */}
            {[1,2,3,4,5,6,7,8,9].map(n => (
              <motion.button key={n} whileTap={{ scale: 0.86 }}
                onClick={() => addDigit(String(n))}
                className="rounded-2xl flex items-center justify-center"
                style={{ height: "54px", background: "white", border: "1.5px solid #e0eaf4", boxShadow: "0 4px 0 #d0dff0" }}>
                <span style={{ fontFamily: "'Fredoka One', cursive", fontSize: "22px", color: "#102d54" }}>{n}</span>
              </motion.button>
            ))}
            {/* Bottom row: Delete · 0 · Cancel */}
            <motion.button whileTap={{ scale: 0.86 }} onClick={del}
              className="rounded-2xl flex items-center justify-center"
              style={{ height: "54px", background: "#fff3f5", border: "1.5px solid #ffd0d8", boxShadow: "0 4px 0 #ffc0cc" }}>
              <span style={{ fontSize: "20px" }}>⌫</span>
            </motion.button>
            <motion.button whileTap={{ scale: 0.86 }} onClick={() => addDigit("0")}
              className="rounded-2xl flex items-center justify-center"
              style={{ height: "54px", background: "white", border: "1.5px solid #e0eaf4", boxShadow: "0 4px 0 #d0dff0" }}>
              <span style={{ fontFamily: "'Fredoka One', cursive", fontSize: "22px", color: "#102d54" }}>0</span>
            </motion.button>
            <motion.button whileTap={{ scale: 0.86 }} onClick={onCancel}
              className="rounded-2xl flex items-center justify-center"
              style={{ height: "54px", background: "#fff3f5", border: "1.5px solid #ffd0d8", boxShadow: "0 4px 0 #ffc0cc" }}>
              <X size={20} color="#ff5c9f" />
            </motion.button>
          </div>
        </div>

        {/* ── Verify button ── */}
        <div className="px-4 pb-5 pt-1">
          <motion.button
            whileTap={canVerify ? { scale: 0.95 } : {}}
            onClick={() => { if (canVerify) { if (digits.join("") === PARENT_CODE) onSuccess(); else { setShake(true); setWrong(true); setTimeout(() => { setShake(false); setWrong(false); setDigits([]); }, 900); } } }}
            className="w-full py-3.5 rounded-2xl"
            style={{
              fontFamily: "'Fredoka One', cursive", fontSize: "18px",
              background: canVerify ? "linear-gradient(135deg, #ff5c9f, #ff1f6e)" : "#e8f0f8",
              color: canVerify ? "white" : "#b0c4d8",
              boxShadow: canVerify ? "0 6px 0 #b8154e, 0 10px 24px rgba(255,31,110,0.32)" : "none",
              cursor: canVerify ? "pointer" : "default",
              transition: "all 0.2s",
            }}>
            {canVerify ? "Verify Code ✓" : "Enter 4 digits first"}
          </motion.button>
          <button onClick={onCancel} className="w-full mt-2.5 text-center"
            style={{ fontFamily: "'Nunito', sans-serif", fontWeight: 700, color: "#9ab0c8", fontSize: "13px" }}>
            ← Go Back
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

const BG_STARS = [
  { x: 5,  y: 12, s: 2.5 }, { x: 18, y: 28, s: 1.5 }, { x: 32, y: 8,  s: 2   },
  { x: 48, y: 18, s: 1.8 }, { x: 62, y: 5,  s: 2.2 }, { x: 76, y: 24, s: 1.5 },
  { x: 88, y: 10, s: 2   }, { x: 94, y: 40, s: 1.5 }, { x: 10, y: 55, s: 1.8 },
  { x: 24, y: 70, s: 2   }, { x: 38, y: 82, s: 1.5 }, { x: 52, y: 65, s: 2.2 },
  { x: 68, y: 78, s: 1.8 }, { x: 82, y: 62, s: 2   }, { x: 96, y: 85, s: 1.5 },
  { x: 14, y: 92, s: 2   }, { x: 44, y: 45, s: 1.5 }, { x: 58, y: 50, s: 2.2 },
  { x: 72, y: 36, s: 1.8 }, { x: 86, y: 50, s: 1.5 },
];

// ─── ROOT APP ─────────────────────────────────────────────────────────────────

const ALL_SCREENS: Screen[] = [
  "welcome","profiles","createProfile","map","lessonHub","vocab","listening","pronunciation","quiz","achievements","quest","boss","parent"
];

export default function App() {
  const [screen, setScreen]     = useState<Screen>("welcome");
  const [gateOpen, setGateOpen] = useState(false);

  // Intercept navigation to "parent" — show the gate first
  const navigate = (s: Screen) => {
    if (s === "parent") { setGateOpen(true); return; }
    setScreen(s);
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 relative overflow-hidden"
      style={{ background: "linear-gradient(140deg, #1a0a3c 0%, #0d2060 55%, #0a3880 100%)" }}>
      {/* bg stars */}
      {BG_STARS.map((st, i) => (
        <div key={i} className="absolute rounded-full pointer-events-none"
          style={{
            left: `${st.x}%`, top: `${st.y}%`,
            width: `${st.s}px`, height: `${st.s}px`,
            background: "white", opacity: 0.45 + (i % 5) * 0.1,
          }} />
      ))}

      {/* phone frame */}
      <div className="relative flex-shrink-0"
        style={{
          width: "390px", height: "844px",
          borderRadius: "50px", background: "#111",
          boxShadow: "0 0 0 2px #383838, 0 0 0 3px #111, 0 32px 80px rgba(0,0,0,0.65), inset 0 0 0 1px rgba(255,255,255,0.04)",
          padding: "12px",
        }}>
        {/* screen area */}
        <div className="relative w-full h-full rounded-[40px] overflow-hidden flex flex-col"
          style={{ background: "#8ed8ff" }}>
          {/* dynamic island / notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 z-50"
            style={{ width: "120px", height: "34px", background: "#111", borderRadius: "0 0 22px 22px" }}>
            <div className="absolute right-8 top-1/2 -translate-y-1/2 w-3 h-3 rounded-full"
              style={{ background: "#2a2a2a" }} />
          </div>

          {/* content */}
          <div className="w-full h-full pt-8 flex flex-col">
            {screen === "welcome"        && <WelcomeScreen        onNav={navigate} />}
            {screen === "profiles"      && <ProfilesScreen      onNav={navigate} />}
            {screen === "createProfile" && <CreateProfileScreen  onNav={navigate} />}
            {screen === "map"          && <MapScreen          onNav={navigate} />}
            {screen === "lessonHub"    && <LessonHubScreen    onNav={navigate} />}
            {screen === "listening"    && <ListeningScreen    onNav={navigate} />}
            {screen === "quiz"         && <QuizScreen         onNav={navigate} />}
            {screen === "vocab"        && <VocabScreen        onNav={navigate} />}
            {screen === "pronunciation"&& <PronunciationScreen onNav={navigate} />}
            {screen === "achievements" && <AchievementsScreen onNav={navigate} />}
            {screen === "quest"        && <QuestScreen        onNav={navigate} />}
            {screen === "boss"         && <BossScreen         onNav={navigate} />}
            {screen === "parent"       && <ParentScreen       onNav={navigate} />}

            {/* Parent Gate Modal — absolute overlay inside the phone screen */}
            {gateOpen && (
              <ParentGateModal
                onSuccess={() => { setGateOpen(false); setScreen("parent"); }}
                onCancel={() => setGateOpen(false)}
              />
            )}
          </div>
        </div>
      </div>

      {/* screen nav pills */}
      <div className="mt-5 flex flex-wrap justify-center gap-2 max-w-lg">
        {ALL_SCREENS.map(s => (
          <button key={s} onClick={() => navigate(s)}
            className="px-3 py-1 rounded-full text-xs font-black transition-all"
            style={{
              background: screen === s ? "rgba(255,255,255,0.95)" : "rgba(255,255,255,0.12)",
              color: screen === s ? "#102d54" : "rgba(255,255,255,0.65)",
              fontFamily: "'Nunito', sans-serif",
              boxShadow: screen === s ? "0 2px 12px rgba(255,255,255,0.2)" : "none",
            }}>
            {s}
          </button>
        ))}
      </div>
    </div>
  );
}
