'use client';

import { useState } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Clock, AlertCircle } from 'lucide-react';

export function DashboardCalendar() {
  const today = new Date();
  const [selectedDay, setSelectedDay] = useState(today.getDate());

  const monthName = today.toLocaleDateString('en-US', { month: 'short' });
  const dayName = today.toLocaleDateString('en-US', { weekday: 'long' });
  const year = today.getFullYear();

  const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Generate a standard calendar view for current month
  const currentMonth = today.getMonth();
  const firstDayIndex = (new Date(year, currentMonth, 1).getDay() + 6) % 7;
  const daysInMonth = new Date(year, currentMonth + 1, 0).getDate();

  const calendarDays = [];
  // previous month padding
  for (let i = 0; i < firstDayIndex; i++) {
    calendarDays.push({ day: null, isCurrentMonth: false });
  }
  // current month days
  for (let i = 1; i <= daysInMonth; i++) {
    calendarDays.push({ day: i, isCurrentMonth: true });
  }

  return (
    <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow flex flex-col space-y-4">
      {/* Header with Date */}
      <div className="flex items-center justify-between">
        <div className="flex flex-col">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Today</span>
          <h4 className="text-base font-bold text-slate-800">
            {monthName}, {today.getDate()} {dayName}
          </h4>
        </div>
        <div className="flex items-center gap-1 text-slate-400">
          <button className="p-1 rounded-lg hover:bg-slate-100 hover:text-slate-700 transition">
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button className="p-1 rounded-lg hover:bg-slate-100 hover:text-slate-700 transition">
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Weekdays Row */}
      <div className="grid grid-cols-7 text-center text-[11px] font-semibold text-slate-400 pb-1">
        {daysOfWeek.map((d, i) => (
          <div key={i}>{d}</div>
        ))}
      </div>

      {/* Days Grid */}
      <div className="grid grid-cols-7 gap-y-1.5 text-center text-xs">
        {calendarDays.slice(0, 35).map((item, i) => {
          if (!item.day) {
            return <div key={i} className="h-7 w-7 mx-auto"></div>;
          }

          const isToday = item.day === today.getDate();
          const isSelected = item.day === selectedDay;

          return (
            <button
              key={i}
              onClick={() => setSelectedDay(item.day!)}
              className={`h-7 w-7 mx-auto rounded-full flex items-center justify-center font-medium transition text-xs ${
                isToday 
                  ? 'bg-[#10B981] text-white font-bold shadow-sm shadow-emerald-400/30' 
                  : isSelected
                    ? 'bg-[#2F80ED] text-white font-bold'
                    : 'text-slate-600 hover:bg-[#F4F7FE]'
              }`}
            >
              {item.day}
            </button>
          );
        })}
      </div>

      {/* Upcoming Review & Meetings Schedule (Figma Style) */}
      <div className="pt-2 space-y-2 border-t border-[#F0F4FA]">
        <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
          Scheduled Admin Tasks
        </div>

        {/* Coral Alert Pill */}
        <div className="flex items-center justify-between p-2.5 rounded-xl bg-gradient-to-r from-red-500 to-rose-500 text-white shadow-xs">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-white/80 animate-ping"></span>
            <span className="text-xs font-semibold">Dispute & Fraud Audit</span>
          </div>
          <span className="text-[10px] font-medium bg-white/20 px-2 py-0.5 rounded-full">14:00</span>
        </div>

        {/* Blue Info Pill */}
        <div className="flex items-center justify-between p-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-sky-500 text-white shadow-xs">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-white/80"></span>
            <span className="text-xs font-semibold">CNIC Worker Verification</span>
          </div>
          <span className="text-[10px] font-medium bg-white/20 px-2 py-0.5 rounded-full">16:30</span>
        </div>

        {/* Green Done Pill */}
        <div className="flex items-center justify-between p-2.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-xs">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-white/80"></span>
            <span className="text-xs font-semibold">Escrow Release Sign-off</span>
          </div>
          <span className="text-[10px] font-medium bg-white/20 px-2 py-0.5 rounded-full">18:00</span>
        </div>
      </div>
    </div>
  );
}
