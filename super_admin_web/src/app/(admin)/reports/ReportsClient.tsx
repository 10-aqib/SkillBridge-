'use client';

import { useState } from 'react';
import { 
  ShieldAlert, 
  ShieldCheck, 
  CheckCircle2, 
  AlertTriangle, 
  Search, 
  Filter, 
  User, 
  Clock, 
  Check, 
  X, 
  MessageSquare,
  ChevronRight,
  TrendingDown
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';

export interface ReportItem {
  id: string;
  reporter: string;
  reporterRole: string;
  reported: string;
  reportedRole: string;
  reason: string;
  details?: string;
  status: 'pending' | 'investigating' | 'resolved';
  date: string;
  priority: 'low' | 'medium' | 'high';
}

const INITIAL_REPORTS: ReportItem[] = [
  {
    id: 'REP-1049',
    reporter: 'Hamza Tariq',
    reporterRole: 'Customer',
    reported: 'Muhammad Bilal (Electrician)',
    reportedRole: 'Worker',
    reason: 'Service No-Show & Delayed Start',
    details: 'The technician accepted the wiring job scheduled for 11:00 AM in F-10 Islamabad but did not arrive or respond to messages for 4 hours.',
    status: 'pending',
    date: '2026-09-21',
    priority: 'high',
  },
  {
    id: 'REP-1048',
    reporter: 'Ayesha Malik',
    reporterRole: 'Customer',
    reported: 'QuickFix AC Services',
    reportedRole: 'Worker',
    reason: 'Billing Discrepancy / Overcharge',
    details: 'Agreed contract price was Rs. 3,500 for gas refill, but technician requested additional Rs. 2,000 cash on site.',
    status: 'pending',
    date: '2026-09-20',
    priority: 'medium',
  },
  {
    id: 'REP-1047',
    reporter: 'SkillBridge Automated Sentinel',
    reporterRole: 'System',
    reported: 'Zahid Khan (Plumber)',
    reportedRole: 'Worker',
    reason: 'Unusual Bidding Frequency',
    details: 'Spike of 45 proposals submitted within 2 minutes across diverse unrelated technical categories.',
    status: 'investigating',
    date: '2026-09-19',
    priority: 'low',
  },
  {
    id: 'REP-1046',
    reporter: 'Usman Ghani',
    reporterRole: 'Worker',
    reported: 'Kamran Enterprises',
    reportedRole: 'Customer',
    reason: 'Payment Escrow Release Delay',
    details: 'Carpentry repair completed and verified 5 days ago; client has not confirmed milestone release.',
    status: 'resolved',
    date: '2026-09-17',
    priority: 'medium',
  },
];

export function ReportsClient() {
  const { toast } = useToast();
  const [reports, setReports] = useState<ReportItem[]>(INITIAL_REPORTS);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [activeReport, setActiveReport] = useState<ReportItem | null>(null);

  // Compute stats
  const totalReports = reports.length;
  const pendingCount = reports.filter(r => r.status === 'pending').length;
  const investigatingCount = reports.filter(r => r.status === 'investigating').length;
  const resolvedCount = reports.filter(r => r.status === 'resolved').length;

  const filteredReports = reports.filter((r) => {
    const matchesSearch = 
      r.reporter.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.reported.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.reason.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.id.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = selectedStatus === 'all' || r.status === selectedStatus;
    return matchesSearch && matchesStatus;
  });

  const handleUpdateStatus = (id: string, newStatus: 'pending' | 'investigating' | 'resolved') => {
    setReports(prev => prev.map(r => r.id === id ? { ...r, status: newStatus } : r));
    toast({
      title: 'Status Updated',
      description: `Report ${id} has been marked as ${newStatus}.`,
    });
    if (activeReport?.id === id) {
      setActiveReport(prev => prev ? { ...prev, status: newStatus } : null);
    }
  };

  const getPriorityBadge = (p: string) => {
    switch (p) {
      case 'high':
        return (
          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-700">
            HIGH
          </span>
        );
      case 'medium':
        return (
          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-700">
            MED
          </span>
        );
      default:
        return (
          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-600">
            LOW
          </span>
        );
    }
  };

  const getStatusBadge = (s: string) => {
    switch (s) {
      case 'resolved':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-600 border border-emerald-200">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
            Resolved
          </span>
        );
      case 'investigating':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-600 border border-blue-200">
            <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
            Under Review
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-600 border border-amber-200">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
            Pending Action
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Reports</span>
            <div className="text-2xl font-black text-slate-800 mt-1">{totalReports}</div>
            <span className="text-[11px] font-semibold text-slate-500 flex items-center gap-1 mt-0.5">
              Platform moderation
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-slate-100 text-slate-600 flex items-center justify-center">
            <ShieldAlert className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Pending Action</span>
            <div className="text-2xl font-black text-slate-800 mt-1">{pendingCount}</div>
            <span className="text-[11px] font-semibold text-amber-500 flex items-center gap-1 mt-0.5">
              Requires review
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Investigating</span>
            <div className="text-2xl font-black text-slate-800 mt-1">{investigatingCount}</div>
            <span className="text-[11px] font-semibold text-blue-500 flex items-center gap-1 mt-0.5">
              In mediation
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-blue-50 text-[#2F80ED] flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Resolved</span>
            <div className="text-2xl font-black text-slate-800 mt-1">{resolvedCount}</div>
            <span className="text-[11px] font-semibold text-emerald-600 flex items-center gap-1 mt-0.5">
              Disputes closed
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <ShieldCheck className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Table Card (Figma Style) */}
      <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow overflow-hidden">
        {/* Table Filter / Search Header */}
        <div className="p-4 border-b border-[#F0F4FA] flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input 
              type="text"
              placeholder="Search reports by user, reason, or ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-[#F4F7FE] border-none text-xs text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#2F80ED]/30 transition"
            />
          </div>

          <div className="flex items-center gap-1 bg-[#F4F7FE] p-1 rounded-xl">
            {['all', 'pending', 'investigating', 'resolved'].map((status) => (
              <button
                key={status}
                onClick={() => setSelectedStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition ${
                  selectedStatus === status 
                    ? 'bg-white text-[#2F80ED] shadow-sm font-bold' 
                    : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                {status}
              </button>
            ))}
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F8FAFD] text-slate-400 font-semibold uppercase tracking-wider text-[11px] border-b border-[#E8EFF9]">
              <tr>
                <th className="px-6 py-3.5">Report ID & Date</th>
                <th className="px-6 py-3.5">Filer / Reporter</th>
                <th className="px-6 py-3.5">Reported Subject</th>
                <th className="px-6 py-3.5">Reason & Priority</th>
                <th className="px-6 py-3.5">Status</th>
                <th className="px-6 py-3.5 text-right">Moderation Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0F4FA] text-slate-700 font-medium">
              {filteredReports.map((report) => (
                <tr key={report.id} className="hover:bg-[#F8FAFD] transition duration-150">
                  <td className="px-6 py-4">
                    <span className="font-mono font-bold text-slate-800 block text-xs">{report.id}</span>
                    <span className="text-[11px] text-slate-400 block mt-0.5">{report.date}</span>
                  </td>

                  <td className="px-6 py-4">
                    <span className="font-semibold text-slate-800 block">{report.reporter}</span>
                    <span className="text-[10px] text-slate-400 block">{report.reporterRole}</span>
                  </td>

                  <td className="px-6 py-4">
                    <span className="font-semibold text-slate-800 block">{report.reported}</span>
                    <span className="text-[10px] text-slate-400 block">{report.reportedRole}</span>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-slate-800 max-w-[200px] truncate block">{report.reason}</span>
                      {getPriorityBadge(report.priority)}
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    {getStatusBadge(report.status)}
                  </td>

                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-1.5">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setActiveReport(report)}
                        className="text-[#2F80ED] hover:bg-[#EBF3FF] rounded-xl text-xs font-semibold px-2.5 h-8"
                      >
                        Inspect
                      </Button>

                      {report.status !== 'resolved' ? (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleUpdateStatus(report.id, 'resolved')}
                          className="h-8 w-8 text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700 rounded-xl"
                          title="Mark as Resolved"
                        >
                          <Check className="h-4 w-4" />
                        </Button>
                      ) : (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleUpdateStatus(report.id, 'pending')}
                          className="h-8 w-8 text-slate-400 hover:bg-slate-100 rounded-xl"
                          title="Re-open"
                        >
                          <Clock className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}

              {filteredReports.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <ShieldCheck className="w-8 h-8 text-slate-300" />
                      <p className="font-medium text-sm text-slate-600">No reports found</p>
                      <p className="text-xs text-slate-400">No active disputes matching current filters.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Case Details Dialog */}
      <Dialog open={!!activeReport} onOpenChange={(open) => !open && setActiveReport(null)}>
        <DialogContent className="max-w-md rounded-2xl p-6 bg-white border border-[#E8EFF9] figma-card-shadow">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold text-slate-800">
              Dispute Investigation
            </DialogTitle>
            <DialogDescription className="text-xs text-slate-400">
              Detailed filing testimony and evidence record.
            </DialogDescription>
          </DialogHeader>

          {activeReport && (
            <div className="space-y-4 pt-3 text-xs">
              <div className="p-3 bg-[#F4F7FE] rounded-xl flex items-center justify-between">
                <div>
                  <span className="font-mono font-bold text-slate-800 text-sm">{activeReport.id}</span>
                  <span className="text-[11px] text-slate-500 block">Filed on {activeReport.date}</span>
                </div>
                {getStatusBadge(activeReport.status)}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 border border-slate-100 rounded-xl">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Reporting Party</span>
                  <span className="font-bold text-slate-800 text-xs mt-0.5 block">{activeReport.reporter}</span>
                  <span className="text-[10px] text-[#2F80ED] font-semibold">{activeReport.reporterRole}</span>
                </div>
                <div className="p-3 border border-slate-100 rounded-xl">
                  <span className="text-[10px] text-slate-400 uppercase font-semibold block">Subject Party</span>
                  <span className="font-bold text-slate-800 text-xs mt-0.5 block">{activeReport.reported}</span>
                  <span className="text-[10px] text-red-500 font-semibold">{activeReport.reportedRole}</span>
                </div>
              </div>

              <div className="p-3 border border-slate-100 rounded-xl space-y-1">
                <span className="text-[10px] text-slate-400 uppercase font-semibold block">Dispute Violation</span>
                <p className="font-bold text-slate-800">{activeReport.reason}</p>
                <p className="text-slate-600 text-xs leading-relaxed pt-1 bg-white p-2.5 rounded-lg border border-slate-50">
                  {activeReport.details || 'No additional narrative provided.'}
                </p>
              </div>

              <div className="flex items-center justify-between pt-2">
                <div className="flex items-center gap-2">
                  {activeReport.status !== 'resolved' ? (
                    <Button 
                      onClick={() => handleUpdateStatus(activeReport.id, 'resolved')}
                      className="bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-semibold px-3 h-8"
                    >
                      Resolve Case
                    </Button>
                  ) : (
                    <Button 
                      onClick={() => handleUpdateStatus(activeReport.id, 'investigating')}
                      variant="outline"
                      className="rounded-xl text-xs font-semibold px-3 h-8"
                    >
                      Move to In Review
                    </Button>
                  )}
                </div>

                <Button 
                  onClick={() => setActiveReport(null)}
                  variant="ghost"
                  className="rounded-xl text-xs text-slate-500 hover:text-slate-800"
                >
                  Close
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
