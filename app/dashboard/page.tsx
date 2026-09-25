"use client";

import React, { useState } from 'react';
import { Shield, Cloud, Server, AlertCircle, CheckCircle2, RefreshCw, ExternalLink, Filter, Plus } from 'lucide-react';

export default function DashboardPage() {
  const [certificates] = useState([
    { id: '1', domain: 'api.sirket.com', provider: 'AWS', region: 'us-east-1', daysLeft: 82, status: 'HEALTHY', autoRenew: true },
    { id: '2', domain: 'payment.sirket.com', provider: 'AZURE', region: 'westeurope', daysLeft: 12, status: 'WARNING', autoRenew: true },
    { id: '3', domain: 'legacy-vpn.sirket.com', provider: 'ON_PREM', region: 'internal-vpc', daysLeft: -2, status: 'CRITICAL', autoRenew: false },
    { id: '4', domain: 'staging.sirket.com', provider: 'GCP', region: 'europe-west1', daysLeft: 45, status: 'HEALTHY', autoRenew: true },
  ]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex">
      <aside className="w-64 border-r border-slate-800 p-6 flex flex-col justify-between hidden md:flex">
        <div className="space-y-8">
          <div className="flex items-center gap-2 font-bold text-xl text-white">
            <Shield className="w-6 h-6 text-indigo-500" />
            <span>CLM Platform</span>
          </div>
          <nav className="space-y-1">
            <a href="#" className="flex items-center gap-3 px-3 py-2 bg-indigo-600/10 text-indigo-400 font-semibold rounded-xl border border-indigo-800/30">
              <Server className="w-4 h-4" /> Envanter & Sertifikalar
            </a>
            <a href="#" className="flex items-center gap-3 px-3 py-2 text-slate-400 hover:text-white hover:bg-slate-900 rounded-xl transition-colors">
              <Cloud className="w-4 h-4" /> Bulut Hesapları
            </a>
            <a href="#" className="flex items-center gap-3 px-3 py-2 text-slate-400 hover:text-white hover:bg-slate-900 rounded-xl transition-colors">
              <RefreshCw className="w-4 h-4" /> Otonom Yenileme (ACME)
            </a>
          </nav>
        </div>
        <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <p className="text-xs text-slate-400">Aktif Abonelik</p>
          <p className="text-sm font-bold text-white mt-0.5">Enterprise Plan</p>
          <p className="text-xs text-indigo-400 mt-2 font-mono">142/500 Sertifika</p>
        </div>
      </aside>

      <main className="flex-1 p-8 overflow-y-auto">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
          <div>
            <h1 className="text-2xl font-bold text-white">Multi-Cloud Sertifika Envanteri</h1>
            <p className="text-slate-400 text-sm mt-1">Tüm bulut ve VPC ağlarınızdaki aktif TLS/SSL durumları</p>
          </div>
          <button className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold px-4 py-2.5 rounded-xl transition-all flex items-center gap-2 text-sm shadow-lg shadow-indigo-600/20">
            <Plus className="w-4 h-4" /> Yeni Bulut Hesabı Bağla
          </button>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl">
          <div className="p-4 border-b border-slate-800 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Filter className="w-4 h-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-300">Filtrele</span>
            </div>
            <span className="text-xs text-slate-500 font-mono">Toplam: {certificates.length} Sertifika</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-950/50 text-slate-400 uppercase text-xs border-b border-slate-800">
                <tr>
                  <th className="p-4">Domain / Endpoint</th>
                  <th className="p-4">Sağlayıcı</th>
                  <th className="p-4">Bölge / Ağ</th>
                  <th className="p-4">Kalan Süre</th>
                  <th className="p-4">Auto-Renewal</th>
                  <th className="p-4 text-right">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {certificates.map((cert) => (
                  <tr key={cert.id} className="hover:bg-slate-800/50 transition-colors">
                    <td className="p-4 font-mono font-medium text-white flex items-center gap-2">
                      {cert.domain}
                      <ExternalLink className="w-3.5 h-3.5 text-slate-500" />
                    </td>
                    <td className="p-4 font-semibold">
                      <span className={`px-2.5 py-1 rounded-md text-xs border ${
                        cert.provider === 'AWS' ? 'bg-amber-950/50 text-amber-400 border-amber-800' :
                        cert.provider === 'AZURE' ? 'bg-blue-950/50 text-blue-400 border-blue-800' :
                        cert.provider === 'GCP' ? 'bg-red-950/50 text-red-400 border-red-800' :
                        'bg-purple-950/50 text-purple-400 border-purple-800'
                      }`}>
                        {cert.provider}
                      </span>
                    </td>
                    <td className="p-4 text-slate-400 text-xs font-mono">{cert.region}</td>
                    <td className="p-4">
                      {cert.daysLeft < 0 ? (
                        <span className="text-red-500 font-bold">{Math.abs(cert.daysLeft)} gün önce doldu</span>
                      ) : (
                        <span className={cert.daysLeft <= 15 ? 'text-amber-400 font-bold' : 'text-slate-300'}>
                          {cert.daysLeft} gün kaldı
                        </span>
                      )}
                    </td>
                    <td className="p-4">
                      {cert.autoRenew ? (
                        <span className="inline-flex items-center gap-1 text-xs text-emerald-400">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Aktif (ACME)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs text-slate-500">
                          Devre Dışı
                        </span>
                      )}
                    </td>
                    <td className="p-4 text-right">
                      {cert.status === 'HEALTHY' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-950 text-emerald-400 border border-emerald-800">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Sağlıklı
                        </span>
                      )}
                      {cert.status === 'WARNING' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-950 text-amber-400 border border-amber-800">
                          <AlertCircle className="w-3.5 h-3.5" /> Riskli (Süre Az)
                        </span>
                      )}
                      {cert.status === 'CRITICAL' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-red-950 text-red-400 border border-red-800">
                          <AlertCircle className="w-3.5 h-3.5" /> Kritik
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
