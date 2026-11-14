'use client';

import { useState } from 'react';
import { 
  Briefcase, 
  MapPin, 
  Clock, 
  Search, 
  Tag, 
  CheckCircle2, 
  FileText,
  TrendingUp,
  X,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';

interface Job {
  id: string;
  title: string;
  clientName: string;
  categoryName: string;
  city: string;
  budgetMin: number;
  budgetMax: number;
  status: string;
  totalProposals: number;
  createdAt: string;
}

interface JobsTableClientProps {
  initialJobs: Job[];
}

export function JobsTableClient({ initialJobs }: JobsTableClientProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);

  // Compute stats
  const totalJobs = initialJobs.length;
  const openJobs = initialJobs.filter(j => j.status === 'open').length;
  const inProgressJobs = initialJobs.filter(j => j.status === 'in_progress').length;
  const completedJobs = initialJobs.filter(j => j.status === 'completed').length;

  const filteredJobs = initialJobs.filter((job) => {
    const matchesSearch = 
      job.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.clientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.categoryName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.city.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = 
      selectedStatus === 'all' || 
      job.status.toLowerCase() === selectedStatus.toLowerCase();

    return matchesSearch && matchesStatus;
  });

  const getStatusBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'completed':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sb-success-subtle text-sb-on-success-subtle border border-sb-success/30">
            <span className="w-1.5 h-1.5 rounded-full bg-sb-success"></span>
            Completed
          </span>
        );
      case 'open':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sb-primary-subtle text-sb-primary border border-sb-border-strong">
            <span className="w-1.5 h-1.5 rounded-full bg-sb-primary"></span>
            Open
          </span>
        );
      case 'in_progress':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sb-warning-subtle text-sb-on-warning-subtle border border-sb-warning/30">
            <span className="w-1.5 h-1.5 rounded-full bg-sb-accent"></span>
            In Progress
          </span>
        );
      case 'cancelled':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sb-error-subtle text-sb-error border border-sb-error/30">
            <span className="w-1.5 h-1.5 rounded-full bg-sb-error"></span>
            Cancelled
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sb-surface-sunken text-sb-text-secondary border border-sb-border">
            <span className="w-1.5 h-1.5 rounded-full bg-sb-border-input"></span>
            {status}
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Total Postings</span>
            <div className="text-2xl font-black text-sb-text mt-1">{totalJobs}</div>
            <span className="text-[11px] font-semibold text-sb-primary flex items-center gap-1 mt-0.5">
              <TrendingUp className="w-3 h-3" /> Live platform jobs
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-primary-subtle text-sb-primary flex items-center justify-center">
            <Briefcase className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Open For Bids</span>
            <div className="text-2xl font-black text-sb-text mt-1">{openJobs}</div>
            <span className="text-[11px] font-semibold text-sb-success flex items-center gap-1 mt-0.5">
              <span className="w-1.5 h-1.5 rounded-full bg-sb-success animate-pulse"></span> Receiving proposals
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-success-subtle text-sb-on-success-subtle flex items-center justify-center">
            <FileText className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">In Progress</span>
            <div className="text-2xl font-black text-sb-text mt-1">{inProgressJobs}</div>
            <span className="text-[11px] font-semibold text-sb-accent flex items-center gap-1 mt-0.5">
              Active service orders
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-warning-subtle text-sb-on-warning-subtle flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Completed</span>
            <div className="text-2xl font-black text-sb-text mt-1">{completedJobs}</div>
            <span className="text-[11px] font-semibold text-sb-on-success-subtle flex items-center gap-1 mt-0.5">
              Successfully fulfilled
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-primary-subtle text-sb-on-primary-subtle flex items-center justify-center">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Table Card (Figma Style) */}
      <div className="bg-sb-surface rounded-2xl border border-sb-border figma-card-shadow overflow-hidden">
        {/* Table Filter / Search Header */}
        <div className="p-4 border-b border-sb-border flex flex-col md:flex-row md:items-center justify-between gap-3">
          {/* Search Pill */}
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-sb-text-secondary" />
            <input 
              type="text"
              placeholder="Search by title, client, category, city..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-sb-canvas border-none text-xs text-sb-text placeholder:text-sb-text-secondary focus:outline-none focus:ring-2 focus:ring-sb-focus/30 transition"
            />
            {searchQuery && (
              <button 
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-sb-text-secondary hover:text-sb-text-secondary"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          {/* Status Tabs */}
          <div className="flex items-center gap-1 bg-sb-canvas p-1 rounded-xl overflow-x-auto">
            {['all', 'open', 'in_progress', 'completed', 'cancelled'].map((status) => (
              <button
                key={status}
                onClick={() => setSelectedStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition ${
                  selectedStatus === status 
                    ? 'bg-sb-surface text-sb-primary shadow-sm font-bold' 
                    : 'text-sb-text-secondary hover:text-sb-text'
                }`}
              >
                {status.replace('_', ' ')}
              </button>
            ))}
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-sb-canvas text-sb-text-secondary font-semibold uppercase tracking-wider text-[11px] border-b border-sb-border">
              <tr>
                <th className="px-6 py-3.5">Job Title & Category</th>
                <th className="px-6 py-3.5">Client</th>
                <th className="px-6 py-3.5">City</th>
                <th className="px-6 py-3.5">Budget</th>
                <th className="px-6 py-3.5">Proposals</th>
                <th className="px-6 py-3.5">Status</th>
                <th className="px-6 py-3.5">Posted</th>
                <th className="px-6 py-3.5 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-sb-border text-sb-text font-medium">
              {filteredJobs.map((job) => (
                <tr key={job.id} className="hover:bg-sb-canvas transition duration-150">
                  <td className="px-6 py-4">
                    <div className="max-w-[240px]">
                      <span className="font-bold text-sb-text text-sm block truncate">{job.title}</span>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <Tag className="w-3 h-3 text-sb-text-secondary" />
                        <span className="text-[11px] font-semibold text-sb-primary bg-sb-primary-subtle px-2 py-0.5 rounded-md">
                          {job.categoryName}
                        </span>
                      </div>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <span className="font-semibold text-sb-text block">{job.clientName}</span>
                    <span className="text-[11px] text-sb-text-secondary block font-mono truncate max-w-[120px]">ID: {job.id.slice(0, 8)}</span>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1 text-sb-text-secondary">
                      <MapPin className="w-3.5 h-3.5 text-sb-text-secondary shrink-0" />
                      <span>{job.city}</span>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <div className="font-bold text-sb-text">
                      Rs. {job.budgetMin.toLocaleString()}
                      {job.budgetMax > job.budgetMin && (
                        <span className="text-sb-text-secondary font-normal"> - {job.budgetMax.toLocaleString()}</span>
                      )}
                    </div>
                    <span className="text-[10px] text-sb-text-secondary">Fixed / Estimated</span>
                  </td>

                  <td className="px-6 py-4">
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-sb-surface-sunken text-sb-text">
                      {job.totalProposals} bids
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    {getStatusBadge(job.status)}
                  </td>

                  <td className="px-6 py-4 text-sb-text-secondary whitespace-nowrap">
                    {new Date(job.createdAt).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    })}
                  </td>

                  <td className="px-6 py-4 text-right">
                    <Button 
                      variant="ghost" 
                      size="sm"
                      onClick={() => setSelectedJob(job)}
                      className="text-sb-primary hover:text-sb-primary hover:bg-sb-primary-subtle rounded-xl text-xs font-semibold"
                    >
                      Inspect
                    </Button>
                  </td>
                </tr>
              ))}

              {filteredJobs.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-sb-text-secondary">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <div className="w-12 h-12 rounded-full bg-sb-canvas flex items-center justify-center text-sb-text-disabled">
                        <Briefcase className="w-6 h-6" />
                      </div>
                      <p className="font-medium text-sm text-sb-text-secondary">No jobs match your criteria</p>
                      <p className="text-xs text-sb-text-secondary">Try adjusting your search query or status filter.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Table Footer */}
        <div className="p-4 border-t border-sb-border flex items-center justify-between text-xs text-sb-text-secondary">
          <span>Showing {filteredJobs.length} of {initialJobs.length} total postings</span>
          <span className="text-[11px] font-medium text-sb-text-secondary">Live sync active</span>
        </div>
      </div>

      {/* Inspect Dialog */}
      <Dialog open={!!selectedJob} onOpenChange={(open) => !open && setSelectedJob(null)}>
        <DialogContent className="max-w-md rounded-2xl p-6 bg-sb-surface border border-sb-border figma-card-shadow">
          <DialogHeader>
            <DialogTitle className="text-lg font-bold text-sb-text">Job Specifications</DialogTitle>
            <DialogDescription className="text-xs text-sb-text-secondary">
              Contract details and bidding overview.
            </DialogDescription>
          </DialogHeader>

          {selectedJob && (
            <div className="space-y-4 pt-3 text-xs">
              <div className="p-3 bg-sb-canvas rounded-xl space-y-1">
                <span className="text-[10px] uppercase font-bold text-sb-text-secondary tracking-wider">Title</span>
                <p className="font-bold text-sb-text text-sm">{selectedJob.title}</p>
                <div className="flex items-center gap-2 pt-1">
                  <span className="bg-sb-primary-subtle text-sb-primary text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {selectedJob.categoryName}
                  </span>
                  {getStatusBadge(selectedJob.status)}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 border border-sb-border rounded-xl">
                  <span className="text-[10px] text-sb-text-secondary uppercase font-semibold block">Client Name</span>
                  <span className="font-bold text-sb-text text-xs block mt-0.5">{selectedJob.clientName}</span>
                </div>
                <div className="p-3 border border-sb-border rounded-xl">
                  <span className="text-[10px] text-sb-text-secondary uppercase font-semibold block">Location</span>
                  <span className="font-bold text-sb-text text-xs block mt-0.5">{selectedJob.city}</span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 border border-sb-border rounded-xl">
                  <span className="text-[10px] text-sb-text-secondary uppercase font-semibold block">Budget Range</span>
                  <span className="font-bold text-sb-text text-xs block mt-0.5">
                    Rs. {selectedJob.budgetMin.toLocaleString()} - {selectedJob.budgetMax.toLocaleString()}
                  </span>
                </div>
                <div className="p-3 border border-sb-border rounded-xl">
                  <span className="text-[10px] text-sb-text-secondary uppercase font-semibold block">Proposals Submitted</span>
                  <span className="font-bold text-sb-primary text-xs block mt-0.5">
                    {selectedJob.totalProposals} Workers
                  </span>
                </div>
              </div>

              <div className="p-3 border border-sb-border rounded-xl">
                <span className="text-[10px] text-sb-text-secondary uppercase font-semibold block">Job ID</span>
                <span className="font-mono text-sb-text-secondary text-[11px] block mt-0.5 select-all">{selectedJob.id}</span>
              </div>

              <div className="flex justify-end pt-2">
                <Button 
                  onClick={() => setSelectedJob(null)}
                  className="bg-sb-primary hover:bg-sb-primary text-sb-on-primary rounded-xl text-xs font-semibold px-4 h-9"
                >
                  Close Inspection
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
