import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";

export default function Landing() {
  const navigate = useNavigate();

  // Animation variants for smooth loading
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.15, // Loads items one after another
      },
    },
  };

  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: { y: 0, opacity: 1, transition: { type: "spring", stiffness: 100 } },
  };

  return (
    // MAIN WRAPPER (Handles full-screen background)
    // We use a dark background with radial gradients (glowing orbs) to match the Yearn screenshot aesthetic.
    <div className="min-h-screen bg-black text-white relative overflow-hidden">
      
      {/* ─── BACKGROUND DECORATION (The Glowing Orbs) ─── */}
      <div className="absolute inset-0 z-0">
        {/* Top-left soft blue glow */}
        <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] rounded-full bg-blue-900 opacity-30 blur-[120px]" />
        {/* Bottom-right soft purple glow */}
        <div className="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] rounded-full bg-purple-900 opacity-20 blur-[150px]" />
      </div>

      {/* ─── HEADER NAVIGATION ─── */}
      <header className="relative z-10 flex items-center justify-between p-6 md:px-12 backdrop-blur-sm bg-black/30 border-b border-gray-800">
        <div className="flex items-center gap-2">
          {/* Logo placeholder - replace with your icon */}
          <div className="w-8 h-8 rounded-full bg-red-900 flex items-center justify-center font-bold text-sm">
            D
          </div>
          <span className="text-xl font-bold tracking-tight">DotYield</span>
        </div>
        
        {/* Navigation Links (Desktop) */}
        <nav className="hidden md:flex items-center gap-8 text-gray-300">
          <a href="#features" className="hover:text-white transition">Features</a>
          <a href="#how-it-works" className="hover:text-white transition">How it Works</a>
          <a href="#security" className="hover:text-white transition">Security</a>
        </nav>

        {/* Call to Action in Nav */}
        <button 
          onClick={() => navigate("/app")}
          className="bg-red-900 text-white px-4 py-2 rounded-sm font-semibold hover:bg-red-800 transition shadow-md shadow-red-950/30"
        >
          Launch App
        </button>
      </header>

      {/* ─── HERO SECTION (Centered Content) ─── */}
      <main className="relative z-10 flex-grow flex items-center justify-center pt-16 pb-24 px-6">
        <motion.div 
          className="flex flex-col items-center justify-center text-center max-w-4xl"
          initial="hidden"
          animate="visible"
          variants={containerVariants}
        >
          
          {/* Tagline/Pill (Like the 'deposited' pill in the screenshot) */}
          <motion.div 
            variants={itemVariants}
            className="inline-flex items-center gap-2 border border-gray-700 bg-gray-900/60 px-4 py-1.5 rounded-full text-xs text-gray-300 mb-6 backdrop-blur-sm"
          >
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Optimizing across 5+ chains seamlessly.
          </motion.div>

          {/* Main Title - Smaller on mobile, large on desktop */}
          <motion.h1 
            variants={itemVariants}
            className="text-5xl md:text-7xl lg:text-8xl font-extrabold mb-8 tracking-tighter leading-tight bg-gradient-to-b from-white to-gray-400 bg-clip-text text-transparent"
          >
            DotYield
          </motion.h1>

          {/* Subtitle/Description */}
          <motion.p 
            variants={itemVariants}
            className="text-xs md:text-sm text-gray-400 w-4/6 mb-12 leading-relaxed"
          >
            Deposit once and let AI manage your crypto portfolio automatically with tested strategies.
          </motion.p>

          {/* Hero Button - Primary "Explore" action */}
          <motion.button
            variants={itemVariants}
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.98 }}
            className="bg-white text-black mt-12 px-4 py-1 rounded-2xl font-bold text-sm shadow-lg hover:shadow-xl hover:bg-gray-100 transition-all flex items-center gap-2"
            onClick={() => {
                // Smooth scroll to main features if needed
                // document.getElementById('features').scrollIntoView({ behavior: 'smooth' });
                navigate("/app"); // Keep navigation for now, but move visual hierarchy to the nav button
            }}
          >
            Start Earning
            <span className="text-xl">→</span>
          </motion.button>

        </motion.div>
      </main>

      {/* Simple Footer just to finish the look */}
      <footer className="relative z-10 border-t border-gray-800 bg-black py-6 text-center text-gray-600 text-sm">
        © 2026 DotYield Labs. Built for Hackathon.
      </footer>

    </div>
  );
}